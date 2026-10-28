--!strict
-- PBR decoration policy for the four playable sectors AND the original
-- out-of-bounds architecture. Pure decisions; no graphics or event loops.
local PbrDistrictRules = {}

function PbrDistrictRules.limit(tierName)
    if tierName == "High" then return 16 end
    if tierName == "Medium" then return 6 end
    return 0
end

function PbrDistrictRules.eligibleOwner(owner)
    if not owner or not owner:IsA("Model") then return false end
    local sector = owner:GetAttribute("DistrictSector")
    if owner:GetAttribute("LocalOriginal3D") == true
        and owner:GetAttribute("CosmeticOnly") == true
        and type(sector) == "number"
        and sector >= 1 and sector <= 4 and sector == math.floor(sector) then
        return true
    end
    return owner:GetAttribute("ArenaDistrictArchitecture") == true
        or owner:GetAttribute("CornerLandmarkIndex") ~= nil
        or owner.Name == "ArenaHeroArchitecture3D"
        or owner:GetAttribute("ChaosPerimeterStation") == true
end

function PbrDistrictRules.eligiblePart(part)
    if not part or not part:IsA("BasePart")
        or not part.Anchored or part.CanCollide or part.CanTouch
        or part.CanQuery or part.Transparency >= 0.16
        or part.Material == Enum.Material.Neon
        or part.Material == Enum.Material.Glass
        or part.MaterialVariant ~= "" then
        return false
    end
    -- Preserve any original UV-authored PBR on imported mesh assets.
    if part:IsA("MeshPart") and part:FindFirstChildOfClass("SurfaceAppearance") then
        return false
    end
    local smallest = math.min(part.Size.X, part.Size.Y, part.Size.Z)
    local longest = math.max(part.Size.X, part.Size.Y, part.Size.Z)
    return longest >= 3 and smallest >= 0.35
end

function PbrDistrictRules.materialKey(partName, material)
    local name = tostring(partName or ""):lower()
    if name:find("foundation", 1, true)
        or name:find("basalt", 1, true)
        or name:find("concrete", 1, true)
        or name:find("ballast", 1, true)
        or name:find("ceramic", 1, true) then
        return "ceramic"
    end
    if name:find("armor", 1, true)
        or name:find("armour", 1, true)
        or name:find("plate", 1, true)
        or name:find("reinforce", 1, true)
        or name:find("deck", 1, true) then
        return "armor"
    end
    if name:find("rust", 1, true)
        or name:find("service", 1, true)
        or name:find("support", 1, true)
        or name:find("shroud", 1, true)
        or material == Enum.Material.CorrodedMetal then
        return "oxidized"
    end
    return "titanium"
end

-- Material variants have GPU costs even though they create no new Parts.
-- Spend the same 6/16 per-model budget on visible facade and hero volumes
-- rather than the first six tiny details produced by the procedural builder.
function PbrDistrictRules.priority(part)
    local size = part.Size
    local area = 2 * (size.X * size.Y + size.Y * size.Z + size.X * size.Z)
    local name = part.Name:lower()
    local architecturalFace = name:find("housing", 1, true)
        or name:find("shell", 1, true)
        or name:find("panel", 1, true)
        or name:find("cassette", 1, true)
        or name:find("cladding", 1, true)
        or name:find("tower", 1, true)
        or name:find("dish", 1, true)
        or name:find("manifold", 1, true)
    return math.min(area, 4000) + (architecturalFace and 250 or 0)
end

return PbrDistrictRules
