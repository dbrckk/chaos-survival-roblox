# Navigation des bots : vraies barrières Skybridge bloquantes

**5 novembre 2026 — code modifié, pas encore publié.** Dépôt `dbrckk/chaos-survival-roblox`, base `175593b33d1579b366bd1df0e7e30a9d184c9b16`.

## Défaut identifié dans les sources

Les Skybridges Towers restent physiquement collidables pendant que les portiques passent par `Warning`, `Raising`, `Raised` ou `Lowering`. Mais la règle d'admissibilité commune de navigation `AISurvivorRules.platformAvailable` n'examinait que `CanCollide`, `Transparency`, `CollapsePhase`. L'ancienne exclusion des volets n'existait que pour un mode de traversée dédié `targetIsSkyrail`; les bots choisissaient donc des destinations ordinairement sûres mais **inaccessibles à cause du volet**, ce qui les bloquait.

## Correction réelle

1. La règle centrale accepte maintenant un quatrième argument optionnel `shutterPhase` : `nil` et `Idle` seuls sont considérés ouverts. Les états `Warning`, `Raising`, `Raised` et `Lowering` interdisent une **nouvelle destination**, sans modifier les collisions ni les portiques. Les appels historiques à trois arguments restent compatibles.
2. **16 appels** du service de bots consultent désormais le vrai `BridgeShutterPhase` de chaque Part : liste des candidats, voisin de fuite en hauteur, scoring, socialisation, routes physiques, contrôle de destination, saut entre deux étages, récupération après un blocage et vérification du sol. Un bot peut toujours quitter un pont fermé grâce à `skybridgeShutterEscape`, qui conserve son délai de réaction humain.
3. Le sol physique propre au bot est aussi vérifié avant de le faire suivre un autre avatar sur une route élevée. Une Skybridge qui ferme n'est jamais considérée comme un appui social valide.
4. L'ancien contrôle réservé aux seuls `targetIsSkyrail`, devenu redondant, est retiré afin d'avoir un unique critère d'admissibilité. Les champs `record.skyrailDirection` sont remis à zéro en annulant une destination.
5. Aucun téléport, `WalkSpeed` spécial, RemoteEvent, script de rendu, rayon, modèle ou recherche de chemin supplémentaire. Le coût est une lecture d'attribut sur les décisions déjà existantes.

## Validation

Le test du fichier `tests/engine/ai-survivor-rules.spec.luau` vérifie toujours le cas normal et la collision/phase, puis les quatre états de portique bloqué. Jalon exact-SHA : Build Validation et 7 suites Roblox Cloud. Sur un vrai Studio/Android, observer sept bots lors de `Warning → Raised → Idle`, leurs récupérations `BotStallRecoveryCount` et des séquences de Towers + Double Chaos ; ne pas prétendre avoir mesuré le comportement uniquement par succès des suites.

**Aucune publication publique.** Le ticket de connexion #563 reste un suivi indépendant.
