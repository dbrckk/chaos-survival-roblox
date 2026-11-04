-- Authenticated original 3D lobby floor; no extra server physics or assets.
-- The same approved UV/tangent Model already covers the actual arena ground.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = {}
local SOURCE_ID = 72507987666671
local POSITIONS = {
    Vector2.new(-1, -1), Vector2.new(1, -1),
    Vector2.new(-1, 1), Vector2.new(1, 1),
}

local function sourceTemplate()
    local holder = ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local model = holder:FindFirstChild("PremiumGroundTile")
    if not model or not model:IsA("Model") or model.Parent ~= holder
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("Original3DAssetId") ~= SOURCE_ID
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("PremiumGround3D") ~= true then return nil end
    local count = 0
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return nil end
            count += 1
        elseif item:IsA("LuaSourceContainer") then return nil end
    end
    if count < 1 or count > 12 then return nil end
    local _, size = model:GetBoundingBox()
    if size.X < 30 or size.X > 65 or size.Z < 30 or size.Z > 65
        or size.Y <= 0 or size.Y > 1.5 then return nil end
    return model, size, count
end

function Kit.tileBudget(tier, pressure)
    if tier == "Low" then return 0 end
    local n = tonumber(pressure)
    if n == nil or n ~= n then n = 0 end
    n = math.clamp(math.floor(n), 0, 2)
    if tier == "High" then
        return n == 0 and 4 or (n == 1 and 2 or 0)
    end
    if tier == "Medium" then
        return n == 0 and 2 or (n == 1 and 1 or 0)
    end
    return 0
end

local function discard(staged)
    for _, model in ipairs(staged) do model:Destroy() end
end

-- Returns actual (MeshParts, tiles). Prepare EVERYTHING before parenting.
-- The 74x74 collidable lobby Floor, instructions and spawns never change.
function Kit.install(folder, floor, tier, pressure)
    local wanted = Kit.tileBudget(tier, pressure)
    if wanted == 0 or not folder or not folder:IsA("Folder")
        or not floor or not floor:IsA("BasePart") or not floor.Parent
        or floor.Name ~= "Floor" or not floor.Anchored or not floor.CanCollide
        or floor.Size.X < 72 or floor.Size.X > 76
        or floor.Size.Z < 72 or floor.Size.Z > 76 then return 0, 0 end
    local source, sourceSize, partsPerTile = sourceTemplate()
    if not source then return 0, 0 end
    -- 34-stud-wide tile islands lie within the lobby's 68-stud inset.
    -- Their top is just above inset but below real tutorial signs/paths.
    local span = math.min(floor.Size.X, floor.Size.Z) * .46
    local scale = math.min(.95, span / sourceSize.X, span / sourceSize.Z)
    if scale < .58 then return 0, 0 end
    local staged = {}
    for i = 1, wanted do
        local clone = source:Clone()
        if not pcall(function() clone:ScaleTo(scale) end) then
            clone:Destroy()
            discard(staged)
            return 0, 0
        end
        local reference, dimensions = clone:GetBoundingBox()
        if dimensions.X > span + .1 or dimensions.Z > span + .1
            or dimensions.Y <= 0 or dimensions.Y > 1.10 then
            clone:Destroy()
            discard(staged)
            return 0, 0
        end
        local position = POSITIONS[i]
        local target = floor.CFrame
            * CFrame.new(position.X * span * .5,
                floor.Size.Y * .5 + .164 - dimensions.Y * .5,
                position.Y * span * .5)
            * CFrame.Angles(0, (i - 1) * math.pi * .5, 0)
        local count = 0
        for _, part in ipairs(clone:GetDescendants()) do
            if part:IsA("MeshPart") then
                part.CFrame = target * reference:ToObjectSpace(part.CFrame)
                part.Anchored = true
                part.Massless = true
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.CastShadow = false
                part:SetAttribute("OriginalLobbyGround3D", true)
                part:SetAttribute("Original3DAssetId", SOURCE_ID)
                count += 1
            end
        end
        if count ~= partsPerTile then
            clone:Destroy()
            discard(staged)
            return 0, 0
        end
        clone.Name = "ApprovedOriginalLobbyFloor3D_" .. tostring(i)
        clone:SetAttribute("CosmeticOnly", true)
        clone:SetAttribute("Original3DAssetId", SOURCE_ID)
        staged[#staged + 1] = clone
    end
    for _, model in ipairs(staged) do model.Parent = folder end
    return #staged * partsPerTile, #staged
end

return Kit
