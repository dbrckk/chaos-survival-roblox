# P4 — Un bâtiment de quartier réellement 3D sur Android Low

**Candidat source du 13 novembre 2026.** Évolution incrémentale de la version publique `main@8df38f97c0fbcf1e58de25564a411f470369f074`, publiée dans l'exécution [43327970065](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43327970065). Ce chantier doit **encore** passer le build sur son SHA, les 7 suites Roblox Engine et une nouvelle publication explicite avant d'apparaître en production.

## Problème de cohérence observé dans le code

Dans les cinq mondes, les 16 grandes structures `ArenaDistrictArchitecture3D` disposent de quatre véritables façades 3D approuvées, mais Android Low n'affichait **aucune** paroi arrière/latérale authentique (`ApprovedDistrictSidewallMeshKit.BUDGET.Low.count=0`). En conséquence, un bâtiment peut présenter une façade réellement sculptée et **cinq** volumes d'origine en primitives Roblox derrière et sur les flancs. Le coût original du nouveau kit latéral est déjà enregistré et approuvé : Model `77387019170428`, 1 764 triangles et 6 MeshParts, [modération Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43302925840).

## Correction produit réellement intégrée

- **Android Low sain :** une seule structure proche (`<=128` studs) peut combiner sa vraie façade 3D et son enveloppe arrière/latérale 3D originale, sans empilement visible des cinq natives `ServiceCore / ArmoredSupportL / ArmoredSupportR / SideCassette-1 / SideCassette1`.
- **Dépendance vérifiée :** la façade locale `PremiumDistrictFacadeMeshKit` doit avoir monté son propre modèle avec `LocalApprovedDistrictFacadeMounted=true`. Si le modèle de façade n'est pas vraiment résident, la coque latérale Low **n'est pas importée**. Le LOD existant appelle d'abord les façades, ensuite les parois latérales sur le **même** snapshot caméra.
- **Budget supplémentaire strict :** maximum **1 modèle approuvé / 6 MeshParts / 1 764 triangles** Low ; sous pression FPS/VFX 1 ou 2, **0** modèle. Medium et High conservent leurs plafonds 4/10 (3/8 sur tactile), leur partage du budget Android global et leurs limites de distance.
- **Retour natif immédiat :** déconnexion/éviction du modèle de façade, disparition d'un des six MeshParts, changement d'arène, perte du package original ou pression GPU rendent immédiatement les cinq volumes originaux. La modification de la façade déclenche la restauration sans RenderStepped ni nouvelle boucle.
- **Nettoyage :** désabonnement de l'ancienne Base lors du changement ou de la suppression d'arène, pour éviter les références à un monde obsolète.
- **Physique inchangée :** vrai `Base` et itinéraires serveur intacts ; toutes les sculptures supplémentaires sont ancrées, non collisionnantes, non requêtables, sans ombre, sans lumière, sans nouveau download ni nouvelle texture.

## Contrats de validation

Le scénario d'intégration Roblox Engine déjà présent dans `tests/engine/visual-budget-rules.spec.luau` est étendu : il génère les **16 bâtiments du véritable générateur serveur**, monte une façade client source-approuvée, puis la coque de six véritables `MeshParts` dans les limites originales et vérifie les **cinq primitives retirées**, l'absence de collision, la réduction immédiate GPU, la pérennité pendant Shrinking Arena et le retour natif instantané après perte de la façade.

Les scénarios moteur de cette suite restent à exécuter dans Roblox Open Cloud. Le code ne prouve pas la présence physique ou le niveau artistique sur Android ; vérifier visuellement en vraie session un district avec façade + murs Low et la restauration sous pression.
