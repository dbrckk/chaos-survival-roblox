-- Four creator-owned, Roblox-moderation-approved original 3D building facades.
-- Sanitized exactly once on the server; clients clone only inert templates.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local PremiumDistrictFacadeAssets = {}
local APPROVED = {
    Observatory = 132020956214241,
    Freight = 88725004643299,
    Turbine = 84217436280282,
    Aerial = 135791763112202,
}
local ORDER = {"Observatory", "Freight", "Turbine", "Aerial"}
local started = false

function PremiumDistrictFacadeAssets.approvedId(name)
    return APPROVED[name]
end

function PremiumDistrictFacadeAssets.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild("ApprovedDistrictFacadeTemplates")
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedDistrictFacadeTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified", true)

    for _, name in ipairs(ORDER) do
        task.spawn(function()
            for attempt = 1, 3 do
                local ok, raw = pcall(AssetService.LoadAssetAsync,
                    AssetService, APPROVED[name])
                if ok and raw and raw:IsA("Model") then
                    local clean = OriginalMeshScenery.sanitize(raw)
                    raw:Destroy()
                    if not clean then
                        warn("Approved original district facade failed sanitizer", name)
                        return
                    end
                    local meshes = 0
                    for _, item in ipairs(clean:GetDescendants()) do
                        if item:IsA("BasePart") then
                            if not item:IsA("MeshPart") then
                                clean:Destroy()
                                warn("District facade must be original MeshParts", name)
                                return
                            end
                            meshes += 1
                        end
                    end
                    local _, bounds = clean:GetBoundingBox()
                    if meshes < 1 or meshes > 24
                        or bounds.X < 8 or bounds.X > 31
                        or bounds.Y < 12 or bounds.Y > 48
                        or bounds.Z < 3 or bounds.Z > 28 then
                        clean:Destroy()
                        warn("District facade geometry outside verified profile", name)
                        return
                    end
                    clean.Name = name
                    clean:SetAttribute("OwnerVerified", true)
                    clean:SetAttribute("CosmeticOnly", true)
                    clean:SetAttribute("Original3DAssetId", APPROVED[name])
                    clean:SetAttribute("DistrictFacade3D", true)
                    clean.Parent = holder
                    holder:SetAttribute(name .. "Ready", true)
                    return
                end
                if ok and typeof(raw) == "Instance" then raw:Destroy() end
                if attempt == 3 then
                    warn("Approved original district facade unavailable; native facade retained",
                        name, tostring(raw))
                else
                    task.wait(attempt * 3)
                end
            end
        end)
    end
end

return PremiumDistrictFacadeAssets
