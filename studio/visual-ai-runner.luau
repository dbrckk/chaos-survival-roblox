-- Runs under the OFFICIAL authenticated Roblox Studio command-line interface.
-- It does not render headlessly or generate image files by itself.
-- A separate Windows desktop collector must capture the displayed 3D window.
local StudioTestService = game:GetService("StudioTestService")

print("CHAOS_VISUAL_AI_BEGIN")
local scenario = {
    suite = "ChaosVisualAI",
    sampleCount = 15,
    intervalSeconds = 3,
    timeoutSeconds = 130,
    -- The trusted local Windows preparer replaces ONLY this field,
    -- without changing tests, player scripts or the public Roblox game.
    arenaVariant = "Harbor",
}
local result = StudioTestService:ExecutePlayModeAsync(scenario)
print("CHAOS_VISUAL_AI_RESULT", result)

-- A generic "PASS:" is not sufficient: prove this exact scenario, exact
-- requested arena, all 15 live frames and >=2 distinct autonomous bots.
-- The outer Windows collector independently hashes the actual 15 PNGs.
local arena, botCount
if type(result) == "string" then
    arena, botCount = result:match(
        "^PASS: visual AI: 15 real ([A-Za-z]+) round frames, (%d+) autonomous bots$"
    )
end
if arena ~= scenario.arenaVariant or not botCount
    or tonumber(botCount) < 2 then
    error("CHAOS_VISUAL_AI_FAILED: exact arena/camera suite validation failed: "
        .. tostring(result))
end

print("CHAOS_VISUAL_AI_OK")
