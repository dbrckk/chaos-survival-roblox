# Inventaire 3D — stations d'entraînement du lobby

État de la branche `art/tower-skybridge-treads` au 19 novembre 2026. Inventaire **statique et limité** à `src/server/LobbyActivities.lua` et `src/client/lobby-sculpted-finish.client.lua`. Ne pas extrapoler au lobby entier ni aux cinq arènes.

## Objets créés par une génération des quatre stations

| Objet | Par station | Total | Rôle | Habillage 3D |
| --- | ---: | ---: | --- | --- |
| PracticeBoostPad | 1 | 4 | Déclencheur tactile | LobbySculptedCasting |
| PracticeCastRim | 4 | 16 | Bordures cosmétiques | LobbySculptedCasting |
| PracticeCornerBoss | 4 | 16 | Angles cosmétiques | LobbySculptedCasting |
| PracticeGuideVane | 2 | 8 | Guides latéraux | LobbySculptedSwept |
| PracticeGuideFin | 2 | 8 | Embouts extérieurs | LobbySculptedSwept |
| **Total** | **13** | **52** | | **52 candidats** |

Ces 52 objets sont encore créés comme `Part` côté serveur. Le client leur substitue une apparence `MeshPart` **uniquement** lorsque le maillage approuvé est disponible, que le joueur est dans le lobby et que le budget d'effets le permet. Le `Part` tactile du boost doit rester présent pour son fonctionnement. En l'absence du maillage, la primitive reste visible.

**Taux de couverture du lot : 52/52 candidats marqués pour habillage conditionnel (100 % des stations, pas 100 % de remplacement effectivement visible).** Aucun taux global du jeu n'est établi : il faut inventorier les constructeurs indirects, les clones, les modèles Roblox et les états LOD des autres scripts.

## Priorités suivantes

1. Inventorier les grandes surfaces visibles de `MapBuilder.lua`, les constructions du lobby et les décorations générées indirectement ; distinguer colliders nécessaires et primitives purement visuelles.
2. Remplacer les grandes silhouettes visibles avant d'ajouter d'autres petits ornements ; réutiliser les maillages approuvés et garder un fallback.
3. Contrôler le rendu réel, la première minute mobile et les performances lors du prochain jalon de validation demandé ; ne pas déclarer ces contrôles réussis avant exécution.
