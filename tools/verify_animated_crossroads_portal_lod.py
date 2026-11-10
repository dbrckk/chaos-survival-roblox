#!/usr/bin/env python3
"""Crossroads animated gate / seven-MeshPart source client LOD contract.

The phase animation owns the native rail's CFrame and Transparency.
LocalTransparencyModifier + SceneryLodHidden must instead own the
local view while the original owner-approved mesh is mounted.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
KIT=(ROOT/"src/client/ApprovedCrossroadsEntrancePortalMeshKit.lua").read_text()
MOTION=(ROOT/"src/client/arena-identity-motion.client.lua").read_text()
RULES=(ROOT/"src/shared/ArenaIdentityMotionRules.lua").read_text()
OLD=(ROOT/"tools/verify_crossroads_entrance_portal_runtime.py").read_text()

assert 'trackPart(decor:FindFirstChild("CrossroadGate" .. i)' in MOTION
assert 'part.Transparency = math.clamp(' in MOTION
assert 'MotionRules.shouldUpdate(part)' in MOTION
assert 'part:GetAttribute("SceneryLodHidden") ~= true' in RULES
assert 'if not MotionRules.shouldUpdate(part) then' in MOTION
assert 'MotionRules.restorePose(part, item)' in MOTION
assert 'local function exactPart(part,decor,name,size,frame,alpha,animated)' in KIT
assert 'railSize,frame,.18,true)' in KIT
assert 'part.Transparency>=.04 and part.Transparency<=.66' in KIT
assert 'rail:GetAttribute("SceneryLodHidden")==true then return end' in KIT
assert 'railOriginalModifier=rail.LocalTransparencyModifier' in KIT
assert 'railOriginalHidden=rail:GetAttribute("SceneryLodHidden")' in KIT
assert 'rail.LocalTransparencyModifier=1' in KIT
assert 'rail:SetAttribute("SceneryLodHidden",true)' in KIT
assert 'rail.LocalTransparencyModifier=entry.railOriginalModifier' in KIT
assert 'rail:SetAttribute("SceneryLodHidden",entry.railOriginalHidden)' in KIT
assert 'entry.rail.LocalTransparencyModifier=1' in KIT
assert 'entry.rail:GetAttribute("SceneryLodHidden")==true' in KIT
assert 'local natives={}' in KIT
assert 'for _,post in ipairs(posts) do natives[post]=post.Transparency end' in KIT
assert 'for native in pairs(natives) do native.Transparency=1 end' in KIT
assert 'for native,alpha in pairs(entry.nativeAlpha) do' in KIT
assert 'native.Transparency=alpha' in KIT
assert 'if #meshParts~=7 then model:Destroy();return end' in KIT
assert KIT.index('model.Parent=bucket') < KIT.index(
    'rail:SetAttribute("SceneryLodHidden",true)')
assert KIT.index('for native in pairs(natives) do native.Transparency=1 end') < KIT.index(
    'rail:SetAttribute("SceneryLodHidden",true)')
assert 'rail.Transparency=1' not in KIT
assert 'entry.rail.Transparency=1' not in KIT
assert 'rail.CFrame=' not in KIT
assert 'if stress>=2 then cap=0 end' in KIT
assert 'Low=0,Medium=2,High=4' in KIT
assert '127067628128103' in KIT
assert '"OriginalCrossroadsEntrancePortal3D"' in KIT
assert 'model.Parent=bucket' in KIT
assert '"SceneryLodHidden"' not in OLD  # new regression covers the motion fix
print("PASS full Crossroads ring four gateways / live pulse animator contract")
print("PASS animated rail hidden via local modifier, two posts via native alpha")
print("PASS no flash/fighting alpha writes, exact rollback to previous LOD owner")
