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
# Original, owner-approved Classic/Crossroads signature 3D must be
# mountable on Low without changing collisions, other tiers or fallbacks.
FORGE=(ROOT/"src/client/ApprovedClassicForgedSupportsMeshKit.lua").read_text()
INTERCHANGE=(ROOT/"src/client/ApprovedCrossroadsSignatureInterchangeMeshKit.lua").read_text()
FORGE_ASSETS=(ROOT/"src/server/PremiumClassicForgedSupportsAssets.lua").read_text()
assert 'local QUALITY={Low=1,Medium=1,High=1}' in FORGE
assert 'local RANGE={Low=320,Medium=440,High=610}' in FORGE
assert 'local QUALITY={Low=1,Medium=1,High=1}' in INTERCHANGE
assert 'local RANGE={Low=320,Medium=405,High=580}' in INTERCHANGE
for client in (FORGE,INTERCHANGE):
    assert 'if stress>=2 or (stress==1 and tier~="High") then' in client
    assert 'native.Transparency=alpha' in client
    assert 'bucket.ChildRemoved:Connect' in client
    assert 'if count~=7 then return nil end' in client
    assert 'Original3DAssetId' in client
    assert 'part.CanCollide=false' in client
    assert 'part.CanTouch=false' in client
    assert 'part.CanQuery=false' in client
    assert 'RenderStepped' not in client and 'Heartbeat' not in client
assert 'local MODEL_ID=91717127334369' in FORGE
assert 'local MODEL_ID=96622579843060' in INTERCHANGE
assert '91717127334369' in APPROVED
assert '96622579843060' in APPROVED
assert 'require("./PremiumActiveVariantImportSchedule")' in FORGE_ASSETS
assert 'ActiveSignatureSchedule.waitFor("Classic",56,119)' in FORGE_ASSETS
assert 'task.wait(119)' not in FORGE_ASSETS
assert FORGE_ASSETS.count('task.spawn(function()')==1
assert FORGE_ASSETS.count('GlobalApprovedImportGate.load')==1
assert 'OriginalMeshScenery.sanitize(raw)' in FORGE_ASSETS
print("PASS Low native swaps Classic 5->7 and Crossroads 4->7 with fallback")
print("PASS Classic forge source active-only at 56s, otherwise 119s")

assert "function Schedule.waitFor(variant, earlySeconds, fallbackSeconds, alsoVariant)" in SCHEDULE
assert 'assert(alsoVariant == nil or (type(alsoVariant) == "string"' in SCHEDULE
assert 'alsoVariant ~= nil and id == alsoVariant' in SCHEDULE
assert 'local function isTarget(arena)' in SCHEDULE
assert "task.wait(earlySeconds)" in SCHEDULE
assert "task.delay(remaining" in SCHEDULE
assert "fallbackSeconds - earlySeconds" in SCHEDULE
assert 'workspace:FindFirstChild("GeneratedMap")' in SCHEDULE
assert 'generated:FindFirstChild("Arena")' in SCHEDULE
assert 'local id = arena:GetAttribute("VariantId")' in SCHEDULE
assert 'return id == variant or (alsoVariant ~= nil and id == alsoVariant)' in SCHEDULE
assert "arena.Parent == generated" in SCHEDULE
assert "if initial and isTarget(initial) then" in SCHEDULE
assert SCHEDULE.index("task.wait(earlySeconds)") < SCHEDULE.index(
    "if initial and isTarget(initial) then")
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
    expected = (f'ActiveSignatureSchedule.waitFor("{variant}",{early},'
                f'{normal}' + (',"Towers")' if variant == "Orbital" else ')'))
    assert expected in source,(variant,expected)
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

# The shared Orbital torus is Towers' central crown too. Stable Towers
# legitimately prioritizes TWO existing loads, never an extra worker.
# Other maps still prioritize only their matching signature.
for active in (*SOURCES,None,""):
    actual={}
    for variant,(_,_,early,normal) in SOURCES.items():
        match = active==variant or (variant=="Orbital" and active=="Towers")
        actual[variant]=early if match else normal
    if active=="Towers":
        assert actual["Towers"]==21 and actual["Orbital"]==22
        assert sum(actual[v]<SOURCES[v][3] for v in SOURCES)==2
    elif active in SOURCES:
        assert sum(actual[v]<SOURCES[v][3] for v in SOURCES)==1
    else:
        assert all(actual[v]==SOURCES[v][3] for v in SOURCES)
    assert actual.get("Classic",0)>0
print("PASS five arena and missing-map combinations preserve five total imports")
print("PASS Towers shares the ONE original Orbital source at the active window")
# Harbor's animated hero station and two actual gantry Models used to
# start loading at 96s/76s even when Harbor was the current 30-45s arena.
# Verify that only their start times change, not the source security gate,
# original assets, sequential crane imports or fallback for other variants.
HARBOR_LANDMARKS = (
    ("PremiumHarborHeroStationAssets.lua", "73237902371094", 33, 96),
    ("PremiumHarborGantryAssets.lua", "75684193304551", 58, 76),
)
for path, source_id, early, normal in HARBOR_LANDMARKS:
    source=(ROOT/"src/server"/path).read_text()
    assert source_id in APPROVED,(path,source_id)
    assert 'require("./PremiumActiveVariantImportSchedule")' in source
    assert 'require("./PremiumApprovedAssetImportGate")' in source
    assert f'ActiveSignatureSchedule.waitFor("Harbor",{early},{normal})' in source
    assert f"task.wait({normal})" not in source
    assert source.count("ActiveSignatureSchedule.waitFor")==1
    assert source.count("GlobalApprovedImportGate.load")==1
    assert source.count("task.spawn(function()")==1
    assert 'OriginalMeshScenery.sanitize(raw)' in source
    assert 'holder:SetAttribute("OwnerVerified",true)' in source or (
        'holder:SetAttribute("OwnerVerified", true)' in source)
    assert ("for attempt=1,3 do" in source
        or "for attempt = 1, 3 do" in source)
    assert early < normal
    print(f"PASS Harbor source {source_id}: {normal}s -> {early}s active")
gantries=(ROOT/"src/server/PremiumHarborGantryAssets.lua").read_text()
assert "98809955094422" in gantries and "98809955094422" in APPROVED
assert 'for _, spec in ipairs(SOURCES) do' in gantries
assert 'task.wait(4)' in gantries
assert 'counts.Static ~= 4 or counts.Trolley ~= 1' in gantries
assert 'counts.Cable ~= 1 or counts.Load ~= 1' in gantries
print("PASS two real Harbor cranes remain sequential, validated and reversible")

print("NOTE source CI does not measure concurrent network load or actual FPS")
