-- Original approved skyline roof sculpt; Roblox owner upload #42994003806.
-- Real Model 80692067525256, Moderation Approved on 11 November 2026.
-- Optional art never blocks the map, bots, round start, or fallbacks.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local ImportGate = require("./PremiumApprovedAssetImportGate")

local Assets = {}
local ID = 80692067525256
local EXPECTED = Vector3.new(11.4, 33.95, 7.19)
local started = false

local function validated(model)
    local pieces = 0
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            if not child:IsA("MeshPart")
                or child.CanCollide or child.CanTouch or child.CanQuery then
                return false
            end
            pieces += 1
        elseif child:IsA("LuaSourceContainer") then
            return false
        end
    end
    if pieces ~= 7 then return false end
    local _, size = model:GetBoundingBox()
    local horizontal = (math.abs(size.X - EXPECTED.X) <= .45
            and math.abs(size.Z - EXPECTED.Z) <= .45)
        or (math.abs(size.Z - EXPECTED.X) <= .45
            and math.abs(size.X - EXPECTED.Z) <= .45)
    return horizontal and math.abs(size.Y - EXPECTED.Y) <= .45
end

function Assets.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild("ApprovedSkylineDepthSculptTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedSkylineDepthSculptTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified", true)

    -- One creator-owned Model for all five variants. Stagger behind the
    -- near-field hero signatures, before the long-distance prop queues.
    task.spawn(function()
        task.wait(34)
        if holder:FindFirstChild("Roof") then return end
        for attempt = 1, 3 do
            local ok, raw = pcall(ImportGate.load, AssetService, ID)
            if ok and raw and raw:IsA("Model") then
                local clean = OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not validated(clean) then
                    if clean then clean:Destroy() end
                    warn("Original skyline depth model rejected: geometry")
                    return
                end
                clean.Name = "Roof"
                clean:SetAttribute("OwnerVerified", true)
                clean:SetAttribute("CosmeticOnly", true)
                clean:SetAttribute("OriginalSkylineDepthSculpt3D", true)
                clean:SetAttribute("Original3DAssetId", ID)
                clean.Parent = holder
                holder:SetAttribute("RoofReady", true)
                return
            end
            if typeof(raw) == "Instance" then raw:Destroy() end
            if attempt >= 3 then
                warn("Original skyline depth model unavailable", tostring(raw))
            else
                task.wait(attempt * 5)
            end
        end
    end)
end

return Assets
