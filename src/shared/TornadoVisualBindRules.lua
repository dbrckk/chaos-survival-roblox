-- StreamingEnabled can replicate a RoundTornado model before some of its
-- parts. Do not commit client visuals from a partial model; reconnect as
-- direct children arrive, without a 2-second timeout or polling loop.
local TornadoVisualBindRules = {}

local REQUIRED = {"DangerZone", "LowerFunnel", "MiddleFunnel", "UpperFunnel"}

function TornadoVisualBindRules.read(model)
    if typeof(model) ~= "Instance" or not model:IsA("Model")
        or model.Name ~= "RoundTornado" then
        return nil
    end
    local found = {}
    for _, name in ipairs(REQUIRED) do
        local part = model:FindFirstChild(name)
        if not part or not part:IsA("BasePart") then
            return nil
        end
        found[name] = part
    end
    return found
end

return TornadoVisualBindRules
