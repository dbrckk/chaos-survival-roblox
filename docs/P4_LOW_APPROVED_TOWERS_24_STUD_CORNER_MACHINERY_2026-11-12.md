# P4 — Machines d'angle Towers : grands blocs remplacés par la sculpture originale sur Android Low

**12 novembre 2026. Code GitHub uniquement ; aucune mise à jour Roblox ni mesure FPS Engine revendiquée.**

## Audit du dépôt

`MapBuilder.lua` génère, à chacun des quatre angles extérieurs de Towers :
- un `TowerMachineryN` de **5,2 × 24 × 5,2 studs**, natif et non collidable ;
- un `TowerMachineryCapN` de **7,4 × 1 × 7,4 studs**, animé par `arena-identity-motion.client.lua` ;
- une `TowerAntennaN` de **0,55 × 9 × 0,55 studs**, animée indépendamment.

Le serveur met déjà à disposition l'original créateur **`72143366927826`**, source `variant_towers_sculpted_machinery` approuvée avec sept vrais MeshParts et un volume **7,36 × 24,9 × 7,36 studs**. Il est distribué après validation du contenu et de la provenance `OwnerVerified`, `CosmeticOnly`, `OriginalTowersMachinery3D` et `Original3DAssetId`.

Le module client `ApprovedVariantTowersLandmarkMeshKit.lua` dispose déjà du masque réversible du corps statique et du capuchon animé. Cependant, deux verrous indépendants interdisaient leur remplacement sur Android Low : `CAP.Low=0` / `RANGE.Low=0` et `if touch` qui réduisait **tous** les plafonds Low à zéro.

## Modifications

1. **Low : un seul original** de sept MeshParts maximum, sur une vraie machine d'angle Towers, à moins de **220 studs** de la caméra. Rétention LOD inchangée de **24 studs** sur le modèle déjà monté.
2. La branche tactile accepte elle aussi ce même plafond **Low=1**. Les règles Medium (**2 à 290 studs**) et High (**4 à 410 studs**) ne changent pas ; plafond High tactile 2, Medium tactile 1.
3. Dès la pression graphique **1**, `floor(1×0,5)=0` : la sculpture Low facultative est démontée et le bloc natif ainsi que l'état du capuchon sont rétablis. Même repli à pression 2.
4. Une écoute `ApprovedTowersMachineryLocal.ChildRemoved` restaure immédiatement le **vrai corps** et le **capuchon animé** si le gestionnaire de budget éjecte le modèle entre deux échantillons LOD. Pas de boucle supplémentaire.
5. `TowerMachineryCap` retrouve son précédent `SceneryLodHidden` et `LocalTransparencyModifier`. Sa couleur, sa transparence de phase et son `CFrame` restent exclusivement gérés par `arena-identity-motion`, sans animation concurrente.
6. **L'antenne `TowerAntenna` n'est jamais masquée ni déplacée** par le kit. Son signal existant reste animé indépendamment.
7. Les sept MeshParts sont ancrés et sans collision, toucher, requête ou ombre ; aucun élément physique, parcours, danger, lumière, matériau ni système réseau ne change.
8. Le dossier `workspace.ApprovedTowersMachineryLocal` était déjà déclaré dans `VisualBudgetRules.LocalFolders` et continue de participer au budget graphique Android partagé de 440 Parts.
9. Les règles de remplacement atomique, source partielle, disparition de MeshPart, streaming, rétrécissement de l'arène et changements de cartes préexistantes sont conservées.

## Recette Engine/Android restant à exécuter

- En qualité **Low** avec `OptionalVfxPressure=0`, rejoindre Towers et approcher un vrai `TowerMachinery` à moins de 220 studs après chargement différé de la source serveur. Vérifier **un seul** `TowersCornerSculpted3D_N` de sept MeshParts, le bloc natif masqué, son capuchon visible uniquement au travers de la sculpture, et l'antenne animée indépendamment.
- Observer le capuchon sur plusieurs phases d'animation ; aucun conflit d'orientation/couleur et aucune disparition de l'antenne.
- Lire `LocalTowersLandmarkMeshCount≤1` et `LocalTowersLandmarkPrimitivesReplaced≤2` sur Low : deux primitives peuvent être masquées par l'unique sculpture (corps et capuchon).
- Simuler pression 1 puis 2 ; les deux primitives doivent revenir sans modifier l'antenne. Tester également éviction du dossier local, import source partiel, perte d'une MeshPart, shrink, streaming et renouvellement de map.
- Comparer captures, temps de frame p95, FPS et mémoire sur un vrai Android Low avant déploiement de la Place.

Les contrôles GitHub `tools/verify_variant_towers_machinery_runtime.py`, `tools/verify_towers_machinery_motion_shrink_lod.py` et `tools/verify_original_3d_budget_census.py` protègent la provenance, les plafonds mobiles, l'animation et le repli natif. **Ils ne prouvent pas le rendu dans Roblox Engine ni une publication de la place.**
