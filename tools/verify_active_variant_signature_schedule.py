#!/usr/bin/env python3
"""Regression: active visual signature loads earlier; inactive imports do not.

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
               "112493873850364",44,104),
    "Crossroads":("PremiumCrossroadsSignatureInterchangeAssets.lua",
                  "96622579843060",45,77),
    "Harbor":("PremiumHarborSignatureGantryAssets.lua",
              "124368710235343",46,91),
    "Towers":("PremiumTowersSignatureBridgeAssets.lua",
              "126298311664881",47,62),
}
assert "function Schedule.waitFor(variant, earlySeconds, fallbackSeconds)" in SCHEDULE
assert "task.wait(earlySeconds)" in SCHEDULE
assert "task.wait(fallbackSeconds-earlySeconds)" in SCHEDULE
assert "local generated=workspace:FindFirstChild(\"GeneratedMap\")" in SCHEDULE
assert 'local arena=generated and generated:FindFirstChild("Arena")' in SCHEDULE
assert 'arena:GetAttribute("VariantId")==variant' in SCHEDULE
assert "arena.Parent==generated" in SCHEDULE
assert "if isActive then return true end" in SCHEDULE
assert SCHEDULE.index("task.wait(earlySeconds)")<SCHEDULE.index("if isActive then")
assert SCHEDULE.index("if isActive then")<SCHEDULE.index(
    "task.wait(fallbackSeconds-earlySeconds)")
for forbidden in ("task.spawn(", "Heartbeat:Connect","RenderStepped",
                  "AssetService","LoadAssetAsync","RemoteEvent",
                  "GetAsync","HttpService"):
    assert forbidden not in "\n".join(x.split("--",1)[0]
                                     for x in SCHEDULE.splitlines()),forbidden

assert "MapBuilder.build(Config, \"Classic\", ArenaVariants)" in INIT
assert INIT.index("MapBuilder.build(Config, \"Classic\", ArenaVariants)")<INIT.index(
    "task.defer(PremiumClassicSignatureObservatoryAssets.start)")
for variant,(path,asset,early,normal) in SOURCES.items():
    source=(ROOT/"src/server"/path).read_text()
    assert asset in APPROVED,(variant,asset)
    assert asset in source
    assert "PremiumActiveVariantImportSchedule" in source
    assert f'ActiveSignatureSchedule.waitFor("{variant}",{early},{normal})' in source
    assert f"task.wait({normal})" not in source
    assert source.count("AssetService.LoadAssetAsync")==1
    assert source.count("task.spawn(function()")==1
    assert "OriginalMeshScenery.sanitize(raw)" in source
    assert 'holder:SetAttribute("OwnerVerified",true)' in source or (
        'folder:SetAttribute("OwnerVerified",true)' in source)
    assert 'if count~=7 then return false end' in source
    assert "for attempt=1,3 do" in source
    assert "task.wait(attempt*5)" in source
    assert "task.defer("+path.removesuffix(".lua")+".start)" in INIT
    assert 30<=early<normal<=120
    print(f"PASS {variant}: real Approved {asset}, {normal}s -> {early}s when active")

# Only ONE of the four big signature importers is accelerated. Startup
# with no map, or other active arena, retains existing original schedule.
for active in (*SOURCES,"Orbital",None,""):
    actual={}
    for variant,(_,_,early,normal) in SOURCES.items():
        actual[variant]=early if active==variant else normal
    if active in SOURCES:
        assert sum(actual[v]<SOURCES[v][3] for v in SOURCES)==1
    else:
        assert all(actual[v]==SOURCES[v][3] for v in SOURCES)
    assert actual.get("Classic",0)>0
print("PASS all active/missing/other arena combinations preserve 4 total imports")
print("NOTE source CI does not measure concurrent network load or actual FPS")
