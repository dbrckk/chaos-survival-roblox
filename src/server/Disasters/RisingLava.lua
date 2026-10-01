local Players = game:GetService("Players")

local D = {Name = "RISING LAVA", Hint = "GET HIGH!"}

function D.coverageSize(baseSize, padding)
    local size = typeof(baseSize) == "Vector3" and baseSize or Vector3.new(102, 2, 102)
    local extra = math.max(0, tonumber(padding) or 8)
    return Vector3.new(
        math.max(1, size.X + extra),
        4,
        math.max(1, size.Z + extra)
    )
end

function D.rootInsideLava(rootPosition, lavaPosition, lavaSize, clearance)
    if typeof(rootPosition) ~= "Vector3"
        or typeof(lavaPosition) ~= "Vector3"
        or typeof(lavaSize) ~= "Vector3"
    then
        return false
    end

    local safeClearance = math.max(0, tonumber(clearance) or 2.5)
    local halfX = math.max(0, lavaSize.X * 0.5)
    local halfZ = math.max(0, lavaSize.Z * 0.5)
    local lavaTopY = lavaPosition.Y + (lavaSize.Y * 0.5)

    return math.abs(rootPosition.X - lavaPosition.X) <= halfX
        and math.abs(rootPosition.Z - lavaPosition.Z) <= halfZ
        and (rootPosition.Y - safeClearance) <= lavaTopY
end

function D.isActiveContestant(player, ctx)
    if not player then
        return false
    end

    if ctx.IsContestantActive then
        return ctx.IsContestantActive(player) == true
    end

    for _, contestant in ipairs(ctx.Contestants or {}) do
        if contestant == player then
            return true
        end
    end

    return false
end

function D.start(ctx)
    local generatedMap = workspace:FindFirstChild("GeneratedMap")
    local arena = generatedMap and generatedMap:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    local lavaSize = D.coverageSize(
        base and base:IsA("BasePart") and base.Size or nil,
        8
    )

    local lava = Instance.new("Part")
    lava.Name = "RoundLava"
    lava.Size = lavaSize
    lava.Position = ctx.Config.ArenaCenter + Vector3.new(0, -8, 0)
    lava.Anchored = true
    lava.Material = Enum.Material.Neon
    lava.Color = Color3.fromRGB(255, 85, 0)
    lava.Parent = workspace

    lava.Touched:Connect(function(hit)
        local current = hit
        local character = nil
        local player = nil

        while current and current ~= workspace do
            if current:IsA("Model") then
                player = Players:GetPlayerFromCharacter(current)
                if player then
                    character = current
                    break
                end
            end
            current = current.Parent
        end

        local hum = character and character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and D.isActiveContestant(player, ctx) then
            hum.Health = 0
        end
    end)

    local startY = lava.Position.Y
    local duration = math.max(
        0.1,
        tonumber(ctx.RoundSeconds or ctx.Config.RoundSeconds) or 1
    )

    ctx.Cleanup[#ctx.Cleanup+1] = lava

    task.spawn(function()
        local started = os.clock()
        while ctx.Active() and lava.Parent do
            local alpha = math.clamp((os.clock() - started) / duration, 0, 1)
            lava.Position = Vector3.new(lava.Position.X, startY + alpha * 25, lava.Position.Z)

            for _, player in ipairs(ctx.Contestants or {}) do
                if D.isActiveContestant(player, ctx) then
                    local character = player.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    local hum = character and character:FindFirstChildOfClass("Humanoid")
                    if root
                        and root:IsA("BasePart")
                        and hum
                        and hum.Health > 0
                        and D.rootInsideLava(root.Position, lava.Position, lava.Size, 2.5)
                    then
                        hum.Health = 0
                    end
                end
            end

            task.wait(0.1)
        end
    end)
end

return D
