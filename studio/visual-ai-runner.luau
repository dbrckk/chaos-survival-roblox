-- Runs under the OFFICIAL authenticated Roblox Studio command-line interface.
-- It does not render headlessly or generate image files by itself.
-- A separate Windows desktop collector must capture the displayed 3D window.
local StudioTestService = game:GetService("StudioTestService")

print("CHAOS_VISUAL_AI_BEGIN")
local result = StudioTestService:ExecutePlayModeAsync({
    suite = "ChaosVisualAI",
    sampleCount = 15,
    intervalSeconds = 3,
    timeoutSeconds = 110,
})
print("CHAOS_VISUAL_AI_RESULT", result)

if type(result) ~= "string" or string.sub(result, 1, 5) ~= "PASS:" then
    error("CHAOS_VISUAL_AI_FAILED: " .. tostring(result))
end

print("CHAOS_VISUAL_AI_OK")
