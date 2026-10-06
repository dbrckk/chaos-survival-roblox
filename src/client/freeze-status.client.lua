local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local tint = Lighting:FindFirstChild("FreezeStatusTint") or Instance.new("ColorCorrectionEffect")
tint.Name = "FreezeStatusTint"
tint.Enabled = true
tint.Brightness = 0
tint.Contrast = 0
tint.Saturation = 0
tint.TintColor = Color3.new(1, 1, 1)
tint.Parent = Lighting

local activeHighlight = nil
local humanoidConnection = nil
local characterToken = 0

local function clearHighlight()
    if activeHighlight and activeHighlight.Parent then
        activeHighlight:Destroy()
    end
    activeHighlight = nil
end

local function applyFrozenVisual(character, frozen)
    clearHighlight()

    if frozen and character and character.Parent then
        local highlight = Instance.new("Highlight")
        highlight.Name = "LocalFreezeStatusHighlight"
        highlight.Adornee = character
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.FillColor = Color3.fromRGB(145, 220, 255)
        highlight.OutlineColor = Color3.fromRGB(205, 245, 255)
        highlight.FillTransparency = 0.84
        highlight.OutlineTransparency = 0.22
        highlight.Parent = character
        activeHighlight = highlight
    end

    TweenService:Create(
        tint,
        TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        frozen and {
            TintColor = Color3.fromRGB(232, 246, 255),
            Saturation = -0.045,
            Contrast = 0.015,
            Brightness = 0,
        } or {
            TintColor = Color3.new(1, 1, 1),
            Saturation = 0,
            Contrast = 0,
            Brightness = 0,
        }
    ):Play()
end

local function bindCharacter(character)
    characterToken += 1
    local token = characterToken

    if humanoidConnection then
        humanoidConnection:Disconnect()
        humanoidConnection = nil
    end

    clearHighlight()
    applyFrozenVisual(nil, false)

    local humanoid = character:FindFirstChildOfClass("Humanoid")
        or character:WaitForChild("Humanoid", 5)
    if token ~= characterToken or not humanoid then
        return
    end

    local function refresh()
        if token ~= characterToken then
            return
        end
        applyFrozenVisual(character, humanoid:GetAttribute("ChaosFrozen") == true)
    end

    humanoidConnection = humanoid:GetAttributeChangedSignal("ChaosFrozen"):Connect(refresh)
    refresh()
end

player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(function(character)
    if character == player.Character then
        characterToken += 1
        if humanoidConnection then
            humanoidConnection:Disconnect()
            humanoidConnection = nil
        end
        clearHighlight()
        applyFrozenVisual(nil, false)
    end
end)

if player.Character then
    task.defer(bindCharacter, player.Character)
end
