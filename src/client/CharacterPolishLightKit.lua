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
    if target and not chosen then
        chosen = Instance.new("PointLight")
        chosen.Name = NAME
        chosen.Brightness = 0
        chosen.Range = 7
        chosen.Shadows = false
        chosen.Enabled = false
        chosen.Parent = target
    end

    -- Switch off stale lights after streaming or torso priority changes.
    -- A currently selected, already-enabled light is never toggled off/on.
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("PointLight") and child.Name == NAME
                    and child ~= chosen and child.Enabled then
                    child.Enabled = false
                end
            end
        end
    end

    if not chosen then return nil end
    local range = isLocal == true and 8 or 6
    if chosen.Color ~= accent then chosen.Color = accent end
    if chosen.Brightness ~= brightness then chosen.Brightness = brightness end
    if chosen.Range ~= range then chosen.Range = range end
    if not chosen.Enabled then chosen.Enabled = true end
    return chosen
end

return LightKit
