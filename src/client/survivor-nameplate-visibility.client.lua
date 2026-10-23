-- AI rigs, their replicated identity attributes and their nameplate UI
-- may arrive in different streaming batches. Never rely on a one-off timer
-- or on a countdown packet to repair a missing label.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local BotNameplateRules = require(ReplicatedStorage.Shared.BotNameplateRules)

local phase = "waiting"
local folder = nil
local folderAddedConnection = nil
local folderRemovedConnection = nil
local descendantConnection = nil
local modelConnections = {}

local function applyModel(model)
    if not model or not model:IsA("Model")
        or model:GetAttribute("AISurvivor") ~= true then
        return
    end

    local head = model:FindFirstChild("Head")
    local billboard = head and head:FindFirstChild("SurvivorNameplate")
    if not billboard or not billboard:IsA("BillboardGui") then
        return
    end

    local style = BotNameplateRules.presentation(
        phase, tostring(player:GetAttribute("VfxQualityTier") or "High"),
        UserInputService.TouchEnabled
    )
    billboard.AlwaysOnTop = style.AlwaysOnTop
    billboard.MaxDistance = style.MaxDistance

    local label = billboard:FindFirstChild("DisplayName")
    if label and label:IsA("TextLabel") then
        label.TextStrokeTransparency = style.StrokeTransparency
    end
end

local function refreshAll()
    if not folder then return end
    for _, model in ipairs(folder:GetChildren()) do
        applyModel(model)
    end
end

local function unwatchModel(model)
    local conn = modelConnections[model]
    if conn then
        conn:Disconnect()
        modelConnections[model] = nil
    end
end

local function watchModel(model)
    if not model:IsA("Model") or modelConnections[model] then
        return
    end
    modelConnections[model] = model:GetAttributeChangedSignal("AISurvivor")
        :Connect(function()
            -- The server may replicate the identity marker after the rig.
            applyModel(model)
        end)
    applyModel(model)
end

local function bindFolder(nextFolder)
    if folderAddedConnection then
        folderAddedConnection:Disconnect()
        folderAddedConnection = nil
    end
    if folderRemovedConnection then
        folderRemovedConnection:Disconnect()
        folderRemovedConnection = nil
    end
    if descendantConnection then
        descendantConnection:Disconnect()
        descendantConnection = nil
    end
    for model in pairs(modelConnections) do
        unwatchModel(model)
    end
    folder = nextFolder
    if not folder then return end

    folderAddedConnection = folder.ChildAdded:Connect(watchModel)
    folderRemovedConnection = folder.ChildRemoved:Connect(unwatchModel)
    descendantConnection = folder.DescendantAdded:Connect(function(descendant)
        -- The entire nameplate can arrive after Head, or its TextLabel
        -- can replicate after the BillboardGui was already styled.
        if descendant.Name ~= "SurvivorNameplate"
            and descendant.Name ~= "DisplayName" then
            return
        end
        -- DescendantAdded can fire before a streamed TextLabel has been
        -- parented to its final Head/BillboardGui on a slow Android client.
        -- Defer once, then check that the same folder still owns the rig.
        local owningFolder = folder
        task.defer(function()
            if folder ~= owningFolder or not descendant:IsDescendantOf(owningFolder) then
                return
            end
            local model = descendant:FindFirstAncestorOfClass("Model")
            if model and model.Parent == owningFolder then
                applyModel(model)
            end
        end)
    end)

    for _, model in ipairs(folder:GetChildren()) do
        watchModel(model)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "AISurvivors"
        and workspace:FindFirstChild("AISurvivors") == child then
        bindFolder(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == folder then
        bindFolder(workspace:FindFirstChild("AISurvivors"))
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    -- The phase, not the countdown seconds, controls nameplate emphasis.
    if type(state) ~= "table" then return end
    local nextPhase = tostring(state.phase or "waiting")
    if nextPhase == phase then return end
    phase = nextPhase
    refreshAll()
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshAll)

bindFolder(workspace:FindFirstChild("AISurvivors"))
