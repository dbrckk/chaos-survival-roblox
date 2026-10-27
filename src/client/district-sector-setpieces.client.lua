-- Authored native 3D silhouettes at the FOUR playable districts.
-- Unlike off-map skyline art these sit inside the 320-stud floor, close
-- enough to orient real players along the outer stair and branch routes.
-- Client-only, noncolliding, no runtime physics, sound, external assets,
-- RenderStepped, Heartbeat, lights or high-frequency update tasks.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "DistrictSectorSetpiecesLocal"
folder.Parent = workspace

local watchedMap = nil
local disconnectReady = nil
local rebuildQueued = false

local signs = {
    {-1, -1, "OBSERVATORY", "01"},
    {1, -1, "CARGO DEPOT", "02"},
    {-1, 1, "POWER PLANT", "03"},
    {1, 1, "COMMS ARRAY", "04"},
}

local function part(parent, name, size, frame, color, material, alpha, shape)
    local piece = Instance.new("Part")
    piece.Name = name
    piece.Size = size
    piece.CFrame = frame
    piece.Anchored = true
    piece.CanCollide = false
    piece.CanQuery = false
    piece.CanTouch = false
    piece.CastShadow = false
    piece.Color = color
    piece.Material = material or Enum.Material.Metal
    piece.Transparency = alpha or 0
    if shape then piece.Shape = shape end
    piece.Parent = parent
    return piece
end

local function beam(parent, name, root, a, b, thick, color, alpha)
    local delta = b - a
    if delta.Magnitude < 0.1 then return end
    local at = (a + b) * 0.5
    return part(parent, name, Vector3.new(thick, delta.Magnitude, thick),
        root * CFrame.lookAt(at, b) * CFrame.Angles(math.pi * 0.5, 0, 0),
        color, Enum.Material.Metal, alpha)
end

local function sectorSign(model, anchor, copy, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "SectorWaypoint"
    gui.Adornee = anchor
    gui.Size = UDim2.fromOffset(156, 40)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 2.0, 0)
    gui.MaxDistance = 105
    gui.AlwaysOnTop = false
    gui.Parent = anchor

    local label = Instance.new("TextLabel")
    label.Name = "SectorName"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(14, 24, 36)
    label.BackgroundTransparency = 0.18
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.TextColor3 = color
    label.Text = copy
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = label
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = 0.32
    stroke.Thickness = 1.2
    stroke.Parent = label
end

local function makeSector(base, theme, index, high)
    local sx, sz, title, number = table.unpack(signs[index])
    local reachX = math.min(116, base.Size.X * 0.5 - 26)
    local reachZ = math.min(88, base.Size.Z * 0.5 - 38)
    local root = base.CFrame
        * CFrame.new(sx * reachX, base.Size.Y * 0.5, sz * reachZ)
        * CFrame.Angles(0, math.rad((index - 1) * 90 + 45), 0)

    local dark = theme.Structure:Lerp(Color3.fromRGB(14, 22, 31), 0.42)
    local alloy = theme.Detail:Lerp(theme.Structure, 0.36)
    local accent = index % 2 == 0 and theme.Secondary or theme.Accent
    local model = Instance.new("Model")
    model.Name = "Sector" .. number .. "_" .. title:gsub("%s+", "")
    model:SetAttribute("LocalOriginal3D", true)
    model:SetAttribute("CosmeticOnly", true)
    model:SetAttribute("DistrictSector", index)
    model.Parent = folder

    local function make(name, size, localCFrame, color, material, alpha, shape)
        return part(model, name, size, root * localCFrame,
            color or alloy, material, alpha, shape)
    end

    local foundation = make("GroundFoundation",
        Vector3.new(14, 0.55, 13),
        CFrame.new(0, 0.27, 0), dark, Enum.Material.Slate, 0.07)
    local face = make("SectorIdentityPlate", Vector3.new(9, 1.6, 0.55),
        CFrame.new(0, 5.4, -5.8), alloy, Enum.Material.Metal, 0.03)
    sectorSign(model, face, "SECTOR " .. number .. "\n" .. title, accent)

    if index == 1 then
        -- Observatory: tall angled receiver with a distinct disk antenna.
        make("ReceiverMast", Vector3.new(2.1, 17.0, 2.1),
            CFrame.new(0, 9.0, 0), dark)
        make("RadarDish", Vector3.new(0.62, 8.6, 8.6),
            CFrame.new(0, 18, 0) * CFrame.Angles(0, math.rad(22), math.rad(20)),
            alloy, Enum.Material.Metal, 0.02, Enum.PartType.Cylinder)
        local eye = make("RadarEye", Vector3.new(2.5, 2.5, 2.5),
            CFrame.new(-0.65, 18, -0.3), accent, Enum.Material.Glass, 0.24,
            Enum.PartType.Ball)
        if high then
            for side = -1, 1, 2 do
                beam(model, "ReceiverBrace" .. side, root,
                    Vector3.new(side * 6, 0.7, 3),
                    Vector3.new(0, 15.5, 0), 0.75, alloy, 0.04)
            end
            make("ScannerBalance", Vector3.new(8.2, 0.7, 0.7),
                CFrame.new(0, 17, 1.8) * CFrame.Angles(0, math.rad(30), 0),
                alloy)
            make("DishBacklight", Vector3.new(3.2, 0.2, 1.1),
                CFrame.new(0.3, 14.0, -1), accent, Enum.Material.Neon, 0.35)
        end
        eye:SetAttribute("OriginalLens", true)
    elseif index == 2 then
        -- Cargo depot: stacked freight pods, crane frame and suspended load.
        for side = -1, 1, 2 do
            make("CargoPod" .. side, Vector3.new(5.6, 5.4, 4.5),
                CFrame.new(side * 3.1, 3.25, 0), dark,
                Enum.Material.CorrodedMetal, 0.06)
            make("CargoStripe" .. side, Vector3.new(5.7, 0.46, 4.6),
                CFrame.new(side * 3.1, 5.65, 0), accent,
                Enum.Material.Neon, 0.32)
        end
        make("GantryBridge", Vector3.new(16.5, 1.6, 4),
            CFrame.new(0, 15, 0), alloy)
        if high then
            for side = -1, 1, 2 do
                make("GantryPylon" .. side, Vector3.new(1.35, 16, 1.45),
                    CFrame.new(side * 7.0, 8.5, 0), dark)
            end
            make("CargoHanger", Vector3.new(0.55, 6.4, 0.55),
                CFrame.new(0, 11.1, 0), alloy)
            make("RaisedSupplyPod", Vector3.new(4.8, 3.0, 3.4),
                CFrame.new(0, 7.4, 0), theme.Detail)
            make("CraneCap", Vector3.new(4.5, 0.6, 5),
                CFrame.new(0, 16, 0), accent, Enum.Material.Neon, 0.44)
        end
    elseif index == 3 then
        -- Power station: visual containment volume with axial fins.
        make("ReactorCoreHousing", Vector3.new(7, 12.5, 7),
            CFrame.new(0, 6.95, 0), dark)
        make("ContainmentGlass", Vector3.new(7.25, 2.5, 7.25),
            CFrame.new(0, 8.6, 0), accent,
            Enum.Material.Glass, 0.26)
        for side = -1, 1, 2 do
            make("ReactorFin" .. side, Vector3.new(2.3, 10, 4.5),
                CFrame.new(side * 5.4, 5.8, 0),
                alloy, Enum.Material.Metal, 0.07)
        end
        if high then
            for segment = 1, 8 do
                local angle = (segment - 1) * (math.pi * 2 / 8)
                make("MagneticCollar" .. segment, Vector3.new(3.8, 0.54, 0.74),
                    CFrame.new(math.cos(angle) * 5.0, 14.0,
                        math.sin(angle) * 5.0)
                        * CFrame.Angles(0, -angle, 0),
                    segment % 2 == 0 and accent or alloy,
                    segment % 2 == 0 and Enum.Material.Neon
                        or Enum.Material.Metal,
                    segment % 2 == 0 and 0.35 or 0.06)
            end
        end
    else
        -- Comms relay: tall scanner fin, side receivers and glass collar.
        make("CommsMast", Vector3.new(2.3, 21, 2.3),
            CFrame.new(0, 11.2, 0), dark)
        make("CommsSignalFin", Vector3.new(9.3, 7.4, 1.4),
            CFrame.new(0, 17.4, 0) * CFrame.Angles(0, math.rad(17), 0),
            alloy)
        make("ControlCabin", Vector3.new(5.2, 3.8, 5.2),
            CFrame.new(0, 12.1, 0), dark)
        make("ScannerWindow", Vector3.new(5.35, 1.6, 5.35),
            CFrame.new(0, 12.5, 0), accent, Enum.Material.Glass, 0.32)
        if high then
            for side = -1, 1, 2 do
                beam(model, "TransmitterSupport" .. side, root,
                    Vector3.new(side * 5, 0.6, 3),
                    Vector3.new(0, 17, 0), 0.67, alloy, 0.06)
            end
            make("CommsTopBeacon", Vector3.new(1.5, 1.5, 1.5),
                CFrame.new(0, 22.1, 0), accent, Enum.Material.Glass, 0.18,
                Enum.PartType.Ball)
            make("AntennaNeedle", Vector3.new(0.38, 5, 0.38),
                CFrame.new(0, 25.1, 0), alloy)
        end
    end

    -- A runtime budget check prevents future editorial additions silently
    -- multiplying geometry on phones. This does not mask a broken tier.
    local count = 0
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then count += 1 end
    end
    model:SetAttribute("Decorative3DParts", count)
    assert(count <= (high and 22 or 9),
        "District sector setpiece exceeded tier part count")
    return model
end

local function rebuild()
    folder:ClearAllChildren()
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
    if tier == "Low" then return end

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = MapVisualReadiness.part(generated, "Arena", "Base")
    if not arena or not base or not base:IsA("BasePart") then return end
    if math.min(base.Size.X, base.Size.Z) < 280 then return end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    for index = 1, 4 do
        makeSector(base, theme, index, tier == "High")
    end
end

local function scheduleRebuild()
    if rebuildQueued then return end
    rebuildQueued = true
    task.defer(function()
        rebuildQueued = false
        rebuild()
    end)
end

local function bindMap(generated)
    if disconnectReady then
        disconnectReady()
        disconnectReady = nil
    end
    watchedMap = generated
    if generated then
        disconnectReady = MapVisualReadiness.watch(
            generated, "Arena", "Base", scheduleRebuild
        )
    else
        folder:ClearAllChildren()
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and child == workspace:FindFirstChild("GeneratedMap") then
        bindMap(child)
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scheduleRebuild)
bindMap(workspace:FindFirstChild("GeneratedMap"))
scheduleRebuild()
