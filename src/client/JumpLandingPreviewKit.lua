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

    local function hide()
        targetPart = nil
        for _, part in ipairs(pieces) do
            part.Transparency = 1
        end
    end

    local function validSurface(hit)
        return hit ~= nil and hit.Instance:IsA("BasePart")
            and hit.Instance.CanCollide
            and hit.Instance:GetAttribute("CollapsePhase") == nil
            and hit.Normal.Y >= 0.84
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
        if targetPart and (not targetPart.Parent or not targetPart.CanCollide
            or targetPart:GetAttribute("CollapsePhase") ~= nil) then
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

        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Include
        rayParams.FilterDescendantsInstances = helix
            and {base, platforms, helix} or {base, platforms}
        rayParams.IgnoreWater = true
        rayParams.RespectCanCollide = true

        local origin = root.Position + Vector3.new(0, 0.25, 0)
        local first = workspace:Raycast(origin, Vector3.new(0, -24, 0), rayParams)
        if not validSurface(first) then
            hide()
            return
        end

        local velocity = root.AssemblyLinearVelocity
        local footOffset = root.Size.Y * 0.5 + humanoid.HipHeight
        local footY = root.Position.Y - footOffset
        local firstTime = Rules.timeToSurface(
            velocity.Y, workspace.Gravity, footY - first.Position.Y
        )
        if not firstTime then
            hide()
            return
        end

        -- Sample actual collision at the short, locally projected contact
        -- point. A missed platform edge means no reticle, not fake safety.
        local offset = Vector3.new(velocity.X, 0, velocity.Z) * firstTime
        if offset.Magnitude > 8 then
            hide()
            return
        end
        local projected = origin + offset
        local hit = workspace:Raycast(projected, Vector3.new(0, -24, 0), rayParams)
        if not validSurface(hit) then
            hide()
            return
        end

        local correctedTime = Rules.timeToSurface(
            velocity.Y, workspace.Gravity, footY - hit.Position.Y
        )
        if not correctedTime or math.abs(correctedTime - firstTime) > 0.10 then
            hide()
            return
        end

        local margin = Rules.edgeMargin(hit.Instance, hit.Position)
        if not margin or margin < 0 then
            hide()
            return
        end

        targetPart = hit.Instance
        local caution = margin < 1.75
        local color = caution and Color3.fromRGB(246, 159, 195)
            or Color3.fromRGB(135, 222, 252)
        local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
        local reduced = player:GetAttribute("ReduceMotion") == true
        local count = tier == "Low" and 2 or 4
        local up = hit.Normal.Unit
        local forward = Vector3.new(0, 0, -1)
        forward = forward - up * forward:Dot(up)
        if forward.Magnitude < 0.1 then
            forward = Vector3.xAxis
        end
        local center = hit.Position + up * 0.09
        local basis = CFrame.lookAt(center, center + forward.Unit, up)
        for index, part in ipairs(pieces) do
            if index <= count then
                local angle = (index - 1) * math.pi * 0.5 + math.pi * 0.25
                part.CFrame = basis * CFrame.Angles(0, angle, 0)
                    * CFrame.new(0, 0, -0.77)
                part.Color = color
                -- Only outlines: never tint or cover an underlying hazard.
                part.Transparency = reduced and 0.50
                    or (tier == "Low" and 0.44 or 0.34)
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
