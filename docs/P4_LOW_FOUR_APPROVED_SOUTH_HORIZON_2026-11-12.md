# P4 — Quatre monuments de l'horizon sud en vraie 3D sur Android Low

**12 novembre 2026 — changement GitHub, non publié dans Roblox.**

## Audit des derniers gros volumes basiques au sud

Le serveur `MapBuilder.lua` crée `Arena.Decor.SouthHorizonMonument`,
avec un modèle de décor distinct pour Classic, Towers, Crossroads,
Orbital et Harbor. Les quatre kits ci-dessous utilisaient déjà des
sources 3D originales approuvées en Medium et High, mais avaient tous
`QUALITIES.Low=0` : le profil Android Low gardait les gros cubes,
cylindres ou wedges du monument sur toute la carte.

| Arène | Modèle authentique créateur | ID approuvé | Primitives remplacées après montage complet |
| --- | --- | --- | ---: |
| Classic | Observatoire sud, paraboles et salle de contrôle | `105516749001927` | 13 |
| Towers | Pont de transfert et cabine suspendue | `120959181274080` | 2 |
| Crossroads | Grand échangeur de fret et fourches | `77870668100712` | 13 |
| Harbor | Chantier naval, manutention et passerelle | `125428569657840` | 14 |

**Chaque modèle utilise sept véritables MeshParts**, et les quatre
familles sont mutuellement exclusives par `VariantId`. La variante
Orbital dispose déjà de son propre anneau sud approuvé sur Low et
n'est **pas** modifiée dans ce lot.

## Modification réalisée

- `QUALITIES={Low=1,Medium=1,High=1}` pour chacun des quatre kits.
- `DISTANCE={Low=290,Medium=420,High=580}` : Low ne charge le
  véritable modèle qu'à **290 studs maximum de la caméra**, avec
  la rétention de **26 studs** déjà existante pour empêcher le
  clignotement lors des déplacements.
- Le détenteur `Arena.Decor.SouthHorizonMonument` doit être un
  modèle complet, avec exactement les dimensions, positions,
  rotations et attributs originaux. `VariantId` et
  `SignatureVariant` doivent correspondre.
- La source doit porter `OwnerVerified`, `CosmeticOnly`,
  `Original3DAssetId` exact et le drapeau approuvé propre à
  la sculpture. Les sept pièces sont vérifiées de type
  `MeshPart`, non collidables, sans scripts, et validées
  géométriquement avant tout montage.
- Le montage existant conserve son ordre transactionnel :
  **monter le modèle original avant de masquer les formes
  primitives serveur**. Si l'import est tardif, absent ou
  partiel, toutes les formes natives restent visibles.
- Sous `OptionalVfxPressure >= 1` sur Low, le propriétaire
  démonte le modèle et restaure chaque primitive native.
  Les limites Medium/High et leurs règles de pression sont
  inchangées.
- Les quatre dossiers `ApprovedSouth*Local` sont déjà inclus
  une fois dans `VisualBudgetRules.LocalFolders` : les sept
  nouveaux MeshParts éventuels demeurent comptés dans le
  même budget Android et utilisent le passage LOD existant.
- Aucune nouvelle instance physique, `RemoteEvent`, texture,
  ombre, lampe, `RenderStepped`, `Heartbeat`, requête HTTP
  ou AssetService côté client.

## Recette de validation Roblox Engine / Android

1. En Low et `OptionalVfxPressure=0`, entrer dans chaque
   arène en approchant la caméra de `SouthHorizonMonument`
   à moins de 290 studs. Vérifier qu'au plus **une sculpture
   de sept MeshParts** remplace sa silhouette de blocs.
2. Vérifier les attributs client de diagnostic :
   `LocalApprovedSouthClassicObservatoryCount`,
   `LocalApprovedSouthTowersSkytransferCount`,
   `LocalApprovedSouthCrossroadsExchangeCount`,
   `LocalApprovedSouthHarborDrydockCount` et leurs compteurs
   exacts de primitives remplacées : **13, 2, 13, 14**.
3. Tester `OptionalVfxPressure=1` puis 2 : le modèle authentique
   disparaît, toutes les primitives d'origine sont visibles.
4. Simuler une source incomplète, un départ de source approuvée,
   une pièce retirée, un changement de carte et StreamingEnabled :
   aucune géométrie fantôme, aucun masque natif persistant.
5. Confirmer les collisions, avertissements de danger,
   Shrinking Arena, déplacements et bots inchangés. Comparer
   les captures depuis le sud et mesurer FPS, mémoire et p95
   sur un vrai smartphone Android Low.

`tools/verify_original_3d_budget_census.py` vérifie la provenance
et le contrat de restauration des quatre kits. Les workflows GitHub
sont une validation **de source** ; ils ne prouvent pas le rendu
Roblox Engine, les FPS réels ni une publication du jeu.
