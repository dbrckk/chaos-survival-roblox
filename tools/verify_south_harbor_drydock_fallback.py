#!/usr/bin/env python3
"""Regression gate for verified south Harbor cosmetic mesh replacement.

This does not constitute Roblox Studio/Android rendering validation.
"""
import json
import re
from pathlib import Path

root=Path(__file__).resolve().parents[1]
client=(root/"src/client/ApprovedSouthHarborDrydockMeshKit.lua").read_text()
server=(root/"src/server/PremiumSouthHarborDrydockAssets.lua").read_text()
builder=(root/"src/server/MapBuilder.lua").read_text()
models={m["name"]:m for m in json.loads(
    (root/"assets/source/roblox-asset-registry.json").read_text())["models"]}
asset=models["south_harbor_sculpted_drydock"]
assert asset["asset_id"]=="125428569657840"
assert asset["moderation"]=="Approved"
assert asset["workflow_run_id"]==42847077638
assert "local MODEL_ID=125428569657840" in client
assert "local APPROVED_ID=125428569657840" in server
assert "OriginalSouthHarborSculptedDrydock3D" in client
assert "OriginalSouthHarborSculptedDrydock3D" in server
assert "OriginalMeshScenery.sanitize(raw)" in server
assert "if count~=7 then return false end" in server
print("PASS owner-authenticated 7-MeshPart original drydock and asset bounds")

expected={
    "Foundation":"Part","FloorInset":"Part",
    "WestQuayColumn":"Part","EastQuayColumn":"Part",
    "WestQuayCargo":"Part","EastQuayCargo":"Part",
    "WestContainerHoist":"Part","EastContainerHoist":"Part",
    "WestQuayRig":"WedgePart","EastQuayRig":"WedgePart",
    "HarborLightshipBridge":"Part","HarborSignalCab":"Part",
    "HarborStormLens":"Part","HarborStormBeacon":"Part",
}
context=client.split("local function context(arena)",1)[1].split("local function fit(",1)[0]
specs=context.split("local specs={",1)[1].split("\n    }",1)[0]
pairs=re.findall(r'\{"([^"]+)",\s*"(Part|WedgePart)"',specs)
assert len(pairs)==14,(len(pairs),pairs)
assert dict(pairs)==expected,pairs
assert len(set(k for k,v in pairs))==14
assert all('"'+name+'"' in builder for name in expected)
assert 'arena:GetAttribute("VariantId")~="Harbor"' in context
assert 'owner:GetAttribute("SignatureVariant")~="Harbor"' in context
assert 'part:IsA(spec[2])' in context
assert 'part.CFrame.LookVector:Dot(expected.LookVector)' in context
assert 'part.CFrame.UpVector:Dot(expected.UpVector)' in context
assert "part.Shape~=Enum.PartType.Block" in context
assert "or not part.Anchored or part.CanCollide" in context
print("PASS exact 14 southern Harbor Part/WedgePart native targets and transform guard")

restore=client.split("local function restore()",1)[1].split("local function clear()",1)[0]
assert 'part:IsA("BasePart")' in restore
assert 'part.Transparency=alpha' in restore
assert 'part.Transparency==1' in restore
assert 'model.Parent=bucket' in client
assert 'native.Transparency=1' in client
assert client.index("model.Parent=bucket")<client.index("native.Transparency=1")
assert "#currentNatives~=14" in client
assert 'if cap==0 or not cameraReady' in client
assert 'source.DescendantRemoving:Connect' in client
assert "RenderStepped" not in client and "Heartbeat" not in client
assert 'part.CanCollide=false' in client
assert 'part.CanTouch=false' in client and 'part.CanQuery=false' in client
print("PASS mount-before-hide, WedgePart-native restoration and no new frame loop")

for path in ("src/server/init.server.lua","src/client/scenery-lod.client.lua",
             "src/shared/VisualBudgetRules.lua"):
    assert "SouthHarborDrydock" in (root/path).read_text(),path
# Both external Harbor landmarks are anchored to the original server
# footprint, not the shrinking live survival floor. Their real native
# positions are fixed while only Base.Size changes during disasters.
north=(root/"src/client/ApprovedHarborSignatureGantryMeshKit.lua").read_text()
for name,code in (("north",north),("south",client)):
    assert 'local function authenticBase(base,arena)' in code,name
    assert 'base:GetAttribute("OriginalSizeX")' in code,name
    assert 'base:GetAttribute("OriginalSizeZ")' in code,name
    assert 'base.Size.X>0 and base.Size.Z>0' in code,name
    assert 'base.Size.X<=sx+.2 and base.Size.Z<=sz+.2' in code,name
    assert 'if not authenticBase(base,arena)' in code,name
    assert 'if not authenticBase(base,arena) then restore() end' in code,name
    assert 'base.Size.X<318 or base.Size.Z<318' not in code,name
    for signal in ('base:GetPropertyChangedSignal("Size")',
                   'base:GetPropertyChangedSignal("CanCollide")',
                   'base.AncestryChanged:Connect'):
        assert signal in code,(name,signal)
assert 'originalX*.24,base.Size.Y*.5+43.5,-(originalZ*.5+66)' in north
assert '-originalX*.20,base.Size.Y*.5,originalZ*.5+54' in client
assert 'or (stress==1 and tier~="High")' in north
assert 'if stress==1 and tier~="High" then cap=0 end' in client
assert 'local QUALITY={Low=1,Medium=1,High=1}' in north
assert 'local QUALITIES={Low=1,Medium=1,High=1}' in client
assert 'local MODEL_ID=124368710235343' in north
assert '124368710235343' in [m['asset_id'] for m in models.values() if m.get('moderation')=='Approved']
assert 'part.CanCollide=false' in north
assert 'part.CanCollide=false' in client
assert 'model.Parent=bucket' in north
assert 'model.Parent=bucket' in client
print("PASS both Harbor offshore approved Models are shrink-safe, pressure-adaptive and restore natives")
print("PASS server loader, shared scenery sampling, LOD and visual budget")
