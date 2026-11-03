# Chaos Survival — quatre véritables façades/toitures 3D originales

**3 novembre 2026.** Cible : **VIS-011 / VIS-032 / VIS-029** et remplacement des bâtiments Roblox génériques par des meshes industriels modulaires de qualité vérifiable. Le lot crée et valide de nouvelles sources 3D, **sans prétendre à leur présence en jeu avant approbation Roblox et intégration runtime**.

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

## Creator-owned import confirmed; runtime integration

The four one-time Roblox Open Cloud import jobs all returned a **real approved Model package ID** (not a glTF preview URL): [run #41629861517](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41629861517). Exact verified IDs: observatory `132020956214241`, freight `88725004643299`, turbine `84217436280282`, aerial `135791763112202`.

`PremiumDistrictFacadeAssets.lua` now loads only these four IDs on the server, sanitizes each into inert approved MeshParts using `OriginalMeshScenery.sanitize`, and publishes authenticated templates in ReplicatedStorage. Any failed moderation/load/geometry check leaves the original authored native building intact.

`PremiumDistrictFacadeMeshKit.lua` composes the real 3D roofs and facades on the existing sixteen buildings, choosing the four profiles by verified `DistrictProfile`, anchored to the actual `ServiceEntryDoor` and its authored rotated building origin. All imported parts are **client-local, cosmetic, anchored, noncolliding, non-queryable and shadow-free**. The existing scenery LOD scheduler caps residency at **Low 1 / Medium 3 / High 6** nearest buildings, with 130/190/255-stud distances; no new frame poller, network remote or additional gameplay geometry. No existing server doorway or district wayfinding is removed.

**Release acceptance:** branch Luau compilation, mobile VFX gate, full Rojo build, then main exact-SHA Build Validation and all five Roblox Cloud engine shards. Source and engine passing cannot certify actual Roblox import orientation, mobile memory/FPS, or screenshots; the Android visual review is still outstanding.
