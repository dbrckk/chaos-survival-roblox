#!/usr/bin/env python3
"""Prevent the original premium 3D source import thundering herd globally.

Deterministic repository contract: 48 independently scheduled owner-approved
Premium*Assets modules share exactly one bounded AssetService queue; the
eight South imports additionally retain their stricter one-at-a-time gate.
The engine's true request timings still require Studio measurement.
"""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
SERVER=ROOT/"src/server"
QUEUE=(SERVER/"PremiumApprovedAssetImportGate.lua").read_text()
SOUTH=(SERVER/"PremiumSouthApprovedImportGate.lua").read_text()
SOURCES=sorted(SERVER.glob("Premium*Assets.lua"))
SOUTH_NAMES={
    "PremiumSouthClassicObservatoryAssets.lua",
    "PremiumSouthCrossroadsExchangeAssets.lua",
    "PremiumSouthHarborDrydockAssets.lua",
    "PremiumSouthOrbitalFinishingAssets.lua",
    "PremiumSouthOrbitalObservationRingAssets.lua",
    "PremiumSouthTowersFinishingAssets.lua",
    "PremiumSouthTowersLiftTwinsAssets.lua",
    "PremiumSouthTowersSkytransferAssets.lua",
}
assert len(SOURCES)==48,(len(SOURCES),[s.name for s in SOURCES])
assert len(SOUTH_NAMES)==8
assert SOUTH_NAMES <= {s.name for s in SOURCES}
assert "local MAX_IN_FLIGHT = 2" in QUEUE
assert "local inFlight = 0" in QUEUE
assert "local waiting = {}" in QUEUE
assert "function Gate.load(service, assetId)" in QUEUE
assert 'Instance.new("BindableEvent")' in QUEUE
assert 'signal.Event:Wait()' in QUEUE
assert 'signal:Destroy()' in QUEUE
assert 'waiting[#waiting + 1] = signal' in QUEUE
assert 'local first = table.remove(waiting, 1)' in QUEUE
assert 'first:Fire()' in QUEUE
assert "inFlight += 1" in QUEUE
assert "inFlight -= 1" in QUEUE
assert "local ok, result = pcall(service.LoadAssetAsync, service, assetId)" in QUEUE
assert QUEUE.index("release()\n    -- The existing") > QUEUE.index(
    "local ok, result = pcall(service.LoadAssetAsync, service, assetId)")
assert QUEUE.index("if not ok then error(result, 0) end") > QUEUE.index(
    "release()\n    -- The existing")
assert "if inFlight < MAX_IN_FLIGHT and #waiting == 0 then" in QUEUE
assert "function Gate.snapshot()" in QUEUE
for attr in ("InFlight = inFlight","Waiting = #waiting",
             "PeakInFlight = peakInFlight","Limit = MAX_IN_FLIGHT",
             "Completed = completed","Failed = failed",
             "TotalWaits = totalWaits"):
    assert attr in QUEUE,attr
for forbidden in ("task.spawn", "task.wait", "RenderStepped",
                  "Heartbeat:Connect", "RemoteEvent", "RemoteFunction"):
    assert forbidden not in "\n".join(
        line.split("--",1)[0] for line in QUEUE.splitlines()),forbidden
assert 'require("./PremiumApprovedAssetImportGate")' in SOUTH
assert "pcall(GlobalApprovedImportGate.load,service,assetId)" in SOUTH
assert "while busy do task.wait(.2) end" not in SOUTH
assert 'Instance.new("BindableEvent")' in SOUTH
assert 'signal.Event:Wait()' in SOUTH
assert 'signal:Destroy()' in SOUTH
assert 'nextWaiter:Fire()' in SOUTH
assert "release()\n    if not ok then error(result,0) end" in SOUTH
assert "pcall(service.LoadAssetAsync" not in SOUTH

# The original 3D station apex source now favors the verified arena
# at 60 seconds while preserving the 132s background sweep and 3 retries.
# This is a source contract, not an asserted real-network latency.
APEX=(SERVER/"PremiumPerimeterVariantApexAssets.lua").read_text()
assert 'local function activeSourceKind()' in APEX
assert 'generated.Parent ~= workspace' in APEX
assert 'arena.Parent ~= generated' in APEX
assert 'if variant == "Classic" or variant == "Harbor" then' in APEX
assert 'return "Relay"' in APEX
assert 'return APPROVED[variant] and variant or nil' in APEX
assert 'task.wait(60)' in APEX
assert 'local earlyKind = activeSourceKind()' in APEX
assert 'if earlyKind then tryImport(earlyKind) end' in APEX
assert 'local remaining = 132 - (time() - startedAt)' in APEX
assert 'if remaining > 0 then task.wait(remaining) end' in APEX
assert 'local currentKind = activeSourceKind()' in APEX
assert 'if currentKind then tryImport(currentKind) end' in APEX
assert 'if attempted[kind] then return end' in APEX
assert 'attempted[kind] = true' in APEX
assert APEX.index('attempted[kind] = true') < APEX.index(
    'pcall(GlobalApprovedImportGate.load,')
assert 'for _, kind in ipairs(ORDER) do' in APEX
assert APEX.count('task.spawn(function()') == 1
assert APEX.count('GlobalApprovedImportGate.load') == 1
assert APEX.count('for attempt = 1, 3 do') == 1
assert 'OriginalMeshScenery.sanitize(raw)' in APEX
assert 'geometryOK(clean, spec)' in APEX

for source in SOURCES:
    s=source.read_text()
    assert "OriginalMeshScenery.sanitize(" in s,source
    assert "task.spawn(function()" in s,source
    if source.name in SOUTH_NAMES:
        assert 'require("./PremiumSouthApprovedImportGate")' in s,source
        assert len(re.findall(r"pcall\(SouthImportGate\.load,",s))==1,source
        assert "GlobalApprovedImportGate.load" not in s,source
    else:
        assert 'require("./PremiumApprovedAssetImportGate")' in s,source
        assert s.count("GlobalApprovedImportGate.load")==1,source
        assert "SouthImportGate.load" not in s,source
    assert "AssetService.LoadAssetAsync" not in s,source
    assert "service.LoadAssetAsync" not in s,source

print("PASS 60s authentic active apex priority, 132s background sweep, no duplicate import")
print("PASS 48 Premium original 3D loaders use the global 2-import FIFO queue")
print("PASS 8 South imports retain a stricter shared 1-import sub-gate")
print("PASS no direct calls outside queue; no new server/client frame loops")
print("LIMIT runtime concurrency and Android FPS must be measured in-engine")
