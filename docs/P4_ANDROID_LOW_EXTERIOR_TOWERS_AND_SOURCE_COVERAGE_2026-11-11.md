# P4 — Tours extérieures 3D sur Low et couverture mesurable de cinq familles

**Date :** 11 novembre 2026. **Périmètre :** cinq variantes Roblox,
Android/PC, aucun changement de physique et aucun nouvel asset importé.

## 1. Réduire la géométrie native des tours extérieures sur Low

Les quatre `ExteriorSilhouette{North,East,South,West}` de chaque arène
comprennent **quatre corps structurels** (`ReactorShell`,
`RoofCanopy`, `LeftRib`, `RightRib`) initialement fabriqués à
partir de Parts rectangulaires. Le kit existant remplace ces quatre corps
par l'un des quatre **véritables Model assets 3D du créateur**,
composés de sept MeshParts et approuvés. Il conserve
`SignalBand` et `Antenna` pour la navigation.

Le nouveau budget du seul `ApprovedExteriorTowerMeshKit` :

| Qualité | Modèles en résidence | Rayon caméra |
| --- | ---: | ---: |
| Low Android/PC | 1 | 275 studs |
| Medium Android/PC | 2 | 330 studs |
| High Android | 3 | 450 studs |
| High PC | 4 | 450 studs |
| Pression 1 sur Low | 0 | retour aux natives |
| Pression 2 | 0 | retour aux natives |

Une tour originale supplémentaire peut donc être visible sur Low,
représentant **sept MeshParts pour quatre formes primitives
masquées**, uniquement si le Model approuvé, le streaming, la
proximité caméra, les formes et la provenance sont valides.
Cela ne signifie pas qu'un modèle est garanti pendant la
première manche. Les quotas Low des kits de skyline principale et de
toitures (1 et 1) restent séparés, soit **21 MeshParts au maximum
sur ces trois familles Low**, avant les autres éléments du jeu.
Le budget de `VisualBudgetRules.LocalFolders` comptabilise déjà
ces trois propriétaires. La pression graphique restaure les
fallbacks sans changer les collisions.

## 2. Véritables cartes PBR sur les tours proches Medium/High

`PremiumNearfieldPbrKit` peut désormais sélectionner les
**quatre sources** d'exterior tower 3D existantes pour chacune des
cinq variantes : `137744886537150`,
`74958476744494`, `97864559770371`,
`112172520488996`.

Les 16 images de `OriginalGroundPbrTemplates` fournissent
normal, couleur, métal et rugosité sur les surfaces adaptées.
Les parties SIGNAL, GRIP, CARBON et GLASS gardent leurs matériaux
natifs. Aucun plafond PBR n'augmente et aucune nouvelle boucle,
requête AssetService client ou image Roblox n'est introduite.
Les overlays restent réversibles à la disparition d'un Model.

## 3. Indicateur honnête des cibles 3D

Dans le **même** passage `scenery-lod.client.lua`, le client
additionne les seuls compteurs déjà calculés par cinq kits
**disjoints** :

| Famille | Primitives d'origine par arène |
| --- | ---: |
| ExteriorSilhouette (4 tours × 4 corps) | 16 |
| SkylineStructure (4 × 4 corps) | 16 |
| SkylineDepth (8 toits) | 8 |
| ExteriorRidges (4 coins × 3 wedges) | 12 |
| Atmosphere (4 piliers + 4 spines) | 8 |
| **Total des seules cinq familles** | **60** |

Trois attributs locaux : `LocalP4LandscapeTargetSourceSlots`,
`LocalP4LandscapeReplacedSourceSlots`,
`LocalP4LandscapeSourceReplacementPct`. Le numérateur est
la somme bornée des **remplacements déclarés** par les
cinq kits au passage courant ; le dénominateur reste un nombre
de **slots définis par les générateurs** et non un comptage
de fragments réellement rendus, de polygones GPU ou de tous
les objets visuels de la carte. Des sources absentes/streamées
ou la faible qualité peuvent ramener le pourcentage à zéro.

Cet indicateur ne mesure **pas** la couverture globale du jeu,
les FPS Android ni le rendu réel des matériaux. Il ne doit
pas être présenté comme la part de toute l'expérience devenue AAA.

## Prochaine validation

Au jalon de publication, comparer le même lieu et le même angle
sur Android Low/Medium/High avec les compteurs ci-dessus, puis
vérifier FPS/p95, disparition des natives seulement lorsque
les vrais MeshParts sont prêts, et restauration sous pression.
Le statut source ou une suite CI positive n'est pas une
preuve de capture in-engine ni de version publique mise à jour.
