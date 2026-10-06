local AnimationCatalog = {}

-- Roblox-native R15 fallback clips currently used by AI Survivors.
-- Keep IDs centralized so authored project clips can replace them without
-- changing survivor behavior/state logic.
AnimationCatalog.AISurvivor = {
    Idle = 507766666,
    Walk = 507777826,
    Run = 507767714,
    Jump = 507765000,
    Fall = 507767968,
}

function AnimationCatalog.assetId(value)
    local id = math.max(0, math.floor(tonumber(value) or 0))
    return id > 0 and ("rbxassetid://" .. tostring(id)) or ""
end

return AnimationCatalog
