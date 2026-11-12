# Diagnostic concret — refus de publication Chaos Survival (12 novembre 2026)

## Preuves GitHub Actions, SHA public concerné

Candidat refusé : `db41c28e22d9f6691cf4e2a7678f2eac198e45fe`.

| Run | Constat |
| --- | --- |
| [Publication 43312357642](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43312357642) | Échec dans `Verify green build and real-engine tests for exact main SHA`. Aucune requête POST Roblox effectuée. IDs Universe `10771083668` et Place `95351659174730` confirmés. |
| [Build Validation 43310986429](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43310986429) | L'assertion sur le châssis sous plateforme attendait encore `underdecks=0` en Low, alors que l'implémentation approuvée et pilotée par pression autorise **un** maillage Low. |
| [Engine Tests 43311171571](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43311171571) | `gameplay_world` : **179/181** tests réussis ; deux échecs dans le test d'intégration `mapbuilder-advanced.spec.luau` (châssis sous arène 0 vs 1, sol MeshPart 0 vs 2). |
| [Readiness 43311418249](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43311418249) | Analyse read-only échouée, parce que les deux validations du SHA étaient rouges. |

## Corrections de source, sans raccourcir la sécurité

1. La Build Validation exige maintenant les **véritables** plafonds du `PremiumRouteMeshKit` : Low `1`, Medium `2`, High `4` châssis validés et budgétés, sans revenir au faux zéro.
2. Le scénario d'intégration Roblox Engine du sous-plancher utilise les **sept MeshParts de matériaux** qui représentent effectivement le package propriétaire approuvé `84582262145054`. Le scénario précédent n'avait **qu'une** MeshPart : le client rejetait donc correctement la source en Low (`pieces ~= 7`) mais le test prétendait attendre un montage. Le test vérifie toujours le montage réel d'instances Roblox, les pièces non physiques, la disparition au shrink et le retour de la géométrie d'origine.
3. Le montage des revêtements 3D `PremiumGroundMeshKit` n'utilise plus le `Model:ScaleTo` dont l'échec était silencieusement traité comme une absence de modèle : la translation, l'orientation et l'échelle uniformes des **véritables MeshParts** sont maintenant calculées depuis leur CFrame relatif au modèle approuvé, indépendamment de cet appel. La géométrie est vérifiée contre le module serveur avant tout montage ; les normales/UV du modèle approuvé restent conservées. Aucun nouveau collider, modèle, mesh, texture, requête réseau ou boucle visuelle.

## État et vérification requise

Ce correctif ne vaut pas publication. Après fusion, exécuter `Build Validation` et `Roblox Open Cloud Engine Tests` sur le **nouveau SHA exact de main**. Si les deux sont verts, le workflow existant `Publish Existing Chaos Survival (Public Playtest Update)` autorise la publication vers l'expérience **existante** : pas de nouvelle Place, pas d'alpha privée. Le workflow refuse toujours les SHA obsolètes et les vrais tests rouges.

Les 86 suites de test moteur existantes ne sont ni supprimées ni remplacées par une vérification factice. Les FPS Android et la certification Studio ne sont pas attestés.
