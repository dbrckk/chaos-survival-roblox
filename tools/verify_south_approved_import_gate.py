#!/usr/bin/env python3
"""Prove all eight South 3D loaders use the same exception-safe permit."""
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
assert "while busy do task.wait(.2) end" in gate
assert "busy=true" in gate and "busy=false" in gate
assert "local ok,result=pcall(service.LoadAssetAsync,service,assetId)" in gate
assert gate.index("busy=false",gate.index("local ok,result=pcall"))<gate.index(
    "if not ok then error(result,0) end")
assert "function Gate.snapshot()" in gate
assert "InFlight=busy and 1 or 0" in gate
assert "PeakInFlight=peak" in gate
assert "Waiting=waiting" in gate
assert "Completed=completed" in gate and "Failed=failures" in gate
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
print("NOTE Roblox engine runtime/network behavior not measured in source CI")
