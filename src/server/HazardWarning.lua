local HazardWarning = {}

function HazardWarning.coverageDiameter(baseSize, padding)
    local size = typeof(baseSize) == "Vector3" and baseSize or Vector3.new(86, 0, 86)
    local extra = math.max(0, tonumber(padding) or 6)
    local diagonal = math.sqrt((size.X * size.X) + (size.Z * size.Z))
    return math.max(1, diagonal + extra)
end

function HazardWarning.arenaCoverageDiameter(fallback)
    local generatedMap = workspace:FindFirstChild("GeneratedMap")
    local arena = generatedMap and generatedMap:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if base and base:IsA("BasePart") then
        return HazardWarning.coverageDiameter(base.Size, 6)
    end

    return math.max(1, tonumber(fallback) or 150)
end

function HazardWarning.configure(part, kind, duration, startSize, endSize)
    local safeDuration = math.max(0.05, tonumber(duration) or 0.05)
    part:SetAttribute("WarningDuration", safeDuration)
    part:SetAttribute("WarningStartSize", math.max(0.1, tonumber(startSize) or 1))
    part:SetAttribute("WarningEndSize", math.max(0.1, tonumber(endSize) or startSize or 1))
    part:SetAttribute("WarningStartedAt", workspace:GetServerTimeNow())
    -- WarningKind is the readiness marker and must be replicated after all metadata.
    part:SetAttribute("WarningKind", kind)
end

return HazardWarning
