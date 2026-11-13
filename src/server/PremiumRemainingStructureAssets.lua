-- Five genuinely imported, creator-owned Roblox Approved original models.
-- Three stage-specific overhead arches, one nonphysical architectural casing
-- and one non-walkable Orbital ramp underframe. Never imports client requests.
-- These source IDs were verified by Roblox Asset API upload/moderation run
-- 43467373476. Geometry bounds and exact 7-MeshPart provenance fail closed.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local Gate = require("./PremiumApprovedAssetImportGate")

local Kit = {}
local APPROVED = {
    Access = {id=110243423264048, major=17.6, minor=3.9, height=17.53},
    Transfer = {id=107273631120961, major=17.6, minor=4.1, height=18.33},
    Summit = {id=127049813505254, major=17.6, minor=5.2, height=19.73},
    Casing = {id=130196548599769, major=8.58, minor=5.3, height=10.378},
    Helix = {id=106863534763803, major=23.6, minor=5.08, height=1.453},
}
local ORDER = {"Access", "Transfer", "Summit", "Casing", "Helix"}
local started = false

function Kit.approvedId(name)
    local rule = APPROVED[name]
    return rule and rule.id or nil
end

local function genuine(model, spec)
    if not model or not model:IsA("Model") then return false end
    local pieces = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or not part.Anchored
                or part.CanCollide or part.CanTouch or part.CanQuery
                or not part.Massless then
                return false
            end
            pieces += 1
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if pieces ~= 7 then return false end
    local _, box = model:GetBoundingBox()
    local major, minor = math.max(box.X, box.Z), math.min(box.X, box.Z)
    return math.abs(major-spec.major) < .75
        and math.abs(minor-spec.minor) < .75
        and math.abs(box.Y-spec.height) < .8
end

function Kit.start()
    if started then return end
    started = true
    local folder = ReplicatedStorage:FindFirstChild("ApprovedRemainingStructureTemplates")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ApprovedRemainingStructureTemplates"
        folder.Parent = ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified", true)

    -- Existing asset loaders are already running on server boot. A separate
    -- late SERIAL lane never blocks a round, client, bot or game startup;
    -- the shared GlobalApprovedImportGate also limits all Roblox imports.
    task.spawn(function()
        task.wait(38)
        for _, name in ipairs(ORDER) do
            local spec = APPROVED[name]
            for attempt=1,3 do
                local ok, raw = pcall(Gate.load, AssetService, spec.id)
                if ok and raw and raw:IsA("Model") then
                    local clean = OriginalMeshScenery.sanitize(raw)
                    raw:Destroy()
                    if not genuine(clean, spec) then
                        if clean then clean:Destroy() end
                        warn("P4 structure source geometry rejected", name)
                        break
                    end
                    clean.Name = name
                    clean:SetAttribute("OwnerVerified", true)
                    clean:SetAttribute("CosmeticOnly", true)
                    clean:SetAttribute("Original3DAssetId", spec.id)
                    clean:SetAttribute("P4OriginalRemainingStructure3D", true)
                    clean.Parent = folder
                    folder:SetAttribute(name.."Ready", true)
                    break
                end
                if ok and typeof(raw) == "Instance" then raw:Destroy() end
                if attempt == 3 then
                    warn("P4 structure 3D import unavailable; native fallback",
                        name, tostring(raw))
                else
                    task.wait(attempt*4)
                end
            end
            task.wait(.35)
        end
    end)
end

return Kit
