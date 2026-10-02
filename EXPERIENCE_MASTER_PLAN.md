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
[EN COURS] A2 Mouvement : micro-tilt + landing + burst adaptatif ajoutés ; animation corporelle avancée à poursuivre.
[A FAIRE] A3 Feedback tactile/gamepad si supporté, sans dépendance.
[FAIT] A4 Réduction automatique du mouvement caméra sur VFX Low / mobile.
[EN COURS] A5 Reduce Motion persistant ajouté ; QA réelle motion sickness à effectuer sur appareil.

PHASE B — AUDIO PREMIUM
[FAIT] B1 Spatialiser météores/bombes/impacts.
[FAIT] B2 Mix dynamique séparé Music / Hazard / UI / Reward, avec priorité danger en round et Final Rush.
[FAIT] B3 Ducking musique lors des rounds critiques / Final Rush.
[EN COURS] B4 Cues critiques recomposés en couches premium ; remplacement final par assets originaux/Creator Store vérifiés encore à faire.
[EN COURS] B5 Profils tonaux/pitch propres à chaque arène ajoutés ; assets d'ambiance dédiés à sélectionner plus tard.

PHASE C — MAP ART PASS
[EN COURS] C1 Classic Grid : broadcast fins + grille animée ajoutés ; art pass fin à poursuivre.
[EN COURS] C2 Towers : machinery/antennes + énergie verticale ajoutées ; art pass fin à poursuivre.
[EN COURS] C3 Crossroads : gantries/signaux + flux directionnel ajoutés ; signage fin à poursuivre.
[EN COURS] C4 Orbital : reactor nodes/struts + couronne animée ajoutés ; art pass fin à poursuivre.
[EN COURS] C5 Lobby renforcé : couronne suspendue, panneaux identité/contenu/fair-play ; progression personnalisée monde à poursuivre.
[EN COURS] C6 Micro-décors animés ajoutés par arène, client-local et adaptatifs ; profondeur finale à poursuivre.
[EN COURS] C7 Signatures animées locales distinctes ajoutées aux 4 arènes ; variation par round à poursuivre.

PHASE D — VFX / ANIMATION
[FAIT] D1 Hiérarchie telegraph -> impact -> aftermath : impacts, shock rings, afterglow, debris et ambiance résiduelle.
[FAIT] D2 Debris/afterglow adaptatifs sur impacts, avec budget Low/Medium/High.
[A FAIRE] D3 Signature visuelle unique par disaster.
[EN COURS] D4 Feedback monde victoire/élimination/Master Round ajouté ; animations corporelles avancées à poursuivre.
[A FAIRE] D5 Réduction stricte du bruit pendant Final Rush.

PHASE E — CUSTOMIZATION
[EN COURS] E1 Catalogue porté à 15 items avec set Arena Masters ; extension future optionnelle.
[FAIT] E2 Raretés visuelles Common/Rare/Epic/Legendary/Premium, sans puissance.
[FAIT] E3 Preview claire dans UI : dégradé réel ColorA→ColorB affiché sur chaque carte cosmétique.
[FAIT] E4 Quatre cosmétiques GOLD liés aux maîtrises d'arène, unlock live, non achetables et explicités dans l'UI.
[A FAIRE] E5 Sets premium peu chers mais désirables.

PHASE F — RETENTION / FUN
[FAIT] F1 "Next goal" niveau/XP affiché après les rounds hors événements prioritaires.
[FAIT] F2 Mastery persistante catastrophe/arène avec paliers Rookie/Bronze/Silver/Gold/Elite et affichage post-round.
[FAIT] F3 Weekly challenges persistants : 2 objectifs/semaine, progression serveur-authoritative, récompenses modérées et UI intégrée.
[FAIT] F4 Collection log dérivé de l'inventaire : sets cohérents, progression owned/total, sets complétés et milestones Collector.
[EN COURS] F5 FIRST CHAOS medal + célébration monde garanties au premier round terminé ; accélération FTUE déjà via rookie coach, QA réelle restante.
[A FAIRE] F6 Variété contrôlée de micro-objectifs sans surcharge.

PHASE G — UI/UX
[EN COURS] G1 Layout responsive + dock tactile ajoutés ; validation réelle 16:9/tall/tablet encore requise.
[EN COURS] G2 Boutons méta masqués pendant READY/ROUND + dock tactile unique + result tags compactés sur mobile ; simplification fine à poursuivre.
[A FAIRE] G3 Microanimations cohérentes via tokens.
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
