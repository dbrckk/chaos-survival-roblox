-- Event-driven, localized readability for the REAL timed Tower shutters.
-- No camera loop, billboard duplication, remote or extra gameplay authority.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")

local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local ForgedBridge = require(script.Parent.ApprovedTowersSignatureBridgeMeshKit)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local roundState = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local phase = "waiting"
local tracked = {}
local requestedMeshes = {}
local readyMeshes = {}
local REOPEN_SECONDS = 1.6

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
    local locale = player.LocaleId
    if status == "Idle" and not gate.CanCollide then
        local stamp = gate:GetAttribute("ShutterReopenedAt")
        local age = type(stamp) == "number" and workspace:GetServerTimeNow() - stamp
        if type(age) == "number" and age >= -0.15 and age < REOPEN_SECONDS then
            bundle.label.Text = CoreLocalization.text(locale, "TOWER_SHUTTER_OPEN")
            bundle.label.TextColor3 = Color3.fromRGB(217, 255, 232)
            bundle.outline.Color = Color3.fromRGB(87, 202, 151)
            bundle.sign.MaxDistance = 40
            bundle.sign.Enabled = true
            if bundle.reopenStamp ~= stamp then
                bundle.reopenStamp = stamp
                task.delay(REOPEN_SECONDS - age, function()
                    if tracked[gate] ~= bundle or bundle.reopenStamp ~= stamp then return end
                    bundle.reopenStamp = nil
                    update(gate, bundle)
                end)
            end
            return
        end
    end
    if status ~= "Warning" and status ~= "Raising" and status ~= "Raised" then
        bundle.sign.Enabled = false
        return
    end
    bundle.outline.Color = Color3.fromRGB(235, 182, 95)
    bundle.sign.MaxDistance = 55
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

local function refreshSkins()
    if not next(tracked) then return end
    local source = ForgedBridge.sweptProfile()
    if not source then return end
    local meshId = source.MeshId
    if not readyMeshes[meshId]
        and ContentProvider:GetAssetFetchStatus(meshId) ~= Enum.AssetFetchStatus.Success then
        if requestedMeshes[meshId] then return end
        requestedMeshes[meshId] = true
        task.spawn(function()
            local loaded = false
            local ok = pcall(ContentProvider.PreloadAsync, ContentProvider, {meshId}, function(_, status)
                loaded = status == Enum.AssetFetchStatus.Success
            end)
            if ok and loaded then
                readyMeshes[meshId] = true
                refreshSkins()
            end
        end)
        return
    end

    for gate, bundle in pairs(tracked) do
        if bundle.skin and bundle.skin.Parent == gate then continue end
        bundle.skin, bundle.releaseSkin = ForgedBridge.bindShutterSkin(gate, source)
    end
end

local function remove(gate)
    local bundle = tracked[gate]
    if not bundle then return end
    tracked[gate] = nil
    for _, connection in ipairs(bundle.connections) do connection:Disconnect() end
    if bundle.releaseSkin then bundle.releaseSkin() end
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

    local bundle = {sign = sign, label = label, outline = outline}
    tracked[gate] = bundle
    local function changed() update(gate, bundle) end
    bundle.connections = {
        gate:GetAttributeChangedSignal("ShutterPhase"):Connect(changed),
        gate:GetAttributeChangedSignal("ShutterReopenedAt"):Connect(changed),
        gate:GetPropertyChangedSignal("CanCollide"):Connect(changed),
    }
    changed()
    refreshSkins()
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
ReplicatedStorage.DescendantAdded:Connect(function(instance)
    if instance.Name == "ForgedBridge" or instance.Name == "SweptCrossbeam" then
        task.defer(refreshSkins)
    end
end)
for _, gate in ipairs(CollectionService:GetTagged("TowerSkybridgeShutter")) do
    attach(gate)
end
