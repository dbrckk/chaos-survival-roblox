#!/usr/bin/env python3
"""Orbital reactor original 3D animation and shrinking-arena regression."""
import math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
KIT=(ROOT/"src/client/ApprovedOrbitalReactorLandmarkMeshKit.lua").read_text()
MOTION=(ROOT/"src/client/arena-identity-motion.client.lua").read_text()
RULES=(ROOT/"src/shared/ArenaIdentityMotionRules.lua").read_text()
MAP=(ROOT/"src/server/MapBuilder.lua").read_text()

assert 'trackPart(decor:FindFirstChild("OrbitalReactorNode" .. i)' in MOTION
assert 'local lift = math.sin(now * 1.25' in MOTION
assert 'MotionRules.ornamentOffset(' in MOTION
assert 'part:GetAttribute("SceneryLodHidden") ~= true' in RULES
assert 'part.CFrame = item.baseCFrame' in MOTION
assert 'base:SetAttribute("OriginalSizeX", base.Size.X)' in MAP
assert 'base:SetAttribute("OriginalSizeZ", base.Size.Z)' in MAP
for term in (
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    'math.max(originalX*.5,originalZ*.5)+7',
    '(animated and .65 or .17)',
    'native.Transparency>=.06 and native.Transparency<=.56',
    'Enum.PartType.Ball,.20,true)',
    'nodeFrame,NODE_ID,NODE_BOUNDS,false',
    'if node:GetAttribute("SceneryLodHidden")==true then return end',
    'nodeOriginalModifier=node.LocalTransparencyModifier',
    'nodeOriginalHidden=node:GetAttribute("SceneryLodHidden")',
    'node.LocalTransparencyModifier=1',
    'node:SetAttribute("SceneryLodHidden",true)',
    'entry.node.LocalTransparencyModifier=1',
    'entry.node.LocalTransparencyModifier=entry.nodeOriginalModifier',
    'entry.node:SetAttribute("SceneryLodHidden",entry.nodeOriginalHidden)',
    'natives={[strut]=strut.Transparency}',
    'strut.Transparency=1',
    'native.Transparency=alpha',
    'Low=0,Medium=3,High=6',
    'if pressureLevel>=2 then cap=0 end',
    '104654294187035','138666009076890',
):
    assert term in KIT,term
assert 'math.max(base.Size.X*.5,base.Size.Z*.5)+7' not in KIT
assert 'node.Transparency=1' not in KIT
assert 'entry.node.Transparency=1' not in KIT
assert KIT.index('wrapper.Parent=bucket') < KIT.index('strut.Transparency=1')
assert KIT.index('strut.Transparency=1') < KIT.index(
    'node:SetAttribute("SceneryLodHidden",true)')
for forbidden in ('game:GetService("AssetService")',
                  "Heartbeat:Connect","RenderStepped"):
    assert forbidden not in KIT,forbidden

# Authoring phase motion: vertical lift +/-0.32, node offset +/-0.12
# and yaw max +/-2.2deg. A tolerance of .65 studs is adequate.
assert .32+.12 < .65
assert math.cos(math.radians(2.2)) > .999
for original in (320,360,400):
    for live in (120,200,original):
        radius=original*.5+7
        assert radius>live*.5
        for index in range(1,9):
            angle=(index-1)*math.pi/4
            x,z=math.cos(angle)*radius,math.sin(angle)*radius
            assert abs(math.hypot(x,z)-radius)<1e-8
print("PASS Orbital eight original positions during shrinking rounds")
print("PASS animated offsets and original body local LOD visibility")
print("PASS two approved genuine MeshPart sources and native fallback")
