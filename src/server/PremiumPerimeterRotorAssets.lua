-- Verified creator-owned original rotor Model, workflow #42691052644.
-- Roblox moderation Approved; no client-selected asset IDs, no gameplay Parts.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Assets = {}
local ID = 133526819668194
local started = false

local function geometryAllowed(model)
    local count = 0
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return false end
            count += 1
            if item.CanCollide or item.CanTouch or item.CanQuery then
                return false
            end
        elseif item:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count ~= 7 then return false end
    local _, dimensions = model:GetBoundingBox()
    -- glTF may import with an axial rotation. Accept only the real thin
    -- disc envelope, never an arbitrarily scaled/generic foreign model.
    local sides = {dimensions.X, dimensions.Y, dimensions.Z}
    table.sort(sides)
    return sides[1] >= 0.65 and sides[1] <= 1.15
        and sides[2] >= 2.35 and sides[2] <= 2.95
        and sides[3] >= 2.35 and sides[3] <= 2.95
end

function Assets.approvedId()
    return ID
end

function Assets.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedPerimeterRotorTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedPerimeterRotorTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified", true)
    -- Late, serialized OPTIONAL art import, never delay a playable round.
    task.spawn(function()
        task.wait(74)
        if holder:FindFirstChild("Rotor") then return end
        for attempt = 1, 3 do
            local ok, raw = pcall(GlobalApprovedImportGate.load, AssetService, ID)
            if ok and raw and raw:IsA("Model") then
                local clean = OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not geometryAllowed(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved perimeter rotor rejected: unsafe source geometry")
                    return
                end
                clean.Name = "Rotor"
                clean:SetAttribute("OwnerVerified", true)
                clean:SetAttribute("CosmeticOnly", true)
                clean:SetAttribute("OriginalPerimeterRotor3D", true)
                clean:SetAttribute("Original3DAssetId", ID)
                clean.Parent = holder
                holder:SetAttribute("RotorReady", true)
                return
            end
            if typeof(raw) == "Instance" then raw:Destroy() end
            if attempt == 3 then
                warn("Approved perimeter rotor unavailable; native cylinders retained",
                    tostring(raw))
            else
                task.wait(4 * attempt)
            end
        end
    end)
end

return Assets
