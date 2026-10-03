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
- Beaucoup de cues réutilisent les sons historiques Roblox (collide/swoosh/ping).
- Peu de spatialisation 3D sur impacts.
- Pas encore de véritable mix dynamique par phase/danger.

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
- AI Survivors ont animation R15, mais le joueur réel repose surtout sur animations Roblox standards.
- Peu de célébrations corporelles, anticipation ou recovery liés aux événements.

P1 — UX/UI
- Fonctionnelle et riche, mais init.client.lua est très dense et plusieurs panneaux se disputent l'espace.
- Besoin d'une hiérarchie encore plus stricte : survival > danger > timer > objectifs > méta.

P2 — Présentation publique
- Icon/thumbnails/captures finales encore absents.
- Nécessitera des scènes composées spécifiquement pour la page Roblox.

ROADMAP
=======
PHASE A — GAME FEEL CORE
[FAIT] A1 Caméra réactive légère : landing, impacts, pads, accélération et FOV vitesse plafonné/adaptatif.
[FAIT] A2 Mouvement : micro-tilt, landing/burst, sensation périphérique de vitesse + lean/compression corporelle R15 locale et compatible Animate. SpeedSurge bénéficie maintenant d'un FOV/pitch/lean dédiés ; LowGravity ajoute dérive caméra aérienne et pose flottante corporelle.
[FAIT] A3 Haptics adaptatifs touch/gamepad : pads, impacts, close calls, shards, Final Rush et résultats.
[FAIT] A4 Réduction automatique du mouvement caméra sur VFX Low / mobile.
[EN COURS] A5 Reduce Motion persistant ajouté ; QA réelle motion sickness à effectuer sur appareil.

PHASE B — AUDIO PREMIUM
[FAIT] B1 Spatialiser météores/bombes/impacts.
[FAIT] B2 Mix dynamique séparé Music / Hazard / UI / Reward, avec priorité danger en round et Final Rush.
[FAIT] B3 Ducking musique lors des rounds critiques / Final Rush.
[EN COURS] B4 Cues critiques + Vote/Reward/Last Survivor/Overdrive/Flow Combo recomposés en couches premium ; remplacement final par assets originaux/Creator Store vérifiés encore à faire.
[EN COURS] B5 Profils tonaux/pitch propres à chaque arène ajoutés ; assets d'ambiance dédiés à sélectionner plus tard.

PHASE C — MAP ART PASS
[EN COURS] C1 Classic Grid : broadcast fins, grille animée, mâts skyline, cadrage broadcast, surface technique, sous-structure et réponse lumière/ColorShift dédiée ; QA visuelle finale restante.
[EN COURS] C2 Towers : machinery/antennes, énergie verticale, mégastructures, rails, cadrage industriel, anneaux de surface, supports profonds et éclairage acier/ColorShift ; QA finale restante.
[EN COURS] C3 Crossroads : gantries/signaux, flux directionnel, portiques skyline, cadrage transit, lanes lumineuses, midground urbain et lumière diffuse violette ; QA finale restante.
[EN COURS] C4 Orbital : reactor nodes/struts, couronne, anneaux skyline, satellites, arcs de surface, sous-structure et ColorShift spatial renforcé ; QA finale restante.
[FAIT] C5 Lobby hub : couronne, panneaux identité/fair-play, progression personnelle et runway/ribs cadrant clairement le portail arène.
[EN COURS] C6 Profondeur en 5 couches + horizon calme + transition reveal d'arène, avec surface, bords, sous-structure, midground, skyline et props adaptatifs. Reveal spécifique à chaque arène + langage de navigation fonctionnel relié aux vrais pads (chevrons directionnels, balises verticales Towers, repères centraux propres à chaque map), avec LOD dédié ; QA visuelle finale restante.
[FAIT] C7 Signatures animées distinctes + 3 profils de rythme/direction/amplitude alternés à chaque round.

PHASE D — VFX / ANIMATION
[FAIT] D1 Hiérarchie telegraph -> impact -> aftermath : impacts, shock rings, afterglow, debris et ambiance résiduelle. Lecture de fuite locale réservée aux dangers réellement évitables Meteor/Bomb ; Freeze conserve son télégraphe global. Identifiants aftermath alignés et couverture complète des 11 catastrophes.
[FAIT] D2 Debris/afterglow adaptatifs sur impacts, avec budget Low/Medium/High.
[FAIT] D3 11 signatures catastrophe : palettes/atmosphères distinctes + warning geometry dédiée pour Meteor/Bomb/JumpShock/Disappearing Platforms. Disappearing Platforms expose un état Warning/Gone répliqué et un cadre d'effondrement local adaptatif ; Tornado ajoute une traction caméra tangentielle de proximité ; JumpShock émet un impact feedback dédié ; ShrinkingArena ajoute une pression d'écran locale et resserre aussi les vrais pads de mobilité, dont le langage visuel suit désormais la position.
[FAIT] D4 Feedback monde + poses corporelles procédurales distinctes pour victoire, élimination et Master Round, compatibles Animate/Reduce Motion.
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
[EN COURS] F5 FIRST CHAOS medal + célébration monde garanties au premier round terminé ; accélération FTUE déjà via rookie coach, QA réelle restante.
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
[EN COURS] G1 Layout responsive + dock tactile + palier compact/tablette <1.50 ajoutés ; validation réelle 16:9/tall/tablet encore requise.
[EN COURS] G2 Boutons méta masqués pendant READY/ROUND + dock tactile unique + result/panels compactés sur tablette/mobile ; QA réelle restante.
[FAIT] G3 Tokens de mouvement UI centralisés : press/release, panel-in, result emphasis et fades cohérents.
[FAIT] G4 State machine UI : READY/ROUND ferme la méta, masque le dock et invalide tout résultat retardé ; gameplay critique prioritaire.
[EN COURS] G5 Reduce Motion persistant actif sur caméra/postFX/décors/world polish ; contraste et warnings redondants, QA réelle restante.

PHASE H — PERFORMANCE
[EN COURS] H1 Budgets dynamiques appliqués aux world VFX, impacts, lights, cosmétiques + LOD local scenery ; mesures réelles restantes.
[EN COURS] H2 Boucles catastrophe idle ; world-polish cache centres lobby + CenterBeacon, réutilise profil VFX et réduit motion. Audit transversal des 11 catastrophes : fallbacks contestants nettoyés, Freeze couvre JumpPower+JumpHeight, RisingLava ne bloque plus la physique, régression ShrinkingArena/pads couverte par test moteur. Les pads lisent désormais leur impulsion live et ShrinkingArena réduit/restaure leur poussée horizontale avec la taille réelle de l'arène afin d'éviter les launches hors-zone.
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
