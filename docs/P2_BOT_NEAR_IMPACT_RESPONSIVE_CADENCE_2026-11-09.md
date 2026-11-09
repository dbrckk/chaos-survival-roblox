# P2 — décision IA plus réactive aux avertissements réellement proches

**9 novembre 2026 — branche source uniquement.** `feat/p2-hazard-responsive-bot-brain-20261109` depuis `main@000ff81cf0ecd49691e6d3362f359c6f79c64064`.

## Défaillance de conception vérifiée en lecture du code

Le serveur conserve un seul `startBrain` séquentiel pour au maximum sept bots. `AISurvivorRules.brainCadence(7, "round")` vaut **0,42 s**, même pendant un nouvel avertissement Meteor/Bomb/JumpShock. Les personnages ont déjà un délai de réaction de profil (`ReactionSeconds`, environ 0,12–0,26 s). Un avertissement apparu juste après un passage ne sera donc remarqué qu'au passage suivant ; les réactions d'urgence peuvent paraître lentes. **Aucune fréquence de défaite ni latence réelle n'a encore été mesurée.**

## Intervention ciblée

1. Conserver `AISurvivorRules.brainCadence` inchangé pour la boucle ordinaire et les comportements hors danger.
2. Après chaque passage existant de `startBrain` **pendant `round` seulement**, utiliser `warningParts()`, déjà maintenu par événements de `workspace.ChildAdded/Removed`, pour examiner uniquement les vrais avertissements `MeteorWarning`, `BombWarning` ou `JumpShockWarning`. Pas de second scan du Workspace.
3. Réutiliser `AISurvivorRules.warningDetectionRadius` et `warningDistance` : la proximité doit correspondre à au moins un **bot vivant réellement participant**. Le JumpShock utilise la portée horizontale existante, même si le bot est sur une route élevée. `FreezeWarning` (reaction cosmétique) ne déclenche pas une cadence coûteuse.
4. **Si un avertissement proche est réel ET que le coût mesuré du passage est ≤14 ms**, raccourcir uniquement la prochaine attente de **0,42 à 0,30 s** pour sept bots. Les petits rosters dont la cadence est déjà ≤0,30 s n'accélèrent pas. Le serveur chargé garde la cadence habituelle.
5. Enregistrer deux compteurs serveur dans `AISurvivorService.PerformanceDiagnostics` : `HazardResponsivePasses` (passages accélérés, pas dodges réussis) et `HazardResponsiveLoadDeferrals` (danger proche mais coût trop élevé). Pas de nouvel attribut répliqué, RemoteEvent, tâche, RenderStepped ou modification des dégâts/collisions/physique.

**Charges attendues, non mesurées :** à sept bots, les décisions par seconde passent temporairement d'environ **2,38 à 3,33 passages complets/s** pendant une alerte réellement proche et un serveur suffisamment disponible (+40 % durant cette courte fenêtre). Le garde-fou de 14 ms est une politique de prudence à confronter au MicroProfiler, pas une garantie de performances. **Pas de nouveau système de réaction** : le chemin d'esquive, les raycasts et les délais humains existants demeurent identiques.

## Matrice de réception, prochain jalon

- 1 humain+7 bots, cinq arènes, Meteor/Bomb proche : l'attente de la boucle baisse à 0,30 s ; les bots restent capables de réagir après leur délai humain habituel, sans immobilité prolongée.
- Impact hors de portée de tous les bots : cadence normale 0,42 s, compteurs inchangés.
- JumpShock sur terrasse élevée : proximité horizontale reconnue ; saut toujours piloté par `issueTimedShockJump`, jamais dupliqué par ce changement.
- `FreezeWarning` seul : aucune accélération supplémentaire.
- Serveur sous charge (pass >14 ms) : cadence normale, `HazardResponsiveLoadDeferrals` augmente.
- Lobby, vote, READY et résultat : aucun surcoût de cadence / changement d'interactions.
- Double Chaos, alertes qui apparaissent/disparaissent, décès d'un bot en phase, sortie de session : aucune nouvelle tâche ni fuite ; le cache existant se réconcilie.
- Profiler vraies manches : `AveragePassMs`, `PeakPassMs`, `BotCount`, `HazardResponsivePasses` et `HazardResponsiveLoadDeferrals`, puis comparer survie et esquive par danger. Ne revendiquer ni gain FPS ni victoire sans observation moteur.

## Livraison

**Ne pas fusionner immédiatement.** La version P1 `main@000ff81c...` vient d'être intégrée et attend son **propre** Build Validation / Roblox Open Cloud / publication sur le SHA exact. La P2 reste isolée jusqu'à ce jalon, puis sera fusionnée et certifiée indépendamment. Aucun test unitaire nouveau ni suppression d'un test existant.
