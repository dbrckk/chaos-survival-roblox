-- P3 PERSONAL MASTERY / TOWERS + ORBITAL + HARBOR
-- One event-driven status chip for genuine server-owned movement charges.
-- No per-frame scan, RemoteEvent, clickable input, collision or rendering
-- of nonexistent world paths. Critical mobile hazard notices win.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local MobileHudNotices = require(ReplicatedStorage.Shared.MobileHudNotices)

local player = Players.LocalPlayer
local french = string.sub(
    string.lower(LocalizationService.RobloxLocaleId), 1, 2) == "fr"
local touch = UserInputService.TouchEnabled
local activeRound = false
local trackerFits = true
local deadlineScheduled = 0
local boundMap = nil
local mapConnections = {}

local gui = Instance.new("ScreenGui")
gui.Name = "ArenaMasteryStatus"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 34
gui.Parent = player:WaitForChild("PlayerGui")

local chip = Instance.new("TextLabel")
chip.Name = "PersonalMovementCharge"
chip.AnchorPoint = Vector2.new(0.5, 0)
chip.Position = UDim2.fromScale(0.5, 0.125)
chip.Size = UDim2.fromOffset(245, 32)
chip.BackgroundColor3 = Color3.fromRGB(16, 27, 43)
chip.BackgroundTransparency = 0.14
chip.BorderSizePixel = 0
chip.Font = Enum.Font.GothamBold
chip.TextColor3 = Color3.fromRGB(187, 244, 234)
chip.TextScaled = true
chip.Visible = false
chip.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = chip

local outline = Instance.new("UIStroke")
outline.Thickness = 1
outline.Color = Color3.fromRGB(88, 201, 195)
outline.Transparency = 0.28
outline.Parent = chip

local function variant()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    return arena and arena:GetAttribute("VariantId")
end

local function layout()
    if not touch then
        chip.Position = UDim2.fromScale(0.5, 0.125)
        chip.Size = UDim2.fromOffset(245, 32)
        trackerFits = true
    else
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize
            or Vector2.new(1280, 720)
        local inset = GuiService:GetGuiInset()
        local size = UIResponsive.mobileMechanicTracker(viewport, inset.Y)
        chip.Position = UDim2.new(size.centerXScale, 0, 0, size.topOffset)
        chip.Size = UDim2.fromOffset(size.width, size.height)
        trackerFits = size.fits
    end
end

local refresh
refresh = function()
    local eligible = activeRound
        and player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true
    if not eligible then
        chip.Visible = false
        return
    end

    local id = variant()
    local textValue = nil
    local color = Color3.fromRGB(187, 244, 234)

    if id == "Towers"
        and player:GetAttribute("RoundSkyrailAceBoostReady") == true
    then
        textValue = french and "AS SKYRAIL • ÉLAN PRÊT"
            or "SKYRAIL ACE • SURGE READY"
        color = Color3.fromRGB(131, 229, 255)
    elseif id == "Orbital"
        and player:GetAttribute("RoundHelixMasterPulseReady") == true
    then
        textValue = french and "ORBITE • RAMPE CHARGÉE"
            or "ORBIT MASTER • CHARGED RAMP"
        color = Color3.fromRGB(149, 251, 204)
    elseif id == "Harbor" then
        if player:GetAttribute("RoundHarborTransferReady") == true then
            textValue = french and "PORT • BOOST DU PROCHAIN PAD"
                or "HARBOR • NEXT PAD BOOST"
            color = Color3.fromRGB(113, 229, 241)
        elseif (tonumber(player:GetAttribute("RoundHarborTransferStep")) or 0)
            == 1 then
            local deadline = tonumber(
                player:GetAttribute("RoundHarborTransferDeadline")) or 0
            local seconds = deadline - workspace:GetServerTimeNow()
            if seconds > 0 then
                textValue = french and "PORT 1/2 • AUTRE PAD BLEU"
                    or "HARBOR 1/2 • ANOTHER BLUE PAD"
                color = Color3.fromRGB(142, 231, 253)
                -- One callback when this actual server deadline expires,
                -- not a repeating time/position/render loop on Android.
                if deadlineScheduled ~= deadline then
                    deadlineScheduled = deadline
                    task.delay(math.clamp(seconds + 0.06, 0.06, 15),
                        function() refresh() end)
                end
            end
        end
    end

    chip.Visible = textValue ~= nil and (not touch
        or (trackerFits and MobileHudNotices.current() == nil))
    if textValue then
        chip.Text = textValue
        chip.TextColor3 = color
        outline.Color = color
    end
end

local viewportConnection = nil
local function bindCamera()
    if viewportConnection then viewportConnection:Disconnect() end
    local camera = workspace.CurrentCamera
    viewportConnection = camera
        and camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            layout()
            refresh()
        end) or nil
    layout()
    refresh()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

-- Rebinding after a real map swap also handles StreamingEnabled's
-- late Arena replication without scanning Workspace every frame.
local function bindMap(map)
    if boundMap == map and #mapConnections > 0 then return end
    for _, connection in ipairs(mapConnections) do
        connection:Disconnect()
    end
    table.clear(mapConnections)
    boundMap = map
    if map then
        table.insert(mapConnections, map.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then
                local arena = child
                table.insert(mapConnections, arena:GetAttributeChangedSignal(
                    "VariantId"):Connect(refresh))
                refresh()
            end
        end))
        table.insert(mapConnections, map.ChildRemoved:Connect(refresh))
        local arena = map:FindFirstChild("Arena")
        if arena then
            table.insert(mapConnections, arena:GetAttributeChangedSignal(
                "VariantId"):Connect(refresh))
        end
    end
    refresh()
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then bindMap(child) end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == boundMap then bindMap(nil) end
end)
bindMap(workspace:FindFirstChild("GeneratedMap"))

local stateEvent = ReplicatedStorage:WaitForChild("Remotes")
    :WaitForChild("RoundState")
stateEvent.OnClientEvent:Connect(function(state)
    activeRound = type(state) == "table" and state.phase == "round"
    refresh()
end)

for _, name in ipairs({
    "RoundParticipant", "RoundEliminated",
    "RoundSkyrailAceBoostReady", "RoundHelixMasterPulseReady",
    "RoundHarborTransferReady", "RoundHarborTransferStep",
    "RoundHarborTransferDeadline",
}) do
    player:GetAttributeChangedSignal(name):Connect(refresh)
end
MobileHudNotices.Changed:Connect(refresh)
