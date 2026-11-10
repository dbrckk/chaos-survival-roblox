# P4 — Inventaire exact du monument de l'horizon sud

## État des remplacements vérifiés — 10 novembre 2026

| Variante | Source primitive | Cibles avec mesh original approuvé + kit LOD | Restent natives sans mesh |
|---|---:|---:|---:|
| Orbital sud | 20 | **14** (`ObservationArc1..14`) | 6 |
| Towers sud | 13 | **13** (pont/cabine 2, tours/couronnes 4, finition 7) | **0** |
| Crossroads sud | 13 | **13** (échangeur sculpté complet) | **0** |
| Harbor sud | 14 | 0 | 14 |
| Classic sud | 13 | 0 | 13 |
| **Total** | **73** | **40 (54,8 %)** | **33** |

**Périmètre exact : 73 occurrences-source de la famille `SouthHorizonMonument` sur les cinq variantes, pas toutes les primitives du jeu.** Un seul monument de variante est présent à la fois. Les remplacements sont actifs uniquement lorsque le modèle modéré est chargé et que le LOD Medium/High l'autorise ; les primitives natives sont restaurées sur Low ou sous pression GPU.

Assets confirmés `Moderation: Approved` : Orbital anneau `124474310430876` ([Actions #42821753995](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42821753995)), Towers `120959181274080`, `114886409893890`, `79666240429608`, Crossroads `77870668100712` ([Actions #42842143479](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42842143479)). Les tests de régression source des modules Towers et Crossroads sont verts sur `main`. **Tests Roblox Studio, captures Android, FPS et publication publique non vérifiés.**

**Nouvelle priorité :** les 6 autres éléments Orbital sud (2 socles, 2 supports, sphère et bride), puis les 14 éléments Harbor et 13 éléments Classic sud. Les priorités initiales ci-dessous restent un historique d'audit, pas l'état actuel.


**Établi à partir de `src/server/MapBuilder.lua`, fonction `addSouthHorizonMonument`, sur le commit `3dc4e37aabf684a74ec071ef6fe30c501a9e26c6`.**

## Constats

Le monument `Decor/SouthHorizonMonument` est une famille distincte de `ArenaSignatureMegastructure` (nord) et des 11 bâtiments `CinematicHorizon` déjà pris en charge par `ApprovedCinematicHorizonMeshKit`. **Ne pas compter leurs MeshParts comme des remplacements du monument sud.** Il est généré pour chaque variante, hors zone jouable et sans collision, avec `ChaosDistantScenery=true` et `SignatureVariant`.

| Variante | Grandes primitives prioritaires à sculpter | Autres primitives du même monument |
|---|---|---|
| Orbital | `ObservationArc1..14` (14 segments Part, anneau de rayon 17) | `LeftRingSupport`, `RightRingSupport`, `SuspendedOrb` sphérique, `OrbClamp` |
| Towers | `WestLift`, `EastLift`, `WestCrown`, `EastCrown`, `SkyTransfer`, `UnderslungLift` | deux rails lumineux, deux suspensions inclinées, `TransferSignal` |
| Crossroads | `ExchangeCore`, `WestFork`, `EastFork`, `WestFreightArm`, `EastFreightArm`, `CentralSwitchCab` | deux contrepoids, deux signaux, `CabWindow` |
| Harbor | `WestQuayColumn`, `EastQuayColumn`, `WestQuayCargo`, `EastQuayCargo`, `HarborLightshipBridge`, `HarborSignalCab` | deux hoists, deux rigs WedgePart, `HarborStormLens`, `HarborStormBeacon` |
| Classic | `WestRadarPylon`, `EastRadarPylon`, `WestRadarDish`, `EastRadarDish`, `ObservatoryBridge`, `ObservatoryCabin` | deux récepteurs, deux braces, `ObservatoryGlass` |

Les deux éléments communs `Foundation` (47×2×13) et `FloorInset` (39×0,3×10) restent aussi des Parts rectangulaires dans **chaque** variante. Les variantes ont donc respectivement **20, 13, 13, 14 et 13 primitives** au total (en comptant ces deux éléments communs), soit **73 occurrences-source sur cinq variantes**, mais **une seule variante est présente dans une arène à la fois**. Les chiffres sont un inventaire statique de pièces, **pas un pourcentage de couverture 3D du jeu ni un décompte de pièces affichées en permanence**.

## Priorité de livraison

1. **Orbital sud** : remplacer les 14 `ObservationArc` par un anneau creux continu réellement triangulé, plus des traverses et connecteurs forgés. Le centre doit rester ouvert et la sphère `SuspendedOrb` visible. Cette famille apporte le plus grand nombre de rectangles visibles pour un seul modèle original.
2. **Towers sud** : deux fûts et couronnes, plus le pont suspendu, sous forme de 3D sculptée. Conserver les rails de signal et suspensions d'origine jusqu'à remplacement approuvé.
3. **Harbor, Crossroads, Classic sud** : sculpter les six grands volumes distinctifs de chaque variante ; ne pas recycler le modèle nord en lui attribuant une fausse identité.

## Contrat de remplacement non négociable

- Générateur source original OBJ/glTF avec vraies normales, UV, tangentes, sept matériaux industriels et dimensions vérifiées ; import Roblox créateur, puis **`Moderation: Approved`** avant toute référence d'asset dans le runtime.
- Vérifier `GeneratedMap/Arena/Decor/SouthHorizonMonument`, la variante et les tailles, CFrames, propriétés `Anchored`/`CanCollide`/`CanTouch`/`CanQuery` exactes de toutes les pièces ciblées ; conserver `Foundation` et `FloorInset` jusqu'à un lot séparé.
- Monter **tous** les MeshParts non physiques avant de masquer atomiquement les natives ; restaurer la transparence originale en cas de streaming incomplet, source détruite, changement de variante, qualité Low, pression GPU ou réduction de base.
- Réutiliser le seul échantillonnage `scenery-lod.client.lua` et le budget `VisualBudgetRules.lua`. Aucun nouveau `RenderStepped`, aucune collision, aucun réseau client, aucune altération des bots ou du gameplay.
- Valider le rendu Roblox Studio et les FPS Android **avant** de prétendre à une publication de la Place. La présence d'un fichier ou d'un Model approuvé ne prouve pas son rendu effectif.

**Statut au moment de l'audit :** inventaire vérifié et priorités définies. Les 73 pièces de cette famille ne sont **pas** déclarées remplacées.
