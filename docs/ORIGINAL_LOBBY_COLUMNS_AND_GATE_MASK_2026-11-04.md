# Chaos Survival — quatre vraies colonnes du lobby et portique sans primitives superposées

**4 novembre 2026 — intégration source, aucune publication publique.**

## Problème constaté dans le dépôt

`MapBuilder.buildLobby` crée quatre pylônes natifs physiques de **2,2 × 10 × 2,2 studs** aux quatre coins du lobby. `StructureRetrofit.buildLobby` ajoute pour chacun quatre éléments décoratifs, dont deux `WedgePart` et deux collerettes natives ; ceux-ci restent immédiatement visibles, notamment depuis le spawn. Le portique d'entrée possède déjà un **véritable Model 3D original approuvé**, mais une veste native `MachinedArenaEntrance` de cinq Part/WedgePart peut rester dessinée devant.

## Remplacement 3D authentique

`lobby-pylon-original-3d.client.lua` réutilise le **Model créateur Roblox Approved `91626128452597`**, sculpture industrielle déjà importée et nettoyée côté serveur par `PremiumLargeStructureAssets` sous `ApprovedLargeStructureTemplates.Classic`. Le même modèle original est réemployé dans les arènes pour les supports : **aucun nouvel upload ni chargement à la demande du client**.

Le kit vérifie l'identifiant, le dossier certifié `OwnerVerified`, les attributs `CosmeticOnly` et `OriginalLargeStructure3D`, un contenu entièrement en `MeshPart` (1 à 12) sans code Lua et des dimensions de source de ~14 studs. Chaque clone est réduit à la hauteur réelle des 10 studs et ajusté horizontalement pour englober la collision native de 2,2 studs ; celle-ci n'est jamais supprimée, modifiée ou désactivée. **L'affichage des blocs natifs et des quatre pièces de carénage par colonne n'est masqué localement qu'une fois les vrais meshes montés.**

Le kit prépare la totalité du groupe sélectionné hors du monde, puis effectue la substitution en une fois. Si l'une des colonnes ne convient pas ou qu'un modèle approuvé manque, **tous les anciens pylônes demeurent visibles**. L'arrivée tardive des assets, le remplacement d'une carte, la perte inattendue d'un MeshPart ou les changements de niveau graphique rétablissent la substitution ou le retour natif de manière événementielle, sans RenderStepped.

`lobby-gate-original-3d.client.lua` conserve le portique original `136009650118642`, ses montants physiques et son SurfaceGui de phase. Il masque maintenant **uniquement cinq éléments non physiques de `MachinedArenaEntrance`** si et seulement si le véritable modèle 3D approuvé est présent et l'ensemble des cinq pièces est vérifié. Les pylônes `PylonGlow` et leurs lumières restent visibles et actifs.

## Budget Android et preuve

| Qualité | Pression normale | Pression 1 | Pression 2 |
|---|---:|---:|---:|
| Low | 0 | 0 | 0 |
| Medium | 4 colonnes | 2 | 0 |
| High | 4 colonnes | 4 | 2 |

La limite dure est quatre modèles et au plus **48 MeshParts** si l'asset source comporte douze pièces. Le nouvel owner `OriginalLobbyPylons3DLocal` est déclaré dans `VisualBudgetRules.LocalFolders` et partage les budgets d'instances existants (Low 440, Medium 680, High 900). Pas de lumière supplémentaire, collision, chemin, source d'image 2K, son ou boucle de rendu.

La télémétrie locale `LocalOriginalLobbyPylon3DCount` et `LocalOriginalLobbyPylonMeshPartCount` donne les montages présents ; elle ne prouve pas les images finales.

## Éléments encore à certifier

- Build et sept suites Roblox Cloud sur le commit final du lot.
- En jeu, capturer les quatre angles, les deux pylônes avant près du spawn et la perspective du portique : vérifier que les nouveaux meshes couvrent **réellement la silhouette des colliders**, qu'aucune collerette primitive ne dépasse et que le signal de phase de la porte reste parfaitement lisible.
- Android Low/Medium/High : compter les modèles, observer le déchargement sous pression, mesurer FPS, mémoire et chargement tardif des assets.
- Lors d'un retrait d'asset, d'un changement de qualité ou d'un nouveau lobby, vérifier que les collisions et les pylônes natifs reviennent correctement.
- Restent distincts : création de modules **originaux spécifiques au lobby** (une colonne réutilisée quatre fois est déjà authentique mais non unique), bornes et autres grandes pièces encore natives.

**Cette évolution est un remplacement visuel source, pas une validation AAA ni une preuve de publication du jeu.**
