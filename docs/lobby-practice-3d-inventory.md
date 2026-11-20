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

Le relevé statique du constructeur couvre les pièces directement identifiables du lobby. Les boucles du générateur et les contrôleurs clients déterminent le nombre d’objets présents selon la qualité, la pression graphique et la disponibilité des maillages.

### Contraintes et priorités vérifiées dans le code

- `Lobby.Floor` et `Arena.Base` sont des surfaces de gameplay : **conserver les collisions serveur**, traiter uniquement leur apparence.
- `Arena.KillPlane` est un déclencheur invisible létal : **ne jamais le remplacer par une pièce décorative**.
- `LobbyFloorInset` et `ArenaDeckInset` sont de grandes surfaces visibles : étudier un habillage premium adapté à la lisibilité des dangers et aux appareils mobiles, plutôt qu'un maillage décoratif épais.
- Les trois `LobbyLoopPanel`, les quatre `LobbyIdentityPanel` et `ChaosSign` utilisent huit supports de texte transparents et sans collision. Leurs plaques sont éligibles à l’habillage sculpté après chargement du maillage approuvé. Le client ignore les autres plaques qui portent encore un `SurfaceGui` direct.
- Les appels `fitDecorMesh` utilisent déjà des maillages approuvés avec secours en primitives ; ne pas les comptabiliser comme « primitifs restants » sans vérifier le chargement effectif.

**Pourcentage global du jeu : non déterminé.** Il faudrait un inventaire à l'exécution par arène, catégorie et niveau de détail, ainsi qu'une vérification des chargements de maillages, avant de publier une métrique crédible.

## Grandes formes visibles du lobby

| Ensemble | Quantité observée dans le code | État |
| --- | ---: | --- |
| Lames du noyau et segments orbitaux | 3 + 12 | Le profil forgé approuvé remplace chaque pièce en Medium et High quand le maillage est prêt et la pression graphique normale. Chaque emplacement conserve un seul objet animé. |
| Sphère du noyau | 1 | Maillage sphérique facetté du réacteur Orbital approuvé, ajusté au volume de 3,6 studs en Medium et High. La sphère native prend le relais sous pression graphique ou pendant le chargement. Le même point lumineux suit les deux formes. |
| Fragments du noyau | 3 / 5 / 7 selon la qualité | Le même profil Orbital habille en Medium et High la coque vitrée et le cœur lumineux des fragments. Le rendu de secours prend le relais sous pression graphique. Les orbites et la cadence restent celles du contrôleur existant. |
| Balises du parcours d’entraînement | 4 | Plaques moulées approuvées dans le gabarit des disques de 8,5 studs. Les disques prennent le relais tant que le maillage est indisponible ou sous pression graphique. Les étiquettes et la détection à 5,4 studs gardent les mêmes ancrages. |
| Plateau et dalles physiques | 2 | Colliders natifs avec habillage sculpté conditionnel. |

Ce relevé compte les emplacements définis dans le code. Il reste à mesurer les maillages affichés sur un appareil mobile avant d’établir un taux de remplacement pour le lobby.

## Décompte des formes simples restantes

Relevé du 20 novembre 2026. Le tableau compte les pièces produites par chaque constructeur. Les lignes dépendent de phases et de conditions graphiques différentes. Leur somme ne représente donc pas une scène vue par le joueur.

| Ensemble | Low | Medium | High | Condition |
| --- | ---: | ---: | ---: | --- |
| Accessoires de Chaos Showtime | 37 | 56 | 86 | Enceintes, console, structure, couronne et égaliseur pendant la phase Showtime. |
| Tablier, dalles, bordures et pylônes de Showtime | 18 | 25 | 34 | Autour de la piste de 13,8 × 13,8 studs. |
| Danseurs holographiques de Showtime | 0 | 8 | 20 | Un danseur à huit pièces en Medium, deux à dix pièces en High. |
| **Total visuel potentiel de Showtime** | **55** | **89** | **140** | Hors ancrages transparents, interfaces et effets. |
| Bras des chevrons des stations d’entraînement | 8 | 16 | 24 | Emplacements éligibles au profil forgé approuvé. Deux bras par chevron, avec secours natif pendant le chargement et sous pression graphique. |
| Orbites et noyau avec tous les maillages prêts | 16 | 0 | 0 | En Low, douze segments, une sphère et trois fragments utilisent les primitives par choix de qualité. |
| Joints, trappes et inserts de secours du vestibule | 8 | 12 | 24 | Nombre maximal lorsqu’aucune dalle 3D ne couvre le vestibule. |

Le plateau principal et l’estrade, les quatre pylônes et les trois pièces physiques du portail totalisent neuf ancres de gameplay côté serveur. Leur présence dans l’arborescence est indépendante du remplacement de leur apparence.

Le secteur Showtime concentre le plus de formes simples dans les constructeurs examinés. Les premiers remplacements à forte visibilité sont le tablier, les deux enceintes, la console, les trois éléments du portique et le cristal suspendu. Les chevrons d’entraînement constituent le suivant : chaque bras peut garder son empreinte et utiliser le profil forgé existant, sans ajouter de pièce visible.

Le lot Showtime rend ces huit emplacements éligibles aux profils approuvés. Le tablier, les enceintes et la console reprennent le moulage du périmètre, le portique le profil forgé de Tower Run et le cristal le cœur facetté d’Orbital. Chaque emplacement garde une seule pièce. Le tablier conserve ses ancrages audio et ses effets. Les formes de secours restent visibles jusqu’au chargement et reviennent sous pression graphique.

Les chevrons des quatre stations reprennent le profil forgé de Tower Run. Chaque bras conserve sa largeur, sa hauteur et sa position au-dessus du pad. Le montage normalise les deux orientations d’import et suit le repère du pad sans changer sa zone tactile.
