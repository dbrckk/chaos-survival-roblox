local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local FrozenArmorKit = require(script.Parent.FrozenArmorKit)
local CelebrationMeshes = require(script.Parent.LobbyCelebrationMeshes)

local player = Players.LocalPlayer

local tint = Lighting:FindFirstChild("FreezeStatusTint")
if tint and not tint:IsA("ColorCorrectionEffect") then
    tint:Destroy()
    tint = nil
end
if not tint then
    tint = Instance.new("ColorCorrectionEffect")
end
tint.Name = "FreezeStatusTint"
tint.Enabled = true
tint.Brightness = 0
tint.Contrast = 0
tint.Saturation = 0
tint.TintColor = Color3.new(1, 1, 1)
tint.Parent = Lighting

local activeHighlight = nil
local humanoidConnection = nil
local torsoConnection = nil
local characterToken = 0
local tintTween = nil
local activeArmor = {}
local meshPressure = tonumber(player:GetAttribute("OptionalVfxPressure")) or 0

local function clearArmor()
    FrozenArmorKit.clear(activeArmor)
    activeArmor = {}
end

local function buildArmor(character)
    local tier = VfxQuality.deviceTier(
        player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled
    )
    local reduced = player:GetAttribute("ReduceMotion") == true
    local source = not reduced and tier.Name ~= "Low"
        and CelebrationMeshes.readyProfile("fragment", meshPressure)
    local cloneShard = if source then function()
        return CelebrationMeshes.cloneProfile(source)
    end else nil
    activeArmor = FrozenArmorKit.build(character, tier.Name, reduced, cloneShard)
end

local function disconnectCharacter()
    if humanoidConnection then
        humanoidConnection:Disconnect()
        humanoidConnection = nil
    end
    if torsoConnection then
        torsoConnection:Disconnect()
        torsoConnection = nil
    end
end

local function clearHighlight()
    if activeHighlight and activeHighlight.Parent then
        activeHighlight:Destroy()
    end
    activeHighlight = nil
end

local function applyFrozenVisual(character, frozen)
    clearHighlight()
    clearArmor()

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
        -- Never allocate crystal pieces outside a frozen local avatar.
        -- R6 and R15 use the same torso-relative non-colliding recipe.
        buildArmor(character)
    end

    if tintTween then
        tintTween:Cancel()
        tintTween = nil
    end

    tintTween = TweenService:Create(
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
    )
    tintTween:Play()
end

local function bindCharacter(character)
    characterToken += 1
    local token = characterToken

    disconnectCharacter()

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
    torsoConnection = character.ChildAdded:Connect(function(child)
        if token == characterToken and child:IsA("BasePart")
            and (child.Name == "UpperTorso" or child.Name == "Torso")
            and humanoid:GetAttribute("ChaosFrozen") == true then
            clearArmor()
            buildArmor(character)
        end
    end)
    refresh()
end

local function refreshArmorQuality()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if character and humanoid and humanoid:GetAttribute("ChaosFrozen") == true then
        -- Retain the current tint/highlight and rebuild only the tiered
        -- crystal geometry, rather than restarting the freeze feedback tween.
        clearArmor()
        buildArmor(character)
    end
end

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshArmorQuality)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(refreshArmorQuality)
player:GetAttributeChangedSignal("OptionalVfxPressure"):Connect(function()
    local previous = meshPressure
    meshPressure = tonumber(player:GetAttribute("OptionalVfxPressure")) or 0
    if (previous < 1) ~= (meshPressure < 1) then refreshArmorQuality() end
end)

player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(function(character)
    if character == player.Character then
        characterToken += 1
        disconnectCharacter()
        clearHighlight()
        applyFrozenVisual(nil, false)
    end
end)

if player.Character then
    task.defer(bindCharacter, player.Character)
end
