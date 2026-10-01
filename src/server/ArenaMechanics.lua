local ArenaMechanics = {}

ArenaMechanics.Definitions = {
    Classic = {
        Name = "ESCAPE PADS",
        Hint = "Blue pads launch you away from the center when a route collapses",
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
        Hint = "Pink pads accelerate you along a lane so you can switch routes quickly",
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
    light.Color = definition.Color
    light.Brightness = 0.75
    light.Range = 11
    light.Shadows = false
    light.Parent = pad

    local attachment = Instance.new("Attachment")
    attachment.Position = Vector3.new(0, 0.25, 0)
    attachment.Parent = pad

    local particles = Instance.new("ParticleEmitter")
    particles.Name = "MobilityPulse"
    particles.Rate = 6
    particles.Lifetime = NumberRange.new(0.25, 0.45)
    particles.Speed = NumberRange.new(1.5, 3)
    particles.SpreadAngle = Vector2.new(18, 18)
    particles.LightEmission = 0.8
    particles.Color = ColorSequence.new(definition.Color, Color3.new(1, 1, 1))
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.22),
        NumberSequenceKeypoint.new(1, 0),
    })
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    particles.Parent = attachment

    return pad, padDefinition.impulse, particles
end

local function rootAndPlayerFromHit(hit)
    local character = hit and hit.Parent
    if not character then
        return nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then
        return nil, nil
    end

    local Players = game:GetService("Players")
    return root, Players:GetPlayerFromCharacter(character)
end

function ArenaMechanics.get(variantId)
    return ArenaMechanics.Definitions[variantId]
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
        local pad, impulse, particles = createPad(folder, base.Position, definition, index)

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
            cooldownUntil[player.UserId] = now + 1.1

            local velocity = root.AssemblyLinearVelocity + impulse
            if velocity.Magnitude > 82 then
                velocity = velocity.Unit * 82
            end
            root.AssemblyLinearVelocity = velocity
            particles:Emit(14)

            if ctx.OnArenaMechanicUsed then
                pcall(ctx.OnArenaMechanicUsed, player, variantId, definition.Name)
            end
        end)
    end

    return {
        name = definition.Name,
        hint = definition.Hint,
    }
end

return ArenaMechanics
