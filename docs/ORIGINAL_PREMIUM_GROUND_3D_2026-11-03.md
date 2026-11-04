**Complément — 4 novembre 2026 :** les modèles 3D validés/UV du sol reçoivent désormais les quatre vrais canaux des textures PBR 2K approuvées, par clonage de SurfaceAppearance sérialisés en Rojo. Les cinq arènes ont des matériaux dominants distincts ou des combinaisons de familles originales ; budgets Android adaptatifs High 6/3/1, Medium 2/1/0, Low 0. Contrôle de source/périphérique toujours requis. [Dossier détaillé](ORIGINAL_GROUND_2K_UV_PBR_FIVE_ARENAS_2026-11-04.md).

# Visuel AAA : vraie dalle industrielle 3D (source, avant import Roblox)

**Date** : 3 novembre 2026. **Priorités** : VIS-008 (grandes surfaces de sol), VIS-032 (géométrie UV industrielle originale). **Ce jalon est la création du vrai modèle 3D, pas encore son utilisation certifiée dans le jeu.**

## Livrable vérifié

Le script source maintenable `tools/generate_premium_ground_tile.py` émet un OBJ triangulé original, reproductible, avec :
- **2 976 vrais triangles, 1 984 vertices OBJ, 152 groupes mécaniques**, sept matériaux métalliques/carbone/céramique industriels ;
- dimensions **48,5 × 48,5 studs**, compatibles avec les cases du sol 6 × 6 (49,13 studs) des cinq arènes ;
- 16 plaques octogonales réellement biseautées avec trois niveaux de profil, 64 boulons octogonaux, inserts antidérapants, rails séparateurs et poutres de châssis sous la surface ;
- finition entre Y = **−0,226 et +0,033 stud**, sans arête artificielle assez haute pour modifier les sauts ni recouvrir les marquages du danger déjà surélevés ;
- UV et tangentes générées dans le glTF 2.0 par `tools/obj_to_gltf.py`, métallurgie PBR via glTF metallic/roughness. Les **textures normales 2K Roblox déjà approuvées** restent utilisées sur les surfaces natives sous-jacentes : ne pas prétendre que la nouvelle mesh importée dispose déjà de 2K normal maps.

Preuve de production source : [Luau + Rojo + générateur + UV/tangentes + budget visuel, tous réussis](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41622514593). Les commandes exécutées incluent `python3 tools/generate_premium_ground_tile.py --output assets/source/chaos_premium_ground_tile.obj`, puis `python3 tools/obj_to_gltf.py --source assets/source/chaos_premium_ground_tile.obj --materials assets/source/chaos_route_kit.mtl --output build/mesh-previews/chaos_premium_ground_tile.gltf`.

## Publication de l'asset

Le workflow ponctuel `one-time-import-premium-ground-3d-20261103.yml` déclenche l'import du nouveau Model sous l'inventaire utilisateur Roblox existant (`9774173158`), en passant obligatoirement par `upload-original-3d-models.yml` qui vérifie la provenance, les modèles autorisés, les droits du créateur, l'API et la modération. **Il n'affecte pas le jeu public.**

Ne jamais inventer l'AssetId. Vérifier l'état de modération `Approved` et l'ID modèle authentique dans les journaux de l'Action et/ou le manifeste avant de l'ajouter à `PremiumRouteMeshAssets.lua`, au registre et au code client.

## Conditions obligatoires pour intégrer sur les cinq arènes

1. Garder **le sol de collision serveur existant** ; cloner le MeshPart seulement en décor local, sans collisions, touch, query, scripts ni ombre de portée.
2. Monter le modèle sur la case `PremiumGroundModule1..36` réelle, avec transformation et échelle conformes à sa position/rotation, sous les avertissements de danger, sans z-fighting.
3. Contrôler les budgets par caméra : **Low maximum 1 case, Medium 3, High 6**, sans créer de RenderStepped ni augmenter les quotas MaterialService PBR 2K.
4. Cacher et détruire toute dalle importée immédiatement lors du `ShrinkingArena`, ou si sa case rétrécit, disparaît ou quitte la carte ; le sol natif doit toujours rester visible et praticable.
5. Éviter la collision avec les signes de danger, les panneaux de guidage, les points de spawn et les autres modèles ; valider moteur Roblox, source exact-SHA, publication publique via le workflow existant.
6. Réaliser les captures réelles Studio et mesures Android Low/Medium/High avant de cocher `VIS-008` **terminé AAA**.

**Note technique** : le générateur est le fichier source maintenu en Git, tandis que l'OBJ et le glTF sont générés et validés dans les workflows. Aucun asset tiers ni fichier binaire sous licence externe.

## Import réellement confirmé et branche de rendu cinq-arènes

Le workflow Roblox `41622860616` a confirmé l'**approbation de modération** de la nouvelle pièce 3D authentique, sous l'ID de package Model `72507987666671`, appartenant au créateur existant. [Preuve de l'import](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41622860616).

**Intégration runtime source** (non publiée tant que les contrôles final SHA ne sont pas verts) :

- `assets/source/roblox-asset-registry.json` contient la 9e entrée uniquement après la vraie réponse Roblox, pas d'ID inventé ;
- `PremiumRouteMeshAssets.lua` charge le troisième modèle dans `ReplicatedStorage.PremiumRouteMeshTemplates` après sanitisation stricte des scripts/effects, avec conservation uniquement des véritables `MeshPart` ; si indisponible, le sol de base reste présent ;
- `PremiumGroundMeshKit.lua` ne clone que les vraies `PremiumGroundModule1..36` originales qui sont déjà non-collidantes et sous le contrôle de `ShrinkingArena` ; aucun changement du `Base` ni du danger ;
- le dessin 3D supérieur est placé à **+0,032 stud** au-dessus du centre de chaque dalle existante, donc à ~**0,185 stud au-dessus du sol physique**, sous les pictogrammes d'alerte relevés à ~0,19/0,20 stud ;
- trois budgets locaux en fonction de la caméra : **Low 1 / Medium 3 / High 6** modèles, avec tous leurs `MeshPart` comptabilisés dans `VisualBudgetRules.LocalFolders`. Aucun nouveau `RenderStepped` ni appel Roblox asset côté client ;
- le premier redimensionnement/mouvement du sol cache immédiatement les vrais MeshParts ; le prochain passage du LOD les détruit. Le décor natif et les matériaux PBR 2K du sol sont conservés comme fallback. Les changements de carte libèrent tous les clones ;
- les contrôles exacts du code original, du build, des cinq suites moteur, de la provenance des IDs et de l'absence de collision doivent encore réussir avant publication. **Pas de validation AAA sur écran Android sans captures réelles.**

**Différence essentielle :** la topologie et les UV sont vraiment ceux du modèle importé, mais l'effet de brillance PBR vient des facteurs metallic/roughness du glTF et des matériaux 2K natifs sous-jacents. Une normal map 2K directement posée sur chaque nouveau MeshPart serait un autre travail à tester et budgéter, pas une caractéristique livrée ici.

## 4 novembre 2026 — couverture maximale réelle du grand sol par les MeshParts existants

**Changement produit :** le kit qui montait déjà de véritables dalles 3D approuvées ne profitait pas de tout le damier physique de 36 cases en qualité High. L'ancien maximum de 24 laissait **12 cases sur 36** en finition native, sans même tenir compte de la distance caméra. Le nouveau plafond High est **36/36**, Medium **12/36** au lieu de 8 et Low **2/36** inchangé. Les 36 plaques utilisent le **même véritable asset original approuvé**, pas des primitives inventées, et la sélection reste spatiale : les dalles hors portée ou non répliquées ne créent pas de MeshPart.

**Adaptation immédiate aux vrais appareils Android :** le recensement et l'échantillonnage FPS/frametime déjà présents produisent `OptionalVfxPressure=0/1/2` avec hystérésis. Sur le même cycle LOD existant, le maximum de modèles devient :

| Qualité | Normal | Pression modérée | Pression forte |
| --- | ---: | ---: | ---: |
| Low | 2 | 2 | 1 |
| Medium | 12 | 8 | 4 |
| High | 36 | 24 | 16 |

Chaque dalle représente **2 976 triangles** et au plus sept `MeshPart` par modèle ; budget géométrique maximal en situation normale : High **107 136 triangles**, Medium **35 712**, Low **5 952**. Cela s'ajoute aux autres assets présents et ne garantit pas un FPS donné : la pression observée rétablit automatiquement une couverture plus légère. Aucun nouveau timer, `RenderStepped`, chargement réseau, collider ou surface fictive. Le clone continue à être retiré et le décor natif restauré lors d'un changement de carte, du rétrécissement ou d'une sortie de champ LOD. Toutes les alertes restent devant la vraie surface jouable.

**Contrôle à accomplir :** la validation moteur du commit final et des captures réelles sur Android (Low/Medium/High, caméra devant/derrière, catastrophe Shrinking Arena et stress FPS). Le registre de 50 vrais assets reste inchangé : c'est une amélioration de **couverture réelle** des assets déjà disponibles, pas une nouvelle importation. Ce travail ne certifie pas à lui seul la qualité AAA finale ni la mise à jour publique.
