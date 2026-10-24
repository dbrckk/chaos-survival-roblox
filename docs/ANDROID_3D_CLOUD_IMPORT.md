# Importer nos modèles 3D Roblox depuis Android — sans PC

**État : procédure préparée, non exécutée.** Ce workflow crée un **Model asset** dans l'inventaire Roblox du créateur. Il ne publie pas le jeu et n'ajoute aucun objet dans une arène.

Roblox Open Cloud accepte les fichiers **glTF** pour la création d'assets de type **Model**, avec un ou plusieurs MeshParts importés ; l'import direct de fichiers OBJ comme type Mesh n'est pas disponible via cette API. Source officielle : https://create.roblox.com/docs/cloud/guides/usage-assets

## Configuration initiale dans GitHub (une fois)

1. Sur https://create.roblox.com/dashboard/credentials, crée une **clé API distincte** autorisée à gérer les Assets du bon créateur Roblox, avec les droits **Read/Write** nécessaires. Une clé de publication Universe/Place ne donne pas automatiquement les autorisations Assets. Ne poste jamais la clé dans une issue, un message ou un fichier.
2. Dans le dépôt GitHub, ouvre **Settings → Secrets and variables → Actions → New repository secret**, nom exact `ROBLOX_ASSET_API_KEY`, colle la valeur. Ne remplace pas `ROBLOX_API_KEY` qui sert déjà à publier/tester le jeu.
3. Trouve l'ID numérique du **même utilisateur ou groupe Roblox qui doit posséder les nouveaux modèles**. C'est le compte ou groupe autorisé par la clé. Il doit posséder/autoriser les assets dans l'expérience Chaos Survival.

## Lance le workflow sur smartphone

1. Ouvre https://github.com/dbrckk/chaos-survival-roblox/actions/workflows/upload-original-3d-models.yml et touche **Run workflow**.
2. Sélectionne la branche `main`. Dans `model`, choisis `reactor_spire` ou `service_crane`.
3. `creator_kind` = `user` pour un compte ou `group` pour un groupe ; renseigne son ID numérique exact.
4. **Premier passage prudent :** laisse `dry_run=true`, lance et vérifie que la validation des triangles, des matériaux et du glTF est réussie. Aucun appel d'upload Roblox n'est fait.
5. Pour créer réellement l'asset, repasse sur `dry_run=false` et écris exactement `UPLOAD_CHAOS_ORIGINAL_3D` dans `confirmation`. L'action essaiera **un seul envoi** et attendra la réponse Open Cloud. Elle archive uniquement le nouvel asset ID et l'état de modération, jamais la clé.
6. Si Roblox répond **401/403**, vérifie les droits du nouveau secret sur Assets et le propriétaire. Si Roblox refuse un modèle pour des raisons d'import/modération, conserve le modèle d'origine. Il ne faut pas forcer les permissions ni utiliser des IDs inventés.

## Après création du Model asset

- L'upload produit un **package Model** appartenant au créateur. Un asset ID réussi ne signifie ni qu'il est déjà visible dans la partie, ni qu'il est approuvé, ni qu'il fonctionne correctement sur Android.
- Avant l'intégration, il faut inspecter l'asset dans Roblox/Studio ou une expérience staging autorisée, vérifier les matériaux, l'échelle, les normales et les coûts graphiques.
- Ajouter uniquement l'**ID réel, approuvé et autorisé** dans les sources Roblox, avec une solution de repli utilisant les décors procéduraux existants. Les modèles restent des décorations, sans collision, toucher, requête ou ombres inutiles.
- Tester les quatre arènes (Low/Medium/High), les dangers et la fluidité Android **avant** la nouvelle publication manuelle publique.

La génération glTF est effectuée par `tools/obj_to_gltf.py`, écrit en Python standard sans Blender, à partir des OBJ et du fichier MTL originaux sous `assets/source/`. Les fichiers source demeurent modifiables.

**Important :** la clé API est un secret GitHub nécessaire à l'exécution réelle ; aucun assistant n'en a besoin en clair. Les données Roblox des joueurs, le DataStore, les achats et le jeu public ne sont pas modifiés par ce workflow.
