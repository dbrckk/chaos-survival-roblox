-- A single, depth-tested world-space NEXT JUMP cue for new players.
-- The source deck must be under the character's feet. All targets are
-- server-owned, collision-checked, and sourced from the live arena.
-- No new Parts, collision, rewards, network traffic, lights or RenderStepped.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirstTimeExperience = require(ReplicatedStorage.Shared.FirstTimeExperience)
local JumpRouteCueRules = require(ReplicatedStorage.Shared.JumpRouteCueRules)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local marker
local caption
local currentTarget
local currentMap
local mapPlatforms

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function hide()
    if marker then marker.Enabled = false end
    currentTarget = nil
end

local function gui()
    if marker and marker.Parent == playerGui then return marker end
    if marker then marker:Destroy() end
    marker = Instance.new("BillboardGui")
    marker.Name = "RookiePhysicalJumpCue"
    marker.Size = UDim2.fromOffset(144, 38)
    marker.MaxDistance = 34
    marker.AlwaysOnTop = false
    marker.LightInfluence = 0
    marker.Enabled = false
    marker.ResetOnSpawn = false
    marker.Parent = playerGui

    caption = Instance.new("TextLabel")
    caption.Name = "NextPhysicalJump"
    caption.Size = UDim2.fromScale(1, 1)
    caption.BackgroundColor3 = Color3.fromRGB(13, 27, 38)
    caption.BackgroundTransparency = 0.10
    caption.BorderSizePixel = 0
    caption.TextColor3 = Color3.fromRGB(210, 248, 236)
    caption.TextStrokeTransparency = 0.4
    caption.Font = Enum.Font.GothamBlack
    caption.TextScaled = true
    caption.Text = player.LocaleId:sub(1, 2) == "fr"
        and "SAUT SUIVANT  ↑" or "NEXT JUMP  ↑"
    caption.Parent = marker

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = caption
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(70, 207, 185)
    border.Thickness = 1.6
    border.Parent = caption
    return marker
end

local function update()
    local games = FirstTimeExperience.effectiveGames(
        player:GetAttribute("Games"),
        player:GetAttribute("SessionRoundsPlayed")
    )
    -- This is instructional only: never compete with the normal hazard
    -- HUD, reward panels or experienced players' own route choices.
    if not FirstTimeExperience.isRookie(games)
        or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true then
        hide()
        return false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0
        or humanoid.FloorMaterial == Enum.Material.Air then
        hide()
        return true
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    local base = arena and arena:FindFirstChild("Base")
    if not platforms or not base or not base:IsA("BasePart") then
        hide()
        return true
    end

    -- The old platform folder can be destroyed when the map changes.
    -- Do not keep a stale target, array or listener from a previous round.
    if generated ~= currentMap or platforms ~= mapPlatforms then
        currentMap, mapPlatforms = generated, platforms
        hide()
    end

    rayParams.FilterDescendantsInstances = {character}
    local hit = workspace:Raycast(
        root.Position, Vector3.new(0, -9, 0), rayParams
    )
    local from = hit and hit.Instance
    if not from or from.Parent ~= platforms or hit.Normal.Y < 0.65 then
        hide()
        return true
    end

    local target = JumpRouteCueRules.nextPhysical(
        from, platforms:GetChildren(), base.Position,
        arena:GetAttribute("VariantId")
    )
    if not target or (root.Position - target.Position).Magnitude > 36 then
        hide()
        return true
    end

    local sign = gui()
    if currentTarget ~= target then
        currentTarget = target
        sign.Adornee = target
        sign.StudsOffsetWorldSpace = Vector3.new(
            0, target.Size.Y * 0.5 + 3.1, 0
        )
    end
    sign.Enabled = true
    return true
end

task.spawn(function()
    while true do
        local active = update()
        task.wait(active and 0.40 or 0.85)
    end
end)
