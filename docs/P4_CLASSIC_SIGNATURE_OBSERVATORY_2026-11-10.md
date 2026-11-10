# P4 — Observatoire Classic sculpté et paraboles réelles

**10 novembre 2026.** Fabrication originale de l'observatoire signature Classic, sans déploiement de la Place.

## Contexte vérifié dans MapBuilder

`addArenaSignatureMegastructure` produit une mégastructure nord extérieure à la zone jouable. L'arène Classic contient sept masses géométriques particulièrement visibles encore natives : `PrimaryRelayMast` (Part 3×55×3), `RelayHead` (WedgePart 7×4,7×4,2), `DishBridge` (Part 30×1,2×2), `ReceiverDishWest/East` (Cylinder Part 0,8×10,5×10,5) et `ReceiverHubWest/East` (Part 2,1×2,1×2,1). Ce sont **sept pièces décoratives sans collision** qui conservent une empreinte claire dans le code source : mast y27,5, tête y58, pont y37, deux récepteurs x±13 aux élévations 41/47.

Les `RelayButtressWest/East`, `RelaySparWest/East`, `ServicePanel`, `Foundation` et `InsetBase` restent natifs. Il est inutile de toucher à leur physique ou aux règles de la carte.

## Géométrie originale

`tools/generate_original_signature_classic_observatory.py` fabrique une structure 3D originalement triangulée et de silhouette sculptée avec un mât en douze facettes à sept niveaux et conduits, tête profilée et renforts, traverse de récepteurs à garde-corps ajourés, **deux vraies paraboles concaves** (surface avant courbe et coque arrière distinctes) avec anneaux usinés en forme de tore creux, douze nervures radiales par parabole, moyeux et haubans. Ces détails sont modélisés en relief, pas peints sur une forme cylindrique.

L'art utilise les sept matériaux industriels PBR source du projet, UV/normales/tangentes via le convertisseur existant. Pour respecter les limites d'import source du pipeline `Sculpture`, les dimensions originales ont été uniformément normalisées au quart ; le client remettra l'asset à l'échelle en conservant ses proportions et sans transformation d'axes inégale. L'union native visée est d'environ **36,5×60,35×4,2 studs**.

Un workflow spécifique `.github/workflows/one-time-original-classic-observatory-20261110.yml` vérifiera l'OBJ et le glTF, les deux paraboles concaves, les matériaux et les bornes. Il créera ensuite uniquement un Model sur le compte créateur autorisé, sans publier de Place Roblox. Aucune valeur d'asset n'est considérée comme valide avant un reçu `Moderation: Approved`.

## Contrat runtime prévu

Un kit client ne masque **aucune** des sept primitives avant validation du Model entièrement importé et des sept MeshParts réels. Il doit reconnaître la véritable variante Classic, le bon emplacement de la mégastructure, les CFrames et dimensions exactes de `PrimaryRelayMast`, `RelayHead`, `DishBridge` et des quatre éléments dish/hub, ainsi que la présence des contreforts et du panneau d'information. La conversion reste purement cosmétique, LOD et streaming réversibles, et la pression GPU Android doit préserver les autres familles de décors.

**Aucune validation Roblox Engine, capture Android, mesure FPS ou publication publique sur ce commit.** Le taux source de couverture 3D des stations (16/23) est une population distincte, qui ne change pas avec ce travail.
