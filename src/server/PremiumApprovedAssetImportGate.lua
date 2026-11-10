-- Single bounded queue for owner-approved Premium 3D Model imports.
-- Gameplay, bot startup and map generation NEVER await this module.
-- Shared by all server Premium*Assets loaders; two AssetService calls max.
-- Queue uses BindableEvent signals, never polling every frame.
local ServerStorage = game:GetService("ServerStorage")
local Gate = {}

-- ServerStorage only: diagnostic counters cannot be spoofed by clients,
-- and do not add replicated attributes or network traffic.
local diagnostics = ServerStorage:FindFirstChild("PremiumApprovedImportDiagnostics")
if diagnostics and not diagnostics:IsA("Folder") then
    diagnostics = nil
end
if not diagnostics then
    diagnostics = Instance.new("Folder")
    diagnostics.Name = "PremiumApprovedImportDiagnostics"
    diagnostics.Parent = ServerStorage
end

local MAX_IN_FLIGHT = 2
local inFlight = 0
local peakInFlight = 0
local waiting = {}
local completed = 0
local failed = 0
local totalWaits = 0
local lastQueueWaitMs = 0
local maxQueueWaitMs = 0
local lastRequestMs = 0
local maxRequestMs = 0

local function publish()
    diagnostics:SetAttribute("InFlight", inFlight)
    diagnostics:SetAttribute("Waiting", #waiting)
    diagnostics:SetAttribute("PeakInFlight", peakInFlight)
    diagnostics:SetAttribute("Limit", MAX_IN_FLIGHT)
    diagnostics:SetAttribute("Completed", completed)
    diagnostics:SetAttribute("Failed", failed)
    diagnostics:SetAttribute("TotalWaits", totalWaits)
    diagnostics:SetAttribute("LastQueueWaitMs", lastQueueWaitMs)
    diagnostics:SetAttribute("MaxQueueWaitMs", maxQueueWaitMs)
    diagnostics:SetAttribute("LastRequestMs", lastRequestMs)
    diagnostics:SetAttribute("MaxRequestMs", maxRequestMs)
end

publish()

local function reserve()
    if inFlight < MAX_IN_FLIGHT and #waiting == 0 then
        inFlight += 1
        peakInFlight = math.max(peakInFlight, inFlight)
        publish()
        return
    end

    -- FIFO handoff: an in-flight permit is reserved for this waiter
    -- before it is signalled by the releasing worker.
    local signal = Instance.new("BindableEvent")
    local queuedAt = os.clock()
    waiting[#waiting + 1] = signal
    totalWaits += 1
    publish()
    signal.Event:Wait()
    signal:Destroy()
    lastQueueWaitMs = math.max(0, math.floor((os.clock()-queuedAt)*1000+.5))
    maxQueueWaitMs = math.max(maxQueueWaitMs, lastQueueWaitMs)
    publish()
end

local function release()
    -- If a worker is waiting, transfer this permit directly. This
    -- prevents new requests from overtaking earlier queued ones.
    if #waiting > 0 then
        local first = table.remove(waiting, 1)
        first:Fire()
    else
        inFlight -= 1
    end
    publish()
end

function Gate.load(service, assetId)
    assert(typeof(service) == "Instance"
        and service:IsA("AssetService"), "AssetService required")
    assert(type(assetId) == "number" and assetId > 0,
        "Approved numeric Roblox Model ID required")

    reserve()
    local startedAt = os.clock()
    local ok, result = pcall(service.LoadAssetAsync, service, assetId)
    lastRequestMs = math.max(0, math.floor((os.clock()-startedAt)*1000+.5))
    maxRequestMs = math.max(maxRequestMs, lastRequestMs)
    if ok then
        completed += 1
    else
        failed += 1
    end
    release()
    -- The existing outer pcall/retry in each original loader can
    -- handle this error exactly as it handled AssetService errors.
    if not ok then error(result, 0) end
    return result
end

function Gate.snapshot()
    return {
        InFlight = inFlight,
        Waiting = #waiting,
        PeakInFlight = peakInFlight,
        Limit = MAX_IN_FLIGHT,
        Completed = completed,
        Failed = failed,
        TotalWaits = totalWaits,
        LastQueueWaitMs = lastQueueWaitMs,
        MaxQueueWaitMs = maxQueueWaitMs,
        LastRequestMs = lastRequestMs,
        MaxRequestMs = maxRequestMs,
    }
end

return Gate
