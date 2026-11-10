#!/usr/bin/env python3
"""Exact-release contract: real owner-approved original Models + Lest suite.

This source gate is intentionally not a substitute for Rojo build or
Roblox Open Cloud engine execution. Those run on exact post-merge SHA.
"""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[1]
registry=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
workflow=(ROOT/".github/workflows/ci.yml").read_text()
start=workflow.index("      - name: Validate Roblox-approved original asset registry")
end=workflow.index("      - name:",start+20)
section=workflow[start:end]
head=section[:section.index('assert {m["name"] for m in models} == (')]
groups=re.findall(r"(\w+_names)\s*=\s*\{([\s\S]*?)\}",head)
assert groups,len(groups)
named={}
for group,body in groups:
    named[group]=set(re.findall(r'"([^"]+)"',body))
assert "premium_extension_names" in named
assert len(named["premium_extension_names"])==39
assert len(named)==17,(len(named),sorted(named))
expected=set().union(*named.values())
models=registry["models"]
actual={x["name"] for x in models}
assert len(models)==101,(len(models),"approved source count")
assert len(expected)==len(models)==len(actual),(len(expected),len(models),len(actual))
assert expected==actual,("Missing",sorted(actual-expected),"Phantom",sorted(expected-actual))
ids=[x["asset_id"] for x in models]
assert len(set(ids))==101
for model in models:
    assert model["moderation"]=="Approved"
    assert model["asset_id"].isdecimal() and int(model["asset_id"])>0
    assert type(model["workflow_run_id"]) is int and model["workflow_run_id"]>0
    for attr in ("source","source_materials"):
        path=Path(model[attr])
        if not (ROOT/path).is_file():
            # Seven legacy OBJ files are deterministic outputs of the
            # FIRST official Build Validation step, not committed blobs.
            # Preserve exact allowed names rather than accepting arbitrary
            # unavailable creator models.
            generated = {
                "premium_ground_tile", "district_observatory",
                "district_freight", "district_turbine",
                "district_aerial", "skyfleet_carrier",
                "underdeck_chassis",
            }
            assert attr=="source" and model["name"] in generated, (
                model["name"],attr,path)
            assert path.is_relative_to("assets/source") and path.suffix==".obj"
            producer = (
                "tools/generate_premium_ground_tile.py"
                if model["name"]=="premium_ground_tile" else
                "tools/generate_district_profile_meshes.py"
                if model["name"].startswith("district_") else
                "tools/generate_original_skyfleet_carrier.py"
                if model["name"]=="skyfleet_carrier" else
                "tools/generate_original_underdeck_chassis.py"
            )
            assert (ROOT/producer).is_file(),producer
            assert producer in workflow,producer
        if attr=="source" and model["name"] in named["premium_extension_names"]:
            assert path.is_relative_to("tools")
            assert path.name.startswith("generate_original_")
        if attr=="source_materials":
            assert path.is_relative_to("assets/source")
assert "assert len(models) == 101" in section
assert '| harbor_original_names | premium_extension_names)' in section
assert 'model["name"] in premium_extension_names' in section
assert 'tools/verify_premium_approved_asset_import_queue.py' in section
assert 'assert "AssetService.LoadAssetAsync" in source' in section
assert 'assert "GlobalApprovedImportGate.load" in gate_source' in section
assert '"GlobalApprovedImportGate.load"' in section
assert 'assert len(models) == 62' not in section

engine=(ROOT/"tests/engine/premium-import-diagnostics.spec.luau").read_text()
assert engine.strip().endswith("return nil"),"Lest engine bundle requires terminal return nil"
assert engine.count('describe("Premium 3D Model import diagnostics"')==1
cloud=(ROOT/".github/workflows/roblox-cloud-test.yml").read_text()
all_specs={p.relative_to(ROOT).as_posix() for p in (ROOT/"tests/engine").glob("*.spec.luau")}
listed=re.findall(r'"(tests/engine/[^"*]+\.spec\.luau)"',cloud)
assert len(all_specs)==86,(len(all_specs),"unexpected engine spec count")
assert len(set(listed))==86 and len(listed)==86
assert set(listed)==all_specs,("Missing",all_specs-set(listed))
print("PASS 101 real Approved original Models and all 39 new reproducible sources")
print("PASS release Build Validation uses current 2-permit global importer contract")
print("PASS all 86 engine specs listed exactly once; Lest diagnostic test is valid")
