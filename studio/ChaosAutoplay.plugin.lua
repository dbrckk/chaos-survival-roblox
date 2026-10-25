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

local visualButton = toolbar:CreateButton(
    "Chaos Visual AI 15",
    "Watch autonomous AI survivors in Studio and validate 15 camera samples",
    ""
)

local running = false

local function setButtonsEnabled(enabled)
    button.Enabled = enabled
    soloButton.Enabled = enabled
    visualButton.Enabled = enabled
end

button.Click:Connect(function()
    if running then return end
    running = true
    setButtonsEnabled(false)

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
        setButtonsEnabled(true)
    end)
end)

soloButton.Click:Connect(function()
    if running then return end
    running = true
    setButtonsEnabled(false)

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
        setButtonsEnabled(true)
    end)
end)

-- The Studio test driver observes real AI movement, changes the camera
-- only inside the local test client and verifies 15 timed render samples.
-- Images themselves require an interactive desktop screenshot collector;
-- this toolbar test alone NEVER claims that external PNGs were saved.
visualButton.Click:Connect(function()
    if running then return end
    running = true
    setButtonsEnabled(false)

    task.spawn(function()
        local ok, result = pcall(function()
            return StudioTestService:ExecutePlayModeAsync({
                suite = "ChaosVisualAI",
                sampleCount = 15,
                intervalSeconds = 3,
                timeoutSeconds = 110,
            })
        end)
        if ok then
            print("CHAOS_VISUAL_AI_RESULT:", result)
            if type(result) ~= "string" or string.sub(result, 1, 5) ~= "PASS:" then
                warn("CHAOS_VISUAL_AI_FAILED:", result)
            end
        else
            warn("CHAOS_VISUAL_AI_LAUNCH_FAILED:", result)
        end

        running = false
        setButtonsEnabled(true)
    end)
end)
