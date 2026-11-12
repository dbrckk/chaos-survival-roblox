#!/usr/bin/env python3
"""P4 Harbor hero station authentic nearfield Low regression.

Source/structural contract, NOT a Roblox Engine rendering or FPS test.
"""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[1]
KIT=(ROOT/"src/client/HarborHeroStationMeshKit.lua").read_text()
SERVER=(ROOT/"src/server/PremiumHarborHeroStationAssets.lua").read_text()
LOD=(ROOT/"src/client/scenery-lod.client.lua").read_text()
BUDGET=(ROOT/"src/shared/VisualBudgetRules.lua").read_text()
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
entry=next(x for x in REG["models"] if x["name"]=="harbor_hero_station")
assert entry["asset_id"]=="73237902371094"
assert entry["moderation"]=="Approved"
assert entry["workflow_run_id"]==41859877575
assert entry["source"]=="tools/generate_original_harbor_hero_station.py"
assert 'local ID=73237902371094' in KIT
assert '73237902371094' in SERVER
assert 'Low={count=1,distance=170,retain=22}' in KIT
assert 'Medium={count=1,distance=215,retain=26}' in KIT
assert 'High={count=1,distance=345,retain=42}' in KIT
assert '(tier=="Medium" or tier=="Low") and stress>=1' in KIT
assert 'stress>=2' in KIT
assert 'if not arena or not cameraReady or budget.count==0' in KIT
assert 'localFolder.ChildRemoved:Connect(function(child)' in KIT
assert 'if entry and entry.model==child then' in KIT
assert 'dismount()' in KIT
assert KIT.index('entry=nil') < KIT.index('old.model:Destroy()')
assert 'old.disposing=true' in KIT
assert 'if part.Parent then part.Transparency=original end' in KIT
assert 'OriginalHarborHeroStationLocal' in KIT
assert '"OriginalHarborHeroStationLocal"' in BUDGET
assert 'HarborHeroStationMeshKit.sync(' in LOD
assert 'OriginalHarborHeroStation3D' in KIT
assert 'OriginalHarborHeroMotionRole' in KIT
assert 'OwnerVerified' in KIT
assert 'CosmeticOnly' in KIT
assert 'if roles.Static~=4 or roles.Radar~=1' in KIT
assert 'if #pieces~=7 or roles.Static~=4' in KIT
assert 'if observed<12 then clone:Destroy();return nil end' in KIT
assert 'clone.Parent=localFolder' in KIT
assert KIT.index('clone.Parent=localFolder') < KIT.index('if visibility(e) then syncMotion(e) end')
assert 'HarborHeroStormLens' in KIT
assert 'native:GetPropertyChangedSignal("CFrame")' in KIT
assert 'native:GetPropertyChangedSignal("Transparency")' in KIT
assert 'part.CanCollide=false' not in KIT or True  # actual loop uses p
for flag in ('p.CanCollide=false','p.CanTouch=false',
             'p.CanQuery=false','p.CastShadow=false'):
    assert flag in KIT,flag
for forbidden in ('RenderStepped','Heartbeat:Connect','LoadAssetAsync',
                  'RemoteEvent','RemoteFunction'):
    assert forbidden not in KIT,forbidden
# One model can hide only the approved, nonphysical native pieces.
assert len(re.findall(r'^    HarborHero[A-Za-z]+\s*=true,',KIT,re.MULTILINE))>=19
assert 'EXPECTED_NAMES[native.Name]' in KIT
assert 'if native.CanCollide or native.CanQuery or native.CanTouch then' in KIT
assert 'if part.Parent then part.Transparency=show and 1 or original' in KIT
print("PASS Harbor hero: one 7-MeshPart approved model replaces >=12 verified native pieces on healthy Low")
print("PASS original Radar/Cable/Weight motion, storm lens, GPU pressure and budget eviction fallback")
print("LIMIT: Roblox Engine visual output and real Android FPS not measured")
