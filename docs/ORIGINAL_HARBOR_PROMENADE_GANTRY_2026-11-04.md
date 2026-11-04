# Chaos Survival — vrais portiques de fret sculptés sur les six sky-promenades Storm Harbor

**4 novembre 2026 — Source + Model Roblox approuvé, pas une publication du jeu.**

## Avant / source inspectée

Le lobby est déjà en 3D et les 5 arènes disposent de nombreuses surfaces premium. Le défaut visuel visé est distinct : `src/server/PromenadeArchitecture.lua` fabrique **6 grands portiques (2 promenades × marches 2, 4 et 7)** par arène, chacun en **9 `Part` et `WedgePart` non physiques**. À Storm Harbor : deux `LoadPylon`, deux `DiagonalStay`, `MonumentalCrosshead`, `UnderdeckTruss`, `FreightHoistArm`, `SuspendedCrate`, `CargoChain`. Les vrai tabliers `PlatformN` sont des surfaces serveur de 2 studs d'épaisseur et **12 studs de large**, reliées à des parcours de 200+ studs avec vrais sauts. Ne pas retirer le moindre collider, les interruptions ou les signaux d'itinéraire.

## Œuvre et preuves

La source originale `tools/generate_original_harbor_promenade_portal.py` construit une passerelle-grue manufacturée **à silhouette ouverte** : deux jambes coniques à 10 côtés, six caissons de fixation, diagonales et treillis de toiture, véritable traverse, rail de grue, trolley, câbles, caisse cargo suspendue et cadre sous le tablier. Les piliers restent au-delà de `|z|=7.08` ; le tablier marche sur `|z|<=6`. Les éléments suspendus commencent à près de dix studs au-dessus du sol jouable, et toutes les pièces importées sont purement décoratives sans collision.

- Génération **1 956 triangles**, **7 groupes de matériaux** complets (`ARMOR/BRUSHED/CARBON/GRIP/ALLOY/CERAMIC/SIGNAL`), glTF 2.0, normals/UV/tangents valides.
- Source et import réel : [Github Actions #41837415151](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41837415151) **success**.
- Model propriétaire Roblox : **`134157110756659`**, modération Roblox : **Approved**. Aucun ID inventé.
- L'importeur existant `upload-original-3d-models.yml` contient désormais le choix de source fixe `harbor_promenade_portal`. Aucune requête Roblox côté client ni dépendance marketplace.

## Contrat d'intégration

- `PremiumHarborPromenadePortalAssets.lua` récupère **uniquement l'ID approuvé**, nettoie avec `OriginalMeshScenery.sanitize`, exige 1 à 12 MeshParts et vérifie la bounding box sous l'une ou l'autre orientation X/Z, puis réplique `ApprovedHarborPromenadePortalTemplates.CargoGantry`. Chargeur différé 52 s ; aucune manche, AI, spawn ni vote ne dépend de lui.
- `HarborPromenadePortalMeshKit.lua` vérifie identité, taille, phase, `ChaosPermanentRoute`, `PromenadeLane 1/2`, `PromenadeStep 2/4/7`, matériau `Original3DAssetId` et source entièrement en MeshParts.
- Tous les vrais morceaux sont attachés par `WeldConstraint` inertes à leur **vraie plateforme**. Les neuf pièces natives correspondantes sont masquées via `LocalTransparencyModifier=1` **après** que le modèle original complet est monté. Les éléments arrivant après streaming sont aussi masqués. Si source manquante, modèle incomplet, collapse/shrink, changements de carte ou tier, les anciens éléments sont réaffichés.
- `scenery-lod.client.lua` est l'**unique propriétaire d'échantillonnage caméra** ; pas de nouveau RenderStepped, Heartbeat, timer ou lumière. `VisualBudgetRules.LocalFolders` inclut tous les MeshParts sous `OriginalHarborPromenadePortalsLocal`.
- Diagnostic `LocalOriginalHarborPromenadeCount` : nombre de portiques originaux encore montés correctement. Compteur d'instances, pas une preuve d'image affichée.

| Appareil / pression | 0 | 1 | 2 |
|---|---:|---:|---:|
| Low | 0 | 0 | 0 |
| Medium | 2 | 1 | 0 |
| High | 6 | 3 | 1 |

Le maximum High est **42 MeshParts** pour 6 portiques, en remplacement du dessin de **54 anciennes pièces natives** (elles restent présentes serveur comme fallback). Les 1 956 triangles correspondent à **un modèle**, pas au total des six résidents. Portées caméra Medium 205 studs / High 280 studs, avec hystérésis contre le popping.

## QA de livraison à obtenir

1. Build et sept suites Roblox Cloud **au commit final exact** du lot, sans publier.
2. En jeu réel sur Harbor : photographier les six portiques, constater que l'ancien `Part`/ `WedgePart` ne perce pas les volumes 3D ; toit, hangar de fret, treillis et dessous doivent rester discernables en vues proches.
3. Parcours R6/R15 : une traversée aller-retour de chaque promenade sans obstacle invisible, faux palier, mauvaise orientation ni disparition de plateforme ; vérifier saut de 2.4 studs et collision serveur inchangée.
4. Phase ShrinkingArena/streaming/Low et sous pression FPS : aucun portail flottant, aucun mesh suspendu au-dessus d'une route disparue, fallback visible, pas de fuite de `WeldConstraint` ou de connexion.
5. Relevé Android réel Low/Medium/High, 15 captures par arène au jalon visuel, FPS/p95/mémoire sur 30 min ; ne jamais annoncer une augmentation de qualité à partir du nombre de fichiers changés.
6. Répéter la méthode sur les quatre variantes de promenade encore natives **après** certification du standard Harbor. Les modèles ne sont pas visuellement interchangeables : design unique pour Classic, Towers, Crossroads et Orbital.

**Publication publique : NON, sauf workflow de publish séparé, contrôles Android et preuve Roblox versionNumber.**
