# Chaos Survival — colonnes 3D originales et sous-châssis des grandes plateformes

**Candidat source, 4 novembre 2026 ; aucune publication du jeu public.**

## Lot 3D réellement produit et approuvé

Source originale : `tools/generate_original_large_supports.py`. Six modèles triangulés OBJ → glTF 2.0 (sept matériaux originaux, normales, UV et tangentes), dont **cinq pylônes de 14 studs** aux géométries propres à chaque arène et **un châssis ajouré de 22 × 10 studs** pour les grandes plateformes de promenade/colonne vertébrale du ciel. Les six imports ont tous réussi leurs contrôles et leur modération Roblox : [#41808940118](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41808940118).

| Type | Identifiant Roblox Model | Silhouette |
|---|---:|---|
| Classic | `91626128452597` | acier forgé, évents, rivets |
| Towers | `107521411452905` | guides hydrauliques, rails de levage |
| Crossroads | `93993697329658` | protège-pylônes, pare-chocs routiers |
| Orbital | `119010829781313` | circuits de flux, plaques diélectriques |
| Harbor | `76194593490199` | renforts de quai, assemblage métal/composite |
| LongCradle | `128914328933863` | vrai treillis sous les longues routes aériennes |

Une coque carrée **indépendante** `large_deck_hull` (`125929150866282`) couvre les hubs de 18 studs ; cette réalisation complémentaire est préservée sans duplication avec les nouveaux pylônes et châssis longs. Le registre commun comporte désormais **50 modèles approuvés**, mais sa présence n'est pas une preuve de chargement réussi en jeu.

## Fonctionnement réel, sécurité et repli

- `src/server/PremiumLargeStructureAssets.lua` utilise une allowlist de six ID authentifiés, `OriginalMeshScenery.sanitize`, un contrôle de dimensions/nombre de `MeshPart` et un chargement facultatif décalé. Aucun objet de gameplay, collision ou événement serveur n'est créé.
- `src/client/PremiumLargeStructureMeshKit.lua` accroche les colonnes **directement aux vrais supports `PlatformSupportN_M` de MapBuilder**. Un support haut peut recevoir jusqu'à trois tronçons de vraie géométrie 3D, avec un maximum de 12 `MeshPart` par tronçon (sept attendues). Seuls les supports complètement couverts peuvent être masqués ; les échecs conservent les originaux.
- `src/client/PlatformNativeTrimReplacementKit.lua` applique un masque **local et réversible** (`LocalTransparencyModifier`), uniquement sur la primitive de support source vérifiée ; elle ne détruit ni ne change les colliders. Les formes physiques restent disponibles sur le serveur à tout moment.
- Les supports créés restent soudés à leur support serveur qui suit le rétrécissement. Un unique signal `Size` par support adapte largeur et profils latéraux, sans nouvelle boucle `RenderStepped`. `PlatformFinishKit.captureRouteFootprint` les exclut d'un **second** redimensionnement : aucune contraction double.
- Les longues plateformes de `PromenadeStep` et `SkySpineStep` éligibles peuvent remplacer leur vieux bloc `PlatformUnderFrame` par un vrai treillis. La géométrie ne dépasse pas le colliseur et utilise la soudure du propriétaire de route actuel pour suivre son déplacement et sa contraction.
- `PremiumRouteMeshKit` renonce à ajouter son ancien chassis de 3 072 triangles sur les decks où `LocalOriginalLongCradleMounted` existe. La cohabitation de deux modèles lourds sur la même sous-face est évitée. L'attribut est purement cosmétique côté client, et redevient absent lorsque le modèle est désinstallé.
- Chaque vraie `MeshPart` est `Anchored=false`, `Massless=true`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false` et enregistrée dans `ArenaPlatformIdentityLocal`, déjà suivie par le recensement Android. Les phases `Warning/Gone` continuent de cacher les pièces premium.
- Budget source : **Low : 0**, **Medium : au maximum 8 modules de colonnes + 1 châssis long**, **High : 16 modules + 2 châssis longs**. Les autres plateformes continuent d'utiliser leurs supports et finitions d'origine. Aucun clone illimité au changement de caméra.

## Reste à vérifier avant de publier

1. Build Validation et sept suites Open Cloud du SHA exact : synthèse source, registre et contrats visuels.
2. Captures Android réelles en mode Low/Medium/High : comparer colonnes 3D, supports sources masqués, lisibilité des dangers et des routes.
3. Tester l'arrivée tardive des modèles via StreamingEnabled et AssetService (matériaux, orientation, tailles de MeshPart). Les builds statiques seuls ne remplacent pas cette vérification.
4. Catastrophes `Shrinking Arena` et `Disappearing Platforms` : vérifier la disparition et le redimensionnement des vrais treillis sans faux plancher ou poteau flottant.
5. Les **supports de toute la carte** ne sont pas encore remplacés. Les arènes de 320 studs, les centaines de modules serveur restants, les textures raster PBR complètes, les gros rails et les éclairages sont toujours des travaux distincts.

**Statut public : non publié.** `publication.large_support_models_inserted_in_game=false`. Les six nouveaux packages sont modérés **Approved**, pas « validés sur Android ».
