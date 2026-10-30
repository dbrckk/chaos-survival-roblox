-- Event-driven, localized readability for the REAL timed Tower shutters.
-- No camera loop, billboard duplication, remote or extra gameplay authority.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local roundState = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local phase = "waiting"
local tracked = {}

local function participantCanSee()
    return phase == "round"
        and player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true
end

local function update(gate, bundle)
    if not bundle or not bundle.sign.Parent then return end
    if not gate.Parent or not participantCanSee() then
        bundle.sign.Enabled = false
        return
    end
    local status = gate:GetAttribute("ShutterPhase")
    if status ~= "Warning" and status ~= "Raising"
        and status ~= "Raised" then
        bundle.sign.Enabled = false
        return
    end
    local locale = player.LocaleId
    if status == "Raised" then
        bundle.label.Text = CoreLocalization.text(
            locale, "TOWER_SHUTTER_JUMP"
        )
        bundle.label.TextColor3 = Color3.fromRGB(255, 231, 184)
    else
        bundle.label.Text = CoreLocalization.text(
            locale, "TOWER_SHUTTER_WARNING"
        )
        bundle.label.TextColor3 = Color3.fromRGB(255, 236, 188)
    end
    bundle.sign.Enabled = true
end

local function remove(gate)
    local bundle = tracked[gate]
    if not bundle then return end
    tracked[gate] = nil
    if bundle.connection then bundle.connection:Disconnect() end
    bundle.sign:Destroy()
end

local function attach(gate)
    if not gate:IsA("BasePart") or tracked[gate]
        or gate:GetAttribute("BridgeShutter") ~= true then return end
    local sign = Instance.new("BillboardGui")
    sign.Name = "TowerTimedGateGuide"
    sign.Adornee = gate
    sign.Size = UDim2.fromOffset(194, 46)
    sign.StudsOffsetWorldSpace = Vector3.new(0, 3.3, 0)
    sign.MaxDistance = 55
    sign.AlwaysOnTop = false
    sign.LightInfluence = 0.15
    sign.ResetOnSpawn = false
    sign.Enabled = false
    sign.Parent = playerGui

    local label = Instance.new("TextLabel")
    label.Name = "JumpOrWait"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(21, 27, 36)
    label.BackgroundTransparency = 0.15
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(255, 236, 188)
    label.TextScaled = true
    label.TextWrapped = true
    label.Text = ""
    label.Parent = sign

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
    local outline = Instance.new("UIStroke")
    outline.Color = Color3.fromRGB(235, 182, 95)
    outline.Thickness = 1.4
    outline.Transparency = 0.2
    outline.Parent = label

    local bundle = {sign = sign, label = label}
    tracked[gate] = bundle
    bundle.connection = gate:GetAttributeChangedSignal("ShutterPhase")
        :Connect(function() update(gate, bundle) end)
    update(gate, bundle)
end

roundState.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    phase = tostring(state.phase or "waiting")
    for gate, bundle in pairs(tracked) do update(gate, bundle) end
end)

player:GetAttributeChangedSignal("RoundParticipant"):Connect(function()
    for gate, bundle in pairs(tracked) do update(gate, bundle) end
end)
player:GetAttributeChangedSignal("RoundEliminated"):Connect(function()
    for gate, bundle in pairs(tracked) do update(gate, bundle) end
end)

CollectionService:GetInstanceAddedSignal("TowerSkybridgeShutter")
    :Connect(attach)
CollectionService:GetInstanceRemovedSignal("TowerSkybridgeShutter")
    :Connect(remove)
for _, gate in ipairs(CollectionService:GetTagged("TowerSkybridgeShutter")) do
    attach(gate)
end
