# Importer nos modèles 3D Roblox depuis Android — sans PC

**État : procédure préparée, aucun nouvel upload vérifié.** Ce workflow crée un **Model asset** dans l'inventaire Roblox du créateur. Il ne publie pas le jeu et n'ajoute aucun objet dans une arène.

Roblox Open Cloud accepte les fichiers **glTF** pour la création d'assets de type **Model**, avec un ou plusieurs MeshParts importés ; l'import direct de fichiers OBJ comme type Mesh n'est pas disponible via cette API. Source officielle : https://create.roblox.com/docs/cloud/guides/usage-assets

## Configuration initiale dans GitHub (une fois, pour les imports réels uniquement)

Le premier essai **dry-run** ne demande ni clé Roblox ni ID de créateur ; tu peux le lancer directement depuis Android.

1. Sur https://create.roblox.com/dashboard/credentials, crée une **clé API distincte** autorisée à gérer les Assets du bon créateur Roblox, avec les droits **Read/Write** nécessaires. Une clé de publication Universe/Place ne donne pas automatiquement les autorisations Assets. Ne poste jamais la clé dans une issue, un message ou un fichier.
2. Dans le dépôt GitHub, ouvre **Settings → Secrets and variables → Actions → New repository secret**, nom exact `ROBLOX_ASSET_API_KEY`, colle la valeur. Ne remplace pas `ROBLOX_API_KEY` qui sert déjà à publier/tester le jeu.
3. Trouve l'ID numérique du **même utilisateur ou groupe Roblox qui doit posséder les nouveaux modèles**. C'est le compte ou groupe autorisé par la clé. Il doit posséder/autoriser les assets dans l'expérience Chaos Survival.

## Lance le workflow sur smartphone

1. Ouvre https://github.com/dbrckk/chaos-survival-roblox/actions/workflows/upload-original-3d-models.yml et touche **Run workflow**.
2. Sélectionne la branche `main`. Dans `model`, choisis `reactor_spire`, `service_crane` ou `perimeter_gate`. Le modèle `perimeter_gate` utilise automatiquement son fichier palette `chaos_perimeter_gate.mtl` (différent de celui des deux autres modèles).
3. **Premier passage sans clé ni ID :** laisse `creator_kind=user`, `creator_id` vide et `dry_run=true` (valeur par défaut). Lance et vérifie la validation des triangles, des matériaux et du glTF. Aucun appel d'upload Roblox n'est fait. Dans le run réussi, rubrique **Artifacts**, télécharge `chaos-original-mesh-preview-<modèle>` : il contient le vrai fichier glTF (géométrie et palette intégrées) et son rapport de validation, affichables avec un lecteur glTF sur Android.
4. Pour créer réellement l'asset, renseigne alors `creator_kind` = `user` ou `group` et son `creator_id` numérique autorisé. Repasse `dry_run=false` et écris exactement `UPLOAD_CHAOS_ORIGINAL_3D` dans `confirmation`. L'action essaiera **un seul envoi** et attendra la réponse Open Cloud. Elle archive uniquement le nouvel asset ID et l'état de modération, jamais la clé.
5. Si Roblox répond **401/403**, vérifie les droits du nouveau secret sur Assets et le propriétaire. Si Roblox refuse un modèle pour des raisons d'import/modération, conserve le modèle d'origine. Il ne faut pas forcer les permissions ni utiliser des IDs inventés.

## Intégration visuelle après l'import

Le modèle Perimeter Gate est conçu pour les quatre stations périphériques déjà présentes dans chaque arène. Les modèles Reactor Spire et Service Crane sont destinés à des décors extérieurs (hors trajectoires et zones de catastrophe). **Ce workflow ne les insère jamais tout seul dans le jeu public** : la création de l'asset ne garantit pas son approbation ni sa disponibilité. Il faut d'abord relever les ID Roblox réels depuis les artifacts du workflow, puis les contrôler sur une expérience de staging distincte. Les objets provenant d'un asset doivent être dépourvus de scripts et tous leurs MeshParts doivent être ancrés, sans collision, contact, requête ni ombres avant installation.

## Après création du Model asset

- L'upload produit un **package Model** appartenant au créateur. Un asset ID réussi ne signifie ni qu'il est déjà visible dans la partie, ni qu'il est approuvé, ni qu'il fonctionne correctement sur Android.
- Avant l'intégration, il faut inspecter l'asset dans Roblox/Studio ou une expérience staging autorisée, vérifier les matériaux, l'échelle, les normales et les coûts graphiques.
- Ajouter uniquement l'**ID réel, approuvé et autorisé** dans les sources Roblox, avec une solution de repli utilisant les décors procéduraux existants. Les modèles restent des décorations, sans collision, toucher, requête ou ombres inutiles.
- Tester les quatre arènes (Low/Medium/High), les dangers et la fluidité Android **avant** la nouvelle publication manuelle publique.

La génération glTF est effectuée par `tools/obj_to_gltf.py`, écrit en Python standard sans Blender, à partir des OBJ et du fichier MTL propre à chaque modèle sous `assets/source/`. **Les trois modèles sont désormais contrôlés par Build Validation** : intégrité des buffers, triangles et palettes, sans faire d'upload. Les fichiers source demeurent modifiables.

**Important :** la clé API est un secret GitHub nécessaire à l'exécution réelle ; aucun assistant n'en a besoin en clair. Les données Roblox des joueurs, le DataStore, les achats et le jeu public ne sont pas modifiés par ce workflow.
