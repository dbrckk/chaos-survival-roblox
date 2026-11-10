-- Four Roblox Approved original industrial 3D facade + roofline Models.
-- Official creator asset IDs: GitHub Action #41629861517 (four Approved).
-- Optional cosmetic art only. Never alter authoritative game geometry.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

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

local function validatedGeometry(model)
    local meshCount = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then return false end
            meshCount += 1
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if meshCount < 1 or meshCount > 24 then return false end
    local _, bounds = model:GetBoundingBox()
    return bounds.X >= 8 and bounds.X <= 31
        and bounds.Y >= 12 and bounds.Y <= 48
        and bounds.Z >= 3 and bounds.Z <= 28
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

    local function loadOne(name)
        for attempt = 1, 3 do
            local ok, raw = pcall(GlobalApprovedImportGate.load,
                AssetService, APPROVED[name])
            if ok and raw and raw:IsA("Model") then
                local clean = OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not validatedGeometry(clean) then
                    if clean then clean:Destroy() end
                    warn("Original approved district facade rejected by geometry gate",
                        name)
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
                warn("Original approved district facade unavailable; native fallback remains",
                    name, tostring(raw))
                return
            end
            task.wait(attempt * 3)
        end
    end

    -- OriginalMeshScenery already has two 3D asset network lanes; the
    -- earlier facade loader spawned FOUR simultaneous AssetService calls
    -- at player join, adding unnecessary owner-wide API throttling.
    -- Use ONE sequential lane, non-blocking to rounds and player spawn.
    task.spawn(function()
        for _, name in ipairs(ORDER) do
            loadOne(name)
        end
    end)
end

return PremiumDistrictFacadeAssets
