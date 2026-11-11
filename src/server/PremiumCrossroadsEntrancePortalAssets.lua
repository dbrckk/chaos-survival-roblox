-- Four authentic decorative Crossroads gateways share one imported,
-- owner-approved original seven-material Model (127067628128103).
-- Source import GitHub Actions 42872132972, Moderation Approved.
-- Never modifies map physics or obstructs real gameplay paths.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")
local ActiveSignatureSchedule = require("./PremiumActiveVariantImportSchedule")

local Assets={}
local ID=127067628128103
local BOUNDS=Vector3.new(19.2,10.59,1.755)
local HOLDER="ApprovedCrossroadsEntrancePortalTemplates"
local started=false

local function genuine(model)
    local n=0
    for _,item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart")
                or item.CanCollide or item.CanTouch or item.CanQuery then
                return false
            end
            n+=1
        elseif item:IsA("LuaSourceContainer") then
            return false
        end
    end
    if n~=7 then return false end
    local _,size=model:GetBoundingBox()
    local horizontal={size.X,size.Z}
    table.sort(horizontal)
    return math.abs(size.Y-BOUNDS.Y)<=.32
        and math.abs(horizontal[1]-BOUNDS.Z)<=.33
        and math.abs(horizontal[2]-BOUNDS.X)<=.38
end

function Assets.start()
    if started then return end
    started=true
    local holder=ReplicatedStorage:FindFirstChild(HOLDER)
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name=HOLDER
        holder.Parent=ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- Optional server-only decorative import, one source for 4 instances.
        -- Staggered after essential round and character initialization.
        -- Active Crossroads can request its portal during round one.
        -- Other maps retain the 92-second fallback and approved FIFO.
        ActiveSignatureSchedule.waitFor("Crossroads",44,92)
        if holder:FindFirstChild("EntrancePortal") then return end
        for attempt=1,3 do
            local ok,raw=pcall(GlobalApprovedImportGate.load,AssetService,ID)
            if ok and raw and raw:IsA("Model") then
                local safe=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not safe or not genuine(safe) then
                    if safe then safe:Destroy() end
                    warn("Authentic Crossroads entrance portal geometry rejected")
                    return
                end
                safe.Name="EntrancePortal"
                safe:SetAttribute("OwnerVerified",true)
                safe:SetAttribute("CosmeticOnly",true)
                safe:SetAttribute("OriginalCrossroadsEntrancePortal3D",true)
                safe:SetAttribute("Original3DAssetId",ID)
                safe.Parent=holder
                holder:SetAttribute("EntrancePortalReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Crossroads owner-approved entrance portal unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
