#!/usr/bin/env python3
"""Audit South 3D imports and both horizons’ approved fallback coverage."""
import json
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
SERVER=ROOT/"src/server"
gate=(SERVER/"PremiumSouthApprovedImportGate.lua").read_text()
items=[
"PremiumSouthClassicObservatoryAssets",
"PremiumSouthCrossroadsExchangeAssets",
"PremiumSouthHarborDrydockAssets",
"PremiumSouthOrbitalFinishingAssets",
"PremiumSouthTowersFinishingAssets",
"PremiumSouthTowersSkytransferAssets",
"PremiumSouthTowersLiftTwinsAssets",
"PremiumSouthOrbitalObservationRingAssets",
]
assert len(set(items))==8
assert "local busy=false" in gate
assert "while busy do task.wait(.2) end" not in gate
assert 'Instance.new("BindableEvent")' in gate
assert 'signal.Event:Wait()' in gate
assert 'signal:Destroy()' in gate
assert 'local nextWaiter=table.remove(waiting,1)' in gate
assert 'nextWaiter:Fire()' in gate
assert 'local waiting={}' in gate
assert 'function Gate.snapshot()' in gate
assert "busy=true" in gate and "busy=false" in gate
assert 'require("./PremiumApprovedAssetImportGate")' in gate
assert "local ok,result=pcall(GlobalApprovedImportGate.load,service,assetId)" in gate
assert gate.index("release()\n    if not ok then") > gate.index(
    "local ok,result=pcall(GlobalApprovedImportGate.load,service,assetId)")
assert "pcall(service.LoadAssetAsync" not in gate
assert gate.index("release()\n    if not ok then")<gate.index(
    "if not ok then error(result,0) end")
assert "function Gate.snapshot()" in gate
assert "InFlight=busy and 1 or 0" in gate
assert "PeakInFlight=peak" in gate
assert "Waiting=#waiting" in gate
assert "Completed=completed" in gate and "Failed=failures" in gate
assert "TotalWaits=totalWaits" in gate
assert "RemoteEvent" not in gate and "RenderStepped" not in gate
assert "task.spawn" not in gate
for name in items:
    src=(SERVER/(name+".lua")).read_text()
    assert 'require("./PremiumSouthApprovedImportGate")' in src,name
    assert len(re.findall(r"pcall\(SouthImportGate\.load,\s*AssetService,",
                          src))==1,name
    assert "AssetService.LoadAssetAsync" not in src,name
    assert src.count("for attempt=1,3 do")==1,name
    assert "OriginalMeshScenery.sanitize(raw)" in src,name
    assert 'ActiveSignatureSchedule.waitFor(' in src,name
    assert "if count~=7 then return false end" in src,name
print("PASS all 8 Approved South owners use one exception-safe shared permit")
print("PASS no direct South LoadAssetAsync or new per-frame loop")

geometry = (ROOT/"src/shared/HorizonMonumentGeometry.lua").read_text()
models = json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())["models"]
approved = {model["asset_id"] for model in models if model.get("moderation") == "Approved"}

def read_asset_table(name):
    section = geometry.split(f"local {name} = {{", 1)[1].split("\n}", 1)[0]
    ids = dict(re.findall(r"(\w+) = (\d{9,})\b", section))
    assert set(ids.values()) <= approved, set(ids.values()) - approved
    return ids

assets = read_asset_table("assets")
shafts = read_asset_table("shafts")
assert set(shafts) == {"Classic", "Towers", "Crossroads", "Orbital", "Harbor"}

builder = (SERVER/"MapBuilder.lua").read_text()
piece_builder = builder.split("local function horizonPieceBuilder",1)[1].split("\nend",1)[0]
assert 'template and template.MeshId ~= ""' in piece_builder
assert "HorizonMonumentGeometry.assetId(profile, variant)" in piece_builder
assert 'if shape and item:IsA("Part") then item.Shape = shape end' in piece_builder


def targets(section, arc, count):
    calls = re.findall(r'^\s*piece\(\s*(?:side < 0 and "(\w+)" or "(\w+)"|"(\w+)")', section, re.M)
    names = {name for call in calls for name in call if name}
    if arc in names:
        names.remove(arc)
        names.update(f"{arc}{i}" for i in range(1, count+1))
    return names


def audit_horizon(label, builder_name, boundary, arc, totals):
    profile_name = label.lower() + "Profiles"
    profile_section = geometry.split(f"local {profile_name} = {{",1)[1].split("local ",1)[0]
    profiles = dict(re.findall(r'(\w+) = "(\w+)"', profile_section))
    arc_count = int(re.search(r"for index = 1, (\d+) do", profile_section)[1])
    arc_profile = re.search(rf'{profile_name}\["{arc}" \.\. index\] = "(\w+)"', profile_section)[1]
    profiles.update({f"{arc}{i}": arc_profile for i in range(1, arc_count+1)})
    monument = builder.split(f"local function {builder_name}",1)[1].split(boundary,1)[0]
    foundation, *sections = re.split(
        r'^    (?:(?:if|elseif) variant.Id == "\w+" then|else)$', monument, flags=re.M)
    shared_targets = targets(foundation, arc, arc_count)
    all_targets = set()
    variants = ("Orbital", "Towers", "Crossroads", "Harbor", "Classic")
    for name, section, total in zip(variants, sections, totals, strict=True):
        names = shared_targets | targets(section, arc, arc_count)
        assert len(names) == total and names <= profiles.keys(), (name, names-profiles.keys())
        all_targets.update(names)
    assert all_targets == profiles.keys(), all_targets ^ profiles.keys()
    used_profiles = set(profiles.values())
    assert used_profiles == {"bevel", "shaft", "roller", "lens", "beam", "cast"}
    assert used_profiles - {"shaft"} <= assets.keys()
    used_ids = {assets[profile] for profile in used_profiles - {"shaft"}} | set(shafts.values())
    assert len(used_ids) == 10
    print(f"PASS {sum(totals)} {label} fallback slots use profiles from {len(used_ids)} approved asset IDs")


audit_horizon("South", "addSouthHorizonMonument", "-- The four corner groups", "ObservationArc",
              (20, 13, 13, 14, 13))
audit_horizon("North", "addArenaSignatureMegastructure", "-- Give the southern horizon", "ReactorArc",
              (24, 13, 13, 16, 14))
print("NOTE Roblox engine runtime/network behavior not measured in source CI")
