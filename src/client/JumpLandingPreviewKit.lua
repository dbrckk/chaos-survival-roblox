-- Four reusable, non-colliding contact brackets. A real collision
-- raycast anchors the preview; it never adds a platform or a movement buff.
-- Reused by the existing movement-feel render owner (no additional loop).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = require(ReplicatedStorage.Shared.JumpLandingPreviewRules)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local JumpLandingPreviewKit = {}

function JumpLandingPreviewKit.new(player)
    local folder = Instance.new("Folder")
    folder.Name = "JumpLandingPreviewLocal"
    folder.Parent = workspace

    local pieces = {}
    for index = 1, 4 do
        local part = Instance.new("Part")
        part.Name = "LandingContactBracket" .. index
        part.Size = Vector3.new(0.11, 0.045, 0.66)
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(128, 224, 255)
        part.Transparency = 1
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Parent = folder
        pieces[index] = part
    end

    local nextSampleAt = 0
    local targetPart = nil
    local showing = false

    -- Reuse one collision query rather than allocating RaycastParams and
    -- filter arrays ten times per second while the player is descending.
    -- Rebind only if streamed map sections are replaced or arrive late.
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.IgnoreWater = true
    rayParams.RespectCanCollide = true
    local observedArena = nil
    local observedBase = nil
    local observedPlatforms = nil
    local observedHelix = nil

    local function hide()
        -- No redundant property writes every RenderStep in the lobby or
        -- during a grounded run: Android needs the visual state, not 60Hz
        -- writes to the same four already-transparent Parts.
        if not showing and not targetPart then return end
        showing = false
        targetPart = nil
        for _, part in ipairs(pieces) do
            part.Transparency = 1
        end
    end

    local function validSurface(hit)
        return hit ~= nil and hit.Normal.Y >= 0.84
            and Rules.surfaceStatus(hit.Instance) ~= "Unavailable"
    end

    local function update(phase, root, humanoid)
        if not root or not root.Parent or not humanoid
            or not Rules.eligible(
                phase,
                player:GetAttribute("RoundParticipant"),
                player:GetAttribute("RoundEliminated"),
                humanoid.Health,
                humanoid:GetState(),
                humanoid.FloorMaterial ~= Enum.Material.Air,
                root.AssemblyLinearVelocity.Y
            )
        then
            hide()
            return
        end

        -- Collision and collapse can change between samples. Never leave a
        -- visible marker on a deck that has disappeared in the meantime.
        if targetPart and (not targetPart.Parent
            or Rules.surfaceStatus(targetPart) == "Unavailable") then
            hide()
        end

        local now = os.clock()
        if now < nextSampleAt then return end
        nextSampleAt = now + Rules.SampleSeconds

        local generated = workspace:FindFirstChild("GeneratedMap")
        local arena = generated and generated:FindFirstChild("Arena")
        local base = arena and arena:FindFirstChild("Base")
        local platforms = arena and arena:FindFirstChild("Platforms")
        local helix = arena and arena:FindFirstChild("HelixCircuit")
        if not base or not platforms then
            hide()
            return
        end

        if arena ~= observedArena or base ~= observedBase
            or platforms ~= observedPlatforms or helix ~= observedHelix then
            observedArena = arena
            observedBase = base
            observedPlatforms = platforms
            observedHelix = helix
            rayParams.FilterDescendantsInstances = helix
                and {base, platforms, helix} or {base, platforms}
        end

        local origin = root.Position + Vector3.new(0, 0.25, 0)
        local velocity = root.AssemblyLinearVelocity
        local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
        local footOffset = root.Size.Y * 0.5 + humanoid.HipHeight
        local footY = root.Position.Y - footOffset

        -- A straight-down ray often hits the LOW base floor while the
        -- player is mid-jump over a gap between two higher decks. Probe the
        -- actual horizontal trajectory instead. This remains only a
        -- short-range visual estimate, with a confirmed physical landing
        -- target; no route prediction or gameplay authority.
        local bestCandidate = nil
        local bestTime = nil
        local bestError = math.huge
        for _, probeTime in ipairs(Rules.ProbeSeconds) do
            local offset = horizontalVelocity * probeTime
            if offset.Magnitude > Rules.MaxHorizontalTravel then
                continue
            end
            local candidate = workspace:Raycast(
                origin + offset, Vector3.new(0, -24, 0), rayParams
            )
            if validSurface(candidate) then
                local contactTime = Rules.timeToSurface(
                    velocity.Y, workspace.Gravity, footY - candidate.Position.Y
                )
                if Rules.probeMatches(probeTime, contactTime) then
                    local errorSeconds = math.abs(probeTime - contactTime)
                    -- Prefer first physical impact (the elevated
                    -- target), then the better-timed probe for ties.
                    if Rules.preferContact(
                        probeTime, contactTime, bestTime, bestError
                    ) and (horizontalVelocity * contactTime).Magnitude
                        <= Rules.MaxHorizontalTravel then
                        bestCandidate = candidate
                        bestTime = contactTime
                        bestError = errorSeconds
                    end
                end
            end
        end

        -- All three candidates are evaluated before we commit to a surface.
        -- One final physical ray confirms the closest timed contact. This
        -- caps the whole airborne sample at FOUR raycasts, including when
        -- an earlier probe saw the lower base while crossing a gap.
        if not bestCandidate then
            hide()
            return
        end
        local hit = workspace:Raycast(
            origin + horizontalVelocity * bestTime,
            Vector3.new(0, -24, 0),
            rayParams
        )
        if not validSurface(hit) or hit.Instance ~= bestCandidate.Instance then
            hide()
            return
        end

        local margin = Rules.edgeMargin(hit.Instance, hit.Position)
        if not margin or margin < 0 then
            hide()
            return
        end

        targetPart = hit.Instance
        showing = true
        local caution = margin < 1.75
        local warning = Rules.surfaceStatus(hit.Instance) == "Warning"
        -- Danger is communicated in both colour and silhouette. The
        -- same four reusable brackets contract into an unmistakable red
        -- X, without hiding the server's yellow 1.35-second warning.
        local color = warning and Color3.fromRGB(255, 80, 90)
            or (caution and Color3.fromRGB(246, 159, 195)
                or Color3.fromRGB(135, 222, 252))
        local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
        local reduced = player:GetAttribute("ReduceMotion") == true
        -- A danger X needs all four EXISTING segments on Android Low,
        -- otherwise two fragments could resemble a safe landing bracket.
        local count = warning and 4 or (tier == "Low" and 2 or 4)
        local up = hit.Normal.Unit
        local forward = Vector3.new(0, 0, -1)
        forward = forward - up * forward:Dot(up)
        if forward.Magnitude < 0.1 then
            forward = Vector3.xAxis
        end
        -- Server-authored inset panels can sit 0.18 studs above the
        -- collision surface; lift only the thin outline to avoid z-fighting.
        local center = hit.Position + up * 0.22
        local basis = CFrame.lookAt(center, center + forward.Unit, up)
        for index, part in ipairs(pieces) do
            if index <= count then
                local angle = (index - 1) * math.pi * 0.5 + math.pi * 0.25
                part.CFrame = basis * CFrame.Angles(0, angle, 0)
                    * CFrame.new(0, 0, warning and -0.43 or -0.77)
                part.Size = warning and Vector3.new(0.18, 0.045, 0.93)
                    or Vector3.new(0.11, 0.045, 0.66)
                part.Color = color
                -- Only outlines: never tint or cover an underlying hazard.
                part.Transparency = warning
                    and (reduced and 0.43 or 0.20)
                    or (reduced and 0.50
                        or (tier == "Low" and 0.44 or 0.34))
            else
                part.Transparency = 1
            end
        end
    end

    return {
        update = update,
        hide = hide,
    }
end

return JumpLandingPreviewKit
