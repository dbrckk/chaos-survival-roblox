-- Physics ownership for server-driven NPCs.
-- A generated Humanoid rig is not eligible for SetNetworkOwner until it
-- belongs to Workspace; claim the root assembly only after parenting.
local AISurvivorNetworkOwnership = {}

function AISurvivorNetworkOwnership.claim(model)
    if not model or not model:IsA("Model") or not model:IsDescendantOf(workspace) then
        return false
    end

    local root = model:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") or root.Anchored then
        return false
    end

    local checked, canSet = pcall(root.CanSetNetworkOwnership, root)
    if not checked or not canSet then
        return false
    end

    -- The root and Motor6D/weld-connected limbs form a single physics assembly.
    -- Unrelated terrain, anchored parts, and server-authoritative gameplay are
    -- not touched.
    return pcall(root.SetNetworkOwner, root, nil)
end

return AISurvivorNetworkOwnership
