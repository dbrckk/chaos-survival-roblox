-- Read-only source-aware visual ownership for the client-side platform
-- identity Parts. No physics mutations, asset creation or update loop.
-- The owner is the REAL server physical deck or original support post,
-- obtained from the existing renderer's exact source-authored weld.
local horizonModule = script and script.Parent:FindFirstChild("HorizonMonumentGeometry")
local HorizonMonumentGeometry = if horizonModule then require(horizonModule)
    else require("./HorizonMonumentGeometry")
local Rules = {}
local PROMENADE_HEIGHT = {[2] = 13.25, [4] = 14.5, [7] = 16.2}
local PROMENADE_VARIANTS = {Classic = true, Towers = true, Crossroads = true, Orbital = true, Harbor = true}

local SWITCHBACK_WIDTHS = {12, 12, 11.6, 11.1, 10.6, 10.1, 9.6}
local function routeIndex(value, maximum)
    return type(value) == "number" and value % 1 == 0
        and value >= 1 and value <= maximum
end

function Rules.isHarborLanding(deck)
    return deck:GetAttribute("HarborRoute") ~= nil
        or deck:GetAttribute("HarborSpokeRoute") ~= nil
        or deck:GetAttribute("HarborSkywayLane") ~= nil
end

function Rules.isHarborCargoTurn(deck)
    local route = deck:GetAttribute("HarborRoute")
    local step = deck:GetAttribute("HarborStep")
    return routeIndex(route, 4) and routeIndex(step, 6) and step >= 2
end

function Rules.isHarborSkywayInterior(deck)
    local lane = deck:GetAttribute("HarborSkywayLane")
    local step = deck:GetAttribute("HarborSkywayStep")
    return routeIndex(lane, 2) and routeIndex(step, 6) and step >= 2
end

function Rules.isHarborUpperPier(deck)
    local route = deck:GetAttribute("HarborSpokeRoute")
    local step = deck:GetAttribute("HarborSpokeStep")
    return routeIndex(route, 4) and routeIndex(step, 4) and step >= 3
end

function Rules.platformSupportFootY(base, deck)
    local ground = base.Position.Y + base.Size.Y * 0.5
    if deck:GetAttribute("PromenadeStep") ~= nil
        or deck:GetAttribute("SkySpineInterchange") == true
        or Rules.isHarborCargoTurn(deck)
        or Rules.isHarborSkywayInterior(deck)
        or Rules.isHarborUpperPier(deck) then
        -- Seat the forged shaft in the arena slab so it meets the floor.
        return ground - 0.08
    end
    return ground + 0.15
end

function Rules.isAuthoredUnderFrameMesh(part)
    return part:IsA("MeshPart")
        and part.Name:match("^PlatformUnderFrame%d+$") ~= nil
        and part:GetAttribute("OriginalPlatformUnderFrame3D") == true
end

function Rules.matchesDeckTrimPose(part, frame, size, sizeTolerance, positionTolerance, quarterTurn)
    -- Approved profiles may import with their long axis on X or Z.
    if quarterTurn and part.CFrame.LookVector:Dot(frame.LookVector) < .999 then
        frame *= CFrame.Angles(0, math.pi * 0.5, 0)
        size = Vector3.new(size.Z, size.Y, size.X)
    end
    return (part.Size - size).Magnitude <= sizeTolerance
        and (part.Position - frame.Position).Magnitude <= positionTolerance
        and part.CFrame.UpVector:Dot(frame.UpVector) >= .999
        and part.CFrame.LookVector:Dot(frame.LookVector) >= .999
end

function Rules.isHarborLandingTrimReserve(part)
    if not part:IsA("MeshPart") or part.MeshId == "" then return false end
    local assetId = part:GetAttribute("Original3DAssetId")
    return assetId == HorizonMonumentGeometry.harborCaissonAssetId()
        or assetId == HorizonMonumentGeometry.assetId("beam")
end

function Rules.matchesUnderdeckFallback(part, frame, size, sizeTolerance, positionTolerance)
    if not part then return false end
    local quarterTurn = false
    if Rules.isAuthoredUnderFrameMesh(part) then
        if part:GetAttribute("OriginalHarborLandingTrimReserve3D") == true
            and not Rules.isHarborLandingTrimReserve(part) then return false end
        if part:GetAttribute("OriginalElevatedLatticeFrame3D") == true then
            if part.MeshId == "" or part:GetAttribute("Original3DAssetId") ~= 106401955318567 then
                return false
            end
            quarterTurn = true
        end
    elseif part:IsA("MeshPart") then
        local name = part.Name
        local assetId = part:GetAttribute("Original3DAssetId")
        local arena = part.Parent and part.Parent.Parent
        local casting = arena and HorizonMonumentGeometry.isFloorCasting(assetId, arena:GetAttribute("VariantId"))
        local structuralProfile = assetId == 126298311664881 or assetId == 106401955318567 or casting
        local spine = structuralProfile
            and part:GetAttribute("OriginalSkySpineUnderdeck3D") == true
            and (name:match("^SkySpine%d+_Undercarriage%-?1$")
                or name:match("^SkySpine%d+_CrossStiffener$"))
        local promenade = structuralProfile
            and part:GetAttribute("OriginalPromenadeUnderdeck3D") == true
            and name:match("^Promenade%d+_UnderdeckTruss$")
        if part.MeshId == "" or not (spine or promenade) then return false end
        quarterTurn = true
    elseif not part:IsA("Part") or part.Shape ~= Enum.PartType.Block then
        return false
    end
    return Rules.matchesDeckTrimPose(part, frame, size, sizeTolerance, positionTolerance, quarterTurn)
end

function Rules.promenadeUnderdeckGeometry(top, span, scale, sculpted)
    if sculpted then
        -- Seat the upper flange against the walking deck's underside.
        return Vector3.new(5.6 * scale, .62, span * scale), CFrame.new(0, -top - .29, 0)
    end
    return Vector3.new(5.6 * scale, 1.7, span * scale), CFrame.new(0, top - 1.3, 0)
end

function Rules.promenadeSculptedStayPose(top, rise, side, scale)
    -- At full contraction an 8-degree stay still clears the deck's edge.
    -- Its raised center seats the upper end in the crosshead.
    local angle = math.rad(8)
    return CFrame.new(0, top + rise * .66 + .68, side * 8.3 * scale)
        * CFrame.Angles(side * angle, 0, 0), angle
end

function Rules.isAuthoredPlatformBevel(part)
    return part ~= nil and part:GetAttribute("OriginalStructuralBevel") == true
        and (part:IsA("WedgePart") or (part:IsA("MeshPart")
            and part:GetAttribute("OriginalPlatformBevel3D") == true))
end

function Rules.harborLandingWidth(deck)
    if routeIndex(deck:GetAttribute("HarborSkywayLane"), 2)
        and routeIndex(deck:GetAttribute("HarborSkywayStep"), 7) then
        local step = deck:GetAttribute("HarborSkywayStep")
        return (step == 1 or step == 7) and 10.5 or 9.8
    end
    local harbor = deck:GetAttribute("HarborRoute")
    local harborStep = deck:GetAttribute("HarborStep")
    if routeIndex(harbor, 4) and routeIndex(harborStep, 7) then
        return SWITCHBACK_WIDTHS[harborStep]
    end
    local spoke = deck:GetAttribute("HarborSpokeRoute")
    local spokeStep = deck:GetAttribute("HarborSpokeStep")
    if routeIndex(spoke, 4) and routeIndex(spokeStep, 4) then return 12-(spokeStep-1)*.5 end
    return nil
end

function Rules.promenadePylonIndex(native)
    if typeof(native) ~= "Instance" or native:GetAttribute("PromenadeVisualOnly") ~= true then
        return nil
    end
    local index, side = native.Name:match("^Promenade(%d+)_LoadPylon(%-?1)$")
    local block = native:IsA("Part") and native.Shape == Enum.PartType.Block
    local shaft = native:IsA("MeshPart") and native.MeshId ~= ""
        and native:GetAttribute("OriginalPromenadePylonShaft3D") == true
    if not index or not (block or shaft)
        or not native.Anchored or native.CanCollide or native.CanTouch or native.CanQuery
        or native:GetAttribute("PerimeterPlatformIndex") ~= tonumber(index) then
        return nil
    end
    return tonumber(index), tonumber(side)
end

function Rules.matchesPromenadePylon(native, deck)
    local index, side = Rules.promenadePylonIndex(native)
    if not index or not deck or not deck:IsA("BasePart") or not deck.Parent
        or deck.Name ~= "Platform" .. index
        or deck:GetAttribute("ChaosPermanentRoute") ~= true
        or deck:GetAttribute("RouteTier") ~= 4 then return false end
    local arena = deck.Parent.Parent
    if not arena or deck.Parent ~= arena:FindFirstChild("Platforms")
        or native.Parent ~= arena:FindFirstChild("Decor") then return false end
    local variant = arena:GetAttribute("VariantId")
    if not PROMENADE_VARIANTS[variant] then return false end
    if native:IsA("MeshPart") then
        local assetId = native:GetAttribute("Original3DAssetId")
        if assetId ~= HorizonMonumentGeometry.assetId("shaft", variant)
            and not HorizonMonumentGeometry.isFloorCasting(assetId, variant) then return false end
    end
    local lane = deck:GetAttribute("PromenadeLane")
    local height = PROMENADE_HEIGHT[deck:GetAttribute("PromenadeStep")]
    if not height or (lane ~= 1 and lane ~= 2) then return false end
    local scale = deck.Size.Z / 12
    local size = native.Size
    local expected = deck.CFrame * CFrame.new(0, (deck.Size.Y + height) * .5, side * 7.6 * scale)
    return scale >= .445 and scale <= 1.005 and math.abs(deck.Size.Y - 2) < .12
        and math.abs(size.Y - height) < .06
        and math.abs(size.X - 1.6 * scale) < .08
        and math.abs(size.Z - 1.8 * scale) < .08
        and (native.Position - expected.Position).Magnitude < .16
        and expected.LookVector:Dot(native.CFrame.LookVector) > .999
        and expected.UpVector:Dot(native.CFrame.UpVector) > .999
end

local JOINT_NAMES = {
    "ChaosPlatformTrimWeld",
    "PlatformIdentityWeld",
    "OriginalSupportVisualWeld",
}

function Rules.owner(visual, platforms, decor)
    if typeof(visual) ~= "Instance" or not visual:IsA("BasePart")
        or not visual.Parent then return nil end
    for _, name in ipairs(JOINT_NAMES) do
        local joint = visual:FindFirstChild(name)
        if joint and (joint:IsA("Weld") or joint:IsA("WeldConstraint"))
            and joint.Part0 == visual then
            local native = joint.Part1
            if native and native:IsA("BasePart")
                and native.Parent == platforms
                and platforms ~= nil then
                return native
            end
            -- Only a real, named nonphysical support column in this
            -- generated arena is allowed to anchor its genuine 3D mesh.
            if native and native:IsA("BasePart")
                and native.Parent == decor
                and decor ~= nil
                and native.Anchored
                and not native.CanCollide and not native.CanTouch
                and not native.CanQuery then
                if native.Name:match("^PlatformSupport%d+_%d+$") then
                    return native
                end
                local pylonIndex = native.Name:match(
                    "^SkySpine(%d+)_MonumentalPylon%-?1$")
                if pylonIndex
                    and visual:GetAttribute("OriginalSkySpinePylon3D") == true
                    and native:GetAttribute("SkySpineDecor") == true
                    and native:GetAttribute("PerimeterPlatformIndex")
                        == tonumber(pylonIndex) then
                    return native
                end
                if visual:GetAttribute("OriginalPromenadePylon3D") == true
                    and Rules.promenadePylonIndex(native) then
                    return native
                end
            end
        end
    end
    return nil
end

function Rules.nearFieldRetarget(tier, pressure, focus, cameraPoint, elapsed)
    local low = tier == "Low"
    local stress = tonumber(pressure) or 0
    if stress >= (low and 1 or 2) or elapsed < 12 then return false end
    local dx = cameraPoint.X - focus.X
    local dz = cameraPoint.Z - focus.Z
    local distance = low and 64 or 88
    return dx * dx + dz * dz >= distance * distance
end

function Rules.distance(cameraPoint, arenaOrigin, ownerPosition)
    if typeof(cameraPoint) ~= "Vector3"
        or typeof(arenaOrigin) ~= "Vector3"
        or typeof(ownerPosition) ~= "Vector3" then return math.huge end
    -- Match old near-CENTER decoration, AND preserve actual adjacent deck
    -- finishes when the player is at a distant 320-stud perimeter route.
    return math.min((cameraPoint - arenaOrigin).Magnitude,
        (cameraPoint - ownerPosition).Magnitude)
end

return Rules
