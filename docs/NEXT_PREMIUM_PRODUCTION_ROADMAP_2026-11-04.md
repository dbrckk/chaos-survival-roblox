# Chaos Survival — nouveau plan d'amélioration premium après les lots 3D et lumière

## Actualisation opérationnelle — 7 novembre 2026 (priorités de livraison)

Ce document reste **le plan de référence**, actualisé plutôt que remplacé par une nouvelle liste. Les chantiers visuels des sections suivantes restent applicables. État source constaté : `main` après fusion de la [PR #660](https://github.com/dbrckk/chaos-survival-roblox/pull/660), commit `2dfd65c4b517175802c946bbcd4b2e52dacaf3cc`. Le propriétaire a confirmé le bon fonctionnement dans le jeu, mais cette approbation **ne constitue pas** un rapport CI, une mesure Android instrumentée ou une preuve de publication de ce SHA.

### Ordre actif et critères de sortie

| Ordre | Lot | Situation vérifiable | Définition de terminé |
| --- | --- | --- | --- |
| **G4-0 — P0** | Sécurité de version et fonctionnement | PR #660 fusionnée dans `main`; publication Roblox exacte non vérifiée | Une seule provenance SHA du build et de l'univers/place publique, accès public et round fonctionnels, procédure de retour arrière disponible |
| **G4-1 — P0 SOURCE FUSIONNÉE** | **Décisions IA sur dangers simultanés** | [PR #661](https://github.com/dbrckk/chaos-survival-roblox/pull/661) fusionnée : Meteor/Bomb prioritaire sur Freeze/JumpShock avec hystérésis à urgence égale | Aucune alerte globale de saut/gel ne masque un impact local dans l'enveloppe réelle ; choix stable entre deux impacts ; réactions et vitesses physiques inchangées |
| **G4-2 — P0 EN COURS** | **Navigation physique des sept bots** | Navigation Pathfinding et reprise de blocage existantes ; correctif en cours pour empêcher les collisions verticales avec décor/bots de faire rejeter le vrai sol de l'arène | 0 bot bloqué involontairement plus de 6 s dans 30 min de session représentative ; aucun saut privilégié, téléportation ou trajet sur un vide |
| **G4-3 — P0** | Gameplay à huit et interactions visibles | Remplissage 1 humain + jusqu'à 7 IA au début de manche, relais et stations existants | Huit participants au READY si la création réussit, événements coop réellement activés, issue/recompenses de fin de manche lisibles et immédiatement compréhensibles |
| **G4-4 — P0** | **Premier plan AAA et lisibilité** | Modèles 3D/PBR approuvés et LOD existants, qualité perceptuelle non certifiée | Sur les **cinq** cartes, vrais grands MeshParts visibles sur routes et ponts High, mode Low sûr, éclairage diurne/nuit/Darkness et danger toujours lisibles sur Android |
| **G4-5 — P1** | Fluidité Android et interactions cinématiques | Cadence IA échelonnée, budget LOD, sons et effets existants | Profilage réel sur sept R15 + Double Chaos : aucune hausse de coût serveur/client non justifiée ; suivi FPS, mémoire, latence de réaction et éliminations équitables |
| **G4-6 — P0 release** | **Validation consolidée et publication** | `Build Validation` est à déclenchement manuel sur `main`; aucune CI PR n'est supposée | Même SHA pour build + suites moteur + preuve Studio/Android ; publication gardée explicitement confirmée, lien public vérifié et rollback documenté |

**Avancement G4-2 du 7 novembre — source en cours sur branche `fix/g4-ground-nav-base-only-validation`.** `requestGroundNavigation` vérifiait la présence de `Base` avec un rayon descendant qui pouvait rencontrer un pont, une structure ancrée ou un avatar avant le sol de l'arène. Le même trajet était ensuite contrôlé avec un rayon **filtré sur la vraie `Base`** dans `liveGroundRouteCorridorSafe` : incohérence de validation susceptible de faire échouer le NavMesh au tout premier contrôle. Le correctif applique cette même règle `Include={base}` aux points du trajet calculé, avec contrôle de l'empreinte réelle locale, de la hauteur, de la normale et du contact physique. Aucun nouveau rayon, RemoteEvent ou mouvement IA privilégié. **En attente de build/suites moteur au jalon et observation Android d'une récupération autour d'un vrai obstacle.**

**Avancement G4-2 — quarantaine des destinations inaccessibles.** La règle `filterRecentlyFailedCandidates` réintroduisait silencieusement la liste complète si *toutes* les destinations disponibles se trouvaient dans les 11 studs du dernier objectif échoué. Cela permettait de renvoyer le bot contre le même obstacle à chaque nouvelle décision. Désormais, la liste filtrée peut rester vide : `chooseArenaTarget` possède déjà le repli physique sûr sur `root.Position` pendant la quarantaine (7,5 s), sans marche dans le vide ni téléportation. Les alertes de danger restent prioritaires. **Code source fusionnable ; mesure des échecs réels et validation moteur/Android encore requises avant clôture de G4-2.**

### Prochaines actions sans dispersion

1. **G4-1 : source fusionnée via PR #661.** Certification moteur/Android au jalon de release, pas de revendication de validation instrumentée sur le dernier SHA.
2. **G4-2 : lot actif.** Corriger les faux rejets de chemins Pathfinding dus au décor supérieur, puis contrôler les itinéraires devenus invalides et les récupérations au sol. Garder la vérification du collider Base réel, des bornes X/Z, de l'altitude, des obstacles et des hazards ; utiliser la télémétrie serveur existante, sans deuxième moteur d'IA.
3. Reprendre **G4-4** à l'échelle des grandes surfaces visibles avant les ornements. Préserver la sécurité des vrais colliders, des dangers et des replis visuels.
4. **G4-6** en jalon unique, sans multiplier les tests durant la phase d'amélioration. Ne déclarer « publié » ni « AAA validé » sans preuve appareil et exact-SHA.

**Suivi :** distinguer systématiquement *source codée*, *fusionnée*, *build/moteur validé*, *essai réel sur appareil* et *publication*. Le retour du propriétaire valide un comportement observé, pas automatiquement les quatre autres statuts. Aucune nouvelle version publique intermédiaire par simple fusion GitHub.

---

**Créé le 4 novembre 2026.** Dépôt : `dbrckk/chaos-survival-roblox`, branche `main`, SHA source de référence : `d36f651572860ee6d3d57c0ae3f4ecd11fef698d`. Plan d'exécution du produit, pas preuve que cette version a été publiée ni que le rendu satisfait déjà un niveau AAA.

> **Cap de production :** fiabilité > jeu réellement fonctionnel > sécurité/équité > architecture > performance > rendu visuel > fonctionnalités secondaires. Le **rendu visible, les vraies routes et les bots** constituent les prochains gros investissements, pas l'accumulation d'ornements. Terminer chaque lot au niveau final visé avant de passer au suivant. Ne créer aucune version publique intermédiaire ni tests unitaires supplémentaires. Exécuter les builds/tests moteur aux jalons importants seulement.

**Lot 6 / 7 — halo Orbital en treillis MeshPart 3D homologués (5 novembre 2026) :** les 14 segments de l'anneau lointain, encore des barres Part plates, deviennent éligibles à quatre vrais modules de charpente 3D par secteur. Réutilisation de l'import original créateur `PremiumSkybridgeModule` approuvé (aucune clé, nouveau CDN, rendu simulé ni modèle inventé). Sélection répartie spatialement, remontage atomique, repli natif automatique, plafond qualité Low 0 / Medium 2 / High PC 5 / High Android 3, davantage réduit si pression. Tous les MeshParts ajoutés au recensement 440/680/900. [Contrat](VIS_ORBITAL_APPROVED_3D_HALO_TRUSS_2026-11-05.md). **Validation moteur puis contrôle réel Android impératifs ; pas de publication intermédiaire.**

**Lot 5 / 7 — trafic aérien animée en vrais modèles 3D (5 novembre 2026) :** les anciens 2/4 traits néon en mouvement de chaque arène deviennent de vrais drones, nacelles, véhicules de transit, satellites et cargos Roblox créateur déjà approuvés : jusqu'à 20 parcours théoriques sur les cinq mondes, 0 Low / 2 Medium / 4 High PC réellement actifs par carte. Leurs MeshParts sont soudés au pilote cosmétique d'origine, dont le TweenService devient CFrame plutôt que Position : trajectoire et durée inchangées, aucun animateur supplémentaire. Contraintes Android High 3/1/0 sous pression, Medium 2/1/0 ; natifs restaurés si streaming ou asset indisponible. [Contrat et QA](VIS_AUTHENTIC_ANIMATED_CINEMATIC_SKY_TRAFFIC_2026-11-05.md). **Tests moteur et contrôle visuel réel nécessaires, pas encore de publication.**

**Lot 1 / 7 — remplacement massif des horizons 3D (5 novembre 2026) :** le propriétaire cinématique peut substituer de vrais modèles MeshPart Roblox approuvés aux **55 emplacements High potentiels** (11 par monde × cinq mondes, un seul actif à la fois), avec disparition groupée de la masse primitive, couronne et éventuelle fente d'éclairage. Sources réelles district/Towers/Orbital, emplacements et thèmes préservés, retour natif atomique en streaming ou pression. Plafonds modèles Android Low 2 / Medium 5 / High 7 (High PC 11), réduction automatique si pression GPU ; tous comptés dans le budget existant. [Contrat et limites de preuve](VIS_AUTHENTIC_CINEMATIC_HORIZON_MASS_REPLACEMENT_2026-11-05.md). **Code préparé : compilation, suites Roblox Cloud et captures réelles encore nécessaires ; pas de publication intermédiaire.**

**Lot 4 / 7 — positions immuables des horizons des cinq arènes (5 novembre 2026) :** une variation de qualité Low/Medium/High ne déplace plus les masses cinématiques, halos Orbital, balises lumineuses ni trafic aérien. Le budget visuel reste exactement 5/8/11, 0/10/14, 0/3/5 et 0/2/4 ; seuls des emplacements fixes supplémentaires s'ajoutent. [Contrat](VIS_FIVE_WORLD_FIXED_CINEMATIC_DEPTH_LAYOUT_2026-11-05.md). **Tests Cloud et validation Android requis, aucune publication.**

**Lot 1 / 7 — stations Orbital immobiles sous changement de qualité (5 novembre 2026) :** les sculptures originales du ciel ne se déplacent plus à cause du nombre 3/4/6 de stations lors d'un passage Low/Medium/High. Six positions d'origine restent fixes, les trois/quatre premiers emplacements sont des sous-ensembles spatiaux, et les modèles approuvés contrôlent aussi les coordonnées natives exactes. [Contrat](VIS_ORBITAL_STABLE_3D_STATION_SECTORS_ACROSS_ANDROID_TIERS_2026-11-05.md). **Code à valider par moteur et screenshots Android, aucune publication intermédiaire.**

**Lot 1 / 7 — vrais modèles 3D visibles sur les parcours périphériques (5 novembre 2026) :** la géométrie de plateforme décorative utilisait un masquage global au-delà de 105 studs en Low / 165 en Medium depuis le centre de l'arène. Les pièces soudées aux vraies plateformes suivent maintenant aussi leur propre distance au joueur (y compris les colonnes natives certifiées), sans nouvelle Part ni changement des budgets. Le serveur reste propriétaire des dangers et colliders. [Contrat](VIS_REAL_PLATFORM_OWNER_NEAR_RIM_3D_LOD_2026-11-05.md). **Code sur main ; build/Cloud/Android à vérifier.**

**Lot 1 / 7 — arrière-plans visibles jusque sur les bords (5 novembre 2026) :** correction de la disparition des cinq familles de silhouettes natives de secours, causée par le culling du groupe complet depuis le centre du terrain. Chaque structure utilise aussi la distance à sa position réelle, sans augmenter les seuils Low 145 / Medium 215, budgets 3D ni le coût des sources approuvées. [Contrat](VIS_OUTBOARD_NATIVE_FALLBACK_RIM_LOD_2026-11-05.md). **Code source ; QA moteur/Android à certifier.**

**Lot 1 / 7 — silhouettes d'origine réparties sur les CINQ mondes (5 novembre 2026) :** extension du même sélectionneur purement spatial aux véritables refroidisseurs 3D de Towers et aux satellites sculptés Orbital. Un modèle authentique proche, puis des modèles autorisés dans d'autres quartiers ; budgets GPU, caméra, distances et restaurations de Parts identiques, sans texture ni maillage supplémentaire. [Contrat](VIS_FIVE_WORLD_DISTRIBUTED_ORIGINAL_OUTBOARD_3D_2026-11-05.md). **Code source non publié ; build/Cloud/visuels Android à contrôler.**

**Lot 1 / 7 — véritables silhouettes 3D dans plusieurs secteurs (5 novembre 2026) :** les façades d'architecture Classic/Crossroads et les barges Harbor conservent les mêmes assets créateur approuvés, distances et budgets de rendu, mais répartissent les emplacements supplémentaires sur des zones réellement séparées au lieu de concentrer deux modèles Medium côte à côte. [Contrat](VIS_DISTRIBUTED_REAL_3D_OUTBOARD_SKYLINE_2026-11-05.md). **Code source et tests moteur requis ; screenshots Android ultérieurs.**

**Lot 3 / 7 — danger 3D lisible à coût mobile maîtrisé (5 novembre 2026) :** la catastrophe Disappearing Platforms marque seulement les vraies surfaces condamnées au serveur ; le client remplace un scan de 200+ plateformes chaque 0,12 s par le suivi des 1–2 avertissements actifs. Plus de fausse alerte sur simple matériau néon et retrait immédiat de l'accent jaune à Gone. [Contrat](VIS_EVENT_DRIVEN_REAL_DISAPPEARING_PLATFORM_WARNING_2026-11-05.md). **Code non publié ; QA et captures Android à confirmer.**

**Lot 2 / 7 — vraie navigation immédiatement au spawn (5 novembre 2026) :** les motifs de centre et les indications des quatre parcours physiques sont maintenant indépendants du dossier `Mechanics` facultatif : plus de disparition de tous les indices en attendant les pads mobiles sur Android ; les pads réapparaissent lors de leur chargement. [Dossier](VIS_FIRST_JOIN_REAL_ROUTE_GUIDES_WITHOUT_MECHANICS_2026-11-05.md). **Code uniquement ; Android et moteur à vérifier.**

**Lot 2 / 7 — accès réel aux quatre parcours depuis le spawn (5 novembre 2026) :** le serveur marque exactement les quatre premiers paliers physiques de chaque monde ; les flèches Android apparaissent même si les plateformes/métadonnées arrivent après Base/Mechanics, puis se masquent sur Warning/Gone, perte de collision ou streaming. Les abonnements ne concernent que ces quatre vrais paliers, sans nouveau parcours ni boucle. [Contrat](VIS_REAL_PERIMETER_ENTRY_STREAMING_AND_HAZARD_GUIDES_2026-11-05.md). **Source seulement, certification moteur et Android en attente.**

**Lot 4 / 7 — identité Harbor et lumière Darkness Android (5 novembre 2026) :** le centre Harbor cesse d'utiliser le quadrillage Classic et emploie deux marques de quai ; l'apparition Harbor remplace ses faux grands axes néon par des impulsions courtes portuaires. L'éclairage mobile normal est maintenu, mais son supplément de remplissage n'éclaircit plus une catastrophe Darkness (y compris en Double Chaos). [Contrat](VIS_HARBOR_REAL_IDENTITY_AND_ANDROID_DARKNESS_LIGHTING_2026-11-05.md). **Code seulement ; build/Cloud et captures Android encore à confirmer.**

**Lot 1 — continuité 3D sur toute l'arène (5 novembre 2026) :** les véritables sous-châssis de 22 studs et colonnes originales des cinq mondes réservent toujours les silhouettes de premier plan, mais répartissent les autres modèles approuvés sur les vrais secteurs éloignés, sans augmenter les budgets High/Medium ni générer de route fictive. [Dossier](VIS_3D_SPATIAL_SKYSPINE_CRADLES_COLUMNS_2026-11-05.md). **Validation source/Android en attente.**

**Lot 1 — chargement 3D progressif (5 novembre 2026) :** les véritables sous-châssis longs `LongCradle` peuvent désormais apparaître dès que les plateformes physiques et le modèle approuvé sont présents, sans attendre le décor secondaire ; les colonnes originales se montent ensuite à l'arrivée des vrais `PlatformSupportN_K` via une seule reprise événementielle groupée. [Dossier](VIS_3D_LONG_CRADLE_LATE_DECOR_STREAMING_2026-11-05.md). **Code uniquement : contrôles moteur et appareils non effectués sur ce SHA.**

**Lot 1 — continuité visuelle source du 5 novembre 2026 :** 16 High / 8 Medium véritables carapaces, majorité près de la caméra puis répartition sur les decks physiques de toute l'arène, sans nouvelles Parts ni boucle de rendu. Towers sélectionne le véritable pont proche pour son treillis 3D avec quota un seul et autorité des shutters. [Contrat et contrôles](VIS_3D_PLATFORM_SPATIAL_COVERAGE_2026-11-05.md). **Source seulement, build/Cloud/Android et publication à confirmer.**

**Lot 1 — avancement source (4 novembre 2026) :** nouvelle sélection de carapaces réelles selon la proximité de la zone jouée plutôt que des numéros modulo 6/12 ; plafonds 16 High et 8 Medium, aucun modèle Low, fallback natif strict. Le sampler existant adapte désormais les MeshParts de route et underdecks à la pression graphique. [Dossier technique](NEAR_CAMERA_APPROVED_PLATFORM_CARAPACE_2026-11-04.md). **Montage en jeu et certification Android non encore prouvés.**

**Lot 1 — jonctions réelles des grandes passerelles (4 novembre 2026) :** les carapaces compactes ne peuvent plus masquer un sous-châssis long qu'elles ne couvrent pas. De vrais `LongCradle` sur les plus proches promenades et Sky Spine (max 4 High / 2 Medium), et des colonnes originales proches caméra dans le même budget module 16/8 ; anciens truss natifs masqués seulement si le véritable treillis est monté. [Contrat technique et QA](PREMIUM_APPROVED_SKYBRIDGE_UNDERCARRIAGE_2026-11-04.md). **Source intégrée, rendu Android et publication non attestés.**

**Lot 1 — fiabilité des grandes jonctions (5 novembre 2026) :** le masquage des anciens sous-châssis et poutres n'est désormais autorisé que tant que le vrai Part serveur est sûr, visible, non rétréci et sans shutter actif. Restauration réactive et sélective pendant `CollapsePhase`, `ShrinkingArena` et streaming. [Contrat et QA](ROUTE_NATIVE_3D_FALLBACK_HAZARD_LIFECYCLE_2026-11-05.md). **Validation moteur et réelle à confirmer.**

**Lot IA/parcours — source 5 novembre 2026 :** fermeture de l'accès de navigation à toute Skybridge dont le vrai volet n'est pas `Idle` ; 16 sites existants de décisions NPC maintenant synchronisés, plus le contrôle du propre appui physique du bot, y compris fuite et socialisation, sans augmenter le coût du cheminement. [Dossier](BOT_TRUE_SKYBRIDGE_GATE_PATHING_2026-11-05.md). Validation exacte du jalon moteur et essai Android encore nécessaires.

**Lot 3 — prédiction des obstacles IA (5 novembre 2026) :** destinations au sol refusées depuis un skydeck sans liaison, pré-vérification physique bornée des objectifs ordinaires avant collision, priorité absolue aux catastrophes et sauts authentiques. Compteurs rig serveur des obstacles détectés/évités. [Détails et critères de QA](BOT_OBSTACLE_PREVIEW_REAL_GROUND_ROUTE_2026-11-05.md). **Source enregistrée, pas de validation Android revendiquée.**

**Lot IA — validité des routes au sol (5 novembre 2026) :** un parcours calculé par `PathfindingService` ne reste plus fiable par défaut pendant 11 secondes. Validation physique bornée du segment courant au maximum tous les 0,72–0,96 s par bot engagé, rejet immédiat si le vrai plancher ou un mur bloque, abandon contrôlé avec métrique, et angle droit rapproché à 2,25 studs avant franchissement. [Contrat](BOT_LIVE_GROUND_PATH_CORRIDOR_AND_CORNERS_2026-11-05.md). **Validation moteur et Android non attestées sur ce nouveau SHA.**

**Lot visuel prioritaire VIS-009/VIS-010 — 5 novembre 2026 :** remplacement premium des paliers et passerelles réelles recentré sur la couverture géométrique certifiée par les modèles approuvés (source X/Z, nombre minimal de sections, panneaux natifs conservés si couverture insuffisante ou streaming). Quotas 3 Medium / 5 High, sans augmentation de la densité Low ni nouvelle boucle, comptage client de surfaces réellement remplacées. [Dossier](PREMIUM_NEAR_CAMERA_COMPLETE_ROUTE_SHELLS_2026-11-05.md). **Validation moteur sur ce SHA et captures Android encore nécessaires.**

**Lot VIS-010 / VIS-027 — quatre vrais portiques Sky Spine 3D (5 novembre 2026) :** étapes 2/5/6/9 des cinq mondes éligibles au véritable Model Roblox Approved 71492051540032 ; plafonds 1/2/4 Low/Medium/High dégradés sous pression, repli natif immédiat si modèle supprimé, compteur distinct pour les deux nouveaux portiques externes. [Dossier](APPROVED_3D_FOUR_SKY_SPINE_GATEWAYS_2026-11-05.md). **Validation moteur et appareil à obtenir.**

**Lot VIS-010 / VIS-PBR — continuité métallurgie 2K passerelle/portique Sky Spine (5 novembre 2026) :** `PremiumRoutePbrKit` applique uniquement aux groupes ARMOR/ALLOY/BRUSHED/CERAMIC des vrais MeshParts approuvés les `SurfaceAppearance` 2K déjà certifiés, en protégeant SIGNAL/GRIP/CARBON, avec démantèlement atomique et budget mobile strict. [Dossier](APPROVED_2K_PBR_BRIDGE_TO_SKY_SPINE_JOINTS_2026-11-05.md). **Validation build/Cloud et contrôle Android encore attendus.**

**Lot VIS-048 — vrai éclairage SIGNAL du Sky Spine (5 novembre 2026) :** jusqu'à deux `PointLight` sur les vrais MeshParts approuvés des portiques 3D, avec budget Low 0 / Medium 1 / High tactile 1 / High desktop 2 ; zéro sous pression et extinction immédiate Darkness/Warning, sans nouveaux colliders ni boucles. [Dossier](SKY_SPINE_GENUINE_SIGNAL_LIGHTING_2026-11-05.md). Validation moteur sur le nouveau SHA nécessaire, aucune publication par ce lot.

**Lot VIS-010 / VIS-027 — raccords 3D réels (5 novembre 2026) :** les quotas existants de 3/5 passerelles Medium/High sont désormais alloués avec priorité aux vraies plateformes successives et aux deux jonctions du H Sky Spine/proménades, avec validation du collider, gap et altitude. Les copies isolées perdent la priorité, les faux ponts restent impossibles. [Dossier](APPROVED_CONTIGUOUS_3D_SKY_ROUTE_JUNCTIONS_2026-11-05.md). **Tests moteur et visuels Android requis ; aucune publication par ce lot.**

**Lot VIS-027 / VIS-PBR — portiques Harbor 2K (5 novembre 2026) :** 2K sur le véritable cargo gantry approuvé le plus visible en Medium/High sans pression, six portiques physiques conservés, matériaux SIGNAL/GRIP/CARBON protégés, retour natif immédiat si le Model disparaît. [Détails](APPROVED_HARBOR_SKYWALK_GANTRY_2K_PBR_AND_NATIVE_FALLBACK_2026-11-05.md). **Validation moteur et appareil à obtenir, pas de publication.**

## 1. État réellement vérifié du produit

| Domaine | Acquis confirmé dans le dépôt | Réserve / manque de preuve |
| --- | --- | --- |
| Infrastructure | Main `d36f65157286`. Build [#41923239283](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41923239283), sept suites Roblox Cloud [#41923254445](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41923254445) et jalon lumière [#41923216601](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41923216601) : **success**, même SHA. | Cela ne valide pas une session Android authentique, ni une publication de ce SHA. |
| Arènes | Cinq arènes `Classic`, `Towers`, `Crossroads`, `Orbital`, `Harbor`, toutes `BaseSize=320×320`. | Une grande base ne signifie pas des routes riches sur 320 studs : couverture/choix réels à mesurer, et beaucoup de géométrie de premier plan reste native. |
| Authenticité 3D | **62 Roblox Model assets approuvés** dans `assets/source/roblox-asset-registry.json`. Les derniers lots couvrent Skyline Classic/Crossroads, cinq towers réelles, six stations Orbital, Harbor et diverses structures, avec fallback natif et budgets LOD. | Les flags `publication.models_inserted_in_game=false` et `android_visual_qa_completed=false` ne permettent pas de certifier les modèles réellement observés sur appareil. |
| PBR/lumière | Quatre familles de matériaux PBR originaux, directions solaires différentes par arène, recalibrage des matériaux pendant READY/round. | Ne pas considérer `VIS-042/043/057` clos avant images et comparaison perceptuelle ; vérifier `Darkness`, contre-jour, lampes et danger sur Android. |
| IA / population | `AISurvivorRules.desiredBotCount` remplit le lobby de round jusqu'à **8 participants initiaux**, avec 7 bots maximum, puis roster bloqué. Navigation/récupération d'obstacles élaborée. | Le chiffre 8 ne veut PAS dire huit survivants pendant toute la manche. Pas de mesure récente de blocage, fluidité, temps de réaction et équité des bots. |
| Fonctionnement public | Le propriétaire a signalé que des sessions récentes fonctionnaient. | [Ticket #563](https://github.com/dbrckk/chaos-survival-roblox/issues/563), problème « Waiting for an available server » daté du 2 novembre, **toujours ouvert**. Il faut distinguer incident réglé et preuve d'accès public récent. |
| QA visuelle | Workflow existant `roblox-ai-remote-windows.yml` capable de créer une session Studio et de viser **15 captures × 5 arènes = 75 images**, avec manifestes. | Le dernier essai documenté était `AUTH_REQUIRED` et produisait **0/75 images**. L'authentification officielle Studio reste nécessaire dans une session Windows temporaire ; aucune capture IA fictive. |
| Audio / motion | Mix audio, spatialisation, locomotion R6/R15 et effets de mouvement existants. | `AudioConfig.lua` contient encore des sons `rbxasset://sounds/...` et `AnimationCatalog.lua` des clips R15 Roblox standards. |
| Produit | Onze catastrophes, Double Chaos, vote/READY/round/result, progression, quêtes, monnaies, statistiques. | Mesurer la compréhension de la première minute, la rétention et l'interaction plutôt que supposer qu'elles sont bonnes. |

**Pas de nouvelle note /10 fondée** sans sessions filmées, révision des cinq arènes et mesures du vrai appareil. Les notes historiques sont des estimations sur code, pas une preuve d'apparence.

## 2. Ordre strict des grands lots

| Ordre | Priorité | Lot complet | Résultat concret exigé |
| --- | --- | --- | --- |
| **0** | **P0 — sûreté produit** | Vérité de version, accès public, collecte visuelle | Session publique démarrée, bonne place/univers, aucune boucle de connexion ; 75 images Studio authentiques OU limitation documentée ; SHA et parcours de release fiables |
| **1** | **P0 — grand impact visuel** | **Premier plan et routes 3D terminés** : plateformes, dessous, jonctions, rails cosmétiques, escaliers, ponts et grandes supports | Les vraies routes ne ressemblent plus à des assemblages cubiques en High, aucune fausse surface sûre, collision serveur et fallback Low intacts |
| **2** | **P0 — level design** | Cinq grandes arènes jouables, pas seulement cinq grands sols | Plusieurs choix de déplacement tangibles depuis le spawn, routes alternatives uniques par carte, lignes de vue lisibles, dimensions et densité utiles |
| **3** | **P0 — comportement** | Bots crédibles et interactions joueur-environnement | 8 participants au début, élimination honnête, aucun bot durablement coincé sur les scénarios QA, animation et décisions cohérentes, zéro téléportation injuste |
| **4** | **P1 — direction artistique** | Cinq identités finales cohérentes : matériaux, UV/PBR, lumière, skyline, météo | Rendu distinct sans HUD, faces/sols visibles Android Low/Medium/High, aucun danger masqué ni catastrophe Darkness neutralisée |
| **5** | **P1 — spectacle jouable** | Catastrophes, réaction du décor, timing et interactions | Onze catastrophes lisibles par silhouette + son + préavis, destruction synchronisée avec collider, Double Chaos équitable |
| **6** | **P1 — sensation premium** | Animation originale R15/R6, sons originaux, caméra, mix | Déplacement sans glissement visible, transitions correctes et sons non stock pertinents, feedback fiable même sans audio |
| **7** | **P1 — première minute/UI** | Onboarding, HUD Android, vote/READY/résultat, objectif suivant | Comprendre le but sans lire un long texte, agir avant 30 secondes, résultat/récompenses immédiatement visibles, ergonomie tactile |
| **8** | **P2 — finition commerciale** | Récompenses, progression, identité de marque et page Roblox | Progression sans P2W, icône/miniatures prises du jeu, consentement/publication et assets sous licences vérifiées |
| **9** | **P0 — livraison** | Certification Android + Studio + moteur, publication gardée | Exact-SHA gates réussis, mesures FPS/mémoire, preuves visuelles datées, tests publics, rollback prêt, publication contrôlée unique |

**Règle d'interruption :** tout blocage de connexion, spawn, physique, bot empêchant la manche, DataStore, crash ou perte de progression remonte immédiatement avant le lot visuel en cours. Le lot 0 est un contrôle de vérité, **pas** une nouvelle longue phase d'infrastructure.

## 3. Exécution détaillée et définition de terminé

### Lot 0 — Reconnaître le runtime réel avant de le modifier

1. Inspecter le dernier publisher GitHub Actions réussi et le `versionNumber` Roblox de l'univers **10771083668** et de la place **95351659174730**, sans prétendre que le SHA source correspond à la publication avant preuve.
2. Reproduire ou classer [#563](https://github.com/dbrckk/chaos-survival-roblox/issues/563) : accès public neuf, arrivée lobby, entrée dans la manche, reconnexion. Clore le ticket uniquement après preuve de disparition ; le retour « cela fonctionne » est utile mais pas une mesure instrumentée.
3. Exploiter d'abord les hooks du workflow de capture authentique existant. Pour `All`, collecter 15 captures `Studio` par carte, plus trois angles permettant de voir le sol, les bâtiments lointains et le HUD. Ne pas déclencher une machine éphémère qui attendrait en vain l'authentification officielle.
4. Exporter les diagnostics `LocalOriginal*`, `LocalNative*`, PBR et Lighting aux moments des captures. Distinguer `source approved`, `modèle présent runtime`, `modèle visible`, `qualité perçue validée`.
5. Préparer le **plan de vérification de chaque lot**, sans multiplier builds moteur à chaque petit commit.

**Terminé si :** incident public classé avec preuve, provenance source/public claire, état exact de la capture et des 62 modèles connu. Si Studio n'est pas accessible, avancer sur les lots de code sans inventer une validation visuelle.

### Lot 1 — Vraies géométries près de la caméra, priorité absolue du rendu

**Fichiers d'entrée existants :** `src/client/PremiumRouteMeshKit.lua`, `PremiumPlatformSideMeshKit.lua`, `PlatformNativeTrimReplacementKit.lua`, `ArenaDeckFinishKit.lua`, `src/server/MapBuilder.lua`, `ArenaGroundArchitecture.lua` ; pour Harbor `HarborScenery.lua`, `SkySpineArchitecture.lua` et les kits de caissons/grues/carènes déjà approuvés.

1. Établir un inventaire **par nom réel de Part/MeshPart** de chaque zone à moins de 80 studs de la caméra : collision jouable, avertissement, effet transitoire, habillage uniquement décoratif. Ne jamais masquer le collider ou l'avertissement de danger.
2. Remplacer **d'abord la silhouette complète** des grandes plateformes, sous-faces, passerelles et raccords par des modèles approuvés existants. Couvrir la majorité des structures vraiment dominantes à l'écran plutôt que se concentrer sur des boulons.
3. Garder les éléments `Part` non cosmétiques sur le serveur ; cacher le décor natif indexé **seulement après** l'installation complète d'un vrai modèle validé. Restaurer immédiatement après streaming, destruction, shrink, LOD ou catastrophe.
4. Changer la géométrie autorisée si un raccord est mal conçu, en conservant le contrat de saut, les collisions et les navigations IA. Pas de modèle tiers non licencié ni de `MeshId` inventé.
5. Variantes par carte, pas seulement une même sculpture recolorée : Classic (grilles et relais), Towers (structures verticales), Crossroads (passerelles de transit), Orbital (courbes/anneaux), Harbor (quais industriels).
6. Fixer la couverture mesurée en QA : objectif **≥90 % des grands éléments cosmétiques du parcours visibles en vrai mesh** sur High, avec fallback intact et propre en Low. Cette cible doit être mesurée sur captures, elle n'est pas déjà atteinte.

**Terminé si :** silhouettes manifestement travaillées sur les cinq cartes, 0 route fictive, 0 perte de collision, 0 disparition abusive de danger, nombre de vrais meshes confirmé en jeu, aucune dette de montage/récupération.

### Lot 2 — Transformer les 320×320 studs en vraie aire de survie

**Fichiers :** `ArenaVariants.lua`, `MapBuilder.lua`, `ArenaMechanics.lua`, `Disasters/ShrinkingArena.lua`, navigation/rampes/hélix existantes.

- Plutôt qu'agrandir encore `BaseSize`, dessiner pour chaque map **trois familles de routes réellement utilisées** : rapide/risquée, longue/sûre et verticale/échappatoire. Elles doivent rencontrer au moins un danger ou une interaction propre à la carte.
- Rendre chaque départ, destination et alternative visible depuis un point de décision sans HUD, avec des silhouettes/hauteurs différenciées.
- Empêcher les trajets sans échappatoire, les sauts impossibles sur mobile et les routes supprimées mais visuellement présentes pendant `ShrinkingArena`.
- Aligner les objectifs des bots sur **les mêmes points physiques** que les humains, sans déplacement privilégié.

**Terminé si :** parcours mesurés sur cinq cartes, ≥2 choix viables depuis chaque zone principale, aucun point chaud de spawn/retour qui piège les joueurs, test de navigation humains/bots identique.

### Lot 3 — IA, interactions, lisibilité du jeu à huit

**Fichiers :** `AISurvivorService.lua`, `AISurvivorRules.lua`, `bot-motion-polish.client.lua`, `ArenaMechanics.lua`, `GameAnalytics.lua`.

- Conserver `TargetVisibleParticipants=8` **au départ du round** : avec un humain, sept bots max. Les bots éliminés ne réapparaissent pas artificiellement pour maintenir huit survivants, et les nouveaux humains attendent les règles d'insertion sans double place.
- Traquer les phases de blocage `stuckCount` / `recoverIfStuck`, les mauvaises directions, les murs et les hésitations. Objectif de QA : **0 immobilisation non résolue de plus de six secondes** sur une session de 30 minutes, hors arrêts délibérés.
- Vérifier que le pathfinding ne crée ni pont invisible, ni téléportation, ni vitesse réservée aux bots ; faire varier choix, anticipation, mouvement et attention sociale.
- Augmenter les interactions utiles : éléments de décor activables ou réactifs, signaux de coop, obstacles et plateformes qui exigent une décision, sans effets purement décoratifs comptabilisés comme gameplay.
- Partager les statistiques existantes : ratio de survie humains/bots par carte, recoveries, délai première action, heatmap de mort si collecte autorisée. L'axe Harbor existe déjà dans la liste autoritaire `ArenaVariants.Order`.

**Terminé si :** round à huit participants au départ, bots crédibles sous observation, 0 blocage prolongé dans les scénarios QA, équité statistique examinée (sans équilibrer automatiquement sur des chiffres inventés).

### Lot 4 — Cinq scènes premium avec lumière et PBR contrôlés

**Fichiers :** `VisualTheme.lua`, `arena-lighting.client.lua`, `ArenaLightingReadabilityRules.lua`, `juice.client.lua`, `pbr-district-materials.client.lua`, `ArenaPostProcessLayer.lua`.

- Comparer des captures authentiques à caméra/phase comparables : Low, Medium, High ; lobby, READY, round, résultat et Darkness.
- Vérifier les quatre canaux `Color/Normal/Roughness/Metallic` pour les matériaux qui les utilisent, l'échelle UV, l'orientation des normales, l'absence de z-fighting et de surfaces uniformément chromées.
- Conserver les directions solaires des cinq arènes et les améliorations du diffus validées sur source ; **ne pas simplement pousser `Brightness` partout**. Protéger les silhouettes et les surfaces de jeu contre bloom, fog et noir.
- Vérifier le vrai contraste joueur / danger / plateforme / décor lointain ; aucune correction globale ne doit éclaircir artificiellement Darkness.
- Réduire l'overdraw et les reflets excessifs sur Low ; réserver les détails lourds, éclairages et 2K aux surfaces prioritaires réellement visibles.

**Terminé si :** chaque map identifiable sans HUD, toutes les zones de sécurité/risque lisibles sur appareil, absence de clipping/halos masquants, rendu High premium ET Low stable.

### Lot 5 — Onze catastrophes, du préavis au résultat

**Fichiers :** `Disasters/*`, `arena-cinematic-disaster-atmosphere.client.lua`, `disaster-signature-vfx.client.lua`, `hazard-warning-visuals.client.lua`, `ArenaCrisisSurfaceRules.lua`.

- Pour chaque catastrophe, un langage de forme + son + mouvement : `anticipation → impact → évitement → aftermath`. Les zones qui blessent ne doivent jamais différer de l'avertissement visuel.
- Transformer les grandes primitives les plus visibles, **lave, météores, effondrement, tornade et plateformes qui disparaissent**, avant les micro-débris.
- Faire réagir le vrai décor : balises, panneaux, ventilations, structure et son, avec LOD automatique ; pas d'objet sans interaction utile.
- Vérifier les combinaisons Double Chaos réellement compatibles, en écartant les superpositions qui cachent le sol ou rendent la survie impossible.

**Terminé si :** onze catastrophes reconnaissables sans nom, avertissement correct et équité confirmée, aucun faux effet de destruction résiduel après round.

### Lot 6 — Mouvement, audio, identité 2D et première minute

- Remplacer en priorité les **cinq clips R15 génériques des bots** (`AnimationCatalog.lua`) par des clips originaux correctement publiés et autorisés, en conservant des transitions anatomiques R6/R15 et l'animation fallback si chargement refusé. Éliminer patinage des pieds, pivots robotiques, pause des bras.
- Reprendre `AudioConfig.lua` : sfx essentiels READY, catastrophe, collision, réussite et musique ; vérifier propriété/licences, spatialisation, niveaux et voix non synthétique robotique. Pas de nouvel audio non autorisé.
- Simplifier la première minute : **Survivre jusqu'à 0** évident, flèche utile vers la route, prochaine menace lisible, victoire/résultat célébrés et choix de « rejouer » sans confusion. Les panneaux HUD mobiles ne doivent jamais chevaucher une alerte.
- Conserver accessibilité (son coupé, daltonisme, ReduceMotion, text-scaled), performances et latence tactile.
- Remplacer les icônes de base par une identité visuelle originale cohérente, puis capturer icône/miniatures authentiques du jeu, pas une représentation trompeuse du gameplay.

**Terminé si :** première action utile <30 s dans un parcours observé, compréhension du but en une lecture rapide, victoire/récompense toujours visible, effets/sfx premium sans sons génériques dominants.

### Lot 7 — Certification de sortie, pas « green pipeline = jeu AAA »

1. **Source** : code complet sur `main`, pas de marqueurs fictifs, vrais assets modérés/licenciés, scripts et droits sous contrôle.
2. **Tests exact-SHA** : `Build Validation` et **sept suites réelles** `Roblox Open Cloud Engine Tests` de ce même SHA, aucune suite vide/skipped ; `Studio E2E` authentifié avec artéfacts si disponible.
3. **Visuel** : 75 captures du workflow Studio ou preuve authentique équivalente ; revue réelle Android **Low/Medium/High**, cinq maps, onze dangers, bots et transitions.
4. **Performance** : sur Android cible, 30 min de jeu ; objectif de départ **Low ≥30 FPS soutenus**, **Medium ≥45 FPS** si le matériel le permet, pas de baisse mémoire/instances monotone, pas de blocage >250 ms répété. Ces chiffres sont des objectifs à confronter au téléphone réel, pas des résultats déjà obtenus. Contrôler aussi température, batterie, réseau moyen et reprise après suspension Android.
5. **Fonctionnement** : arrivée serveur, spawn, déplacement, huit participants initiaux, élimination/récompense, sauvegarde/reconnexion, parcours/risques, retour lobby, plusieurs manches successives, restauration après streaming.
6. **Destination** : vérifier les IDs, la version et le rollback de la place. **Un seul déploiement public** du candidat certifié, seulement après le gate Release Candidate et les preuves humaines nécessaires.

## 4. Prochain lot à exécuter sans réouvrir le plan

**Entrée immédiatement exécutable : `P0-runtime + VIS-009 / VIS-010 / VIS-025 / VIS-027`.**

- D'abord vérifier sans modifier le jeu l'état exact de la publication et de l'incident #563. Débloquer si réellement reproduit ; sinon consigner l'absence de preuve indépendante.
- Ensuite, **finir le remplacement des grands volumes de gameplay proches caméra** (routes, plateformes et dessous) en utilisant en priorité `PremiumRouteMeshKit`, `PremiumPlatformSideMeshKit` et `PlatformNativeTrimReplacementKit`. Inventorier séparément les vrais colliders, avertissements et simples blocs cosmétiques. Couvrir une famille complète de surfaces sur les cinq cartes sans lancer de multiples mini-versions.
- Contrôler le montage/fallback Low et le shrink ; ne pas rajouter un deuxième sampler LOD, de texture inventée ou de MeshPart sans provenance.
- Ne déclencher les suites moteur qu'à la fin de ce **gros lot visible**. Ajouter ensuite les preuves visuelles réelles et marquer les items `VIS` clos uniquement s'ils sont réellement certifiés.

## 5. Politique de suivi

- Pour chaque lot, tenir un état **À faire / Source développée / Source + build validés / Visuel appareil validé / Publié**, un SHA et des liens de preuves, sans confondre les niveaux.
- Les fichiers antérieurs `ROADMAP_PREMIUM_EXECUTION_2026-11-04.md`, `URGENT_AAA_VISUAL_BACKLOG_2026-11-03.md`, `VISUAL_QA_SCORECARD.md` et `RELEASE_CHECKLIST.md` restent les annexes. Ce document prend la priorité pour l'ordre des gros travaux.
- Limiter les vérifications coûteuses pendant le développement ; aucun nouveau test unitaire n'est demandé. Préférer les outils déjà disponibles, gratuits et open source.
- Le prochain « continue », « go » ou « fais la suite » commence directement le **lot actif et non validé** de ce plan, après inspection du HEAD actuel et des éventuelles modifications concurrentes.
