local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StudioTestService = game:GetService("StudioTestService")

local VisualBudgetRules = require(ReplicatedStorage.Shared.VisualBudgetRules)

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
local roundStateReceived = false
local lastRoundPhase = nil
local visualMetrics = {
    Parts = 0,
    Lights = 0,
    Effects = 0,
}
local auditedFolders = 0
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local roundStateEvent = remotes and remotes:FindFirstChild("RoundState")
local visualPhaseProbed = {}

local function sendVisualPhaseProbe(phase)
    if phase ~= "ready" and phase ~= "round" and phase ~= "result" then
        return
    end
    if visualPhaseProbed[phase] then
        return
    end
    visualPhaseProbed[phase] = true

    task.delay(0.35, function()
        if not player.Parent then
            return
        end

        local metrics, folders = VisualBudgetRules.collect(workspace)
        local tierName = tostring(player:GetAttribute("VfxQualityTier") or "High")
        local camera = workspace.CurrentCamera

        reportEvent:FireServer({
            kind = "visual_phase_probe",
            phase = phase,
            vfxTier = tierName,
            fieldOfView = camera and camera.FieldOfView or 0,
            auditedFolders = folders,
            visualMetrics = metrics,
            withinBudget = VisualBudgetRules.withinBudget(tierName, metrics),
        })
    end)
end

if roundStateEvent and roundStateEvent:IsA("RemoteEvent") then
    roundStateEvent.OnClientEvent:Connect(function(state)
        if type(state) == "table" then
            roundStateReceived = true
            lastRoundPhase = state.phase
            sendVisualPhaseProbe(tostring(state.phase or ""))
        end
    end)
else
    table.insert(failures, "RoundState RemoteEvent missing")
end


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

local function rectsOverlap(a, b)
    if not a or not b then
        return false
    end

    local aPos = a.AbsolutePosition
    local aSize = a.AbsoluteSize
    local bPos = b.AbsolutePosition
    local bSize = b.AbsoluteSize

    return aPos.X < bPos.X + bSize.X
        and aPos.X + aSize.X > bPos.X
        and aPos.Y < bPos.Y + bSize.Y
        and aPos.Y + aSize.Y > bPos.Y
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
local accessibilityGui = playerGui:WaitForChild("AccessibilityQuickSettings", 10)
local roundFocusGui = playerGui:WaitForChild("ChaosRoundFocus", 10)
local roundEventsGui = playerGui:WaitForChild("ChaosRoundEvents", 10)
local hazardGui = playerGui:WaitForChild("HazardReadabilityCue", 10)
local shrinkGui = playerGui:WaitForChild("ShrinkPressure", 10)
local inviteGui = playerGui:WaitForChild("ChaosSocialInvite", 10)
local shareGui = playerGui:WaitForChild("ChaosMomentShare", 10)
local reactionsGui = playerGui:WaitForChild("ChaosSocialReactions", 10)

check(hud ~= nil, "ChaosHUD missing")
check(juice ~= nil, "ChaosJuice missing")
check(spectator ~= nil, "ChaosSpectator missing")
check(accessibilityGui ~= nil, "AccessibilityQuickSettings missing")
if accessibilityGui then
    for _, controlName in ipairs({
        "ReduceMotionToggle",
        "AudioToggle",
        "HapticsToggle",
    }) do
        local control = accessibilityGui:FindFirstChild(controlName, true)
        check(control ~= nil, controlName .. " missing")
        if control and control:IsA("GuiObject") then
            local minimumHeight = UserInputService.TouchEnabled and 44 or 34
            check(
                control.AbsoluteSize.X >= 44
                    and control.AbsoluteSize.Y >= minimumHeight,
                controlName .. " tap target too small"
            )
            check(insideViewport(control), controlName .. " outside viewport")
        end
    end
end
if spectator then
    local spectatorNext = spectator:FindFirstChild("NextSpectator", true)
    check(spectatorNext ~= nil, "spectator NEXT control missing")
    if spectatorNext and spectatorNext:IsA("GuiObject") then
        check(
            spectatorNext.AbsoluteSize.X >= 44 and spectatorNext.AbsoluteSize.Y >= 44,
            "spectator NEXT tap target too small"
        )
        check(insideViewport(spectatorNext), "spectator NEXT outside viewport")
    end
end
check(roundFocusGui ~= nil, "ChaosRoundFocus missing")
check(roundEventsGui ~= nil, "ChaosRoundEvents missing")
check(hazardGui ~= nil, "HazardReadabilityCue missing")
check(shrinkGui ~= nil, "ShrinkPressure missing")
check(inviteGui ~= nil, "ChaosSocialInvite missing")
check(shareGui ~= nil, "ChaosMomentShare missing")
check(reactionsGui ~= nil, "ChaosSocialReactions missing")

do
    local minHeight = UserInputService.TouchEnabled and 44 or 36
    local socialButtons = {
        inviteGui and inviteGui:FindFirstChild("InviteFriendsButton", true),
        shareGui and shareGui:FindFirstChild("ShareMomentButton", true),
    }

    for _, socialButton in ipairs(socialButtons) do
        check(socialButton ~= nil, "social CTA missing")
        if socialButton and socialButton:IsA("GuiButton") then
            check(
                socialButton.AbsoluteSize.X >= 44
                    and socialButton.AbsoluteSize.Y >= minHeight,
                socialButton.Name .. " tap target too small"
            )
            check(insideViewport(socialButton), socialButton.Name .. " outside viewport")
        end
    end

    if reactionsGui then
        for _, reactionId in ipairs({"gg", "again", "wow"}) do
            local reaction = reactionsGui:FindFirstChild("Reaction_" .. reactionId, true)
            check(reaction ~= nil, "reaction button missing: " .. reactionId)
            if reaction and reaction:IsA("GuiButton") then
                check(
                    reaction.AbsoluteSize.X >= 44
                        and reaction.AbsoluteSize.Y >= minHeight,
                    reaction.Name .. " tap target too small"
                )
            end
        end
    end
end

if roundStateEvent and roundStateEvent:IsA("RemoteEvent") then
    roundStateEvent.OnClientEvent:Connect(function(state)
        if type(state) ~= "table" or tostring(state.phase or "") ~= "result" then
            return
        end

        task.spawn(function()
            local deadline = os.clock() + 2.0
            local resultCard = nil
            local title = nil
            local reward = nil
            local tip = nil
            local nextRound = nil

            repeat
                if hud and hud.Parent then
                    resultCard = hud:FindFirstChild("ResultCard", true)
                    title = resultCard and resultCard:FindFirstChild("ResultTitle", true)
                    reward = resultCard and resultCard:FindFirstChild("ResultReward", true)
                    tip = resultCard and resultCard:FindFirstChild("ResultTip", true)
                    nextRound = resultCard and resultCard:FindFirstChild("NextRoundCountdown", true)
                end

                local complete = resultCard
                    and resultCard:IsA("GuiObject")
                    and resultCard.Visible
                    and title and title:IsA("TextLabel") and title.Text ~= ""
                    and reward and reward:IsA("TextLabel") and reward.Text ~= ""
                    and tip and tip:IsA("TextLabel") and tip.Text ~= ""
                    and nextRound and nextRound:IsA("TextLabel") and nextRound.Text ~= ""

                if complete then
                    break
                end
                task.wait(0.10)
            until os.clock() >= deadline

            local issues = {}
            local function uxCheck(condition, message)
                if not condition then
                    table.insert(issues, message)
                end
            end

            uxCheck(resultCard ~= nil, "RESULT card missing")
            if resultCard and resultCard:IsA("GuiObject") then
                uxCheck(resultCard.Visible == true, "RESULT card not visible")
                uxCheck(insideViewport(resultCard), "RESULT card outside viewport")
            end

            for _, item in ipairs({
                {label = title, name = "ResultTitle"},
                {label = reward, name = "ResultReward"},
                {label = tip, name = "ResultTip"},
                {label = nextRound, name = "NextRoundCountdown"},
            }) do
                uxCheck(item.label ~= nil, item.name .. " missing")
                if item.label and item.label:IsA("TextLabel") then
                    uxCheck(item.label.Text ~= "", item.name .. " is empty during RESULT")
                end
            end

            reportEvent:FireServer({
                kind = "ux_phase_probe",
                phase = "result",
                ok = #issues == 0,
                error = table.concat(issues, " | "),
            })
        end)
    end)
end

if roundStateEvent and roundStateEvent:IsA("RemoteEvent") then
    roundStateEvent.OnClientEvent:Connect(function(state)
        if type(state) ~= "table" or tostring(state.phase or "") ~= "ready" then
            return
        end

        task.delay(0.25, function()
            local issues = {}
            local function uxCheck(condition, message)
                if not condition then
                    table.insert(issues, message)
                end
            end

            local countdown = hud and hud:FindFirstChild("RoundCountdown", true)
            local kicker = countdown and countdown:FindFirstChild("CountdownKicker", true)
            local main = countdown and countdown:FindFirstChild("CountdownMain", true)
            local guidance = countdown and countdown:FindFirstChild("CountdownGuidance", true)

            uxCheck(countdown ~= nil, "READY countdown card missing")
            if countdown and countdown:IsA("GuiObject") then
                uxCheck(countdown.Visible == true, "READY countdown card not visible")
                uxCheck(insideViewport(countdown), "READY countdown outside viewport")
            end

            for _, label in ipairs({kicker, main, guidance}) do
                uxCheck(label ~= nil, "READY countdown text field missing")
                if label and label:IsA("TextLabel") then
                    uxCheck(label.Text ~= "", label.Name .. " is empty during READY")
                    uxCheck(
                        label.AbsoluteSize.X > 0 and label.AbsoluteSize.Y > 0,
                        label.Name .. " has invalid size"
                    )
                end
            end

            if guidance and guidance:IsA("TextLabel") then
                uxCheck(#guidance.Text >= 3, "READY guidance is too short to be actionable")
            end

            reportEvent:FireServer({
                kind = "ux_phase_probe",
                phase = "ready",
                ok = #issues == 0,
                error = table.concat(issues, " | "),
            })
        end)
    end)
end

if hud then
    local top = hud:FindFirstChild("TopHUD", true)
    local stats = hud:FindFirstChild("StatsHUD", true)
    local xpTrack = hud:FindFirstChild("XPTrack", true)
    local questButton = hud:FindFirstChild("QuestButton", true)
    local cosmeticButton = hud:FindFirstChild("CosmeticsButton", true)
    local achievementButton = hud:FindFirstChild("AchievementButton", true)
    local supportButton = hud:FindFirstChild("SupportButton", true)
    local questPanel = hud:FindFirstChild("QuestPanel", true)
    local cosmeticPanel = hud:FindFirstChild("CosmeticsPanel", true)
    local achievementPanel = hud:FindFirstChild("AchievementPanel", true)
    local votePanel = hud:FindFirstChild("VotePanel", true)
    local rookieCoach = hud:FindFirstChild("RookieCoach", true)

    check(top ~= nil and insideViewport(top), "top HUD outside viewport")
    check(rookieCoach ~= nil, "rookie coach missing")
    if rookieCoach and rookieCoach:IsA("TextLabel") and rookieCoach.Visible then
        check(rookieCoach.Text ~= "", "rookie coach visible without guidance")
        check(insideViewport(rookieCoach), "rookie coach outside viewport")
    end
    check(stats ~= nil and insideViewport(stats), "stats HUD outside viewport")
    check(xpTrack ~= nil and insideViewport(xpTrack), "XP bar outside viewport")

    local minTouchHeight = UserInputService.TouchEnabled and 44 or 36
    for _, button in ipairs({questButton, cosmeticButton, achievementButton}) do
        check(button ~= nil, "menu button missing")
        if button and button:IsA("GuiButton") then
            check(
                button.AbsoluteSize.X >= 44 and button.AbsoluteSize.Y >= minTouchHeight,
                button.Name .. " tap target too small"
            )
            check(insideViewport(button), button.Name .. " outside viewport")
        end
    end

    if supportButton and supportButton:IsA("GuiButton") and supportButton.Visible then
        check(
            supportButton.AbsoluteSize.X >= 44
                and supportButton.AbsoluteSize.Y >= minTouchHeight,
            "SupportButton tap target too small"
        )
        check(insideViewport(supportButton), "SupportButton outside viewport")
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

do
    task.wait(0.10)

    local focusBar = roundFocusGui and roundFocusGui:FindFirstChild("FocusBar", true)
    local eventCard = roundEventsGui and roundEventsGui:FindFirstChild("EventCard", true)
    local hazardCue = hazardGui and hazardGui:FindFirstChild("NearestHazardCue", true)
    local centerCue = shrinkGui and shrinkGui:FindFirstChild("CenterEscapeCue", true)

    check(focusBar ~= nil, "round focus bar missing")
    check(eventCard ~= nil, "round event card missing")
    check(hazardCue ~= nil, "hazard readability cue missing")
    check(centerCue ~= nil, "shrink center cue missing")

    for _, item in ipairs({
        focusBar,
        eventCard,
        hazardCue,
        centerCue,
    }) do
        if item and item:IsA("GuiObject") then
            check(
                item.AbsoluteSize.X > 0 and item.AbsoluteSize.Y > 0,
                item.Name .. " has invalid size"
            )
            check(insideViewport(item), item.Name .. " outside viewport")
        end
    end

    if hazardCue and centerCue
        and hazardCue:IsA("GuiObject")
        and centerCue:IsA("GuiObject")
    then
        check(
            not rectsOverlap(hazardCue, centerCue),
            "hazard and shrink escape cues overlap"
        )
    end
end

do
    local camera = workspace.CurrentCamera
    check(camera ~= nil, "CurrentCamera missing")
    if camera then
        check(
            camera.FieldOfView >= 60 and camera.FieldOfView <= 90,
            "camera FOV outside safe presentation bounds"
        )
    end

    local cloudCount = 0
    for _, child in ipairs(workspace.Terrain:GetChildren()) do
        if child:IsA("Clouds") then
            cloudCount += 1
        end
    end
    check(cloudCount == 1, "expected exactly one Clouds instance")

    local Lighting = game:GetService("Lighting")
    local expectedLightingEffects = {
        ArenaIdentityColor = "ColorCorrectionEffect",
        ArenaIdentityAtmosphere = "Atmosphere",
        ArenaIdentityBloom = "BloomEffect",
        ArenaIdentityDepth = "DepthOfFieldEffect",
        ArenaIdentitySunRays = "SunRaysEffect",
    }

    for effectName, className in pairs(expectedLightingEffects) do
        local count = 0
        for _, child in ipairs(Lighting:GetChildren()) do
            if child.Name == effectName and child.ClassName == className then
                count += 1
            end
        end
        check(
            count == 1,
            string.format("%s expected exactly once, found %d", effectName, count)
        )
    end

    visualMetrics, auditedFolders = VisualBudgetRules.collect(workspace)

    for _, folderName in ipairs(VisualBudgetRules.LocalFolders) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, descendant in ipairs(folder:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    check(not descendant.CanCollide, folderName .. ": decorative part can collide")
                    check(not descendant.CanTouch, folderName .. ": decorative part can touch")
                    check(not descendant.CanQuery, folderName .. ": decorative part can query")
                end
            end
        end
    end

    check(auditedFolders >= 4, "visual decorator folders did not initialize")

    local tierName = tostring(player:GetAttribute("VfxQualityTier") or "High")
    check(
        VisualBudgetRules.withinBudget(tierName, visualMetrics),
        string.format(
            "visual budget exceeded for %s: parts=%d lights=%d effects=%d",
            tierName,
            visualMetrics.Parts,
            visualMetrics.Lights,
            visualMetrics.Effects
        )
    )
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

local roundStateDeadline = os.clock() + 5
while not roundStateReceived and os.clock() < roundStateDeadline do
    task.wait(0.1)
end
check(roundStateReceived, "no RoundState snapshot received after client bootstrap")

reportEvent:FireServer({
    ok = #failures == 0,
    error = table.concat(failures, " | "),
    viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.zero,
    roundStateReceived = roundStateReceived,
    roundPhase = lastRoundPhase,
    roundParticipant = player:GetAttribute("RoundParticipant") == true,
    roundEliminated = player:GetAttribute("RoundEliminated") == true,
    vfxTier = tostring(player:GetAttribute("VfxQualityTier") or "Unknown"),
    fieldOfView = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 0,
    visualMetrics = visualMetrics,
})

local function runSpectatorProbe()
    local spectatorCard = spectator and spectator:FindFirstChildWhichIsA("Frame", true)
    local deadline = os.clock() + 4

    while spectatorCard and not spectatorCard.Visible and os.clock() < deadline do
        task.wait(0.1)
    end

    reportEvent:FireServer({
        kind = "spectator_probe",
        ok = spectatorCard ~= nil and spectatorCard.Visible == true,
        error = spectatorCard and "" or "spectator card missing",
        spectatorVisible = spectatorCard ~= nil and spectatorCard.Visible == true,
    })
end

player:GetAttributeChangedSignal("ChaosE2ESpectatorProbe"):Connect(function()
    if player:GetAttribute("ChaosE2ESpectatorProbe") == true then
        task.spawn(runSpectatorProbe)
    end
end)

if player:GetAttribute("ChaosE2ESpectatorProbe") == true then
    task.spawn(runSpectatorProbe)
end

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
