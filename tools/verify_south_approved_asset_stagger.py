#!/usr/bin/env python3
"""Eight already-approved South 3D sources: prevent t=49s request herd.

Checks complete source identity, unchanged sanitization/retry, strictly
separated nominal first-request slots for *any* active arena variant.
Actual API concurrency, FPS and runtime streaming must be measured in Studio.
"""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
ROWS={r["asset_id"]:r for r in REG["models"]}
BASE=(ROOT/"src/server")
HELPER=(BASE/"PremiumActiveVariantImportSchedule.lua").read_text()
INIT=(BASE/"init.server.lua").read_text()

# (module, variant, true approved asset id, active delay, inactive delay)
ITEMS=[
("PremiumSouthClassicObservatoryAssets","Classic","105516749001927",59,101),
("PremiumSouthCrossroadsExchangeAssets","Crossroads","77870668100712",59,115),
("PremiumSouthHarborDrydockAssets","Harbor","125428569657840",59,129),
("PremiumSouthOrbitalFinishingAssets","Orbital","96266711661930",59,143),
("PremiumSouthTowersFinishingAssets","Towers","79666240429608",59,157),
("PremiumSouthTowersSkytransferAssets","Towers","120959181274080",75,171),
("PremiumSouthTowersLiftTwinsAssets","Towers","114886409893890",91,185),
("PremiumSouthOrbitalObservationRingAssets","Orbital","124474310430876",75,199),
]
assert 'task.wait(earlySeconds)' in HELPER
assert 'task.delay(remaining' in HELPER
assert 'fallbackSeconds - earlySeconds' in HELPER
assert 'arena:GetAttribute("VariantId") == variant' in HELPER
assert 'arena:GetAttributeChangedSignal("VariantId")' in HELPER
assert 'wake.Event:Wait()' in HELPER
assert 'wake:Destroy()' in HELPER
assert len(ITEMS)==8
assert len({x[2] for x in ITEMS})==8
assert len({x[4] for x in ITEMS})==8
assert "MapBuilder.build(Config, \"Classic\", ArenaVariants)" in INIT

for filename,variant,model_id,early,fallback in ITEMS:
    source=(BASE/(filename+".lua")).read_text()
    assert ROWS[model_id]["moderation"]=="Approved"
    assert model_id in source
    assert 'require("./PremiumActiveVariantImportSchedule")' in source
    assert f'ActiveSignatureSchedule.waitFor("{variant}",{early},{fallback})' in source
    assert 'task.wait(49)' not in source
    assert source.count('task.spawn(function()')==1
    assert source.count('SouthImportGate.load')==1
    assert 'require("./PremiumSouthApprovedImportGate")' in source
    assert 'AssetService.LoadAssetAsync' not in source
    assert 'OriginalMeshScenery.sanitize(raw)' in source
    assert 'if count~=7 then return false end' in source
    assert 'for attempt=1,3 do' in source
    assert 'task.wait(attempt*5)' in source
    assert 'SetAttribute("OwnerVerified",true)' in source
    assert 'SetAttribute("CosmeticOnly",true)' in source
    assert 'SetAttribute("Original3DAssetId",' in source
    assert f'task.defer({filename}.start)' in INIT
    assert 0<early<fallback
    print(f"PASS {filename}: verified Approved id {model_id},"
          f" active {early}s / inactive {fallback}s")

# One native-source family per world priority, with optional extension
# assets for Towers and Orbital. No two of THESE EIGHT loaders are
# deliberately scheduled for the same first-request second.
for current in (None,"Classic","Crossroads","Harbor","Orbital","Towers","Unknown"):
    clock={}
    early_count=0
    for filename,variant,_,early,fallback in ITEMS:
        planned=early if current==variant else fallback
        early_count+=int(current==variant)
        if planned in clock:
            raise AssertionError(("Nominal South import collision",current,
                                  planned,clock[planned],filename))
        clock[planned]=filename
    expected={"Classic":1,"Crossroads":1,"Harbor":1,"Orbital":2,"Towers":3}
    assert early_count==expected.get(current,0)
    assert len(clock)==8
    assert min(clock.values(),key=str) # nonempty
    assert sorted(clock)==sorted(set(clock))
    print(f"PASS arena {str(current):10s}: {len(clock)} separate "
          f"South first-request time slots, {early_count} priority models")

# Existing first-wave 49s simultaneous request risk replaced by a
# 59/75/91 active sequence and 101..199s inactive staggered positions.
assert sorted({fallback for *_,fallback in ITEMS})==[
    101,115,129,143,157,171,185,199]
print("PASS no first-window 49-second herd, no new source IDs or load calls")
print("LIMIT: task.wait and network duration are not exact real-time barriers")
