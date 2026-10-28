#!/usr/bin/env python3
"""One-shot creator-authorized recovery of TWO missing Roblox PBR Image assets.

Never POSTs the 14 images already created. Never retries POST. Records the
creation operation before polling, and keeps all receipts after partial failure.
This is deliberately NOT a general asset-upload tool.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import time
import urllib.error
import urllib.request
import uuid

from PIL import Image

BASE = "https://apis.roblox.com/assets/v1/"
ROOT = Path("build/pbr-recovery-once")
RECEIPTS = Path("assets/source/roblox-pbr-upload-receipts.json")
CHANNELS = ("roughness", "metallic")
OWNER = "9774173158"
# Roblox rejected both previous POSTs with HTTP 400 "Asset name length is
# invalid." The original prefix was longer for roughness/metallic than the
# already-created color/normal assets. Use stable SHORT names < 50 chars.
ROBLOX_ASSET_NAME_MAX = 50


def safe_asset_name(channel: str) -> str:
    assert channel in CHANNELS
    name = f"Chaos PBR Diamondplate {channel.title()} 2K"
    assert len(name) <= ROBLOX_ASSET_NAME_MAX, "Roblox Image name too long"
    return name


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def safe_message(data: bytes) -> str:
    try:
        result = json.loads(data.decode("utf-8", errors="replace"))
        if isinstance(result, dict):
            message = (result.get("message") or result.get("error")
                       or result.get("errors") or result.get("status")
                       or "Roblox returned no structured error message")
        else:
            message = result
    except (ValueError, UnicodeDecodeError):
        message = "Non-JSON response"
    return str(message).replace("\n", " ")[:500]


def api_request(method: str, suffix: str, key: str, body: bytes | None = None,
                content_type: str | None = None) -> tuple[int, bytes]:
    headers = {"x-api-key": key}
    if content_type:
        headers["Content-Type"] = content_type
    req = urllib.request.Request(BASE + suffix, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=65) as response:
            return response.status, response.read(16384)
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read(16384)


def encode_multipart(payload: dict, image: bytes, boundary: str) -> bytes:
    # Matches the proven Roblox multipart shape from the three successful packs.
    fields = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    return (
        b"--" + boundary.encode() + b"\r\n"
        + b'Content-Disposition: form-data; name="request"\r\n\r\n'
        + fields + b"\r\n"
        + b"--" + boundary.encode() + b"\r\n"
        + b'Content-Disposition: form-data; name="fileContent"; filename="original.png"\r\n'
        + b"Content-Type: image/png\r\n\r\n"
        + image + b"\r\n"
        + b"--" + boundary.encode() + b"--\r\n"
    )


def verify_sources() -> tuple[dict, dict]:
    receipts = json.loads(RECEIPTS.read_text(encoding="utf-8"))
    assert receipts["creator_user_id"] == OWNER
    armor = receipts["materials"]["armored_diamondplate"]
    assert armor["selected_partial_run_id"] == 40674439392
    assert armor["channels"]["color"]["id"] == "86680602350796"
    assert armor["channels"]["normal"]["id"] == "94326474312318"
    assert armor["channels"]["roughness"] is None
    assert armor["channels"]["metallic"] is None
    assert armor["missing"] == list(CHANNELS)
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["resolution"] == [2048, 2048]
    assert manifest["texture_upload_status"] == "NOT_UPLOADED_TO_ROBLOX"
    assert len(manifest["materials"]) == 1
    assert manifest["materials"][0]["name"] == "armored_diamondplate"
    for channel in CHANNELS:
        assert len(safe_asset_name(channel)) <= ROBLOX_ASSET_NAME_MAX
        entry = manifest["materials"][0]["maps"][channel]
        path = ROOT / entry["path"]
        assert path.is_file() and path.stat().st_size < 20 * 1024 * 1024
        assert hashlib.sha256(path.read_bytes()).hexdigest() == entry["sha256"]
        with Image.open(path) as image:
            assert image.format == "PNG" and image.size == (2048, 2048)
            assert image.mode == "L"
    return receipts, manifest


def create_one(channel: str, manifest: dict, key: str, report: dict) -> dict:
    assert channel in CHANNELS
    entry = manifest["materials"][0]["maps"][channel]
    image = (ROOT / entry["path"]).read_bytes()
    request = {
        "assetType": "Image",
        "displayName": safe_asset_name(channel),
        "description": "Original game-authored 2048px PBR map for Chaos Survival.",
        "creationContext": {"creator": {"userId": OWNER}},
    }
    boundary = "ChaosOwnedImage" + uuid.uuid4().hex
    body = encode_multipart(request, image, boundary)
    result = {"channel": channel, "source_sha256": entry["sha256"],
              "post_count": 0, "state": "not_started"}
    report["channels"][channel] = result
    write_json(ROOT / "roblox-operations" / "attempt-report.json", report)

    # One POST maximum per missing channel, EVER for this automated run.
    result["post_count"] = 1
    result["state"] = "post_sent_result_unknown"
    write_json(ROOT / "roblox-operations" / "attempt-report.json", report)
    try:
        code, raw = api_request("POST", "assets", key, body,
                                f"multipart/form-data; boundary={boundary}")
    except Exception as exc:
        result.update(state="network_uncertain", detail=type(exc).__name__)
        print(f"ERROR {channel}: POST network outcome unknown. NEVER retry blindly.", flush=True)
        write_json(ROOT / "roblox-operations" / "attempt-report.json", report)
        return result

    result["http_status"] = code
    if not 200 <= code < 300:
        result.update(state="http_error", error=safe_message(raw))
        print(f"ERROR {channel}: Roblox HTTP {code}: {result['error']}", flush=True)
        write_json(ROOT / "roblox-operations" / "attempt-report.json", report)
        return result

    try:
        created = json.loads(raw)
        operation = created.get("path", "")
        if not isinstance(operation, str) or not operation.startswith("operations/"):
            raise ValueError("Missing valid Roblox operation path")
    except (ValueError, TypeError):
        result.update(state="creation_response_unknown", detail="No valid operation path")
        write_json(ROOT / "roblox-operations" / "attempt-report.json", report)
        return result

    result.update(state="operation_pending", operation_path=operation)
    write_json(ROOT / "roblox-operations" / "attempt-report.json", report)
    for poll in range(1, 25):
        try:
            code, raw = api_request("GET", operation, key)
            if not 200 <= code < 300:
                result.update(state="poll_http_error", poll_http_status=code,
                              detail=safe_message(raw))
                break
            item = json.loads(raw)
            if item.get("error"):
                result.update(state="roblox_rejected", detail=safe_message(raw))
                break
            if item.get("done"):
                response = item.get("response") or {}
                asset_id = str(response.get("assetId") or "")
                if asset_id.isdecimal():
                    moderation = (response.get("moderationResult") or {}).get(
                        "moderationState", "PENDING")
                    result.update(state="created", asset_id=asset_id,
                                  moderation_at_creation=moderation,
                                  successful_operation_poll=poll)
                    break
                result.update(state="completed_without_asset_id")
                break
        except Exception as exc:
            result.update(state="poll_network_uncertain", detail=type(exc).__name__)
            break
        if poll < 24:
            time.sleep(5)
    else:
        result.update(state="operation_pending_after_timeout")
    write_json(ROOT / "roblox-operations" / "attempt-report.json", report)
    print(f"{channel}: state={result['state']}"
          + (f", asset={result['asset_id']}" if result.get("asset_id") else ""), flush=True)
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    if args.dry_run == args.execute:
        parser.error("choose exactly one of --dry-run and --execute")

    receipts, manifest = verify_sources()
    report = {
        "schema": "Chaos original diamondplate missing-channel one-shot recovery v1",
        "dry_run": args.dry_run,
        "base_source_run": receipts["materials"]["armored_diamondplate"]["selected_partial_run_id"],
        "previous_two_channel_attempt": 40678338047,
        "previous_terminal_rejection": "HTTP 400: Asset name length is invalid",
        "asset_names": {channel: safe_asset_name(channel) for channel in CHANNELS},
        "existing_color_id": "86680602350796",
        "existing_normal_id": "94326474312318",
        "channels": {},
    }
    out = ROOT / "roblox-operations" / "attempt-report.json"
    write_json(out, report)

    if args.execute:
        # No other event, ref, or rerun can use the one-shot upload credentials.
        if (os.environ.get("GITHUB_EVENT_NAME") != "push"
                or os.environ.get("GITHUB_REF") != "refs/heads/main"
                or os.environ.get("GITHUB_RUN_ATTEMPT") != "1"
                or os.environ.get("CHAOS_PBR_OWNER_APPROVED_ONCE") != "true"):
            raise SystemExit("Refusing upload outside the owner-approved, first main push")
        key = os.environ.get("ROBLOX_ASSET_API_KEY", "")
        if not key:
            raise SystemExit("Missing ROBLOX_ASSET_API_KEY GitHub secret")
        for channel in CHANNELS:
            # Even after a failed POST, attempt the *other* channel once only.
            create_one(channel, manifest, key, report)
            if channel != CHANNELS[-1]:
                time.sleep(4)
    else:
        for channel in CHANNELS:
            report["channels"][channel] = {"state": "verified_dry_run_only",
                                            "source_sha256": manifest["materials"][0]["maps"][channel]["sha256"],
                                            "post_count": 0}
        write_json(out, report)
        print("DRY RUN: two original 2K maps verified. ZERO Roblox POSTs.", flush=True)

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as f:
            f.write("### Chaos diamondplate two-image recovery (one-shot)\n\n")
            f.write("- Color and normal assets: existing IDs reused without POSTs\n")
            for channel in CHANNELS:
                r = report["channels"][channel]
                f.write(f"- **{channel}**: {r['state']}")
                if r.get("asset_id"):
                    f.write(f"; new asset ID **{r['asset_id']}**")
                    f.write(f"; creation-time moderation **{r['moderation_at_creation']}**")
                if r.get("http_status") and r["state"] != "created":
                    f.write(f"; HTTP **{r['http_status']}**")
                f.write("\n")
            f.write("- No Roblox experience or public place was published\n")

    if args.execute and any(
        report["channels"].get(c, {}).get("state") != "created" for c in CHANNELS
    ):
        print("PARTIAL/FAILED: inspect artifact; do not rerun create POSTs blindly.", flush=True)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
