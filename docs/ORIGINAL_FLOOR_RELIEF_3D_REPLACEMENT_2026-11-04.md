# CHAOS SURVIVAL — six nouveaux reliefs de sol 3D originaux

**Date : 4 novembre 2026. Statut : sources intégrées dans `main` et six Roblox Model imports Approved.** Ne pas confondre ces preuves avec une certification Android, une validation du jeu publié ou des textures 2K.

## Géométrie originale réellement créée

`tools/generate_original_floor_relief.py` génère six fichiers OBJ sculptés distincts, triangulés, avec UV/normales/tangentes dans le glTF 2.0 vérifié et sept groupes de matières. Aucun modèle Marketplace et aucune Part Roblox ajoutée à la surface jouable.

| Cible | Modèle sculpté original | Asset Roblox Model ID |
|---|---|---|
| Low universel (six plaques par arène) | `relief_essential` : mâchoires de fixation, dents de traction, rivets réels, rainure centrale | `71267601603297` |
| Classic | `relief_classic` : trappe blindée, charnières, drainage, 4 rivets et marquage en retrait | `102746904688141` |
| Towers | `relief_towers` : rail d'expansion métallisé, neuf patins en relief et broches transversales | `74708751016233` |
| Crossroads | `relief_crossroads` : bande d'interverrouillage tactile, cinq rainures antidérapantes, profil dovetail | `84038993323581` |
| Orbital | `relief_orbital` : rail magnétique isolé, armure de renfort, sept écrans de flux | `123089585720736` |
| Harbor | `relief_harbor` : ferrures de ponton, renforts acier et cannelures, rouleau de charge | `94830155055482` |

**Preuve indépendante :** [six source gates et six imports Roblox avec `Moderation: Approved` — workflow #41736767816](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41736767816). Les identifiants et reçus sont dans `assets/source/roblox-asset-registry.json`.

## Montage sans altération gameplay

`PremiumFloorReliefAssets.lua` charge les six packages approuvés en différé, sérialisés et sanitisés. La provenance est strictement allowlistée et le contenu doit être un ensemble vérifié de vrais `MeshPart`.

`PremiumFloorReliefMeshKit.lua` remplace les grandes familles de plaques :
- `EssentialDeckPlate` / `EssentialDeckInset` en Low ;
- `ClassicReliefHatch` / `ClassicReliefHatchInset` ;
- `TowerReliefRib` / `TowerReliefRibLens` ;
- `CrossroadsRumble` ;
- `OrbitalReliefSegment` / `OrbitalReliefGlow` ;
- `HarborDeckCargoCleat` / `HarborDeckLoadLine`.

Le client convertit les meshes du Model en enfants directs du dossier `ArenaSurfaceReliefLocal` **avant l'appel existant à `ArenaFloorFollowerKit.bind`**. C'est impératif : le snapshot `Base.Size` doit déplacer/réduire ensemble les reliefs d'origine et les vraies pièces 3D pendant `ShrinkingArena`. **Aucune nouvelle boucle de rendu ni aucun listener de shrink supplémentaire.**

Les deux pièces natives d'une même finition sont masquées **après que tous les MeshParts 3D ont été préparés et rattachés**. Si l'import manque, elles restent visibles. Les meshes sont `Anchored=true`, `Massless=true`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false`. Le `Base` serveur, les plateformes physiques, l'IA, les catastrophes et leurs glyphes sont intacts.

## Budget Android

- **Low :** 6 modèles 3D de plaque universelle (au maximum 42 sous-meshes).
- **Medium :** 16 modèles de finition d'arène, suffisants même pour les seize bandes Crossroads.
- **High :** 28 modèles, suffisants pour toutes les bandes Crossroads High (au maximum 196 sous-meshes sur la seule arène active).

Les autres arènes ont entre 4 et 14 reliefs principaux, donc restent sous ces plafonds. Ils comptent dans `VisualBudgetRules.LocalFolders` grâce à `ArenaSurfaceReliefLocal` et passent par le LOD existant. Les contrôles de proximité ne changent pas le vrai terrain collision.

## Vérifications restantes

- Réussir Build Validation et sept suites Roblox Cloud sur le SHA source final, puis les tests visuels Studio/Android et la certification de publication uniquement lors d'un jalon autorisé.
- Vérifier hauteur/visibilité de chacune des finitions, absence d'intersection avec les pictogrammes de danger, état après shrink et FPS/mémoire sur Android Low et Medium.
- Ce lot **ne remplace pas encore** les petits `ReliefFastener`, `ReliefCornerBevel`, `HarborQuayTieDown`, ni toutes les pièces natives du lobby et des ponts. Leur origine/fonction devra être remplacée par une gamme d'assets dédiés plutôt que prétendre que toutes les primitives ont disparu.
- Les sept groupes métalliques ont des matériaux glTF et UV/tangentes, **pas de nouvelles cartes raster PBR 2K**. Les assets PBR raster déjà approuvés appartiennent à un autre chantier visuel.

Le registre conserve `floor_relief_models_inserted_in_game=false` tant que la publication du SHA exact n'est pas démontrée.
