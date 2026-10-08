local VisualBudgetRules = {}

VisualBudgetRules.LocalFolders = {
    "ArenaCinematicDepthLocal",
    "ArenaSurfaceReliefLocal",
    "ArenaSilhouetteBreakupLocal",
    "ArenaMidgroundMassLocal",
    "ArenaUnderstructureLocal",
    "ArenaHeroSceneryLocal",
    "ArenaSignatureLocal",
    "ArenaEdgeProfileLocal",
    "ArenaServicePropsLocal",
    "ArenaNavigationLanguageLocal",
    "ArenaPlatformIdentityLocal",
    "ArenaAmbientPropsLocal",
    "ArenaFocalLightingLocal",
    "ArenaSurfaceDetailLocal",
    "ChaosEnvironmentDepthLocal",
    "ChaosWorldPolishLocal",
    "ArenaCinematicDisasterAtmosphereLocal",
    "LobbyCoreOrbitLocal",
    "LobbyCrewBeaconLocal",
    "ResultConstellationLocal",
    "ChaosHazardWarningDecorLocal",
    "ChaosPremiumDisasterVfxLocal",
    "DisappearingPlatformReadabilityLocal",
    "DisasterClimaxLocal",
    "DisasterResidueLocal",
    "HazardRouteReadabilityLocal",
    "HazardWarningSignaturesLocal",
    "LobbyPersonalProgressLocal",
    "LobbyPresentationLocal",
    "LobbyProfileHologramLocal",
    "LobbyRoundRecapLocal",
    "LobbySurfaceDetailLocal",
    "LobbyTimeTrialLocal",
    "LobbyWayfindingLocal",
    "PracticePadPolishLocal",
    "ResultSurvivorSpotlightsLocal",
    "RookieWorldGuideLocal",
    "TornadoDebrisLocal",
}

VisualBudgetRules.Budgets = {
    High = {
        Parts = 900,
        Lights = 64,
        Effects = 110,
    },
    Medium = {
        Parts = 680,
        Lights = 48,
        Effects = 82,
    },
    Low = {
        Parts = 440,
        Lights = 32,
        Effects = 56,
    },
}

function VisualBudgetRules.isLight(instance)
    return instance ~= nil and instance:IsA("Light")
end

function VisualBudgetRules.isEffect(instance)
    return instance ~= nil
        and (
            instance:IsA("ParticleEmitter")
            or instance:IsA("Trail")
            or instance:IsA("Beam")
            or instance:IsA("Highlight")
            or instance:IsA("Smoke")
            or instance:IsA("Fire")
            or instance:IsA("Sparkles")
        )
end

function VisualBudgetRules.collect(root)
    local metrics = {
        Parts = 0,
        Lights = 0,
        Effects = 0,
    }
    local auditedFolders = 0

    if not root then
        return metrics, auditedFolders
    end

    for _, folderName in ipairs(VisualBudgetRules.LocalFolders) do
        local folder = root:FindFirstChild(folderName)
        if folder then
            auditedFolders += 1
            for _, descendant in ipairs(folder:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    metrics.Parts += 1
                elseif VisualBudgetRules.isLight(descendant) then
                    metrics.Lights += 1
                elseif VisualBudgetRules.isEffect(descendant) then
                    metrics.Effects += 1
                end
            end
        end
    end

    return metrics, auditedFolders
end

function VisualBudgetRules.forTier(tierName)
    return VisualBudgetRules.Budgets[tierName] or VisualBudgetRules.Budgets.High
end

function VisualBudgetRules.withinBudget(tierName, metrics)
    local budget = VisualBudgetRules.forTier(tierName)
    local values = metrics or {}

    return (tonumber(values.Parts) or 0) <= budget.Parts
        and (tonumber(values.Lights) or 0) <= budget.Lights
        and (tonumber(values.Effects) or 0) <= budget.Effects
end

function VisualBudgetRules.status(tierName, metrics)
    if tierName ~= "High" and tierName ~= "Medium" and tierName ~= "Low" then
        return "UNKNOWN"
    end
    return VisualBudgetRules.withinBudget(tierName, metrics) and "OK" or "OVER"
end

function VisualBudgetRules.overages(tierName, metrics)
    local budget = VisualBudgetRules.forTier(tierName)
    local values = metrics or {}
    local result = {}

    for _, key in ipairs({"Parts", "Lights", "Effects"}) do
        local count = tonumber(values[key]) or 0
        local limit = budget[key]
        if count > limit then
            result[key] = count - limit
        end
    end

    return result
end

return VisualBudgetRules
