#!/usr/bin/env python3
"""Regression gate for verified south Classic cosmetic mesh replacement.

This does not constitute Roblox Studio/Android rendering validation.
"""
import json
import re
from pathlib import Path

root=Path(__file__).resolve().parents[1]
client=(root/"src/client/ApprovedSouthClassicObservatoryMeshKit.lua").read_text()
server=(root/"src/server/PremiumSouthClassicObservatoryAssets.lua").read_text()
builder=(root/"src/server/MapBuilder.lua").read_text()
models={m["name"]:m for m in json.loads(
    (root/"assets/source/roblox-asset-registry.json").read_text())["models"]}
asset=models["south_classic_sculpted_observatory"]
assert asset["asset_id"]=="105516749001927"
assert asset["moderation"]=="Approved"
assert asset["workflow_run_id"]==42849092927
assert "local MODEL_ID=105516749001927" in client
assert "local APPROVED_ID=105516749001927" in server
assert "OriginalSouthClassicSculptedObservatory3D" in client
assert "OriginalSouthClassicSculptedObservatory3D" in server
assert "OriginalMeshScenery.sanitize(raw)" in server
assert "if count~=7 then return false end" in server
print("PASS owner-authenticated 7-MeshPart original observatory and asset bounds")

expected={
    "Foundation":"Part","FloorInset":"Part",
    "WestRadarPylon":"Part","EastRadarPylon":"Part",
    "WestRadarDish":"Part","EastRadarDish":"Part",
    "WestReceiver":"Part","EastReceiver":"Part",
    "WestServiceBrace":"Part","EastServiceBrace":"Part",
    "ObservatoryBridge":"Part","ObservatoryCabin":"Part",
    "ObservatoryGlass":"Part",
}
context=client.split("local function context(arena)",1)[1].split("local function fit(",1)[0]
specs=context.split("local specs={",1)[1].split("\n    }",1)[0]
pairs=re.findall(r'\{"([^"]+)",\s*"(Part|WedgePart)"',specs)
assert len(pairs)==13,(len(pairs),pairs)
assert dict(pairs)==expected,pairs
assert len(set(k for k,v in pairs))==13
assert all('"'+name+'"' in builder for name in expected)
assert 'arena:GetAttribute("VariantId")~="Classic"' in context
assert 'owner:GetAttribute("SignatureVariant")~="Classic"' in context
assert 'ExteriorDetailGeometry.monumentFootprint(part,owner,spec[2],shape)' in context
assert 'pose.LookVector:Dot(expected.LookVector)' in context
assert 'pose.UpVector:Dot(expected.UpVector)' in context
assert "Enum.PartType.Cylinder" in context
assert '"WestRadarDish"' in context and '"EastRadarDish"' in context
assert "Enum.PartType.Block" in context
geometry=(root/"src/client/ExteriorDetailGeometry.lua").read_text()
assert 'or not part.Anchored or part.CanCollide or part.CanTouch or part.CanQuery' in geometry
assert 'part.Shape ~= (fallbackShape or Enum.PartType.Block)' in geometry
assert 'part:GetAttribute("Original3DAssetId") ~= assetId' in geometry
print("PASS exact 13 Classic targets with approved meshes and Part/Cylinder fallback")

restore=client.split("local function restore()",1)[1].split("local function clear()",1)[0]
assert 'part:IsA("BasePart")' in restore
assert 'part.Transparency=alpha' in restore
assert 'part.Transparency==1' in restore
assert 'model.Parent=bucket' in client
assert 'native.Transparency=1' in client
assert client.index("model.Parent=bucket")<client.index("native.Transparency=1")
assert "#currentNatives~=13" in client
assert 'if cap==0 or not cameraReady' in client
assert 'source.DescendantRemoving:Connect' in client
assert "RenderStepped" not in client and "Heartbeat" not in client
assert 'part.CanCollide=false' in client
assert 'part.CanTouch=false' in client and 'part.CanQuery=false' in client
print("PASS mount-before-hide, Cylinder-native restoration and no new frame loop")

for path in ("src/server/init.server.lua","src/client/scenery-lod.client.lua",
             "src/shared/VisualBudgetRules.lua"):
    assert "SouthClassicObservatory" in (root/path).read_text(),path
print("PASS server loader, shared scenery sampling, LOD and visual budget")
