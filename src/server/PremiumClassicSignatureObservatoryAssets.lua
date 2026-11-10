-- Genuine owner-approved Classic observatory Model with two concave dishes.
-- Moderation: Approved (GitHub Actions run #42787663042), Model ID
-- 112493873850364. Delayed visual-only optional import, no gameplay.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")
local ActiveSignatureSchedule=require("./PremiumActiveVariantImportSchedule")

local Assets={}
local APPROVED_ID=112493873850364
local started=false

local function verifiedSource(model)
    local count=0
    for _,item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then
                return false
            end
            count+=1
        elseif item:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count~=7 then return false end
    local _,bounds=model:GetBoundingBox()
    -- OBJ has proven bounds 9.105 × 15.0875 × 1.03, normalized 1:4.
    -- Roblox importer may interchange horizontal axes, never vertical.
    local small,large=math.min(bounds.X,bounds.Z),
        math.max(bounds.X,bounds.Z)
    return math.abs(bounds.Y-15.0875)<.43
        and math.abs(small-1.03)<.20
        and math.abs(large-9.105)<.40
end

function Assets.start()
    if started then return end
    started=true
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedClassicSignatureObservatoryTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name="ApprovedClassicSignatureObservatoryTemplates"
        holder.Parent=ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- Main spawn and bot scheduler must never wait for optional art.
        ActiveSignatureSchedule.waitFor("Classic",44,104)
        if holder:FindFirstChild("DualDishObservatory") then return end
        for attempt=1,3 do
            local ok,raw=pcall(GlobalApprovedImportGate.load,
                AssetService,APPROVED_ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not verifiedSource(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved Classic original observatory rejected on geometry")
                    return
                end
                clean.Name="DualDishObservatory"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalClassicDualDishObservatory3D",true)
                clean:SetAttribute("Original3DAssetId",APPROVED_ID)
                clean.Parent=holder
                holder:SetAttribute("DualDishObservatoryReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Approved Classic observatory source unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
