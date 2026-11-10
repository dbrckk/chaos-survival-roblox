# P4 — Limiteur global des imports 3D approuvés

Date : 10 novembre 2026. Lors de l'audit du code principal,
**46** modules `Premium*Assets.lua` contenaient leur propre chemin
d'accès aux Models originaux Roblox modérés. Seuls les huit chargeurs sud
partageaient précédemment une limite de concurrence. Décaler les premiers
appels par des `task.wait` ne suffit pas lorsque les délais de réseau
varient ou que Roblox répond lentement.

## Nouveau contrat

Le module serveur `PremiumApprovedAssetImportGate` fournit une file
**FIFO à deux permis**, accessible par `GlobalApprovedImportGate.load`.
Les 38 chargeurs non-sud utilisent cette méthode. Les huit chargeurs sud
continuent de passer par leur sous-verrou exclusif
`PremiumSouthApprovedImportGate`, qui appelle désormais le même
limiteur global. La concurrence nominale totale des 46 propriétaires
est donc **au maximum de deux appels AssetService à la fois**, dont
**au maximum un appel sud**.

La file s'endort sur `BindableEvent.Event:Wait` au lieu d'utiliser
une boucle de vérification périodique. Un permis est transmis dans
l'ordre d'arrivée aux demandeurs ; il est libéré même en cas d'erreur
de `LoadAssetAsync`. Les anciens `pcall` externes, la politique
de 3 retries, les contrôles MeshPart, les modèles natifs de secours,
les délais initiaux, collisions et limites LOD sont conservés.

L'API `Gate.snapshot()` renvoie les indicateurs
`InFlight`, `Waiting`, `PeakInFlight`, `Limit`, `Completed`,
`Failed` et `TotalWaits`. Les compteurs sont temporaires,
locaux à chaque serveur, sans stockage, réseau ou boucle supplémentaire.

## Limites de mesure

Ce lot protège les **46 chargeurs Premium référencés** du dépôt.
Les autres scripts qui utiliseraient directement `AssetService` ne sont
pas inclus dans cette limite. Une requête Roblox suspendue sans retour
peut retarder les imports cosmétiques restants : le gameplay, la
génération de carte et les bots ne doivent pas attendre la file.

Les tests automatisés peuvent vérifier l'usage du module, le code
de la file et l'absence de nouvel appel direct, mais ne prouvent
pas le comportement réseau et le FPS en conditions réelles.
Avant de qualifier le résultat, consulter les compteurs du serveur
dans Studio et les mesures de FPS Android.
