-- Client-only practice pad presentation. An Attachment must be a direct
-- child of its BasePart; nesting it inside a Folder can detach the particle
-- emitter from the world's actual floor-pad transform.
local Kit = {}

function Kit.rate(quality, reduced)
    if reduced == true then return 0 end
    if not quality or quality.Name == "Low" then return 0.8 end
    local particles = tonumber(quality.ParticleScale) or 0
    if particles ~= particles or math.abs(particles) == math.huge then
        return 0
    end
    return math.clamp(4 * particles, 0, 20)
end

function Kit.create(pad)
    if typeof(pad) ~= "Instance" or not pad:IsA("BasePart")
        or pad:GetAttribute("LobbyPracticePad") ~= true
        or pad:FindFirstChild("PracticePadPolishLocal")
        or pad:FindFirstChild("PracticeMotesAttachment") then
        return nil
    end

    local folder = Instance.new("Folder")
    folder.Name = "PracticePadPolishLocal"
    folder.Parent = pad

    -- Roblox particle emitters use an Attachment in a BasePart, not one
    -- inside a Folder. Keep it separate from the highlight container.
    local attachment = Instance.new("Attachment")
    attachment.Name = "PracticeMotesAttachment"
    attachment.Position = Vector3.new(0, 0.25, 0)
    attachment.Parent = pad

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "PracticeMotes"
    emitter.Rate = 4
    emitter.Lifetime = NumberRange.new(0.25, 0.45)
    emitter.Speed = NumberRange.new(1.2, 2.8)
    emitter.SpreadAngle = Vector2.new(35, 35)
    emitter.LightEmission = 0.9
    emitter.Color = ColorSequence.new(pad.Color, Color3.new(1, 1, 1))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.25),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment

    local highlight = Instance.new("Highlight")
    highlight.Name = "PracticeHighlight"
    highlight.Adornee = pad
    highlight.FillColor = pad.Color
    highlight.FillTransparency = 0.90
    highlight.OutlineColor = pad.Color:Lerp(Color3.new(1, 1, 1), 0.42)
    highlight.OutlineTransparency = 0.18
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = folder

    return {
        folder = folder,
        attachment = attachment,
        emitter = emitter,
        highlight = highlight,
    }
end

-- Localize the server-authored 3D practice sign on this client only.
-- A late-streaming BillboardGui/TextLabel may arrive after the pad.
function Kit.localizePadLabel(pad, text)
    if typeof(pad) ~= "Instance" or not pad:IsA("BasePart")
        or type(text) ~= "string" or text == "" then
        return false
    end
    local billboard = pad:FindFirstChild("PracticeLabel")
    if not billboard or not billboard:IsA("BillboardGui") then
        return false
    end
    local label = billboard:FindFirstChildOfClass("TextLabel")
    if not label then return false end
    if label.Text ~= text then label.Text = text end
    return true
end

function Kit.destroy(bundle)
    if not bundle then return end
    if bundle.labelConnection then bundle.labelConnection:Disconnect() end
    if bundle.glyphConnection then bundle.glyphConnection:Disconnect() end
    if bundle.attachment then bundle.attachment:Destroy() end
    if bundle.folder then bundle.folder:Destroy() end
end

return Kit
