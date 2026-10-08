local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StudioTestService = game:GetService("StudioTestService")
local Lighting = game:GetService("Lighting")

local VisualBudgetRules = require(ReplicatedStorage.Shared.VisualBudgetRules)
local RoundJourneyRules = require(ReplicatedStorage.Shared.RoundJourneyRules)

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
local roundJourneyStage = 0
local observedJourneys = {}
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
local arenaProbed = {}
local showtimeProbed = {}
local arenaEntryProbed = {}
local arenaEntryPending = {}

local function sendVisualPhaseProbe(phase)
    if phase ~= "ready" and phase ~= "round" and phase ~= "result" then
        return
    end

    task.delay(0.35, function()
        if not player.Parent then
            return
        end

        local root = workspace:FindFirstChild("GeneratedMap")
        local arena = root and root:FindFirstChild("Arena")
        local arenaId = arena and tostring(arena:GetAttribute("VariantId") or "") or ""
        local probeKey = phase .. "|" .. arenaId

        if arenaId == "" or visualPhaseProbed[probeKey] then
            return
        end
        visualPhaseProbed[probeKey] = true

        local metrics, folders = VisualBudgetRules.collect(workspace)
        local tierName = tostring(player:GetAttribute("VfxQualityTier") or "High")
        local camera = workspace.CurrentCamera
        local depth = Lighting:FindFirstChild("ArenaIdentityDepth")
        local sunRays = Lighting:FindFirstChild("ArenaIdentitySunRays")

        reportEvent:FireServer({
            kind = "visual_phase_probe",
            phase = phase,
            arenaId = arenaId,
            vfxTier = tierName,
            fieldOfView = camera and camera.FieldOfView or 0,
            auditedFolders = folders,
            visualMetrics = metrics,
            withinBudget = VisualBudgetRules.withinBudget(tierName, metrics),
            postProcess = {
                depthNearIntensity = depth and depth:IsA("DepthOfFieldEffect")
                    and depth.NearIntensity or -1,
                depthFarIntensity = depth and depth:IsA("DepthOfFieldEffect")
                    and depth.FarIntensity or -1,
                sunRaysEnabled = sunRays and sunRays:IsA("SunRaysEffect")
                    and sunRays.Enabled or false,
                sunRaysIntensity = sunRays and sunRays:IsA("SunRaysEffect")
                    and sunRays.Intensity or -1,
            },
        })
    end)
end

local function sendShowtimePhaseProbe(phase)
    if phase ~= "round" and phase ~= "result" then
        return
    end
    if showtimeProbed[phase] then
        return
    end
    showtimeProbed[phase] = true

    task.delay(0.55, function()
        if not player.Parent then
            return
        end
        local root = workspace:FindFirstChild("LobbyShowtimeLocal")
        local deck = root and root:FindFirstChild("ShowtimeDeck")
        local assets = root and root:FindFirstChild("Showtime3DAssets")
        local expected = phase == "result"
        local parts = 0
        local visible = 0
        local safe = true
        if assets then
            for _, item in ipairs(assets:GetDescendants()) do
                if item:IsA("BasePart") then
                    parts += 1
                    if item.Transparency < 0.98 then
                        visible += 1
                    end
                    if not item.Anchored or item.CanCollide
                        or item.CanTouch or item.CanQuery
                    then
                        safe = false
                    end
                end
            end
        end

        local deckVisible = deck and deck:IsA("BasePart")
            and deck.Transparency < 0.98
        local hero = assets and assets:FindFirstChild("ShowtimeCrownHeart")
        local dj = assets and assets:FindFirstChild("ShowtimeDJBooth")
        local okay = root ~= nil and deck ~= nil
            and assets ~= nil and hero ~= nil and dj ~= nil
            and parts >= 12 and safe
            and deckVisible == expected
            and ((expected and visible > 0)
                or (not expected and visible == 0))

        reportEvent:FireServer({
            kind = "showtime_phase_probe",
            phase = phase,
            ok = okay,
            propParts = parts,
            visibleProps = visible,
            error = okay and "" or string.format(
                "phase=%s deck=%s props=%d visible=%d crown=%s dj=%s safe=%s",
                phase, tostring(deckVisible), parts, visible,
                tostring(hero ~= nil), tostring(dj ~= nil), tostring(safe)
            ),
        })
    end)
end

local function sendArenaProbe(state)
    if type(state) ~= "table" or tostring(state.phase or "") ~= "result" then
        return
    end

    local arenaId = tostring(state.arenaId or "")
    if arenaId == "" or arenaProbed[arenaId] then
        return
    end
    arenaProbed[arenaId] = true

    local root = workspace:FindFirstChild("GeneratedMap")
    local arena = root and root:FindFirstChild("Arena")
    local worldArenaId = arena and tostring(arena:GetAttribute("VariantId") or "") or ""
    local matchesWorld = worldArenaId == arenaId
    local expectedHero = ({
        Classic = "ClassicRadarSweep",
        Towers = "TowerAnimatedLift",
        Crossroads = "CrossroadAnimatedSignal1",
        Orbital = "OrbitalGyroscopeHeart",
    })[arenaId]
    local signatureRoot = workspace:FindFirstChild("ArenaSignatureLocal")
    local signatureSet = signatureRoot and signatureRoot:FindFirstChild("ArenaSignatureSet")
    local signatureHero = signatureSet and expectedHero
        and signatureSet:FindFirstChild(expectedHero)
    local signatureParts = 0
    local safeParts = true
    if signatureSet then
        for _, child in ipairs(signatureSet:GetDescendants()) do
            if child:IsA("BasePart") then
                signatureParts += 1
                if not child.Anchored or child.CanCollide
                    or child.CanTouch or child.CanQuery
                then
                    safeParts = false
                end
            end
        end
    end
    local signatureReady = signatureHero ~= nil
        and signatureHero:IsA("BasePart")
        and signatureParts >= 6 and signatureParts <= 50
        and safeParts

    reportEvent:FireServer({
        kind = "arena_probe",
        arenaId = arenaId,
        worldArenaId = worldArenaId,
        ok = matchesWorld and signatureReady,
        signatureReady = signatureReady,
        signatureHero = expectedHero or "Unknown",
        signatureParts = signatureParts,
        error = matchesWorld and signatureReady
            and ""
            or string.format(
                "arena=%s world=%s hero=%s exists=%s parts=%d safe=%s",
                arenaId, worldArenaId, tostring(expectedHero),
                tostring(signatureHero ~= nil), signatureParts, tostring(safeParts)
            ),
    })
end

local function sendArenaEntryProbe(state)
    if type(state) ~= "table" or tostring(state.phase or "") ~= "ready" then
        return
    end

    local expectedArenaId = tostring(state.arenaId or "")
    if expectedArenaId == ""
        or arenaEntryProbed[expectedArenaId]
        or arenaEntryPending[expectedArenaId]
    then
        return
    end

    arenaEntryPending[expectedArenaId] = true

    task.spawn(function()
        local deadline = os.clock() + 1.25
        local finalReport = nil

        while player.Parent and os.clock() < deadline do
            local generated = workspace:FindFirstChild("GeneratedMap")
            local arena = generated and generated:FindFirstChild("Arena")
            local worldArenaId = arena and tostring(arena:GetAttribute("VariantId") or "") or ""

            local base = arena and arena:FindFirstChild("Base")
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local humanoidRoot = character and character:FindFirstChild("HumanoidRootPart")
            local characterReady = humanoid ~= nil
                and humanoid.Health > 0
                and humanoidRoot ~= nil
            local insideFootprint = false
            local offsetX = 0
            local offsetZ = 0
            local limitX = 0
            local limitZ = 0

            if base and base:IsA("BasePart")
                and humanoidRoot and humanoidRoot:IsA("BasePart")
            then
                local localPosition = base.CFrame:PointToObjectSpace(humanoidRoot.Position)
                offsetX = localPosition.X
                offsetZ = localPosition.Z
                limitX = base.Size.X * 0.5 + 10
                limitZ = base.Size.Z * 0.5 + 10
                insideFootprint = math.abs(offsetX) <= limitX
                    and math.abs(offsetZ) <= limitZ
            end

            local arenaMatches = worldArenaId == expectedArenaId
            local ok = characterReady
                and base ~= nil
                and insideFootprint
                and arenaMatches

            finalReport = {
                kind = "arena_entry_probe",
                arenaId = expectedArenaId,
                worldArenaId = worldArenaId,
                ok = ok,
                characterReady = characterReady,
                insideFootprint = insideFootprint,
                arenaMatches = arenaMatches,
                offsetX = offsetX,
                offsetZ = offsetZ,
                limitX = limitX,
                limitZ = limitZ,
                error = ok and "" or string.format(
                    "characterReady=%s inside=%s expected=%s world=%s offset=(%.1f,%.1f) limit=(%.1f,%.1f)",
                    tostring(characterReady),
                    tostring(insideFootprint),
                    expectedArenaId,
                    worldArenaId,
                    offsetX,
                    offsetZ,
                    limitX,
                    limitZ
                ),
            }

            if ok then
                break
            end

            task.wait(0.10)
        end

        arenaEntryPending[expectedArenaId] = nil

        if arenaEntryProbed[expectedArenaId] or not finalReport then
            return
        end

        arenaEntryProbed[expectedArenaId] = true
        reportEvent:FireServer(finalReport)
    end)
end
if roundStateEvent and roundStateEvent:IsA("RemoteEvent") then
    roundStateEvent.OnClientEvent:Connect(function(state)
        if type(state) == "table" then
            roundStateReceived = true
            lastRoundPhase = state.phase
            local stage, completed = RoundJourneyRules.advance(
                roundJourneyStage, state.phase
            )
            roundJourneyStage = stage
            if completed then
                local arenaId = tostring(state.arenaId or "")
                if arenaId ~= "" and not observedJourneys[arenaId] then
                    observedJourneys[arenaId] = true
                    reportEvent:FireServer({
                        kind = "round_journey_probe",
                        arenaId = arenaId,
                        completedStages = stage,
                        phases = {"intermission", "ready", "round", "result"},
                    })
                end
            end
            sendVisualPhaseProbe(tostring(state.phase or ""))
            sendShowtimePhaseProbe(tostring(state.phase or ""))
            sendArenaProbe(state)
            sendArenaEntryProbe(state)
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
local showtimeGui = playerGui:WaitForChild("ChaosShowtime", 10)

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

check(showtimeGui ~= nil, "ChaosShowtime emote interface missing")
if showtimeGui then
    for _, controlName in ipairs({
        "ShowtimeToggle",
        "Emote_dance",
        "Emote_shuffle",
        "Emote_groove",
        "Emote_cheer",
        "Emote_wave",
        "Emote_laugh",
    }) do
        local control = showtimeGui:FindFirstChild(controlName, true)
        check(control ~= nil, controlName .. " missing")
        if control and control:IsA("GuiObject") then
            check(
                control.Size.Y.Offset >= 44,
                controlName .. " touch target too small"
            )
        end
    end
end

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
    local metaDock = hud:FindFirstChild("MetaDock", true)
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
            if metaDock and metaDock:IsA("GuiObject") then
                check(metaDock.Visible == false, "meta dock visible during active vote")
            end

            local inviteButton = inviteGui and inviteGui:FindFirstChild("InviteFriendsButton", true)
            if inviteButton and inviteButton:IsA("GuiObject") then
                check(inviteButton.Visible == false, "invite CTA visible during active vote")
            end

            local shareButton = shareGui and shareGui:FindFirstChild("ShareMomentButton", true)
            if shareButton and shareButton:IsA("GuiObject") then
                check(shareButton.Visible == false, "share CTA visible during active vote")
            end

            local reactionDock = reactionsGui and reactionsGui:FindFirstChild("ResultReactionDock", true)
            if reactionDock and reactionDock:IsA("GuiObject") then
                check(reactionDock.Visible == false, "reaction dock visible during active vote")
            end

            local voteButtons = {}
            for _, child in ipairs(votePanel:GetChildren()) do
                if child:IsA("TextButton") then
                    table.insert(voteButtons, child)
                end
            end
            check(#voteButtons == 3, "expected three vote buttons")

            for _, voteButton in ipairs(voteButtons) do
                check(insideViewport(voteButton), voteButton.Name .. " outside viewport")
                if UserInputService.TouchEnabled then
                    check(
                        voteButton.AbsoluteSize.X >= 44 and voteButton.AbsoluteSize.Y >= 44,
                        voteButton.Name .. " tap target too small"
                    )
                end

                local hazardName = voteButton:FindFirstChild("VoteHazardName", true)
                local hazardHint = voteButton:FindFirstChild("VoteHazardHint", true)

                check(hazardName ~= nil, voteButton.Name .. " hazard name missing")
                check(hazardHint ~= nil, voteButton.Name .. " hazard hint missing")

                if hazardName and hazardName:IsA("TextLabel") then
                    check(hazardName.Text ~= "", voteButton.Name .. " hazard name empty")
                end
                if hazardHint and hazardHint:IsA("TextLabel") then
                    check(#hazardHint.Text >= 3, voteButton.Name .. " hazard guidance too short")
                end
            end

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

    for _, legacyName in ipairs({
        "ChaosColor",
        "ChaosAtmosphere",
        "ChaosBloom",
        "ChaosRays",
    }) do
        check(
            Lighting:FindFirstChild(legacyName) == nil,
            legacyName .. " legacy post-process should not exist"
        )
    end

    for _, className in ipairs({
        "Atmosphere",
        "BloomEffect",
        "DepthOfFieldEffect",
        "SunRaysEffect",
    }) do
        local total = 0
        for _, child in ipairs(Lighting:GetChildren()) do
            if child.ClassName == className then
                total += 1
            end
        end
        check(
            total == 1,
            string.format("%s expected exactly once in Lighting, found %d", className, total)
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
