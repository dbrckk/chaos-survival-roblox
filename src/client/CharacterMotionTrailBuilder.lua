local Builder = {}
function Builder.ensure(root, accent)
    local old = root:FindFirstChild("ChaosMotionTrail")
    if old and old:IsA("Trail") then return old end
    local a = Instance.new("Attachment")
    a.Name = "ChaosMotionTrailLeft"
    a.Position = Vector3.new(-0.72, -0.85, 0.48)
    a.Parent = root
    local b = Instance.new("Attachment")
    b.Name = "ChaosMotionTrailRight"
    b.Position = Vector3.new(0.72, -0.85, 0.48)
    b.Parent = root
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
