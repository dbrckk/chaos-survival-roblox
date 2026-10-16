local StudioTestService = game:GetService("StudioTestService")

local toolbar = plugin:CreateToolbar("Chaos Survival")
local button = toolbar:CreateButton(
    "Chaos E2E",
    "Run automated multiplayer Chaos Survival playtest",
    ""
)

local soloButton = toolbar:CreateButton(
    "Chaos Solo AI",
    "Run real one-player AI survivor movement and network ownership test",
    ""
)

local running = false

button.Click:Connect(function()
    if running then return end
    running = true
    button.Enabled = false
    soloButton.Enabled = false

    task.spawn(function()
        local ok, result = pcall(function()
            return StudioTestService:ExecuteMultiplayerTestAsync(2, {
                suite = "ChaosE2E",
                initialPlayers = 2,
                addPlayers = 2,
                timeoutSeconds = 55,
            })
        end)

        if ok then
            print("CHAOS_E2E_RESULT:", result)
        else
            warn("CHAOS_E2E_LAUNCH_FAILED:", result)
        end

        running = false
        button.Enabled = true
        soloButton.Enabled = true
    end)
end)

soloButton.Click:Connect(function()
    if running then return end
    running = true
    soloButton.Enabled = false
    button.Enabled = false

    task.spawn(function()
        local ok, result = pcall(function()
            return StudioTestService:ExecuteMultiplayerTestAsync(1, {
                suite = "ChaosSoloAI",
                timeoutSeconds = 45,
            })
        end)

        if ok then
            print("CHAOS_SOLO_AI_RESULT:", result)
            if type(result) ~= "string" or string.sub(result, 1, 5) ~= "PASS:" then
                warn("CHAOS_SOLO_AI_TEST_FAILED:", result)
            end
        else
            warn("CHAOS_SOLO_AI_LAUNCH_FAILED:", result)
        end

        running = false
        soloButton.Enabled = true
        button.Enabled = true
    end)
end)
