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


## Répartition spatiale sans hausse de budget — 13 novembre 2026

La précédente sélection High PC réservait les six arches aux seuls
meilleurs scores caméra. Plusieurs arches pouvaient donc se concentrer
sur un seul circuit, alors que les trois sources approuvées
`ACCESS`, `TRANSFER` et `SUMMIT` existaient déjà.

Le propriétaire `ApprovedRemainingStructureMeshKit` vérifie désormais
l'attribut serveur **`PerimeterRoute` entre 1 et 4**. Sur un client
**PC High sans pression**, il choisit dans le quota existant **au maximum
six arches** :

1. Un propriétaire 3D réellement éligible, le mieux placé, sur chacun
   des quatre circuits d'évasion présents dans la fenêtre caméra ;
2. Si des emplacements restent libres, un portique de niveau
   **TRANSFER** et un de niveau **SUMMIT** authentifiés ;
3. Les éventuels autres slots sont remplis selon le score caméra initial.

Cet arbitrage ne change **aucun quota** High PC, Low, Medium, Android
ou état sous pression, ne charge aucun asset supplémentaire, n'ajoute
pas de boucle de rendu, et ne crée aucune collision. Une route dont
les vrais éléments natifs n'ont pas répliqué reste intacte avec son
repli ; les slots non disponibles sont redistribués sans monter
un modèle incomplet.

Les assertions de source existantes et le scénario Roblox Engine des
**cinq arènes** ont été étendus pour vérifier simultanément les
**quatre circuits** et les trois silhouettes `1/4/8`. Cela vérifie
la répartition dans le DataModel Roblox et **ne constitue pas une capture
visuelle Android ni une mesure de FPS**.

## Diversification mobile / PC Medium et repli strict — 13 novembre 2026

Sur **Android Medium (2 arches), Android High (3)** et **PC Medium
(3)**, le propriétaire conserve désormais l'arche admissible la plus
proche de la caméra, puis utilise les places restantes pour faire apparaître
des **silhouettes ACCESS, TRANSFER et SUMMIT différentes**, si leurs vrais
propriétaires collidables et les assets approuvés sont déjà éligibles.
Parmi les candidats de même niveau, les quatre routes réelles
`PerimeterRoute` sont réparties en priorité. Aucun modèle n'est choisi
au-delà de **60 points de priorité caméra** après le dernier candidat qui
aurait été retenu sans diversification : si les sculptures alternatives
sont trop éloignées, la sélection revient aux proches. Ces choix ne
créent ni MeshPart, ni abonnement de rendu, ni budget supplémentaire.

La sélection antérieure **PC High sans pression** (au plus six arches :
quatre routes + TRANSFER/SUMMIT) reste inchangée. Android Low conserve
**une arche**, pression 1 conserve ses plafonds réduits et pression 2
évince toutes ces sculptures. En cas d'import incomplet, sept MeshParts
restent exigés, et une **huitième primitive, un objet script ou une source
perdant sa provenance** provoque un retour au décor natif ; une
primitive ajoutée dans un clone local est également rendue non physique
immédiatement. La prochaine passe LOD reconstruit seulement les clones
depuis les sources approuvées intactes.

La suite Roblox Engine existante a reçu des assertions sur les cinq
mondes, couvrant l'injection d'une huitième primitive, son innocuité
physique, le retour natif, la récupération et le plafond Android High
de trois vrais portiques. **L'ajout de ces assertions ne suffit pas à
revendiquer leur exécution réussie sur le SHA final.** Ni capture
Android/Studio ni mesure FPS ni publication ne sont revendiquées ici.

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
