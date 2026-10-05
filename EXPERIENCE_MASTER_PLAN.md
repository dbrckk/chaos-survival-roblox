# CHAOS SURVIVAL — EXPERIENCE MASTER PLAN

Objectif
========
Amener l'expérience au niveau d'un jeu Roblox commercial très poli, sans sacrifier Android, lisibilité ou équité. Le critère n'est pas "plus d'effets", mais une boucle où chaque seconde est lisible, réactive, satisfaisante et donne une raison de rejouer.

Principes directeurs
====================
1. Fun perceptible en moins de 30 secondes.
2. Chaque catastrophe doit avoir une identité visuelle + sonore + mécanique immédiatement reconnaissable.
3. Chaque mouvement important doit produire un feedback cohérent : caméra, animation, VFX, son, UI.
4. Les cartes doivent être lisibles en une seconde mais riches en routes, silhouettes et micro-décors.
5. La progression doit créer des objectifs courts, moyens et longs sans P2W.
6. Tout polish doit respecter le budget mobile : VFX adaptatifs, peu de lumières coûteuses, pas de logique RenderStep inutile.
7. Aucun système ne doit ajouter du bruit visuel pendant les 5 dernières secondes critiques.

Audit actuel — 2026-10-02
=========================
FORCES
- Boucle de round complète, 11 catastrophes, Double Chaos/Fusion, Overdrive, Final Rush.
- Solo Rush + AI Survivors crédibles pour serveur peu rempli.
- 4 arènes distinctes, mobilité contextuelle, Shards, défis, médailles, momentum.
- HUD mobile déjà structuré et VFX adaptatifs.
- DataStore, analytics, dailies, achievements, cosmetics et monétisation cosmétique.
- CI moteur réelle couvrant la matrice de gameplay.

ECARTS PRINCIPAUX
P0 — Game feel
- Aucun système dédié unifiant landing, impulsions caméra, inclinaison de mouvement, réponse aux impacts.
- Les sensations reposent surtout sur VFX/UI ; le corps et la caméra peuvent encore sembler "Roblox de base".

P0 — Audio
- Architecture premium en place : mix dynamique, ducking, spatialisation 3D Meteor/Bomb, signatures composites par catastrophe, pad/landing/near-miss/result feedback.
- Principal écart restant : remplacement progressif des sons historiques Roblox par des assets originaux/Creator Store vérifiés de meilleure qualité.

P0 — Cartes / décor
- Bonne base sci-fi néon mais langage encore trop homogène.
- Variantes surtout différenciées par géométrie/couleur ; manque de landmarks, profondeur et storytelling environnemental.
- Peu de micro-décors interactifs/animés.

P1 — Personnalisation
- 11 cosmetics, principalement variation de couleur/Trail/Aura.
- Il manque silhouettes, raretés, collections, previews plus désirables et récompenses longues.

P1 — Rétention
- Daily quests + daily reward + achievements présents.
- Manquent objectifs hebdomadaires, collections, mastery par catastrophe/arène et "next goal" très visible après chaque round.

P1 — Animation
- Couche corporelle R15 procédurale superposée à Animate : lean, SpeedSurge, LowGravity, jump/fall, launch pad, impact, landing, victoire/élimination/Master Round.
- Principal écart restant : véritables clips authored originaux pour locomotion/launch/landing/celebrations afin de dépasser définitivement le langage Roblox standard.

P1 — UX/UI
- Fonctionnelle et riche, mais init.client.lua est très dense et plusieurs panneaux se disputent l'espace.
- Besoin d'une hiérarchie encore plus stricte : survival > danger > timer > objectifs > méta.

P2 — Présentation publique
- Icon/thumbnails/captures finales encore absents.
- Nécessitera des scènes composées spécifiquement pour la page Roblox.

RE-AUDIT — 2026-10-04
=======================
P0 — Validation réelle
- Plus gros risque restant : aucune certification visuelle/tactile/performance longue sur vrai Android ni Studio authentifié pour le HEAD actuel. Le code peut être propre sans garantir composition, occlusion, chauffe ou confort caméra réels.

P0 — Audio assets
- Architecture audio désormais avancée (mix, spatial, EQ/réverb, ambience map-specific, footsteps material-aware), mais plusieurs sources utilisent encore des sons Roblox historiques. L'écart qualitatif principal est maintenant l'acquisition/remplacement par assets originaux ou Creator Store vérifiés.

P1 — Animation
- Body feel procédural riche : stride, freinage, virage, jump/fall, launch, impact, résultats et anticipation READY. Le plafond restant vient surtout de l'absence de clips authored originaux publiés sur Roblox.

P1 — Maps / décor
- Géométrie, profondeur et langage de navigation sont solides. Le pass actuel ajoute landmarks narratifs, asymétrie et silhouettes de bord propres à chaque map. Reste principalement la QA visuelle en caméra réelle et, éventuellement, une passe finale de composition après captures Studio.

P1 — UI critique
- Hiérarchie survival/danger renforcée. Les cues Meteor/Bomb et ShrinkingArena disposent maintenant de lanes séparées sur petits écrans ; validation tactile réelle reste requise.

P2 — Public polish
- Icon, thumbnails, trailer et captures finales restent non produits ; à ne lancer qu'après certification visuelle/device du build.

ROADMAP
=======
PHASE A — GAME FEEL CORE
[FAIT] A1 Caméra réactive légère : landing, impacts, pads, accélération et FOV vitesse plafonné/adaptatif.
[FAIT] A2 Mouvement : micro-tilt, landing/burst, sensation périphérique de vitesse + lean/compression corporelle R15 locale et compatible Animate. SpeedSurge bénéficie d'un FOV/pitch/lean dédiés ; LowGravity ajoute dérive caméra aérienne et pose flottante ; locomotion additive désormais rythmée par la vitesse avec stride subtil, freinage, réponse de virage et réduction automatique du swing sur demi-tours.
[FAIT] A3 Haptics adaptatifs touch/gamepad : pads, impacts, close calls, shards, Final Rush et résultats.
[FAIT] A4 Réduction automatique du mouvement caméra sur VFX Low / mobile.
[EN COURS] A5 Reduce Motion persistant ajouté ; QA réelle motion sickness à effectuer sur appareil.

PHASE B — AUDIO PREMIUM
[FAIT] B1 Spatialiser météores/bombes/impacts.
[FAIT] B2 Mix dynamique séparé Music / Hazard / UI / Reward, avec priorité danger en round et Final Rush.
[FAIT] B3 Ducking musique lors des rounds critiques / Final Rush.
[EN COURS] B4 Cues critiques + chaque accent catastrophe + Vote/Reward/Last Survivor/Overdrive/Flow Combo/MobilityPad recomposés en couches distinctes ; loops protégés des accents one-shot, Meteor/Bomb multi-couches spatiales, landing pondéré par airtime, EQ/réverb propres aux cues clés pour réduire l'effet sons Roblox recyclés. Remplacement final par assets originaux/Creator Store vérifiés encore à faire.
[EN COURS] B5 Profils tonaux/pitch propres à chaque arène + beds spatiaux 3D ajoutés : Classic/Towers/Crossroads/Orbital ont EQ, réverb, pitch, rayon et placement distincts ; 1/2/3 sources selon Low/Medium/High et ducking automatique Overdrive/Final Rush. Assets d'ambiance originaux dédiés à sélectionner plus tard.

PHASE C — MAP ART PASS
[EN COURS] C1 Classic Grid : broadcast fins, grille animée, mâts skyline, cadrage broadcast, surface technique, sous-structure et réponse lumière/ColorShift dédiée ; QA visuelle finale restante.
[EN COURS] C2 Towers : machinery/antennes, énergie verticale, mégastructures, rails, cadrage industriel, anneaux de surface, supports profonds et éclairage acier/ColorShift ; QA finale restante.
[EN COURS] C3 Crossroads : gantries/signaux, flux directionnel, portiques skyline, cadrage transit, lanes lumineuses, midground urbain et lumière diffuse violette ; QA finale restante.
[EN COURS] C4 Orbital : reactor nodes/struts, couronne, anneaux skyline, satellites, arcs de surface, sous-structure et ColorShift spatial renforcé ; QA finale restante.
[FAIT] C5 Lobby hub : couronne, panneaux identité/fair-play, progression personnelle et runway/ribs cadrant clairement le portail arène.
[EN COURS] C6 Profondeur en 5+ couches + horizon calme + transition reveal d'arène, avec surface, bords, sous-structure, midground, skyline, couronne d'horizon très lointaine et void multicouche. Lobby et arène sont désormais reliés visuellement par un transit non-collidable avec cascade READY ; silhouettes lointaines spécifiques Classic/Towers/Crossroads/Orbital + langage de navigation fonctionnel relié aux vrais pads, avec LOD dédié. QA visuelle finale restante.
[FAIT] C7 Signatures animées distinctes + 3 profils de rythme/direction/amplitude alternés à chaque round.

PHASE D — VFX / ANIMATION
[FAIT] D1 Hiérarchie telegraph -> impact -> aftermath : impacts, shock rings, afterglow, debris et ambiance résiduelle. Lecture de fuite locale réservée aux dangers réellement évitables Meteor/Bomb ; Freeze conserve son télégraphe global. Identifiants aftermath alignés et couverture complète des 11 catastrophes.
[FAIT] D2 Debris/afterglow adaptatifs sur impacts, avec budget Low/Medium/High.
[FAIT] D3 11 signatures catastrophe : palettes/atmosphères distinctes + warning geometry dédiée pour Meteor/Bomb/JumpShock/Disappearing Platforms. Disappearing Platforms expose un état Warning/Gone répliqué et un cadre d'effondrement local adaptatif ; Tornado ajoute une traction caméra tangentielle de proximité ; JumpShock émet un impact feedback dédié ; ShrinkingArena ajoute une pression d'écran locale et resserre aussi les vrais pads de mobilité, dont le langage visuel suit désormais la position.
[FAIT] D4 Feedback monde + poses corporelles procédurales distinctes pour victoire, élimination et Master Round, plus états authored procéduraux jump/fall/pad launch/hazard impact/landing ; résultat désormais full-body (root+hanches+épaules), locomotion additive testée et compatible Animate/Reduce Motion.
[FAIT] D5 Final Rush réduit UI méta + challenge/momentum + auras/lights/trails/highlights non essentiels.

PHASE E — CUSTOMIZATION
[EN COURS] E1 Catalogue porté à 17 items avec Founder, Hyper Neon et Arena Masters ; extension future optionnelle.
[FAIT] E2 Raretés visuelles Common/Rare/Epic/Legendary/Premium, sans puissance.
[FAIT] E3 Preview claire dans UI : dégradé réel ColorA→ColorB affiché sur chaque carte cosmétique.
[FAIT] E4 Quatre cosmétiques GOLD liés aux maîtrises d'arène, unlock live, non achetables et explicités dans l'UI.
[FAIT] E5 Deux sets premium permanents clarifiés (Founder + Hyper Neon), trail+aura, prix Marketplace dynamique, aucun avantage gameplay.

PHASE F — RETENTION / FUN
[FAIT] F1 "Next goal" niveau/XP affiché après les rounds hors événements prioritaires.
[FAIT] F2 Mastery persistante catastrophe/arène avec paliers Rookie/Bronze/Silver/Gold/Elite et affichage post-round.
[FAIT] F3 Weekly challenges persistants : 2 objectifs/semaine, progression serveur-authoritative, récompenses modérées et UI intégrée.
[FAIT] F4 Collection log : sets, owned/total, sets complétés, milestones Collector 3/6/9/11 et célébration honorifique au franchissement.
[EN COURS] F5 FIRST CHAOS medal + célébration monde garanties au premier round terminé. FTUE implémenté : boost lobby guidé, vote, placement, survie, marqueur monde contextuel, menus secondaires masqués avant la première manche, challenge newcomer = 1 pad et première manche protégée des Chaos Fusions ; QA réelle Studio/mobile restante.
[FAIT] F6 Rotation portée à 6 micro-objectifs, toujours un seul challenge affiché : shards, pads, close call, momentum, flow et variété.
[FAIT] F7 Audit Double Chaos : paires à faible agence bloquées (Freeze + hazards létaux/sol mouvant, JumpShock + ShrinkingArena, Tornado + ShrinkingArena), minimum de 2 partenaires sûrs par catastrophe garanti par test, matrice >=40 paires autorisées, HUD Fusion affiche désormais les deux identités visuelles + nom de fusion.
[FAIT] F8 AI Survivors hazard-aware : réactions urgentes Meteor/Bomb/plateforme instable évaluées à chaque tick cerveau indépendamment du wander, délai humain par profil conservé, CollapsePhase utilisé comme source de vérité, plateformes/pads mobiles suivis pendant ShrinkingArena et parité dégâts radiaux IA/humains couverte par test.
[FAIT] F9 AI Survivors map-aware : sélection de cibles limitée aux hauteurs atteignables à pied, usage des pads pondéré par topologie, approche des pads non décalée par l'anti-regroupement, cibles sociales verticalement atteignables, continuité de route propre à Classic/Towers/Crossroads/Orbital (anneau Orbital, lanes Crossroads, montée locale Towers).
[FAIT] F10 AI Survivors humanisés : tempérament légèrement différent à chaque round tout en conservant l'identité Cautious/Balanced/Bold, hésitations rares hors urgence, changements d'avis occasionnels, durée d'engagement variable, direction préférée renouvelée par round et suivi social anticipant légèrement le mouvement réel d'un joueur proche. Les réactions critiques aux hazards gardent le profil de base afin de ne pas simuler des erreurs artificielles face aux télégraphes.
[FAIT] F11 Difficulté AI Survivors calibrée sans triche : mêmes 100 PV/dégâts que les humains, pression de survie bornée selon santé/Final Rush/Double Chaos, risque/social/hésitation et largeur de choix ajustés progressivement, sauts optionnels réduits à faible santé mais jamais supprimés ; aucune modification des réflexes critiques face aux warnings.
[FAIT] F12 Mouvement AI Survivors humanisé : steering progressif sur déplacements normaux, virage direct sur danger urgent et approche finale des pads, micro-pause uniquement sur demi-tour non critique, courbure conservée sans snap brutal, état de steering reset aux téléports/changements de phase et cadence de marche légèrement individualisée par bot sans toucher aux WalkSpeed pilotés par les catastrophes.
[FAIT] F13 Présence AI Survivors plus crédible : 5 familles d'accessoires procéduraux au lieu de 3, morphologie et trail liés à l'identité plutôt qu'au slot, rotations sociales adoucies, réactions résultat persistantes et variées (jump/sidestep/acknowledge/still) selon tempérament, avec nettoyage complet des états entre phases.
[FAIT] F14 Lobby AI vivant : rotation entre roam/practice/social/vote, regroupements bot↔bot ou bot↔humain avec espacement et cooldown, partenaires sociaux alternés, usage des practice pads sans spam, regroupement temporaire distribué autour du centre pendant les votes puis dispersion, orientation douce vers le centre et gestes sociaux suspendus pendant le vote pour éviter le jitter. Steering et recovery utilisent explicitement l'espace lobby hors round afin de ne jamais être clampés vers l'arène.

PHASE G — UI/UX
[EN COURS] G1 Responsive centralisé via UIResponsive : profils fondés sur dimensions réelles, support 640x360/800x360/1280x720, top HUD/timer/votes/result/panels en hauteurs pixel-safe, cartes de vote simplifiées sur écrans très bas et focus de round dédié ; validation réelle 16:9/tall/tablet encore requise.
[EN COURS] G2 Dock tactile unique avec cible >=44 px, stats/XP déplacés au-dessus du dock puis masqués pendant READY/ROUND mobile, panels réservés au-dessus du dock, warning data séparé du compteur survivants et menus FTUE masqués avant la première manche ; QA réelle restante.
[FAIT] G3 Tokens de mouvement UI centralisés : press/release, panel-in, result emphasis et fades cohérents.
[FAIT] G4 State machine UI : READY/ROUND ferme la méta, masque le dock et invalide tout résultat retardé ; gameplay critique prioritaire.
[EN COURS] G5 Accessibilité chaos renforcée : Reduce Motion persistant actif sur caméra/postFX/décors/world polish + Freeze/Lava premium ; textes critiques avec planchers lisibles mobile ; Meteor/Bomb ajoutent cue écran texte+badge et formes d'évasion distinctes ; ShrinkingArena affiche MOVE CENTER à forte pression ; Disappearing Platforms ajoute un X de pré-effondrement en plus de la couleur. QA contraste/daltonisme/motion sickness réelle restante.

PHASE H — PERFORMANCE
[EN COURS] H1 Budgets dynamiques appliqués aux world VFX, impacts, lights, cosmétiques + LOD local scenery ; mesures réelles restantes.
[EN COURS] H2 Boucles/scan client optimisés : warnings Meteor/Bomb limités aux enfants directs Workspace, VFX pads limités au dossier Arena/Mechanics, LOD scenery cache ses descendants entre changements, Tornado cache les paramètres de débris et respecte Reduce Motion, ShrinkingArena VFX cache la Base active, world-polish anime seulement l'espace de jeu actif, arena-ambient-props et arena-identity-motion dorment désormais hors READY/ROUND/RESULT, et environment-depth reste entièrement événementiel (0 RenderStepped/Heartbeat/scan continu). Audit transversal des 11 catastrophes maintenu ; mesures réelles device encore requises.
[EN COURS] H3 Budgets VFX/Light étendus aux cosmétiques et ambience ; Low réduit lights/particles/specular, Final Rush supprime du bruit visuel.
[A FAIRE] H4 Soak Android 30-60 min.
[A FAIRE] H5 MicroProfiler sur appareil réel.

PHASE I — PUBLIC POLISH
[A FAIRE] I1 Icon finale.
[A FAIRE] I2 3-5 thumbnails.
[A FAIRE] I3 Trailer 15-30 s.
[A FAIRE] I4 Store page mobile.
[A FAIRE] I5 Release candidate 1.0.

Ressources externes évaluées
============================
- star-list : aucun package Roblox/Luau/game-feel pertinent trouvé actuellement.
- RbxCameraShaker (MIT) : bonne référence pour l'architecture d'impulsions caméra ; pas nécessaire de l'importer si une version légère locale suffit.
- Springs Luau MIT : utiles comme référence pour motion/UI fluide ; à intégrer seulement si le besoin dépasse notre spring locale.
- Roblox Creator Hub : référence pour FTUE, rétention, performance mobile et audio spatial/dynamique.

Ordre d'exécution immédiat
==========================
1. Game feel core.
2. Audio spatial + mix.
3. Map art pass.
4. VFX/animation.
5. Customization + retention.
6. UI simplification.
7. Android/performance certification.
8. Assets marketing et RC 1.0.


- [FAIT] Pass hero scenery local : ArenaHeroSceneryLocal, budgets Low/Medium/High, LOD 130/205 studs, silhouettes uniquement en second plan hors routes, aucun impact collision/gameplay.
- [FAIT] Arena lighting enrichi par Atmosphere local map-specific ; densité/haze/glare fortement réduits en READY/ROUND pour préserver la priorité des télégraphes.

- [FAIT] Composition d'entrée : Spawn CFrames orientés par map (centre Classic, verticalité Towers, lanes Crossroads, tangente Orbital), humains/AI Survivors alignés et chevrons directionnels au sol.

- [FAIT] Identité locale des plateformes : motifs spécifiques Classic/Towers/Crossroads/Orbital, soudés aux plateformes pour suivre ShrinkingArena, densité réduite en Low et LOD 105/165 studs.

- [FAIT] Pass matériaux/micro-détails : seams de panneaux, repair plates, edge wear arène, paneling lobby/runway et variation d'albédo déterministe sur structures non-Neon. Budgets Low/Medium/High conservés, aucune boucle frame ajoutée.
- [FAIT] Hot-swap visuel fiabilisé : ArenaSurfaceDetail, ArenaHeroScenery, ArenaPlatformIdentity, MaterialVariation, ArenaEdgeProfile, ArenaUnderstructure et ArenaAmbientProps se reconstruisent désormais lors du remplacement de l'Arena sans recréer GeneratedMap.

- [FAIT] Locomotion additive authored : cycle stride lié à la vitesse, freinage, virage signé/sévérité, réduction du swing sur demi-tour, poses résultat full-body et règles pures couvertes par tests moteur.
- [FAIT] Traitement audio spectral : profils EQ/réverb par cue catastrophe/mobilité/résultat, appliqués à la source et hérités par les one-shots clonés ; bornes de sécurité couvertes par tests.

- [FAIT] Présentation résultat premium : hiérarchie partagée MASTER / CLUTCH / SURVIVED / ELIMINATED, carte résultat colorée distinctement, célébration clutch dédiée, spotlight monde du joueur local et des survivants humains/AI pour conserver une fin de round crédible même en solo.

- [FAIT] Presentation layer de manche : countdown READY 3-2-1 synchronisé audio/visuel, reveal de départ SURVIVE!/SURVIVE THE FUSION!, rails écran colorés, micro-kick caméra additive compatible Reduce Motion, pulse monde au round start, double pulse pour Fusion et pulse orange/rouge au Final Rush. Priorités explicites Final Rush > Round Start > Fusion > Overdrive > countdown, aucun RenderStepped ajouté.
- [FAIT] Arena reveal resynchronisé avec l'entrée réelle en READY afin que la signature de map soit vue après téléportation ; round-events repositionné sur mobile court pour ne pas recouvrir les cues de danger.

- [FAIT] Set-piece d'ouverture des 11 catastrophes : RisingLava rise columns, Meteors skyfall streaks, LowGravity lift beams, DisappearingPlatforms fracture lines, Tornado spiral pillars, Freeze expanding ice ring, Bombs blast rings, SpeedSurge lane streaks, Darkness void contraction, ShrinkingArena collapse ring, JumpShock shock rings. Double Chaos joue les deux signatures avec léger décalage, budgets Low/Medium/High et Reduce Motion conservés.

- [FAIT] Climax progressif des 11 catastrophes : deux paliers visuels déclenchés par RoundIntensity, Overdrive promeut directement au palier critique et Final Rush déclenche le climax maximal. Chaque disaster possède un langage propre (jets, sky streaks, lift beams, fractures, spirale, ice ring/spikes, blast rings, speed lanes, void contraction, shrink contraction, shock rings), joué une seule fois par palier et par disaster. Double Chaos conserve deux climax décalés. Aucun RenderStepped ajouté.
- [FAIT] Optimisation disaster-motion-vfx : LowGravity/SpeedSurge persistent désormais entre broadcasts et ne sont plus détruits/recréés chaque seconde ; rebuild uniquement lors d'un changement de phase/combinaison.

- [FAIT] Disaster residue / décor marqué : Meteor/Bomb laissent scorch/crater + cracks et fragments temporaires ; Freeze/JumpShock laissent un résidu après pulse ; les 11 catastrophes génèrent un langage de trace spécifique pendant RESULT (char, crater, dust, fracture, scrape, frost, scorch, streak, void, edge, shock), avec raycast vers la vraie surface, budgets Low/Medium/High, fade progressif et nettoyage avant READY.

- [FAIT] Character polish joueurs/AI : accent cosmétique unifié via ChaosAccent, outline/rim local contextuel sans remplacer l'avatar, lumière discrète Medium/High, spectateurs/éliminés atténués pendant ROUND, doublons d'aura évités et budgets Final Rush/Low stricts.
- [FAIT] Cosmétiques en mouvement : trails joueurs transformés en rubans horizontaux plus propres, AISurvivorCosmeticTrail soumis aux mêmes budgets VFX/Reduce Motion/Final Rush, contact sol surface-aware pour humains et bots avec culling distance et micro-débris uniquement Medium/High.

- [FAIT] Variété silhouette AI renforcée : DepthScale/HeadScale déterministes et bornés en plus des Height/Width/BodyType/Proportion existants, afin de réduire l'effet clones sans modifier gameplay/hitboxes logiques.
- [FAIT] Contact personnage/environnement finalisé : ring aligné à la normale réelle de la surface ; pendant Final Rush, seuls les impacts du joueur local sont conservés pour préserver lisibilité et budget VFX.

- [FAIT] Lobby vivant/premium : presentation locale pilotée par le vrai état serveur (intermission+voteOptions, ready, waiting), hologramme central contextuel, zones sociales, focus vote, practice pads réactifs, corridor/runway qui s'arme pendant READY, ripple halo/social basse fréquence et retour au lobby marqué après RESULT.
- [FAIT] AI lobby raccordé au décor : les AI Survivors utilisent réellement quatre social nodes cohérents avec les zones visibles, tout en conservant socialisation, vote gathering et practice boosts existants.
- [FAIT] Game feel lobby : practice boost déclenche pulse visuel local + cue audio composite léger ; caches décor/pads évitent les rescans à chaque pulse, aucun RenderStepped ajouté et les éléments locaux sont masqués pendant ROUND.

- [FAIT] Nettoyage lobby transversal : lobby-practice reste la source unique du feedback visuel practice, mais se déclenche désormais sur LobbyPracticeUses confirmé serveur ; l'ancien swoosh direct a été supprimé et l'audio passe par le cue MobilityPad central.
- [FAIT] Perf lobby : lobby-core-orbit ne met plus à jour ses nodes pendant ROUND/READY, devient invisible hors lobby et adapte sa cadence à Low/Medium/High + Reduce Motion ; audit des autres lobby-* confirme absence de RenderStepped et time-trial déjà throttlé à 10 Hz uniquement en waiting/intermission.

- [FAIT] World depth premium : corridor/transit visuel lobby→arène, ribs/supports/rails sous le niveau jouable, cascade lumineuse READY, atténuation pendant ROUND, horizon très lointain centré sur l'ensemble du monde et couleurs hors catastrophe alignées sur le thème d'arène.
- [FAIT] Horizon variant-aware : Classic reste broadcast/industriel équilibré, Towers devient plus vertical avec antennes, Crossroads plus horizontal avec bras/gantries, Orbital utilise volumes sphériques/cylindriques ; parallax obtenu naturellement par vraie géométrie 3D à différentes distances.
- [FAIT] Void multicouche : cadre intermédiaire vers y=-17, seconde profondeur Medium/High vers y=-36, accents emissifs budgetés et fond distant non-collidable ; aucun RenderStepped/Heartbeat ajouté.

- [FAIT] Perf micro-vie arène : ArenaAmbientProps et ArenaIdentityMotion conservent toutes leurs animations pendant READY/ROUND/RESULT mais passent à 0,60 s de sommeil au lobby au lieu de mettre à jour les props ~10 Hz hors écran.

- [FAIT] Spatial arena ambience : beds 3D map-specific autour de l'arène, rolloff borné pour rester inaudible au lobby, EQ/réverb propres à chaque map, fade par phase et aucun RenderStepped/Heartbeat.
- [FAIT] Perf speed-feel : boucle UI passe de 20 Hz permanent à 0,40 s hors participation, 0,12 s sous le seuil de vitesse et 0,08 s seulement quand les streaks sont visibles.

- [FAIT] Render loops catastrophe passés à la demande : disaster-motion-vfx, disaster-premium-vfx, ShrinkingArena pressure, DisappearingPlatforms readability, Meteor/Bomb hazard routes et Tornado ne gardent plus de RenderStepped connecté quand aucun effet correspondant n'est actif.
- [FAIT] AI server perf : warnings Meteor/Bomb/Freeze/JumpShock indexés via Workspace ChildAdded/ChildRemoved au lieu d'un scan GetChildren toutes les ~0,15 s ; brain cadence = 0,18 s avec bots actifs, 0,42 s pendant RESULT et 0,75 s sans bot.

- [FAIT] Map storytelling pass : chaque arène reçoit un landmark narratif hors gameplay (régie broadcast Classic, lift maintenance Towers, hub transit Crossroads, reactor Orbital) avec labels Medium/High et zéro boucle frame.
- [FAIT] Silhouettes de bord propres : ticks broadcast Classic, buttresses Towers, rails de sortie Crossroads, ticks tangentiels Orbital ; aucun impact collision/gameplay.
- [FAIT] Asymétrie contrôlée Medium/High : booth ops, crane maintenance, lane fermée et docking arm pour casser l'effet procédural trop régulier.
- [FAIT] Anticipation READY procédurale : stance corporelle légère avant départ, relâchée au GO, désactivée progressivement par le mouvement et couverte par BodyMotionRules.
- [FAIT] UI danger lanes : cue Meteor/Bomb repositionné sous top HUD selon UIResponsive ; MOVE CENTER bascule latéralement sur compact/tiny pour coexister en Double Chaos.
- [FAIT] Footsteps material-aware : EQ/réverb du son Running local pilotés par FloorMaterial, donnant une signature distincte DiamondPlate/Metal/Slate/SmoothPlastic sans asset supplémentaire ni boucle frame.

- [FAIT] Composition secondaire premium : masses midground distinctes par arène entre deck et skyline (broadcast blocks Classic, cooling towers Towers, transit masses Crossroads, station pods Orbital), budgets Low/Medium/High et zéro boucle frame.
- [FAIT] Sous-structure variant-aware complète : Classic reçoit châssis/data bays, Crossroads junction + trunks cardinaux, Towers core vertical + braces, Orbital hub + spokes + arcs ; lecture de la map conservée même depuis dessous/en chute.
- [FAIT] Focal lighting map-specific : 0 spot Low, 2 Medium, 3 High ; zones de landmark ciblées, fort duck pendant ROUND et quasi-extinction Final Rush pour laisser les hazards prioritaires.
- [FAIT] Matériaux secondaires variant-aware : Classic DiamondPlate, Towers CorrodedMetal, Crossroads Concrete/Slate, Orbital SmoothPlastic sur fraction déterministe Medium/High ; matériaux d'origine conservés/restaurés uniquement en état local Lua.
- [FAIT] Props de service hors routes : caméras broadcast Classic, crates maintenance Towers, bollards/barriers Crossroads, canisters Orbital ; budget 2/4/6 selon qualité.
- [FAIT] AI animation blend : idle/walk/run/jump/fall avec seuils et playback speed liés à la vitesse/gait ; évite le simple walk accéléré des bots rapides et conserve les réactions résultat existantes.
- [FAIT] Surface audio étendu : footsteps + landing locaux partagent désormais le profil EQ/réverb de FloorMaterial, pour cohérence entre matériau visible et contact sonore.
- [FAIT] CI moteur : 56 specs actuellement assignées exactement une fois aux shards Open Cloud ; Build Validation vert sur les derniers commits de cette passe.

- [FAIT] Game feel saut : coyote time 100 ms + jump buffer 120 ms via JumpRequest commun clavier/manette/tactile ; coyote limité à vraie Freefall pour empêcher tout double jump, compatibilité Freeze conservée via JumpPower/JumpHeight.
- [FAIT] LOD composition étendu : ArenaMidgroundMassLocal, ArenaServicePropsLocal et ArenaFocalLightingLocal intégrés au scenery LOD avec distances Low/Medium dédiées ; High conserve la composition complète.
- [FAIT] Studio E2E renforcé : vérifie désormais ChaosRoundFocus, ChaosRoundEvents, HazardReadabilityCue et ShrinkPressure, bounds viewport, taille valide et non-chevauchement Meteor/Bomb ↔ MOVE CENTER.
- [FAIT] Release packaging : README synchronisé avec les 17 cosmetics, AI Survivors, mastery, weekly challenges, 4 arènes nommées, nouvelle composition visuelle, material audio et game-feel ; protocole playtest mobile enrichi avec hazard lanes + coyote/buffer.
- [FAIT] Audit production : aucun TODO/FIXME/HACK, aucun rbxassetid://0 ni print() debug détecté ; Game Pass IDs restent volontairement externes via DataModel attributes SupporterPassId/NeonPackPassId.
- [FAIT] Storytelling micro-décor : les props de service Medium/High portent désormais des marquages diégétiques map-specific (CAM, MAINT, lanes, AUX) via SurfaceGui local, sans collision, sans asset externe et sans coût en Low.

RE-AUDIT UX — 2026-10-05
=========================
[FAIT] Continuité vote → READY → GO : l'action à effectuer face au danger reste visible jusqu'au départ, au lieu de disparaître après le vote.
[FAIT] Double Chaos : le HUD affiche maintenant une consigne courte pour chacun des deux dangers actifs.
[FAIT] Accessibilité FTUE : Reduce Motion / Sound sont accessibles dès la première session hors phase critique, sans exiger une manche déjà jouée.
[FAIT] Guidage rookie monde : boost lobby et pad d'évasion localisés FR/EN, portée augmentée et texte compatible petits écrans.
[FAIT] Guidage arène : noms, stratégie et fonction des pads localisés par VariantId ; carte READY passée en dimensions pixel-safe sur mobile.
[FAIT] Boucle après élimination/résultat : feed d'élimination, badges survivants humains/IA, wayfinding lobby, récompenses, maîtrise, médailles, séries et next goal alignés sur la langue du joueur.
[CONFIRMÉ] Solo social : jusqu'à 3 AI Survivors R15 restent intégrés comme survivants crédibles (noms, vote, lobby, hazards, spectateur, résultat) sans badge "BOT".
[A VALIDER] Les changements ci-dessus restent soumis aux workflows Build Validation/Open Cloud du HEAD et au contrôle Android physique avant publication.

SOCIAL / CAPTIVATION PASS — 2026-10-05
======================================
[FAIT] Stratégie complète ajoutée dans SOCIAL_EXPERIENCE_PLAN.md : présence sociale, synchronie, agency, statut non-P2W, mémoire collective, revanche et lobby "third place".
[FAIT] Boucle d'invitation native Roblox : CTA uniquement après au moins une manche et uniquement aux moments calmes (RESULT / pré-vote), jamais en danger ou pendant le vote.
[FAIT] Framing contextuel : victoire = INVITE FRIENDS ; défaite = BRING BACKUP, avec texte FR/EN.
[FAIT] Crew Signal : nouveau landmark social diégétique dans le lobby, lié à l'action d'invitation plutôt qu'à une publicité flottante permanente.
[FAIT] Last Chaos board : le lobby conserve une mémoire visuelle courte de la manche précédente (danger, arène, survivants) pour créer continuité et histoire partagée.
[FAIT] Payload résultat enrichi avec arenaId/disasterIds/survivorsAlive/contestantCount afin que les présentations sociales restent basées sur des identifiants fiables.
[FAIT] Rendu néon : BloomEffect adaptatif par qualité et phase, fort hors combat puis fortement atténué pendant ROUND afin de préserver les télégraphes.
[A VALIDER] Composition Crew Signal + Last Chaos board sur vrai Android et différentes tailles d'écran.
[A SUIVRE] Reconnaissance d'arrivée d'un ami invité, crew streak purement social, photo/lineup de groupe, analytics funnel social.

[FAIT] Invite LaunchData : une arrivée réellement issue du Crew Signal est reconnue côté serveur, sans modifier spawn/récompenses/puissance ; conversion analytique enregistrée.
[FAIT] Rituel social résultat : réactions GG / ENCORE / INCROYABLE réservées au multijoueur, une seule par joueur et par résultat, rendues au-dessus des avatars et absentes du gameplay actif.
[FAIT] Analytics social funnel : exposition CTA, ouverture prompt, arrivée via invitation et réaction résultat sont maintenant distinguables.



GUIDES DE PRODUCTION — 2026-10-05
================================
[FAIT] AAA_VISUALS_ANIMATION_GUIDE.txt : standard obligatoire pour graphismes, PBR, lighting, maps, VFX, animation, caméra et optimisation visuelle.
[FAIT] GAME_FEEL_UX_GUIDE.txt : standard obligatoire pour contrôle, feedback, rythme, onboarding, social, rétention saine, mobile et accessibilité.
[RÈGLE] Toute future amélioration doit être évaluée contre ces deux guides avant validation finale.
