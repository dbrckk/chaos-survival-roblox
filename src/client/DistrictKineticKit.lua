-- Four original kinetic setpiece signatures: subtle *existing-geometry*
-- movement, not new Parts, lights, physics, network traffic or frame loops.
-- Tweens run on the local client; each is cancelled on map/tier changes.
local TweenService = game:GetService("TweenService")
local DistrictKineticKit = {}

local MOTION = {
    [1] = {
        {name = "RadarDish", mode = "pan", angle = 13, seconds = 4.4},
        {name = "RadarDishInnerLip", mode = "pan", angle = 13, seconds = 4.4, high = true},
    },
    [2] = {
        {name = "CargoStripe-1", mode = "flicker", transparency = 0.62, seconds = 2.6},
        {name = "CargoStripe1", mode = "flicker", transparency = 0.58, seconds = 3.0},
        {name = "CraneCap", mode = "flicker", transparency = 0.73, seconds = 3.3, high = true},
    },
    [3] = {
        {name = "ContainmentGlass", mode = "flicker", transparency = 0.48, seconds = 3.6},
        {name = "MagneticCollar2", mode = "flicker", transparency = 0.63, seconds = 3.1, high = true},
    },
    [4] = {
        {name = "CommsSignalFin", mode = "pan", angle = 9, seconds = 5.2},
        {name = "CommsTopBeacon", mode = "flicker", transparency = 0.58, seconds = 3.2, high = true},
    },
}

function DistrictKineticKit.plan(sector, tier, reducedMotion)
    if reducedMotion == true or (tier ~= "Medium" and tier ~= "High") then
        return {}
    end
    local index = tonumber(sector)
    if not index or index ~= math.floor(index) then return {} end
    local selected = MOTION[index]
    if not selected then return {} end
    local result = {}
    for _, spec in ipairs(selected) do
        if not spec.high or tier == "High" then
            result[#result + 1] = spec
        end
    end
    return result
end

function DistrictKineticKit.start(model, sector, tier, reducedMotion)
    local tracks = {}
    if not model or not model:IsA("Model")
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("LocalOriginal3D") ~= true
        or model:GetAttribute("DistrictSector") ~= sector then
        return tracks
    end
    for _, spec in ipairs(DistrictKineticKit.plan(sector, tier, reducedMotion)) do
        local part = model:FindFirstChild(spec.name)
        if part and part:IsA("BasePart") and part.Anchored
            and not part.CanCollide and not part.CanTouch and not part.CanQuery then
            local property = spec.mode == "pan" and "CFrame" or "Transparency"
            local original = part[property]
            local target
            if spec.mode == "pan" then
                target = original * CFrame.Angles(0, math.rad(spec.angle), 0)
            else
                target = spec.transparency
            end
            local tween = TweenService:Create(part,
                TweenInfo.new(spec.seconds, Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut, -1, true),
                {[property] = target})
            tracks[#tracks + 1] = {
                part = part,
                property = property,
                original = original,
                tween = tween,
            }
            tween:Play()
        end
    end
    return tracks
end

function DistrictKineticKit.stop(tracks)
    if type(tracks) ~= "table" then return end
    for _, track in ipairs(tracks) do
        track.tween:Cancel()
        if track.part.Parent then
            track.part[track.property] = track.original
        end
    end
    table.clear(tracks)
end

return DistrictKineticKit
