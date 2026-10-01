local D = {Name = "MOON GRAVITY", Hint = "DON'T FLY AWAY!"}

function D.compensationForce(mass, worldGravity, targetGravity)
    local safeMass = math.max(0, tonumber(mass) or 0)
    local world = math.max(0, tonumber(worldGravity) or 0)
    local target = math.max(0, tonumber(targetGravity) or 0)

    return math.max(0, safeMass * (world - target))
end

function D.start(ctx)
    local targetGravity = 55
    local worldGravity = workspace.Gravity
    local activeForces = {}

    for _, player in ipairs(ctx.Contestants or {}) do
        if ctx.IsContestantActive and not ctx.IsContestantActive(player) then
            continue
        end

        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

        if root and root:IsA("BasePart") and hum and hum.Health > 0 then
            local attachment = Instance.new("Attachment")
            attachment.Name = "MoonGravityAttachment"
            attachment.Parent = root

            local force = Instance.new("VectorForce")
            force.Name = "MoonGravityForce"
            force.Attachment0 = attachment
            force.RelativeTo = Enum.ActuatorRelativeTo.World
            force.ApplyAtCenterOfMass = true
            force.Force = Vector3.new(
                0,
                D.compensationForce(root.AssemblyMass, worldGravity, targetGravity),
                0
            )
            force.Parent = root

            activeForces[#activeForces+1] = {
                player = player,
                root = root,
                force = force,
            }

            ctx.Cleanup[#ctx.Cleanup+1] = force
            ctx.Cleanup[#ctx.Cleanup+1] = attachment
        end
    end

    task.spawn(function()
        while ctx.Active() do
            for _, state in ipairs(activeForces) do
                local root = state.root
                local force = state.force
                local player = state.player

                if root.Parent
                    and force.Parent
                    and (not ctx.IsContestantActive or ctx.IsContestantActive(player))
                then
                    force.Force = Vector3.new(
                        0,
                        D.compensationForce(root.AssemblyMass, workspace.Gravity, targetGravity),
                        0
                    )
                end
            end
            task.wait(0.25)
        end
    end)
end

return D
