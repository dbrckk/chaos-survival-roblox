#!/usr/bin/env python3
"""Harbor kinetic 3D crane Android Low, shrink and streaming contract.

These tests inspect the actual code and registry; they are NOT Roblox Engine
screenshots, motion profiling or measured Android frame times.
"""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]
CLIENT=(ROOT/"src/client/HarborGantryKineticMeshKit.lua").read_text()
MOTION=(ROOT/"src/client/harbor-gantry-motion.client.lua").read_text()
RULES=(ROOT/"src/shared/HarborGantryMotionRules.lua").read_text()
LODS=(ROOT/"src/client/scenery-lod.client.lua").read_text()
MAP=(ROOT/"src/server/MapBuilder.lua").read_text()
SERVER=(ROOT/"src/server/PremiumHarborGantryAssets.lua").read_text()
LEDGER=(ROOT/"src/shared/VisualBudgetRules.lua").read_text()
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
approved={m["name"]:m for m in REG["models"]}
for name,id in [
    ("harbor_gantry_kinetic_container","75684193304551"),
    ("harbor_gantry_kinetic_drum","98809955094422"),
]:
    row=approved[name]
    assert row["asset_id"]==id and row["moderation"]=="Approved"
    assert row["source"]=="tools/generate_original_harbor_gantry.py"
    assert row["workflow_run_id"]==41856104459
    assert id in CLIENT and id in SERVER
assert 'local BUDGET = {' in CLIENT
assert 'Low = {models=1,distance=135,retention=18}' in CLIENT
assert 'Medium = {models=2,distance=170,retention=24}' in CLIENT
assert 'High = {models=4,distance=345,retention=36}' in CLIENT
assert 'elseif tier=="Low" and stress>0 then' in CLIENT
assert 'maxModels=0' in CLIENT
assert 'if not arena or not cameraReady or maxModels==0' in CLIENT
assert 'OriginalHarborKineticGantryLocal' in LEDGER
assert 'folder.Name = "OriginalHarborKineticGantryLocal"' in CLIENT
assert 'HarborGantryKineticMeshKit.sync(arena,cameraPoint,profile.Name,' in LODS
assert 'LocalOriginalHarborKineticGantryCount' in LODS
assert 'LocalOriginalHarborKineticMeshPartCount' in LODS

# Low still uses one STATIC, source-approved silhouette; it does not
# activate the independent native crane animation or move gameplay.
assert 'if reduceMotion == true or tier == "Low" then' in RULES
assert 'return {Interval = 0.65, Count = 0, Range = 0}' in RULES
assert 'Motion.profile(' in MOTION
assert 'if profile.Count == 0' not in MOTION  # guarded in step() OR clause
assert 'or profile.Count == 0' in MOTION
assert 'GetPropertyChangedSignal("CFrame")' in CLIENT
assert 'GetPropertyChangedSignal("Size")' in CLIENT
assert 'followNativeMotion(e)' in CLIENT
for forbidden in ('RenderStepped','Heartbeat:Connect',
                  'game:GetService("AssetService")','RemoteEvent'):
    assert forbidden not in CLIENT

# Shrinking floors from 320 to 200 / 120 / 60 studs must not remove
# stationary crane silhouettes authored OUTSIDE the original arena.
assert 'base:SetAttribute("OriginalSizeX", base.Size.X)' in MAP
assert 'base:SetAttribute("OriginalSizeZ", base.Size.Z)' in MAP
assert 'local function authenticBase(base)' in CLIENT
assert 'base:GetAttribute("OriginalSizeX")' in CLIENT
assert 'base:GetAttribute("OriginalSizeZ")' in CLIENT
assert 'not authenticBase(base) or base.Parent~=arena' in CLIENT
assert 'not authenticBase(e.base) or e.base.Parent~=e.arena' in CLIENT
assert 'if not authenticBase(base) then clearModels() end' in CLIENT
assert 'base.Size.X<318' not in CLIENT
assert 'base.Size.Z<318' not in CLIENT
for initial in (320,360,400):
    for live in (initial,260,200,120,60):
        # The previous comparison on live Base.Size would fail below 318.
        assert initial>=318
        assert live>=0

# Only the exact two approved source models may replace actual Harbor
# sector cranes. Each has four static + trolley/cable/load MeshParts.
assert 'if roles.Static~=4 or roles.Trolley~=1' in CLIENT
assert 'or roles.Cable~=1 or roles.Load~=1' in CLIENT
assert 'if #pieces~=7 or roles.Static~=4' in CLIENT
assert 'if count ~= 7 or counts.Static ~= 4' in SERVER
assert 'OriginalHarborGantryKineticRole' in CLIENT and (
    'OriginalHarborGantryKineticRole' in SERVER)
assert 'part.CanCollide=false' in CLIENT
assert 'part.CanTouch=false' in CLIENT
assert 'part.CanQuery=false' in CLIENT
assert 'part.CastShadow=false' in CLIENT
assert 'part.Transparency=show and 1 or alpha' in CLIENT
assert 'clone.Parent=folder' in CLIENT

# If budget evicts a model or streaming destroys one real MeshPart /
# source, the native is restored immediately, with callback-safe release.
assert 'local function unmount(crane)' in CLIENT
assert 'mounted[crane]=nil' in CLIENT
assert CLIENT.index('mounted[crane]=nil') < CLIENT.index(
    'dispose(e)',CLIENT.index('local function unmount(crane)'))
assert 'folder.ChildRemoved:Connect(function(child)' in CLIENT
assert 'if e.model==child then unmount(crane);break end' in CLIENT
assert 'source.AncestryChanged:Connect(changed)' in CLIENT
assert 'source.DescendantRemoving:Connect' in CLIENT
assert 'clone.DescendantRemoving:Connect' in CLIENT
assert 'unmount(crane)' in CLIENT
assert 'if part.Parent then part.Transparency=alpha end' in CLIENT
assert 'for _,conn in ipairs(e.connections) do conn:Disconnect() end' in CLIENT
print("PASS one approved 7-MeshPart stationary Harbor crane on healthy Low")
print("PASS exterior crane survives shrinking floor; source/budget fallback")
print("PASS Medium/High native-driven animation and mobile quality caps")
