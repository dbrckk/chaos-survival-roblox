-- One server-wide permit for the eight approved South cosmetic Model imports.
-- Unlike nominal task.wait slots, this gate bounds actual overlapping
-- AssetService.LoadAssetAsync calls from these eight specific owners.
-- Does not intercept gameplay, other independent asset owners, or clients.
local Gate={}
local busy=false
local waiting=0
local peak=0
local completed=0
local failures=0

function Gate.load(service,assetId)
    assert(typeof(service)=="Instance" and service:IsA("AssetService"),
        "AssetService required")
    assert(type(assetId)=="number" and assetId>0,"approved numeric id required")
    waiting+=1
    -- Only eight startup workers can wait; no per-frame hooks or remotes.
    while busy do task.wait(.2) end
    waiting-=1
    busy=true
    peak=math.max(peak,1)
    -- The engine may yield or throw. The permit must be released even on
    -- Roblox HTTP/permission errors, so no later approved art is stranded.
    local ok,result=pcall(service.LoadAssetAsync,service,assetId)
    if ok then completed+=1 else failures+=1 end
    busy=false
    if not ok then error(result,0) end
    return result
end

function Gate.snapshot()
    return {
        InFlight=busy and 1 or 0,
        Waiting=waiting,
        PeakInFlight=peak,
        Completed=completed,
        Failed=failures,
    }
end

return Gate
