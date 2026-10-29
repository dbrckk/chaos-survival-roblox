--!strict
-- Client-only decorative distance LOD. Cosmetic hysteresis prevents scenery
-- visibility popping when a mobile camera hovers near a cutoff.
local SceneryLodRules = {}

SceneryLodRules.Hysteresis = 8

-- Client practice cosmetics are nested in GeneratedMap/Lobby/Activities,
-- not at the workspace root. Only return explicitly owned visual roots.
-- Never hand a server-owned pad or its PointLight to the LOD writer.
function SceneryLodRules.practicePadVisualOwners(root)
    local owners = {}
    if typeof(root) ~= "Instance" then return owners end
    local generated = root:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local activities = lobby and lobby:FindFirstChild("Activities")
    if not activities then return owners end

    for _, pad in ipairs(activities:GetChildren()) do
        if pad:IsA("BasePart")
            and pad:GetAttribute("LobbyPracticePad") == true then
            local highlights = pad:FindFirstChild("PracticePadPolishLocal")
            if highlights and highlights:IsA("Folder") then
                owners[#owners + 1] = highlights
            end
            local particles = pad:FindFirstChild("PracticeMotesAttachment")
            if particles and particles:IsA("Attachment") then
                owners[#owners + 1] = particles
            end
        end
    end
    return owners
end

-- Only cosmetic, author-owned hero skyline models may be hidden by this
-- distance controller. Native Base/Platforms and enemy warnings are excluded.
function SceneryLodRules.heroArchitectureOwner(root)
    if typeof(root) ~= "Instance" then return nil end
    local generated = root:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local decor = arena and arena:FindFirstChild("Decor")
    local hero = decor and decor:FindFirstChild("ArenaHeroArchitecture3D")
    if hero and hero:IsA("Model")
        and hero:GetAttribute("SourceIsOriginal") == true
        and hero:GetAttribute("ChaosDistantScenery") == true
    then
        return hero
    end
    return nil
end

-- Imported original MeshParts stand beyond the physical 320-stud floor.
-- Center-of-arena distance incorrectly culled ALL of them on Android Medium,
-- including the closest one as the camera approached the perimeter.
-- Only sanitized, approved, currently replicated visual models are owners.
-- Call this from the existing 0.65/0.90-second LOD loop, never per frame.
function SceneryLodRules.original3DVisualOwners(arena)
    local owners = {}
    if typeof(arena) ~= "Instance" then return owners end
    local decor = arena:FindFirstChild("Decor")
    local folder = decor and decor:FindFirstChild("Original3DScenery")
    if not folder or not folder:IsA("Folder") then return owners end

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model")
            and model:GetAttribute("CosmeticOnly") == true
            and type(model:GetAttribute("Original3DAssetId")) == "number"
            and model:FindFirstChildWhichIsA("BasePart") then
            owners[#owners + 1] = model
        end
    end
    return owners
end

-- Only the four specifically tagged Storm Harbor GANTRY models are
-- eligible for extra skyline culling. A real platform, hazard signal or
-- mobility pad cannot enter this list; the source is a cosmetic-only
-- folder under the active arena's Decor. Reuse the 0.65/0.90-second
-- scenery owner rather than adding a client render loop.
function SceneryLodRules.harborGantryOwners(arena)
    local owners = {}
    if typeof(arena) ~= "Instance" or not arena:IsA("Folder")
        or arena.Name ~= "Arena" then
        return owners
    end
    local decor = arena:FindFirstChild("Decor")
    local folder = decor and decor:FindFirstChild("StormHarborGantryFleet")
    if not folder or not folder:IsA("Folder") then return owners end

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model")
            and model:GetAttribute("CosmeticOnly") == true
            and model:GetAttribute("SourceIsOriginal") == true
            and model:GetAttribute("ChaosDistantScenery") == true
            and model:FindFirstChildWhichIsA("BasePart") then
            owners[#owners + 1] = model
        end
    end
    return owners
end

-- Preserve a sparse skyline rather than an empty horizon on Android Low.
-- Only an explicitly marked original hero instance may use this exception;
-- gameplay parts and other scenery folders remain under their normal LOD.
function SceneryLodRules.entryVisible(tier, folderVisible, keepHeroLow, essential)
    if folderVisible == true then
        return true
    end
    return tier == "Low" and keepHeroLow == true and essential == true
end

function SceneryLodRules.visible(tier, distance, lowDistance, mediumDistance,
        previouslyVisible)
    if tier ~= "Low" and tier ~= "Medium" then
        return true -- High remains fully visible, as before.
    end

    if type(distance) ~= "number" or distance < 0 or distance ~= distance then
        return false
    end
    local cutoff = tier == "Low" and lowDistance or mediumDistance
    if type(cutoff) ~= "number" or cutoff <= 0 or cutoff ~= cutoff then
        return false
    end

    if previouslyVisible == true then
        return distance <= cutoff + SceneryLodRules.Hysteresis
    elseif previouslyVisible == false then
        return distance <= math.max(0, cutoff - SceneryLodRules.Hysteresis)
    end
    return distance <= cutoff
end

-- Staging diagnostics distinguish successful server mounts from what has
-- actually replicated to one Roblox client. Neither number proves that
-- textures rendered or the device met its frame-time budget.
-- No mesh inspection, descendants traversal, network calls or frame loop.
function SceneryLodRules.original3DAudit(arena)
    if typeof(arena) ~= "Instance" then
        return nil, nil, false
    end
    local serverCount = arena:GetAttribute("Original3DSceneryCount")
    if type(serverCount) ~= "number" or serverCount ~= serverCount
        or serverCount < 0 or serverCount > 100
        or serverCount == math.huge then
        serverCount = nil
    else
        serverCount = math.floor(serverCount)
    end

    local replicated = #SceneryLodRules.original3DVisualOwners(arena)

    return serverCount, replicated,
        arena:GetAttribute("Original3DSceneryComplete") == true
end

return SceneryLodRules
