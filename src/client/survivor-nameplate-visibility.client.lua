local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local phase = "waiting"
local folderConnection = nil
local descendantConnection = nil

local function shouldEmphasize()
    if phase == "ready" or phase == "intermission" then
        return true
    end

    if phase == "result" then
        return true
    end

    return false
end

local function applyModel(model)
    if not model:IsA("Model") or model:GetAttribute("AISurvivor") ~= true then
        return
    end

    local head = model:FindFirstChild("Head")
    local billboard = head and head:FindFirstChild("SurvivorNameplate")
    if not billboard or not billboard:IsA("BillboardGui") then
        return
    end

    billboard.AlwaysOnTop = shouldEmphasize()
    billboard.MaxDistance = shouldEmphasize() and 96 or 72

    local label = billboard:FindFirstChild("DisplayName")
    if label and label:IsA("TextLabel") then
        label.TextStrokeTransparency = shouldEmphasize() and 0.24 or 0.38
    end
end

local function refreshAll()
    local folder = workspace:FindFirstChild("AISurvivors")
    if not folder then
        return
    end

    for _, child in ipairs(folder:GetChildren()) do
        applyModel(child)
    end
end

local function bindFolder(folder)
    if folderConnection then
        folderConnection:Disconnect()
        folderConnection = nil
    end
    if descendantConnection then
        descendantConnection:Disconnect()
        descendantConnection = nil
    end

    if not folder then
        return
    end

    folderConnection = folder.ChildAdded:Connect(function(child)
        task.delay(0.12, function()
            if child.Parent == folder then
                applyModel(child)
            end
        end)
    end)

    descendantConnection = folder.DescendantAdded:Connect(function(descendant)
        if descendant.Name ~= "SurvivorNameplate" then
            return
        end

        local head = descendant.Parent
        local model = head and head.Parent
        if model and model:IsA("Model") then
            task.defer(applyModel, model)
        end
    end)

    refreshAll()
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "AISurvivors" then
        bindFolder(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "AISurvivors" then
        bindFolder(nil)
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state.phase or "waiting")
    refreshAll()
end)

player:GetAttributeChangedSignal("Games"):Connect(refreshAll)

bindFolder(workspace:FindFirstChild("AISurvivors"))
