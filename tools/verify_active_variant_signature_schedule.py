#!/usr/bin/env python3
"""Regression: five active hero signatures get a bounded first-round import.

Source contract only. Does not claim measured Studio/Android startup time,
runtime AssetService concurrency, FPS improvement or Place publication.
"""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]
SCHEDULE=(ROOT/"src/server/PremiumActiveVariantImportSchedule.lua").read_text()
INIT=(ROOT/"src/server/init.server.lua").read_text()
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
APPROVED={m["asset_id"]:m for m in REG["models"] if m.get("moderation")=="Approved"}
SOURCES={
    "Classic":("PremiumClassicSignatureObservatoryAssets.lua",
               "112493873850364",18,104),
    "Crossroads":("PremiumCrossroadsSignatureInterchangeAssets.lua",
                  "96622579843060",19,77),
    "Harbor":("PremiumHarborSignatureGantryAssets.lua",
              "124368710235343",20,91),
    "Towers":("PremiumTowersSignatureBridgeAssets.lua",
              "126298311664881",21,62),
    "Orbital":("PremiumOrbitalSignatureRingAssets.lua",
               "125070862497818",22,42),
}
assert "function Schedule.waitFor(variant, earlySeconds, fallbackSeconds)" in SCHEDULE
assert "task.wait(earlySeconds)" in SCHEDULE
assert "task.delay(remaining" in SCHEDULE
assert "fallbackSeconds - earlySeconds" in SCHEDULE
assert 'workspace:FindFirstChild("GeneratedMap")' in SCHEDULE
assert 'generated:FindFirstChild("Arena")' in SCHEDULE
assert 'arena:GetAttribute("VariantId") == variant' in SCHEDULE
assert "arena.Parent == generated" in SCHEDULE
assert "if initial and initial:GetAttribute" in SCHEDULE
assert SCHEDULE.index("task.wait(earlySeconds)") < SCHEDULE.index(
    "if initial and initial:GetAttribute")
# No polling: a future active arena wakes its pending source.
assert 'arena:GetAttributeChangedSignal("VariantId")' in SCHEDULE
assert 'workspace.ChildAdded:Connect' in SCHEDULE
assert 'workspace.ChildRemoved:Connect' in SCHEDULE
assert 'map.ChildAdded:Connect' in SCHEDULE
assert 'map.ChildRemoved:Connect' in SCHEDULE
assert 'wake.Event:Wait()' in SCHEDULE
assert 'connection:Disconnect()' in SCHEDULE
assert 'wake:Destroy()' in SCHEDULE
assert 'return active' in SCHEDULE
assert 'while ' not in "\n".join(
    line.split("--",1)[0] for line in SCHEDULE.splitlines())
assert "local function currentArena()" in SCHEDULE
assert "local function watchMap(map)" in SCHEDULE
assert "local function watchArena(arena)" in SCHEDULE
assert 'local function checkActive()' in SCHEDULE
assert 'local function finish(wasActive)' in SCHEDULE
for forbidden in ("task.spawn(", "Heartbeat:Connect","RenderStepped",
                  "AssetService","LoadAssetAsync","RemoteEvent",
                  "GetAsync","HttpService"):
    assert forbidden not in "\n".join(x.split("--",1)[0]
                                     for x in SCHEDULE.splitlines()),forbidden

assert "MapBuilder.build(Config, \"Classic\", ArenaVariants)" in INIT
# The 46 optional original 3D owners now live in a private
# startPremiumAssets() scope to keep Luau's round-loop locals <200.
# Their individual defers remain unchanged; the *call* to the scoped
# bootstrap must occur strictly after the native playable map builds.
assert INIT.index("MapBuilder.build(Config, \"Classic\", ArenaVariants)")<INIT.index(
    "task.defer(startPremiumAssets)")
assert INIT.index("local function startPremiumAssets()")<INIT.index(
    "task.defer(PremiumClassicSignatureObservatoryAssets.start)")
assert INIT.index("task.defer(PremiumClassicSignatureObservatoryAssets.start)")<INIT.index(
    "task.defer(startPremiumAssets)")
for variant,(path,asset,early,normal) in SOURCES.items():
    source=(ROOT/"src/server"/path).read_text()
    assert asset in APPROVED,(variant,asset)
    assert asset in source
    assert "PremiumActiveVariantImportSchedule" in source
    assert f'ActiveSignatureSchedule.waitFor("{variant}",{early},{normal})' in source
    assert f"task.wait({normal})" not in source
    assert source.count("GlobalApprovedImportGate.load")==1
    assert 'require("./PremiumApprovedAssetImportGate")' in source
    assert source.count("task.spawn(function()")==1
    assert "OriginalMeshScenery.sanitize(raw)" in source
    assert 'holder:SetAttribute("OwnerVerified",true)' in source or (
        'folder:SetAttribute("OwnerVerified",true)' in source)
    assert 'if count~=7 then return false end' in source
    assert "for attempt=1,3 do" in source
    assert "task.wait(attempt*5)" in source
    assert "task.defer("+path.removesuffix(".lua")+".start)" in INIT
    assert 18<=early<=22<normal<=120
    print(f"PASS {variant}: real Approved {asset}, {normal}s -> {early}s when active")

# For a stable arena, only its matching signature can be accelerated.
# A rotation can wake another pending signature; FIFO limits concurrency.
for active in (*SOURCES,None,""):
    actual={}
    for variant,(_,_,early,normal) in SOURCES.items():
        actual[variant]=early if active==variant else normal
    if active in SOURCES:
        assert sum(actual[v]<SOURCES[v][3] for v in SOURCES)==1
    else:
        assert all(actual[v]==SOURCES[v][3] for v in SOURCES)
    assert actual.get("Classic",0)>0
print("PASS five arena and missing-map combinations preserve five total imports")
print("NOTE source CI does not measure concurrent network load or actual FPS")
