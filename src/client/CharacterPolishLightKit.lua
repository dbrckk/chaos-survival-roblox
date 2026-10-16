--!strict
-- Client-owned avatar fill lights. Preserve the selected light's enabled
-- state across refreshes and never allocate one when the visual budget is 0.
local LightKit = {}
local NAME = "ChaosCharacterPolishLight"

local function preferredPart(model)
    for _, name in ipairs({"UpperTorso", "Torso", "HumanoidRootPart"}) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part end
    end
    return nil
end

local function existingLight(part)
    for _, child in ipairs(part:GetChildren()) do
        if child.Name == NAME and child:IsA("PointLight") then
            return child
        end
    end
    return nil
end

function LightKit.apply(model, brightness, accent, isLocal)
    if not model or not model:IsA("Model") then return nil end
    local wantsLight = type(brightness) == "number"
        and brightness > 0 and brightness < math.huge
        and typeof(accent) == "Color3"
    local target = wantsLight and preferredPart(model) or nil
    local chosen = target and existingLight(target) or nil
    local spare = nil

    -- Reuse the original PointLight when the preferred torso streams in.
    -- The previous implementation allocated a new light and left the old
    -- disabled on the root, multiplying resident GPU light instances.
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("PointLight") and child.Name == NAME
                    and child ~= chosen and not spare then
                    spare = child
                end
            end
        end
    end

    if target and not chosen then
        chosen = spare
        if chosen then
            chosen.Parent = target
        else
            chosen = Instance.new("PointLight")
            chosen.Name = NAME
            chosen.Brightness = 0
            chosen.Range = 7
            chosen.Shadows = false
            chosen.Enabled = false
            chosen.Parent = target
        end
    end

    -- Keep one dormant light during Low/ReduceMotion, for cheap recovery,
    -- but destroy any duplicate stale instances rather than accumulating
    -- them on repeatedly streamed/changed character rigs.
    local keeper = chosen or spare
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("PointLight") and child.Name == NAME
                    and child ~= keeper then
                    child.Enabled = false
                    child:Destroy()
                end
            end
        end
    end

    if not chosen then
        if keeper and keeper.Enabled then keeper.Enabled = false end
        return nil
    end
    local range = isLocal == true and 8 or 6
    if chosen.Color ~= accent then chosen.Color = accent end
    if chosen.Brightness ~= brightness then chosen.Brightness = brightness end
    if chosen.Range ~= range then chosen.Range = range end
    if not chosen.Enabled then chosen.Enabled = true end
    return chosen
end

return LightKit
