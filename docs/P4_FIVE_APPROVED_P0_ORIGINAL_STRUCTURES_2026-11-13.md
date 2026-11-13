# Chaos Survival — cinq véritables nouveaux modèles 3D approuvés (P4)

**Date :** 13 novembre 2026 · **Dépôt :** `dbrckk/chaos-survival-roblox` · **Branche :** `main`.

## Sources approuvées par Roblox

Les cinq originaux sont générés dans le dépôt par
`tools/generate_original_remaining_structures.py` (vraies faces triangulées,
UV et sept régions de matériaux), convertis en glTF 2.0 et enregistrés comme
**modèles Roblox Model possédés par le créateur**. La publication d'un asset
au catalogue du créateur ne signifie **pas** qu'une nouvelle version du jeu
public a été déployée.

| Original | ID Roblox réellement approuvé | Triangles | MeshParts |
|--|--:|--:|--:|
| ACCESS arch | 110243423264048 | 1 584 | 7 |
| TRANSFER arch | 107273631120961 | 1 584 | 7 |
| SUMMIT arch | 127049813505254 | 1 584 | 7 |
| Architectural column casing | 130196548599769 | 928 | 7 |
| Orbital Helix underframe | 106863534763803 | 1 624 | 7 |

**Provenance contrôlée :**
[les cinq glTF générés en dry-run](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43467221966) ;
[les cinq retours d'import Roblox, tous `Approved`](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43467373476).
Le registre `assets/source/roblox-asset-registry.json` contient désormais
108 modèles approuvés. La source versionnée est le générateur : les fichiers
OBJ intermédiaires ne sont pas pris pour des assets déjà compilés.

## Intégration réelle

- **Serveur :** `PremiumRemainingStructureAssets.lua` charge les cinq IDs
  fixes en différé. Chaque Model passe par la file d'import déjà partagée
  (au maximum deux opérations simultanées), la sanitation, le contrôle des
  dimensions, du nombre de MeshParts et de l'absence de collisions.
- **Client :** `ApprovedRemainingStructureMeshKit.lua` conserve un plafond
  de clones par catégorie et utilise l'**unique pass caméra** déjà
  programmé dans `scenery-lod.client.lua`, sans second RenderStepped.
  Les sept MeshParts par clone sont comptés dans le budget Android partagé.
- **Fallback :** toutes les sources natives ne sont masquées que si le vrai
  propriétaire collidable/structural et les sept composants originaux sont
  authentifiés. Le retour natif est déclenché immédiatement sur événement
  de streaming, dimension réelle, disparition d'un mesh ou état
  `CollapsePhase`/`BridgeShutterPhase`.

Les trois catégories ciblent :

1. **Les 3 niveaux des ascensions ACCESS / TRANSFER / SUMMIT.** Les
   plateformes ont des épaisseurs natives différentes — **3, 13,8 et
   28,2 studs** — et leurs véritables hauteurs sont contrôlées par
   `PerimeterStep`. Le modèle monte depuis la vraie face supérieure du
   collider. **Cinq pièces métalliques SUPÉRIEURES par arche** sont
   remplacées : deux pylônes, deux ailerons et une traverse. Les
   abutments, la quille et le girder **profonds restent natifs**, car
   l'original de façade ne s'étend pas jusqu'au dessous des escaliers
   épais. Toutes les balises, flèches et collisions sont conservées.
   L'étage SUMMIT peut s'effondrer : il est éligible au remplacement 3D
   seulement tant qu'il est physiquement sûr.
2. **Quatre casings par arène**, vingt au total dans les cinq définitions :
   jusqu'à **onze** primitives de revêtement éligibles par casing résident.
   Les têtes d'orientation et vrais piliers restent natifs.
3. **Jusqu'à huit rampes Orbital Helix** : jusqu'à **quatre** pièces
   `HelixUnderframe` / `HelixSpineBrace` par rampe 3D résidente. Les
   vingt-quatre vrais tronçons physiques et les signaux restent serveur.

Ces chiffres indiquent un **potentiel conditionnel** par arène, non un
pourcentage certifié de primitives réellement masquées dans une partie.

## Quotas de résidence par arène active

| Qualité | Arches | Casings | Helix |
|--|--:|--:|--:|
| Android Low | 1 | 1 | 0 |
| Android Medium | 2 | 1 | 1 |
| Android High | 3 | 2 | 3 |
| PC Medium | 3 | 2 | 2 |
| PC High | 6 | 4 | 6 |
| Pression 1 | division par deux, arrondie vers zéro | idem | idem |
| Pression 2 | 0 | 0 | 0 |

Chaque modèle résident coûte sept MeshParts; les maximums de cette famille
sont **14 en Low tactile, 28 en Medium tactile, 56 en High tactile,
112 en High PC** quand les trois familles de sources sont présentes
dans la carte, avant dégradation sous pression. Ces MeshParts font partie
des mêmes plafonds globaux Low **440**, Medium **680**, High **900**.

## Recette et limites du travail

`tests/engine/native-premium-fallback.spec.luau` a été enrichi dans son
scénario moteur réel de cinq variantes : vrais propriétaires du
`MapBuilder`, authentification d'une source complète, non-collision,
avertissement d'effondrement et retour natif. L'instrumentation
`RemainingVisualNativeCensus.lua` compte par famille les primitives
localement résidentes encore non masquées toutes les 16 passes LOD.

**Validation attendue avant publication :** Build Validation + sept suites
Open Cloud Engine sur le **même SHA**, puis captures Roblox Studio des
cinq cartes et mesure FPS Android. Un contrôle de source / une approbation
Roblox ne démontre pas à lui seul un rendu AAA ou un FPS mesuré.

**Aucune publication de nouvelle version du jeu public n'est revendiquée
dans cette livraison.**
