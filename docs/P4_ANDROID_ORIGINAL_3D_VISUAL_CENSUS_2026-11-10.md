# P4 — Correctif du recensement Android des vraies MeshParts

10 novembre 2026. Audit de toutes les **64 familles de MeshKit/3DKit**
client du repository et comparaison avec le tableau
`src/shared/VisualBudgetRules.lua:VisualBudgetRules.LocalFolders`.

## Bug identifié

Huit **dossiers directement rattachés à `workspace`** contenaient
des sculptures 3D authentiques mais n'étaient pas inscrits dans le
registre du recensement partagé :

- `ApprovedClassicBroadcastFinLocal` — 4 ailerons Classic possibles ;
- `ApprovedCrossroadsEntrancePortalsLocal` — 4 portails intérieurs ;
- `ApprovedCrossroadsOpenGantryLocal` — 4 portiques périphériques ;
- `ApprovedOrbitalReactorLandmarksLocal` — paires nœud + support ;
- `ApprovedPrimarySkylineLocal` — structures primaires de l'horizon ;
- `ApprovedSkylineDepthLocal` — volumes secondaires lointains ;
- `ApprovedOriginalIdentitySpinesLocal` — mâts Classic et Towers ;
- `ApprovedTowersMachineryLocal` — quatre machines d'angle Towers.

Ces familles ont été introduites après d'autres lots de sculpture,
et ne figuraient pas dans les 109 entrées antérieures de
`LocalFolders`.

`VisualBudgetRules.collect(workspace)` parcourt UNIQUEMENT les noms
présents dans ce registre. Le client Android
`visual-budget-pressure.client.lua` récupère le nombre total de
`BasePart` de ces dossiers, ainsi que les lumières et effets ;
il peut sous-évaluer la charge des MeshParts réelles si un dossier
est omis. Il utilise ce recensement toutes les 20 secondes,
avec des décisions de pression environ toutes les 5 secondes.

## Correction

Ajout des huit dossiers aux noms exacts ; chaque MeshPart importée
compte maintenant comme une `Part` du budget de qualité adaptative
existant. Pas de nouvelle boucle, nouveau `RemoteEvent`, changement
de shader, asset ID ni modification de la physique. La logique LOD
et de retour aux primitives natives reste inchangée.

Le nouveau `verify_original_3d_budget_census.py` vérifie également
l'enregistrement unique de tous les dossiers `*Local` directement
créés sous `workspace` par des modules `*MeshKit`/`*3DKit` ;
les futurs ajouts oublieux échoueront en CI. Il garde une assertion
explicite sur les huit nouveaux propriétaires.

## Validation et limites

C'est une correction **d'exactitude de comptage**, pas une preuve
d'augmentation des FPS. Elle peut déclencher plus tôt la réduction des
cosmétiques sur Android lorsque la population de MeshParts dépasse les
seuils : le rendement dépend du nombre réellement monté, du GPU et
de la pression observée. Pas de publication Roblox Place, capture
Studio ni mesure Android revendiquée par cette CI source.
