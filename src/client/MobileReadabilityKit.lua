-- Touch-device decor readability: bounded, deterministic tier transforms.
-- A watch handles delayed Arena/Decor replication without polling.
local Kit = {}

function Kit.profile(tier)
    -- Android camera captures showed cyan/magenta ornament strips
    -- overwhelming the actual 3D structure. Fade ONLY noninteractive
    -- Neon decor; hazard outlines, route edges and spawn guidance keep
    -- their separate high-contrast treatment in isGameplayEdge().
    if tier == "Low" then
        return 0.28, 0.58
    elseif tier == "Medium" then
        return 0.21, 0.66
    end
    return 0.13, 0.74
end

function Kit.isGameplayEdge(part)
    local name = part.Name
    return string.sub(name, 1, 4) == "Edge"
        or string.find(name, "PlatformGlow", 1, true) ~= nil
        or string.find(name, "SpawnGlow", 1, true) ~= nil
end

-- Store each light's unscaled brightness, so repeated tier changes never
-- compound the dimming. The owner keeps a weak-key cache for map churn.
function Kit.applyInstance(instance, tier, originalBrightness)
    local decorTransparency, lightScale = Kit.profile(tier)
    if instance:IsA("BasePart") and instance.Material == Enum.Material.Neon then
        -- Distance LOD owns the fully hidden state. A touch-tier refresh
        -- must not re-expose an ornament while its LOD owner hides it.
        -- Apply the touch tint again once the LOD owner restores visibility.
        if instance:GetAttribute("SceneryLodHidden") == true then
            return
        end
        if Kit.isGameplayEdge(instance) then
            instance.LocalTransparencyModifier = math.min(0.07, decorTransparency * 0.45)
        else
            instance.LocalTransparencyModifier = decorTransparency
        end
    elseif instance:IsA("PointLight")
        or instance:IsA("SpotLight")
        or instance:IsA("SurfaceLight")
    then
        local baseline = originalBrightness[instance]
        if baseline == nil then
            baseline = instance.Brightness
            originalBrightness[instance] = baseline
        end
        instance.Brightness = baseline * lightScale
    end
end

-- DescendantAdded may first deliver a pre-populated Model/Folder. Apply the
-- complete streamed subtree, not only its container, so nested Neon and
-- motivated lights receive the same touch policy immediately.
function Kit.applyTree(root, tier, originalBrightness)
    if not root then return end
    Kit.applyInstance(root, tier, originalBrightness)
    for _, descendant in ipairs(root:GetDescendants()) do
        Kit.applyInstance(descendant, tier, originalBrightness)
    end
end

-- Distance LOD writes its saved visibility modifier before clearing the
-- hidden attribute. Observe only that explicit reveal transition: a
-- static touch tint can then be restored without a polling/render loop.
function Kit.watchLodReturn(part, onReveal)
    assert(typeof(part) == "Instance" and part:IsA("BasePart")
        and type(onReveal) == "function",
        "MobileReadabilityKit.watchLodReturn requires a part and callback")
    return part:GetAttributeChangedSignal("SceneryLodHidden"):Connect(function()
        if part.Parent and part:GetAttribute("SceneryLodHidden") == false then
            onReveal(part)
        end
    end)
end

-- Emissions are always the currently available Decor or nil. Listener
-- teardown is explicit when a map/arena disappears or another one arrives.
function Kit.watch(generated, onDecor)
    assert(typeof(generated) == "Instance" and type(onDecor) == "function",
        "MobileReadabilityKit.watch requires a map and callback")
    local sourceConnections = {}
    local arenaConnections = {}
    local currentArena = nil
    local alive = true

    local function disconnect(connections)
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)
    end

    local function emit()
        if alive then
            onDecor(currentArena and currentArena:FindFirstChild("Decor") or nil)
        end
    end

    local function bindArena(arena)
        disconnect(arenaConnections)
        currentArena = arena
        if arena then
            table.insert(arenaConnections, arena.ChildAdded:Connect(function(child)
                if child.Name == "Decor" then
                    emit()
                end
            end))
            table.insert(arenaConnections, arena.ChildRemoved:Connect(function(child)
                if child.Name == "Decor" then
                    emit()
                end
            end))
        end
        emit()
    end

    table.insert(sourceConnections, generated.ChildAdded:Connect(function(child)
        if child.Name == "Arena" then
            -- Arena swaps can briefly replicate two same-named folders.
            -- Do not show the incoming Decor until Roblox selects that
            -- arena as the canonical GeneratedMap child. This prevents
            -- a full-screen ornament flash midway through a mobile round.
            local selected = generated:FindFirstChild("Arena")
            if selected ~= currentArena then
                bindArena(selected)
            end
        end
    end))
    table.insert(sourceConnections, generated.ChildRemoved:Connect(function(child)
        if child == currentArena then
            bindArena(generated:FindFirstChild("Arena"))
        end
    end))
    bindArena(generated:FindFirstChild("Arena"))

    return function()
        alive = false
        disconnect(sourceConnections)
        disconnect(arenaConnections)
        currentArena = nil
    end
end

return Kit
