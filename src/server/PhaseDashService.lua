local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhaseDashRules = require(ReplicatedStorage.Shared.PhaseDashRules)

local PhaseDashService = {}

function PhaseDashService.start(remote, phaseProvider)
    assert(remote and remote:IsA("RemoteEvent"), "PhaseDash requires RemoteEvent")
    assert(type(phaseProvider) == "function", "PhaseDash requires phase provider")
    local nextAllowed = {}

    Players.PlayerRemoving:Connect(function(player)
        nextAllowed[player] = nil
    end)

    remote.OnServerEvent:Connect(function(player)
        if player.Parent ~= Players then
            return
        end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root or not root:IsA("BasePart")
            or not root:IsDescendantOf(workspace) then
            return
        end

        local now = os.clock()
        if not PhaseDashRules.canActivate(
            phaseProvider(),
            player:GetAttribute("RoundParticipant"),
            player:GetAttribute("RoundEliminated"),
            humanoid.Health,
            humanoid.FloorMaterial ~= Enum.Material.Air,
            now,
            nextAllowed[player]
        ) then
            return
        end

        nextAllowed[player] = PhaseDashRules.nextReadyAt(now)
        -- The same server-validated heading drives movement and the
        -- replicated cosmetic shockwave (including sideways dashes).
        local heading = PhaseDashRules.direction(
            humanoid.MoveDirection, root.CFrame.LookVector
        )
        root.AssemblyLinearVelocity = PhaseDashRules.velocity(
            root.AssemblyLinearVelocity, heading, heading
        )
        local readyAt = workspace:GetServerTimeNow() + PhaseDashRules.Cooldown
        player:SetAttribute("PhaseDashReadyAt", readyAt)

        -- Replicate the heading before the pulse so remote observers do
        -- not incorrectly orient strafe dashes along the avatar's facing.
        -- Older clients that lack this attribute still use avatar facing.
        character:SetAttribute("PhaseDashHeading", heading)
        -- Replicated one-shot on the character makes the effect visible to
        -- other players without trusting a VFX event from the requestor.
        character:SetAttribute(
            "PhaseDashPulse",
            (tonumber(character:GetAttribute("PhaseDashPulse")) or 0) + 1
        )
    end)
end

return PhaseDashService
