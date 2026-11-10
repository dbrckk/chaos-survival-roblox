-- Source-gated real ocean freighter for the EXISTING distant Storm
-- Harbor ship. Creator-owned approved Roblox Model 128820723471019.
-- Imported 4,918 triangles, 7 MeshParts, UV/tangents, 20 ISO containers.
-- All server-side original Parts remain as streamed fallback.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")
local Kit = {}
local ASSET_ID = 128820723471019
local started = false

function Kit.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild("ApprovedHarborFreighterTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedHarborFreighterTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified", true)
    task.spawn(function()
        -- Prioritize gameplay, near-camera floors and true Harbor routes.
        task.wait(66)
        for attempt = 1, 3 do
            local ok, imported = pcall(
                GlobalApprovedImportGate.load, AssetService, ASSET_ID)
            if ok and imported and imported:IsA("Model") then
                local clean = OriginalMeshScenery.sanitize(imported)
                imported:Destroy()
                if not clean then return end
                local count = 0
                for _, part in ipairs(clean:GetDescendants()) do
                    if not part:IsA("MeshPart") then
                        clean:Destroy()
                        return
                    end
                    count += 1
                end
                local _, bounds = clean:GetBoundingBox()
                local long = math.max(bounds.X, bounds.Z)
                local short = math.min(bounds.X, bounds.Z)
                if count ~= 7 or long < 28.6 or long > 29.6
                    or short < 6.0 or short > 6.9
                    or bounds.Y < 9.1 or bounds.Y > 10.6 then
                    clean:Destroy()
                    warn("Approved Harbor freighter failed source geometry guard")
                    return
                end
                clean.Name = "OriginalContainerFreighter"
                clean:SetAttribute("OwnerVerified", true)
                clean:SetAttribute("CosmeticOnly", true)
                clean:SetAttribute("OriginalHarborFreighter3D", true)
                clean:SetAttribute("Original3DAssetId", ASSET_ID)
                clean.Parent = holder
                holder:SetAttribute("FreighterReady", true)
                return
            end
            if ok and typeof(imported) == "Instance" then imported:Destroy() end
            if attempt < 3 then task.wait(attempt * 3) end
        end
        warn("Original Harbor freighter unavailable; native ship retained")
    end)
end

return Kit
