local SoloRules = {}

function SoloRules.resolve(config, playerCount)
    local solo = playerCount <= 1
    local soloConfig = config.Solo or {}

    if solo then
        return {
            Solo = true,
            IntermissionSeconds = soloConfig.IntermissionSeconds or 6,
            VoteSeconds = soloConfig.VoteSeconds or 4,
            ReadySeconds = soloConfig.ReadySeconds or 2,
            RoundSeconds = soloConfig.RoundSeconds or 30,
            PostRoundSeconds = soloConfig.PostRoundSeconds or 4,
            WinCoinMultiplier = soloConfig.WinCoinMultiplier or 1.4,
            WinXPMultiplier = soloConfig.WinXPMultiplier or 1.25,
            DoubleChaosEvery = soloConfig.DoubleChaosEvery or 4,
            DoubleChaosChance = soloConfig.DoubleChaosChance or config.DoubleChaosChance,
        }
    end

    return {
        Solo = false,
        IntermissionSeconds = config.IntermissionSeconds,
        VoteSeconds = config.VoteSeconds,
        ReadySeconds = config.ReadySeconds or 3,
        RoundSeconds = config.RoundSeconds,
        PostRoundSeconds = config.PostRoundSeconds,
        WinCoinMultiplier = 1,
        WinXPMultiplier = 1,
        DoubleChaosEvery = config.DoubleChaosEvery,
        DoubleChaosChance = config.DoubleChaosChance,
    }
end

function SoloRules.reward(baseAmount, multiplier)
    return math.max(0, math.floor((baseAmount * multiplier) + 0.5))
end

return SoloRules
