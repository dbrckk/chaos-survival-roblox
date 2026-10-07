local StudioTestService = game:GetService("StudioTestService")

print("CHAOS_STUDIO_E2E_BEGIN")

local result = StudioTestService:ExecuteMultiplayerTestAsync(2, {
    suite = "ChaosE2E",
    initialPlayers = 2,
    addPlayers = 2,
    timeoutSeconds = 90,
})

print("CHAOS_STUDIO_E2E_RESULT", result)

if type(result) ~= "string" or string.sub(result, 1, 5) ~= "PASS:" then
    error("CHAOS_STUDIO_E2E_FAILED: " .. tostring(result))
end

print("CHAOS_STUDIO_E2E_OK")
