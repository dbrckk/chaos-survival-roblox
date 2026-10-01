local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ArenaVariants = require(script.Parent.ArenaVariants)
local ArenaMechanics = require(script.Parent.ArenaMechanics)

local metadata = ReplicatedStorage:FindFirstChild("ArenaMetadata") or Instance.new("Folder")
metadata.Name = "ArenaMetadata"
metadata.Parent = ReplicatedStorage

local function publish(definition)
    metadata:SetAttribute("VariantId", definition.Id)
    metadata:SetAttribute("VariantName", definition.Name)
    metadata:SetAttribute("StrategyHint", definition.StrategyHint)

    local mechanic = ArenaMechanics.get(definition.Id)
    metadata:SetAttribute("MechanicName", mechanic and mechanic.Name or "")
    metadata:SetAttribute("MechanicHint", mechanic and mechanic.Hint or "")
end

local function applyMetadata(arena)
    if not arena or not arena:IsA("Folder") or arena.Name ~= "Arena" then
        return
    end

    local variantId = arena:GetAttribute("VariantId") or "Classic"
    local definition = ArenaVariants.get(variantId)
    if not definition then
        return
    end

    arena:SetAttribute("StrategyHint", definition.StrategyHint)
    publish(definition)
end

local function watchGeneratedMap(root)
    local arena = root:FindFirstChild("Arena")
    if arena then
        task.defer(applyMetadata, arena)
    end

    root.ChildAdded:Connect(function(child)
        if child.Name == "Arena" then
            task.defer(applyMetadata, child)
        end
    end)
end

local initialDefinition = ArenaVariants.get("Classic")
if initialDefinition then
    publish(initialDefinition)
end

local root = Workspace:FindFirstChild("GeneratedMap")
if root then
    watchGeneratedMap(root)
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        watchGeneratedMap(child)
    end
end)
