-- Original creator-owned colossal skyfleet Model (not a MeshPart.MeshId).
-- Roblox moderation Approved in source import action #41634338244.
-- The native skyfleet is the always-available fallback if loading fails.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local PremiumSkyfleetMeshAssets = {}
local ASSET_ID = 84239592388200
local started = false

function PremiumSkyfleetMeshAssets.approvedId()
    return ASSET_ID
end

function PremiumSkyfleetMeshAssets.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild("PremiumSkyfleetMeshTemplates")
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "PremiumSkyfleetMeshTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified", true)
    -- Other approved original assets already load at round boot; delay this
    -- independent, cosmetic-only fetch to reduce owner-wide 429 spikes.
    task.spawn(function()
        task.wait(12)
        if holder:FindFirstChild("OriginalSkyfleetCarrier") then return end
        for attempt = 1, 3 do
            local ok, raw = pcall(AssetService.LoadAssetAsync,
                AssetService, ASSET_ID)
            if ok and raw and raw:IsA("Model") then
                local clean = OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean then
                    warn("Approved original 3D skyfleet asset rejected by sanitizer")
                    return
                end
                local meshes = 0
                for _, item in ipairs(clean:GetDescendants()) do
                    if item:IsA("BasePart") then
                        if not item:IsA("MeshPart") then
                            clean:Destroy()
                            warn("Skyfleet asset contains non-mesh source art")
                            return
                        end
                        meshes += 1
                    end
                end
                local _, bounds = clean:GetBoundingBox()
                -- The authored 53.2 x 19.63 x 49.6-stud OBJ may be oriented
                -- differently by Roblox's model importer. Accept either
                -- horizontal axis as long as the full silhouette is verified.
                local narrow = math.min(bounds.X, bounds.Z)
                local wide = math.max(bounds.X, bounds.Z)
                if meshes < 1 or meshes > 16
                    or narrow < 37 or wide < 45
                    or wide > 65 or bounds.Y < 9 or bounds.Y > 30 then
                    clean:Destroy()
                    warn("Original skyfleet asset fails true 3D dimensions",
                        meshes, bounds)
                    return
                end
                clean.Name = "OriginalSkyfleetCarrier"
                clean:SetAttribute("OwnerVerified", true)
                clean:SetAttribute("CosmeticOnly", true)
                clean:SetAttribute("Original3DAssetId", ASSET_ID)
                clean:SetAttribute("PremiumSkyfleet3D", true)
                clean.Parent = holder
                holder:SetAttribute("SkyfleetCarrierReady", true)
                return
            end
            if ok and typeof(raw) == "Instance" then raw:Destroy() end
            if attempt == 3 then
                warn("Original 3D carrier unavailable; live native ships remain",
                    tostring(raw))
            else
                task.wait(attempt * 3)
            end
        end
    end)
end

return PremiumSkyfleetMeshAssets
