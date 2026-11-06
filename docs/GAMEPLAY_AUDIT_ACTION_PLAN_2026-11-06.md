# Chaos Survival — audit gameplay et plan d'action produit (6 novembre 2026)

**Référence réellement inspectée :** `main` au commit `f4d29949e1c24b81823bc3132893e0d408bd179c`.
**Publication vérifiée :** workflow Build Validation, Roblox Open Cloud Engine Tests et publisher public réussis sur **ce même commit** (publisher : https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42270723912).
**Expérience publique :** https://www.roblox.com/games/95351659174730/Chaos-Survival (place `95351659174730`, universe `10771083668`).

Ce document **priorise le GAMEPLAY**, pas la quantité de modèles et d'effets. Il complète sans remplacer `docs/PREMIUM_V3_PRODUCT_ROADMAP_2026-11-05.md`, `docs/ROADMAP_POST_PUBLIC_2026-11-05.md` et l'audit de performance du 6 novembre.
Il s'agit d'un audit **du code et des documents de QA**, non d'une nouvelle partie jouée sur Android. Les tests moteurs réussis valident des contrats automatisés, pas le plaisir, l'équité ressentie ou la rétention D1/D7. Aucun FPS, usage de mécanisme, win rate ou temps joueur réel ne peut être déduit des constantes.

## 1. Verdict gameplay

### Points solides, réellement implémentés
1. **Boucle de jeu complète** : lobby → vote humain prioritaire → READY → survie → élimination/résultat → récompenses → lobby → nouvelle manche. `src/server/init.server.lua`, `RoundResultState.lua`, `RoundSettlement.lua`.
2. **Base de compétition consistante** : cinq variantes d'arènes `Classic/Towers/Crossroads/Orbital/Harbor`, onze catastrophes, compatibilité pour les fusions, danger physique côté serveur, cinq modèles de parcours avec mécanismes propres. `ArenaVariants.lua`, `ArenaMechanics.lua`, `DisasterBalance.lua`.
3. **Vrai déplacement exploitable** : saut, assistances, routes verticales, plateformes et accélérateurs, avertissements de dangers, mécaniques spécifiques (grille, skyrails, aiguillages, hélix, cargos). Les plateformes physiques restent serveur ; les meshes ne doivent pas devenir des faux chemins.
4. **Activités annexes déjà existantes** : shards, near misses, flow/momentum, défis de manche, maîtrise de parcours, médailles, récompenses quotidiennes/hebdomadaires et cosmétiques déverrouillables par pièces. `RoundChallenge.lua`, `RoundCollectibles.lua`, `RoundMedals.lua`, `PlayerData.lua`, `CosmeticService.lua`.
5. **Tutoriel et résultat présents** : trois premières manches protégées, objectif `SURVIVE UNTIL 0`, interface de résultat personnelle, explication de certaines éliminations, gain XP/pièces et relance automatique. `FirstTimeExperience.lua`, `round-focus.client.lua`, `ResultPresentation.lua`.
6. **Télémétrie disponible** : événements `TimeToFirstRoundSeconds`, `TimeToFirstCompletionSeconds`, `SessionExitStage`, `RoundCompleted`, `ArenaTimeAliveSeconds`, `ArenaBotMetrics`. `GameAnalytics.lua`.

### Déficits à corriger par ordre de priorité
| Priorité | Constat sourcé | Effet potentiel pour le joueur | Preuve attendue |
|---|---|---|---|
| **P0 — résultat** | `RoundResultState.snapshot` n'autorise `soleSurvivorAISlot` que pour les slots **1 à 3** (`RoundResultState.lua`), alors que `AISurvivorRules.MaxBots = 7` et `AISurvivorService.soleAliveRoundSlot()` peut renvoyer un slot 4–7. | Un bot gagnant des slots 4–7 peut être privé du titre/spotlight de champion, résultat incohérent. **Défaut logique confirmé dans le code**. | Test moteur des sept slots + résultat après unique bot survivant, puis affichage authentique. |
| **P0 — compréhension** | Les premières manches possèdent une instruction et un HUD, mais le parcours tactique (quelle route prendre, pourquoi monter, comment esquiver) se répartit entre plusieurs avertissements, guides et mécaniques. | Joueur qui survit sans apprendre, ou ne comprend pas ses options malgré les écrans. **Risque UX ; pas un bug prouvé sans test naïf**. | Un novice explique l'objectif et exécute une action de survie pertinente ≤10 s après contrôle du personnage. |
| **P0 — bots** | Huit participants ciblés, dont jusqu'à sept bots ; boucle du cerveau commune à **0,42 s** pour sept, avec `ReactionSeconds` de profil d'environ 0,17–0,20 s à intégrer au cycle. | Réaction tardive, zigzag ou immobilité apparente sur alertes brèves, en particulier contre les obstacles. **Risque de conception, pas une fréquence de blocage mesurée**. | Enregistrements 5 cartes/11 dangers, temps jusqu'à action d'évitement, part des bots bloqués >3 s, trajectoires physiques. |
| **P1 — manche après mort** | Si aucun humain ne reste vivant, `runDisasterSet` interrompt la manche publique même avec des bots survivants ; affichage `WATCH THE SURVIVORS` seulement ~2,25 s, puis résultat. | Promesse de spectateur courte et compétition des bots non résolue. **Comportement confirmé ; intérêt produit à arbitrer**. | Après élimination, spectateur voit une action utile / un résultat honnête et accède rapidement à la revanche. |
| **P1 — rythme** | `Config` : 45 s multi, 30 s solo ; intermission **8 s** multi / **4 s** solo (le vote de 6/3 s est **inclus** dans cette période), READY 4 s, résultat 6/5 s. Premier arrivant nouveau : intermission au moins 12 s et vote ses 8 dernières secondes. | Grandes cartes 320×320 peu exploitées dans une manche courte ; trop d'attente perceptible en cas de jonction tardive, ou risque inverse de manches trop longues si on allonge globalement. **Hypothèse à tester**. | Temps de première action, pourcentage d'utilisation des routes et taux de re-participation ; A/B sur cohortes réelles si volume suffisant. |
| **P1 — choix tactiques** | Nombreux mécanismes sont implémentés, mais rien dans l'audit du code ne prouve que le joueur doit arbitrer entre couvert, hauteur, secours, raccourci et butin dans chaque variante. | Répétition d'esquive/saut malgré beaucoup d'effets et de contenus. **Problème de design à vérifier en jeu**. | ≥2 décisions physiques réellement utilisables par carte et par type de menace principal, observées en partie. |
| **P2 — rejouabilité** | Shards, défis, maîtrise, économies et quêtes sont présents ; le défi visible évolue selon un numéro global de manche et des conditions de débutant. | Le joueur peut gagner des monnaies sans percevoir de nouveauté jouable ou de maîtrise acquise ; objectifs de collection secondaires par rapport à la survie. | Le joueur cite une nouvelle stratégie/route à tenter à la manche suivante ; suivi de 2e/3e manche, D1/D7 avec cohortes suffisantes. |
| **P2 — social** | Votes humains prioritaires et réactions/invitations en lobby ou résultat ; les interactions environnementales existent, mais le système social n'assure pas à lui seul coopération/rivalité en pleine manche. | Huit silhouettes ne donnent pas nécessairement huit sources de tension sociale. | Un mécanisme d'entraide ou de concurrence réellement déclenché, visible et équitable pendant chaque manche. |

### Éléments quantifiés du code, non assimilables à des métriques produit
- **11 catastrophes** : `Bombs`, `Darkness`, `DisappearingPlatforms`, `Freeze`, `JumpShock`, `LowGravity`, `Meteors`, `RisingLava`, `ShrinkingArena`, `SpeedSurge`, `Tornado`.
- **Durée nominale complète sans attente de chargement** : multijoueur **8+4+45+6 = 63 s** ; solo **4+4+30+5 = 43 s**. Le vote n'ajoute pas 6/3 secondes : il est intégré à l'intermission. Ces durées varient en pratique (déconnexions, fin anticipée, rebuild, attente de disponibilité).
- **Rookie** : trois manches guidées ; la première évite les objectifs secondaires avancés. Les catastrophes doubles et dynamiques ont des garde-fous.
- **Bot count** : cible huit présents **au début** d'une manche ; après élimination, ce compte peut diminuer. Aucun script serveur ne transforme le nombre de places humaines maximal du Creator Dashboard en valeur garantie.

## 2. Nouveau cap produit

**Dans les dix premières secondes de contrôle :** le joueur sait qu'il doit rester vivant, voit le prochain danger et identifie un chemin physique utile.

**Pendant une manche :** toutes les 5 à 10 secondes, quelque chose l'oblige à prendre une décision lisible : monter, se couvrir, contourner, activer un mécanisme, secourir un autre joueur, tenter un raccourci risqué ou rester sur une option prudente. Ce rythme est une **cible de conception** à observer, pas une cadence artificielle de nouveaux VFX.

**À la fin :** la victoire, le sort des bots, la cause d'élimination et la récompense doivent être cohérents. Le résultat donne une envie **concrète** de retenter une stratégie différente. L'objectif n'est pas d'ajouter dix monnaies ou de multiplier les HUD.

## 3. Plan d'exécution ordonné — un lot terminé à la fois

### G0 — vérité des résultats et règles compétitives (correctif prioritaire)

**Fichiers :** `src/server/RoundResultState.lua`, `src/server/AISurvivorRules.lua`, `src/client/result-survivors.client.lua`, `src/server/init.server.lua`, suite moteur existante des résultats.

1. Supprimer l'hypothèse périmée **slots IA 1–3**. Valider le slot exclusivement depuis le roster autoritaire des IA vivantes et les limites du service existant, sans fabriquer un champion pour une IA morte, inexistante ou pour un joueur isolé sans adversaire.
2. Vérifier les scénarios : 1 humain+7 bots, 2 humains+6 bots, aucun survivant, humain unique survivant, bot unique aux slots 1, 3, 4, 7, joueurs déconnectés, `RoundFeedback` reçu en retard. `RoundState`, carte résultat et spotlights doivent raconter la même fin.
3. Préserver les transactions de récompense et l'arrêt anticipé pour le moment ; ne pas mélanger changement du résultat avec un redesign de la durée de spectateur.

**Terminé si :** 0 faux champion et 0 champion absent dans tous les cas déterministes ci-dessus ; résultat visible après chaque manche et écran Android sans identité contradictoire. **Aucun changement d'économie.**

### G1 — parcours compréhensibles, décisions de survie et commandes (priorité expérience)

**Fichiers :** `src/shared/FirstTimeExperience.lua`, `src/client/round-focus.client.lua`, `src/client/ArenaGuide.client.lua`, `src/client/hazard-route-readability.client.lua`, `src/server/ArenaMechanics.lua`, `src/shared/JumpRouteCueRules.lua`.

1. Rejouer **le premier accès** en Android avec écran étroit. Une seule consigne centrale, sans masquer le danger : « Survis jusqu'à 0 », puis **prochaine action physique** contextualisée (se déplacer, sauter, monter, éviter). La consigne doit pointer vers une route serveur vraiment praticable, non un décor.
2. Conserver les trois manches guidées ; débloquer graduellement lecture des menaces, accélérateurs puis défis annexes. Ne pas remplacer les explications par des panneaux plus longs.
3. Revoir danger par danger la chaîne : **signal anticipé → lieu d'impact identifiable → sortie possible → conséquence visible → cause d'élimination comprise**. Priorités : `Meteors`, `Bombs`, `RisingLava`, `DisappearingPlatforms`, `Darkness` et fusions.
4. Évaluer la difficulté sur une caméra mobile réaliste, avec humain au sol, sur route haute et en retour de saut ; préserver l'équité des vitesses, du timing et des zones de dégâts.

**Terminé si :** un novice réalise sa première action utile dans les 10 s suivant le contrôle, aucune fausse route suggérée sur les cinq arènes, avertissements lisibles sans son, saut/dash tactile fiable, cause de mort compréhensible.

### G2 — bots rivaux crédibles et utiles (priorité engagement à huit)

**Fichiers :** `src/server/AISurvivorService.lua`, `src/server/AISurvivorRules.lua`, `src/server/AISurvivorNetworkOwnership.lua`, logique de navigation physique existante, métriques `GameAnalytics.arenaBotMetrics`.

1. Établir sur 1+7 bots une grille de référence : marche libre, mur, angle, plateforme haute, saut, passerelle fermée, lave montante, collision entre deux bots, avertissement simultané, changement de carte.
2. Instrumenter les **événements de progression réelle** de l'IA (temps sans mouvement utile, récupération réussie, destination invalide, intervention pour menace urgente), sans nouveau scanner global ni télémétrie à haute cardinalité.
3. Séparer la décision **urgente** (danger imminent, support qui disparaît) du choix de flânerie/objectif non urgent, sans multiplier le coût serveur par sept. Mesurer avant de modifier les intervalles du cerveau.
4. Améliorer suivi des vrais itinéraires, virages, reprise après blocage, espacement mutuel et animation de la décision. Aucun téléport, noclip, boost injuste ou imitation d'un compte Roblox réel.

**Terminé si :** aucun bot immobile contre un obstacle >3 s **sans récupération engagée**, aucune route sautée vers un support disparu, réactions aux avertissements observées, cadence stable avec sept bots sur Android et sur le serveur.

### G3 — interactivité qui change l'issue d'une manche (priorité valeur ludique)

**Réutiliser AVANT d'ajouter :** `TeamDashRelay`, `ArenaMechanics`, `SkybridgeShutters`, `ArenaSkyShieldNetwork`, `RoundCollectibles`, `ArenaDistrictTransit`, mécanismes de grille/flux/harbor.

1. Donner à chaque monde **une décision signature** utile au succès, avec interaction serveur visible : **Classic** circuit de zones sûres ; **Towers** relais de montée/portes ; **Crossroads** aiguillage dangereux mais avantageux ; **Orbital** contrôle d'hélix/anneau ; **Harbor** transfert cargo/couvert mobile.
2. Pour chaque signature, proposer **une alternative** sans activation obligatoire : chemin lent sûr vs action rapide risquée. Un nouveau joueur peut toujours survivre sans connaître tout le système.
3. Activer une conséquence partagée : ouverture temporaire d'une route, couvert, bouton à maintien ou transfert coopératif. Le joueur et les bots doivent recevoir une information d'état cohérente ; l'action ne doit jamais transformer un élément décoratif en collision trompeuse.
4. Observer l'utilisation effective de ces mécanismes ; supprimer ou simplifier ceux qui compliquent la lecture et ne changent aucune décision.

**Terminé si :** chaque arène présente au moins deux options tactiques franchissables et une réaction du monde vérifiable, humain/IA soumis aux mêmes règles, aucune zone d'apparition piégée et aucun mécanisme « juste cosmétique ».

### G4 — rythme, élimination, spectateur, revanche

**Fichiers :** `src/shared/Config.lua`, `src/server/SoloRules.lua`, `src/server/init.server.lua`, `src/client/result-survivors.client.lua`, `src/shared/ResultPresentation.lua`, UI spectateur et lobby déjà présentes.

1. Conserver 30/45 s comme **contrôle** ; mesurer si les joueurs atteignent une route et prennent au moins deux décisions intéressantes avant la fin. Ne pas allonger toutes les manches sur intuition.
2. Revoir l'élimination : actuellement le serveur affiche « WATCH THE SURVIVORS » ~2,25 s si tous les humains sont morts et qu'il reste des bots, avant d'arrêter la manche. Choisir une UX honnête : soit **fin rapide** sans promesse de longue observation, soit **courte fenêtre spectateur réelle, bornée**, avec contrôle de la charge serveur et bouton de préparation de la prochaine manche.
3. Réduire le temps d'inactivité *ressenti* : exercice libre dans le lobby, caméra spectateur, progression personnelle visible, vote immédiatement disponible à l'intermission, transition sans écran mort.
4. Rejouabilité immédiate : cause de défaite + **une action de revanche contextuelle** (ex. route haute pour lave, changement de voie pour sweep), sans popup commerciale et sans fausse récompense.

**Terminé si :** pas de faux bouton/texte « regarder » ni résultat manquant, aucune attente totalement passive longue, hausse mesurée de la participation à la 2e manche sur cohorte comparable (objectif relatif fixé après baseline).

### G5 — rejouabilité et progression perceptible, sans gonfler l'économie

**Fichiers :** `RoundChallenge.lua`, `RoundMedals.lua`, `Mastery.lua`, `DailyQuests.lua`, `WeeklyChallenges.lua`, `CosmeticService.lua`, UI récap.

1. Rendre perceptible la **maîtrise gagnée** : meilleur enchaînement, nouvelle route réussie, score de survie lié au niveau de risque ; afficher un seul événement remarquable sur le résultat, puis la récompense serveur authentique.
2. Donner aux défis de manche un rôle de prise de risque facultative ; éviter qu'une quête de collecte dirige les débutants dans une menace mal expliquée. Contrôler l'atteignabilité de chaque défi selon arène/catastrophe.
3. Proposer des objectifs de maîtrise par arène, avec cosmétiques existants comme récompenses — pas de vitesse ou saut payant.
4. Examiner la distribution des situations de jeu réellement vécues : surreprésentation d'un danger, mêmes trajets, mécaniques jamais activées, WinRate par catastrophe et par ancienneté.

**Terminé si :** objectifs secondaires réellement réalisables, récompenses sauvegardées et compréhensibles, pas de pay-to-win ; la progression explique ce que le joueur sait mieux faire, pas seulement une monnaie accumulée.

## 4. Contrat QA et instrumentation à chaque livraison importante

**Priorité absolue à la session humaine réelle**, non à une simulation de joueur ou à un score de code.

| Observation | Comment et contexte | Cible/condition de décision |
|---|---|---|
| Première compréhension | Joueur nouveau, Android, lobby → première manche | But expliqué + action utile ≤10 s après contrôle ; mesurer sans influencer le joueur |
| Time-to-first-round | Événement existant `TimeToFirstRoundSeconds` par phase d'arrivée | Baseline puis baisse des départs pré-manche ; ne pas confondre attente et problème de chargement |
| Lisibilité du danger | 11 catastrophes ; sol, hauteur, caméra mobile ; son coupé | 0 avertissement visuellement trompeur, sortie physique possible lorsque le design promet une esquive |
| Bots | 1 humain+7 bots et 4 humains+4 bots, cinq mondes | Aucun blocage non traité >3 s, réaction mesurée, vrais déplacements R15 |
| Score/résultat | Dernier humain, dernier bot chacun des 7 slots, zéro survivant, arrivée tardive | Résultat, champion et réception de récompenses serveur cohérents |
| Interaction | Actions observées sur 5 mondes | ≥2 choix utiles par monde ; au moins une action d'environnement modifie une route ou le risque |
| Retours | `RoundCompleted`, `SessionExitStage`, `SessionDurationSeconds`, sessions à 2/3/5 manches | Comparer par période, appareil et expérience ; ne pas annoncer une amélioration sans données |
| Performance | Android Low/Medium/High, 7 bots, 20–30 min | Reprendre les SLO documentés dans `PERFORMANCE_AUDIT_EVOLUTION_PLAN_2026-11-06.md`; zéro régression de stabilité |

**Tests :** réserver la suite Build Validation + Roblox Open Cloud Engine aux jalons de sortie de lots, avec les tests déterministes nécessaires au changement. Ne pas ajouter de suites unitaires à chaque micro-édition. Avant chaque publication, vérifier **le même SHA sur les deux suites et sur le publisher**, puis test visuel Android. Conserver le public actuel si un gate échoue.

**Analyse honnête :** les événements Roblox Analytics et les compteurs locaux peuvent servir de baseline, mais aucune rétention D1/D7, comportement réel des nouveaux joueurs ou FPS n'a été mesuré pendant cet audit. Ne pas interpréter `8/8` comme huit comptes humains.

## 5. Décision de priorité immédiate

**Commencer par G0** : corriger le défaut de champion IA des slots 4–7 et verrouiller l'intégrité résultat/roster/spotlight ; ensuite livrer **G1 complet**, centré sur une première manche immédiatement lisible et une route tactique utile dans chacune des cinq arènes. Une fois le gameplay compréhensible, faire **G2**, puisque la crédibilité des sept bots conditionne presque chaque session solo.

Les autres lots sont volontairement placés après la correction de la boucle centrale : **pas de nouveaux shaders, monnaies, arènes ou interfaces secondaires avant qu'une première manche soit agréable et les bots fiables**.
