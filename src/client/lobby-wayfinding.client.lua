local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(ReplicatedStorage.Shared.UITheme)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "LobbyWayfindingLocal"
folder.Parent = workspace

local markers = {}
local phase = "waiting"

local definitions = {
    {
        name = "ARENA",
        subtitle = "VOTE • SURVIVE • ADAPT",
        offset = Vector3.new(0, 8.5, 38),
        color = UITheme.Colors.Cyan,
    },
    {
        name = "PRACTICE",
        subtitle = "BOOST PADS",
        offset = Vector3.new(-28, 6.5, 0),
        color = UITheme.Colors.Violet,
    },
    {
        name = "TIME TRIAL",
        subtitle = "4 CHECKPOINTS",
        offset = Vector3.new(28, 6.5, 0),
        color = UITheme.Colors.Gold,
    },
}

local function makeMarker(definition)
    local anchor = Instance.new("Part")
    anchor.Name = "Wayfinding_" .. string.gsub(definition.name, " ", "")
    anchor.Size = Vector3.new(0.25, 0.25, 0.25)
    anchor.Position = Config.LobbyCenter + definition.offset
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.Transparency = 1
    anchor.Parent = folder

    local gui = Instance.new("BillboardGui")
    gui.Name = "WayfindingGui"
    gui.Adornee = anchor
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.Size = UDim2.fromOffset(190, 54)
    gui.MaxDistance = 105
    gui.Parent = anchor

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = UITheme.Colors.Panel
    panel.BackgroundTransparency = 0.18
    panel.BorderSizePixel = 0
    panel.Parent = gui
    UITheme.addCorner(panel, UITheme.Corners.Medium)
    UITheme.addStroke(panel, definition.color, 1.2, 0.30)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -12, 0.58, 0)
    title.Position = UDim2.fromOffset(6, 2)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Text = definition.name
    title.TextColor3 = definition.color:Lerp(Color3.new(1, 1, 1), 0.30)
    title.TextScaled = true
    title.Parent = panel

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -12, 0.28, 0)
    subtitle.Position = UDim2.new(0, 6, 0.66, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamBold
    subtitle.Text = definition.subtitle
    subtitle.TextColor3 = UITheme.Colors.Muted
    subtitle.TextScaled = true
    subtitle.Parent = panel

    local beam = Instance.new("Part")
    beam.Name = "WayfindingBeam"
    beam.Size = Vector3.new(0.10, 5.2, 0.10)
    beam.Position = anchor.Position - Vector3.new(0, 3.0, 0)
    beam.Anchored = true
    beam.CanCollide = false
    beam.CanTouch = false
    beam.CanQuery = false
    beam.CastShadow = false
    beam.Material = Enum.Material.Neon
    beam.Color = definition.color
    beam.Transparency = 0.48
    beam.Parent = folder

    table.insert(markers, {gui = gui, beam = beam})
end

for _, definition in ipairs(definitions) do
    makeMarker(definition)
end

local function refresh()
    local visible = phase ~= "ready" and phase ~= "round"
    for _, marker in ipairs(markers) do
        marker.gui.Enabled = visible
        marker.beam.Transparency = visible and 0.48 or 1
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state.phase or "waiting")
    refresh()
end)

refresh()
