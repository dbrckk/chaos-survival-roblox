-- Client-only P4 observation of ACTUALLY RESIDENT, VISIBLE native Parts.
-- This is NOT a claim of rendered pixels, occlusion or GPU draw calls.
-- One bounded traversal every 16 existing scenery LOD passes; no Heartbeat,
-- remotes, new Parts, asset loading or gameplay state changes.
local Census = {}

local function visible(part)
    -- Count the SAME native primitive classes as the real engine source
    -- census; do not incorrectly classify Unions/Terrain as blockout art.
    local primitive = part:IsA("Part") or part:IsA("WedgePart")
        or part:IsA("CornerWedgePart") or part:IsA("TrussPart")
    return primitive and part.Anchored and not part.CanCollide
        and not part.CanTouch and not part.CanQuery
        and part.Transparency < .95
        and part.LocalTransparencyModifier < .95
        and part.Size.X > .02 and part.Size.Y > .02 and part.Size.Z > .02
end

local function groupFor(part, decor, circuit, owners)
    local name = part.Name
    if name:match("^SkyRouteMonument%d+_") then
        return "Ascension"
    elseif name:match("^PlatformBevel%d+_") then
        return "PlatformBevel"
    elseif name:match("^PlatformSupport%d+_") then
        return "PlatformSupport"
    elseif name:match("^PlatformUnderFrame%d+$") then
        return "PlatformUnderFrame"
    elseif name:match("^PlatformPanel%d+$") then
        return "PlatformPanel"
    elseif name:match("^PremiumGroundModule%d+$") then
        return "GroundFinish"
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
    -- All folders are resolved ONCE per sample, rather than calling
    -- FindFirstChild several thousand times for a five-world census.
    if owners.casing and part:IsDescendantOf(owners.casing) then
        return "ColumnCasing"
    end
    if owners.district and part:IsDescendantOf(owners.district) then
        return "District"
    end
    if owners.corners and part:IsDescendantOf(owners.corners) then
        return "CornerLandmarks"
    end
    if owners.exterior and part:IsDescendantOf(owners.exterior) then
        return "ExteriorRetrofits"
    end
    if owners.harbor and part:IsDescendantOf(owners.harbor) then
        return "HarborFleet"
    end
    -- Four pre-existing, owner-tagged stations are Models directly under
    -- Decor; count each descendant without creating another index/loop.
    local owner=part
    while owner and owner.Parent~=decor do
        owner=owner.Parent
    end
    if owner and owner:IsA("Model") and owner.Parent==decor
        and owner:GetAttribute("ChaosPerimeterStation")==true then
        return "PerimeterStations"
    end
    return nil
end

local KEYS = {
    "Ascension", "ColumnCasing", "Helix", "District",
    "PlatformBevel", "PlatformSupport", "PlatformUnderFrame",
    "SkySpine", "Promenade", "PlatformSignals",
    -- Additional P4 breakdowns are independent counters, NOT extra Parts.
    -- Prevent neon/wayfinding cues from inflating a "needs 3D" backlog.
    "AscensionStructure", "AscensionSignal",
    "HelixStructure", "HelixSignal",
    "PlatformPanel", "GroundFinish", "CornerLandmarks",
    "ExteriorRetrofits", "HarborFleet", "PerimeterStations",
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
            local owners = {
                casing = decor:FindFirstChild("OriginalPremiumColumnCladding"),
                district = decor:FindFirstChild("ArenaDistrictArchitecture3D"),
                corners = decor:FindFirstChild("ArenaCornerLandmarks3D"),
                exterior = decor:FindFirstChild("OriginalExteriorRetrofits"),
                harbor = decor:FindFirstChild("StormHarborGantryFleet"),
            }
            -- GetDescendants includes streamed-in SERVER native fallback
            -- only. Client replacement folders live under Workspace and
            -- are intentionally excluded from this diagnostic.
            local function scan(root)
                for _,part in ipairs(root:GetDescendants()) do
                    if visible(part) then
                        scanned += 1
                        local key = groupFor(part, decor, circuit, owners)
                        if key then
                            counts[key] += 1
                            if key=="Ascension" or key=="Helix" then
                                local signal = part.Material==Enum.Material.Neon
                                    or part:GetAttribute("ChaosWayfinding")==true
                                local suffix=signal and "Signal" or "Structure"
                                counts[key..suffix] += 1
                            end
                        end
                    end
                end
            end
            scan(decor)
            if circuit and circuit:IsA("Folder") then scan(circuit) end
            streamed = true
        end
    end
    for _,key in ipairs(KEYS) do set(player, key, counts[key]) end
    -- Backward compatible name; this count includes the Orbital circuit.
    set(player, "AllDecor", scanned)
    set(player, "AllScanned", scanned)
    if player:GetAttribute("LocalP4NativeCensusReady") ~= streamed then
        player:SetAttribute("LocalP4NativeCensusReady", streamed)
    end
    if player:GetAttribute("LocalP4NativeCensusQuality") ~= quality then
        player:SetAttribute("LocalP4NativeCensusQuality", quality)
    end
    player:SetAttribute("LocalP4NativeCensusClock", os.clock())
end

return Census
