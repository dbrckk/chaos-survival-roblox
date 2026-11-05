-- Read-only source-aware visual ownership for the client-side platform
-- identity Parts. No physics mutations, asset creation or update loop.
-- The owner is the REAL server physical deck or original support post,
-- obtained from the existing renderer's exact source-authored weld.
local Rules = {}

local JOINT_NAMES = {
    "ChaosPlatformTrimWeld",
    "PlatformIdentityWeld",
    "OriginalSupportVisualWeld",
}

function Rules.owner(visual, platforms, decor)
    if typeof(visual) ~= "Instance" or not visual:IsA("BasePart")
        or not visual.Parent then return nil end
    for _, name in ipairs(JOINT_NAMES) do
        local joint = visual:FindFirstChild(name)
        if joint and (joint:IsA("Weld") or joint:IsA("WeldConstraint"))
            and joint.Part0 == visual then
            local native = joint.Part1
            if native and native:IsA("BasePart")
                and native.Parent == platforms
                and platforms ~= nil then
                return native
            end
            -- Only a real, named nonphysical support column in this
            -- generated arena is allowed to anchor its genuine 3D mesh.
            if native and native:IsA("BasePart")
                and native.Parent == decor
                and decor ~= nil
                and native.Name:match("^PlatformSupport%d+_%d+$")
                and native.Anchored
                and not native.CanCollide and not native.CanTouch
                and not native.CanQuery then
                return native
            end
        end
    end
    return nil
end

function Rules.distance(cameraPoint, arenaOrigin, ownerPosition)
    if typeof(cameraPoint) ~= "Vector3"
        or typeof(arenaOrigin) ~= "Vector3"
        or typeof(ownerPosition) ~= "Vector3" then return math.huge end
    -- Match old near-CENTER decoration, AND preserve actual adjacent deck
    -- finishes when the player is at a distant 320-stud perimeter route.
    return math.min((cameraPoint - arenaOrigin).Magnitude,
        (cameraPoint - ownerPosition).Magnitude)
end

return Rules
