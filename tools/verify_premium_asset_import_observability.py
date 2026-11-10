#!/usr/bin/env python3
"""Audit Roblox Premium 3D import observability and FIFO handoff.

Static regression only. Studio server-side diagnostics can later establish
actual queueing / API durations; this does not fabricate network benchmarks.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SRC=(ROOT/"src/server/PremiumApprovedAssetImportGate.lua").read_text()
SOUTH=(ROOT/"src/server/PremiumSouthApprovedImportGate.lua").read_text()

assert 'game:GetService("ServerStorage")' in SRC
assert 'ServerStorage:FindFirstChild("PremiumApprovedImportDiagnostics")' in SRC
assert 'diagnostics.Parent = ServerStorage' in SRC
assert 'local diagnostics = ServerStorage:' in SRC
assert 'local MAX_IN_FLIGHT = 2' in SRC
assert 'local waiting = {}' in SRC
assert 'signal.Event:Wait()' in SRC
assert 'signal:Destroy()' in SRC
assert 'local first = table.remove(waiting, 1)' in SRC
assert 'first:Fire()' in SRC
assert 'local ok, result = pcall(service.LoadAssetAsync, service, assetId)' in SRC
assert SRC.index('release()\n    -- The existing') < SRC.index(
    'if not ok then error(result, 0) end')
assert 'local queuedAt = os.clock()' in SRC
assert 'local startedAt = os.clock()' in SRC
assert 'math.floor((os.clock()-queuedAt)*1000+.5)' in SRC
assert 'math.floor((os.clock()-startedAt)*1000+.5)' in SRC
assert 'if lastQueueWaitMs > maxQueueWaitMs then' in SRC
assert 'maxQueueWaitMs = lastQueueWaitMs' in SRC
assert 'slowestQueueAssetId = assetId' in SRC
assert 'if lastRequestMs > maxRequestMs then' in SRC
assert 'maxRequestMs = lastRequestMs' in SRC
assert 'slowestRequestAssetId = assetId' in SRC
for name in ('InFlight','Waiting','PeakInFlight','Limit','Completed','Failed',
             'TotalWaits','LastQueueWaitMs','MaxQueueWaitMs',
             'LastRequestMs','MaxRequestMs'):
    assert f'diagnostics:SetAttribute("{name}",' in SRC, name
    assert f'{name} =' in SRC, name
assert SRC.index("local function publish()")<SRC.index("publish()\n\nlocal function reserve(assetId)")
assert SRC.index("publish()\n    signal.Event:Wait()")<SRC.index("signal.Event:Wait()")
assert SRC.index("release()\n    -- The existing") > SRC.index(
    "local ok, result = pcall(service.LoadAssetAsync")
# Slowest-source identifiers and aggregate diagnostics must be
# observed after actual API completion and remain server-only. This
# makes network bottlenecks attributable to a Model ID, not guessed.
for name in (
    "LastRequestAssetId","SlowestRequestAssetId","SlowestQueueAssetId",
    "TotalRequestMs","TotalQueueWaitMs",
    "SlowRequestCount","SlowQueueCount","SlowThresholdMs"
):
    assert f'diagnostics:SetAttribute("{name}",' in SRC,name
    assert f'{name} =' in SRC,name
assert "local SLOW_MS = 8000" in SRC
assert "local function reserve(assetId)" in SRC
assert "reserve(assetId)" in SRC
assert "lastRequestAssetId = assetId" in SRC
assert "slowestRequestAssetId = assetId" in SRC
assert "slowestQueueAssetId = assetId" in SRC
assert "if lastRequestMs > maxRequestMs then" in SRC
assert "if lastQueueWaitMs > maxQueueWaitMs then" in SRC
assert "totalRequestMs += lastRequestMs" in SRC
assert "totalQueueWaitMs += lastQueueWaitMs" in SRC
assert "if lastQueueWaitMs >= SLOW_MS then" in SRC
assert "if lastRequestMs >= SLOW_MS then" in SRC
assert SRC.index("if lastRequestMs > maxRequestMs then") < SRC.index(
    "if ok then\n        completed += 1")
assert SRC.index("release()\n    -- The existing") > SRC.index(
    "totalRequestMs += lastRequestMs")
assert "RemoteEvent" not in SRC and "HttpService" not in SRC

assert "task.spawn(" not in SRC and "task.wait(" not in SRC
assert "RemoteEvent" not in SRC and "ReplicatedStorage" not in SRC

assert 'Instance.new("BindableEvent")' in SOUTH
assert 'waiting[#waiting+1]=signal' in SOUTH
assert 'signal.Event:Wait()' in SOUTH
assert 'signal:Destroy()' in SOUTH
assert 'local nextWaiter=table.remove(waiting,1)' in SOUTH
assert 'nextWaiter:Fire()' in SOUTH
assert 'pcall(GlobalApprovedImportGate.load,service,assetId)' in SOUTH
assert SOUTH.index("release()\n    if not ok then") > SOUTH.index(
    "pcall(GlobalApprovedImportGate.load,service,assetId)")
assert "while busy do task.wait(.2) end" not in SOUTH
assert "task.wait(" not in SOUTH and "task.spawn(" not in SOUTH
assert "Completed=completed" in SOUTH and "Failed=failures" in SOUTH
assert "Waiting=#waiting" in SOUTH and "TotalWaits=totalWaits" in SOUTH
print("PASS owner-approved global queue: server-only request/wait timing instrumentation")
print("PASS two-permit global FIFO and one-permit South FIFO, exception-safe release")
print("LIMIT engine latency and actual Android graphics still require Studio/device measurement")
