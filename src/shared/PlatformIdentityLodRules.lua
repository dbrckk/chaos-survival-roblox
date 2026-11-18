-- Read-only source-aware visual ownership for the client-side platform
-- identity Parts. No physics mutations, asset creation or update loop.
-- The owner is the REAL server physical deck or original support post,
-- obtained from the existing renderer's exact source-authored weld.
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

function Rules.isAuthoredUnderFrameMesh(part)
    return part:IsA("MeshPart")
        and part.Name:match("^PlatformUnderFrame%d+$") ~= nil
        and part:GetAttribute("OriginalPlatformUnderFrame3D") == true
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
    if not index or not native:IsA("Part") or native.Shape ~= Enum.PartType.Block
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
        or native.Parent ~= arena:FindFirstChild("Decor")
        or not PROMENADE_VARIANTS[arena:GetAttribute("VariantId")] then return false end
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
