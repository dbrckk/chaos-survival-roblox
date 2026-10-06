local D = {Name = "DISAPPEARING PLATFORMS", Hint = "YELLOW MEANS MOVE!"}

function D.eligiblePlatforms(folder, activeStates)
    local result = {}
    if not folder then
        return result
    end

    for _, item in ipairs(folder:GetChildren()) do
        if item:IsA("BasePart")
            and item.CanCollide
            and not activeStates[item]
        then
            result[#result+1] = item
        end
    end

    return result
end

function D.start(ctx)
    local generatedMap = workspace:FindFirstChild("GeneratedMap")
    local arena = generatedMap and generatedMap:FindFirstChild("Arena")
    local folder = arena and arena:FindFirstChild("Platforms")
    if not folder then
        return
    end

    local activeStates = {}
    local generation = 0

    local function restore(part)
        local state = activeStates[part]
        if not state then
            return
        end

        activeStates[part] = nil
        if part and part.Parent then
            part.Transparency = state.transparency
            part.CanCollide = state.canCollide
            part.Color = state.color
            part.Material = state.material
            part:SetAttribute("CollapsePhase", nil)
            part:SetAttribute("CollapseWarningStartedAt", nil)
        end
    end

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        generation += 1
        local parts = {}
        for part in pairs(activeStates) do
            table.insert(parts, part)
        end
        for _, part in ipairs(parts) do
            restore(part)
        end
    end

    task.spawn(function()
        while ctx.Active() and folder.Parent do
            local parts = D.eligiblePlatforms(folder, activeStates)
            if #parts > 0 then
                local p = parts[math.random(1, #parts)]
                generation += 1
                local token = generation
                activeStates[p] = {
                    transparency = p.Transparency,
                    canCollide = p.CanCollide,
                    color = p.Color,
                    material = p.Material,
                    generation = token,
                }

                p:SetAttribute("CollapseWarningStartedAt", workspace:GetServerTimeNow())
                p:SetAttribute("CollapsePhase", "Warning")
                p.Color = Color3.fromRGB(255, 205, 70)
                p.Material = Enum.Material.Neon

                -- Keep one authoritative replicated fallback cue. The animated
                -- edge/cross pulse is client-owned by disappearing-platform-readability,
                -- avoiding repeated server property replication for cosmetic motion.
                p.Transparency = math.min(p.Transparency, 0.24)
                p.Color = Color3.fromRGB(255, 205, 70)
                task.wait(0.75)
                local state = activeStates[p]
                if ctx.Active() and state and state.generation == token and p.Parent then
                    p:SetAttribute("CollapsePhase", "Gone")
                    p.Transparency = 1
                    p.CanCollide = false

                    task.delay(2.0, function()
                        local delayedState = activeStates[p]
                        if delayedState and delayedState.generation == token then
                            restore(p)
                        end
                    end)
                else
                    restore(p)
                end
            end

            local intensity = ctx.Intensity and ctx.Intensity() or 1
            task.wait(math.max(0.95, 1.4 / intensity))
        end
    end)
end

return D
