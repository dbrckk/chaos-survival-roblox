# Intégration 3D originale dans les arènes Roblox — 24 octobre 2026

## État exact

Le code serveur charge désormais les trois **Model packages Roblox approuvés** créés dans l'inventaire du compte `Drackk_08` (ID 9774173158). L'intégration est **préparée dans les sources** ; elle ne devient visible au public qu'après la publication distincte d'une place Roblox qui contient ces scripts. Ni la réussite CI, ni l'ID d'un asset ne prouvent un bon rendu sur un vrai appareil Android.

- `reactor_spire` : `102992487644269`
- `service_crane` : `119468460691888`
- `perimeter_gate` : `137284215564363`

Source d'authenticité : `assets/source/roblox-asset-registry.json`, maintenu en cohérence avec les IDs du code par la validation CI.

## Architecture

- **Serveur :** `src/server/OriginalMeshScenery.lua`. Le lancement, depuis `init.server.lua`, intervient après la création de la carte. Trois chargements asynchrones via `AssetService:LoadAssetAsync` (jusqu'à trois tentatives bornées, uniquement en cas d'échec transitoire), sans faire attendre le round, les téléportations ou l'interface. Les modèles une fois reçus sont mis en cache en mémoire pour les arènes successives, sans nouveau téléchargement à chaque manche.
- **Contrôle de sécurité :** nous extrayons au maximum 24 `BasePart` par package, supprimons chaque script, contrainte, son et effet contenu dans les clones, et n'autorisons que `SurfaceAppearance`, `Decal` et `Texture` comme descendants visuels inertes. Chaque pièce est ancrée et ne peut ni entrer en collision, ni déclencher `Touched`, ni interférer avec les requêtes spatiales ou projeter une ombre.
- **Quatre destinations par arène, quatre identités visuelles :** placements entièrement extérieurs dans `GeneratedMap/Arena/Decor/Original3DScenery`. `Classic` utilise deux portes, un réacteur et une grue ; `Towers` deux grues, une porte et un réacteur ; `Crossroads` deux grues et deux portes ; `Orbital` deux réacteurs et deux portes. Les reculées extérieures s'adaptent aux dimensions de chaque modèle pour préserver la lisibilité et éviter tout chevauchement de la zone jouable.
- **Changement de carte :** lorsqu'une arène est reconstruite, les mêmes modèles déjà chargés sont clonés dans la nouvelle arène. La connexion serveur ne conserve pas les anciens modèles. Les quatre arènes `Classic`, `Towers`, `Crossroads` et `Orbital` utilisent le même système.
- **Repli :** si Roblox refuse l'accès au package, si le chargement réseau échoue ou si la géométrie est invalide, **l'arène native est entièrement conservée et jouable**.
- **Android :** `src/client/scenery-lod.client.lua` réutilise sa boucle de niveau de détail existante. Profil **Low** : modèles importés masqués ; profil **Medium** : affichage à moins de 140 studs du centre avec hystérésis ; profil **High** : affichage complet. Aucun nouveau cycle `RenderStepped`.

L'attribut `Original3DSceneryCount` de l'arène donne le nombre de placements installés (0 à 4). `Original3DSceneryComplete=true` indique la présence des quatre décorations importées, **pas** une validation de la modération visible, des textures ou du FPS Android.

## À vérifier avant publication

1. Vérifier que l'expérience peut charger des assets appartenant à **Drackk_08**. Si le propriétaire de l'expérience est un groupe ou un autre compte, accorder explicitement à l'expérience l'accès aux modèles dans Creator Dashboard, ou les recréer avec le bon propriétaire. **Ne pas activer les assets tiers publics** pour contourner les permissions.
2. Sur une expérience de **staging**, ouvrir successivement les quatre arènes. Le dossier `Original3DScenery` doit contenir deux portes, une grue et un réacteur. Vérifier `Original3DSceneryCount=4`.
3. Depuis Android, vérifier l'orientation, l'absence de flottement, les matériaux et le rendu sur Low, Medium et High, et le comportement de la caméra aux bords.
4. Contrôler l'absence de ralentissement, de double affichage gênant avec les décors natifs, et d'interférence avec les effets ou les zones de danger. Vérifier la destruction des anciennes arènes et le renouvellement des quatre décorations.
5. **Publier uniquement après contrôle**, par le workflow de publication public explicitement autorisé et doté de ses vérifications habituelles.

Roblox documente `AssetService:LoadAssetAsync` comme successeur de `InsertService:LoadAsset`, avec un modèle retourné sandboxé. Source officielle : https://create.roblox.com/docs/reference/engine/classes/AssetService.
