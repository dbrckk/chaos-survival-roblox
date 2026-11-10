# P4 — Inventaire exact du monument de l'horizon sud

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
