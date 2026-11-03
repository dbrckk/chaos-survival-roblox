# Cinq nouveaux équipements industriels 3D originaux — 3 novembre 2026

## Déploiement source
Le pack remplace les silhouettes primitives de **cinq machines de proximité**, chacune développée comme un OBJ triangulé distinct via `tools/generate_original_service_equipment.py`. Les modèles disposent de véritables volumes, perçages apparents, brides, renforts, vis, nervures et conduits, UV et tangentes glTF, et **sept familles de matières de facteurs PBR** (sans prétendre à des textures raster 2K tant qu'aucune carte n'est attachée).

| Arène | Nouveau modèle | Roblox Model approuvé |
| --- | --- | --- |
| Classic | station optique de surveillance à lentilles multiples | `108954400662606` |
| Towers | meuble technique blindé à verrous/ventilation | `106083832432833` |
| Crossroads | borne directionnelle à capteurs et guides | `94223777350022` |
| Orbital | conteneur énergétique à bagues de confinement | `127295681925871` |
| Harbor | double bollard d'amarrage industriel | `137255432266916` |

**Preuve d'upload et modération :** [workflow source + cinq imports approuvés #41729439190](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41729439190). L'import est un acte de création d'assets dans le compte Roblox du propriétaire ; **ce n'est pas la publication du jeu**. IDs enregistrés dans `assets/source/roblox-asset-registry.json`, jamais inventés.

## Montage authentique, sans faux collider
- Serveur : `src/server/PremiumServiceEquipmentAssets.lua` charge les modèles allowlistés, un à un et après le début de partie, puis les nettoie via `OriginalMeshScenery.sanitize` et contrôle leur contenu `MeshPart`, leurs dimensions et leur identité de source.
- Client : `src/client/PremiumServiceEquipmentMeshKit.lua` choisit les équipements les plus proches de la caméra dans `ArenaServicePropsLocal`, positionne et met à l'échelle les véritables meshes de chacun. **Seulement après la réussite du montage**, toutes les pièces natives de la même machine sont masquées, y compris les couches décoratives primitives.
- Les clones sont `Anchored`, `Massless`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false`. La vraie surface de jeu n'est pas modifiée ; les anciens éléments restent dans l'owner et sont récréés sans altération en cas de chargement raté.
- **Budget d'import local : Low 1 / Medium 2 / High 4 vrais modèles maximum parmi 2 / 4 / 6 bornes natives.** Chaque source possède au plus 12 MeshParts, déjà comptés par `VisualBudgetRules.LocalFolders`. Le nombre d'instances montées est exposé par `LocalOriginalServiceEquipment3DCount`.
- Les vrais MeshParts sont des enfants directs de `ArenaServicePropsLocal` afin que les systèmes existants `scenery-lod.client.lua` et `ArenaFloorFollowerKit.lua` les masquent/déplacent pendant les changements de qualité, de caméra et le rétrécissement du sol. Aucun nouveau propriétaire de Heartbeat ni RenderStepped.
- Le client réagit à l'arrivée tardive des templates importés et recrée le petit bundle local, sans modifier une seule collision. Aucune API Roblox n'est appelée par le client.

## À valider avant publication
Il ne faut pas confondre la réussite de l'upload avec une validation visuelle Android. Sur le **SHA exact** de ce lot : Build Validation, toutes les suites moteur Roblox Cloud, puis seulement la publication guarded si explicitement autorisée. Les captures Studio/Android doivent vérifier les proportions des cinq modèles, la lisibilité des warnings, la réponse du sol rétractable, les instances réellement remplacées, le FPS et la mémoire. Tant que cette QA n'est pas effective, ce lot demeure **intégré dans le code, pas certifié AAA ni confirmé en public**.
