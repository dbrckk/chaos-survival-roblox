# Chaos Survival — coque 3D originale fermée des quatre pylônes

**4 novembre 2026 · Asset Roblox ID `75945454705246` · Modération Roblox `Approved` · Import [#41825253849](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41825253849).**

## Remplacement visuel réel

Le lobby conserve quatre pylônes physiques `Pylon1..Pylon4` de **2,2 × 10 × 2,2 studs** placés aux angles de sa dalle de 74 studs. Le précédent remplacement en `MeshPart` `91626128452597` possédait une colonne 3D ouverte/étranglée au centre, laissant le volume du collider natif visible à 50 %. C'était sûr, mais pas une vraie conversion finale de la silhouette.

Le nouveau modèle a été entièrement créé en source reproductible par `tools/generate_original_lobby_pylon_shell.py` : corps métallurgique octogonal **fermé** de **2,84 × 10,36 × 2,84 studs**, chanfrein de 0,16, rails forgés, freinages latéraux, portes d'inspection, cassettes diélectriques et signalétique. Son noyau opaque est présent sur toute la hauteur ; **le noyau ne se limite pas à une bounding box**. La section diagonale critique du chanfrein respecte `2,84 - 0,16 = 2,68 > 2,2` studs, avec marge interne de 0,24 stud sur les coins. La hauteur dépasse la collision de 0,36 stud. Le rendu dispose de **sept matériaux réels, UV, normales et tangentes**, aucune pièce `Part` / `WedgePart` de remplacement.

L'importeur historique du projet a reçu le choix strict `lobby_pylon_shell`. Le workflow ponctuel a exécuté génération d'OBJ, conversion glTF 2.0, vérifications de triangles, attributs UV/TANGENT, fermeture et géométrie, **puis un seul POST non-idempotent** autorisé pour créer le Model Roblox au nom du propriétaire vérifié. La tâche d'import a renvoyé l'ID ci-dessus et la modération `Approved`. **L'ID de modèle est réel ; aucun AssetId n'a été inventé**.

## Intégration runtime et fallback

Le nouveau module serveur `PremiumLobbyPylonShellAssets.lua` charge uniquement cet ID approuvé via `AssetService.LoadAssetAsync`, de façon asynchrone et différée. Le nettoyage passe par `OriginalMeshScenery.sanitize` ; seuls 1–12 vrais `MeshPart` dans des dimensions de source contrôlées sont répliqués dans `ReplicatedStorage.ApprovedLobbyPylonShellTemplates` avec provenance, `OwnerVerified`, `OriginalLobbyPylonShell3D`, `EnclosesCollider`, `CosmeticOnly`.

Le composant client `lobby-pylon-original-3d.client.lua` choisit **en priorité la vraie coque intégrale**, centre chaque clone sur son pylône, tourne les panneaux de maintenance vers le centre du lobby et supprime uniquement **l'affichage local** du collider `PylonN` et des quatre anciens carénages `WedgePart/Part`. Le collider serveur **reste inchangé, ancré et actif**, avec ses vraies dimensions. Les lumières `PylonGlowN` et les `PointLight` associés ne sont jamais masquées. Les quatre modèles sont préparés avant montage pour éviter une demi-conversion visible.

La transition est entièrement réversible :
- Si la nouvelle coque n'a pas encore chargé, le véritable ancien asset 3D peut servir de repli ; son noyau natif reste alors **semi-visible à 50 %** pour ne créer aucun obstacle invisible.
- Si les deux assets sont absents ou rejetés par leurs vérifications, toutes les primitives natives restent présentes.
- En cas de changement de carte, de tier, de pression FPS, de source, ou de retrait inattendu d'un `MeshPart`, les masques locaux sont annulés puis les éléments reconstructibles remontés.
- Aucune collision, pathfinding, ombre, nouvelle lumière, nouvelle boucle `RenderStepped` ou requête Roblox asset côté client n'est ajoutée.

## Économie Android et validation

| Qualité | Pression FPS 0 | Pression 1 | Pression 2 |
|---|---:|---:|---:|
| Low | 0 | 0 | 0 |
| Medium | 4 coques | 2 | 0 |
| High | 4 coques | 4 | 2 |

Les modèles sont comptés dans `VisualBudgetRules.LocalFolders` sous `OriginalLobbyPylons3DLocal`. Diagnostic réel : `LocalOriginalLobbyPylon3DCount`, `LocalOriginalLobbyPylonMeshPartCount`, et **`LocalOriginalLobbyPylonFullShellCount`** (ne compte que les véritables coques fermées installées).

## Conditions avant publication

1. Build, lint et sept suites Roblox Cloud au commit final de ce lot.
2. En Studio/Android : constater les quatre coques, la silhouette opaque à 360°, absence d'écarts entre collision et art, orientation des panneaux, visibilité intacte des chapeaux lumineux, absence de modèles primitifs concurrents.
3. Forcer un CDN/asset indisponible, le streaming/rechargement de carte et les basculements de qualité pour vérifier les deux niveaux de repli.
4. Mesurer FPS, objets en scène, temps de chargement après 23 s de différé, et affichage des panneaux.
5. **L'approbation de l'asset et des tests de code n'atteste pas d'un rendu Android ni d'une mise à jour publique.**
