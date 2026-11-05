# Chaos Survival — feuille de route V2 après publication publique (5 novembre 2026)

**État de référence vérifié :** `dbrckk/chaos-survival-roblox`, version Roblox publique publiée à partir du commit **`9033d6799885ac32cf88222bbd07edace82e9266`**, par l'exécution GitHub Actions [42082161343](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42082161343) (**success**), après [Build Validation 42081379174](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42081379174) et [sept suites moteur 42081391647](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42081391647) (**success**). Cible vérifiée : universe `10771083668`, place `95351659174730`.

**Attention :** le succès CI et la réponse de publication Roblox ne démontrent pas le rendu réel, les FPS Android, les interactions, les modèles présents à l'écran, ni un niveau artistique AAA. Ce nouveau plan remplace l'ordre de priorité du [plan premium du 4 novembre](NEXT_PREMIUM_PRODUCTION_ROADMAP_2026-11-04.md), mais conserve ses contrats techniques et les [critères de validation visuelle](VISUAL_QA_SCORECARD.md). Un commit documentaire ultérieur sur `main` ne constitue jamais une nouvelle mise à jour publique.

## Cap produit et règles d'exécution

**Objectif :** une expérience de survie/plateforme Roblox crédible, immédiatement compréhensible et réellement agréable sur Android et PC, au standard visuel des expériences premium comparables ; cinq mondes distincts, environ huit vrais participants humains/IA au début de chaque manche quand les créations réussissent, comportements IA physiques crédibles, onze catastrophes lisibles, interactions physiques et sociales utiles, manches avec conséquences et progression persistante.

**Priorités :** fiabilité en public → fonctionnement réel des boucles de jeu → sécurité/équité → performances Android → qualité visible du premier plan → navigation et interaction → personnages/animation/son → méta-progression. Ne pas démarrer cinq sous-projets inachevés. Un lot = un objectif produit observable et terminé, puis des contrôles de jalon ; pas d'obligation de tests unitaires pendant chaque modification interne.

**Interdits :** maquiller une capture, considérer les 55 *emplacements éligibles* comme 55 modèles effectivement visibles, créer des parcours purement décoratifs qui semblent praticables, masquer un avertissement serveur, faire passer des bots pour des humains dans les métriques, réclamer une validation FPS sans appareil, importer des modèles sans source et modération prouvées, déployer automatiquement sans publication exacte et contrôlée, remplacer les détails par des placeholders. Réutiliser les vrais MeshParts approuvés et les assets libres compatibles dans la limite des droits et de la provenance.

## Carte d'avancement — bascule des « changements intégrés » vers « qualité effectivement validée »

| Domaine | Déjà intégré et certifié sur le commit public | Travail non encore démontré |
| --- | --- | --- |
| Publication | Place publique existante, SHA et preuve d'upload disponibles | Contrôle visuel sur le vrai client Android/PC, rejoin et version |
| Graphismes | Modèles créateur approuvés et LOD répartis ; horizon, trafic et halo Orbital éligibles à la 3D ; matériaux et éclairage paramétrés | Source réellement présente en session, géométrie convaincante au premier plan, transitions sans flash, évaluation artistique |
| Arènes | Cinq définitions 320×320 ; itinéraires et décor distincts codés | Chaque parcours jouable par un humain, points de vue, événements environnementaux et accès immédiatement intelligibles |
| IA | Objectif huit participants au READY ; gestion de chemins, dangers, portes, sorties de blocage | Tests avec 1/2/4/8 humains, bots se déplaçant naturellement et s'évitant sans collision répétée |
| Catastrophes | Onze scripts, états physiques et avertissements serveur ; Double Chaos | Captures et évaluations de cohérence/readability pour chaque danger, y compris Darkness |
| Performance | LOD Low/Medium/High, quotas PBR/MeshParts/effets, pulses FPS et mémoire côté client | p95 frame time réel, stabilité 30 min, chauffe et mémoire selon catégorie de terminal |
| Engagement | `GameAnalytics`, résultat, quêtes/succès, maîtrise et récompenses déjà en code | Taux d'entrée en manche, compréhension initiale, fin de manche motivante et métriques D1/D7 sur échantillon réel |

## Lot 0 — contrôler la version publique et éliminer les vrais défauts bloquants (P0, en cours)

**Avancement source du 5 novembre :** le canal réel `PerformancePulse` existant échantillonne désormais à 12 secondes actives après le premier join, puis toutes les 45 secondes. Il enregistrera via Analytics les **modèles 3D créateur réellement montés** dans les cinq arènes et les incohérences de restauration de leurs fallback natifs, avec des dimensions limitées et une validation serveur. Aucun nouveau RemoteEvent, sampler image ni boucle. [Implémentation, preuve de publication précédente et limites](LOT0_PUBLIC_REAL_3D_RESIDENCY_OBSERVABILITY_2026-11-05.md). **À qualifier par exact-SHA Build/Cloud ; aucune nouvelle donnée publique Android ou mise à jour Roblox revendiquée.**

**But :** arrêter les changements à l'aveugle et établir la référence *réelle* du nouveau build publié.

- Capturer une session Android physique complète sur les cinq arènes (une vue lobby, quatre directions + un parcours périphérique par monde, une catastrophe, un résultat), avec l'app Roblox; **15 vues clés par manche** pour le diagnostic visuel et une vidéo de bot/danger. Faire Low puis Medium, High sur au moins le monde le plus exigeant et Orbital.
- Contrôler les vraies transitions de qualité, les modèles du ciel/cinématiques, l'éclairage normal et Darkness, les alertes, l'absence de collision ou faux chemin, les surfaces PBR 2K, le chargement tardif, le HUD portrait/paysage et les boutons Dash/Jump.
- Jouer au moins une manche avec 1 humain + 7 bots, puis 2 et 4 humains si possible. Observer l'entrée READY, les spawns, les bots bloqués, l'évitement et la fin de manche. Ne jamais interpréter « 8/8 » comme huit joueurs humains.
- Recueillir les vrais `ClientPerformancePulse` et mesures locales (tier, FPS moyen, p95 frame time, mémoire, compte de MeshParts, transitions qualité, appareil). Tester 30 min et reprise après mise en arrière-plan.
- Regrouper seulement les défauts **observés** par gravité S0 (jeu cassé), S1 (perte de manche/visibilité/navigation), S2 (qualité visuelle/animation), S3 (détails), avec trace SHA, capture ou vidéo et critères reproductibles. Corriger S0/S1 avant de pousser plus de polissage.

**Sortie du lot :** preuve Android/PC et tableau réel des défaillances ; au minimum aucun blocage S0 connu. Si l'accès à un appareil n'est pas disponible, marquer `NON VALIDÉ SUR APPAREIL` : continuer les modifications source prudentes sans inventer la preuve.

## Lot 1 — terminer le premier plan et la direction artistique réellement premium (P1, gros lot visuel)

**But :** faire disparaître l'aspect « plateformes Roblox par défaut » visible à hauteur du joueur, pas simplement augmenter les objets de skyline éloignés.

- Auditer les *vraies surfaces de jeu* et supports physiques : 5 sols, 4 chemins d'évasion par monde, plateformes de saut, passerelles, bords, faces latérales, supports, rampes, entrées et intersections. Pour chaque zone, vérifier que des MeshParts/SurfaceAppearance 2K approuvés couvrent réellement la forme qui les justifie ; ne pas masquer une collision par une coque trop courte. Conserver le repli natif si streaming ou catastrophes.
- Consolider chaque monde autour d'un langage reconnaissable : Classic architecture signal/réseau, Towers verticalité et refroidissement, Crossroads ferroviaire/intersections, Orbital modules et stations scientifiques, Harbor vrais quais/grues/navires/eau. Gros volumes, relief, silhouettes, couleurs de matériaux et mouvements environnementaux, jamais uniquement du néon.
- Harmoniser éclairage utilisable : visibilité du personnage et des surfaces, exposition et ombres sans écrasement, teintes météo et catastrophe ; Darkness reste réellement sombre mais ses avertissements et la navigation restent interprétables. Éviter de créer des dizaines de lumières sur mobile.
- Terminer les grands portiques et châssis proches au moyen des modèles exacts créateur approuvés ; traiter les derniers `Part/WedgePart` dominants *uniquement* si le modèle de remplacement existe et couvre son volume réel. Refuser les géométries inventées via redimensionnement massif.

**Réception :** 5 vues de comparaison avant/après par arène, 25 cadrages rapprochés et 5 panoramas ; chaque décor majeur doit être détaillé de près, aucun avertissement caché ni faux accès physique. Qualité artistique notée dans `VISUAL_QA_SCORECARD.md` **avec preuves**, pas une note inventée de 9/10.

## Lot 2 — compréhension immédiate et activité réelle des joueurs (P1)

**But :** l'objectif « survivre jusqu'à zéro » doit être compris sans lire une notice ni demander quoi faire.

- L'entrée affiche une seule action claire selon la phase : `ENTRE / VOTE / PRÉPARE-TOI / SURVIS X s / RÉSULTAT / REJOUE`. Un guidage de déplacement/jump/dash court et effaçable ; supprimer l'empilement d'instructions concurrentes. Vérifier FR/EN et écran Android étroit.
- Avant le premier danger, guider vers **une vraie** entrée de parcours visible. Marquer direction, destination et hauteur/sécurité sans indiquer un chemin qui se ferme ou qui s'effondre. Les objectifs bonus ne doivent jamais masquer l'instruction de survie.
- En cours de manche, les éléments de l'environnement doivent offrir des décisions utiles : couverture, hauteur, raccourci physique accessible, relais coopératif, collectibles serveur valides. Intégrer les systèmes déjà présents (`TeamDashRelay`, `ArenaMechanics`, `RoundCollectibles`, `SkybridgeShutters`), sans ajouter des boutons fictifs ni une nouvelle monnaie.
- À la victoire et à l'élimination, montrer immédiatement un résultat personnel compréhensible (survie, cause serveur, mini-récompense réelle, objectif de revanche), transition du résultat au prochain vote sans écran mort.

**Réception :** sur un test naïf, la personne doit pouvoir expliquer le but et faire sa première action pertinente en **≤10 secondes après contrôle du personnage** (cible, à mesurer) ; aucune commande de gameplay inactive ou trompeuse, feedback serveur exact, aucune manche terminée sans résultat accessible.

## Lot 3 — IA réellement crédible à huit participants (P1)

**But :** des bots qui agissent comme des adversaires/alliés compétents, sans être présentés comme des joueurs humains dans les données.

- Relever sur chaque monde des enregistrements de bots contre mur, au bord des plateformes, lors des sauts, portes Towers, catastrophe, retour au lobby, vote et suivi d'un humain. Repérer les zigzags, boucles répétées, arrêts longs et cibles inaccessibles.
- Améliorer en une seule passe l'enchaînement `perception physique → choix d'objectif → déplacement humainement plausible → récupération → choix suivant` dans `AISurvivorService`/`AISurvivorRules`. Respecter raycasts/physique serveur, limites de pathfinding, quotas décisions et équité; pas de téléportation ni triche.
- Le service continue à viser huit combattants **au début** d'une manche avec des rigs bot réellement créés, pas huit survivants permanents. Retries bornés lors des échecs de spawn, aucune réapparition des éliminés, humains prioritaires à la manche suivante.
- Rendre lisibles les réactions des personnages : anticipation d'un saut, regard vers le danger, accélération et décélération, esquive crédible et retour à la locomotion. Connecter l'animation réelle au mouvement, pas aux illustrations 2D.

**Réception (cibles de tests) :** zéro bot qui reste collé au même obstacle plus de 3 secondes sans stratégie de récupération, aucun passage dans une plateforme supprimée, aucune sortie illégitime de l'arène, huit participants READY lorsque les avatars sont réellement disponibles ; performance mesurée avec sept rigs R15 Android.

## Lot 4 — catastrophes, caméra, animations et son premium (P1/P2)

**But :** onze catastrophes distinctes, lisibles et spectaculaires, à coût adapté.

- Auditer une fois les 11 scripts `src/server/Disasters/` : anticipation → lancement → impact → conséquences → retour au normal. Rendre les signatures visuelles immédiatement reconnaissables (Meteors/Bombs, Tornado, Lava, Shrink, Freeze, Darkness etc.) sans masquer le danger lui-même. En Double Chaos, priorité à la lisibilité de la première zone dangereuse.
- Remplacer les effets encore plats par de véritables animations courtes en monde 3D : vent et particules contextualisés, machines/structures qui réagissent, impacts de caméra réglables, destruction cohérente et suppression propre des objets. Aucune VFX persistante invisible qui dégrade Android.
- Audio d'identité par arène et catastrophe : ambiances, musique de lobby/manche/résultat, impacts spatialisés cohérents, ducking et volumes qui respectent les réglages; assets autorisés uniquement. Ajouter/ajuster les animations locomotion/atterrissage/gestuelles réellement reproduites par humains et IA.
- Accessibilité : `ReduceMotion`, alternatives aux signaux uniquement colorés, lisibilité sans son, volume/visuel non agressif, priorité sécurité des signaux d'impact.

**Réception :** enregistrement réel des 11 dangers et de plusieurs combinaisons Double Chaos en Low/High ; zéro faux avertissement, effets nettoyés après 10 manches successives, même règle d'impact pour humains et IA.

## Lot 5 — performances, continuité et sécurité production (P0/P1, transversal et passage obligatoire)

- Préserver les réconciliateurs `scenery-lod.client.lua`, `VisualBudgetRules`, `PerformancePulseRules` et les compteurs de résidence : aucune nouvelle boucle par objet, aucun import client non autorisé, pas de dépassement des budgets de Parts/Lights/Effects/PBR et aucune collision introduite par la cosmétique.
- Mesurer Android modeste et moyen ainsi que PC sur les cinq cartes. **Cibles de livraison, non mesures actuelles :** ≥30 FPS soutenus sur Android modeste avec adaptation Low, p95 frame time ≤33,3 ms dans une scène de référence maîtrisée si le matériel le permet; ≥60 FPS visés sur appareils capables; pas de dégradation persistante après 30 minutes. Si une cible n'est pas réalisable sur un appareil, noter matériel/graphismes et fixer une limite documentée, ne jamais falsifier les résultats.
- Tester StreamingEnabled, sources importées tardivement, perte réseau, retour Android, changement de qualité Low↔High, mort/respawn, cinq cartes successives, huit rigs et 11 catastrophes. Pas de fuite de lumières, copies de modèles fantômes, effet resté actif, compteurs gonflés ou modèle natif invisible.
- Vérifier sécurité des Remotes, validation serveur, quotas anti-abus, transactions/sauvegardes et protections de DataStore. Les changements visuels n'accordent jamais des avantages physiques ou récompenses côté client.

**Réception :** matrice de mesures reproductible avec captures, traces, appareil/tier, comparaison avec le public précédent et liste de défauts bloquants vide. Les tests Roblox Cloud sont nécessaires mais insuffisants.

## Lot 6 — satisfaction de fin de manche, progression et fidélisation (P2, après stabilité)

- Réutiliser et rendre utiles les systèmes existants `AchievementService`, `DailyQuests`, `DailyRewards`, `RoundMedals`, `Mastery`, `SessionStreak` plutôt que créer une économie doublon.
- Boucle claire : défi quotidien et objectif de maîtrise liés à une action réellement réalisable → action prouvée par le serveur → récompense cosmétique équitable → feedback et prochain objectif. Pas de pay-to-win ni de récompense de bots inventée.
- Étudier le funnel existant `GameAnalytics` : `Joined → FirstVote → FirstRoundStarted → FirstRoundCompleted → FirstSurvival`, délai première manche, départs avant 60/180 s, début spectateur vs lobby, session, retours D1/D7 lorsque l'échantillon est suffisant. Ne pas présenter les données des bots comme des joueurs.
- Si la rétention est faible à la fin d'une manche, réparer d'abord la revanche et l'enchaînement résultat→vote plutôt qu'ajouter des monnaies.

**Réception :** tous les succès/quêtes/récompenses sont réellement enregistrés, persistants et récupérés après reconnexion; les objectifs ne suggèrent pas d'achat obligatoire; l'analyse dispose de vrais événements humains suffisants avant décision produit.

## Lot 7 — certification de la prochaine grande version publique (P0 final)

- **Une seule candidate finale** : blocage des fonctionnalités, audit des dépendances, provenance des assets, cohérence du README, sauvegarde de la version publique actuelle et plan de retour arrière Roblox.
- À ce jalon seulement : `Build Validation` et toutes les **sept suites Open Cloud** sur le **même SHA**, contrôles release, et Roblox Studio E2E authentifié avec son manifeste si disponible. Corriger toutes les régressions réelles; classer séparément les erreurs d'infrastructure 429/timeouts.
- Valider réellement Android + PC, persistence/rejoin, 1/2/4/8 humains, spawns, 11 catastrophes, sécurité/fairness, 30 minutes, accessibilité, page/miniature/icône, puis seulement déclencher la publication gardée vers l'universe `10771083668` / place `95351659174730`.
- Après publication : vérifier le SHA/version Roblox renvoyé, ouvrir une nouvelle session sur un serveur récent, faire un court smoke test et mesurer l'analytics des premières sessions. **Le code sur GitHub seul n'est pas la publication**. Éviter toute publication publique automatique intermédiaire.

## Ordre de lancement sans dispersion

1. **Maintenant : Lot 0** (preuve Android + classement des vraies anomalies de la version publique).
2. **Puis un seul chantier principal : Lot 1** (finitions 3D du premier plan + direction artistique + lumière), jusqu'à des preuves visuelles suffisantes.
3. **Ensuite Lot 2 et Lot 3**, parce que l'accessibilité du jeu et des bots crédibles décident si le beau décor est effectivement joué.
4. **Puis Lot 4**, audio/animations/catastrophes ; garder **Lot 5** en garde-fou à chaque lot.
5. **Enfin Lot 6, puis Lot 7** quand l'expérience atteint la qualité et la stabilité attendues.

**Contraintes de preuve :** toute amélioration source porte un lien vers le fichier et le commit réellement vérifiés. Tout résultat de CI porte le nom du workflow, le statut et le SHA exact. Toute évaluation artistique ou Android porte un clip/capture authentique, la date, le monde, l'appareil et le niveau de qualité. Ne jamais déclarer « 100 % premium AAA » ni un score sans ces traces.
