-- Nine distinct short-lived ground-scars for non-impact hazards.
-- Purely visual, static and collision-free. Two strokes survive even on Low.
-- The geometry is authored in local ground space so tilted/rotated arenas
-- keep the correct orientation and raycast normal.
local AftermathSurfaceKit = {}

-- {name, dimensions, ground-space offset, yaw, shape, material, tintBlend}
local MARKS = {
    RisingLava = {
        {"BasaltTongue", Vector3.new(1.7, 0.19, 2.5), Vector3.new(-0.4, 0.11, -0.3), 28, "Wedge", Enum.Material.Slate, 0.03},
        {"MeltedSeam", Vector3.new(0.18, 0.045, 3.6), Vector3.new(0.50, 0.04, 0.3), -24, nil, Enum.Material.Slate, 0.03},
        {"SpalledCrust", Vector3.new(1.15, 0.10, 1.25), Vector3.new(-1.00, 0.07, 1.0), 55, "Wedge", Enum.Material.Slate, 0.13},
        {"CoolingCinder", Vector3.new(0.43, 0.05, 0.43), Vector3.new(1.02, 0.06, -1.0), 0, "Ball", Enum.Material.Slate, 0.31},
    },
    LowGravity = {
        {"ApogeeArc", Vector3.new(2.5, 0.05, 0.18), Vector3.new(0, 0.04, -0.85), 18, nil, Enum.Material.SmoothPlastic, 0.12},
        {"PerigeeArc", Vector3.new(2.5, 0.05, 0.18), Vector3.new(0, 0.04, 0.85), -18, nil, Enum.Material.SmoothPlastic, 0.12},
        {"DriftRegister", Vector3.new(0.18, 0.05, 2.2), Vector3.new(-1.12, 0.04, 0), 0, nil, Enum.Material.Glass, 0.23},
        {"GravityNode", Vector3.new(0.60, 0.12, 0.60), Vector3.new(0.65, 0.09, 0), 0, "Ball", Enum.Material.Glass, 0.26},
    },
    DisappearingPlatforms = {
        {"LeftFractureLip", Vector3.new(1.35, 0.09, 1.45), Vector3.new(-0.94, 0.065, 0), 21, "Wedge", Enum.Material.Metal, 0.06},
        {"RightFractureLip", Vector3.new(1.35, 0.09, 1.45), Vector3.new(0.94, 0.065, 0), -21, "Wedge", Enum.Material.Metal, 0.06},
        {"BrokenJoint", Vector3.new(0.11, 0.04, 2.6), Vector3.new(0, 0.04, 0.25), 13, nil, Enum.Material.DiamondPlate, 0.22},
        {"MissingAnchor", Vector3.new(0.45, 0.04, 0.45), Vector3.new(-1.5, 0.04, -1.0), 45, nil, Enum.Material.Metal, 0.25},
    },
    Tornado = {
        {"WindwardScrape", Vector3.new(2.8, 0.04, 0.20), Vector3.new(-0.4, 0.04, -0.85), 34, nil, Enum.Material.Metal, 0.04},
        {"LeewardScrape", Vector3.new(2.1, 0.04, 0.18), Vector3.new(0.45, 0.04, 0.72), -28, nil, Enum.Material.Metal, 0.11},
        {"VortexRadialCut", Vector3.new(1.3, 0.04, 0.15), Vector3.new(-0.78, 0.04, 1.1), 73, nil, Enum.Material.Metal, 0.22},
        {"EddyPlate", Vector3.new(0.7, 0.07, 0.38), Vector3.new(1.05, 0.06, -0.73), -21, "Wedge", Enum.Material.CorrodedMetal, 0.18},
    },
    Freeze = {
        {"PolarNeedleA", Vector3.new(0.86, 0.14, 3.15), Vector3.new(-0.15, 0.11, -0.20), 31, "Wedge", Enum.Material.Ice, 0.04},
        {"PolarNeedleB", Vector3.new(0.76, 0.11, 2.75), Vector3.new(0.17, 0.10, 0.23), -39, "Wedge", Enum.Material.Ice, 0.04},
        {"FrostBranchA", Vector3.new(0.18, 0.06, 2.35), Vector3.new(1.04, 0.05, 0.13), 81, nil, Enum.Material.Ice, 0.17},
        {"FrostBranchB", Vector3.new(0.20, 0.06, 1.9), Vector3.new(-1.10, 0.05, -0.51), -84, nil, Enum.Material.Glass, 0.24},
    },
    SpeedSurge = {
        {"VelocitySlashA", Vector3.new(0.22, 0.05, 3.5), Vector3.new(-0.90, 0.04, 0), -35, nil, Enum.Material.SmoothPlastic, 0.11},
        {"VelocitySlashB", Vector3.new(0.19, 0.05, 2.7), Vector3.new(0.13, 0.04, -0.25), -35, nil, Enum.Material.SmoothPlastic, 0.17},
        {"SlipstreamFeather", Vector3.new(0.14, 0.05, 2.2), Vector3.new(1.0, 0.04, 0.42), -35, nil, Enum.Material.Glass, 0.27},
        {"TurbineTrace", Vector3.new(0.14, 0.05, 1.5), Vector3.new(1.45, 0.04, -0.52), -35, nil, Enum.Material.SmoothPlastic, 0.28},
    },
    Darkness = {
        {"UmbraWingA", Vector3.new(1.75, 0.06, 1.05), Vector3.new(-0.75, 0.04, 0.05), 35, "Wedge", Enum.Material.Slate, 0.08},
        {"UmbraWingB", Vector3.new(1.75, 0.06, 1.05), Vector3.new(0.75, 0.04, 0.05), -35, "Wedge", Enum.Material.Slate, 0.08},
        {"OcclusionFold", Vector3.new(0.32, 0.05, 2.3), Vector3.new(-0.20, 0.04, -0.62), 74, nil, Enum.Material.Slate, 0.24},
        {"EclipseInlay", Vector3.new(0.48, 0.05, 1.32), Vector3.new(0.38, 0.04, 0.85), 30, nil, Enum.Material.Glass, 0.24},
    },
    ShrinkingArena = {
        {"ConvergenceArmA", Vector3.new(2.6, 0.07, 0.20), Vector3.new(-0.32, 0.05, -0.70), 0, nil, Enum.Material.Metal, 0.10},
        {"ConvergenceArmB", Vector3.new(0.20, 0.07, 2.6), Vector3.new(-1.52, 0.05, 0.48), 0, nil, Enum.Material.Metal, 0.10},
        {"PressureTick", Vector3.new(0.18, 0.05, 1.20), Vector3.new(0.45, 0.04, 0.38), -35, nil, Enum.Material.Glass, 0.25},
        {"BoundaryLock", Vector3.new(0.52, 0.06, 0.52), Vector3.new(-1.52, 0.05, -0.73), 45, nil, Enum.Material.Metal, 0.12},
    },
    JumpShock = {
        {"DischargeCutA", Vector3.new(0.19, 0.05, 2.25), Vector3.new(-0.68, 0.04, -0.52), 42, nil, Enum.Material.Metal, 0.07},
        {"DischargeCutB", Vector3.new(0.19, 0.05, 1.98), Vector3.new(0.23, 0.04, 0.38), -39, nil, Enum.Material.Metal, 0.07},
        {"BranchingArc", Vector3.new(0.14, 0.05, 1.45), Vector3.new(0.83, 0.04, -0.76), 52, nil, Enum.Material.Glass, 0.20},
        {"ArcTermination", Vector3.new(0.42, 0.04, 0.38), Vector3.new(1.30, 0.04, -1.27), 0, nil, Enum.Material.Metal, 0.18},
    },
}

function AftermathSurfaceKit.names(id)
    local recipe = MARKS[id]
    if not recipe then return nil end
    return {recipe[1][1], recipe[2][1], recipe[3][1], recipe[4][1]}
end

function AftermathSurfaceKit.count(tier)
    if tier == "Low" then return 2 end
    if tier == "High" then return 4 end
    return 3
end

function AftermathSurfaceKit.build(parent, id, tier, surfaceFrame, profile, scale, tag, accentTheme)
    local recipe = MARKS[id]
    if not recipe or not parent or typeof(surfaceFrame) ~= "CFrame"
        or not profile or typeof(profile.Color) ~= "Color3"
    then
        return {}
    end
    local built = {}
    local factor = math.clamp(tonumber(scale) or 1, 0.5, 1.75)
    local limit = AftermathSurfaceKit.count(tier)
    for index = 1, limit do
        local spec = recipe[index]
        local p = Instance.new(spec[5] == "Wedge" and "WedgePart" or "Part")
        p.Name = id .. "_" .. spec[1] .. "_" .. tostring(tag or "0")
        p.Size = spec[2] * factor
        p.CFrame = surfaceFrame
            * CFrame.new(spec[3] * factor)
            * CFrame.Angles(0, math.rad(spec[4]), 0)
        if spec[5] == "Ball" then
            p.Shape = Enum.PartType.Ball
        end
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.CastShadow = false
        p.Material = spec[6]
        p.Color = accentTheme and accentTheme.Detail
            and profile.Color:Lerp(accentTheme.Detail, spec[7])
            or profile.Color
        p.Transparency = tier == "Low" and 0.30
            or (tier == "High" and 0.14 or 0.24)
        p:SetAttribute("ChaosAftermathMotif", id)
        p.Parent = parent
        table.insert(built, p)
    end
    return built
end

return AftermathSurfaceKit
