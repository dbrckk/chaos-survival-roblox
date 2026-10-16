-- Cinematic gate cues, attached only to the existing lobby gate and runway.
-- All local, non-colliding, unlit; no new frame loop, asset download or render texture.
local TweenService = game:GetService("TweenService")
local LobbyGateCueKit = {}

local COUNTS = {Low = 2, Medium = 4, High = 6}
local NAMES = {
    "GateVectorFinL", "GateVectorFinR",
    "RunwayArrowForwardL", "RunwayArrowForwardR",
    "RunwayApproachMarkerL", "RunwayApproachMarkerR",
}
function LobbyGateCueKit.count(tier)
    return COUNTS[tier] or 0
end

function LobbyGateCueKit.build(parent, gateTop, runway, tier, accents)
    local pieces = {}
    if not parent or not gateTop or not runway
        or not gateTop:IsA("BasePart") or not runway:IsA("BasePart")
        or not accents or LobbyGateCueKit.count(tier) == 0 then
        return {pieces = pieces, mode = nil}
    end

    local specs = {
        {class = "WedgePart", size = Vector3.new(2.75, 1.18, 1.22),
            frame = gateTop.CFrame * CFrame.new(-8.9, -2.24, -0.64)
                * CFrame.Angles(0, 0, math.rad(-24)), kind = "fin", side = -1},
        {class = "WedgePart", size = Vector3.new(2.75, 1.18, 1.22),
            frame = gateTop.CFrame * CFrame.new(8.9, -2.24, -0.64)
                * CFrame.Angles(0, 0, math.rad(24)), kind = "fin", side = 1},
        {class = "WedgePart", size = Vector3.new(2.55, 0.09, 2.9),
            frame = runway.CFrame * CFrame.new(-2.9, runway.Size.Y * 0.5 + 0.20, -7)
                * CFrame.Angles(0, math.rad(90), 0), kind = "arrow", side = -1},
        {class = "WedgePart", size = Vector3.new(2.55, 0.09, 2.9),
            frame = runway.CFrame * CFrame.new(2.9, runway.Size.Y * 0.5 + 0.20, -7)
                * CFrame.Angles(0, math.rad(90), 0), kind = "arrow", side = 1},
        {class = "Part", size = Vector3.new(2.8, 0.075, 0.36),
            frame = runway.CFrame * CFrame.new(-3, runway.Size.Y * 0.5 + 0.18, 7.7),
            kind = "marker", side = -1},
        {class = "Part", size = Vector3.new(2.8, 0.075, 0.36),
            frame = runway.CFrame * CFrame.new(3, runway.Size.Y * 0.5 + 0.18, 7.7),
            kind = "marker", side = 1},
    }
    for index = 1, LobbyGateCueKit.count(tier) do
        local spec = specs[index]
        local part = Instance.new(spec.class)
        part.Name = NAMES[index]
        part.Size = spec.size
        part.CFrame = spec.frame
        part.Material = spec.kind == "fin" and Enum.Material.Metal
            or Enum.Material.DiamondPlate
        part.Color = accents.Cyan
        part.Transparency = 0.62
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part:SetAttribute("ChaosLobbyGateCue", true)
        part:SetAttribute("GateCueRole", spec.kind)
        part.Parent = parent
        table.insert(pieces, {
            part = part, rest = spec.frame, kind = spec.kind, side = spec.side,
        })
    end
    return {pieces = pieces, mode = nil}
end

function LobbyGateCueKit.apply(kit, mode, accents, reduceMotion)
    if not kit or not accents then return end
    local nextMode = (mode == "launch" or mode == "vote" or mode == "social")
        and mode or "inactive"
    if kit.mode == nextMode then return end
    kit.mode = nextMode
    local color = nextMode == "launch" and accents.Gold
        or (nextMode == "vote" and accents.Magenta or accents.Cyan)
    local alpha = nextMode == "inactive" and 1
        or (nextMode == "launch" and 0.12
            or (nextMode == "vote" and 0.36 or 0.70))
    for _, entry in ipairs(kit.pieces) do
        if entry.part.Parent then
            local targetFrame = entry.rest
            if entry.kind == "fin" then
                local tilt = nextMode == "launch" and 12
                    or (nextMode == "vote" and 5 or 0)
                targetFrame = targetFrame
                    * CFrame.Angles(0, 0, math.rad(tilt * entry.side))
            end
            local properties = {
                CFrame = targetFrame,
                Color = color,
                Transparency = nextMode == "inactive" and 1
                    or math.clamp(alpha + (entry.kind == "fin" and 0 or 0.10), 0, 1),
            }
            if reduceMotion then
                for key, value in pairs(properties) do
                    entry.part[key] = value
                end
            else
                TweenService:Create(
                    entry.part,
                    TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    properties
                ):Play()
            end
        end
    end
end

return LobbyGateCueKit
