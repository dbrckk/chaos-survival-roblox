-- Exclusive South 3D owner import permit nested beneath the bounded
-- global Premium queue. A FIFO BindableEvent queue avoids the old
-- 0.2-second polling cycle, even if Roblox AssetService responds slowly.
-- Optional art importers yield; no round, bot or player join awaits them.
local GlobalApprovedImportGate=require("./PremiumApprovedAssetImportGate")
local Gate={}
local busy=false
local waiting={}
local peak=0
local completed=0
local failures=0
local totalWaits=0

local function reserve()
    if not busy and #waiting==0 then
        busy=true
        peak=math.max(peak,1)
        return
    end
    local signal=Instance.new("BindableEvent")
    waiting[#waiting+1]=signal
    totalWaits+=1
    signal.Event:Wait()
    signal:Destroy()
end

local function release()
    if #waiting>0 then
        local nextWaiter=table.remove(waiting,1)
        nextWaiter:Fire()
    else
        busy=false
    end
end

function Gate.load(service,assetId)
    assert(typeof(service)=="Instance" and service:IsA("AssetService"),
        "AssetService required")
    assert(type(assetId)=="number" and assetId>0,"approved numeric id required")
    reserve()
    local ok,result=pcall(GlobalApprovedImportGate.load,service,assetId)
    if ok then completed+=1 else failures+=1 end
    release()
    if not ok then error(result,0) end
    return result
end

function Gate.snapshot()
    return {
        InFlight=busy and 1 or 0,
        Waiting=#waiting,
        PeakInFlight=peak,
        Completed=completed,
        Failed=failures,
        TotalWaits=totalWaits,
    }
end

return Gate
