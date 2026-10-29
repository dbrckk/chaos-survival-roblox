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
local skyrailModule = script and script.Parent:FindFirstChild("SkyrailSlipstream")
local SkyrailSlipstream = if skyrailModule
    then require(skyrailModule)
    else require("./SkyrailSlipstream")
local pressureModule = script and script.Parent:FindFirstChild("SkybridgePressure")
local SkybridgePressure = if pressureModule
    then require(pressureModule)
    else require("./SkybridgePressure")
local switchyardModule = script and script.Parent:FindFirstChild("CrossroadsSwitchyard")
local CrossroadsSwitchyard = if switchyardModule
    then require(switchyardModule)
    else require("./CrossroadsSwitchyard")
local gridSweepModule = script and script.Parent:FindFirstChild("ClassicGridSweep")
local ClassicGridSweep = if gridSweepModule
    then require(gridSweepModule)
    else require("./ClassicGridSweep")
local harborSweepModule = script and script.Parent:FindFirstChild("HarborCargoSweep")
local HarborCargoSweep = if harborSweepModule
    then require(harborSweepModule)
    else require("./HarborCargoSweep")
local ArenaMechanics = {}

ArenaMechanics.Definitions = {
    Classic = {
        Name = "ESCAPE PADS",
        Hint = "Grid Circuit: four clockwise nodes; amber floor bands pulse red, jump or dodge",
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
        Hint = "Climb four marked tower routes; use cyan updrafts and Skyrails; warning bridges can vanish",
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
        Hint = "Climb four switchbacks; pink pads launch, cyan Flux returns, gold junctions cut sideways",
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
        Hint = "Use outer access ramps, cross a Helix, then climb the glowing reactor spokes",
        Color = Color3.fromRGB(65, 255, 205),
        Pads = (function()
            local result = {}
            for index = 0, 7 do
                -- Pads stay at floor height, between access ramps and elevated
                -- decks, so they cannot be buried by a collision roof.
                local angle = math.rad(index * 45 + 22.5)
                local radius = 34
                local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
                table.insert(result, {
                    offset = Vector3.new(math.cos(angle) * radius, 1.7, math.sin(angle) * radius),
                    impulse = tangent * 42 + Vector3.new(0, 9, 0),
                })
            end
            return result
        end)(),
    },
    Harbor = {
        Name = "SQUALL TRANSFER PADS",
        Hint = "Climb timber cargo piers; orange sweep bays turn red—jump or move to a clear lane",
        Color = Color3.fromRGB(78, 202, 222),
        Pads = {
            -- Clear of pier footprints and first eight spawn points.
            -- Strong directional transfers remain strictly capped by
            -- MovementSafety; no scripted boost or paid mobility.
            {offset = Vector3.new(35, 1.7, 0), impulse = Vector3.new(-32, 12, 22)},
            {offset = Vector3.new(-35, 1.7, 0), impulse = Vector3.new(32, 12, -22)},
            {offset = Vector3.new(0, 1.7, 35), impulse = Vector3.new(22, 12, -32)},
            {offset = Vector3.new(0, 1.7, -35), impulse = Vector3.new(-22, 12, 32)},
        },
    },
}

-- Optional dynamic challenges are deliberately disabled in early or
-- incompatible rounds. Never teach a newcomer to search for a nonexistent
-- collapsing bridge, gold impulse lane or floor shockwave.
ArenaMechanics.BaselineHints = {
    Classic = "Blue escape pads launch outward; four Grid Circuit nodes lead clockwise",
    Towers = "Climb from the hub through low-to-high decks; cyan updrafts assist when safe",
    Crossroads = "Reach the hub, then climb an outer lane and its elevated side branch",
    Orbital = "Follow a floor-level green booster to an outer ramp and cross a Helix",
    Harbor = "Follow seven-step cargo switchbacks; blue squall pads offer optional cross-dock transfers",
}

function ArenaMechanics.effectiveHint(variantId, dynamicStarted)
    local definition = ArenaMechanics.Definitions[variantId]
    if not definition then return nil end
    if dynamicStarted == true then return definition.Hint end
    return ArenaMechanics.BaselineHints[variantId] or definition.Hint
end

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
    folder:SetAttribute("MechanicHint", ArenaMechanics.effectiveHint(variantId, false))
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

    local dynamicStarted = false
    if variantId == "Classic" then
        -- The four-station skill course and blue pads remain available even
        -- in a beginner-friendly round with no floor waves.
        GridCircuitService.start(ctx, folder, base.Position)
        dynamicStarted = ClassicGridSweep.start(ctx, arena) ~= nil
    elseif variantId == "Towers" then
        SkyrailSlipstream.start(ctx, folder, arena)
        dynamicStarted = SkybridgePressure.start(ctx, arena) == true
    elseif variantId == "Crossroads" then
        CrossroadsFluxRelay.start(ctx, folder, base.Position)
        dynamicStarted = CrossroadsSwitchyard.start(
            ctx, folder, base.Position
        ) ~= nil
    elseif variantId == "Orbital" then
        -- Skill chains always work; only the charged movement bonuses are
        -- disabled by rookie and externally forced movement safeguards.
        OrbitalHelix.startFlow(ctx, folder, arena)
        dynamicStarted = type(ctx.HelixPulseClaims) == "table"
    elseif variantId == "Harbor" then
        -- The blue squall transfer pads remain available every round;
        -- crane cargo sweeps join only after the shared tutorial period.
        dynamicStarted = HarborCargoSweep.start(ctx, arena) ~= nil
    end

    local hint = ArenaMechanics.effectiveHint(variantId, dynamicStarted)
    folder:SetAttribute("MechanicHint", hint)
    folder:SetAttribute("DynamicRouteActive", dynamicStarted)
    return {
        name = definition.Name,
        hint = hint,
        dynamicStarted = dynamicStarted,
    }
end

return ArenaMechanics
