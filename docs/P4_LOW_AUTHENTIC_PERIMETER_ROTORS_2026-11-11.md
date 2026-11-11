# P4 — Trois turbines originales 3D sur Android Low

**11 novembre 2026.** Source inspectée : `dbrckk/chaos-survival-roblox` à
`2ff9048ad25a227fc55790998b0d42e8512a2206`. La dernière Place publique vérifiée était `f929326` ;
le présent changement n'est pas déployé par la fusion GitHub.

## Défaut

Sur les quatre stations périphériques des cinq arènes, les trois
turbines `IntakeTurbineL`, `IntakeTurbineR` et `GeneratorRotor`
restaient des Parts cylindriques sur Android Low. Le kit client
existant les remplaçait déjà sur Medium et High avec les véritables
modèles 3D créateur-approuvés, mais portait un cap `Low=0`.

Le Model propriétaire `133526819668194`, nommé `perimeter_rotor`,
est approuvé par Roblox (workflow `42691052644`). Le chargeur serveur
existant `PremiumPerimeterRotorAssets.lua` l'importe de manière
asynchrone à partir de 74 secondes par
`PremiumApprovedAssetImportGate`, avec un maximum de deux imports
simultanés sur l'ensemble des assets.

## Changement vérifiable dans le code

- Autoriser au maximum **une station** sur Low à **130 studs** de
  la caméra (rétention 16 studs déjà présente). Le plus proche des
  quatre ensembles complets est choisi par le classement LOD existant.
- Les trois Parts cylindriques natives sont remplacées ensemble :
  chaque source authentique contient exactement **7 MeshParts**,
  soit **21 MeshParts locaux au maximum**. Les trois assemblages sont
  clonés, vérifiés et montés **avant** de masquer un seul cylindre.
- Au premier niveau de pression graphique (`stress=1`),
  `math.floor(1 * 0.5)=0` ; le repli existant restaure les trois
  cylindres sans ajouter de physique ni prendre le contrôle des
  signaux, dégâts, bots, lumières ou animations. Au niveau 2,
  le cap demeure zéro.
- Sur Medium : **une station à 170 studs**. Sur High :
  **trois stations à 245 studs**, ou deux sur écran tactile.
  Tous ces plafonds restent inchangés.
- Le dossier `ApprovedPerimeterRotorsLocal` existe déjà dans
  le ledger `VisualBudgetRules.LocalFolders`, donc les 21 MeshParts
  optionnelles sont comptées dans le quota Android de **440 Parts
  locales Low**. Le superviseur de pression existant gère leur retrait.
- **Aucun asset importé supplémentaire**, aucune texture 2K, aucun
  nouveau `task.spawn`, aucune boucle `RenderStepped`,
  collision, ni `RemoteEvent`.

## Limites et validation

Ce correctif augmente volontairement la complexité locale d'une
station proche et ne prouve pas une amélioration des FPS.
Le remplacement n'a lieu que si le source original est disponible,
si la station est entièrement chargée et si les contrôles de
géométrie, provenance et pression l'autorisent. Dans le cas
contraire, les cylindres natifs restent visibles.

Le script de régression source déjà présent
`tools/verify_original_3d_budget_census.py` vérifie la
provenance du modèle, le repli, le montage complet et le quota Low.
Il ne certifie pas une mesure Android, ni une capture Studio, ni un
rendu Roblox Engine. Une nouvelle Build Validation, les tests
Roblox Engine sur le SHA exact et une publication publique
explicite seront nécessaires après fusion.
