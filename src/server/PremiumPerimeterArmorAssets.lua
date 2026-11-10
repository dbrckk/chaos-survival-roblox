-- P4 authentic owner-approved industrial wing & cap source Models.
-- GitHub source-gate/upload workflow 42694744112, both Moderation Approved.
-- OPTIONAL art only: never blocks player arrival, bots or round lifecycle.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Assets = {}
local SOURCES = {
    {name = "Wing", id = 138096293972093,
        width = 3.277, height = 1.64, depth = 5.62},
    {name = "Cap", id = 88962643359267,
        width = 2.7699, height = 2.14, depth = 2.34},
}
local started = false

local function validGeometry(model, profile)
    local count = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return false end
            count += 1
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count ~= 7 then return false end
    local _, box = model:GetBoundingBox()
    if math.abs(box.Y - profile.height) > 0.32 then return false end
    -- Roblox glTF can swap horizontal axes, but never accept a different
    -- structure by silently non-uniform stretching the imported asset.
    local x, z = math.min(box.X, box.Z), math.max(box.X, box.Z)
    local sx, sz = math.min(profile.width, profile.depth),
        math.max(profile.width, profile.depth)
    return math.abs(x - sx) <= 0.30
        and math.abs(z - sz) <= 0.32
end

function Assets.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedPerimeterArmorTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedPerimeterArmorTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified", true)
    task.spawn(function()
        -- All first-minute gameplay and higher-priority models load first.
        task.wait(96)
        for _, profile in ipairs(SOURCES) do
            if not holder:FindFirstChild(profile.name) then
                for attempt = 1, 3 do
                    local ok, raw = pcall(GlobalApprovedImportGate.load,
                        AssetService, profile.id)
                    if ok and raw and raw:IsA("Model") then
                        local sanitized = OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not sanitized
                            or not validGeometry(sanitized, profile) then
                            if sanitized then sanitized:Destroy() end
                            warn("Approved perimeter armor rejected",
                                profile.name)
                            break
                        end
                        sanitized.Name = profile.name
                        sanitized:SetAttribute("Original3DAssetId", profile.id)
                        sanitized:SetAttribute("OwnerVerified", true)
                        sanitized:SetAttribute("CosmeticOnly", true)
                        sanitized:SetAttribute("OriginalPerimeterArmor3D", true)
                        sanitized.Parent = holder
                        holder:SetAttribute(profile.name .. "Ready", true)
                        break
                    end
                    if typeof(raw) == "Instance" then raw:Destroy() end
                    if attempt == 3 then
                        warn("Approved perimeter armor unavailable",
                            profile.name, tostring(raw))
                    else
                        task.wait(attempt * 5)
                    end
                end
            end
            task.wait(5)
        end
    end)
end

return Assets
