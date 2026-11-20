--!strict
-- Android survival readability: the walkable steel floor must never look
-- like the orange/red RisingLava flood or an authoritative impact warning.
-- Pure COLOR only. Never changes server hazards, genuine colliders,
-- warning decals, route arrows, geometry, texture source IDs or rewards.
local Rules = {}

local STEEL = Color3.fromRGB(81, 133, 147)

function Rules.enabled(state)
    if type(state) ~= "table" or state.phase ~= "round"
        or type(state.disasterIds) ~= "table" then return false end
    for _, id in ipairs(state.disasterIds) do
        if id == "RisingLava" then return true end
    end
    return false
end

-- Accept only server-authored, nonphysical floor FINISH parts, not
-- Base, PlatformN, lava, collapse indicators, mesh proxies or ornaments.
local function floorScale(decor, base)
    if typeof(base) ~= "Instance" or not base:IsA("BasePart") or base.Name ~= "Base"
        or base.Parent ~= decor.Parent or not base.Anchored or not base.CanCollide then
        return 1
    end
    local x, z = base:GetAttribute("OriginalSizeX"), base:GetAttribute("OriginalSizeZ")
    if type(x) ~= "number" or x < 318 or type(z) ~= "number" or z < 318 then return 1 end
    local ratioX, ratioZ = base.Size.X / x, base.Size.Z / z
    if not (ratioX >= .445 and ratioX <= 1.005 and ratioZ >= .445 and ratioZ <= 1.005
        and math.abs(ratioX - ratioZ) < .012) then return 1 end
    return math.min(1, ratioX, ratioZ)
end

function Rules.nativeRole(part, decor, base)
    if typeof(part) ~= "Instance" or typeof(decor) ~= "Instance"
        or not decor:IsA("Folder") or part.Parent ~= decor
        or not part:IsA("BasePart") or not part.Anchored
        or part.CanCollide or part.CanTouch or part.CanQuery
        or part.Transparency >= 0.5
        or part:GetAttribute("PremiumArchitecturalSurface") ~= true
    then return nil end
    if part.Name == "ArenaDeckInset" and part.Size.Y <= .2 then
        local minimum = 200 * floorScale(decor, base)
        if part.Size.X > minimum and part.Size.Z > minimum then return "deck" end
    elseif part.Name:match("^PremiumGroundModule%d+$")
        and part:GetAttribute("OriginalGroundFinish") == true and part.Size.Y <= .12 then
        -- Bays streamed after the floor contracts still need the lava tint.
        local minimum = 35 * floorScale(decor, base)
        if part.Size.X >= minimum and part.Size.Z >= minimum then return "module" end
    end
    return nil
end

-- The exact color is restored after this disaster and after map swaps;
-- never use an already-tinted current Color as the next baseline.
function Rules.tint(baseColor, role, enabled)
    if typeof(baseColor) ~= "Color3" then return baseColor end
    if enabled ~= true then return baseColor end
    if role == "deck" then return baseColor:Lerp(STEEL, 0.78) end
    if role == "module" then return baseColor:Lerp(STEEL, 0.74) end
    if role == "mesh" then return baseColor:Lerp(STEEL, 0.58) end
    if role == "detail" then return baseColor:Lerp(STEEL, 0.30) end
    return baseColor
end

return Rules
