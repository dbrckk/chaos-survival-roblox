--!strict
-- PBR decoration policy for the four playable sectors AND the original
-- out-of-bounds architecture. Pure decisions; no graphics or event loops.
local PbrDistrictRules = {}

function PbrDistrictRules.limit(tierName)
    if tierName == "High" then return 16 end
    if tierName == "Medium" then return 6 end
    return 0
end

-- An owner quota alone multiplies expensive material sampling across
-- every streamed building. Cap the total active PBR surfaces per client.
-- Extra-high Roblox graphics selection never bypasses the Android budget.
function PbrDistrictRules.globalLimit(tierName, touch)
    if tierName == "High" then return touch and 72 or 144 end
    if tierName == "Medium" then return touch and 32 or 48 end
    return 0
end

-- Optional session-local Android comparison switch. Default stays AUTO:
-- desktop and untouched mobile players preserve the existing PBR budget.
-- Disabling PBR affects client-owned materials only, never collision,
-- warning surfaces, physics or the player's adaptive quality tier.
function PbrDistrictRules.effectiveGlobalLimit(tierName, touch, disabled)
    if touch == true and disabled == true then
        return 0
    end
    return PbrDistrictRules.globalLimit(tierName, touch)
end

-- Do not spend even the existing 1.7s/2.2s camera-sampling
-- work when PBR is off, unavailable on Low, or no scenery is loaded.
-- Direct opt-out/tier change listeners still reconcile/restores immediately.
function PbrDistrictRules.cameraSamplingEnabled(tierName, touch, disabled, hasSource)
    return hasSource == true
        and PbrDistrictRules.limit(tierName) > 0
        and PbrDistrictRules.effectiveGlobalLimit(tierName, touch, disabled) > 0
end

function PbrDistrictRules.distanceLimit(tierName, touch)
    if tierName == "High" then return touch and 370 or 550 end
    if tierName == "Medium" then return touch and 240 or 340 end
    return 0
end

-- Read-only visibility check: the existing scenery LOD remains the single
-- authority that hides far ornaments. Do not wake a hidden danger/decor part.
function PbrDistrictRules.visible(part)
    return part:GetAttribute("SceneryLodHidden") ~= true
        and part.LocalTransparencyModifier < 0.95
end

function PbrDistrictRules.withinDistance(part, cameraPosition, tierName, touch)
    local limit = PbrDistrictRules.distanceLimit(tierName, touch)
    if limit <= 0 then return false end
    -- Camera can be absent during first join/respawn. Never allocate
    -- high-resolution materials blindly before the real camera exists.
    -- The existing slow client sampler retries when CurrentCamera appears.
    if typeof(cameraPosition) ~= "Vector3" then return false end
    return (part.Position - cameraPosition).Magnitude <= limit
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

function PbrDistrictRules.eligiblePart(part, ownedVariant)
    if not part or not part:IsA("BasePart")
        or not part.Anchored or part.CanCollide or part.CanTouch
        or part.CanQuery or part.Transparency >= 0.16
        or part.Material == Enum.Material.Neon
        or part.Material == Enum.Material.Glass
        or (part.MaterialVariant ~= ""
            and part.MaterialVariant ~= ownedVariant)
        or not PbrDistrictRules.visible(part) then
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

-- 28-degree mobile camera turn threshold. On-site looking around is
-- meaningful for 2K PBR residency even when the character stands still.
-- Share the existing 1.7 / 2.2-second sampler; no render-frame callback.
local CAMERA_TURN_COSINE = math.cos(math.rad(28))

function PbrDistrictRules.cameraNeedsRescan(previousPosition, previousLook,
    currentPosition, currentLook)
    if typeof(currentPosition) ~= "Vector3" then return false end
    if typeof(previousPosition) ~= "Vector3" then return true end
    if (currentPosition - previousPosition).Magnitude >= 32 then
        return true
    end
    if typeof(previousLook) ~= "Vector3"
        or typeof(currentLook) ~= "Vector3"
        or previousLook.Magnitude < 0.5
        or currentLook.Magnitude < 0.5 then
        return false
    end
    return previousLook.Unit:Dot(currentLook.Unit) < CAMERA_TURN_COSINE
end

-- Pure camera-forward signal. Surfaces within 55 studs remain omni-
-- directional to avoid visible PBR popping at arm's length during turns.
-- More distant surfaces facing into the view receive up to +950 priority;
-- those clearly behind the camera are gently deprioritized, never invalid.
-- Under global overload the most visible facades receive the 2K maps.
function PbrDistrictRules.cameraFacingBonus(part, cameraPosition, lookVector)
    if typeof(cameraPosition) ~= "Vector3"
        or typeof(lookVector) ~= "Vector3" then
        return 0
    end
    local delta = part.Position - cameraPosition
    local distance = delta.Magnitude
    local forwardLength = lookVector.Magnitude
    if distance <= 55 or forwardLength < 0.5 then
        return 0
    end
    local facing = math.clamp(
        delta:Dot(lookVector) / (distance * forwardLength), -1, 1)
    return facing >= 0 and facing * 950 or facing * 350
end

-- Stable selection that values visible, nearby primary architecture.
-- Already-selected surfaces get modest hysteresis, preventing a full
-- material swap whenever the camera moves a few studs on mobile.
-- Optional direction preserves existing callers and offline testability.
function PbrDistrictRules.selectionPriority(
    part, cameraPosition, alreadyApplied, cameraLook)
    local score = PbrDistrictRules.priority(part)
    if typeof(cameraPosition) == "Vector3" then
        local distance = (part.Position - cameraPosition).Magnitude
        score += math.max(0, 400 - distance) * 10
    end
    score += PbrDistrictRules.cameraFacingBonus(
        part, cameraPosition, cameraLook)
    if alreadyApplied then score += 160 end
    return score
end

return PbrDistrictRules
