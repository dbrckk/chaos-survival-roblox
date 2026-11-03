# Cinq arènes : vrais sols 3D prioritaires devant la caméra (Android)

**Date :** 3 novembre 2026. **Point de départ réel :** publication publique de `c297b2a34384d2c169e9123b2939df4d19f7386d` ([workflow éditeur public réussi #41624914108](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41624914108)), avec [Build Validation #41624260822](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41624260822) et [Roblox Cloud #41624270887](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41624270887) verts sur ce même SHA. Les captures Android restent à obtenir.

## Défaut constaté dans le code publié

Le nouveau `PremiumGroundMeshKit` charge les vrais modèles 3D industriels (2 976 triangles chacun) depuis l'inventaire Roblox approuvé, mais il sélectionne les cases du 6 × 6 **exclusivement par distance euclidienne à la caméra**. La caméra Android à la troisième personne se trouve derrière l'avatar ; des dalles plus proches mais hors du regard peuvent monopoliser les plafonds **Low 1, Medium 3, High 6**, laissant une large zone devant le joueur avec de simples surfaces natives. Les mouvements de caméra au bord de la portée remountaient aussi de manière répétée les mêmes modèles approuvés.

## Correctif livré dans les sources

- Transmission du **LookVector horizontal** par le calcul caméra déjà partagé dans `scenery-lod.client.lua`. Aucun second contrôleur caméra.
- Priorité visuelle : toute case à **plus de 54 studs de décalage horizontal** située franchement derrière le regard reçoit une pénalité de sélection ; les zones à proximité et sous les pieds conservent naturellement leur priorité.
- Hystérésis strictement réservée aux cases **déjà montées**, avec **18 / 24 / 28 studs** de marge de sortie selon Low / Medium / High et un faible avantage aux modèles résidents. Les nouvelles dalles gardent exactement leurs seuils d'entrée **112 / 180 / 245 studs**.
- **Plafonds inchangés** : Low 1 / Medium 3 / High 6. Toujours le même asset original `72507987666671`, les mêmes matériaux sous-jacents, la même cadence de LOD et le même décompte GPU.
- **Sécurité inchangée** : les vrais colliders, les pictogrammes, le shrink serveur et les événements immédiats `Size/CFrame/Transparency/Ancestry` continuent à cacher les décorations décalées ; la surface native reste le repli.
- Aucun téléchargement au client, boucle `RenderStepped`, RemoteEvent supplémentaire, modèle non approuvé, nouvelle collision ou hausse de budget.

## Validation technique et perceptive restante

Cette adaptation a été recontrôlée statiquement sur les changements de source (quotas, AssetId approuvé, branchement du vecteur caméra, absence de nouvelle boucle, logique de sécurité inchangée). **Ce n'est pas encore une validation Roblox Studio, un benchmark Android ou une publication de ce correctif.**

À la prochaine grande validation **sur le SHA exact** : compiler tout le Luau, construire la place Rojo, contrôler le budget Android, lancer Build Validation et les cinq suites Roblox Cloud, puis publier via le workflow existant seulement si toutes les étapes réussissent.

Captures Android recherchées : les cinq cartes en Low/Medium/High, caméra derrière l'avatar et pivotée à 180°, progression d'une case à l'autre, première seconde du shrink, rechargement après changement de carte, et comparaison FPS/mémoire/temps de frame avec la version publique `c297b2a`. La preuve d'une amélioration **visuellement mesurée** exige ces captures ; ne pas la présumer de la seule revue du code.
