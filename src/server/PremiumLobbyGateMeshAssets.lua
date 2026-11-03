-- The actual creator-owned original UV/tangent 3D lobby gate Roblox Model.
-- Source validation #41647780811; authorized import #41648061984,
-- Model ID 136009650118642 with moderation state Approved.
-- Server replicates only inert, rigorously sanitized approved MeshParts.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local PremiumLobbyGateMeshAssets = {}
local ASSET_ID = 136009650118642
local started = false

function PremiumLobbyGateMeshAssets.approvedId()
    return ASSET_ID
end

local function matchesSourceBounds(model)
    local count = 0
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            if not child:IsA("MeshPart") then return false end
            count += 1
        elseif child:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count < 1 or count > 12 then return false end
    local _, bounds = model:GetBoundingBox()
    -- The original artwork is ~26 wide, ~20 tall, ~5.5 deep; allow a
    -- horizontal 90-degree Roblox import rotation, NEVER a sideways arch.
    local width = math.max(bounds.X, bounds.Z)
    local depth = math.min(bounds.X, bounds.Z)
    return width >= 24 and width <= 28
        and bounds.Y >= 18 and bounds.Y <= 22
        and depth >= 4 and depth <= 8
end

function PremiumLobbyGateMeshAssets.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild("PremiumLobbyGateMeshTemplates")
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "PremiumLobbyGateMeshTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified", true)

    -- Other approved original asset loads start at server boot. Schedule
    -- this OPTIONAL lobby cosmetic later; never block players or hazards.
    task.spawn(function()
        task.wait(9)
        for attempt = 1, 3 do
            local ok, raw = pcall(AssetService.LoadAssetAsync,
                AssetService, ASSET_ID)
            if ok and raw and raw:IsA("Model") then
                local clean = OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not matchesSourceBounds(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved genuine lobby gate Model rejected by source geometry gate")
                    return
                end
                clean.Name = "OriginalLobbyGate"
                clean:SetAttribute("Original3DAssetId", ASSET_ID)
                clean:SetAttribute("OwnerVerified", true)
                clean:SetAttribute("CosmeticOnly", true)
                clean:SetAttribute("GenuineLobbyGate3D", true)
                clean.Parent = holder
                holder:SetAttribute("LobbyGate3DReady", true)
                return
            end
            if ok and typeof(raw) == "Instance" then raw:Destroy() end
            if attempt == 3 then
                warn("Original 3D lobby gate unavailable; original native gate remains",
                    tostring(raw))
            else
                task.wait(attempt * 3)
            end
        end
    end)
end

return PremiumLobbyGateMeshAssets
