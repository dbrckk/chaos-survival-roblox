local CoreLocalization = {}

local TEXT = {
    en = {
        ENTER_ARENA = "ENTER THE ARENA",
        SYNCING_PROGRESS = "SYNCING PROGRESS",
        READY = "READY",
        ENTERING_ARENA = "ENTERING ARENA",
        SURVIVE_ADAPT_ESCAPE = "SURVIVE  •  ADAPT  •  ESCAPE",
        SURVIVE_ZERO = "SURVIVE UNTIL 0",
        SURVIVE = "SURVIVE",
        VOTE_TITLE = "CHOOSE THE NEXT CHAOS",
        YOUR_CHOICE_WON = "YOUR CHOICE WON",
        CHAOS_SELECTED = "CHAOS SELECTED",
        GET_READY = "GET READY",
        SURVIVORS_READY = "%d SURVIVORS READY  •  SURVIVE UNTIL 0",
        SURVIVORS = "%d SURVIVORS  •  SURVIVE UNTIL 0",
        SURVIVORS_JOINING = "SURVIVORS JOINING",
        SURVIVOR_COUNT = "%d SURVIVORS",
        ALIVE_COUNT = "%d / %d ALIVE",
        SHARD_ONE = "SHARD  1",
        SHARDS_COUNT = "SHARDS  %d",
        STAY_ALIVE = "STAY ALIVE",
        STAY_ALERT = "STAY ALERT",
        INTENSE = "INTENSE",
        FASTER = "FASTER",
        TOUCH_CONTROLS = "LEFT STICK = MOVE  •  RIGHT BUTTON = JUMP  •  SURVIVE UNTIL 0",
        GO_SUB = "REACT  •  MOVE  •  STAY ALIVE",
        VOTE_SOLO = "YOUR VOTE DECIDES  •  TAP A CHAOS",
        VOTE_MULTI = "TAP A CHAOS TO VOTE",
        VOTE_SAVED = "VOTE SAVED",
        VOTED = "VOTED",
        YOUR_VOTE = "YOUR VOTE",
        LEADING = "LEADING",
        CHOOSE = "CHOOSE",
        TOP = "TOP",
        TAP = "TAP",
        VOTE_ONE = "%d VOTE",
        VOTE_MANY = "%d VOTES",
        NEXT = "NEXT",
        SPECTATING = "SPECTATING  %s",
        JOINING_NEXT = "JOINING NEXT ROUND  •  %s",
        ELIMINATED_WAITING = "ELIMINATED • WAITING FOR NEXT ROUND",
        JOINING_WAITING = "JOINING NEXT ROUND • WAITING FOR SURVIVORS",
        ALIVE_SHORT = "%d ALIVE",
        SURVIVOR_LABEL = "SURVIVOR",
        MOTION_REDUCED = "MOTION • REDUCED",
        MOTION_FULL = "MOTION • FULL",
    },
    fr = {
        ENTER_ARENA = "ENTRE DANS L'ARÈNE",
        SYNCING_PROGRESS = "SYNCHRONISATION",
        READY = "PRÊT",
        ENTERING_ARENA = "ENTRÉE DANS L'ARÈNE",
        SURVIVE_ADAPT_ESCAPE = "SURVIS  •  ADAPTE-TOI  •  ÉCHAPPE-TOI",
        SURVIVE_ZERO = "SURVIS JUSQU'À 0",
        SURVIVE = "SURVIS",
        VOTE_TITLE = "CHOISIS LE PROCHAIN CHAOS",
        YOUR_CHOICE_WON = "TON CHOIX A GAGNÉ",
        CHAOS_SELECTED = "CHAOS SÉLECTIONNÉ",
        GET_READY = "PRÉPARE-TOI",
        SURVIVORS_READY = "%d SURVIVANTS PRÊTS  •  SURVIS JUSQU'À 0",
        SURVIVORS = "%d SURVIVANTS  •  SURVIS JUSQU'À 0",
        SURVIVORS_JOINING = "SURVIVANTS EN APPROCHE",
        SURVIVOR_COUNT = "%d SURVIVANTS",
        ALIVE_COUNT = "%d / %d EN VIE",
        SHARD_ONE = "ÉCLAT  1",
        SHARDS_COUNT = "ÉCLATS  %d",
        STAY_ALIVE = "RESTE EN VIE",
        STAY_ALERT = "RESTE VIGILANT",
        INTENSE = "INTENSE",
        FASTER = "PLUS RAPIDE",
        TOUCH_CONTROLS = "JOYSTICK GAUCHE = BOUGER  •  BOUTON DROIT = SAUTER  •  SURVIS JUSQU'À 0",
        GO_SUB = "RÉAGIS  •  BOUGE  •  RESTE EN VIE",
        VOTE_SOLO = "TON VOTE DÉCIDE  •  CHOISIS UN CHAOS",
        VOTE_MULTI = "CHOISIS UN CHAOS POUR VOTER",
        VOTE_SAVED = "VOTE ENREGISTRÉ",
        VOTED = "VOTÉ",
        YOUR_VOTE = "TON VOTE",
        LEADING = "EN TÊTE",
        CHOOSE = "CHOISIS",
        TOP = "1ER",
        TAP = "TOUCHE",
        VOTE_ONE = "%d VOTE",
        VOTE_MANY = "%d VOTES",
        NEXT = "SUIVANT",
        SPECTATING = "TU REGARDES  %s",
        JOINING_NEXT = "PROCHAINE MANCHE  •  %s",
        ELIMINATED_WAITING = "ÉLIMINÉ • PROCHAINE MANCHE BIENTÔT",
        JOINING_WAITING = "PROCHAINE MANCHE • EN ATTENTE DES SURVIVANTS",
        ALIVE_SHORT = "%d EN VIE",
        SURVIVOR_LABEL = "SURVIVANT",
        MOTION_REDUCED = "MOUVEMENT • RÉDUIT",
        MOTION_FULL = "MOUVEMENT • COMPLET",
    },
}

local HAZARDS = {
    en = {
        Meteors = {name = "METEOR SHOWER", hint = "AVOID THE ORANGE WARNING CIRCLES"},
        Bombs = {name = "BOMB RAIN", hint = "LEAVE RED MARKERS BEFORE THEY EXPLODE"},
        RisingLava = {name = "RISING LAVA", hint = "CLIMB EARLY AND STAY ABOVE THE LAVA"},
        LowGravity = {name = "MOON GRAVITY", hint = "USE SHORT JUMPS AND STAY OVER THE ARENA"},
        DisappearingPlatforms = {name = "VANISHING PLATFORMS", hint = "MOVE BEFORE FLASHING PLATFORMS DISAPPEAR"},
        Tornado = {name = "TORNADO", hint = "KEEP YOUR DISTANCE FROM THE TORNADO"},
        Freeze = {name = "FREEZE", hint = "KEEP MOVING BETWEEN FREEZE PULSES"},
        SpeedSurge = {name = "SPEED SURGE", hint = "CONTROL YOUR SPEED NEAR THE EDGES"},
        Darkness = {name = "BLACKOUT", hint = "FOLLOW THE BRIGHT SAFE ROUTES"},
        ShrinkingArena = {name = "SHRINKING ARENA", hint = "MOVE TOWARD THE CENTER AS THE ARENA SHRINKS"},
        JumpShock = {name = "SHOCKWAVE", hint = "GIVE THE BLUE SHOCKWAVE EXTRA SPACE"},
    },
    fr = {
        Meteors = {name = "PLUIE DE MÉTÉORES", hint = "ÉVITE LES CERCLES D'ALERTE ORANGE"},
        Bombs = {name = "PLUIE DE BOMBES", hint = "QUITTE LES ZONES ROUGES AVANT L'EXPLOSION"},
        RisingLava = {name = "LAVE MONTANTE", hint = "MONTE VITE ET RESTE AU-DESSUS DE LA LAVE"},
        LowGravity = {name = "GRAVITÉ LUNAIRE", hint = "FAIS DE PETITS SAUTS ET RESTE AU-DESSUS DE L'ARÈNE"},
        DisappearingPlatforms = {name = "PLATEFORMES INSTABLES", hint = "BOUGE AVANT QUE LES PLATEFORMES CLIGNOTANTES DISPARAISSENT"},
        Tornado = {name = "TORNADE", hint = "GARDE TES DISTANCES AVEC LA TORNADE"},
        Freeze = {name = "GEL", hint = "CONTINUE DE BOUGER ENTRE LES IMPULSIONS DE GEL"},
        SpeedSurge = {name = "ACCÉLÉRATION", hint = "CONTRÔLE TA VITESSE PRÈS DES BORDS"},
        Darkness = {name = "BLACKOUT", hint = "SUIS LES ROUTES LUMINEUSES"},
        ShrinkingArena = {name = "ARÈNE QUI RÉTRÉCIT", hint = "REJOINS LE CENTRE PENDANT QUE L'ARÈNE RÉTRÉCIT"},
        JumpShock = {name = "ONDE DE CHOC", hint = "GARDE TES DISTANCES AVEC L'ONDE BLEUE"},
    },
}

local COACH_FR = {
    ["HOW TO PLAY  •  SURVIVE UNTIL 0  •  MOVE + JUMP  •  SHARDS = BONUS"] =
        "COMMENT JOUER  •  SURVIS JUSQU'À 0  •  BOUGE + SAUTE  •  ÉCLATS = BONUS",
    ["ROUND GOAL  •  SURVIVE UNTIL 0  •  AVOID RED/ORANGE WARNINGS"] =
        "OBJECTIF  •  SURVIS JUSQU'À 0  •  ÉVITE LES ALERTES ROUGES/ORANGE",
    ["VOTE  •  TAP THE CHAOS YOU WANT TO FACE"] =
        "VOTE  •  TOUCHE LE CHAOS QUE TU VEUX AFFRONTER",
    ["ROUND GOAL  •  SURVIVE UNTIL 0  •  AVOID THE HAZARD  •  SHARDS = BONUS"] =
        "OBJECTIF  •  SURVIS JUSQU'À 0  •  ÉVITE LE DANGER  •  ÉCLATS = BONUS",
    ["GET READY  •  SURVIVE UNTIL 0  •  WATCH THE HAZARD WARNING"] =
        "PRÉPARE-TOI  •  SURVIS JUSQU'À 0  •  REPÈRE L'ALERTE DU DANGER",
}

function CoreLocalization.language(localeId)
    local locale = string.lower(tostring(localeId or ""))
    if string.sub(locale, 1, 2) == "fr" then
        return "fr"
    end
    return "en"
end

function CoreLocalization.text(localeId, key, ...)
    local language = CoreLocalization.language(localeId)
    local value = (TEXT[language] and TEXT[language][key])
        or TEXT.en[key]
        or tostring(key)

    if select("#", ...) > 0 then
        return string.format(value, ...)
    end
    return value
end

function CoreLocalization.hazardName(localeId, disasterId)
    local language = CoreLocalization.language(localeId)
    local id = tostring(disasterId or "")
    local record = HAZARDS[language] and HAZARDS[language][id]
    record = record or HAZARDS.en[id]
    return record and record.name or nil
end

function CoreLocalization.hazardHint(localeId, disasterId)
    local language = CoreLocalization.language(localeId)
    local id = tostring(disasterId or "")
    local record = HAZARDS[language] and HAZARDS[language][id]
    record = record or HAZARDS.en[id]
    return record and record.hint or nil
end

function CoreLocalization.hazardTitle(localeId, disasterIds, fallback)
    if type(disasterIds) ~= "table" or #disasterIds == 0 then
        return fallback
    end

    local names = {}
    for _, id in ipairs(disasterIds) do
        table.insert(
            names,
            CoreLocalization.hazardName(localeId, id) or tostring(id)
        )
    end
    return table.concat(names, " + ")
end

function CoreLocalization.coach(localeId, value)
    if value == nil then
        return nil
    end
    if CoreLocalization.language(localeId) == "fr" then
        return COACH_FR[value] or value
    end
    return value
end

return CoreLocalization
