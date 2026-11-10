#!/usr/bin/env python3
"""Source-level regression for approved SkylineDepth wedges (not Studio QA).

The eight 3D placements on each five-variant map must use creator-approved
sculptures already loaded by the existing server import, never invented IDs.
"""
import json
import math
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
KIT=(ROOT/"src/client/ApprovedSkylineDepthMeshKit.lua").read_text()
LOD=(ROOT/"src/client/scenery-lod.client.lua").read_text()
BUILDER=(ROOT/"src/server/MapBuilder.lua").read_text()
SERVER=(ROOT/"src/server/PremiumExteriorTowerAssets.lua").read_text()
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
MODELS={m["name"]:m for m in REG["models"]}
ASSETS={27:"97864559770371",30:"112172520488996"}

for height,asset in ASSETS.items():
    row=MODELS[f"exterior_tower_{height}"]
    assert row["asset_id"]==asset and row["moderation"]=="Approved",row
    assert f"[{height}] = {asset}" in KIT
    assert f"height = {height}, id = {asset}" in SERVER
assert "ApprovedExteriorTowerTemplates" in KIT
for guard in ('"OwnerVerified"','"OriginalExteriorTower3D"',
              '"Original3DAssetId"','"CosmeticOnly"',
              'part:IsA("MeshPart")','count ~= 7',
              'body:IsA("WedgePart")','body.Anchored',
              'body.CanCollide','body.CanTouch','body.CanQuery',
              'source.DescendantRemoving:Connect',
              'clone.DescendantRemoving:Connect',
              'part.CanCollide = false','part.CanTouch = false',
              'part.CanQuery = false','body.Transparency = 1',
              'body.Transparency = entry.original',
              'owner:GetAttribute("ChaosDistantScenery")',
              'variant == "Towers" and 31 or 22'):
    assert guard in KIT,guard
for line in ('SkylineDepth','DistantRoofMass','DistantAerial',
             'local height = (variant.Id == "Towers" and 31 or 22)',
             '16 + layer * 10','layer == 1 and -17 or 19'):
    assert line in BUILDER,line
assert 'ApprovedSkylineDepthMeshKit = require(' in LOD
assert 'ApprovedSkylineDepthMeshKit.sync(arena,cameraPoint,' in LOD
assert 'LocalApprovedSkylineDepthModelCount' in LOD
assert 'LocalSkylineDepthPrimitivesReplaced' in LOD
assert "AssetService" not in KIT
for forbidden in ("RenderStepped","Heartbeat","LoadAssetAsync",
                  "RemoteEvent","RemoteFunction","CanCollide = true"):
    assert forbidden not in KIT,forbidden
assert "Low={cap=0,distance=0}" in KIT
assert "Medium={cap=2,distance=425}" in KIT
assert "High={cap=4,distance=570}" in KIT
assert "if stress >= 2 then cap = 0 end" in KIT
assert "if tier == \"High\" and touch then cap = 3 end" in KIT
assert KIT.index("clone.Parent = bucket")<KIT.index("body.Transparency = 1")
assert "DistantAerial.Transparency" not in KIT
assert "aerial.Transparency" not in KIT

# All eight exterior depth positions must be eligible for a genuine,
# undistorted uniform scale within the stated Android-safe bounding budget.
for variant in ("Classic","Towers","Crossroads","Orbital","Harbor"):
    count=0
    for direction in range(1,5):
        for layer in (1,2):
            height=(31 if variant=="Towers" else 22)+5*layer+3*((direction+layer)%3)
            source=27 if height<=30 else 30
            sizeX=10+3*layer
            scale=min(height/(source+1.2),
                      sizeX*1.35/11.84,8*2/9.84)
            fittedY=(source+1.2)*scale
            assert .80<=scale<=1.60,(variant,direction,layer,scale)
            assert fittedY>=height*.80,(variant,direction,layer,fittedY)
            assert fittedY<=height*1.07
            assert 11.84*scale<=sizeX*1.37
            assert 9.84*scale<=8*2.03
            count+=1
    assert count==8
    print(f"PASS {variant}: 8 authentic SkylineDepth candidates; LOD remains capped")

print("PASS approved IDs, exact native guards, safe rollback, budgets,")
print("PASS old aerial signals untouched, no new assets or frame sampler")
