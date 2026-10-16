local VisualBudgetRules = {}

VisualBudgetRules.LocalFolders = {
    "ArenaCinematicDepthLocal",
    "ArenaSurfaceReliefLocal",
    "ArenaSilhouetteBreakupLocal",
    "ArenaMidgroundMassLocal",
    "ArenaUnderstructureLocal",
    "ArenaHeroSceneryLocal",
    "ArenaSignatureLocal",
    "AerialSurveyLocal",
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
    "ChaosMotionDisasterVfxLocal",
    "DisappearingPlatformReadabilityLocal",
    "DisasterClimaxLocal",
    "DisasterIntroGlyphLocal",
    "DisasterIntroMotionLocal",
    "DisasterResidueLocal",
    "ImpactSetpieceLocal",
    "CharacterContactLocal",
    "LocomotionContactLocal",
    "HazardRouteReadabilityLocal",
    "HazardWarningSignaturesLocal",
    "LobbyPersonalProgressLocal",
    "LobbyPresentationLocal",
    "LobbyShowtimeLocal",
    "PhaseDashVfxLocal",
    "FluxRelayLocal",
    "GridCircuitLocal",
    "OrbitalHelixLocal",
    "TowerSkyrailLocal",
    "LobbyProfileHologramLocal",
    "LobbyRoundRecapLocal",
    "LobbySurfaceDetailLocal",
    "LobbyTimeTrialLocal",
    "LobbyWayfindingLocal",
    "PracticePadPolishLocal",
    -- Nested within that folder on marked lobby pads; the dedicated
    -- lobby-pad collector accounts for its Parts without double-counting.
    "PracticeVectorGlyphLocal",
    "ResultSurvivorSpotlightsLocal",
    "RoundTransitionPulsesLocal",
    "RoundCelebrationPulsesLocal",
    "RookieWorldGuideLocal",
    "TornadoDebrisLocal",
    -- Persistent, non-colliding tornado warning perimeter; retain it in
    -- the existing tiered VFX budget and runtime scenery audit.
    "TornadoWindBoundaryLocal",
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

-- Cosmetic owner names created on a character's HumanoidRootPart. These
-- are not descendants of the workspace-wide local visual folders.
-- The AI's server-owned motion trail is deliberately not attributed here.
local rootEffectTypes = {
    ChaosMotionTrail = "Trail",
    PhaseDashRibbon = "Trail",
    ChaosReactionDodge = "Beam",
    ChaosReactionShock = "Beam",
    ChaosReactionLanding = "Beam",
}

-- Local character/bot polish, human motion, dash and hazard feedback live
-- under character rigs. Count only named client-created GPU objects, never
-- server-owned rig Parts, lights or unrelated visual effects.
local function collectCharacterPolish(model, metrics)
    if not model or not model:IsA("Model") then return end
    local highlight = model:FindFirstChild("ChaosCharacterPolishHighlight")
    if highlight and highlight:IsA("Highlight") then
        metrics.Effects += 1
    end
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            for _, effect in ipairs(part:GetChildren()) do
                if effect.Name == "ChaosCharacterPolishLight"
                    and effect:IsA("PointLight") then
                    metrics.Lights += 1
                elseif part.Name == "HumanoidRootPart" then
                    local effectType = rootEffectTypes[effect.Name]
                    if effectType and effect:IsA(effectType) then
                        -- Disabled transient Effects still own Instances
                        -- until Debris/owner cleanup; audit both states.
                        metrics.Effects += 1
                    end
                end
            end
        end
    end
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

    -- Some cosmetic effects must be parented to server-owned hazard parts
    -- for their Attachment or SurfaceLight behavior. Audit those *named*
    -- client children rather than the authoritative shell/collision parts.
    -- Restrict names, parent types and ancestry so unrelated server FX do
    -- not become falsely attributed to the local graphics budget.
    for _, hazard in ipairs(root:GetChildren()) do
        if hazard:IsA("BasePart") then
            if hazard.Name == "RoundMeteor" then
                local trail = hazard:FindFirstChild("SignatureMeteorTrail")
                if trail and trail:IsA("Trail") then
                    metrics.Effects += 1
                end
            elseif hazard.Name == "RoundLava" or hazard.Name == "FreezeWarning" then
                local isLava = hazard.Name == "RoundLava"
                local lightName = "LavaGlowLocal"
                local attachmentName = isLava and "LavaHeatLocal" or "FreezeMistLocal"
                local emitterName = isLava and "LavaEmbers" or "FreezeMist"
                if isLava then
                    for _, child in ipairs(hazard:GetChildren()) do
                        if child.Name == lightName and child:IsA("SurfaceLight") then
                            metrics.Lights += 1
                        end
                    end
                end
                for _, child in ipairs(hazard:GetChildren()) do
                    if child.Name == attachmentName and child:IsA("Attachment") then
                        for _, effect in ipairs(child:GetChildren()) do
                            if effect.Name == emitterName
                                and effect:IsA("ParticleEmitter") then
                                metrics.Effects += 1
                            end
                        end
                    end
                end
            end
        end
    end

    -- Practice pad cosmetics live under server-owned lobby Parts, not as
    -- direct workspace folders. The old direct-root lookup never saw them.
    -- Count only the client-owned named bundle on a real, marked pad, not
    -- the server-owned pad itself, its light, or unrelated server effects.
    local generated = root:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local activities = lobby and lobby:FindFirstChild("Activities")
    if activities then
        for _, pad in ipairs(activities:GetChildren()) do
            if pad:IsA("BasePart")
                and pad:GetAttribute("LobbyPracticePad") == true then
                local localFolder = pad:FindFirstChild("PracticePadPolishLocal")
                local localAttachment = pad:FindFirstChild("PracticeMotesAttachment")
                local hasFolder = localFolder and localFolder:IsA("Folder")
                local hasAttachment = localAttachment
                    and localAttachment:IsA("Attachment")
                if hasFolder or hasAttachment then
                    auditedFolders += 1
                    if hasFolder then
                        for _, descendant in ipairs(localFolder:GetDescendants()) do
                            if descendant:IsA("BasePart") then
                                metrics.Parts += 1
                            elseif VisualBudgetRules.isLight(descendant) then
                                metrics.Lights += 1
                            elseif VisualBudgetRules.isEffect(descendant) then
                                metrics.Effects += 1
                            end
                        end
                    end
                    if hasAttachment then
                        for _, descendant in ipairs(localAttachment:GetDescendants()) do
                            if descendant.Name == "PracticeMotes"
                                and descendant:IsA("ParticleEmitter") then
                                metrics.Effects += 1
                            end
                        end
                    end
                end
            end
        end
    end

    -- Player characters sit directly in workspace; solo AI contestants sit
    -- in workspace.AISurvivors. Both use the same client-only Polish owner.
    -- Only inspect these immediate model collections, not the entire map.
    for _, model in ipairs(root:GetChildren()) do
        if model:IsA("Model") then
            collectCharacterPolish(model, metrics)
        end
    end
    local bots = root:FindFirstChild("AISurvivors")
    if bots and bots:IsA("Folder") then
        for _, model in ipairs(bots:GetChildren()) do
            collectCharacterPolish(model, metrics)
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
