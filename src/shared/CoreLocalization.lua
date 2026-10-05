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
        NEXT_CHAOS_IN = "NEXT CHAOS IN %ds",
        NEXT_CHAOS_SOON = "NEXT CHAOS SOON",
        TOUCH_CONTROLS = "LEFT STICK = MOVE  •  RIGHT BUTTON = JUMP  •  SURVIVE UNTIL 0",
        KEYBOARD_CONTROLS = "WASD = MOVE  •  SPACE = JUMP  •  SURVIVE UNTIL 0",
        GAMEPAD_CONTROLS = "LEFT STICK = MOVE  •  A = JUMP  •  SURVIVE UNTIL 0",
        GO_SUB = "REACT  •  MOVE  •  STAY ALIVE",
        POSITION_YOURSELF = "POSITION YOURSELF",
        ONE_PLAYER_REMAINS = "ONE PLAYER REMAINS",
        JUICE_MASTER_TITLE = "MASTER ROUND",
        JUICE_MASTER_SUB = "Challenge complete • Momentum x%d",
        JUICE_LAST_BREATH_TITLE = "LAST-BREATH SURVIVAL",
        JUICE_LAST_BREATH_SUB = "You escaped with almost no health left",
        JUICE_UNSTOPPABLE = "UNSTOPPABLE x%d",
        JUICE_STREAK_BONUS = "Survival streak bonus +%d coins",
        JUICE_HOT_STREAK = "HOT STREAK x%d",
        JUICE_KEEP_RUN = "KEEP THE RUN ALIVE",
        JUICE_FIRST_TITLE = "SURVIVE THE CHAOS",
        JUICE_FIRST_SUB = "Vote • Move • Climb • Stay alive until the timer hits 0",
        NEAR_MISS_TITLE = "CLOSE CALL!",
        NEAR_MISS_COMBO = "CLOSE CALL  x%d",
        NEAR_MISS_EDGE = "%.1fx EDGE",
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
        YOU_SURVIVED = "YOU SURVIVED",
        ELIMINATED_FEED = "%s was eliminated",
        WAYFIND_ARENA = "ARENA",
        WAYFIND_ARENA_SUB = "VOTE • SURVIVE • ADAPT",
        WAYFIND_PRACTICE = "PRACTICE",
        WAYFIND_PRACTICE_SUB = "BOOST PADS",
        WAYFIND_TIME_TRIAL = "TIME TRIAL",
        WAYFIND_TIME_TRIAL_SUB = "4 CHECKPOINTS",
        MOTION_REDUCED = "MOTION • REDUCED",
        MOTION_FULL = "MOTION • FULL",
        SETTINGS = "SETTINGS",
        INVITE_FRIENDS = "INVITE FRIENDS",
        BRING_BACKUP = "BRING BACKUP",
        CREW_SIGNAL = "CREW SIGNAL",
        PLAY_TOGETHER = "PLAY TOGETHER",
        LAST_CHAOS = "LAST CHAOS",
        SURVIVED_COUNT = "%d / %d SURVIVED",
        CHAOS_PROFILE = "YOUR CHAOS PROFILE",
        PROFILE_STATS = "LVL %d  •  %d WINS  •  %d COINS",
        NEXT_LEVEL_XP = "NEXT LEVEL  •  %d XP TO GO",
        NEXT_LEVEL_READY_SHORT = "NEXT LEVEL READY",
        COLLECTION_PROGRESS = "COLLECTION  %d / %d",
        COLLECTION_SYNCING = "COLLECTION  •  SYNCING",
        CHAOS_RUN = "YOUR CHAOS RUN",
        CHAOS_RUN_COMPLETE = "YOUR CHAOS RUN • COLLECTION COMPLETE",
        RUN_STATS = "LVL %d  •  %d WINS  •  COLLECTION %d/%d",
        RUN_NEXT_LEVEL = "NEXT • LEVEL %d • %d XP TO GO",
        RUN_LEVEL_READY = "LEVEL %d READY",
        FRIEND_JOINED_CREW = "%s JOINED YOUR CREW",
        SOCIAL_REACTION_GG = "GG",
        SOCIAL_REACTION_AGAIN = "AGAIN!",
        SOCIAL_REACTION_WOW = "NO WAY!",
        INVITE_PROMPT_WIN = "Bring your friends into the next Chaos round!",
        INVITE_PROMPT_LOSS = "Bring backup and take the next Chaos together!",
        SHARE_MOMENT = "SHARE THIS MOMENT",
        SHARE_CAPTURING = "CAPTURING...",
        SHARE_UNAVAILABLE = "SHARING UNAVAILABLE",
        SHARE_REASON_LAST_SURVIVOR = "LAST SURVIVOR",
        SHARE_REASON_MASTER = "MASTER ROUND",
        SHARE_REASON_DOUBLE_CHAOS = "DOUBLE CHAOS CLEARED",
        SHARE_REASON_CLUTCH = "CLUTCH SURVIVAL",
        SHARE_REASON_CREW = "CREW MOMENT",
        SHARE_JOINED = "%s JOINED FROM YOUR SHARED MOMENT",
        PRACTICE_BOOST = "TRY BOOST",
        ESCAPE_PAD = "ESCAPE PAD",
        DAILY_REWARD = "DAILY REWARD",
        QUESTS = "QUESTS",
        DAILY_QUESTS = "DAILY QUESTS",
        WEEKLY_CHALLENGES = "WEEKLY CHALLENGES",
        COSMETICS = "COSMETICS",
        LOADOUT = "LOADOUT",
        EQUIPPED = "EQUIPPED",
        EQUIP = "EQUIP",
        SUPPORT = "SUPPORT",
        SUPPORT_GAME = "SUPPORT THE GAME",
        FAIR_PLAY = "COSMETIC ONLY • NO GAMEPLAY ADVANTAGE",
        SUPPORT_PACK = "Support Pack",
        COSMETICS_PERMANENT = "%d COSMETICS • PERMANENT",
        OWNED = "OWNED",
        ACHIEVEMENTS = "ACHIEVEMENTS",
        AWARDS = "AWARDS",
        STYLE = "STYLE",
        WEEKLY_COMPLETE = "WEEKLY COMPLETE",
        QUEST_COMPLETE = "QUEST COMPLETE",
        ACHIEVEMENT_UNLOCKED = "ACHIEVEMENT UNLOCKED",
        REWARD_LINE = "%s   +%d coins   +%d XP",
        COINS_XP = "+%d coins   +%d XP",
        RESULT_EXTRA_STREAK = "STREAK +%d",
        RESULT_EXTRA_SHARDS = "SHARDS +%d",
        RESULT_EXTRA_CHALLENGE = "CHALLENGE +%d",
        RESULT_EXTRA_FLOW = "FLOW +%d",
        RESULT_EXTRA_FUSION = "FUSION +%d",
        RESULT_RUSH_BONUS = "RUSH BONUS",
        RESULT_CLUTCH_TAG = "CLUTCH SURVIVAL",
        RESULT_CHALLENGE_TAG = "CHALLENGE COMPLETE",
        RESULT_SHARDS_TAG = "SHARDS x%d",
        RESULT_CLOSE_CALLS_TAG = "CLOSE CALLS x%d",
        RESULT_MOMENTUM_TAG = "MOMENTUM x%d",
        RESULT_MEDALS_TAG = "MEDALS x%d",
        RESULT_STREAK_TAG = "STREAK x%d",
        RESULT_CREW_ROUNDS = "CREW • %d ROUNDS TOGETHER",
        RESULT_SURVIVOR_COUNT = "%d SURVIVORS",
        RESULT_SOLE_SURVIVOR = "LAST SURVIVOR",
        RESULT_NEXT_TRY = "NEXT TRY • %s",
        RESULT_FIRST_CHAOS = "FIRST CHAOS CLEARED • survive again to build your streak",
        RESULT_MASTER = "MASTER ROUND • challenge complete • momentum x%d",
        RESULT_FUSION_SURVIVED = "%s SURVIVED • FUSION BONUS +%d",
        RESULT_FLOW_CHALLENGE = "FLOW COMBO +%d • CHALLENGE COMPLETE",
        RESULT_FLOW = "FLOW COMBO • pad → shard chain completed",
        RESULT_CHALLENGE_MEDALS = "CHALLENGE COMPLETE • %s",
        RESULT_CHALLENGE = "ROUND CHALLENGE COMPLETE • bonus secured",
        RESULT_MEDALS = "MEDALS • %s",
        RESULT_CLUTCH = "CLUTCH • you survived at critical health",
        RESULT_STREAK = "STREAK x%d • survive again for +%d streak coins",
        RESULT_TIP = "TIP: %s",
        RESULT_DEFAULT_TIP = "TIP: keep moving and react early to warning zones",
        RESULT_MASTERY = "MASTERY",
        RESULT_NEXT_GOAL_READY = "NEXT GOAL • LEVEL %d READY",
        RESULT_NEXT_GOAL = "NEXT GOAL • LEVEL %d • %d XP TO GO",
        STATS_LINE = "LVL %d    🪙 %d    🏆 %d    XP %d/%d",
        QUEST_ROW = "  %s  •  %s  •  +%d coins",
        WEEKLY_ROW = "  %s  •  %s  •  +%d coins +%d XP",
        ACHIEVEMENT_ROW = "%s  •  %s  •  +%d coins",
        NO_DAILY_QUEST = "No daily quest",
        NO_WEEKLY_CHALLENGE = "No weekly challenge",
        DAY_STREAK = "DAY %d STREAK",
        SOUND_ON = "SOUND • ON",
        SOUND_OFF = "SOUND • OFF",
        TEMP_SESSION_TITLE = "TEMPORARY SESSION",
        TEMP_SESSION_BODY = "Progress will not save • rejoin later",
        SAVE_CONFLICT_TITLE = "SAVE PAUSED",
        SAVE_CONFLICT_BODY = "Another session owns your save • rejoin safely",
        SAVE_FAILED_TITLE = "SAVE RETRY NEEDED",
        SAVE_FAILED_BODY = "Keep playing • the game will retry automatically",
        SAVE_PAUSED_SHORT = "PROGRESS NOT SAVING",
        MOVE_CENTER = "MOVE CENTER",
        DANGER = "DANGER",
        ROUND_CHALLENGE = "ROUND CHALLENGE",
        DONE = "DONE",
        FINAL_RUSH = "FINAL RUSH",
        FINAL_RUSH_SECONDS = "FINAL RUSH  %ds",
        FINAL_RUSH_SUB = "LAST 5 SECONDS • PADS RECHARGE FASTER",
        OVERDRIVE = "OVERDRIVE",
        OVERDRIVE_SECONDS = "OVERDRIVE  %ds",
        OVERDRIVE_SUB = "BOOST PADS • SHARD SURGE • GOLDEN SHARD",
        CHAOS_FUSION = "CHAOS FUSION",
        CHAOS_FUSION_SUB = "SURVIVE BOTH HAZARDS",
        SURVIVE_SECONDS = "SURVIVE  %ds",
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
        NEXT_CHAOS_IN = "PROCHAIN CHAOS DANS %ds",
        NEXT_CHAOS_SOON = "PROCHAIN CHAOS BIENTÔT",
        TOUCH_CONTROLS = "JOYSTICK GAUCHE = BOUGER  •  BOUTON DROIT = SAUTER  •  SURVIS JUSQU'À 0",
        KEYBOARD_CONTROLS = "WASD = BOUGER  •  ESPACE = SAUTER  •  SURVIS JUSQU'À 0",
        GAMEPAD_CONTROLS = "JOYSTICK GAUCHE = BOUGER  •  A = SAUTER  •  SURVIS JUSQU'À 0",
        GO_SUB = "RÉAGIS  •  BOUGE  •  RESTE EN VIE",
        POSITION_YOURSELF = "PLACE-TOI",
        ONE_PLAYER_REMAINS = "UN JOUEUR RESTE EN VIE",
        JUICE_MASTER_TITLE = "MANCHE MAÎTRISÉE",
        JUICE_MASTER_SUB = "Défi terminé • Élan x%d",
        JUICE_LAST_BREATH_TITLE = "SURVIE EXTRÊME",
        JUICE_LAST_BREATH_SUB = "Tu t'en es sorti avec presque plus de vie",
        JUICE_UNSTOPPABLE = "INARRÊTABLE x%d",
        JUICE_STREAK_BONUS = "Bonus de série +%d pièces",
        JUICE_HOT_STREAK = "SÉRIE CHAUDE x%d",
        JUICE_KEEP_RUN = "CONTINUE TA SÉRIE",
        JUICE_FIRST_TITLE = "SURVIS AU CHAOS",
        JUICE_FIRST_SUB = "Vote • Bouge • Grimpe • Reste en vie jusqu'à 0",
        NEAR_MISS_TITLE = "C'ÉTAIT JUSTE !",
        NEAR_MISS_COMBO = "DE JUSTESSE  x%d",
        NEAR_MISS_EDGE = "%.1fx LIMITE",
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
        YOU_SURVIVED = "TU AS SURVÉCU",
        ELIMINATED_FEED = "%s a été éliminé",
        WAYFIND_ARENA = "ARÈNE",
        WAYFIND_ARENA_SUB = "VOTE • SURVIS • ADAPTE-TOI",
        WAYFIND_PRACTICE = "ENTRAÎNEMENT",
        WAYFIND_PRACTICE_SUB = "PADS DE BOOST",
        WAYFIND_TIME_TRIAL = "CONTRE-LA-MONTRE",
        WAYFIND_TIME_TRIAL_SUB = "4 CHECKPOINTS",
        MOTION_REDUCED = "MOUVEMENT • RÉDUIT",
        MOTION_FULL = "MOUVEMENT • COMPLET",
        SETTINGS = "RÉGLAGES",
        INVITE_FRIENDS = "INVITER DES AMIS",
        BRING_BACKUP = "APPELLE DU RENFORT",
        CREW_SIGNAL = "SIGNAL D'ÉQUIPE",
        PLAY_TOGETHER = "JOUEZ ENSEMBLE",
        LAST_CHAOS = "DERNIER CHAOS",
        SURVIVED_COUNT = "%d / %d ONT SURVÉCU",
        CHAOS_PROFILE = "TON PROFIL CHAOS",
        PROFILE_STATS = "NIV %d  •  %d VICTOIRES  •  %d PIÈCES",
        NEXT_LEVEL_XP = "NIVEAU SUIVANT  •  %d XP RESTANTS",
        NEXT_LEVEL_READY_SHORT = "NIVEAU SUIVANT PRÊT",
        COLLECTION_PROGRESS = "COLLECTION  %d / %d",
        COLLECTION_SYNCING = "COLLECTION  •  SYNCHRONISATION",
        CHAOS_RUN = "TA COURSE CHAOS",
        CHAOS_RUN_COMPLETE = "TA COURSE CHAOS • COLLECTION TERMINÉE",
        RUN_STATS = "NIV %d  •  %d VICTOIRES  •  COLLECTION %d/%d",
        RUN_NEXT_LEVEL = "SUIVANT • NIVEAU %d • %d XP RESTANTS",
        RUN_LEVEL_READY = "NIVEAU %d PRÊT",
        FRIEND_JOINED_CREW = "%s A REJOINT TON ÉQUIPE",
        SOCIAL_REACTION_GG = "GG",
        SOCIAL_REACTION_AGAIN = "ENCORE !",
        SOCIAL_REACTION_WOW = "INCROYABLE !",
        INVITE_PROMPT_WIN = "Invite tes amis pour le prochain Chaos !",
        INVITE_PROMPT_LOSS = "Appelle du renfort et affrontez le prochain Chaos ensemble !",
        SHARE_MOMENT = "PARTAGER CE MOMENT",
        SHARE_CAPTURING = "CAPTURE...",
        SHARE_UNAVAILABLE = "PARTAGE INDISPONIBLE",
        SHARE_REASON_LAST_SURVIVOR = "DERNIER SURVIVANT",
        SHARE_REASON_MASTER = "MANCHE MAÎTRISÉE",
        SHARE_REASON_DOUBLE_CHAOS = "DOUBLE CHAOS RÉUSSI",
        SHARE_REASON_CLUTCH = "SURVIE EXTRÊME",
        SHARE_REASON_CREW = "MOMENT D'ÉQUIPE",
        SHARE_JOINED = "%s A REJOINT TON MOMENT PARTAGÉ",
        PRACTICE_BOOST = "ESSAIE LE BOOST",
        ESCAPE_PAD = "PAD D'ÉVASION",
        DAILY_REWARD = "RÉCOMPENSE QUOTIDIENNE",
        QUESTS = "QUÊTES",
        DAILY_QUESTS = "QUÊTES QUOTIDIENNES",
        WEEKLY_CHALLENGES = "DÉFIS HEBDOMADAIRES",
        COSMETICS = "COSMÉTIQUES",
        LOADOUT = "ÉQUIPEMENT",
        EQUIPPED = "ÉQUIPÉ",
        EQUIP = "ÉQUIPER",
        SUPPORT = "SOUTENIR",
        SUPPORT_GAME = "SOUTENIR LE JEU",
        FAIR_PLAY = "COSMÉTIQUE UNIQUEMENT • AUCUN AVANTAGE DE JEU",
        SUPPORT_PACK = "Pack soutien",
        COSMETICS_PERMANENT = "%d COSMÉTIQUES • PERMANENTS",
        OWNED = "POSSÉDÉ",
        ACHIEVEMENTS = "SUCCÈS",
        AWARDS = "SUCCÈS",
        STYLE = "STYLE",
        WEEKLY_COMPLETE = "DÉFI HEBDOMADAIRE TERMINÉ",
        QUEST_COMPLETE = "QUÊTE TERMINÉE",
        ACHIEVEMENT_UNLOCKED = "SUCCÈS DÉBLOQUÉ",
        REWARD_LINE = "%s   +%d pièces   +%d XP",
        COINS_XP = "+%d pièces   +%d XP",
        RESULT_EXTRA_STREAK = "SÉRIE +%d",
        RESULT_EXTRA_SHARDS = "ÉCLATS +%d",
        RESULT_EXTRA_CHALLENGE = "DÉFI +%d",
        RESULT_EXTRA_FLOW = "FLUIDITÉ +%d",
        RESULT_EXTRA_FUSION = "FUSION +%d",
        RESULT_RUSH_BONUS = "BONUS RUSH",
        RESULT_CLUTCH_TAG = "SURVIE EXTRÊME",
        RESULT_CHALLENGE_TAG = "DÉFI TERMINÉ",
        RESULT_SHARDS_TAG = "ÉCLATS x%d",
        RESULT_CLOSE_CALLS_TAG = "RISQUES x%d",
        RESULT_MOMENTUM_TAG = "ÉLAN x%d",
        RESULT_MEDALS_TAG = "MÉDAILLES x%d",
        RESULT_STREAK_TAG = "SÉRIE x%d",
        RESULT_CREW_ROUNDS = "ÉQUIPE • %d MANCHES ENSEMBLE",
        RESULT_SURVIVOR_COUNT = "%d SURVIVANTS",
        RESULT_SOLE_SURVIVOR = "DERNIER SURVIVANT",
        RESULT_NEXT_TRY = "PROCHAIN ESSAI • %s",
        RESULT_FIRST_CHAOS = "PREMIER CHAOS RÉUSSI • survis encore pour construire ta série",
        RESULT_MASTER = "MANCHE MAÎTRISÉE • défi terminé • élan x%d",
        RESULT_FUSION_SURVIVED = "FUSION %s RÉUSSIE • BONUS +%d",
        RESULT_FLOW_CHALLENGE = "COMBO FLUIDITÉ +%d • DÉFI TERMINÉ",
        RESULT_FLOW = "COMBO FLUIDITÉ • chaîne pad → éclat réussie",
        RESULT_CHALLENGE_MEDALS = "DÉFI TERMINÉ • %s",
        RESULT_CHALLENGE = "DÉFI DE MANCHE TERMINÉ • bonus obtenu",
        RESULT_MEDALS = "MÉDAILLES • %s",
        RESULT_CLUTCH = "SURVIE EXTRÊME • tu as survécu avec très peu de vie",
        RESULT_STREAK = "SÉRIE x%d • survis encore pour +%d pièces de série",
        RESULT_TIP = "CONSEIL : %s",
        RESULT_DEFAULT_TIP = "CONSEIL : continue de bouger et réagis tôt aux zones d'alerte",
        RESULT_MASTERY = "MAÎTRISE",
        RESULT_NEXT_GOAL_READY = "PROCHAIN OBJECTIF • NIVEAU %d PRÊT",
        RESULT_NEXT_GOAL = "PROCHAIN OBJECTIF • NIVEAU %d • %d XP RESTANTS",
        STATS_LINE = "NIV %d    🪙 %d    🏆 %d    XP %d/%d",
        QUEST_ROW = "  %s  •  %s  •  +%d pièces",
        WEEKLY_ROW = "  %s  •  %s  •  +%d pièces +%d XP",
        ACHIEVEMENT_ROW = "%s  •  %s  •  +%d pièces",
        NO_DAILY_QUEST = "Aucune quête quotidienne",
        NO_WEEKLY_CHALLENGE = "Aucun défi hebdomadaire",
        DAY_STREAK = "SÉRIE DE %d JOURS",
        SOUND_ON = "SON • ACTIVÉ",
        SOUND_OFF = "SON • COUPÉ",
        TEMP_SESSION_TITLE = "SESSION TEMPORAIRE",
        TEMP_SESSION_BODY = "La progression ne sera pas sauvegardée • reconnecte-toi plus tard",
        SAVE_CONFLICT_TITLE = "SAUVEGARDE EN PAUSE",
        SAVE_CONFLICT_BODY = "Une autre session utilise ta sauvegarde • reconnecte-toi proprement",
        SAVE_FAILED_TITLE = "NOUVEL ESSAI DE SAUVEGARDE",
        SAVE_FAILED_BODY = "Continue de jouer • le jeu réessaiera automatiquement",
        SAVE_PAUSED_SHORT = "PROGRESSION NON SAUVEGARDÉE",
        MOVE_CENTER = "REJOINS LE CENTRE",
        DANGER = "DANGER",
        ROUND_CHALLENGE = "DÉFI DE MANCHE",
        DONE = "RÉUSSI",
        FINAL_RUSH = "SPRINT FINAL",
        FINAL_RUSH_SECONDS = "SPRINT FINAL  %ds",
        FINAL_RUSH_SUB = "5 DERNIÈRES SECONDES • PADS PLUS RAPIDES",
        OVERDRIVE = "SURCHARGE",
        OVERDRIVE_SECONDS = "SURCHARGE  %ds",
        OVERDRIVE_SUB = "PADS BOOSTÉS • PLUS D'ÉCLATS • ÉCLAT DORÉ",
        CHAOS_FUSION = "FUSION CHAOS",
        CHAOS_FUSION_SUB = "SURVIS AUX DEUX DANGERS",
        SURVIVE_SECONDS = "SURVIS  %ds",
    },
}

local HAZARDS = {
    en = {
        Meteors = {name = "METEOR SHOWER", action = "DODGE", hint = "AVOID THE ORANGE WARNING CIRCLES"},
        Bombs = {name = "BOMB RAIN", action = "MOVE OUT", hint = "LEAVE RED MARKERS BEFORE THEY EXPLODE"},
        RisingLava = {name = "RISING LAVA", action = "CLIMB", hint = "CLIMB EARLY AND STAY ABOVE THE LAVA"},
        LowGravity = {name = "MOON GRAVITY", action = "SHORT JUMPS", hint = "USE SHORT JUMPS AND STAY OVER THE ARENA"},
        DisappearingPlatforms = {name = "VANISHING PLATFORMS", action = "KEEP MOVING", hint = "MOVE BEFORE FLASHING PLATFORMS DISAPPEAR"},
        Tornado = {name = "TORNADO", action = "KEEP DISTANCE", hint = "KEEP YOUR DISTANCE FROM THE TORNADO"},
        Freeze = {name = "FREEZE", action = "KEEP MOVING", hint = "KEEP MOVING BETWEEN FREEZE PULSES"},
        SpeedSurge = {name = "SPEED SURGE", action = "CONTROL", hint = "CONTROL YOUR SPEED NEAR THE EDGES"},
        Darkness = {name = "BLACKOUT", action = "FOLLOW LIGHT", hint = "FOLLOW THE BRIGHT SAFE ROUTES"},
        ShrinkingArena = {name = "SHRINKING ARENA", action = "CENTER", hint = "MOVE TOWARD THE CENTER AS THE ARENA SHRINKS"},
        JumpShock = {name = "SHOCKWAVE", action = "BACK OFF", hint = "GIVE THE BLUE SHOCKWAVE EXTRA SPACE"},
    },
    fr = {
        Meteors = {name = "PLUIE DE MÉTÉORES", action = "ESQUIVE", hint = "ÉVITE LES CERCLES D'ALERTE ORANGE"},
        Bombs = {name = "PLUIE DE BOMBES", action = "ÉCARTE-TOI", hint = "QUITTE LES ZONES ROUGES AVANT L'EXPLOSION"},
        RisingLava = {name = "LAVE MONTANTE", action = "MONTE", hint = "MONTE VITE ET RESTE AU-DESSUS DE LA LAVE"},
        LowGravity = {name = "GRAVITÉ LUNAIRE", action = "PETITS SAUTS", hint = "FAIS DE PETITS SAUTS ET RESTE AU-DESSUS DE L'ARÈNE"},
        DisappearingPlatforms = {name = "PLATEFORMES INSTABLES", action = "BOUGE", hint = "BOUGE AVANT QUE LES PLATEFORMES CLIGNOTANTES DISPARAISSENT"},
        Tornado = {name = "TORNADE", action = "GARDE TES DISTANCES", hint = "GARDE TES DISTANCES AVEC LA TORNADE"},
        Freeze = {name = "GEL", action = "BOUGE", hint = "CONTINUE DE BOUGER ENTRE LES IMPULSIONS DE GEL"},
        SpeedSurge = {name = "ACCÉLÉRATION", action = "CONTRÔLE", hint = "CONTRÔLE TA VITESSE PRÈS DES BORDS"},
        Darkness = {name = "BLACKOUT", action = "SUIS LA LUMIÈRE", hint = "SUIS LES ROUTES LUMINEUSES"},
        ShrinkingArena = {name = "ARÈNE QUI RÉTRÉCIT", action = "CENTRE", hint = "REJOINS LE CENTRE PENDANT QUE L'ARÈNE RÉTRÉCIT"},
        JumpShock = {name = "ONDE DE CHOC", action = "ÉCARTE-TOI", hint = "GARDE TES DISTANCES AVEC L'ONDE BLEUE"},
    },
}

local ARENA_COPY = {
    en = {
        Classic = {
            name = "CLASSIC GRID",
            strategy = "Balanced routes • switch height when danger closes in",
            mechanicName = "ESCAPE PADS",
            mechanicHint = "Blue pads launch you away from the center when a route collapses",
        },
        Towers = {
            name = "TOWER RUN",
            strategy = "Vertical arena • high ground helps until escape routes narrow",
            mechanicName = "UPDRAFT PADS",
            mechanicHint = "Cyan pads launch you upward to reopen vertical escape routes",
        },
        Crossroads = {
            name = "CROSSROADS",
            strategy = "Four escape lanes • avoid committing to a dead end too early",
            mechanicName = "LANE BOOSTERS",
            mechanicHint = "Pink pads accelerate you along a lane so you can switch routes quickly",
        },
        Orbital = {
            name = "ORBITAL RING",
            strategy = "Circular routes • keep moving around the ring instead of getting boxed in",
            mechanicName = "ORBIT BOOSTERS",
            mechanicHint = "Green pads push you around the ring to keep circular routes flowing",
        },
    },
    fr = {
        Classic = {
            name = "GRILLE CLASSIQUE",
            strategy = "Routes équilibrées • change de hauteur quand le danger se referme",
            mechanicName = "PADS D'ÉVASION",
            mechanicHint = "Les pads bleus t'éloignent du centre quand une route devient dangereuse",
        },
        Towers = {
            name = "TOURS",
            strategy = "Arène verticale • prends de la hauteur sans te faire enfermer",
            mechanicName = "PADS ASCENDANTS",
            mechanicHint = "Les pads cyan te propulsent vers le haut pour rouvrir des voies de fuite",
        },
        Crossroads = {
            name = "CARREFOUR",
            strategy = "Quatre voies de fuite • ne t'engage pas trop tôt dans une impasse",
            mechanicName = "BOOSTERS DE VOIE",
            mechanicHint = "Les pads roses t'accélèrent le long d'une voie pour changer vite de route",
        },
        Orbital = {
            name = "ANNEAU ORBITAL",
            strategy = "Routes circulaires • continue de tourner pour éviter d'être bloqué",
            mechanicName = "BOOSTERS ORBITAUX",
            mechanicHint = "Les pads verts te poussent autour de l'anneau pour maintenir ton mouvement",
        },
    },
}

local ARENA_ALIASES = {
    ["Classic"] = "Classic",
    ["CLASSIC GRID"] = "Classic",
    ["Towers"] = "Towers",
    ["TOWER RUN"] = "Towers",
    ["Crossroads"] = "Crossroads",
    ["CROSSROADS"] = "Crossroads",
    ["Orbital"] = "Orbital",
    ["ORBITAL RING"] = "Orbital",
}

local function arenaRecord(localeId, arenaIdOrName)
    local language = CoreLocalization.language(localeId)
    local raw = tostring(arenaIdOrName or "")
    local id = ARENA_ALIASES[raw] or raw
    local record = ARENA_COPY[language] and ARENA_COPY[language][id]
    return record or ARENA_COPY.en[id]
end

local QUEST_TITLES = {
    en = {
        PLAY_3 = "Play 3 rounds",
        SURVIVE_2 = "Survive 2 rounds",
        DOUBLE_CHAOS = "Survive a Double Chaos",
        EARN_75 = "Earn 75 round coins",
        PLAY_5 = "Play 5 rounds",
        SURVIVE_3 = "Survive 3 rounds",
        COLLECT_6 = "Collect 6 Chaos Shards",
        PLAY_20 = "Play 20 rounds",
        SURVIVE_10 = "Survive 10 rounds",
        COLLECT_30 = "Collect 30 Chaos Shards",
        DOUBLE_3 = "Survive 3 Double Chaos rounds",
        EARN_500 = "Earn 500 round coins",
    },
    fr = {
        PLAY_3 = "Joue 3 manches",
        SURVIVE_2 = "Survis à 2 manches",
        DOUBLE_CHAOS = "Survis à un Double Chaos",
        EARN_75 = "Gagne 75 pièces en manche",
        PLAY_5 = "Joue 5 manches",
        SURVIVE_3 = "Survis à 3 manches",
        COLLECT_6 = "Ramasse 6 éclats du Chaos",
        PLAY_20 = "Joue 20 manches",
        SURVIVE_10 = "Survis à 10 manches",
        COLLECT_30 = "Ramasse 30 éclats du Chaos",
        DOUBLE_3 = "Survis à 3 manches Double Chaos",
        EARN_500 = "Gagne 500 pièces en manche",
    },
}

local ACHIEVEMENT_COPY = {
    en = {
        FIRST_SURVIVOR = {"First Survivor", "Survive your first round"},
        VETERAN_10 = {"Getting Serious", "Play 10 rounds"},
        SURVIVOR_10 = {"Hard To Kill", "Survive 10 rounds"},
        CHAOS_TAMER = {"Chaos Tamer", "Survive 3 Double Chaos rounds"},
        LEVEL_5 = {"Rising Star", "Reach level 5"},
        STREAK_7 = {"Seven Days Strong", "Reach a 7-day login streak"},
    },
    fr = {
        FIRST_SURVIVOR = {"Premier survivant", "Survis à ta première manche"},
        VETERAN_10 = {"Ça devient sérieux", "Joue 10 manches"},
        SURVIVOR_10 = {"Dur à éliminer", "Survis à 10 manches"},
        CHAOS_TAMER = {"Maître du Chaos", "Survis à 3 manches Double Chaos"},
        LEVEL_5 = {"Étoile montante", "Atteins le niveau 5"},
        STREAK_7 = {"Sept jours d'affilée", "Atteins une série de connexion de 7 jours"},
    },
}

local MEDAL_COPY = {
    en = {
        ["FIRST CHAOS"] = "FIRST CHAOS",
        ["SHARD HUNTER"] = "SHARD HUNTER",
        ["MOBILITY ACE"] = "MOBILITY ACE",
        ["DAREDEVIL"] = "DAREDEVIL",
        ["OVERDRIVE RIDER"] = "OVERDRIVE RIDER",
        ["MOMENTUM MASTER"] = "MOMENTUM MASTER",
        ["CLUTCH"] = "CLUTCH",
    },
    fr = {
        ["FIRST CHAOS"] = "PREMIER CHAOS",
        ["SHARD HUNTER"] = "CHASSEUR D'ÉCLATS",
        ["MOBILITY ACE"] = "AS DE LA MOBILITÉ",
        ["DAREDEVIL"] = "CASSE-COU",
        ["OVERDRIVE RIDER"] = "PILOTE SURCHARGE",
        ["MOMENTUM MASTER"] = "MAÎTRE DE L'ÉLAN",
        ["CLUTCH"] = "SURVIE EXTRÊME",
    },
}

local CHALLENGE_SHORT = {
    en = {
        FIRST_SURVIVAL = "STAY ALIVE",
        SHARD_HUNT = "SHARDS",
        MOBILITY_MASTER = "PADS",
        DANGER_DANCE = "CLOSE CALL",
        MOMENTUM_3 = "MOMENTUM",
        FLOW_CHAIN = "FLOW",
        MIX_IT_UP = "VARIETY",
    },
    fr = {
        FIRST_SURVIVAL = "RESTE EN VIE",
        SHARD_HUNT = "ÉCLATS",
        MOBILITY_MASTER = "PADS",
        DANGER_DANCE = "RISQUE",
        MOMENTUM_3 = "ÉLAN",
        FLOW_CHAIN = "FLUIDITÉ",
        MIX_IT_UP = "VARIÉTÉ",
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

function CoreLocalization.hazardAction(localeId, disasterId)
    local language = CoreLocalization.language(localeId)
    local id = tostring(disasterId or "")
    local record = HAZARDS[language] and HAZARDS[language][id]
    record = record or HAZARDS.en[id]
    return record and record.action or nil
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

function CoreLocalization.arenaName(localeId, arenaIdOrName, fallback)
    local record = arenaRecord(localeId, arenaIdOrName)
    return record and record.name or fallback
end

function CoreLocalization.arenaStrategy(localeId, arenaIdOrName, fallback)
    local record = arenaRecord(localeId, arenaIdOrName)
    return record and record.strategy or fallback
end

function CoreLocalization.arenaMechanicName(localeId, arenaIdOrName, fallback)
    local record = arenaRecord(localeId, arenaIdOrName)
    return record and record.mechanicName or fallback
end

function CoreLocalization.arenaMechanicHint(localeId, arenaIdOrName, fallback)
    local record = arenaRecord(localeId, arenaIdOrName)
    return record and record.mechanicHint or fallback
end

function CoreLocalization.questTitle(localeId, questId, fallback)
    local language = CoreLocalization.language(localeId)
    local id = tostring(questId or "")
    return (QUEST_TITLES[language] and QUEST_TITLES[language][id])
        or QUEST_TITLES.en[id]
        or fallback
end

function CoreLocalization.achievementTitle(localeId, achievementId, fallback)
    local language = CoreLocalization.language(localeId)
    local id = tostring(achievementId or "")
    local record = ACHIEVEMENT_COPY[language] and ACHIEVEMENT_COPY[language][id]
    record = record or ACHIEVEMENT_COPY.en[id]
    return record and record[1] or fallback
end

function CoreLocalization.achievementDescription(localeId, achievementId, fallback)
    local language = CoreLocalization.language(localeId)
    local id = tostring(achievementId or "")
    local record = ACHIEVEMENT_COPY[language] and ACHIEVEMENT_COPY[language][id]
    record = record or ACHIEVEMENT_COPY.en[id]
    return record and record[2] or fallback
end

function CoreLocalization.medal(localeId, medalName)
    local language = CoreLocalization.language(localeId)
    local key = tostring(medalName or "")
    return (MEDAL_COPY[language] and MEDAL_COPY[language][key])
        or MEDAL_COPY.en[key]
        or key
end

function CoreLocalization.challengeShort(localeId, challengeId, fallback)
    local language = CoreLocalization.language(localeId)
    local id = tostring(challengeId or "")
    return (CHALLENGE_SHORT[language] and CHALLENGE_SHORT[language][id])
        or CHALLENGE_SHORT.en[id]
        or fallback
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
