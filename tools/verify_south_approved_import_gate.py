#!/usr/bin/env python3
"""Audit South 3D imports and the approved fallback coverage."""
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

geometry=(ROOT/"src/shared/SouthMonumentGeometry.lua").read_text()
profiles=dict(re.findall(r'(\w+) = "(\w+)"', geometry.split("local assets =",1)[0]))
arc_count=int(re.search(r"for index = 1, (\d+) do", geometry)[1])
profiles.update({f"ObservationArc{i}": "bevel" for i in range(1,arc_count+1)})
asset_ids=set(re.findall(r"= (\d{9,})\b", geometry))
models=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())["models"]
approved={model["asset_id"] for model in models if model.get("moderation")=="Approved"}
assert len(asset_ids)==10 and asset_ids <= approved,asset_ids-approved

builder=(SERVER/"MapBuilder.lua").read_text()
monument=builder.split("local function addSouthHorizonMonument",1)[1].split("-- The four corner groups",1)[0]
foundation,orbital,towers,crossroads,harbor,classic=re.split(
    r'^    (?:(?:if|elseif) variant.Id == "\w+" then|else)$', monument, flags=re.M)
def targets(section):
    calls=re.findall(r'^\s*piece\(\s*(?:side < 0 and "(\w+)" or "(\w+)"|"(\w+)")', section, re.M)
    names={name for call in calls for name in call if name}
    if "ObservationArc" in names:
        names.remove("ObservationArc")
        names.update(f"ObservationArc{i}" for i in range(1,arc_count+1))
    return names

shared_targets=targets(foundation)
all_targets=set()
for name,section,count in (("Classic",classic,13),("Towers",towers,13),
                           ("Crossroads",crossroads,13),("Orbital",orbital,20),
                           ("Harbor",harbor,14)):
    names=shared_targets | targets(section)
    assert len(names)==count and names <= profiles.keys(),(name,names-profiles.keys())
    all_targets.update(names)
assert all_targets==profiles.keys(),(all_targets ^ profiles.keys())
assert 'template and template.MeshId ~= ""' in monument
assert "SouthMonumentGeometry.assetId(profile, variant.Id)" in monument
assert "if shape and item:IsA(\"Part\") then item.Shape = shape end" in monument
print("PASS 73 South fallback slots use profiles from 10 approved asset IDs")
print("NOTE Roblox engine runtime/network behavior not measured in source CI")
