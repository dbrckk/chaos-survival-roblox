# P4 — Rotor de station sculpté en 3D authentique

**9 novembre 2026 — étape de fabrication et d’import d’asset ; aucun déploiement du jeu.**

## Audit du code source

Dans `MapBuilder.addPerimeterStations`, quatre stations par arène conservent chacune trois cylindres natifs : `IntakeTurbineL`, `IntakeTurbineR` (2,6 × 0,8 × 2,6 studs) et `GeneratorRotor` (2,7 × 0,9 × 2,7). Cela représente **60 cylindres** sur les cinq variantes générées (pas 60 pièces résidentes simultanément sur un client).

Aucun asset Model approuvé du dépôt n’avait un contour de turbine approprié : le caisson de maintenance et la machine orbitale sont destinés aux boîtiers, pas aux rotors. Les étirer dans un disque serait une régression visuelle.

## Création réelle

Le nouveau `tools/generate_original_perimeter_rotor.py` génère une pièce mécanique sculptée originale : carter creux à 32 facettes, bague usinée, moyeu, neuf pales profilées et fermées, huit boulons traversants, quatre verrous céramique et huit repères lumineux. Il réemploie le générateur `Sculpture` et la palette originale de sept matériaux.

Résultat de la génération locale : **1 304 triangles**, **32 groupes source**, 7 matériaux, gabarit **2,56 × 0,8155 × 2,56 studs**. Empreinte SHA256 OBJ : `1a7862b9477f97924c7efbb6222a0ce65652eea6d86c748383d7c8607aab8d1c`.

## Import sécurisé

Le nouveau workflow `.github/workflows/one-time-original-perimeter-rotor-20261109.yml` reconstruit cet OBJ à partir du source GitHub, vérifie son hash, les tailles, pales et 7 primitives glTF avec UV, normales et tangentes avant d'appeler **l'uploader original déjà utilisé**. Il est déclenché une seule fois par un push de son propre fichier sur `main`. Pas de nouveau service ni d'asset tiers.

Le pipeline utilise le propriétaire Roblox autorisé et ne publie **aucune Place**. Le chargement effectif dans le jeu nécessite un véritable identifiant Roblox Model issu de cet import, sa modération approuvée et une vérification de tailles dans le moteur ; **aucun identifiant, import réussi ou remplacement effectif n'est présumé à ce stade**.

## Suite sur la version source

Une fois l’asset vérifié, brancher un modèle client uniquement sur les trois vrais rotors de chaque station, sans toucher aux colliders, aux balises de danger, aux lentilles ni aux mécaniques de mouvement. Profils Low/Medium/High et pression GPU doivent réutiliser le sampler `scenery-lod.client.lua` et le budget visuel existant ; les formes primitives devront être restaurées si l’asset ou la station manque.

Conformément à la règle de développement, aucune suite de tests Roblox Engine, aucun benchmark Android et aucune publication publique du jeu n'est revendiqué pendant cette itération.
