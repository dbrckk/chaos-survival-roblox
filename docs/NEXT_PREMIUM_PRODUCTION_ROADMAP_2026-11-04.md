# Chaos Survival — nouveau plan d'amélioration premium après les lots 3D et lumière

**Créé le 4 novembre 2026.** Dépôt : `dbrckk/chaos-survival-roblox`, branche `main`, SHA source de référence : `d36f651572860ee6d3d57c0ae3f4ecd11fef698d`. Plan d'exécution du produit, pas preuve que cette version a été publiée ni que le rendu satisfait déjà un niveau AAA.

> **Cap de production :** fiabilité > jeu réellement fonctionnel > sécurité/équité > architecture > performance > rendu visuel > fonctionnalités secondaires. Le **rendu visible, les vraies routes et les bots** constituent les prochains gros investissements, pas l'accumulation d'ornements. Terminer chaque lot au niveau final visé avant de passer au suivant. Ne créer aucune version publique intermédiaire ni tests unitaires supplémentaires. Exécuter les builds/tests moteur aux jalons importants seulement.

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
