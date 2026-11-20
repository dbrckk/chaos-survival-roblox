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

Les arcs acoustiques et la couronne de Showtime ajoutent 13, 21 ou 43 emplacements éligibles selon la qualité. Les nervures, les ailes, leurs liserés et les segments tournants utilisent le profil forgé de Tower Run. Le cœur et les attaches de la couronne reprennent le profil d’Orbital. Les segments gardent leur pivot tangent et le sens de rotation des deux anneaux quelle que soit l’orientation d’import.

La piste peut afficher des profils approuvés sur ses 9, 16 ou 25 dalles, ses quatre bordures et ses quatre pylônes. Les dalles reprennent le profil moulé sans modifier les joints du quadrillage ni les décalages de pulsation. Les bordures utilisent le profil forgé dans les deux axes. Les pylônes reprennent les facettes d’Orbital et conservent les lumières existantes. Chaque emplacement garde une pièce de secours aux mêmes dimensions.

Les enceintes et le pupitre ajoutent neuf emplacements sculptés en Low et dix-huit en Medium et High. Les cônes, caches et disques utilisent les facettes d’Orbital, le plateau utilise le moulage du périmètre et les garnitures et curseurs le profil forgé. Le secours cylindrique suit le même plan que le maillage, face au public pour les enceintes et à plat sur le pupitre.

Les 3, 5 ou 8 barres de l’égaliseur utilisent le profil forgé lorsque le maillage est prêt. La base des barres reste à la même hauteur pendant les variations et la réduction des animations conserve la hauteur fixe d’origine. Le passage au maillage ou au secours conserve la hauteur courante et le pivot de chaque barre.

Les danseurs holographiques peuvent utiliser des profils approuvés sur leurs huit pièces en Medium et leurs vingt pièces en High. Le torse et les renforts reprennent le moulage du périmètre, la tête les facettes d’Orbital, et les membres et visières le profil forgé. La chorégraphie et les détails utilisent les mêmes pivots avec les maillages et leurs formes de secours.

Les trois façades imprimées, les deux lampes du portique et ses cinq accents réservés au High complètent le lot. Le même `SurfaceGui` suit la façade sur sa face orientée vers le public, y compris avec un maillage importé sur l’autre axe. Les 55, 89 et 140 emplacements visuels recensés de Showtime disposent ainsi d’un profil de remplacement, avec les mêmes formes de secours.

Les halos de victoire, les socles des survivants et l’impulsion de retour peuvent utiliser un anneau creux approuvé d’Orbital. Le centre de la constellation utilise la région facettée du même modèle. Les dimensions, durées et options de réduction des animations suivent le code existant. Un effet qui démarre avant le chargement garde son disque de secours jusqu’à sa fin.

Les pylônes de victoire en qualité moyenne et haute reprennent le profil octogonal de la colonne du lobby pour le corps, la vitre et l’insert lumineux. Leur coiffe reprend le profil facetté d’Orbital. Chaque pylône conserve quatre pièces et sa montée en cascade. Les formes simples servent de secours si les maillages sont indisponibles ou si la pression graphique augmente avant l’apparition des pylônes.

Le balayage doré au départ reprend la traverse forgée de Tower Run, ajustée à 80 % de la largeur de la piste. Il suit la même trajectoire au-dessus du revêtement, y compris si le maillage importé présente son axe long sur Z. La barre plate sert de secours au démarrage et sous pression graphique. Chaque balayage garde sa géométrie jusqu’à la fin du fondu.

Les trois balises d’orientation du lobby peuvent afficher le mât polygonal approuvé de Tower Run. La tige de secours reste visible tant que le maillage charge ou sous pression graphique. Les mâts disparaissent avec les balises pendant la manche et restent masqués en qualité basse. Les panneaux conservent leurs ancrages.

Les anneaux personnels de victoire, de défaite et de médaille peuvent utiliser un seul maillage creux d’Orbital à la place de six ou huit segments. Les couleurs, la durée et les options de réduction des animations suivent le résultat reçu. Les segments existants servent de secours en qualité basse, au chargement et sous pression graphique.

Les traces circulaires de catastrophe utilisent en qualité moyenne et haute un profil approuvé d’Orbital. Les cratères de météores et les ondes de saut adoptent un anneau creux. Le givre et les brûlures de bombes reprennent le noyau facetté aplati. Chaque trace garde une pièce alignée sur la surface et sa durée d’origine. Le disque simple prend le relais en qualité basse, sous pression graphique ou si le maillage est indisponible.

Les fissures d’impact, les lignes résiduelles et les éclats peuvent reprendre deux maillages approuvés. Le profil octogonal du lobby suit l’axe des fissures. La tête forgée à douze facettes fournit le relief des éclats. Chaque élément garde une pièce, son emprise au sol et son fondu. Les formes simples servent de secours au chargement et sous pression graphique.

Les neuf motifs au sol de fin de manche peuvent utiliser des maillages approuvés en qualité moyenne et haute. Les coulées de lave mêlent plaques moulées et rainures, les aiguilles de givre sont facettées et les traces de vent gardent leurs trois obliques biseautées. Chaque motif conserve ses repères au sol et ses deux à quatre pièces selon la qualité. Les formes simples servent de secours en qualité basse, au chargement ou sous pression graphique.

Pendant la manche, les impacts de météores peuvent laisser un cratère ouvert issu de l’anneau d’Orbital. Les bombes utilisent une plaque pleine issue du moulage du périmètre. Les deux marques reprennent la teinte du sol et s’alignent sur sa normale. Le centre occupe une seule pièce dans le budget de l’impact. Les formes simples servent de secours en qualité basse, au chargement et sous pression graphique.

Pour les impacts proches en qualité moyenne et haute, la tête forgée à douze facettes habille les éclats et le rebord temporaire du cratère. Les arcs de pression des bombes reprennent le moulage du périmètre et les volumes lumineux adoptent le noyau facetté d’Orbital. Le nombre de pièces, les trajectoires et les durées restent les mêmes. Les formes simples s’affichent en qualité basse, à distance, sous pression graphique ou pendant le chargement.

Les onze effets 3D de la phase finale peuvent utiliser des profils approuvés. Les aiguilles de givre et les projectiles de météores sont facettés. Les pointes de lave et les volets d’éclipse reprennent la colonne octogonale. Les sillages, les ondes et les limites reprennent le moulage du périmètre. Chaque effet garde sa trajectoire, son enveloppe et le plafond de pièces affichées simultanément. En qualité basse, sous pression graphique ou au chargement, les formes simples prennent le relais.

Les chevrons des quatre stations reprennent le profil forgé de Tower Run. Chaque bras conserve sa largeur, sa hauteur et sa position au-dessus du pad. Le montage normalise les deux orientations d’import et suit le repère du pad sans changer sa zone tactile.

Les impulsions du départ et du sprint final peuvent utiliser le profil du périmètre pour leurs segments fins et espacés. Les impulsions centrées sur le joueur peuvent utiliser un anneau creux d’Orbital. Les repères, les durées et la réduction des animations conservent leurs réglages. Les segments simples servent de secours en qualité basse, sous pression graphique ou au chargement.

Les ondes de choc des impacts proches peuvent afficher des segments facettés pour les météores et des segments moulés pour les bombes. Les deux conservent leur centre dégagé, leur expansion et le plafond d’ondes simultanées. Le rendu simple reste disponible à distance, en qualité basse, en mode animations réduites, au chargement ou sous pression graphique.

Les avertissements de météores peuvent afficher une colonne octogonale, une tête facettée et deux ailettes moulées en qualité haute. Les croix au sol des bombes reprennent le moulage du périmètre. Les formes restent dans les emprises existantes et suivent le temps restant de l’avertissement serveur. Les formes simples servent de secours en qualité basse, en mode animations réduites, au chargement ou sous pression graphique.

Les segments de l’avertissement de décharge au sol reprennent le moulage du périmètre. Ils suivent le diamètre calculé d’après le temps serveur en conservant leur emprise et leur nombre. Si le maillage n’est pas prêt, les segments simples restent visibles pour cet avertissement. Ils servent aussi de secours en qualité basse, sous pression graphique et en mode animations réduites.

Les charges de bombe en descente peuvent afficher un corps facetté d’Orbital, des ailettes moulées et deux accents forgés. Les cinq emplacements suivent le même compte à rebours serveur. La qualité moyenne conserve trois pièces et le mode animations réduites garde une seule forme fixe. Les formes simples s’affichent au chargement, en qualité basse et sous pression graphique.

Le contour du gel peut afficher des aiguilles à douze facettes. Elles suivent le temps serveur dès leur première image, y compris lorsque l’avertissement arrive en cours d’animation. Le voile au sol reste visible dans toute l’arène. Les aiguilles simples prennent le relais en qualité basse, en mode animations réduites, sous pression graphique ou si le maillage manque.

Les rubans de la tornade peuvent utiliser le moulage du périmètre sur leurs deux spirales. Les débris reprennent une forme facettée dans quatre arènes et un profil de planche à Storm Harbor, avec les matériaux de chaque décor. Les plafonds et la limite ambrée suivent les règles existantes. Les formes simples servent de secours en qualité basse, en mode animations réduites, au chargement et sous pression graphique.

Les quatre balises d’obscurité peuvent afficher un profil octogonal. Les quatre repères de rétrécissement reprennent le moulage du périmètre et suivent les bords de la dalle sur les deux axes. Les pièces sont positionnées dès leur première image. Les formes simples prennent le relais en qualité basse, en mode animations réduites, sous pression graphique ou au chargement.
