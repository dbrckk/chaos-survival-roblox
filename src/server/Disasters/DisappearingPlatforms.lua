local D = {Name = "DISAPPEARING PLATFORMS", Hint = "YELLOW MEANS MOVE!"}

function D.eligiblePlatforms(folder, activeStates)
    local result = {}
    if not folder then
        return result
    end

    for _, item in ipairs(folder:GetChildren()) do
        if item:IsA("BasePart")
            and item.CanCollide
            -- Tower Run's engineered skybridges are permanent route backbones.
            -- Their attached visual rails must never advertise a phantom path.
            and item:GetAttribute("ChaosSkybridge") ~= true
            and not activeStates[item]
        then
            result[#result+1] = item
        end
    end

    return result
end

-- The physical platform is not the only thing visible: server-authored
-- deck panels, subframes, core glow and structural supports must follow its
-- disappearance. Otherwise players see a phantom floor after collision is
-- disabled. Skybridges are intentionally permanent and never eligible.
function D.cosmeticsForPlatform(decor, platform)
    if not decor or not platform or not platform:IsA("BasePart") then
        return {}
    end
    local index = platform.Name:match("^Platform(%d+)$")
    if not index then return {} end

    local result = {}
    for _, item in ipairs(decor:GetChildren()) do
        if item:IsA("BasePart") then
            local attachedIndex =
                item.Name:match("^PlatformGlow(%d+)$")
                or item.Name:match("^PlatformPanel(%d+)$")
                or item.Name:match("^PlatformUnderFrame(%d+)$")
                or item.Name:match("^PlatformCoreGlow(%d+)$")
                or item.Name:match("^PlatformSupport(%d+)_%d+$")
            if attachedIndex == index then
                table.insert(result, {
                    part = item,
                    transparency = item.Transparency,
                })
            end
        end
    end
    return result
end

function D.setCosmeticsPhase(cosmetics, phase)
    for _, entry in ipairs(cosmetics or {}) do
        local piece = entry.part
        if piece and piece.Parent then
            if phase == "Gone" then
                piece.Transparency = 1
            elseif phase == "Warning" then
                -- Expose the amber authoritative warning deck through the
                -- opaque top panel instead of camouflaging a collapse.
                piece.Transparency = math.max(entry.transparency,
                    piece.Name:match("^PlatformPanel") and 0.80 or 0.60)
            else
                piece.Transparency = entry.transparency
            end
        end
    end
end

function D.start(ctx)
    local generatedMap = workspace:FindFirstChild("GeneratedMap")
    local arena = generatedMap and generatedMap:FindFirstChild("Arena")
    local folder = arena and arena:FindFirstChild("Platforms")
    if not folder then
        return
    end

    local decor = arena and arena:FindFirstChild("Decor")
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
            D.setCosmeticsPhase(state.cosmetics, nil)
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
                    cosmetics = D.cosmeticsForPlatform(decor, p),
                }

                D.setCosmeticsPhase(activeStates[p].cosmetics, "Warning")
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
                    D.setCosmeticsPhase(state.cosmetics, "Gone")

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
