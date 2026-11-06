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
function Rules.nativeRole(part, decor)
    if typeof(part) ~= "Instance" or typeof(decor) ~= "Instance"
        or not decor:IsA("Folder") or part.Parent ~= decor
        or not part:IsA("BasePart") or not part.Anchored
        or part.CanCollide or part.CanTouch or part.CanQuery
        or part.Transparency >= 0.5
        or part:GetAttribute("PremiumArchitecturalSurface") ~= true
    then return nil end
    if part.Name == "ArenaDeckInset"
        and part.Size.X > 200 and part.Size.Z > 200
        and part.Size.Y <= 0.2 then return "deck" end
    if part.Name:match("^PremiumGroundModule%d+$")
        and part:GetAttribute("OriginalGroundFinish") == true
        and part.Size.X >= 35 and part.Size.Z >= 35
        and part.Size.Y <= 0.12 then return "module" end
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
