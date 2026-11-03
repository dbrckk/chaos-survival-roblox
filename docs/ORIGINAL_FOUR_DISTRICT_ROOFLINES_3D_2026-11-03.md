# Chaos Survival — quatre véritables façades/toitures 3D originales

**3 novembre 2026.** Cible : **VIS-011 / VIS-032 / VIS-029**. La première étape a produit et validé quatre sources originales ; **l'étape d'import a ensuite réussi et les quatre nouveaux assets ont été approuvés par Roblox**. L'intégration au runtime est traitée dans le lot source suivant, et **aucune nouvelle publication publique ni capture Android n'est encore certifiée pour celui-ci**.

## Art 3D original produit et techniquement validé

Le fichier maintenu `tools/generate_district_profile_meshes.py` produit quatre géométries OBJ **triangulées réelles** avec les mêmes groupes de matériaux finis que le kit 3D original des passerelles. Ce ne sont ni des `Part` ni de faux `MeshId`.

| Profil | Géométrie et fonction visuelle | Triangles source |
| --- | --- | ---: |
| Observatoire (`district_observatory`) | bardage industriel facetté, panneaux gravés, contreventements, pods d'instruments, anneau de visée et antenne | **1 524** |
| Fret (`district_freight`) | porteuses massives, profil de poutre lourde, tambours de treuil, câbles, suspentes et toit de manutention | **1 740** |
| Turbines (`district_turbine`) | trois chambres d'extraction, anneaux mécaniques, pales de turbine, châssis et collecteur thermique | **2 256** |
| Communications (`district_aerial`) | mât 3D triangulé, trois anneaux métalliques étagés, récepteurs céramiques, bras de soutien et pointe | **2 376** |

Base commune : véritables profils biseautés, pilastres mécaniques, rangées d'attaches, grilles d'inserts, capotage, rails et tenons, sans poser un plan rempli opaque devant le **couloir de l'entrée d'origine**. Les quatre profils restent géométriquement différents (hashes SHA256 distincts). Maximum autorisé dans le générateur : 14 studs d'écart horizontal, 46 studs de hauteur, 13 studs de profondeur.

**Source gate réellement réussi :** [GitHub Actions #41629230431](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41629230431). Les quatre versions `OBJ → glTF 2.0` ont été converties et inspectées : triangle count égal entre OBJ et glTF, tous matériaux conservés (6 ou 7), POSITION, NORMAL, TEXCOORD_0 et TANGENT sur chaque primitive, buffers et bounds corrects. Les glTF étaient archivés comme artefacts disponibles dans le workflow. Cette preuve **ne vaut pas vérification visuelle Roblox/Android**.

### Materials et honnêteté PBR

Les matériaux métalliques et céramiques utilisent la palette originale `assets/source/chaos_route_kit.mtl`, exportée via `tools/obj_to_gltf.py` avec facteurs glTF metallic/roughness. Il existe des UV et tangentes réels sur le mesh. **Aucune normal map 2K propre à ces quatre nouveaux meshes n'est encore importée** et aucun `SurfaceAppearance` 2K final ne doit être annoncé prématurément. Les matériaux PBR 2K déjà approuvés du sol, des façades natives et des passerelles restent inchangés.

## Import Roblox sécurisé et reproductible

Le workflow existant `.github/workflows/upload-original-3d-models.yml` reconnaît maintenant quatre choix de plus : `district_observatory`, `district_freight`, `district_turbine`, `district_aerial`. Avant upload, il régénère la source, vérifie la palette, le gabarit glTF et le creator ID. Le vrai upload utilise **uniquement** l'API Roblox Assets du créateur déjà connecté, la confirmation exacte `UPLOAD_CHAOS_ORIGINAL_3D`, la clé GitHub existante, la réponse de modération, et n'invente jamais de numéro de modèle.

Le workflow ponctuel `.github/workflows/one-time-import-four-district-profiles-20261103.yml` est limité au **premier commit sur `main` portant ce nouveau fichier**. Il appelle l'importeur déjà vérifié **en série**, afin de limiter l'afflux de jobs et les risques de quota. Il ne modifie **aucun** Universe/Place et ne déploie pas le jeu.

Il faut collecter pour chaque asset **le véritable ID Model et la modération `Approved`** dans les logs de l'import ponctuel, puis renseigner explicitement `assets/source/roblox-asset-registry.json`. Pas de placeholder de `MeshId` ni de désactivation du garde-fou du registre.

## Architecture de l'intégration en jeu — prochain jalon

- Charger les quatre packages approuvés depuis le serveur, les nettoyer via `OriginalMeshScenery.sanitize` et les mettre en cache une seule fois dans `ReplicatedStorage`. Les surfaces 3D importées doivent rester propres au créateur et sans scripts/constraints.
- Les cloner **uniquement côté client** sur les modèles district authentiques `ArenaDistrictArchitecture3D/District<Side><slot>`, selon `DistrictProfile=1..4`, et les ancrer sur les véritables portes et fondations pour conserver la bonne CFrame. **Sans collision, touch, query, ombre ni modification des bots ou zones de danger.**
- Garder les **16 corps de bâtiment natifs** comme structure de secours ; préférer les nouveaux bardages/toits de qualité quand leurs Model assets sont disponibles.
- Budget strict à mesurer : Low 1, Medium 2, High 4 modules 3D à proximité, et désactivation immédiate lors d'un changement de caméra/StreamingEnabled/arène ; compter **toutes les MeshParts**, pas seulement les conteneurs, dans `VisualBudgetRules`. Interdire toute nouvelle boucle `RenderStepped`.
- Vérifier que l'authored front ne recouvre pas les panneaux de signalisation de secteur, les warnings, ni les ouvertures architecturales. Différencier ensuite palette par arène sans importer des assets non approuvés.
- Au jalon de livraison **sur SHA exact** : Luau + Rojo, Build Validation, cinq suites moteur Cloud, publication uniquement après réussite, captures authentiques Studio/Android sur les cinq arènes en Low/Medium/High et mesure FPS/mémoire.

**À ce stade, la production des sources et leur conversion sont vérifiées ; la modération Roblox, les IDs propriétaires, l'insertion runtime et le contrôle sur téléphone sont des étapes distinctes qui ne peuvent être cochées sans preuve.**

## Import Roblox réellement confirmé après l'étape source

Le workflow ponctuel [#41629861517](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41629861517) a terminé **avec succès** les quatre jobs séquentiels le 3 novembre 2026. Les logs de chaque job prouvent le vrai résultat AssetService/Open Cloud et la modération `Approved` :

| Famille | ID Model officiel | Job de preuve |
| --- | ---: | ---: |
| Observatoire | `132020956214241` | `125896379760` |
| Fret | `88725004643299` | `125896565265` |
| Turbines | `84217436280282` | `125896733257` |
| Communications | `135791763112202` | `125896917704` |

Le registre `assets/source/roblox-asset-registry.json` est étendu de 9 à **13 vrais packages Model approuvés** après la preuve d'import, sans fabriquer des IDs de MeshPart.

### Intégration réelle dans le runtime

- `DistrictRooflineAssets.lua` utilise uniquement ces quatre IDs approuvés et **le sanitizer existant** `OriginalMeshScenery.sanitize`, réplique les templates sûrs dans `ReplicatedStorage` et charge la série dans un unique worker asynchrone non bloquant.
- `DistrictRooflineMeshKit.lua` apparie chaque profil `DistrictProfile=1..4` au véritable mesh original (observatoire/fret/turbine/communications) sur les modèles `ArenaDistrictArchitecture3D`, sans copier de geometry importée dans le serveur de gameplay.
- Chaque modèle 3D se place sur l'ancrage réel de `ServiceEntryDoor`, sans collision/Touch/Query ni ombre. Le profil de fret est reculé pour protéger les quatre signes de secteur existants. Aucun écran de sécurité ni collider du serveur n'est remplacé.
- **Plafonds fixes : Low 1 / Medium 2 / High 4 modèles,** rétention petite et priorité à la caméra. Toutes les nouvelles MeshParts sont recensées dans `OriginalDistrictRooflinesLocal` du budget graphique partagé ; aucun nouveau cycle par frame.
- Première diminution de la taille de l'arène et déplacement/stream-out d'une porte : retirer/cacher les clones immédiatement. Changement d'arène : vider les anciennes pièces ; asset non disponible : modèle natif inchangé.
- Le build de référence inclut maintenant la génération/validation des quatre nouveaux glTF, **13 IDs approuvés** et le contrôle que le registre correspond réellement aux IDs source.

### Limites avant certification AAA

La présence dans GitHub **n'atteste pas** que les nouveaux modèles ont été visibles sur une partie Roblox publique ou physiquement inspectés depuis Android. La prochaine release exige les mêmes contrôles *exact-SHA* que les précédentes (Rojo/Luau, cinq suites moteur Roblox Cloud, éditeur public gardé) et les captures Android/Studio restent nécessaires pour vérifier orientation, ombrage, signalétique, premier plan et qualité des textures. Ces modèles possèdent des UV/tangentes et des facteurs PBR mais **pas encore quatre normal maps 2K propres et mesurées sur smartphone**.
