local OrbitalReactor = require(script.Parent.ApprovedOrbitalReactorLandmarkMeshKit)
local PylonShell = require(script.Parent.ApprovedLobbyPylonShell)
local ForgedBridge = require(script.Parent.ApprovedTowersSignatureBridgeMeshKit)
local FloorHardware = require(script.Parent.PremiumFloorHardwareMeshKit)
local PerimeterArmor = require(script.Parent.ApprovedPerimeterArmorMeshKit)
local LobbyMeshPreload = require(script.Parent.LobbyMeshPreload)

local Kit = {}
-- A late mesh is used on the next effect. An in-progress tween keeps
-- its original part and timing.
local geometryReady = LobbyMeshPreload.new(function() end)

local function fragmentProfile()
    local head = FloorHardware.platformCornerProfile()
    return head and head.part
end

function Kit.readyProfile(role, pressure)
    if (tonumber(pressure) or 0) >= 1 then return nil end
    local profile = if role == "ring" then OrbitalReactor.ringProfile()
        elseif role == "pylon" then PylonShell.bodyProfile()
        elseif role == "runway" then ForgedBridge.sweptProfile()
        elseif role == "fragment" then fragmentProfile()
        elseif role == "casting" then PerimeterArmor.wayfinderProfile()
        else OrbitalReactor.coreProfile()
    if profile and geometryReady(profile) then return profile end
    return nil
end

function Kit.size(part, diameter, thickness)
    if part:IsA("MeshPart") then return Vector3.new(diameter, thickness, diameter) end
    return Vector3.new(thickness, diameter, diameter)
end

function Kit.cloneProfile(profile)
    local part = profile and profile:Clone()
    if part then
        part:ClearAllChildren()
        part.TextureID = ""
    end
    return part
end

function Kit.disc(profile, position, diameter, thickness)
    local part = Kit.cloneProfile(profile)
    if part then
        part.CFrame = CFrame.new(position)
    else
        part = Instance.new("Part")
        part.Shape = Enum.PartType.Cylinder
        part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi * 0.5)
    end
    part.Size = Kit.size(part, diameter, thickness)
    return part
end

return Kit
