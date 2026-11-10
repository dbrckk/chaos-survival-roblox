-- Approved, owner-authored service equipment for all five arenas.
-- The allowlist is backed by upload workflow 41729439190: five moderated
-- creator-owned Model packages (NOT MeshPart.MeshId strings).
-- Optional cosmetics; failed imports leave original Roblox service props.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local ServiceAssets = {}
local APPROVED = {
    Classic = 108954400662606, -- service_camera
    Towers = 106083832432833, -- service_maintenance
    Crossroads = 94223777350022, -- service_wayfinder
    Orbital = 127295681925871, -- service_orbital
    Harbor = 137255432266916, -- service_mooring
}
local ORDER = {"Classic", "Towers", "Crossroads", "Orbital", "Harbor"}
local started = false

function ServiceAssets.approvedId(variant)
    return APPROVED[variant]
end

local function authenticMesh(model)
    local n = 0
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return false end
            n += 1
        elseif item:IsA("LuaSourceContainer") then
            return false
        end
    end
    if n < 1 or n > 12 then return false end
    local _, bounds = model:GetBoundingBox()
    -- Five approved originals are small, genuine mechanical sculptures.
    -- Reject scale-jacked third-party models even with a reused display name.
    local longest = math.max(bounds.X, bounds.Y, bounds.Z)
    local shortest = math.min(bounds.X, bounds.Y, bounds.Z)
    return shortest >= .65 and longest <= 6.0
end

function ServiceAssets.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild("ApprovedServiceEquipmentTemplates")
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedServiceEquipmentTemplates"
        holder.Parent = ReplicatedStorage
    end
    if not holder:IsA("Folder") then return end
    holder:SetAttribute("OwnerVerified", true)
    -- Original exterior models, routes, facade profiles and giant carriers
    -- own first-use asset bandwidth. Delay optional five miniature machines
    -- and serialize the lane to avoid five concurrent Roblox 429 responses.
    task.spawn(function()
        task.wait(16)
        for _, variant in ipairs(ORDER) do
            if not holder:FindFirstChild(variant) then
                for attempt = 1, 3 do
                    local ok, raw = pcall(GlobalApprovedImportGate.load,
                        AssetService, APPROVED[variant])
                    if ok and raw and raw:IsA("Model") then
                        local clean = OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not clean or not authenticMesh(clean) then
                            if clean then clean:Destroy() end
                            warn("Original service 3D package failed verification", variant)
                            break
                        end
                        clean.Name = variant
                        clean:SetAttribute("Original3DAssetId", APPROVED[variant])
                        clean:SetAttribute("OwnerVerified", true)
                        clean:SetAttribute("CosmeticOnly", true)
                        clean:SetAttribute("OriginalService3D", true)
                        clean.Parent = holder
                        holder:SetAttribute(variant .. "Ready", true)
                        break
                    end
                    if ok and typeof(raw) == "Instance" then raw:Destroy() end
                    if attempt == 3 then
                        warn("Approved service mesh could not load; native art stays",
                            variant, tostring(raw))
                    else
                        task.wait(attempt * 4)
                    end
                end
            end
        end
    end)
end

return ServiceAssets
