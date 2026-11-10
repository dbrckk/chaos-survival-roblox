-- Single bounded queue for owner-approved Premium 3D Model imports.
-- Gameplay, bot startup and map generation NEVER await this module.
-- Shared by all server Premium*Assets loaders; two AssetService calls max.
-- Queue uses BindableEvent signals, never polling every frame.
local Gate = {}

local MAX_IN_FLIGHT = 2
local inFlight = 0
local peakInFlight = 0
local waiting = {}
local completed = 0
local failed = 0
local totalWaits = 0

local function reserve()
    if inFlight < MAX_IN_FLIGHT and #waiting == 0 then
        inFlight += 1
        peakInFlight = math.max(peakInFlight, inFlight)
        return
    end

    -- FIFO handoff: an in-flight permit is reserved for this waiter
    -- before it is signalled by the releasing worker.
    local signal = Instance.new("BindableEvent")
    waiting[#waiting + 1] = signal
    totalWaits += 1
    signal.Event:Wait()
    signal:Destroy()
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
end

function Gate.load(service, assetId)
    assert(typeof(service) == "Instance"
        and service:IsA("AssetService"), "AssetService required")
    assert(type(assetId) == "number" and assetId > 0,
        "Approved numeric Roblox Model ID required")

    reserve()
    local ok, result = pcall(service.LoadAssetAsync, service, assetId)
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
    }
end

return Gate
