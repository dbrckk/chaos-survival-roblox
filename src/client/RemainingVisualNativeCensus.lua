-- Client-only P4 observation of ACTUALLY RESIDENT, VISIBLE native Parts.
-- This is NOT a claim of rendered pixels, occlusion or GPU draw calls.
-- One bounded traversal every 16 existing scenery LOD passes; no Heartbeat,
-- remotes, new Parts, asset loading or gameplay state changes.
local Census = {}

local function visible(part)
    return part:IsA("BasePart") and not part:IsA("MeshPart")
        and part.Anchored and not part.CanCollide
        and not part.CanTouch and not part.CanQuery
        and part.Transparency < .95
        and part.LocalTransparencyModifier < .95
        and part.Size.X > .02 and part.Size.Y > .02 and part.Size.Z > .02
end

local function groupFor(part, decor, circuit)
    local name = part.Name
    if name:match("^SkyRouteMonument%d+_") then
        return "Ascension"
    elseif name:match("^PlatformBevel%d+_") then
        return "PlatformBevel"
    elseif name:match("^PlatformSupport%d+_") then
        return "PlatformSupport"
    elseif name:match("^PlatformUnderFrame%d+$") then
        return "PlatformUnderFrame"
    elseif name:match("^SkySpine%d+_") then
        return "SkySpine"
    elseif name:match("^Promenade%d+_")
        or name:match("^PromenadeJumpChevron") then
        return "Promenade"
    elseif name:match("^PlatformGlow%d+$")
        or name:match("^PlatformCoreGlow%d+$") then
        return "PlatformSignals"
    end
    if circuit and part:IsDescendantOf(circuit) then return "Helix" end
    local casing = decor:FindFirstChild("OriginalPremiumColumnCladding")
    if casing and part:IsDescendantOf(casing) then return "ColumnCasing" end
    local district = decor:FindFirstChild("ArenaDistrictArchitecture3D")
    if district and part:IsDescendantOf(district) then return "District" end
    return nil
end

local KEYS = {
    "Ascension", "ColumnCasing", "Helix", "District",
    "PlatformBevel", "PlatformSupport", "PlatformUnderFrame",
    "SkySpine", "Promenade", "PlatformSignals",
}
local function set(player, key, value)
    local attr = "LocalP4VisibleNative" .. key
    if player:GetAttribute(attr) ~= value then
        player:SetAttribute(attr, value)
    end
end

function Census.sample(player, arena, quality)
    local counts = {}
    for _,key in ipairs(KEYS) do counts[key] = 0 end
    local scanned = 0
    local streamed = false
    if arena and arena.Name == "Arena"
        and arena.Parent == workspace:FindFirstChild("GeneratedMap") then
        local decor = arena:FindFirstChild("Decor")
        local circuit = arena:FindFirstChild("HelixCircuit")
        if decor and decor:IsA("Folder") then
            -- GetDescendants includes streamed-in server native fallback only.
            -- Exclude client-generated replacement folders under Workspace.
            local function scan(root)
                for _,part in ipairs(root:GetDescendants()) do
                    if visible(part) then
                        scanned += 1
                        local key = groupFor(part, decor, circuit)
                        if key then counts[key] += 1 end
                    end
                end
            end
            scan(decor)
            if circuit and circuit:IsA("Folder") then scan(circuit) end
            streamed = true
        end
    end
    for _,key in ipairs(KEYS) do set(player, key, counts[key]) end
    set(player, "AllDecor", scanned)
    if player:GetAttribute("LocalP4NativeCensusReady") ~= streamed then
        player:SetAttribute("LocalP4NativeCensusReady", streamed)
    end
    if player:GetAttribute("LocalP4NativeCensusQuality") ~= quality then
        player:SetAttribute("LocalP4NativeCensusQuality", quality)
    end
    player:SetAttribute("LocalP4NativeCensusClock", os.clock())
end

return Census
