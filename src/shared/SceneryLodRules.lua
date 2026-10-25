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

return SceneryLodRules
