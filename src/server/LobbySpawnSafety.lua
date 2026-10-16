-- Server-owned, spawn-only recovery for the lobby.
-- Prevents a fresh R6/R15 character from remaining embedded in the
-- central stage or immobilized after native SpawnLocation placement.
-- Never moves a round contestant, never runs during active play.
local Players = game:GetService("Players")

local LobbySpawnSafety = {}

local CHECK_DELAY = 0.9
local LOBBY_RADIUS = 52
local EPSILON = 1.0

local function validLobby()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local floor = lobby and lobby:FindFirstChild("Floor")
    local decor = lobby and lobby:FindFirstChild("Decor")
    local centerPlatform = decor and decor:FindFirstChild("CenterPlatform")
    if not floor or not floor:IsA("BasePart")
        or not centerPlatform or not centerPlatform:IsA("BasePart") then
        return nil
    end
    return floor, centerPlatform
end

local function closeToLobby(floor, position)
    local delta = Vector3.new(position.X - floor.Position.X, 0,
        position.Z - floor.Position.Z)
    return delta.Magnitude <= LOBBY_RADIUS
end

local function centerStageFloor(platform, position)
    local localPosition = platform.CFrame:PointToObjectSpace(position)
    return math.abs(localPosition.X) < platform.Size.X * 0.5
        and math.abs(localPosition.Z) < platform.Size.Z * 0.5
end

function LobbySpawnSafety.recover(player, character)
    if player.Parent ~= Players or player.Character ~= character
        or player:GetAttribute("RoundParticipant") == true then
        return false
    end

    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0
        or not root or not root:IsA("BasePart") then
        return false
    end

    local floor, platform = validLobby()
    if not floor or not closeToLobby(floor, root.Position) then
        -- Never touch an avatar already in the arena or another world area.
        return false
    end

    local floorTop = floor.Position.Y + floor.Size.Y * 0.5
    local stageTop = platform.Position.Y + platform.Size.Y * 0.5
    local expectedSurface = centerStageFloor(platform, root.Position)
        and stageTop or floorTop
    local footY = root.Position.Y - humanoid.HipHeight - root.Size.Y * 0.5
    local embedded = footY < expectedSurface - EPSILON
    local immobilized = root.Anchored or humanoid.PlatformStand
    if not embedded and not immobilized then
        return false
    end

    -- Use a stable, unobstructed central-stage entry, not a client request.
    -- HipHeight permits both R6 and R15 without moving the avatar into the
    -- collision surface; the extra clearance lets Roblox settle naturally.
    local clearance = math.max(3.5, humanoid.HipHeight
        + root.Size.Y * 0.5 + 1.0)
    local landing = CFrame.new(
        platform.Position.X,
        stageTop + clearance,
        platform.Position.Z - 7
    )
    character:PivotTo(landing)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Anchored = false
    if humanoid.PlatformStand then
        humanoid.PlatformStand = false
    end
    if humanoid.Sit then
        humanoid.Sit = false
    end
    player:SetAttribute("LobbySpawnRecovered", true)
    return true
end

local function inspectCharacter(player, character)
    task.spawn(function()
        -- CharacterAdded can precede the root/humanoid on slow connections.
        local root = character:WaitForChild("HumanoidRootPart", 6)
        local humanoid = character:WaitForChild("Humanoid", 6)
        if not root or not humanoid then return end
        task.wait(CHECK_DELAY)
        LobbySpawnSafety.recover(player, character)
    end)
end

local playerConnections = {}

local function bindPlayer(player)
    if playerConnections[player] then return end
    playerConnections[player] = player.CharacterAdded:Connect(function(character)
        inspectCharacter(player, character)
    end)
    if player.Character then
        inspectCharacter(player, player.Character)
    end
end

function LobbySpawnSafety.start()
    Players.PlayerAdded:Connect(bindPlayer)
    Players.PlayerRemoving:Connect(function(player)
        local connection = playerConnections[player]
        if connection then
            connection:Disconnect()
            playerConnections[player] = nil
        end
    end)
    for _, player in ipairs(Players:GetPlayers()) do
        bindPlayer(player)
    end
end

return LobbySpawnSafety
