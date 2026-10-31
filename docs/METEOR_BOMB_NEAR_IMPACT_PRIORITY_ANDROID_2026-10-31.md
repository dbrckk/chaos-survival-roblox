# Chaos Survival — priorité aux impacts proches (Android) et synchronisation des météores

31 octobre 2026. Correctifs client et règle cosmétique partagée, **sans audit visuel actuel des cartes, sans exécution moteur et sans publication Roblox**.

## Problèmes constatés sur `main`

- `hazard-impact-feedback.client.lua` utilisait un unique compteur de 6/8/10 explosions temporaires pour **tous** les impacts situés à moins de 150 studs de l'observateur. En Double Chaos, une rafale de bombes/météores éloignés pouvait saturer le compteur avant un impact tout près du joueur ; même les effets compacts de l'explosion proche étaient supprimés. Les avertissements et dégâts serveur sont gérés ailleurs et restaient actifs.
- Les éléments plus coûteux étaient déjà régulés par `ImpactPulseRules.richDetailAllowed`, mais il manquait une limite pour la **quantité de bursts périphériques** à l'intérieur du budget total.
- `disaster-signature-vfx.client.lua` réactivait son scan immédiatement à chaque `RoundState` en phase météores, même si le même état était simplement répété par le serveur. Les messages de numéros de manche précédents n'étaient pas filtrés : une ancienne phase `round` pouvait réactiver des rubans de météore après la fin.

## Modification

1. **Sous-budget périphérique uniquement Android** — `ImpactPulseRules.peripheralBurstCap(tier, reducedMotion, touchDevice, distance)` renvoie `nil` sur PC et près de la caméra (<=48 studs Low, <=72 Medium, <=88 High). Au-delà, le budget des bursts périphériques simultanés est limité à **1 sur Low ou ReduceMotion, 2 sur Medium/High**. Il ne modifie **pas** la limite globale d'effets proches ni les avertissements au sol, directions d'évitement, dégâts, colis ou audio serveur.
2. `hazard-impact-feedback` suit `activePeripheralBursts` séparément. Il n'accorde pas d'effet secondaire coûteux (`richDetail`) à une explosion périphérique mobile. Chaque burst accepté libère les deux budgets correspondants à sa fin ; `burstEpoch` empêche les timers de l'ancienne carte/manche de décrémenter le nouveau compteur.
3. **Météores** — `disaster-signature-vfx` rejette les `RoundState` numériquement antérieurs, invalide les rubans à chaque changement de manche et ne planifie une synchronisation immédiate que si la phase, l'activation de météores ou le numéro de manche changent. La boucle existante à 0,25 s continue de suivre les parts qui se déplacent. Les abonnements `workspace.ChildAdded` restent actifs afin de traiter rapidement les nouveaux météores pendant la manche.
4. Aucun nouveau `RenderStepped`, aucun `RemoteEvent`, aucun changement de physique, d'IA ou de serveur, pas de suppression de la signalétique de catastrophe. Les budgets de `HazardWarning`, `BombCharge`, `GroundOutline` et des flèches d'évitement restent inchangés.

## Contrats à valider au prochain jalon de release

- Build Validation et **cinq suites Roblox Open Cloud**, exécutées sur le SHA exact de la fusion, plus une session Android Low/Medium/High et PC.
- Double Chaos Bomb + Meteor : saturer d'impacts éloignés puis provoquer un impact près de l'avatar ; vérifier que les effets proches restent admissibles et que les avertissements de toutes les explosions restent visibles.
- Envoyer des impacts périphériques en rafale avec `ReduceMotion` ; vérifier le quota de 1, la suppression des smoke/PointLight secondaires et le fonctionnement des signaux essentiels.
- Changer de carte ou de numéro de manche pendant des bursts actifs : aucun ancien minuteur ne modifie le nouveau sous-compteur.
- Envoyer des `RoundState` identiques et un ancien numéro après une phase résultat ; vérifier l'absence de création de rubans obsolètes et la continuité des météores réellement actifs.
- Mesurer FPS, mémoire, temps CPU et nombre de pièces dans `ImpactSetpieceLocal` et les rubans de météores ; **ne pas revendiquer de gain chiffré avant ces mesures**.

L'audit réel des cartes et le déploiement Roblox public restent reportés conformément au périmètre demandé.
