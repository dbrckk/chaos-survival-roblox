# P4 — Pont industriel sculpté pour la mégastructure Towers

**Actualisation après import (10 novembre 2026) :** l'OBJ/glTF source a passé les contrôles de [l'action #42777274284](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42777274284) avec **3 042 triangles, sept matériaux et limites source 40,64 × 4,87784 × 6,77 studs**. Le Model Roblox original propriétaire `126298311664881` est **Moderation: Approved**. Le serveur et le client possèdent désormais le montage source du pont : [contrat runtime détaillé](P4_RUNTIME_TOWERS_SIGNATURE_BRIDGE_2026-11-10.md). Le texte d'import futur ci-dessous est historique. Il ne s'agit pas d'une publication du jeu ni d'une preuve de rendu Android.


10 novembre 2026. Ce travail concerne les corps du pont décoratif lointain de ArenaSignatureMegastructure en variante Towers, et **pas** les ponts Skyrail jouables ou leur physique.

## Audit exact

src/server/MapBuilder.lua crée un modèle ArenaSignatureMegastructure dans Decor avec, entre autres, les pièces OverheadServiceBridge (Part 41 × 2,4 × 6,5, décalage 0,39,0) et LowerTruss (Part 35 × 0,8 × 1,2, décalage 0,35,6,-3,2). Ces deux blocs sont actuellement les principales masses visuelles du pont suspendu; HangingSignal, LiftTowerWest/East, TowerCrownWest/East, inlays et diagonales doivent rester visibles et intacts. Tous sont cosmétiques, statiques et non collisionnels.

## Nouvelle sculpture

tools/generate_original_signature_towers_bridge.py fabrique une vraie géométrie continue de pont métallique avec sections triangulées, coque à quilles, consoles profilées, longerons ajourés, diagonales forgées et modules de traction en relief. Les sept matériaux industriels du projet sont intégrés à l'OBJ/glTF avec UV, normales et tangentes. Le modèle est centré sur le volume de l'union des deux pièces natives (environ 41 × 5 × 7,05 studs). Un seul Model source remplace deux grandes pièces rectangulaires, sans uniformisation écrasant les détails.

Le workflow .github/workflows/one-time-original-towers-forged-bridge-20261110.yml vérifie l'art original et effectue un upload Model au compte créateur via l'uploader sécurisé du projet, sans publier une Place. Ne jamais inventer de Model ID : attendre la vraie modération Approved avant de brancher le runtime.

## Intégration et sécurité

Le futur module client devra valider l'arène Towers, le vrai modèle distant, la présence des deux natives aux cotes/rotations exactes et les silhouettes indicatrices conservées. Une fois le vrai Model chargé, les sept MeshParts doivent être ancrés, non collisionnels, et installés atomiquement avant d'occulter les deux anciennes Parts. Restauration sur suppression, streaming partiel, changement de carte, qualité Low et pression GPU. Les deux grandes pièces sont non physiques : pas de modification des ponts sur lesquels les joueurs peuvent courir ni du système Skyrail.

Aucune mesure de FPS ni publication Roblox de ce lot n'est encore revendiquée.
