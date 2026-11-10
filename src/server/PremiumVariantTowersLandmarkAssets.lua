-- Verified original Towers corner machinery sculpture. Approved Roblox Model
-- 72143366927826, creator import action 42861370182.
-- Optional cosmetic only, never blocks rounds or modifies native collision.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Assets = {}
local ASSET_ID = 72143366927826
local SIZE = Vector3.new(7.36,24.9,7.36)
local started = false

local function valid(model)
    local n = 0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return false end
            n += 1
        elseif part:IsA("LuaSourceContainer") then return false end
    end
    if n ~= 7 then return false end
    local _,bounds = model:GetBoundingBox()
    return (bounds-SIZE).Magnitude <= .55
end

function Assets.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild("ApprovedVariantTowersLandmarkTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedVariantTowersLandmarkTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    -- Stagger after the first wave of essential scenery imports. This
    -- one shared source is loaded ONCE and reused by up to four corners.
    task.spawn(function()
        task.wait(62)
        if holder:FindFirstChild("Machinery") then return end
        for attempt = 1, 3 do
            local ok,raw = pcall(GlobalApprovedImportGate.load,
                AssetService,ASSET_ID)
            if ok and raw and raw:IsA("Model") then
                local clean = OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not valid(clean) then
                    if clean then clean:Destroy() end
                    warn("Verified Towers machinery geometry rejected")
                    return
                end
                clean.Name = "Machinery"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalTowersMachinery3D",true)
                clean:SetAttribute("Original3DAssetId",ASSET_ID)
                clean.Parent = holder
                holder:SetAttribute("MachineryReady",true)
                return
            end
            if typeof(raw) == "Instance" then raw:Destroy() end
            if attempt == 3 then
                warn("Verified Towers machinery source unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
