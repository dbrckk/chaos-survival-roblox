#!/usr/bin/env python3
"""Static regression: actual approved original skyline roofs and safe fallbacks.

Models are only eligible after their owner-approved Roblox Model is available,
a genuine 7-MeshPart source has been validated and camera/quality allows it.
This is NOT a substitute for Studio / Android visual and FPS tests.
"""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
KIT=(ROOT/"src/client/ApprovedSkylineDepthMeshKit.lua").read_text()
LOD=(ROOT/"src/client/scenery-lod.client.lua").read_text()
BUILDER=(ROOT/"src/server/MapBuilder.lua").read_text()
SERVER=(ROOT/"src/server/PremiumSkylineDepthSculptAssets.lua").read_text()
INIT=(ROOT/"src/server/init.server.lua").read_text()
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
MODELS={model["name"]:model for model in REG["models"]}
SOURCE=MODELS["skyline_depth_sculpt"]
ASSET_ID="80692067525256"
assert SOURCE["asset_id"]==ASSET_ID
assert SOURCE["moderation"]=="Approved"
assert SOURCE["source"]=="tools/generate_original_skyline_depth.py"
assert SOURCE["workflow_run_id"]==42994003806
assert "local SOURCE_ID = "+ASSET_ID in KIT
assert "local ID = "+ASSET_ID in SERVER

for guard in ('"OwnerVerified"','"OriginalSkylineDepthSculpt3D"',
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
              'variant == "Towers" and 31 or 22',
              'SOURCE_SIZE = Vector3.new(11.4,33.95,7.19)',
              'CFrame.Angles(0,yaw,0)',
              'if scale < .72 or scale > 1.55'):
    assert guard in KIT,guard

for guard in ('PremiumApprovedAssetImportGate','ImportGate.load',
              'OriginalMeshScenery.sanitize','OriginalSkylineDepthSculpt3D',
              'ApprovedSkylineDepthSculptTemplates',
              'task.wait(34)','validated(clean)',
              '"LuaSourceContainer"', 'pieces ~= 7',
              'math.abs(size.Y - EXPECTED.Y) <= .45'):
    assert guard in SERVER,guard
assert "require(script.PremiumSkylineDepthSculptAssets)" in INIT
assert "task.defer(PremiumSkylineDepthSculptAssets.start)" in INIT
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
assert 'if tier == "High" and touch then cap = 3 end' in KIT
assert KIT.index("clone.Parent = bucket")<KIT.index("body.Transparency = 1")
assert "DistantAerial.Transparency" not in KIT
assert "aerial.Transparency" not in KIT

# Compute all 8 possible owner silhouettes in each of the 5 variants,
# including 27-stud Classic roofs and 47-stud Towers roofs. Only nearby
# sources are mounted, capped at 2/3/4; Low retains the native wedges.
for variant in ("Classic","Towers","Crossroads","Orbital","Harbor"):
    count=0
    for direction in range(1,5):
        for layer in (1,2):
            height=(31 if variant=="Towers" else 22)+5*layer+3*((direction+layer)%3)
            width=10+3*layer
            scale=min(height/33.95,width*1.35/11.4,8*2/7.19)
            fitted_y=33.95*scale
            assert .72<=scale<=1.55,(variant,direction,layer,scale)
            assert fitted_y>=height*.79,(variant,direction,layer,fitted_y)
            assert fitted_y<=height*1.07
            assert 11.4*scale<=width*1.15
            assert 7.19*scale<=8*1.28
            count+=1
    assert count==8
    print("PASS",variant,"8 approved skyline candidates; LOD cap unchanged")

print("PASS approved original asset, map provenance, no physics or external client fetch")
print("PASS native rollback, 7-MeshPart integrity, camera and Android pressure budgets")
print("LIMIT rendering, streaming, frame times and moderation are engine/device-dependent")
