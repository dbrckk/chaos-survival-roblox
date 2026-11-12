#!/usr/bin/env python3
"""Source-level regression gate for all three approved South Towers LOD kits.

Does not replace Roblox Studio runtime verification.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
specs=[
 ("ApprovedSouthTowersSkytransferMeshKit.lua","120959181274080",
  ["SkyTransfer","UnderslungLift"],2),
 ("ApprovedSouthTowersLiftTwinsMeshKit.lua","114886409893890",
  ["WestLift","EastLift","WestCrown","EastCrown"],4),
 ("ApprovedSouthTowersFinishingMeshKit.lua","79666240429608",
  ["Foundation","FloorInset","WestLiftRail","EastLiftRail",
   "WestSuspension","EastSuspension","TransferSignal"],7),
]
all_targets=[name for _,_,names,_ in specs for name in names]
assert len(all_targets)==13 and len(set(all_targets))==13,all_targets
expected_targets={
    "Foundation","FloorInset","WestLift","EastLift",
    "WestCrown","EastCrown","WestLiftRail","EastLiftRail",
    "WestSuspension","EastSuspension","SkyTransfer",
    "UnderslungLift","TransferSignal",
}
assert set(all_targets)==expected_targets,(set(all_targets)^expected_targets)
for filename,asset,names,count in specs:
    source=(root/"src/client"/filename).read_text()
    assert "local MODEL_ID="+asset in source,filename
    restore=source.split("local function restore()",1)[1].split("local function clear()",1)[0]
    # SkyTransfer uses only Parts; the lift-twin kit must also restore WedgeParts.
    expected_class="BasePart" if count>=4 else "Part"
    assert 'part:IsA("'+expected_class+'")' in restore,filename
    assert 'part.Transparency=alpha' in source,filename
    assert 'native.Transparency=1' in source,filename
    assert 'model.Parent=bucket' in source,filename
    assert source.index("model.Parent=bucket")<source.index("native.Transparency=1"),filename
    assert "currentNatives or #currentNatives~="+str(count) in source,filename
    assert all('"'+name+'"' in source for name in names),filename
    assert 'if cap==0 or not cameraReady' in source,filename
    assert "RenderStepped" not in source and "Heartbeat" not in source,filename
    assert "part.CanCollide=false" in source,filename
    assert "Original3DAssetId" in source and "OwnerVerified" in source,filename
    assert "SouthHorizonMonument" in source and '"Towers"' in source,filename
    assert "source.DescendantRemoving:Connect" in source,filename
    print("PASS",filename,asset,count,"native fallback")
# South Towers' three authentic models target 13 disjoint block/wedge
# instances and can coexist ONLY within their own independent caps.
# In Low the newly enabled finishing has a much smaller trigger range
# than the previously validated bridge and lift twins. Pressure 1
# restores all 13 native parts; the total source bound is 3 x 7.
low_ranges={
    "ApprovedSouthTowersSkytransferMeshKit.lua":290,
    "ApprovedSouthTowersLiftTwinsMeshKit.lua":152,
    "ApprovedSouthTowersFinishingMeshKit.lua":106,
}
assert len(low_ranges)==len(specs)==3
for filename,distance in low_ranges.items():
    source=(root/"src/client"/filename).read_text()
    assert "local QUALITIES={Low=1,Medium=1,High=1}" in source,filename
    assert "local DISTANCE={Low="+str(distance)+",Medium=420,High=580}" in source,filename
    assert "local RETENTION=26" in source,filename
    assert 'if stress==1 and tier~="High" then cap=0 end' in source,filename
    assert 'if stress>=2 then cap=0 end' in source,filename
    assert 'if n~=7 then return nil end' in source,filename
    assert 'if #pieces~=7 then' in source,filename
    assert 'source:GetAttribute("CosmeticOnly")~=true' in source,filename
    assert 'source:GetAttribute("OwnerVerified")~=true' in source,filename
    assert 'source:GetAttribute("Original3DAssetId")~=MODEL_ID' in source,filename
    assert 'part.CanTouch=false' in source and 'part.CanQuery=false' in source,filename
    assert "source.DescendantRemoving:Connect" in source,filename
    print("PASS verified South Towers Low",filename,distance,
          "studs, 7 MeshParts, native fallback at pressure 1")
assert sum(count for _,_,_,count in specs)==13
assert 7*len(specs)==21
print("PASS South Towers 13/13 primitive targets disjoint; maximum 21",
      "creator-approved cosmetic MeshParts across three owners on healthy Low")

for p in ("src/server/init.server.lua","src/client/scenery-lod.client.lua",
          "src/shared/VisualBudgetRules.lua"):
    text=(root/p).read_text()
    assert "SouthTowersLiftTwins" in text and "SouthTowersFinishing" in text,p
print("PASS shared LOD wiring")

import json
registry=json.loads((root/"assets/source/roblox-asset-registry.json").read_text())
models={model["name"]:model for model in registry["models"]}
assert models["south_towers_forged_finishing"]["asset_id"]=="79666240429608"
assert models["south_towers_forged_finishing"]["moderation"]=="Approved"
assert models["south_towers_forged_finishing"]["workflow_run_id"]==42840287655
print("PASS full South Towers 13/13 authored primitive coverage, disjoint LOD targets and registry")
