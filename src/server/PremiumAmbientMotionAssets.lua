-- Owner-authored moving industrial machinery: five Roblox Model assets,
-- all moderation Approved, source workflow #41733818047.
-- Client Never calls AssetService. Server only replicates sanitized MeshParts.
-- The fallback animated Parts remain if a package cannot be loaded.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local Kit = {}
local APPROVED = {
    Classic = 102850052145878, -- ambient_drone
    Towers = 72210530094580, -- ambient_lift
    Crossroads = 116186226477876, -- ambient_transit
    Orbital = 127850230318627, -- ambient_satellite
    Harbor = 131294203899636, -- ambient_cargo
}
local ORDER = {"Classic", "Towers", "Crossroads", "Orbital", "Harbor"}
local started = false

function Kit.approvedId(variant)
    return APPROVED[variant]
end

local function validImportedModel(model)
    local count = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then return false end
            count += 1
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count < 1 or count > 12 then return false end
    local _, bounds = model:GetBoundingBox()
    return math.min(bounds.X, bounds.Y, bounds.Z) >= .5
        and math.max(bounds.X, bounds.Y, bounds.Z) <= 8.0
end

function Kit.start()
    if started then return end
    started = true

    local holder = ReplicatedStorage:FindFirstChild("ApprovedAmbientMotionTemplates")
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedAmbientMotionTemplates"
        holder.Parent = ReplicatedStorage
    end
    if not holder:IsA("Folder") then return end
    holder:SetAttribute("OwnerVerified", true)

    -- All other original exterior/collision-proximate art receives priority.
    -- This independent cosmetic lane is late, sequential, bounded and
    -- never delays a player join, bot, round or disaster transition.
    task.spawn(function()
        task.wait(24)
        for _, variant in ipairs(ORDER) do
            if not holder:FindFirstChild(variant) then
                for attempt = 1, 3 do
                    local ok, raw = pcall(AssetService.LoadAssetAsync,
                        AssetService, APPROVED[variant])
                    if ok and raw and raw:IsA("Model") then
                        local clean = OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not clean or not validImportedModel(clean) then
                            if clean then clean:Destroy() end
                            warn("Owner original moving ambient mesh rejected",
                                variant)
                            break
                        end
                        clean.Name = variant
                        clean:SetAttribute("Original3DAssetId", APPROVED[variant])
                        clean:SetAttribute("OwnerVerified", true)
                        clean:SetAttribute("CosmeticOnly", true)
                        clean:SetAttribute("ApprovedAmbientMotion3D", true)
                        clean.Parent = holder
                        holder:SetAttribute(variant .. "Ready", true)
                        break
                    end
                    if ok and typeof(raw) == "Instance" then raw:Destroy() end
                    if attempt == 3 then
                        warn("No approved moving ambient Model for", variant,
                            "— native animated fixture preserved", tostring(raw))
                    else
                        task.wait(4 * attempt)
                    end
                end
            end
        end
    end)
end

return Kit
