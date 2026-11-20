> **Mise à jour :** [cinq assets Roblox approuvés et montage réel sécurisé sur des plateformes de 3/13,8/28,2 studs](../P4_FIVE_APPROVED_P0_ORIGINAL_STRUCTURES_2026-11-13.md). Les limites de résidence et les primitives profondément porteuses restées natives sont détaillées dans ce rapport.

> **Rectificatif après inspection des propriétaires et du registre de publication (13 novembre 2026).** Les cinq modèles `ascension_access_arch`, `ascension_transfer_arch`, `ascension_summit_arch`, `architectural_column_casing` et `orbital_helix_underframe` sont **déjà publiés et approuvés** dans `assets/source/roblox-asset-registry.json` (IDs réels 110243423264048, 107273631120961, 127049813505254, 130196548599769, 106863534763803). `src/client/ApprovedRemainingStructureMeshKit.lua` les monte déjà, sur la même boucle LOD, avec quotas Low/Medium/High et conservation des signaux, colliders et fallback. **La mention « source dédiée non identifiée » dans l'analyse historique ci-dessous est donc périmée.** Les vrais chantiers restants sont la **couverture partielle** : 5 pièces supérieures par arche sélectionnée (quille et poutres profondes conservées), 11 par casing sélectionné, 4 par rampe Helix sélectionnée. Plafonds normaux PC Low/Medium/High : arches **1/3/6**, casings **1/2/4**, Helix **0/2/6** ; plafonds tactiles encore plus faibles. L'existence de ces assets ne démontre pas une couverture 100 % en session.

> **Mesure désormais instrumentée :** `src/client/RemainingVisualNativeCensus.lua` observe toutes les **16 passes LOD** les véritables `Part/WedgePart/CornerWedgePart/TrussPart` natives non physiques encore présentes et non masquées localement, dans la carte active. Le recensement inclut façades, casings, arches, Helix, supports, bordures, sous-cadres, panneaux, finitions de sol, stations périphériques, monuments, skyline Harbor et passerelles. Les attributs `LocalP4VisibleNativeAscensionStructure`, `...AscensionSignal`, `...HelixStructure` et `...HelixSignal` séparent **les vrais volumes primitifs des signaux de navigation**. `LocalP4VisibleNativeAllScanned` donne le nombre de primitives natives visibles dans les deux dossiers parcourus, sans prétendre qu'elles méritent toutes un remplacement. Les comptes sont des **instantanés des objets streamés et non masqués**, ni des pixels rendus ni un FPS. Les vrais colliders sont exclus. Les arènes absentes sont signalées par `LocalP4NativeCensusReady=false`, et non traitées comme un zéro validé.

## Priorités autour des parcours jouables

Revue des générateurs de la PR #920 à partir de `aa70b187`. Les nombres ci-dessous décrivent les emplacements cosmétiques persistants produits lorsque la mécanique est présente. Leur présence à l’écran dépend du streaming, du réglage graphique et de la partie.

| Priorité | Famille | Pièces et état du code |
| --- | --- | --- |
| 1 | Quatre stations de Classic Grid | Les secours construisent **20 / 68 / 100 pièces** en Low, Medium et High. Chaque station a un socle et un anneau segmenté. Medium ajoute montants et filaments, High ajoute les couronnes. Les guides entre stations et l’effet de passage sont hors de ce total. |
| 2 | Quatre portiques Flux de Crossroads | **40 / 48 / 60 emplacements** en Low, Medium et High, assises comprises. Les formes simples servent de secours en attendant les profils approuvés ou sous pression graphique. |
| 3 | Appuis des routes d’ascension, de l’Épine céleste et des Promenades | Les pièces de secours peuvent encore être visibles près d’un tablier si sa source est absente à la construction ou lorsque le modèle local sort du budget. Relever les sous-cadres, appuis et panneaux près des départs et des embranchements avant de refaire une famille entière. |
| 4 | Repères et portiques du Skyrail | **Huit repères** Low peuvent reprendre le moulage approuvé ou le profil forgé quand le moulage manque. Les quatre portiques Medium/High emploient les mêmes sources de secours pour leurs montants et signaux, selon les profils chargés. |

Le relevé client ajoute un rayon de **36 studs** autour de la caméra, calculé jusqu’à la boîte orientée de chaque pièce. Les attributs `LocalP4VisibleNativeNearRouteNativeTotal` et `LocalP4VisibleNativeNearRouteLocalTotal` suivent respectivement les familles serveur retenues et les trois ensembles décoratifs locaux nommés ci-dessus. Les attributs `LocalP4VisibleNativeNearGridStations`, `...NearFluxGates`, `...NearSkyrail` et les compteurs par famille serveur détaillent le total. Un relevé exploitable a `LocalP4NativeNearRouteReady=true`. Les pièces masquées, les colliders, les capteurs et les effets ponctuels des ensembles locaux sont exclus. Les compteurs décrivent la proximité géométrique et la transparence, sans mesurer l’occlusion ou les pixels rendus. Les compteurs historiques conservent leur périmètre.

Les montants du Skyrail s’engagent dans le bord extérieur de leurs quatre vrais ponts. Les filets lumineux restent devant la face intérieure des montants. Le client conserve au plus une volée d’éclats d’accélération et la retire à l’alerte du volet, à l’effondrement ou à la perte du pont. La pression graphique rend les formes simples aux emplacements existants et retire les éclats. Les compteurs de proximité continuent de distinguer les pièces persistantes et les effets brefs.

## Revue du 20 novembre 2026

La revue de la branche de la PR [#920](https://github.com/dbrckk/chaos-survival-roblox/pull/920), à partir de `565d843`, combine le recensement des générateurs, le registre des modèles et le suivi des propriétaires de chaque famille. Le registre contient 112 modèles approuvés et l’audit recense 509 fichiers Luau. Le fichier CSV du 13 novembre reste le relevé historique. Il ne permet pas de déduire le nombre de primitives visibles un jour donné.

| Famille | État retrouvé dans le code |
| --- | --- |
| Monuments de secteur proches des parcours | Les quatre monuments locaux peuvent afficher 20, 56 ou 106 maillages par arène selon la qualité et les sources chargées. Les bâtiments de façade du serveur ont leurs propriétaires et budgets propres. |
| Bordures, supports, sous-cadres et panneaux des decks | `MapBuilder.lua` peut déjà monter des profils approuvés dans ces familles. Plusieurs propriétaires client masquent ou remplacent des cohortes à portée de caméra. Le compteur historique de primitives ne mesure pas leur apparence une fois chargés. |
| Arches d’ascension | Les pylônes, ailettes et traverses utilisent une source à la construction quand elle est disponible. Les deux culées, la quille et le longeron peuvent aussi utiliser des maillages dès la construction, pour 48 pièces par arène. Le kit local `ApprovedRemainingStructureMeshKit.lua` garde la priorité sur les arches sélectionnées et peut remettre en place les pièces de base sculptées ou simples. |
| Colonnes périphériques | `ArchitecturalCladding.lua` prévoit les profilés moulés à la construction. Le kit local de structures restantes prend aussi en charge les colonnes admissibles. |
| Rampes d’Orbital | Les rampes principales `HelixRamp1…9` peuvent utiliser les longerons approuvés pour leurs 18 cadres latéraux et 27 entretoises. Le modèle complet garde la priorité à proximité, avec le même suivi du rétrécissement. Le générateur crée séparément **jusqu’à 15 châssis visuels** sous les rampes compactes, huit `EntryChassis` et sept `CoreChassis`. Le kit local peut déjà monter le modèle complet sur une sélection de ces châssis. Ces 15 logements privilégient désormais le treillis ajouré du châssis approuvé dans la même enveloppe de 0,22 stud. Les longerons, puis le profil forgé de Tower Run, servent de secours. Ce profil forgé peut aussi reprendre les 45 emplacements de cadres et d’entretoises des rampes principales si leurs longerons manquent. Les modèles complets restent prioritaires à proximité. Les formes simples reprennent le relais si aucun profil de structure n’est chargé. |

L’attribut `LocalP4VisibleNativeHelixAccessChassis` observe leur nombre parmi les structures natives présentes et non masquées côté client. Il fait partie du total Helix. La bande centrale `HelixCenterGrain` est comptée comme un signal puisque son apparence reflète l’état de charge des voies. La mesure en jeu reste au prochain jalon.

Les 72 bandes de guidage des 24 rampes d’Orbital peuvent reprendre le moulage approuvé du périmètre, le relief de sol d’Orbital ou, en dernier secours, le profil forgé de Tower Run. Chaque bande garde un seul emplacement. Les 27 bandes des rampes principales et les 45 bandes des accès suivent la longueur de leur rampe. Les huit voies de jeu conservent leur signal ambré à la charge, avec leurs teintes et leur transparence d’origine au retour à l’état normal.

Les 16 façades par arène peuvent reprendre le moulage du périmètre pour les vitrages et les ailettes de signal, soit 84 pièces sur Classic, Crossroads, Orbital et Storm Harbor, et 100 sur Tower Run. Les quatre enseignes conservent leur fenêtre, leur face et leur orientation. Le vitrage de la cabine reste compatible avec le masque de façade à proximité, comme celui du transfert sur Tower Run l’est avec le masque des équipements de toit.

Chaque arène peut afficher 32 supports blindés façonnés avec le profil polygonal de sa variante et 32 rails de toiture avec les longerons approuvés. Le kit de parois latérales vérifie l’asset et le gabarit des supports avant de prendre le relais. Chaque famille possède son propre secours à la construction.

Les 16 bâtiments peuvent aussi afficher **80 pièces de structure sculptées par arène**. Le lot couvre les 32 pans de toiture, les 32 caissons latéraux et les 16 noyaux de service. Les pans reprennent le sens de leur pente, quelle que soit l’orientation horizontale de l’asset importé. Les caissons et noyaux gardent leur empreinte et restent admissibles à l’habillage des parois de proximité.

Les fondations et les équipements de toit des 16 bâtiments couvrent **180 pièces supplémentaires sur Classic, Tower Run et Storm Harbor, et 196 sur Crossroads et Orbital**. Le lot couvre 32 pièces de fondation, 68 pièces réparties entre les quatre silhouettes de toiture, ainsi que 80 ou 96 équipements propres à l’arène. Chaque maillage remplace une pièce à son emplacement. Les formes simples reprennent le relais si une source manque. Les kits de proximité reconnaissent les maillages approuvés et les formes de secours. Les portes de service gardent leur rôle d’ancrage.

Les 16 entrées de service peuvent reprendre le moulage approuvé pour leur encadrement répliqué. Jusqu’à 64 détails locaux en qualité moyenne et 96 en qualité haute peuvent aussi reprendre les maillages approuvés, selon les bâtiments à portée et l’habillage de façade actif. Les linteaux, auvents, colonnes, coffrets, treuils, collerettes et conduits occupent les emplacements existants. Les auvents profonds descendent vers l’approche et les collerettes s’alignent sur le conduit. Les détails locaux reprennent leurs formes simples si un profil manque ou si la pression graphique augmente. Le vantail garde son fini, son enseigne et ses ancrages.

Les quatre monuments d’angle peuvent utiliser des maillages approuvés dans **57 emplacements par arène**. L’observatoire conserve 17 pièces, le portique de fret 13, le réacteur 17 et le phare 10. Les socles, les corps et les deux couronnes restent compatibles avec les habillages de proximité. La couronne du portique s’aligne sur les axes du monument même si la pente de l’aileron importé exige un quart de tour. Les silhouettes reprennent leurs formes simples si une source manque à la construction.

### Géométrie au contact des parcours

Les quatre générateurs de bouclier des manches Météores et Bombes peuvent utiliser **68 maillages sur Classic, Tower Run et Orbital, et 72 sur Crossroads et Storm Harbor**. Les socles moulés, les fûts polygonaux, les noyaux facettés et les équipements propres à chaque arène réutilisent les emplacements existants. Jusqu’à six liaisons d’équipe peuvent aussi reprendre le profil forgé pour leurs sept repères chacune. Le noyau reste le support de l’interaction, et le volume de protection et sa couronne d’impact conservent leur géométrie. Les formes simples reprennent le relais si leur profil n’est pas chargé. Le recensement `LocalP4VisibleNativeSkyShields` relève les primitives visibles du dossier des boucliers pendant la manche.

Le poste d’aiguillage des trois voies peut afficher **74 pièces sculptées par arène**. Quatre consoles reçoivent chacune un socle moulé, deux montants polygonaux, deux traces lumineuses dégagées, un noyau facetté et une traverse forgée. Le cadre s’aligne en travers de la voie et les traces reprennent la teinte des ponts une fois le réseau connecté. Les 46 bords des ponts temporaires suivent les deux axes et s’allument à l’ouverture des 23 passages. Les pièces simples servent de secours si leur profil manque lors de la création du poste. Les plateformes de liaison gardent leur géométrie de collision. Le recensement `LocalP4VisibleNativeSkySwitchyard` relève les primitives cosmétiques visibles.

Les plateformes de mobilité des cinq arènes peuvent recevoir quatre bordures forgées par capteur à portée du budget graphique. Les bordures sont sous la face supérieure. Le libellé, la direction et la lueur du capteur restent dégagés. Chaque cadre suit son capteur pendant la contraction et reprend la teinte de surcharge ou de bonus personnel. Le cadre s’ajoute lorsque le profil approuvé est chargé. Il est retiré lorsque le profil n’est plus disponible ou que la qualité graphique impose le secours. Le budget existant couvre jusqu’à quatre cadres sur PC, trois en qualité haute tactile et deux en qualité moyenne.

Les deux relais d’accélération d’équipe peuvent afficher **dix pièces sculptées par arène**. Le socle moulé, le fût polygonal, le noyau facetté et les deux bras inclinés réutilisent les emplacements du relais. Les bras s’assombrissent avec le noyau lorsque la charge a été distribuée. La borne s’efface si la contraction lui retire son appui, y compris pendant l’impulsion visuelle. Le bouton, l’indication et le rayon de partage gardent leur point de référence. Les formes simples servent de secours si une source manque au début de la manche. Le recensement `LocalP4VisibleNativeTeamDashRelays` observe les primitives visibles de ces relais.

Les fragments à collecter affichent trois silhouettes si les profils approuvés sont chargés. Le fragment ordinaire est un cristal allongé, le doré un noyau large avec une couronne en qualité moyenne ou haute, et le fret un coffret vert à pans coupés. Chaque fragment utilise au plus deux maillages locaux. Le capteur sphérique reste actif et redevient visible si le maillage disparaît, si sa source est indisponible ou sous pression graphique. Les libellés, les récompenses et les limites d’apparition gardent leurs réglages.

Les quatre aiguillages de Crossroads affichent deux flèches opposées par station, soit **16 branches sculptées** si le profil forgé est disponible à la création. Le socle de proximité et le revêtement de sol restent sous les flèches. La paire chargée reste ambrée. Le raccourci maître conserve sa teinte claire et la direction du dernier virage accepté s’éclaircit brièvement, avec un repère fixe en mode de réduction des mouvements. Les formes simples reprennent les mêmes flèches si le profil manque. Les capteurs et les impulsions gardent leurs réglages.

Les quatre couloirs de balayage de Storm Harbor peuvent afficher **16 bordures sculptées**. Chaque contour suit la limite horizontale qui déclenche la poussée, avec la même marge de 0,3 stud que le serveur et les aides à l’évacuation. Les bordures s’allument en ambre pendant l’annonce, en rouge pendant la poussée et s’effacent au repos. Le marquage central et le compte à rebours gardent leurs réglages. Les bordures simples reprennent le même contour si le profil manque.

Les quatre bandes de Classic Grid utilisent le même contour forgé que Storm Harbor, soit **16 bordures** lorsque le profil est disponible. Elles matérialisent la marge de 0,3 stud comprise dans l’effet réel, sur les deux axes. Elles suivent la bande si elle est déplacée ou redimensionnée, reprennent ses couleurs d’alerte et de poussée, puis s’effacent au repos et au nettoyage. Le signal sonore et le marquage central restent disponibles avec les bordures simples de secours.

Les quatre points d’accélération de Tower Run reprennent les traverses forgées pour leur portique et leur couronne, et la fonderie du périmètre pour les huit repères au sol en qualité basse. Le chargement tardif peut remplacer les formes simples pendant la manche. Les fibres débordent des faces intérieures des montants et les courriers gardent leur orientation sur les deux axes pendant la contraction. Les signaux s’atténuent à la fermeture du volet. Côté serveur, le calcul de la piste disponible utilise le même sens que le déplacement lorsque le pont suit l’axe Z, notamment pour une accélération près d’une extrémité.

Les quatre volets de Tower Run peuvent afficher **16 branches de chevrons forgées**. Les pointes indiquent les deux directions pour s’éloigner de la traverse centrale. Les branches restent entièrement au-dessus du revêtement de marche, sur les deux axes et pour les deux orientations du maillage importé. Elles suivent l’alerte, la montée, la fermeture et la réouverture avec les mêmes fondus. La traverse continue de marquer l’emplacement précis de l’obstacle. Les formes simples reprennent les flèches si le profil manque.

Les quatre stations de Classic Grid peuvent utiliser des socles et couronnes moulés, des montants polygonaux et un anneau à facettes par station. L’anneau remplace les 4, 8 ou 12 segments simples selon la qualité, soit **12 à 44 pièces persistantes de moins** sur les quatre stations lorsque son profil est disponible. Les filaments dégagent la face intérieure des montants et les chevrons entre stations peuvent reprendre le profil forgé. La couleur de progression, les étiquettes et les capteurs gardent leur rôle. Les sources arrivées pendant une manche sont prises en compte, et les formes simples reprennent le relais sous pression graphique.

Les quatre portiques Flux de Crossroads peuvent reprendre les assises moulées, les montants polygonaux et les traverses forgées dès la qualité basse. Deux assises soutiennent chaque portique. Les flèches pointent vers le centre sur les quatre voies et dégagent le revêtement de sol. Le cadre non physique suit le capteur s’il se déplace. Les profils arrivés pendant la manche remplacent les pièces simples. Si le capteur disparaît avec le streaming ou si la pression graphique augmente, le portique se réconcilie avec son capteur et ses profils disponibles.

La revue de la branche à partir de `df33653` a retrouvé huit stations de transit actives pendant les manches éligibles. Elles sont placées au sol entre le centre et les districts. Le recensement précédent ignorait leur dossier temporaire, créé directement sous l’arène. Chaque station peut utiliser des maillages approuvés pour le seuil, les montants, la traverse, les signaux et son équipement propre à l’arène. Cela représente **72 emplacements sur Classic, Crossroads et Orbital, et 80 sur Tower Run et Storm Harbor**. La traverse conserve la position du bouton de voyage et de l’enseigne. Chaque pièce retrouve sa forme simple si son profil manque au début de la manche.

Le recensement client inclut désormais le transit quand le serveur le crée. Les attributs `LocalP4VisibleNativeDistrictTransitStructure` et `LocalP4VisibleNativeDistrictTransitSignal` donnent ses deux sous-totaux. `LocalP4VisibleNativeUnclassifiedLarge` relève les primitives de 12 studs ou plus sans famille identifiée pour orienter la prochaine inspection. `AllDecor` conserve son périmètre historique Décor + Helix. `AllScanned` couvre aussi le transit. Ces mesures dépendent du streaming et des masques client.

Les 20 installations extérieures qui bordent les arènes peuvent utiliser des maillages approuvés dans **276 emplacements**. Classic, Tower Run, Orbital et Storm Harbor ont chacun 52 pièces. Crossroads en a 68, dont les 16 renforts et profilés des quatre portiques. Ces profilés suivent l’axe réel du portique, même si l’import permute les axes horizontaux. Les habillages complets de proximité reconnaissent les formes sculptées et leurs secours avec les mêmes budgets. Les inventaires de sol distinguent toujours les dalles PBR, les alertes et les habillages géométriques.

Les quatre installations de Storm Harbor peuvent réutiliser le moulage fermé de Harbor, de Classic ou du périmètre dans **40 des 52 emplacements** lorsque les poutres et fûts dédiés manquent. Les douze ailes et sous-faces inclinées gardent leur pente de secours si leur profil manque. Les habillages complets de proximité reconnaissent ces moulages et les fûts approuvés par emplacement. Les ancrages extérieurs et le budget Low sont conservés.

### Grandes dalles des parcours

Les **36 dalles par arène**, soit 180 emplacements sur les cinq variantes, peuvent reprendre le biseau continu du caisson de service approuvé. Leur empreinte et leur épaisseur de 0,035 stud restent les mêmes. Leur sommet reste à 0,1705 stud au-dessus du sol physique, sous les marquages de danger. Les dalles gardent leurs teintes, leur finition PBR, leurs ancrages pour les modèles complets de proximité et leur suivi du rétrécissement. Leur forme plate sert de secours si le profil manque à la construction. Les dalles et le fond de sol reçus après un rétrécissement continuent à prendre la teinte de contraste pendant la montée de lave.

### Monuments propres à chaque arène

Les cinq monuments à l’est de l’arène peuvent utiliser des maillages approuvés dans **124 emplacements**. Le lot couvre 25 pièces sur l’observatoire de Classic, 28 sur le portique de Tower Run, 21 sur l’échangeur de Crossroads, 31 sur le réacteur d’Orbital et 19 sur le chantier naval de Storm Harbor. Les dimensions et les budgets de silhouette Low restent les mêmes, soit 10, 8, 6, 10 et 8 pièces. Les corps, socles et équipements complets de proximité gardent leurs ancrages. Chaque forme simple reste disponible si son profil manque à la construction. `LocalP4VisibleNativeHeroMonuments` compte les primitives de ces monuments quand elles sont chargées et visibles côté client.

### Horizons et stations de Storm Harbor

Un seul moulage fermé approuvé de Harbor ou de Classic peut couvrir **52 emplacements sur les horizons** et **56 sur les quatre stations** quand leurs profils spécialisés manquent. Les silhouettes sont réparties entre les deux grands monuments, les quatre tours de premier plan et les huit arrière-plans. Les formes inclinées gardent leur propre profil de secours. Les habillages de proximité reconnaissent les moulages sur les pièces qu’ils couvrent. Aux stations, le repère lumineux reste en place et les emplacements réservés aux mécanismes complets gardent leur géométrie d’origine.

### Flotte de Storm Harbor

La flotte extérieure peut utiliser des maillages approuvés dans **207 emplacements**, dont 122 sur les quatre grues et 85 sur le cargo. Les chariots, câbles, palonniers et charges conservent leur mouvement avec les maillages de secours. Le radar du cargo conserve son balayage sur la silhouette de secours. Les ancrages du portique et du pont du navire conservent leurs axes pour les modèles complets. La silhouette Low du cargo affiche toujours 14 pièces. Les formes simples reprennent le relais lorsqu’un profil manque.

À la construction de l’arène, la flotte privilégie le moulage de Harbor et peut réutiliser ceux de Classic ou du périmètre. Les longerons et les montants reprennent le moulage disponible si leur profil spécialisé manque. Les tambours et leurs flasques peuvent utiliser la lentille facettée ou le fût déjà chargé. Les 14 pièces de la silhouette Low du cargo et les points d’ancrage des modèles complets gardent leurs dimensions. La proue conserve la forme en pente si son maillage dédié manque.

Les barges du littoral et les défenses de quai peuvent reprendre **16, 39 ou 76 pièces sculptées** selon la qualité Low, Medium ou High. Ce total couvre respectivement 8, 27 ou 56 pièces de barges et 8, 12 ou 20 pièces de quai, dont les quatre butées d’angle en qualité haute. Les barges restent à leurs postes d’amarrage d’origine pendant le rétrécissement et les habillages de quai suivent le bord du terrain.

Le moulage fermé de Harbor ou de Classic prend le relais lorsque les profils spécialisés manquent. Les modèles complets à proximité reconnaissent les deux moulages sur leurs points d’ancrage et masquent la silhouette de secours avec sa cargaison. Le client réagit à l’arrivée des sources dès la première arène et après un changement de carte. Les formes simples restent disponibles lorsque les sources approuvées sont absentes.

Les quatre avant-postes jouables de Storm Harbor peuvent afficher **20 pièces sculptées en qualité moyenne ou 36 en haute**. Les quilles, montants, traverses, jambes de force et ailettes conservent leurs soudures à la vraie plateforme. Les instruments gardent leur pivot d’animation et leurs modèles complets de proximité. Les pièces suivent le rétrécissement, s’atténuent pendant l’alerte et disparaissent à l’effondrement. Si un profil manque ou si la pression graphique augmente, les formes simples reprennent le relais. Les seuils de montage des assemblages de proximité restent inchangés.

Les trois têtes cylindriques acceptent le rouleau moulé de Harbor sur les deux axes d’import. Les quatre instruments peuvent aussi réutiliser la tête polygonale d’une fixation approuvée lorsque le rouleau ou la lentille ne sont pas chargés. Le mouvement reste centré sur le même pivot. Quand un instrument complet prend le relais à proximité, il conserve la même pose pendant les alertes et le rétrécissement.

Les deux passerelles hautes de Storm Harbor peuvent recevoir **28 bordures forgées** sur leurs 14 paliers. Les **58 paliers des trois familles de parcours** peuvent aussi conserver leurs deux signaux et leur châssis sculptés quand les pièces communes manquent à la construction, pour 174 emplacements de secours. Les deux signaux utilisent le rouleau moulé de Harbor. Le châssis utilise son profil de tôle fermé. Les coins et châssis restent admissibles à l’habillage de proximité après rotation de l’import et rétrécissement du palier. Les formes simples restent disponibles selon les sources chargées. Les pièces visibles suivent l’alerte, l’effondrement et la remise en service de leur palier.

### Accès aux quais de Storm Harbor

Huit chevrons marquent les départs des quatre parcours de fret et des quatre quais cardinaux. Chaque repère s’aligne sur les deux premiers paliers et peut reprendre le profil biseauté de Harbor ou le profil forgé de Tower Run. Les huit incrustations de quai acceptent aussi le profil forgé en secours. Ces repères suivent le sol pendant le rétrécissement et gardent le seuil des premiers paliers dégagé. Les seize premiers paliers des deux familles peuvent réutiliser un moulage fermé pour leurs bordures, signaux et sous-cadres quand leurs sources dédiées manquent. Les huit deuxièmes paliers peuvent reprendre un fût polygonal approuvé déjà chargé. Les caissons et habillages de proximité conservent leurs poses de référence. Les formes simples restent disponibles.

### Quais cardinaux supérieurs de Storm Harbor

Les huit paliers supérieurs peuvent recevoir **16 biseaux forgés** sur les faces transversales aux quatre montées. Leurs **24 poteaux** s’engagent de 0,08 stud dans la dalle, avec quatre appuis sous chaque troisième palier et deux sous chaque avant-poste. Le serveur et les habillages de proximité partagent la même hauteur d’assise. Le moulage fermé et le fût polygonal peuvent prendre le relais si les profils dédiés sont absents. Les biseaux conservent l’empreinte de secours et les pièces suivent le rétrécissement et l’effondrement de leur tablier.

En qualité basse, les incrustations de bois et les chevrons déjà affichés peuvent utiliser la collerette de Harbor ou le moulage fermé de Classic quand le profil principal manque. Le même secours couvre les pièces des avant-postes en qualité moyenne et haute. Les pièces reprennent le profil de Harbor dès son arrivée et gardent leur emplacement, leur nombre et leur suivi du tablier.

### Virages des parcours de fret de Storm Harbor

Aux vingt virages, les bandes latérales suivent la sortie du palier et les inserts sculptés sous le tablier reprennent l’axe du saut d’arrivée. Les poteaux s’engagent de 0,08 stud dans la dalle et leurs têtes restent sous le tablier. Le moulage et le fût polygonal déjà chargés peuvent prendre le relais si les sources dédiées manquent. Les instruments de guidage, la détection des alertes et le montage des caissons gardent leurs repères physiques. Le scénario de rétrécissement couvre les deux axes sur les 58 paliers des trois familles.

### Raccords des sommets de fret aux traversées hautes

Sur les quatre raccords de Storm Harbor, les huit biseaux qui se font face peuvent reprendre le profil forgé de Tower Run. Le montage utilise la même sélection de palier que le guidage des sauts, puis vérifie que les rives se font face. Les biseaux gardent leur empreinte afin que le vide reste lisible, y compris pendant le rétrécissement. Chaque rive suit son propre tablier et s’efface avec lui. Les huit tabliers peuvent aussi réutiliser un moulage et un fût polygonal approuvés en secours, en conservant les repères des caissons de proximité.

### Paliers intermédiaires des traversées hautes de Storm Harbor

Les dix paliers intermédiaires peuvent compléter leurs bordures longitudinales avec vingt traverses forgées sur les faces qui bordent les sauts. Les quatre biseaux de chaque palier gardent l’empreinte d’origine et restent compatibles avec le caisson de proximité. Les poteaux s’engagent dans la dalle et conservent leur ancrage sous le tablier. Lorsqu’un profil dédié manque, le moulage fermé et un fût polygonal déjà chargé servent de secours. Le rétrécissement conserve les espaces de saut et les alertes utilisent le propriétaire du tablier.

### Secours des parcours des autres arènes

Sur Classic, Tower Run, Crossroads et Orbital, les **384 paliers** peuvent réutiliser le moulage fermé de leur arène, ou celui de Classic en secours, quand les profils communs manquent. Les 3 072 emplacements répartis sur ces quatre cartes couvrent quatre bordures, une dalle, un châssis et deux signaux par palier. Les chevrons de parcours peuvent aussi reprendre ce moulage. Les profils dédiés gardent la priorité. La hauteur et la transparence des repères restent celles du générateur existant. À Storm Harbor, les paliers acceptent maintenant le rouleau importé sur X ou sur Z. Les tests locaux ont vérifié l’empreinte, le rétrécissement à 45 % et le retour à l’état normal.

### Portiques d’ascension et contremarches

Les 60 portiques réutilisent le moulage fermé de leur arène, puis celui de Classic si nécessaire, quand une source dédiée manque. Avec le seul moulage fermé disponible, 860 des 904 pièces de portique peuvent rester sculptées. Les 240 emplacements de contremarche du périmètre, des branches et des traversées peuvent aussi reprendre ce moulage. Le rotor d’Orbital peut reprendre l’anneau du réacteur. Les lentilles gardent leur sphère de secours. Les pièces restent non physiques et suivent leur palier pendant le rétrécissement et la chute.

### Tours d’horizon d’Orbital

Les quatre tours peuvent réutiliser le fût polygonal d’Orbital, le moulage du périmètre pour leurs huit colliers et le profil facetté du réacteur pour leurs quatre balises, soit seize emplacements. Les tours gardent leurs ancrages d’horizon. L’habillage complet de proximité masque seulement le fût. Il libère la prise si un collier ou une balise est retiré ou ne correspond plus au profil attendu. Chaque famille de maillages peut prendre le relais indépendamment, avec les formes simples en secours.

### Balises et supports du premier anneau d’Orbital

Les douze segments lumineux reprennent le profil forgé de Tower Run. Ils sont tangents à l’anneau et rapprochés du sol. Les quatre pylônes atmosphériques peuvent reprendre le fût polygonal d’Orbital et leurs quatre balises, le noyau facetté du réacteur. Les positions des pylônes et les lumières des balises sont conservées. L’habillage complet de proximité accepte les fûts sculptés et les blocs d’origine, puis restitue le fût masqué quand il se retire. Les sources peuvent manquer indépendamment et les pièces simples restent disponibles.

### Accès au sol d’Orbital

Huit chevrons au sol pointent vers les huit rampes physiques d’entrée, avec deux ailes par repère. Le relief approuvé d’Orbital garde la priorité sur le profil forgé de Tower Run. Les formes simples reprennent la même pose si les deux sources manquent. Les chevrons se contractent avec les rampes en laissant leur seuil dégagé. Les huit rayons du centre et le médaillon suivent aussi le sol. Le disque de secours conserve sa hauteur et reste circulaire pendant le rétrécissement.

### Plateforme centrale de secours d’Orbital

Le tablier sous le réacteur peut incruster l’anneau approuvé dans sa surface, avec un fini métallique et une lèvre sous les marquages de guidage. Il réutilise l’emplacement de la bande périphérique, qui reste disponible si l’anneau manque. Le sous-cadre peut reprendre le treillis ajouré dans son empreinte d’origine. L’anneau et le sous-cadre suivent le tablier pendant le rétrécissement, s’effacent à l’effondrement et retrouvent leur état initial au rétablissement du tablier.

### Plateformes extérieures d’Orbital

Les huit plateformes au débouché des rampes d’entrée peuvent recevoir le profil annulaire du réacteur dans l’emplacement du noyau lumineux. L’anneau est placé sous le sous-cadre et la bande périphérique, y compris lorsque cette dernière reprend sa forme plate. Les bandes jumelles suivent l’axe d’arrivée sur les rampes cardinales. Le profilage des plaques, bandes et biseaux peut utiliser le moulage du périmètre si les revêtements de sol sont absents. Le treillis approuvé prend le relais sous le tablier si les longerons manquent. Les pièces gardent le suivi de leur tablier durant le rétrécissement et l’effondrement.

### Plateformes d’arrivée du réacteur d’Orbital

Les huit paliers intérieurs et le podium peuvent recevoir neuf treillis ajourés dans l’empreinte des sous-cadres existants. Leurs plaques, bandes et biseaux peuvent garder un moulage quand le revêtement principal manque. Les poteaux peuvent reprendre un autre fût polygonal approuvé déjà chargé. Les habillages suivent leurs plateformes au rétrécissement et à l’effondrement. Au-dessus du podium, le noyau lumineux et les huit balises peuvent reprendre le profil facetté du réacteur. Ils conservent leurs positions, leurs teintes et la lumière ponctuelle du noyau. Des formes simples restent disponibles pour les emplacements dont les sources manquent.

### Supports des promenades et de la Sky Spine

Sur les cinq arènes, 430 emplacements peuvent réutiliser le moulage fermé de leur arène ou celui de Classic. Le total comprend 180 pièces des portiques de promenade, 210 pièces de la Sky Spine et 40 renforts aux jonctions avec les belvédères. Les maillages dédiés restent prioritaires. Les châssis de proximité vérifient les sources autorisées, leur emprise après rétrécissement et la continuité du croisement entre les deux tabliers. Les renforts des belvédères ne sont générés que lorsque les tabliers existants se chevauchent.

Les 26 tabliers suspendus par arène (16 de Promenade et 10 de l’Épine céleste) peuvent conserver un sous-cadre sculpté quand le châssis d’accès ne fournit ni treillis ni longerons. Le cadre reprend alors le moulage de l’arène, celui de Classic ou le socle approuvé du périmètre. Il garde son empreinte peu profonde sous les entrées et les jonctions, avec le treillis séparé des portiques. Les poteaux des tabliers et les montants des portiques d’ascension peuvent utiliser le fût polygonal d’une autre arène déjà chargée si leur fût dédié manque. Le registre et les vérifications du modèle importé déterminent quelles sources sont admissibles. Les formes simples restent disponibles quand aucun modèle approuvé n’est prêt à la construction. La mesure de cette couverture en jeu reste à effectuer.

# Audit P4 — structures primitives encore candidates au remplacement 3D

**Date :** 13 novembre 2026 · **Dépôt :** `dbrckk/chaos-survival-roblox` · **Code actuel audité :** `16b8a52cc128e9130ba97a8a5e876d004c946b76` (branche `main`).

**Inventaires vérifiables :** [754 lignes du relevé moteur d'origine](structure-family-census-2026-11-13.csv), [25 groupes priorisés et cinq colonnes par arène](remaining-3d-priority-matrix-2026-11-13.csv), [audit historique et méthode](P4_AUDIT_EXHAUSTIF_STRUCTURES_RESTANTES_2026-11-13.md).

## Instrumentation complémentaire — 13 novembre 2026

Le recensement client `RemainingVisualNativeCensus.sample` distingue
maintenant, pour **District**, **PlatformSupport**, **SkySpine** et
**Promenade**, les primitives de structure (`...Structure`) des
primitives de guidage (`...Signal`). La classification se fonde sur le
matériau Neon, l'attribut `ChaosWayfinding` et les marqueurs de nom
`signal/beacon/guide/glow`. Les totaux de famille restent inchangés :
ces compteurs sont des sous-ensembles, **pas des objets additionnels**.

L'objectif est de mesurer, sur une vraie session Android/PC, le
**reste de volumes primitifs non physiques visibles** avant de relever
des budgets MeshParts. Les chiffres historiques du CSV ne doivent pas
être présentés comme un inventaire de ce qui est actuellement visible.
Aucune capture, mesure FPS, création d'asset ou publication n'est
revendiquée par cette instrumentation seule.

## Conclusion

Il n'existe **aucun nombre exact démontré de modèles « non remplacés actuellement à l'écran »** : le serveur conserve les primitives de repli ; les copies MeshPart réelles sont activées localement selon la caméra, le streaming, la carte, la qualité et la pression GPU. Il est incorrect de dire que les 13 846 natives initiales restent toutes visuellement primitives.

Les trois familles ci-dessous étaient des **lacunes au moment du recensement moteur historique**. Elles ont depuis reçu cinq modèles approuvés et un propriétaire de remplacement 3D LOD : leur *stock natif initial* reste utile pour quantifier la couverture non masquée, mais n'est plus un manque d'asset.
- **Monuments des routes d'ascension (`SkyRouteMonument`) : 904 natives initiales** dont 280 signaux. Les 624 autres sont des volumes/matériaux non signalétiques, mais toutes ne justifient pas un gros mesh. `src/server/SkyRouteMonuments.lua` dessine des pylônes, `MonumentalOverpass`, `TaperedFin`, `LoadBearingKeel`, `RecessedCentralGirder` en primitives non collidantes ; les modèles physiques des vrais decks appartiennent à d'autres systèmes.
- **Revêtements `OriginalPremiumColumnCladding` : 260 natives**, exactement 4 casings de 13 pièces par arène. `src/server/ArchitecturalCladding.lua` utilise notamment `FoundationFoot`, `ArmoredFrontShell`, `AngledArmorFin`, `DiagonalLoadSpar`, `MachinedUpperCollar`, `RecessedCrown` et la tête de navigation. Les cinq assets approuvés `column_classic/...` concernent `ArenaAtmosphere`, pas ces casings.
- **Circuit Orbital `HelixCircuit` : 132 natives non physiques**, dont 63 signaux, en plus des **24 éléments physiques** qui doivent rester autoritaires. Priorité aux `HelixUnderframe*` et `HelixSpineBrace*` ; préserver `HelixEdgeSignal*`, le suivi des rampes et les collisions.

Les familles **partiellement remplacées** les plus massives restent les 2 248 natives des districts, 2 080 bordures de decks, 800 supports, 520 sous-cadres, ainsi que Promenade/Sky Spine/Harbor. Plusieurs disposent déjà de sources 3D validées et **ne nécessitent pas** 1 asset différent par Part serveur.

## Chiffres vérifiés et limites

Le relevé de `MapBuilder` dans un vrai Roblox Engine (run [43400304859](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43400304859), SHA `f099298b`) contient **14 480 BaseParts**, dont **13 846 natives non physiques** et **4 911 natives non physiques de taille ≥12 studs**, sur cinq reconstructions avec le lobby répété. **Chaque variante n'est pas visible en même temps**. Après déduplication du lobby, ce catalogue contient **13 498** natives non physiques sur cinq arènes et un lobby unique. Le recensement moteur détaillé **n'a pas été recalculé sur le dernier SHA** ; les modules 3D et budgets ont évolué depuis.

| Arène | BaseParts initiaux | Natives visuelles non physiques | Grandes natives |
|---|--:|--:|--:|
| Classic | 2 673 | 2 561 | 889 |
| Towers | 2 776 | 2 659 | 954 |
| Crossroads | 2 754 | 2 641 | 962 |
| Orbital | 2 916 | 2 778 | 992 |
| Harbor | 3 361 | 3 207 | 1 114 |
| **Somme avec lobby x5** | **14 480** | **13 846** | **4 911** |

Le contrôle du **code actuel** recense **103 modèles originaux approuvés sur 103**, **67** modules MeshKit/3DKit, **57** reliés directement au LOD, **65** avec un ID connu et **489** fichiers Luau. **Zéro ancien garde de largeur globale 318** ne reste dans les kits vérifiés : c'est une correction de shrink, pas un taux de conversion 3D.

## Familles à traiter par ordre d'importance

Nombres = **pièces du générateur natif initial sur cinq cartes**, et non modèles réellement non masqués sur client. La colonne signal est un *sous-ensemble* qu'il faut traiter séparément.

| Famille | Natives source | Grandes ≥12 | Signaux | Priorité | Situation |
|---|--:|--:|--:|:--|:--|
| Bâtiments de district | 2 248 | 440 | 120 | P0 | PARTIEL SOURCE 3D |
| Bordures WedgePart | 2 080 | 1 148 | 0 | P0 | PARTIEL SOURCE 3D |
| Supports de decks | 800 | 592 | 0 | P0 | PARTIEL SOURCE 3D |
| Sous-cadres de decks | 520 | 317 | 0 | P0 | PARTIEL SOURCE 3D |
| Monuments des routes ascensionnelles | 904 | 140 | 280 | P0 | SOURCE DEDIEE NON IDENTIFIEE |
| Habillages de colonnes architecturales | 260 | 0 | 0 | P0 | SOURCE DEDIEE NON IDENTIFIEE |
| Panneaux supérieurs de decks | 520 | 149 | 0 | P1 | NATIF MATERIAU PBR |
| Promenade / portiques | 590 | 116 | 332 | P1 | PARTIEL SOURCE 3D |
| Sky Spine transversal | 392 | 334 | 162 | P1 | PARTIEL SOURCE 3D |
| Circuit orbital (hors colliders) | 132 | 73 | 63 | P1 | SOURCE DEDIEE NON IDENTIFIEE |
| Flotte grues / navire Harbor | 207 | 80 | 4 | P1 | PARTIEL SOURCE 3D |
| Monuments des 4 coins | 285 | 100 | 30 | P1 | PARTIEL SOURCE 3D |
| Rétrofits extérieurs | 276 | 48 | 20 | P1 | PARTIEL A VERIFIER |
| Structures skyline | 164 | 56 | 0 | P1 | PARTIEL SOURCE 3D |
| Modules de finition au sol | 180 | 180 | 0 | P1 | SOURCE 3D EXISTANTE |

### Répartition par arène des principaux chantiers

| Famille | Classic | Towers | Crossroads | Orbital | Harbor | Total |
|---|--:|--:|--:|--:|--:|--:|
| Bâtiments de district | 440 | 456 | 456 | 456 | 440 | 2248 |
| Bordures WedgePart | 376 | 396 | 380 | 384 | 544 | 2080 |
| Supports de decks | 128 | 136 | 152 | 140 | 244 | 800 |
| Sous-cadres de decks | 94 | 99 | 95 | 96 | 136 | 520 |
| Monuments des routes ascensionnelles | 176 | 176 | 176 | 188 | 188 | 904 |
| Habillages de colonnes architecturales | 52 | 52 | 52 | 52 | 52 | 260 |
| Panneaux supérieurs de decks | 94 | 99 | 95 | 96 | 136 | 520 |
| Promenade / portiques | 118 | 118 | 118 | 118 | 118 | 590 |
| Sky Spine transversal | 78 | 78 | 78 | 78 | 80 | 392 |
| Circuit orbital (hors colliders) | 0 | 0 | 0 | 132 | 0 | 132 |
| Flotte grues / navire Harbor | 0 | 0 | 0 | 0 | 207 | 207 |

**Harbor**, avec 3 207 natives non physiques, est la variante la plus dense. **Orbital** ajoute les rampes physiques et décoratives de `HelixCircuit` ; ces pièces doivent être traitées comme un ensemble asservi au même vrai deck. **Towers** exige la priorité au contraste des passerelles hautes. Les cartes Classic/Crossroads sont concernées par les mêmes monuments de route et casings.

## Ce qui possède déjà un modèle 3D et ne doit pas être recréé à l'aveugle

1. **Bordures + supports + sous-cadres :** la famille `PlatformBevel` comporte 4 wedges par `PlatformN` et peut bénéficier d'une carapace originale approuvée qui masque 4 wedges + un sous-cadre, **Low 1 / Medium 8 / High 16 decks maximum sur la carte active**, si la source, les limites caméra et l'état du deck le permettent. Cela couvre au maximum 4 / 32 / 64 bordures dans le budget propre à ce kit sur une arène, bien moins que le stock natif d'origine. Les colonnes de support 3D ont des plafonds de **1 / 8 / 16 modules source** ; les hauts piliers peuvent consommer plusieurs modules. Le vrai gain est la meilleure distribution spatiale des modèles admis, pas un relèvement aveugle de GPU Android.
2. **Districts :** 16 bâtiments par arène et 2 248 natives cumulées. Sur le dernier code, High PC sain peut allouer **16 façades sculptées** et **12 coques latérales** ; Android tactile High est plafonné à **8/8**, Medium à 3 façades et 3 coques en tactile, Low à 1/1 sans pression. Les murs/socles/guidages non couverts ne deviennent pas automatiquement de vrais MeshParts.
3. **Promenade / Sky Spine :** respectivement **590** et **392** natives initiales, dont **332** et **162** signaux. Harbor dispose de modèles cargo, Sky Spine de couronnes et LongCradle, mais seulement sur les propriétaires sélectionnés. Les autres architectures, bandes d'accès et sous-structures demandent un audit client par classe d'objet.
4. **Harbor :** `StormHarborGantryFleet` = **207** natives initiales pour 4 grues et le navire. `HarborFreighterMeshKit` et `HarborGantryKineticMeshKit` possèdent déjà des sources approuvées, mais leur visibilité reste bornée par les LOD. Il faut déterminer la silhouette effectivement visible avant de refaire ces modèles.
5. **Monuments de coins et extérieurs :** **285** et **276** natives initiales. Les vraies sources approuvées masquent les silhouettes redondantes ; les socles, pointes, antennes et indications restent souvent volontairement natifs.
6. **Sol / stations / profondeur :** les 180 modules de sol ont déjà une source originale (résidences normales Low 2, Medium 16, High 36 par carte). Les stations ont **17/23 pièces éligibles** à la source 3D, soit **340/460** du catalogue, les 120 autres étant des éléments conservés. Horizon sud **73/73**, crêtes **60/60** éligibles ; SkylineDepth **40/80** (toits, avec 40 antennes natives).

### Ce qu'il faut préserver ou transformer en finition plutôt qu'en gros mesh

`PlatformGlow` **520** et `PlatformCoreGlow` **520** sont des signaux natifs initialement visibles, essentiels à la navigation et aux catastrophes. De même, beaucoup des 280 signaux `SkyRouteMonument` et des 332 signaux `Promenade` doivent rester contrastés. Les **520** `PlatformPanel` sont des plaques fines de matériau et d'orientation, déjà traitées par le système PBR : poser une grosse sculpture dessus pourrait créer un faux sol ou effacer les alertes. La cible est une finition de meilleure qualité, pas une disparition systématique.

## Ordre d'exécution recommandé

**P0 — lot 1, sculptures d'ascension :** créer/valider un original 3D par gabarit `ACCESS / TRANSFER / SUMMIT` avec cinq matériaux d'arène et remplacement uniquement des pylônes, portiques, poutres et coques dont l'empreinte est authentifiée. Conserver les vraies flèches, balises, signaux et le repli natif sous `CollapsePhase`, shrink et streaming.

**P0 — lot 2, casings :** rehausser les **20 casings / 260 primitives** des colonnes centrales, sans modifier leur collision ni leur repère de navigation. Réutiliser des assets approuvés uniquement s'ils ont réellement les bonnes dimensions ; sinon produire de nouvelles sources créateur, les faire approuver, puis les monter avec LOD.

**P0 — lot 3, couverture proche :** mesurer la résidence réelle des carapaces, supports et sous-cadres dans les cinq arènes. Les attributs existants `LocalBevelNativePartsReplaced`, `LocalSupportNativePartsReplaced` et `LocalUnderframeNativePartsReplaced` fournissent des comptages **des natives réellement masquées** sur le client ; agréger sans additionner cinq cartes comme une session unique.

**P1 — Orbital/Harbor et passerelles :** vraies structures techniques sous rampes, arches et grues ; préserver l'état des vrais decks, les 24 collisions Orbital et les signaux.

**P1/P2 — finitions :** vérification des façades/volumes restants, panneaux PBR, ambiance/lumière, relief, compression des détails répétitifs et cohérence des cinq matériaux d'arène.

### Critères d'acceptation non négociables

Un remplacement n'est terminé que lorsque : **asset original réellement approuvé**, colliders inchangés, masquage seulement des natives effectivement couvertes, restauration immédiate si source/mesh/weld manque ou lors de danger, qualité Low/Medium/High cohérente, quotas Android de **440 / 680 / 900 Parts locaux**, Build Validation + sept suites Roblox Engine réussies, et **captures d'un vrai client Studio/Android** (caméra proche/loin, pression 0/1/2, cinq variantes). Les fps p50/p95 et le nombre exact de silhouettes encore perçues **ne sont pas mesurés dans cet audit**.

## Preuves actuelles

- [Audit sources / 103 assets / 489 Luau / 0 ancien garde global : réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43460240975)
- [Budget Android et origine 3D : réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43460241005)
- [Build Validation : réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43460240862)
- [Sept suites Roblox Open Cloud Engine : réussi sur `16b8a52`](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43460377189)

**Cette intervention constitue un audit et un plan priorisé ; aucune nouvelle sculpture, mesure FPS Android ou republication Roblox n'est revendiquée.**
