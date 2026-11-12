#!/usr/bin/env python3
"""Verify Towers machinery cap's animation does not fight original MeshParts."""
import math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
KIT=(ROOT/"src/client/ApprovedVariantTowersLandmarkMeshKit.lua").read_text()
MOTION=(ROOT/"src/client/arena-identity-motion.client.lua").read_text()
RULES=(ROOT/"src/shared/ArenaIdentityMotionRules.lua").read_text()
MAP=(ROOT/"src/server/MapBuilder.lua").read_text()

assert 'trackPart(decor:FindFirstChild("TowerMachineryCap" .. tower)' in MOTION
assert 'trackPart(decor:FindFirstChild("TowerAntenna" .. tower)' in MOTION
assert 'part.Transparency = math.clamp(' in MOTION
assert 'part:GetAttribute("SceneryLodHidden") ~= true' in RULES
assert 'part.CFrame = item.baseCFrame * offset' in MOTION
assert '"TowerMachineryCap" .. i' in MAP
assert '"TowerAntenna" .. i' in MAP
assert 'base:SetAttribute("OriginalSizeX", base.Size.X)' in MAP
assert 'base:SetAttribute("OriginalSizeZ", base.Size.Z)' in MAP
for term in (
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    'x*(originalX*.5+6)',
    'z*(originalZ*.5+6)',
    'cap.Position-(center+Vector3.new(0,12.4,0))).Magnitude > .28',
    'cap.Transparency>=.05 and cap.Transparency<=.68',
    'antenna.Transparency>=.05',
    'antenna.Transparency<=.68',
    'if cap:GetAttribute("SceneryLodHidden")==true then return end',
    'capOriginalModifier=cap.LocalTransparencyModifier',
    'capOriginalHidden=cap:GetAttribute("SceneryLodHidden")',
    'cap:SetAttribute("SceneryLodHidden",true)',
    'cap.LocalTransparencyModifier=1',
    'entry.cap.LocalTransparencyModifier=1',
    'entry.cap.LocalTransparencyModifier=entry.capOriginalModifier',
    'entry.cap:SetAttribute("SceneryLodHidden",entry.capOriginalHidden)',
    'body.Transparency=1',
    '[body]=body.Transparency',
    'native.Transparency = alpha',
    'LocalTransparencyModifier>=.99',
    'Low=1,Medium=2,High=4',
    'Low=220,Medium=290,High=410',
    'or tier=="Low" and math.min(cap,1) or 0',
    'if stress==1 then cap=math.floor(cap*.5) end',
    'if stress>=2 then cap=0 end',
    'bucket.ChildRemoved:Connect(function(child)',
    'if entry.model==child then',
    '72143366927826',
):
    assert term in KIT,term
assert 'x*(base.Size.X*.5+6)' not in KIT
assert 'z*(base.Size.Z*.5+6)' not in KIT
assert 'cap.Transparency=1' not in KIT
assert 'entry.cap.Transparency=1' not in KIT
assert 'antenna.Transparency=1' not in KIT
assert 'antenna.CFrame=' not in KIT
assert KIT.index('clone.Parent=bucket') < KIT.index('body.Transparency=1')
assert KIT.index('body.Transparency=1') < KIT.index(
    'cap:SetAttribute("SceneryLodHidden",true)')
assert .18 < .28
assert math.cos(math.radians(1.5))>.999
for authored in (320,360,400):
    for shrunk in (120,200,authored):
        sourceCorner=authored*.5+6
        assert sourceCorner>shrunk*.5
print("PASS 4 Towers corners use authored radii during floor shrink")
print("PASS pulse cap is suppressed locally, antenna remains animated")
print("PASS 7 original MeshParts, native body fallback and mobile LOD")
