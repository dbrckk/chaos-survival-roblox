local StudioTestService = game:GetService("StudioTestService")

local toolbar = plugin:CreateToolbar("Chaos Survival")
local button = toolbar:CreateButton(
    "Chaos E2E",
    "Run automated multiplayer Chaos Survival playtest",
    ""
)

local running = false

button.Click:Connect(function()
    if running then return end
    running = true
    button.Enabled = false

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
    end)
end)
