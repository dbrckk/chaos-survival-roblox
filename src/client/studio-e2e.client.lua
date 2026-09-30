local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StudioTestService = game:GetService("StudioTestService")

local player = Players.LocalPlayer
if not player then return end

local activeDeadline = os.clock() + 12
while ReplicatedStorage:GetAttribute("ChaosE2EActive") ~= true and os.clock() < activeDeadline do
    task.wait(0.1)
end
if ReplicatedStorage:GetAttribute("ChaosE2EActive") ~= true then
    return
end

local reportEvent = ReplicatedStorage:WaitForChild("ChaosE2EReport")
local failures = {}

local function check(condition, message)
    if not condition then
        table.insert(failures, message)
    end
end

local function insideViewport(guiObject)
    local camera = workspace.CurrentCamera
    if not camera then return false end

    local viewport = camera.ViewportSize
    local pos = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize

    return pos.X >= -1
        and pos.Y >= -1
        and pos.X + size.X <= viewport.X + 1
        and pos.Y + size.Y <= viewport.Y + 1
end

local function click(button)
    local virtualInput = UserInputService:CreateVirtualInput()
    if not virtualInput then
        table.insert(failures, "VirtualInput unavailable")
        return false
    end

    local center = button.AbsolutePosition + (button.AbsoluteSize * 0.5)
    virtualInput:SendMousePosition(center)
    virtualInput:SendMouseButton(center, Enum.UserInputType.MouseButton1, true, 0)
    task.wait(0.05)
    virtualInput:SendMouseButton(center, Enum.UserInputType.MouseButton1, false, 0)
    task.wait(0.15)
    return true
end

local playerGui = player:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("ChaosHUD", 10)
local juice = playerGui:WaitForChild("ChaosJuice", 10)
local spectator = playerGui:WaitForChild("ChaosSpectator", 10)

check(hud ~= nil, "ChaosHUD missing")
check(juice ~= nil, "ChaosJuice missing")
check(spectator ~= nil, "ChaosSpectator missing")

if hud then
    local top = hud:FindFirstChild("TopHUD", true)
    local stats = hud:FindFirstChild("StatsHUD", true)
    local xpTrack = hud:FindFirstChild("XPTrack", true)
    local questButton = hud:FindFirstChild("QuestButton", true)
    local cosmeticButton = hud:FindFirstChild("CosmeticsButton", true)
    local achievementButton = hud:FindFirstChild("AchievementButton", true)
    local questPanel = hud:FindFirstChild("QuestPanel", true)
    local cosmeticPanel = hud:FindFirstChild("CosmeticsPanel", true)
    local achievementPanel = hud:FindFirstChild("AchievementPanel", true)
    local votePanel = hud:FindFirstChild("VotePanel", true)

    check(top ~= nil and insideViewport(top), "top HUD outside viewport")
    check(stats ~= nil and insideViewport(stats), "stats HUD outside viewport")
    check(xpTrack ~= nil and insideViewport(xpTrack), "XP bar outside viewport")

    for _, button in ipairs({questButton, cosmeticButton, achievementButton}) do
        check(button ~= nil, "menu button missing")
        if button and button:IsA("GuiButton") then
            check(button.AbsoluteSize.X >= 44 and button.AbsoluteSize.Y >= 36, button.Name .. " tap target too small")
            check(insideViewport(button), button.Name .. " outside viewport")
        end
    end

    if questButton and questPanel and cosmeticPanel and achievementPanel then
        click(questButton)
        check(questPanel.Visible == true, "quest panel did not open")
        check(cosmeticPanel.Visible == false and achievementPanel.Visible == false, "panels overlap after quest open")
    end

    if cosmeticButton and questPanel and cosmeticPanel and achievementPanel then
        click(cosmeticButton)
        check(cosmeticPanel.Visible == true, "cosmetic panel did not open")
        check(questPanel.Visible == false and achievementPanel.Visible == false, "panels overlap after cosmetic open")
    end

    if achievementButton and questPanel and cosmeticPanel and achievementPanel then
        click(achievementButton)
        check(achievementPanel.Visible == true, "achievement panel did not open")
        check(questPanel.Visible == false and cosmeticPanel.Visible == false, "panels overlap after achievement open")
    end

    if votePanel then
        local voteDeadline = os.clock() + 12
        while not votePanel.Visible and os.clock() < voteDeadline do
            task.wait(0.1)
        end

        check(votePanel.Visible, "vote panel never became visible")
        if votePanel.Visible then
            local voteButtons = {}
            for _, child in ipairs(votePanel:GetChildren()) do
                if child:IsA("TextButton") then
                    table.insert(voteButtons, child)
                end
            end
            check(#voteButtons == 3, "expected three vote buttons")
            if voteButtons[1] then
                click(voteButtons[1])
            end
        end
    end
end

local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart", 6)
if rootPart then
    local before = rootPart.Position
    local virtualInput = UserInputService:CreateVirtualInput()
    if virtualInput then
        virtualInput:SendKey(true, Enum.KeyCode.W, false)
        task.wait(0.75)
        virtualInput:SendKey(false, Enum.KeyCode.W, false)
        task.wait(0.15)

        local moved = (rootPart.Position - before).Magnitude
        check(moved > 0.25, "character did not respond to keyboard movement")
    end
else
    check(false, "HumanoidRootPart missing")
end

reportEvent:FireServer({
    ok = #failures == 0,
    error = table.concat(failures, " | "),
    viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.zero,
})

player:GetAttributeChangedSignal("ChaosE2EShouldLeave"):Connect(function()
    if player:GetAttribute("ChaosE2EShouldLeave") == true then
        task.wait(0.25)
        if StudioTestService:CanLeaveTest() then
            StudioTestService:LeaveTest()
        end
    end
end)

if player:GetAttribute("ChaosE2EShouldLeave") == true and StudioTestService:CanLeaveTest() then
    StudioTestService:LeaveTest()
end
