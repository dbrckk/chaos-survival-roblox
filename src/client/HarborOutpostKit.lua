-- Four original, sharply readable miniature dry-dock silhouettes.
-- Owned by the EXISTING arena-platform-identity rebuild and its welded
-- shrink/collapse lifecycle; never starts a new heartbeat or render loop.
-- No collision, touch/query, lights or new asset imports.
local HarborOutpostKit = {}
local WIDTH = 10.5
local FRAME_MODULES = 3

-- Roblox may import the truss along either horizontal axis. The sources
-- are two approved, seven-material packs with axis-aligned material meshes.
local function stage(source, dimensions, target, size, truss)
    if not source or not dimensions or not source.Archivable then return nil end
    local frame = source:GetBoundingBox()
    if truss and dimensions.Z > dimensions.X then
        frame *= CFrame.Angles(0, math.pi*.5, 0)
        dimensions = Vector3.new(dimensions.Z, dimensions.Y, dimensions.X)
    end
    local stretch = size/dimensions
    local function absolute(unit)
        return Vector3.new(math.abs(unit.X),math.abs(unit.Y),math.abs(unit.Z))
    end
    local parts = {}
    for _,mesh in ipairs(source:GetChildren()) do
        if not mesh:IsA("MeshPart") or not mesh.Anchored
            or mesh.CanCollide or mesh.CanTouch or mesh.CanQuery
            or mesh.Transparency >= 1 then break end
        local relative = frame:ToObjectSpace(mesh.CFrame)
        local x,y,z = absolute(relative.RightVector),
            absolute(relative.UpVector),absolute(relative.LookVector)
        if math.max(x.X,x.Y,x.Z) < .9999 or math.max(y.X,y.Y,y.Z) < .9999
            or math.max(z.X,z.Y,z.Z) < .9999 then break end
        local piece = mesh:Clone()
        if not piece then break end
        piece.Size = mesh.Size*Vector3.new(x:Dot(stretch),y:Dot(stretch),z:Dot(stretch))
        piece.CFrame = target*CFrame.new(relative.Position*stretch)*relative.Rotation
        parts[#parts+1] = piece
    end
    if #parts == 7 then return parts end
    for _,piece in ipairs(parts) do piece:Destroy() end
    return nil
end

-- Use the ordinary collapse and LOD owners for both pictures. This
-- switch only chooses which geometry they expose, and can be reversed
-- even when an existing welded mesh is detached after a rebuild.
local function bindFrame(platform, meshes, fallback, onLost)
    local connections = {}
    local function disconnect()
        for _,connection in ipairs(connections) do connection:Disconnect() end
        table.clear(connections)
    end
    local function lose()
        disconnect()
        for _,piece in ipairs(meshes) do
            if piece.Parent then
                piece:SetAttribute("ChaosBaseTransparency",1)
                piece.Transparency = 1
            end
        end
        local phase = platform:GetAttribute("CollapsePhase")
        for part,alpha in pairs(fallback) do
            part:SetAttribute("ChaosBaseTransparency",alpha)
            part.Transparency = phase == "Gone" and 1
                or (phase == "Warning" and math.max(.8,alpha) or alpha)
        end
        if onLost then onLost() end
    end
    for _,piece in ipairs(meshes) do
        local weld = piece:FindFirstChild("PlatformIdentityWeld")
        local owner = piece.Parent
        connections[#connections+1] = piece.AncestryChanged:Connect(function()
            if piece.Parent ~= owner then lose() end
        end)
        connections[#connections+1] = weld.AncestryChanged:Connect(function()
            if weld.Parent ~= piece then lose() end
        end)
        for _,property in ipairs({"Part0","Part1"}) do
            connections[#connections+1] = weld:GetPropertyChangedSignal(property):Connect(function()
                if weld.Part0 ~= piece or weld.Part1 ~= platform then lose() end
            end)
        end
    end
    return disconnect
end

local PROFILES = {
    [1] = {name = "StormRadar", yaw = 0, shape = Enum.PartType.Cylinder,
        span = 6.1, height = 4.5, legX = 2.7},
    [2] = {name = "CargoHoist", yaw = -math.pi * 0.5,
        shape = Enum.PartType.Cylinder, span = 7.4, height = 3.3, legX = 3.25},
    [3] = {name = "TidalBeacon", yaw = math.pi, shape = Enum.PartType.Ball,
        span = 5.7, height = 4.0, legX = 2.5},
    [4] = {name = "SignalArray", yaw = math.pi * 0.5,
        shape = Enum.PartType.Cylinder, span = 6.7, height = 5.0, legX = 2.95},
}

function HarborOutpostKit.count(tier)
    if tier == "High" then return 9 end
    if tier == "Medium" then return 5 end
    return 0
end

-- Select only real Harbor endpoints, using the existing camera snapshot.
-- At most one frame on touch/Medium, two on High desktop. Low keeps the
-- established lightweight endpoint presentation.
function HarborOutpostKit.candidates(platforms, tier, cameraPoint, pressure, touch)
    local limit = tier == "High" and (touch and 1 or 2)
        or (tier == "Medium" and 1 or 0)
    if limit == 0 or typeof(cameraPoint) ~= "Vector3"
        or (tonumber(pressure) or 0) > 0 then return {}, 0 end
    local found = {}
    local range = tier == "High" and 150 or 110
    for _,deck in ipairs(platforms) do
        local phase = deck:GetAttribute("CollapsePhase")
        if deck:IsA("BasePart") and deck.Anchored and deck.CanCollide
            and deck.Transparency < .75 and (phase == nil or phase == "Safe" or phase == "Normal")
            and deck:GetAttribute("RouteTier") == 4
            and deck:GetAttribute("HarborSpokeStep") == 4
            and PROFILES[deck:GetAttribute("HarborSpokeRoute")] then
            local distance = (deck.Position-cameraPoint).Magnitude
            if distance <= range then
                found[#found+1] = {deck=deck,distance=distance}
            end
        end
    end
    table.sort(found,function(a,b)
        return a.distance < b.distance
            or (a.distance == b.distance and a.deck.Name < b.deck.Name)
    end)
    return found, limit
end

HarborOutpostKit.frameModules = FRAME_MODULES

-- `makePart` is the scene's existing factory: it registers each cosmetic
-- with the real platform, assigns ChaosBaseTransparency and creates an
-- adjustable PlatformIdentityWeld. The owner then applies one shared
-- shrink-footprint and CollapsePhase policy to ALL of these pieces.
function HarborOutpostKit.build(makePart, platform, index, theme, tier, sources, onLost)
    if type(makePart) ~= "function" or not platform
        or not platform:IsA("BasePart") or not theme then
        return 0
    end
    local route = platform:GetAttribute("HarborSpokeRoute")
    local step = platform:GetAttribute("HarborSpokeStep")
    local profile = PROFILES[route]
    local budget = HarborOutpostKit.count(tier)
    local scale = platform.Size.X/WIDTH
    if not profile or step ~= 4 or budget == 0
        or scale < .445 or scale > 1.005
        or math.abs(platform.Size.X-platform.Size.Z) > .08 then
        return 0
    end

    -- All above-surface hardware sits at the OUTWARD edge of the real
    -- final deck; the centre landing remains visually open. A worn keel
    -- projects UNDER the deck, never suggesting a false walkable ledge.
    local frame = platform.CFrame * CFrame.Angles(0, profile.yaw, 0)
    local top = platform.Size.Y * 0.5
    local rear = -WIDTH*.34
    local horizontal = Vector3.new(scale, 1, scale)
    local function fitFrame(localFrame)
        return frame*CFrame.new(localFrame.Position*horizontal)*localFrame.Rotation
    end
    local mastHeight = profile.height
    local spread = profile.legX
    local steel = theme.Structure:Lerp(theme.Detail, 0.25)
    local trim = theme.Detail:Lerp(theme.Secondary, 0.23)
    local muted = theme.Structure:Lerp(Color3.fromRGB(72, 91, 104), 0.30)
    local signature = ({
        [1] = Color3.fromRGB(169, 197, 201),
        [2] = Color3.fromRGB(199, 161, 118),
        [3] = Color3.fromRGB(171, 174, 148),
        [4] = Color3.fromRGB(149, 174, 197),
    })[route]
    local made = 0
    local meshes, fallback = {}, {}
    local legFrames = {
        CFrame.new(-spread, top+mastHeight*.5, rear),
        CFrame.new(spread, top+mastHeight*.5, rear),
    }
    local gantryFrame = CFrame.new(0,top+mastHeight+.15,rear)
    local staged = {}
    local phase = platform:GetAttribute("CollapsePhase")
    if sources and platform.Anchored and platform.CanCollide and platform.Transparency < .75
        and platform:GetAttribute("RouteTier") == 4
        and (phase == nil or phase == "Safe" or phase == "Normal") then
        local legSize = Vector3.new(.9,mastHeight,.9)*horizontal
        staged[1] = stage(sources.column,sources.columnSize,fitFrame(legFrames[1]),legSize)
        staged[2] = stage(sources.column,sources.columnSize,fitFrame(legFrames[2]),legSize)
        staged[3] = stage(sources.truss,sources.trussSize,fitFrame(gantryFrame),
            Vector3.new(profile.span,.66,1.02)*horizontal,true)
    end
    local forged = staged[1] ~= nil and staged[2] ~= nil and staged[3] ~= nil
    for _,parts in pairs(staged) do
        local source = parts == staged[3] and sources.truss or sources.column
        for _,piece in ipairs(parts) do
            if forged then
                piece:SetAttribute("OriginalHarborOutpostFrame3D",true)
                piece:SetAttribute("Original3DAssetId",source:GetAttribute("Original3DAssetId"))
                meshes[#meshes+1] = makePart(
                    "Harbor"..profile.name.."Forged"..tostring(index).."_"..tostring(#meshes+1),
                    piece.Size,piece.CFrame,piece.Color,piece.Material,piece.Transparency,platform,piece)
            else
                piece:Destroy()
            end
        end
    end
    local function add(suffix, size, localFrame, color, material, alpha, shape, replaced)
        local masked = forged and replaced
        local part = makePart(
            "Harbor" .. profile.name .. suffix .. tostring(index),
            size*horizontal, fitFrame(localFrame), color, material, masked and 1 or alpha, platform
        )
        if masked and part then fallback[part] = alpha end
        if part and shape then
            part.Shape = shape
        end
        made += 1
        return part
    end

    -- Medium: exactly five pieces per outpost; 20 across Harbor.
    add("Keel", Vector3.new(profile.span + 0.35, 0.44, 1.05),
        CFrame.new(0, -top - 0.38, rear),
        muted, Enum.Material.CorrodedMetal, 0.08)
    for i, leg in ipairs(legFrames) do
        add(i == 1 and "PortLeg" or "StarboardLeg",
            Vector3.new(0.65, mastHeight, 0.65), leg,
            steel, Enum.Material.Metal, 0.06, nil, true)
    end
    add("Gantry", Vector3.new(profile.span, 0.48, 0.84),
        gantryFrame, trim, Enum.Material.CorrodedMetal, 0.05, nil, true)

    local instrumentSize = route == 3
        and Vector3.new(1.75, 1.75, 1.75)
        or (route == 2 and Vector3.new(1.30, 1.85, 1.85)
            or Vector3.new(0.85, 2.15, 2.15))
    local instrument = add("Instrument", instrumentSize,
        CFrame.new(0, top + mastHeight - 0.15, rear - 0.15)
            * CFrame.Angles(0, 0, route == 4 and math.rad(20) or 0),
        signature, route == 3 and Enum.Material.Slate
            or Enum.Material.CorrodedMetal,
        0.10, profile.shape)

    if tier == "High" then
        -- Add only four machined details per endpoint (36 total in High).
        -- These are close-range accents, not lights, beams or warning glyphs.
        for _, side in ipairs({-1, 1}) do
            add(side < 0 and "PortKnee" or "StarboardKnee",
                Vector3.new(0.28, 2.25, 0.43),
                CFrame.new(side * (spread - 0.55), top + 1.1, rear)
                    * CFrame.Angles(0, 0, side * math.rad(32)),
                muted, Enum.Material.Metal, 0.12, nil, true)
        end
        for _, side in ipairs({-1, 1}) do
            add(side < 0 and "PortVane" or "StarboardVane",
                Vector3.new(1.05, 0.30, 1.4),
                CFrame.new(side * (spread * 0.5), top + mastHeight + 0.55, rear - 0.45)
                    * CFrame.Angles(0, side * math.rad(16), 0),
                signature:Lerp(steel, 0.55),
                Enum.Material.CorrodedMetal, 0.16)
        end
    end
    if forged then return made, instrument, bindFrame(platform, meshes, fallback, onLost) end
    return made, instrument
end

-- A server-authored round contains at most two disaster IDs. Reduce the
-- pair to ONE stable mechanical posture. Priority is deterministic regardless
-- of the order in which the IDs reach a client. No hazard warnings, new light
-- or fake safe-zone marker are synthesized here.
local DISASTER_POSTURES = {
    Freeze = {mode = "stowed", weight = 7},
    DisappearingPlatforms = {mode = "stowed", weight = 7},
    Meteors = {mode = "impact", weight = 6},
    Bombs = {mode = "impact", weight = 6},
    ShrinkingArena = {mode = "impact", weight = 6},
    JumpShock = {mode = "impact", weight = 6},
    Tornado = {mode = "gale", weight = 5},
    SpeedSurge = {mode = "gale", weight = 5},
    RisingLava = {mode = "heat", weight = 4},
    LowGravity = {mode = "drift", weight = 3},
    Darkness = {mode = "night", weight = 2},
}

function HarborOutpostKit.disasterPosture(ids, phase)
    if phase ~= "round" or type(ids) ~= "table" then
        return "normal"
    end
    local chosen, weight = "normal", 0
    for _, id in ipairs(ids) do
        local candidate = type(id) == "string" and DISASTER_POSTURES[id]
        if candidate and candidate.weight > weight then
            chosen, weight = candidate.mode, candidate.weight
        end
    end
    return chosen
end

-- A very restrained surface shift makes the equipment state readable at
-- close range, without reusing yellow/red hazard telegraphs or changing any
-- global ColorCorrection/Atmosphere. The rest of the gantry stays original.
function HarborOutpostKit.instrumentColor(baseColor, posture)
    if typeof(baseColor) ~= "Color3" then return baseColor end
    if posture == "stowed" or posture == "night" then
        return baseColor:Lerp(Color3.fromRGB(93, 111, 121), 0.18)
    elseif posture == "gale" then
        return baseColor:Lerp(Color3.fromRGB(146, 179, 183), 0.16)
    elseif posture == "impact" then
        return baseColor:Lerp(Color3.fromRGB(94, 110, 123), 0.12)
    elseif posture == "heat" then
        return baseColor:Lerp(Color3.fromRGB(157, 149, 127), 0.10)
    elseif posture == "drift" then
        return baseColor:Lerp(Color3.fromRGB(150, 169, 190), 0.12)
    end
    return baseColor
end

-- Move the ONE original instrument per terminal, not its collision deck.
-- The owner tweens PlatformIdentityWeld.C0; Shrinking Arena alone owns C1.
-- Different disasters change only amplitude/tempo and the neutral surface
-- tone. The truly dangerous floor telegraphs always remain authoritative.
function HarborOutpostKit.motionTarget(route, posture)
    if posture == "stowed" then return nil end
    local amplitude, interval = 1, 1
    if posture == "gale" then
        amplitude, interval = 1.18, 0.75
    elseif posture == "impact" then
        amplitude, interval = 0.50, 1.20
    elseif posture == "drift" then
        amplitude, interval = 0.70, 1.35
    elseif posture == "heat" then
        amplitude, interval = 0.82, 1.17
    elseif posture == "night" then
        amplitude, interval = 0.54, 1.30
    end
    if route == 1 then
        -- Weather radar: wide sweep during wind; stow during freezing.
        return CFrame.Angles(0, math.rad(20 * amplitude), 0), 2.8 * interval
    elseif route == 2 then
        -- Loaded cargo winch: a slow axle rotation in an impact wave.
        return CFrame.Angles(math.rad(14 * amplitude), 0, 0), 2.2 * interval
    elseif route == 3 then
        -- Tidal probe: compliant, nonflashing response to the weather.
        return CFrame.Angles(0, 0, math.rad(6 * amplitude)), 3.4 * interval
    elseif route == 4 then
        -- Communications sensor maintains a safe bounded elevation arc.
        return CFrame.Angles(0, math.rad(-12 * amplitude),
            math.rad(9 * amplitude)), 3.0 * interval
    end
    return nil
end

return HarborOutpostKit
