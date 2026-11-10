-- The *actual* creator-owned 3D Harbor megagantry.
-- Verified moderation receipt: GitHub run 42780163672, ID 124368710235343.
-- Optional source-only art; never blocks round startup or hoist gameplay.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")
local ActiveSignatureSchedule=require("./PremiumActiveVariantImportSchedule")

local Assets={}
local OWNER_ID=124368710235343
local started=false

local function verifiedMesh(model)
    local count=0
    for _,item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return false end
            count+=1
        elseif item:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count~=7 then return false end
    -- Authored OBJ source dimensions from successful source-gate:
    -- 40.8 x 14.0425 x 9.141 (one homogeneous source pivot). The
    -- glTF importer may swap its two horizontal axes.
    local _,b=model:GetBoundingBox()
    local small,large=math.min(b.X,b.Z),math.max(b.X,b.Z)
    return math.abs(b.Y-14.0425)<.44
        and math.abs(small-9.141)<.40
        and math.abs(large-40.8)<.52
end

function Assets.start()
    if started then return end
    started=true
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedHarborSignatureGantryTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name="ApprovedHarborSignatureGantryTemplates"
        holder.Parent=ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- First playable round, bots, and core arena generation come first.
        ActiveSignatureSchedule.waitFor("Harbor",46,91)
        if holder:FindFirstChild("SculptedGantry") then return end
        for attempt=1,3 do
            local ok,raw=pcall(GlobalApprovedImportGate.load,
                AssetService,OWNER_ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not verifiedMesh(clean) then
                    if clean then clean:Destroy() end
                    warn("Original Harbor signature gantry failed mesh checks")
                    return
                end
                clean.Name="SculptedGantry"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalHarborSignatureGantry3D",true)
                clean:SetAttribute("Original3DAssetId",OWNER_ID)
                clean.Parent=holder
                holder:SetAttribute("SculptedGantryReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Approved Harbor signature gantry unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
