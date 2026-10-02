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
[FAIT] A1 Caméra réactive légère : landing, impacts, pads, vitesse.
[FAIT] A2 Mouvement : micro-tilt, landing/burst, sensation périphérique de vitesse + lean/compression corporelle R15 locale et compatible Animate.
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
[EN COURS] C1 Classic Grid : broadcast fins + grille animée + skyline technique dédiée ; QA visuelle finale restante.
[EN COURS] C2 Towers : machinery/antennes + énergie verticale + mégatours distantes ; QA visuelle finale restante.
[EN COURS] C3 Crossroads : gantries/signaux + flux directionnel + skyline transit basse ; signage/QA finale restante.
[EN COURS] C4 Orbital : reactor nodes/struts + couronne + satellites/nodes distants ; QA visuelle finale restante.
[FAIT] C5 Lobby hub : couronne, panneaux identité/fair-play et hologramme progression personnelle niveau/wins/coins/XP/collection.
[EN COURS] C6 Micro-décors animés + skyline + couronne orbitale du Chaos Core, client-local et adaptatifs ; QA visuelle finale restante.
[FAIT] C7 Signatures animées distinctes + 3 profils de rythme/direction/amplitude alternés à chaque round.

PHASE D — VFX / ANIMATION
[FAIT] D1 Hiérarchie telegraph -> impact -> aftermath : impacts, shock rings, afterglow, debris et ambiance résiduelle.
[FAIT] D2 Debris/afterglow adaptatifs sur impacts, avec budget Low/Medium/High.
[FAIT] D3 11 signatures catastrophe : palettes/atmosphères distinctes + warning geometry dédiée pour Meteor/Bomb/JumpShock/Disappearing Platforms.
[EN COURS] D4 Feedback monde victoire/élimination/Master Round ajouté ; animations corporelles avancées à poursuivre.
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

PHASE G — UI/UX
[EN COURS] G1 Layout responsive + dock tactile + palier compact/tablette <1.50 ajoutés ; validation réelle 16:9/tall/tablet encore requise.
[EN COURS] G2 Boutons méta masqués pendant READY/ROUND + dock tactile unique + result/panels compactés sur tablette/mobile ; QA réelle restante.
[FAIT] G3 Tokens de mouvement UI centralisés : press/release, panel-in, result emphasis et fades cohérents.
[EN COURS] G4 Hiérarchie de phase renforcée : gameplay critique > méta-progression.
[EN COURS] G5 Reduce Motion persistant actif sur caméra/postFX/décors/world polish ; contraste et warnings redondants, QA réelle restante.

PHASE H — PERFORMANCE
[EN COURS] H1 Budgets dynamiques appliqués aux world VFX, impacts, lights, cosmétiques et scan IA warnings mis en cache ; mesures réelles restantes.
[EN COURS] H2 Boucles catastrophe idle ; world-polish cache centres lobby + CenterBeacon, réutilise profil VFX et réduit motion.
[EN COURS] H3 Budgets VFX/Light étendus aux cosmétiques par client ; Low désactive aura lights et réduit fortement particules/trails.
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
