local HazardWarning = {}

function HazardWarning.configure(part, kind, duration, startSize, endSize)
    part:SetAttribute("WarningKind", kind)
    part:SetAttribute("WarningDuration", math.max(0.05, tonumber(duration) or 0.05))
    part:SetAttribute("WarningStartSize", math.max(0.1, tonumber(startSize) or 1))
    part:SetAttribute("WarningEndSize", math.max(0.1, tonumber(endSize) or startSize or 1))
end

return HazardWarning
