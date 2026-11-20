local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RouteSignalGeometry = require("./RouteSignalGeometry")
local PremiumLargeStructureAssets = require("./PremiumLargeStructureAssets")

local RoundEquipmentArt = {}

-- Resolve the approved regions once when the round creates its equipment.
-- Availability is independent per region and never delays round setup.
function RoundEquipmentArt.profiles(variant)
    local bridge = RouteSignalGeometry.approvedModel(
        ReplicatedStorage:FindFirstChild("ApprovedTowersSignatureBridgeTemplates"),
        "ForgedBridge", "OriginalTowersSignatureBridge3D", 126298311664881)
    local perimeter = RouteSignalGeometry.approvedModel(
        ReplicatedStorage:FindFirstChild("ApprovedPerimeterArmorTemplates"),
        "Cap", "OriginalPerimeterArmor3D", 88962643359267)
    local reactor = RouteSignalGeometry.approvedModel(
        ReplicatedStorage:FindFirstChild("ApprovedOrbitalReactorLandmarkTemplates"),
        "Node", "OriginalOrbitalReactorLandmark3D", 104654294187035)
    local shaft, shaftId = PremiumLargeStructureAssets.shaftProfile(variant)
    local function region(model, name, assetId)
        local mesh = model and model:FindFirstChild(name)
        return {
            part = mesh and mesh:IsA("MeshPart") and mesh.Archivable and mesh or nil,
            assetId = assetId,
        }
    end
    return {
        beam = region(bridge, "SweptCrossbeam", 126298311664881),
        edge = region(bridge, "SculptedEdgeBand", 126298311664881),
        casting = region(perimeter, "WayfinderBase", 88962643359267),
        shaft = {part = shaft, assetId = shaftId},
        core = {part = reactor and RouteSignalGeometry.regionByBounds(reactor, Vector3.new(2.96, 2.9503, 2.96)),
            assetId = 104654294187035},
        ring = {part = reactor and RouteSignalGeometry.regionByBounds(reactor, Vector3.new(4.11, 0.39, 4.11)),
            assetId = 104654294187035},
    }
end

function RoundEquipmentArt.create(parent, name, size, frame, color, material, alpha, profile, shape)
    local meshFrame, meshSize = frame, size
    if profile and shape == Enum.PartType.Cylinder then
        -- Cylinder fallback uses X as its axis. The imported ring uses Y.
        meshFrame = frame * CFrame.Angles(0, 0, -math.pi * 0.5)
        meshSize = Vector3.new(size.Y, size.X, size.Z)
    end
    local p = profile and RouteSignalGeometry.fitStructural(meshFrame, meshSize, false, profile)
    if not p then
        p = Instance.new("Part")
        p.Size = size
        p.CFrame = frame
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        if shape then p.Shape = shape end
    end
    p.Name = name
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Transparency = alpha or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = parent
    return p
end

return RoundEquipmentArt
