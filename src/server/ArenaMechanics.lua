local Players = game:GetService("Players")
local MovementSafety = if script then require(script.Parent.MovementSafety) else require("./MovementSafety")
local CrossroadsFluxRelay = if script then require(script.Parent.CrossroadsFluxRelay) else require("./CrossroadsFluxRelay")
local helixModule = script and script.Parent:FindFirstChild("OrbitalHelix")
local OrbitalHelix = if helixModule
    then require(helixModule)
    else require("./OrbitalHelix")
local gridModule = script and script.Parent:FindFirstChild("GridCircuitService")
local GridCircuitService = if gridModule
    then require(gridModule)
    else require("./GridCircuitService")
local ArenaMechanics = {}

ArenaMechanics.Definitions = {
    Classic = {
        Name = "ESCAPE PADS",
        Hint = "Blue escape pads launch outward; touch four Grid Circuit nodes clockwise for a skill clear",
        Color = Color3.fromRGB(90, 180, 255),
        Pads = {
            {offset = Vector3.new(18, 1.7, 0), impulse = Vector3.new(38, 10, 0)},
            {offset = Vector3.new(-18, 1.7, 0), impulse = Vector3.new(-38, 10, 0)},
            {offset = Vector3.new(0, 1.7, 18), impulse = Vector3.new(0, 10, 38)},
            {offset = Vector3.new(0, 1.7, -18), impulse = Vector3.new(0, 10, -38)},
        },
    },
    Towers = {
        Name = "UPDRAFT PADS",
        Hint = "Cyan pads launch you upward to reopen vertical escape routes",
        Color = Color3.fromRGB(65, 220, 255),
        Pads = {
            {offset = Vector3.new(-28, 1.7, -28), impulse = Vector3.new(8, 55, 8)},
            {offset = Vector3.new(28, 1.7, -28), impulse = Vector3.new(-8, 55, 8)},
            {offset = Vector3.new(-28, 1.7, 28), impulse = Vector3.new(8, 55, -8)},
            {offset = Vector3.new(28, 1.7, 28), impulse = Vector3.new(-8, 55, -8)},
        },
    },
    Crossroads = {
        Name = "LANE BOOSTERS",
        Hint = "Pink launch pads rush outward; timed cyan Flux Relays send you back toward the hub",
        Color = Color3.fromRGB(235, 105, 220),
        Pads = {
            {offset = Vector3.new(18, 1.7, 0), impulse = Vector3.new(46, 8, 0)},
            {offset = Vector3.new(-18, 1.7, 0), impulse = Vector3.new(-46, 8, 0)},
            {offset = Vector3.new(0, 1.7, 18), impulse = Vector3.new(0, 8, 46)},
            {offset = Vector3.new(0, 1.7, -18), impulse = Vector3.new(0, 8, -46)},
        },
    },
    Orbital = {
        Name = "ORBIT BOOSTERS",
        Hint = "Green pads push you around the ring to keep circular routes flowing",
        Color = Color3.fromRGB(65, 255, 205),
        Pads = (function()
            local result = {}
            for index = 0, 7 do
                local angle = math.rad(index * 45)
                local radius = 31
                local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
                table.insert(result, {
                    offset = Vector3.new(math.cos(angle) * radius, 1.7, math.sin(angle) * radius),
                    impulse = tangent * 42 + Vector3.new(0, 9, 0),
                })
            end
            return result
        end)(),
    },
}

local function createPad(folder, center, definition, index)
    local padDefinition = definition.Pads[index]
    local pad = Instance.new("Part")
    pad.Name = "MobilityPad" .. tostring(index)
    pad.Size = Vector3.new(6.5, 0.35, 6.5)
    pad.Position = center + padDefinition.offset
    pad.Anchored = true
    pad.CanCollide = false
    pad.CanTouch = true
    pad.CanQuery = false
    pad.CastShadow = false
    pad.Material = Enum.Material.Neon
    pad.Color = definition.Color
    pad.Transparency = 0.12
    pad.TopSurface = Enum.SurfaceType.Smooth
    pad.BottomSurface = Enum.SurfaceType.Smooth
    pad:SetAttribute("ArenaMobilityPad", true)
    pad:SetAttribute("ImpulseX", padDefinition.impulse.X)
    pad:SetAttribute("ImpulseY", padDefinition.impulse.Y)
    pad:SetAttribute("ImpulseZ", padDefinition.impulse.Z)
    pad.Parent = folder

    local light = Instance.new("PointLight")
    light.Name = "MobilityPadLight"
    light.Color = definition.Color
    light.Brightness = 0.75
    light.Range = 11
    light.Shadows = false
    light.Parent = pad

    return pad, padDefinition.impulse
end

local function rootAndPlayerFromHit(hit)
    local current = hit
    while current and current ~= workspace do
        if current:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(current)
            if player then
                local humanoid = current:FindFirstChildOfClass("Humanoid")
                local root = current:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
                    return root, player
                end
                return nil, nil
            end
        end
        current = current.Parent
    end

    return nil, nil
end

function ArenaMechanics.get(variantId)
    return ArenaMechanics.Definitions[variantId]
end

function ArenaMechanics.impulseFor(impulse, overdrive)
    local multiplier = overdrive == true and 1.28 or 1
    return impulse * multiplier
end

function ArenaMechanics.readPadImpulse(pad, fallback)
    local default = typeof(fallback) == "Vector3" and fallback or Vector3.zero
    if not pad or not pad:IsA("BasePart") then
        return default
    end

    return Vector3.new(
        tonumber(pad:GetAttribute("ImpulseX")) or default.X,
        tonumber(pad:GetAttribute("ImpulseY")) or default.Y,
        tonumber(pad:GetAttribute("ImpulseZ")) or default.Z
    )
end

function ArenaMechanics.cooldownFor(finalRush)
    return finalRush == true and 0.65 or 1.1
end

function ArenaMechanics.safeVelocity(currentVelocity, impulse)
    return MovementSafety.addImpulse(
        currentVelocity,
        impulse,
        60,
        -52,
        58
    )
end

function ArenaMechanics.start(ctx, variantId)
    local definition = ArenaMechanics.get(variantId)
    if not definition then
        return nil
    end

    local generatedMap = workspace:FindFirstChild("GeneratedMap")
    local arena = generatedMap and generatedMap:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not base or not base:IsA("BasePart") then
        return nil
    end

    local oldFolder = arena:FindFirstChild("Mechanics")
    if oldFolder then
        oldFolder:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = "Mechanics"
    folder:SetAttribute("MechanicName", definition.Name)
    folder:SetAttribute("MechanicHint", definition.Hint)
    folder.Parent = arena
    table.insert(ctx.Cleanup, folder)

    local cooldownUntil = {}

    for index = 1, #definition.Pads do
        local pad, impulse = createPad(folder, base.Position, definition, index)

        pad.Touched:Connect(function(hit)
            if not ctx.Active() then
                return
            end

            local root, player = rootAndPlayerFromHit(hit)
            if not root or not player or not ctx.IsContestantActive(player) then
                return
            end

            local now = os.clock()
            if (cooldownUntil[player.UserId] or 0) > now then
                return
            end
            local finalRush = ctx.FinalRush and ctx.FinalRush() == true
            cooldownUntil[player.UserId] = now + ArenaMechanics.cooldownFor(finalRush)

            local overdrive = ctx.Overdrive and ctx.Overdrive() == true
            local currentImpulse = ArenaMechanics.readPadImpulse(pad, impulse)
            local appliedImpulse = ArenaMechanics.impulseFor(currentImpulse, overdrive)

            root.AssemblyLinearVelocity = ArenaMechanics.safeVelocity(
                root.AssemblyLinearVelocity,
                appliedImpulse
            )
            if ctx.OnArenaMechanicUsed then
                pcall(ctx.OnArenaMechanicUsed, player, variantId, definition.Name, overdrive)
            end
        end)
    end

    if variantId == "Classic" then
        -- Optional non-pay-to-win navigation skill inside the stable base.
        GridCircuitService.start(ctx, folder, base.Position)
    elseif variantId == "Crossroads" then
        -- Secondary timed traversal loop, sharing the mechanics lifecycle and
        -- round cleanup. Unlike pads, only the charged alternating lane pair
        -- relays the runner inward.
        CrossroadsFluxRelay.start(ctx, folder, base.Position)
    elseif variantId == "Orbital" then
        -- Reward intentional skill-route traversal as a style mechanic.
        -- Invisible checkpoints travel with their ramp during shrink.
        OrbitalHelix.startFlow(ctx, folder, arena)
    end

    return {
        name = definition.Name,
        hint = definition.Hint,
    }
end

return ArenaMechanics
