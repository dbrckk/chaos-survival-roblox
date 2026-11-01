# Chaos Survival — correction du chargement des modules pour les tests moteur (01/11/2026)

## Incident de publication du 1er novembre

Le déclencheur de publication publique #511 a correctement lancé **Build Validation** et **Roblox Open Cloud Engine Tests** sur le même commit `4dbaf9c2851b2b4b0f2066e04b659ce1f58d3c88`.

- Build Validation : **success**, GitHub Actions run `41286235541`.
- Roblox Open Cloud Engine Tests : **failure**, run `41286240283`, job `124788012406`.
- Publication conditionnelle : **failure sans déploiement**, run `41286229617` ; la garde exige les deux validations vertes.

Les 9 composite specs gameplay ont échoué au **chargement de modules**, sans atteindre les assertions : `DistrictFacadeStyles is not a valid member of Folder "ReplicatedStorage.Shared"`, `src/shared/DisasterAtmosphereLayout.lua:4: attempt to index nil with 'Parent'`, `src/shared/TornadoSpiralRules.lua:5: attempt to index nil with 'Parent'`.

Le build Roblox contient les Shared ModuleScripts via Rojo. Mais **Lest charge des modules source avant déploiement du nouveau jeu**, donc le Shared folder de l'expérience de test peut manquer les nouveaux modules ; le chargement par chemin dans Lest ne fournit pas toujours de variable globale `script`. C'est un défaut du contrat de chargement des tests moteur, pas une preuve de régression du mouvement ou du gameplay.

## Correctif

1. `src/server/ArenaDistrictArchitecture.lua` et `src/client/DistrictFacadeDetailKit.lua` : utiliser la table `DistrictFacadeStyles` de `ReplicatedStorage.Shared` lorsqu'elle existe, sinon charger **la même source** via `require("../shared/DistrictFacadeStyles")`.
2. `src/shared/DisasterAtmosphereLayout.lua`, `TornadoSpiralRules.lua`, `ImpactPulseRules.lua` : garder le lien `script.Parent.DisasterCosmeticRules` en version Rojo, résoudre `./DisasterCosmeticRules` lorsque Lest exécute la source sans `script`.
3. `src/shared/VisualBudgetPressureRules.lua` : même correction pour `VisualBudgetRules`.

Aucun mock ni dépendance substituée : **les deux voies chargent les véritables modules du dépôt**, en préservant leurs règles. Aucun changement de collisions, des zones de danger, du rythme des catastrophes, des FPS, des clients, des récompenses ni des modèles 3D.

## Nouveau jalon

Le déclencheur à usage unique du 1er novembre (nouveau fichier) doit relancer Build Validation puis les **cinq suites Roblox Open Cloud** sur le SHA exact de la fusion. En cas d'échec, **ne pas publier** et lire les logs jusqu'à ce que la cause soit corrigée. Si les deux réussissent, le workflow de public playtest validé précédemment peut publier l'expérience existante universe `10771083668`, place `95351659174730`, sous les gardes originaux.

Cette voie ne constitue **pas** une certification Android physique/Studio. L'audit visuel des cartes est toujours reporté. Prochaine fonctionnalité retenue après publication : améliorer la compréhension des premières 30 secondes sans surcharger le HUD mobile.
