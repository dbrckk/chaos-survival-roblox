local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ArenaVariants = require(script.Parent.ArenaVariants)
local ArenaMechanics = require(script.Parent.ArenaMechanics)

local metadata = ReplicatedStorage:FindFirstChild("ArenaMetadata") or Instance.new("Folder")
metadata.Name = "ArenaMetadata"
metadata.Parent = ReplicatedStorage

local function publish(definition)
    local mechanic = ArenaMechanics.get(definition.Id)
    -- Publish the identity last. Clients can use it to reject hints
    -- from the previous arena while this bundle is being replaced.
    metadata:SetAttribute("VariantName", definition.Name)
    metadata:SetAttribute("StrategyHint", definition.StrategyHint)
    metadata:SetAttribute("MechanicName", mechanic and mechanic.Name or "")
    metadata:SetAttribute("MechanicHint", mechanic and mechanic.Hint or "")
    metadata:SetAttribute("VariantId", definition.Id)
end

local function clearMetadata()
    for _, attribute in ipairs({
        "VariantId", "VariantName", "StrategyHint", "MechanicName", "MechanicHint",
    }) do
        metadata:SetAttribute(attribute, nil)
    end
end

local activeRoot = nil
local activeArena = nil
local arenaVariantConnection = nil
local rootAddedConnection = nil
local rootRemovedConnection = nil

local function applyCurrentMetadata()
    -- Never republish an old arena from a removed/replaced GeneratedMap.
    if not activeRoot or activeRoot.Parent ~= Workspace then return end
    local definition = ArenaVariants.activeDefinition(activeArena, activeRoot)
    if not definition then
        clearMetadata()
        return
    end
    activeArena:SetAttribute("StrategyHint", definition.StrategyHint)
    publish(definition)
end

local function bindArena(arena)
    if arena == activeArena then
        -- A new map can start without an Arena child. Even when both
        -- pointers are nil, invalidate metadata from the previous map.
        applyCurrentMetadata()
        return
    end
    if arenaVariantConnection then
        arenaVariantConnection:Disconnect()
        arenaVariantConnection = nil
    end
    activeArena = nil
    if arena and arena:IsA("Folder") and arena.Name == "Arena"
        and arena.Parent == activeRoot then
        activeArena = arena
        -- A late or changed VariantId must update the presentation too.
        arenaVariantConnection = arena:GetAttributeChangedSignal("VariantId")
            :Connect(applyCurrentMetadata)
    end
    applyCurrentMetadata()
end

local function bindMap(root)
    if root == activeRoot then return end
    if rootAddedConnection then
        rootAddedConnection:Disconnect()
        rootAddedConnection = nil
    end
    if rootRemovedConnection then
        rootRemovedConnection:Disconnect()
        rootRemovedConnection = nil
    end
    bindArena(nil)

    activeRoot = nil
    if root and root:IsA("Folder") and root.Name == "GeneratedMap"
        and root.Parent == Workspace then
        activeRoot = root
        rootAddedConnection = root.ChildAdded:Connect(function(child)
            if activeRoot == root and child.Name == "Arena" then
                bindArena(child)
            end
        end)
        rootRemovedConnection = root.ChildRemoved:Connect(function(child)
            if activeRoot == root and child == activeArena then
                bindArena(root:FindFirstChild("Arena"))
            end
        end)
        bindArena(root:FindFirstChild("Arena"))
    else
        clearMetadata()
    end
end

-- Preserve the original harmless startup fallback until a generated map
-- arrives; absent or invalid active arenas do not masquerade as Classic.
local initialDefinition = ArenaVariants.get("Classic")
if initialDefinition then
    publish(initialDefinition)
end

local initialRoot = Workspace:FindFirstChild("GeneratedMap")
if initialRoot then
    bindMap(initialRoot)
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindMap(child)
    end
end)

Workspace.ChildRemoved:Connect(function(child)
    if child == activeRoot then
        bindMap(Workspace:FindFirstChild("GeneratedMap"))
    end
end)
