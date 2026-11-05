# Anticipation physique des obstacles par les bots — grand lot IA

**5 novembre 2026.** Base examinée `d1163b51aee4d582f31b597e837585a705c4dd04` sur `dbrckk/chaos-survival-roblox`. Source intégrée seulement ; aucun rendu Android ni déploiement public certifié.

## Défauts identifiés dans le runtime

1. `arenaCandidates` permettait de choisir un `Spawn` ou un waypoint aléatoire sur le `Base` depuis un toit situé 8 à 10 studs au-dessus du sol : `reachableElevation` admettait cette descente même sans chemin physique. L'IA pouvait donc s'élancer vers une destination à 100 studs au sol à partir d'un balcon sans liaison.
2. Les bots n'inspectaient la continuité du sol et les murs qu'**après** un blocage avéré d'au moins 1,15 seconde. Un obstacle statique massif immédiatement devant une nouvelle cible de roaming provoquait donc choc contre le mur, pause, puis récupération, répété à chaque nouvelle cible.

## Changements effectifs

- Les `Spawns` et objectifs aléatoires du `Base` ne sont plus ajoutés à `arenaCandidates` lorsque `AISurvivorRules.elevatedRouteHasSupport(rootY, baseTop, false)` refuse l'accès au réseau du sol. Le raycast actuel du bot sur les étages demeure la seule preuve permettant de choisir un voisin de plateforme ; aucune surface invisible n'est créée.
- Nouveau **contrôle préventif borné et événementiel à la décision** : pendant le choix d'un nouvel objectif normal, un bot sur le vrai `Base` vérifie un couloir de **10 studs maximum** devant ses pieds et son torse. Un vrai collider `Anchored` bloque l'itinéraire ; les autres avatars ne sont pas considérés comme murs permanents. Au plus un essai tous les **2,4 secondes par bot**, échelonné selon le slot, pas de scan `Workspace` et aucun nouveau tick.
- Si obstacle, le bot utilise la récupération physique existante `nearbyRecoveryStep` : 7 directions distinctes, raycasts de dégagement corps entier et cinq échantillons de sol réellement collidable. La cible impossible est mise en quarantaine 7,5 s ; si aucun pas latéral n'est possible, il reste sur sa position et demande le vrai `PathfindingService:ComputeAsync` déjà existant, limité aux marches réellement sur le `Base`.
- Le contrôle n'intervient **jamais** pendant `Meteor/Bomb` actif visible, une fuite urgente, `ShrinkingArena`, `RisingLava`, `Tornado`, `DisappearingPlatforms`, un saut en cours, une promenade en hauteur, un objectif `PlatformN`, une station réservée ou une traversée Skybridge.
- Deux attributs sur le vrai rig `BotObstaclePreviewCount` et `BotObstacleAvoidedCount` permettent d'observer les obstacles détectés et les véritables détours montés. Leurs compteurs sont remis à zéro au début de la manche ; ce ne sont **pas** des preuves de FPS, de fluidité ou de réussite du trajet.

## Coûts et sécurité

- 1 raycast vertical de preuve du sol et jusqu'à 2 raycasts horizontaux seulement pour un objectif normal éligible, une fois par fenêtre de 2,4 s et par NPC, sans coût réseau supplémentaire. Le calcul approfondi de détour à cinq points de sol est **déclenché uniquement si un obstacle physique ancré existe**.
- Pas de nouveau RemoteEvent, serveur, modèle IA, `Heartbeat`, `RunService`, `PivotTo`, vitesse de marche ou `Humanoid.JumpPower`. Les sept bots gardent la cadence `brainCadence` et leurs propres noms.
- Les contraintes sur les vraies plateformes, barrières `BridgeShutterPhase`, sky gaps et `CollapsePhase` du lot précédent restent prioritaires.
- Le niveau **Android** doit encore montrer une baisse des collisions répétées, sans mouvement inhumain ni baisse de FPS sur 7 R15. Les vrais comportements ne peuvent être déduits de la seule validation source.

## Certification du jalon

1. Build Rojo et sept suites Roblox Open Cloud Engine réussis au même SHA ; le fichier de tests moteur existant `ai-survivor-rules.spec.luau` étend le contrat préventif et son refus sur étages/situations dangereuses.
2. Captures Studio authentifiées pendant des objectifs de roaming, obstacles fixes, transitions `Ground → PerimeterStep`, Harbor/Sky Spine/Orbital, et `Towers + Shutters`.
3. Observer `BotStallRecoveryCount`, `BotObstaclePreviewCount`, `BotObstacleAvoidedCount` pendant 30 minutes de jeu et vérifier qu'aucune fuite urgente n'est remplacée par un détour décoratif.
4. Si les protections échouent, revenir sur le commit identifié ; aucun déploiement public ne découle de l'exécution du workflow de contrôle.
