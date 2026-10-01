local Workspace = game:GetService("Workspace")

local ArenaVariants = require(script.Parent.ArenaVariants)

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

local root = Workspace:FindFirstChild("GeneratedMap")
if root then
    watchGeneratedMap(root)
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        watchGeneratedMap(child)
    end
end)
