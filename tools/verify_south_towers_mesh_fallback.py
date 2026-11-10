#!/usr/bin/env python3
"""Source-level regression gate for the two approved South Towers LOD kits.

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
    print("PASS",filename,asset,count,"native fallback")
for p in ("src/server/init.server.lua","src/client/scenery-lod.client.lua",
          "src/shared/VisualBudgetRules.lua"):
    assert "SouthTowersLiftTwins" in (root/p).read_text(),p
print("PASS shared LOD wiring")
