-- One authored ribbon per human root. Reuse attachments after a trail is
-- externally removed so repeated recreation never accumulates GPU objects.
local Builder = {}

local function findChild(root, name, className)
    for _, child in ipairs(root:GetChildren()) do
        if child.Name == name and child:IsA(className) then
            return child
        end
    end
    return nil
end

local function attachment(root, name, position)
    local existing = findChild(root, name, "Attachment")
    if existing then return existing end
    local created = Instance.new("Attachment")
    created.Name = name
    created.Position = position
    created.Parent = root
    return created
end

function Builder.ensure(root, accent)
    local a = attachment(root, "ChaosMotionTrailLeft", Vector3.new(-0.72, -0.85, 0.48))
    local b = attachment(root, "ChaosMotionTrailRight", Vector3.new(0.72, -0.85, 0.48))
    local old = findChild(root, "ChaosMotionTrail", "Trail")
    if old then
        -- Streaming/reparenting can invalidate either attachment while the
        -- Trail survives. Repair in place instead of creating a second Trail.
        if old.Attachment0 ~= a then old.Attachment0 = a end
        if old.Attachment1 ~= b then old.Attachment1 = b end
        return old
    end
    local t = Instance.new("Trail")
    t.Name = "ChaosMotionTrail"
    t.Attachment0, t.Attachment1 = a, b
    t.FaceCamera = true
    t.MinLength = 0.05
    t.LightEmission = 0.8
    t.Color = ColorSequence.new(accent, accent:Lerp(Color3.new(1, 1, 1), 0.28))
    t.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.58),
        NumberSequenceKeypoint.new(1, 1),
    })
    t.Enabled = false
    t.Parent = root
    return t
end
return Builder
