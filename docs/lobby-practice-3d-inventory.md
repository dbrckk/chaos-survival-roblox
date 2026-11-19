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

Les finitions utilisent le même préchargement que le portique, les pylônes et les dalles. Chaque finition attend le maillage précis dont elle a besoin. Un profil en échec est retenté une fois après vingt secondes, pendant que sa pièce de secours reste visible.

**Taux de couverture du lot : 52/52 candidats marqués pour habillage conditionnel (100 % des stations, pas 100 % de remplacement effectivement visible).** Aucun taux global du jeu n'est établi : il faut inventorier les constructeurs indirects, les clones, les modèles Roblox et les états LOD des autres scripts.

## Priorités suivantes

1. Inventorier les grandes surfaces visibles de `MapBuilder.lua`, les constructions du lobby et les décorations générées indirectement ; distinguer colliders nécessaires et primitives purement visuelles.
2. Remplacer les grandes silhouettes visibles avant d'ajouter d'autres petits ornements ; réutiliser les maillages approuvés et garder un fallback.
3. Contrôler le rendu réel, la première minute mobile et les performances lors du prochain jalon de validation demandé ; ne pas déclarer ces contrôles réussis avant exécution.

## Audit complémentaire : `MapBuilder.lua` (statique)

Relevé sur la branche de travail, sans instanciation Roblox. Le fichier compte **3 822 lignes** ; la fonction `buildLobby` occupe **626 lignes** jusqu'à `buildArena`. Dans `buildLobby`, on observe **7 appels textuels à `part(...)`**, **5 à `decorPart(...)`** et **9 à `sculpt(...)`**, y compris les déclarations de fonctions locales. Ces nombres sont des **sites d'appel**, pas des quantités d'objets générés : les boucles et les modules importés rendent impossible une conversion fiable en nombre de primitives sans exécuter le générateur.

Sur la portion `buildArena` et les fonctions suivantes, relevé de **4 appels textuels à `part(...)`**, **2 à `decorPart(...)`** et **14 à `fitDecorMesh(...)`**. Ce comptage ne couvre pas les fonctions auxiliaires précédentes, notamment les fondations, stations périphériques et mégastructures ; les cinq variantes partagent du code mais peuvent générer des objets différents.

### Contraintes et priorités vérifiées dans le code

- `Lobby.Floor` et `Arena.Base` sont des surfaces de gameplay : **conserver les collisions serveur**, traiter uniquement leur apparence.
- `Arena.KillPlane` est un déclencheur invisible létal : **ne jamais le remplacer par une pièce décorative**.
- `LobbyFloorInset` et `ArenaDeckInset` sont de grandes surfaces visibles : étudier un habillage premium adapté à la lisibilité des dangers et aux appareils mobiles, plutôt qu'un maillage décoratif épais.
- Les trois `LobbyLoopPanel`, les quatre `LobbyIdentityPanel` et `ChaosSign` utilisent huit supports de texte transparents et sans collision. Leurs plaques sont éligibles à l’habillage sculpté après chargement du maillage approuvé. Le client ignore les autres plaques qui portent encore un `SurfaceGui` direct.
- Les appels `fitDecorMesh` utilisent déjà des maillages approuvés avec secours en primitives ; ne pas les comptabiliser comme « primitifs restants » sans vérifier le chargement effectif.

**Pourcentage global du jeu : non déterminé.** Il faudrait un inventaire à l'exécution par arène, catégorie et niveau de détail, ainsi qu'une vérification des chargements de maillages, avant de publier une métrique crédible.
