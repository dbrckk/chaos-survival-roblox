#!/usr/bin/env python3
"""Read-only verification of 16 creator-owned original Roblox PBR Image IDs.

Never creates or updates Roblox assets, never publishes a place, and never
writes original asset IDs into the shipped default.project.json. A fully
verified copy of the Rojo project is a PRIVATE staging artifact only.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import sys
from typing import Any
import urllib.error
import urllib.request

RECEIPTS = Path("assets/source/roblox-pbr-upload-receipts.json")
SHIPPED_PROJECT = Path("default.project.json")
OUT = Path("build/pbr-asset-audit")
CREATOR = "9774173158"
CHANNELS = ("color", "normal", "roughness", "metallic")
VARIANTS = {
    "brushed_titanium": "ChaosBrushedTitanium",
    "oxidized_steel": "ChaosOxidizedSteel",
    "armored_diamondplate": "ChaosDiamondArmor",
    "reactor_ceramic": "ChaosReactorCeramic",
}
PROPERTIES = {
    "color": "ColorMap",
    "normal": "NormalMap",
    "roughness": "RoughnessMap",
    "metallic": "MetalnessMap",
}
ASSET_TYPES = {"IMAGE", "DECAL", "ASSET_TYPE_IMAGE", "ASSET_TYPE_DECAL"}


def load_receipts() -> dict[str, Any]:
    data = json.loads(RECEIPTS.read_text(encoding="utf-8"))
    if str(data.get("creator_user_id")) != CREATOR:
        raise ValueError("PBR receipt creator does not match the experience owner")
    materials = data.get("materials", {})
    if set(materials) != set(VARIANTS):
        raise ValueError("Expected precisely the four original PBR material families")
    all_ids: list[str] = []
    for material, record in materials.items():
        entries = record.get("channels", {})
        if set(entries) != set(CHANNELS):
            raise ValueError(f"Missing or unexpected Image channel in {material}")
        for channel in CHANNELS:
            item = entries[channel]
            asset_id = item.get("id") if isinstance(item, dict) else None
            if not isinstance(asset_id, str) or not asset_id.isdecimal():
                raise ValueError(f"Unverified Roblox Image ID for {material}/{channel}")
            all_ids.append(asset_id)
    if len(all_ids) != 16 or len(set(all_ids)) != 16:
        raise ValueError("Require exactly 16 DISTINCT creator-owned Image receipts")
    if materials["armored_diamondplate"].get("missing") != []:
        raise ValueError("Diamondplate recovery not recorded as completed")
    return data


def normalized_state(state: Any) -> str:
    if not isinstance(state, str):
        return "UNKNOWN"
    normalized = re.sub(r"[^A-Z_]", "", state.strip().upper())
    return {
        "APPROVED": "APPROVED",
        "MODERATION_STATE_APPROVED": "APPROVED",
        "REVIEWING": "REVIEWING",
        "MODERATION_STATE_REVIEWING": "REVIEWING",
        "REJECTED": "REJECTED",
        "MODERATION_STATE_REJECTED": "REJECTED",
    }.get(normalized, "UNKNOWN")


def evaluate(asset_id: str, body: dict[str, Any]) -> dict[str, Any]:
    """Fail closed on absent identity, creator, asset type or moderation."""
    creator = (body.get("creationContext") or {}).get("creator") or {}
    owner_matches = str(creator.get("userId") or "") == CREATOR
    id_matches = str(body.get("assetId") or "") == asset_id
    asset_type = str(body.get("assetType") or "").upper()
    type_matches = asset_type in ASSET_TYPES
    moderation = normalized_state(
        (body.get("moderationResult") or {}).get("moderationState")
    )
    return {
        "moderation": moderation,
        "creator_verified": owner_matches,
        "asset_id_verified": id_matches,
        "image_type_verified": type_matches,
        "asset_type": asset_type,
        "approved_for_private_staging": bool(
            owner_matches and id_matches and type_matches
            and moderation == "APPROVED"
        ),
    }


def fetch_asset(asset_id: str, api_key: str) -> dict[str, Any]:
    url = f"https://apis.roblox.com/assets/v1/assets/{asset_id}"
    req = urllib.request.Request(
        url, headers={"x-api-key": api_key, "Accept": "application/json"},
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=24) as response:
            status = response.status
            raw = response.read(32768)
    except urllib.error.HTTPError as exc:
        status = exc.code
        # Do not expose API key, authorization headers or arbitrary response.
        exc.read(32768)
        return {"http_status": status, "error_category": f"HTTP_{status}",
                "approved_for_private_staging": False}
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        return {"error_category": type(exc).__name__,
                "approved_for_private_staging": False}
    if status != 200:
        return {"http_status": status, "error_category": "Unexpected_HTTP",
                "approved_for_private_staging": False}
    try:
        body = json.loads(raw)
    except (ValueError, UnicodeDecodeError):
        return {"http_status": status, "error_category": "Invalid_JSON",
                "approved_for_private_staging": False}
    if not isinstance(body, dict):
        return {"http_status": status, "error_category": "Invalid_Metadata",
                "approved_for_private_staging": False}
    return {"http_status": status, **evaluate(asset_id, body)}


def build_private_staging(report: dict[str, Any]) -> bool:
    if not report["all_16_approved"]:
        return False
    source = json.loads(SHIPPED_PROJECT.read_text(encoding="utf-8"))
    material_service = source["tree"]["MaterialService"]
    receipts = load_receipts()["materials"]
    for name, variant in VARIANTS.items():
        properties = material_service[variant]["$properties"]
        for channel, property_name in PROPERTIES.items():
            properties[property_name] = (
                "rbxassetid://" + receipts[name]["channels"][channel]["id"]
            )
    target = OUT / "default.original-pbr.PRIVATE-STAGING.project.json"
    target.write_text(json.dumps(source, indent=2) + "\n", encoding="utf-8")
    return True



def verify_shipped_pbr_contract() -> None:
    """Guard the real shipped variants against the independent owner audit.

    This is a snapshot consistency check, NOT a fresh Roblox moderation check.
    A revoked permission or changed moderation still requires live Open Cloud
    re-verification before any public-place deployment.
    """
    receipts = load_receipts()
    evidence_path = Path("assets/source/roblox-pbr-approval-evidence.json")
    evidence = json.loads(evidence_path.read_text(encoding="utf-8"))
    if evidence.get("source") != (
        "read-only Roblox Open Cloud GET /assets/v1/assets/{assetId}; per-image HTTP 200"
    ):
        raise ValueError("Approval evidence must come from real read-only Roblox GET")
    if (str(evidence.get("creator_user_id")) != CREATOR
            or evidence.get("all_approved_at_audit") is not True
            or evidence.get("approved_current_at_audit") != 16
            or evidence.get("total_unique_image_ids") != 16):
        raise ValueError("Missing complete creator-owned PBR approval evidence")
    if evidence.get("public_place_published") is not False:
        raise ValueError("Audit must not claim a public release")
    if set(evidence.get("materials", {})) != set(VARIANTS):
        raise ValueError("Approval evidence material list differs from shipped PBR")

    project = json.loads(SHIPPED_PROJECT.read_text(encoding="utf-8"))
    variants = project["tree"]["MaterialService"]
    for material, variant in VARIANTS.items():
        if variant not in variants:
            raise ValueError(f"Missing shipped MaterialVariant {variant}")
        properties = variants[variant]["$properties"]
        receipt_channels = receipts["materials"][material]["channels"]
        approval_channels = evidence["materials"][material]
        if set(approval_channels) != set(CHANNELS):
            raise ValueError(f"Incomplete audited PBR channels: {material}")
        for channel, prop in PROPERTIES.items():
            asset_id = receipt_channels[channel]["id"]
            approved = approval_channels[channel]
            if (str(approved.get("id")) != asset_id
                    or approved.get("current_moderation_at_audit") != "APPROVED"
                    or str(approved.get("ownership_at_audit")) != CREATOR
                    or approved.get("asset_metadata_http_status") != 200):
                raise ValueError(f"Unverified approval for {material}/{channel}")
            if properties.get(prop) != "rbxassetid://" + asset_id:
                raise ValueError(
                    f"Shipped {variant}.{prop} does not match approved owner asset"
                )
    print("PASS: all 16 shipped PBR maps match approved owner evidence and receipts.")



def self_test() -> None:
    verify_shipped_pbr_contract()
    assets = load_receipts()
    test_id = assets["materials"]["armored_diamondplate"]["channels"]["roughness"]["id"]
    valid = {
        "assetId": test_id, "assetType": "ASSET_TYPE_IMAGE",
        "creationContext": {"creator": {"userId": CREATOR}},
        "moderationResult": {"moderationState": "MODERATION_STATE_APPROVED"},
    }
    assert evaluate(test_id, valid)["approved_for_private_staging"]
    for state in ("Reviewing", "Rejected", "", "unknown"):
        v = dict(valid, moderationResult={"moderationState": state})
        assert not evaluate(test_id, v)["approved_for_private_staging"]
    wrong_owner = dict(valid, creationContext={"creator": {"userId": "42"}})
    assert not evaluate(test_id, wrong_owner)["approved_for_private_staging"]
    wrong_id = dict(valid, assetId="999")
    assert not evaluate(test_id, wrong_id)["approved_for_private_staging"]
    unknown_type = dict(valid, assetType="ASSET_TYPE_MODEL")
    assert not evaluate(test_id, unknown_type)["approved_for_private_staging"]
    incomplete = dict(valid)
    incomplete.pop("moderationResult")
    assert not evaluate(test_id, incomplete)["approved_for_private_staging"]
    assert normalized_state("MODERATION_STATE_APPROVED") == "APPROVED"
    assert normalized_state("Approved") == "APPROVED"
    assert normalized_state("MODERATION_STATE_REVIEWING") == "REVIEWING"
    print("PASS: all 16 unique receipts and fail-closed owner/ID/moderation/type gates.")


def run(mode: str) -> int:
    receipts = load_receipts()
    OUT.mkdir(parents=True, exist_ok=True)
    key = os.environ.get("ROBLOX_ASSET_API_KEY", "") if mode == "live" else ""
    rows: list[dict[str, Any]] = []
    for material in VARIANTS:
        for channel in CHANNELS:
            record = receipts["materials"][material]["channels"][channel]
            row: dict[str, Any] = {
                "material": material, "channel": channel,
                "asset_id": record["id"],
                "creation_time_moderation": record.get("state_at_upload", "UNKNOWN"),
            }
            if mode != "live":
                row.update({"error_category": "OFFLINE_ONLY",
                            "approved_for_private_staging": False})
            elif not key:
                row.update({"error_category": "ASSET_READ_KEY_MISSING",
                            "approved_for_private_staging": False})
            else:
                row.update(fetch_asset(record["id"], key))
            rows.append(row)
            if mode == "live":
                print(f"{material}/{channel}: "
                      f"{row.get('moderation','UNVERIFIED')} "
                      f"(HTTP {row.get('http_status', 'n/a')}, "
                      f"owner={'ok' if row.get('creator_verified') else 'unverified'})",
                      flush=True)

    approved = sum(bool(row.get("approved_for_private_staging")) for row in rows)
    report = {
        "schema": "Chaos original PBR real-time creator-owned asset verification v1",
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "mode": mode, "source": "Roblox Open Cloud GET /assets/v1/assets/{assetId}",
        "creator_user_id": CREATOR, "total": len(rows),
        "approved_count": approved,
        "all_16_approved": mode == "live" and approved == 16,
        "game_runtime_qa_completed": False,
        "public_place_published": False,
        "assets": rows,
    }
    report["private_staging_project_created"] = build_private_staging(report)
    (OUT / "asset-moderation-report.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as s:
            s.write(f"### Original PBR asset audit — {mode}\n\n"
                    f"- {approved}/16 independently approved & owned Images\n"
                    f"- Private staging JSON: {'ready' if report['private_staging_project_created'] else 'BLOCKED'}\n"
                    f"- Shipped project unchanged; **no assets created; no public Roblox publish**\n"
                    f"- This does not verify Android render, permissions to the universe, or Studio frame time\n\n")
            s.write("| Material | Channel | Roblox asset | Current metadata | Ownership |\n"
                    "|---|---|---:|---|---|\n")
            for item in rows:
                status = item.get("moderation", item.get("error_category", "unknown"))
                owner = "verified" if item.get("creator_verified") else "not verified"
                s.write(f"| {item['material']} | {item['channel']} | "
                        f"{item['asset_id']} | {status} | {owner} |\n")
    print(f"READ-ONLY {mode}: {approved}/16 approved+owned. "
          f"Private staging {'CREATED' if report['private_staging_project_created'] else 'BLOCKED'}."
          " Shipped place and project UNCHANGED.", flush=True)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--self-test", action="store_true")
    group.add_argument("--offline", action="store_true")
    group.add_argument("--live", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    return run("live" if args.live else "offline")


if __name__ == "__main__":
    sys.exit(main())
