# Chaos Survival — plan directeur premium (9 novembre 2026)

**Statut : plan de production révisé, fondé sur le dépôt réel.**  
**Dépôt :** `dbrckk/chaos-survival-roblox` ; **référence de code :** `main@0d334571560dac92d55190b02f19c1221b28959b`.  
**Expérience publique cible :** [Chaos Survival](https://www.roblox.com/games/95351659174730/Chaos-Survival), universe `10771083668`, place `95351659174730`.  
**Portée :** jeu fonctionnel, fiable, lisible, rejouable et visuellement premium sur Android/PC. Les critères indiqués sont des **objectifs d'acceptation**, pas des métriques déjà observées.

## A. Vérité opérationnelle au point de départ

- Code : les PR [#702](https://github.com/dbrckk/chaos-survival-roblox/pull/702) (IA/dangers), [#704](https://github.com/dbrckk/chaos-survival-roblox/pull/704) (finale et READY) et [#705](https://github.com/dbrckk/chaos-survival-roblox/pull/705) (contrat de quarantaine) sont fusionnées. La PR #703 a été supplantée par #704.
- Architecture observée : 5 variantes (`Classic`, `Towers`, `Crossroads`, `Orbital`, `Harbor`), 11 catastrophes `src/server/Disasters/`, cible 8 compétiteurs au début (humains prioritaires, jusqu'à 7 IA), serveur autoritaire pour la physique, gagnants et récompenses.
- Boucle et durée configurées : lobby/vote → READY → survie → résultat ; 30 s en solo, 45 s en multi (hors transitions). La finale entre bots restant vivants est limitée et ne prolonge pas le temps physique des dangers.
- Systèmes existants à valoriser : `ArenaMechanics`, `GridCircuitService`, `SkybridgeShutters`, `CrossroadsFluxRelay`, `OrbitalHelix`, `HarborCargoSweep`, `TeamDashRelay`, `ArenaSkyShieldNetwork`, `RoundChallenge`, `Mastery`, quêtes, cosmétiques, `GameAnalytics`.
- LOD et qualité Android existent : `scenery-lod.client.lua`, `visual-budget-pressure.client.lua`, `VisualBudgetRules.lua`, `PerformancePulseRules.lua`, avec reprise/fallbacks natifs. L'existence de ces budgets ne prouve **aucun FPS observé**.
- **Livraison bloquée à cette date :** [Build Validation #42603750446](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42603750446) a réussi sur l'ancien SHA `87f6cc...`, mais le test moteur [#42605796466](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42605796466) a échoué sur une ancienne assertion de récupération IA. La PR #705 a corrigé cette attente **sans changer la logique de déplacement** ; elle n'est pas encore validée par les workflows sur son nouveau SHA `0d334571...`. La tentative de publication [#42608816130](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42608816130) a refusé l'envoi faute de deux checks verts sur le SHA exact. La dernière publication publique réussie constatée est [#42358436832](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42358436832), sur une version plus ancienne, le 7 novembre.
- Aucun test utilisateur naïf, aucun profilage MicroProfiler, aucune capture Android comparative, aucun taux de rétention ou mesure de victoire ne sont disponibles pour **cette version**. Ne pas confondre audit source, test Open Cloud et validation sur appareil.

## B. Décision produit

**Promesse en une phrase :** « Survis à une succession de catastrophes imprévisibles en exploitant cinq arènes physiques uniques, face à sept adversaires crédibles lorsque tu joues seul. »

La priorité n'est plus d'accumuler de nouveaux mini-systèmes. Il faut **finir les systèmes existants** dans un ordre qui améliore un ressenti visible et mesurable :

1. La version que l'on teste est bien celle publiée, sans erreur moteur bloquante.
2. En moins de 10 secondes, le nouveau joueur comprend le but et tente une décision utile.
3. L'IA est un rival lisible qui parcourt réellement le monde et réagit aux catastrophes, sans triche physique.
4. Chaque arène impose une vraie décision différente et répond aux actions.
5. Les surfaces proches, la lumière, les catastrophes et les animations atteignent une direction artistique cohérente, sans sacrifier la lisibilité ni les FPS.
6. Le résultat, la revanche et la progression donnent envie de jouer plusieurs manches.

**Principes de fabrication :** lot vertical complet > dizaines de micro-modifications ; fiabilité > fonctionnement réel > sécurité > architecture > performance > interface > contenu secondaire. Sources 3D authentiques/créateur approuvées, cohérence entre collision et habillage, coût nul ou minimal, compatibilité Android. Ne pas modifier simultanément IA, économie et rendu sur le même lot.

## C. Séquence de livraison (un lot terminé avant le suivant)

| Lot | Priorité | Résultat perceptible | Risque/coût | Dépendance |
| --- | --- | --- | --- | --- |
| **P0 — publication exacte et référence publique** | Bloquant | Le joueur accède réellement au build corrigé | Faible coût, risque de release élevé | Immédiat |
| **P1 — première manche guidée sans surcharge** | Très haute | Le joueur sait quoi faire dès l'arrivée | Moyen | P0, observation Android |
| **P2 — bots convaincants à 8** | Très haute | Les rivaux courent, contournent, esquivent, se reprennent | Élevé | P1 pour lire leurs actions |
| **P3 — cinq mécaniques signature utiles** | Haute | Chaque arène propose deux décisions tactiques réelles | Élevé | P2 pour cohabitation humain/IA |
| **P4 — refonte visuelle frontale premium** | Haute | La zone jouée, pas seulement le fond, semble travaillée | Élevé | P3, collisions figées |
| **P5 — catastrophe, animation, son et récompense de fin** | Haute | Chaque danger a une identité, chaque défaite est compréhensible | Moyen/élevé | P1 + P3 + P4 |
| **P6 — optimisation Android/PC et résilience** | Passage obligatoire | Qualité stable même à huit et après 30 min | Élevé | P2–P5, travail transversal prudent |
| **P7 — rejouabilité et rétention mesurée** | Secondaire | Une raison claire de retenter, sans économie parasite | Moyen | Version stable et mesurée |

### P0 — clôturer la publication réellement bloquée

**Pourquoi d'abord :** une version « fonctionnelle sur GitHub » qui n'est pas accessible aux joueurs ne satisfait pas l'objectif produit.

**Travaux :**
- Garder `main@0d334571...` intact pendant le jalon de vérification. Ne pas fusionner un nouveau lot de code avant d'avoir obtenu les résultats de ce SHA ; la présente roadmap reste sur branche documentaire pour préserver la preuve.
- Depuis `main`, lancer **une fois à ce jalon**, dans l'ordre : [Build Validation](https://github.com/dbrckk/chaos-survival-roblox/actions/workflows/ci.yml) puis [Roblox Open Cloud Engine Tests](https://github.com/dbrckk/chaos-survival-roblox/actions/workflows/roblox-cloud-test.yml). En cas d'échec, isoler **la ligne de log et la cause réelle**, corriger sur PR dédiée, ne jamais affaiblir le contrôle ou fabriquer un résultat.
- Quand ces deux workflows ont une conclusion `success` sur le **même HEAD `main`**, effectuer la [publication du jeu public existant](https://github.com/dbrckk/chaos-survival-roblox/actions/workflows/publish-existing-public-playtest.yml) avec la confirmation exacte demandée par son workflow. Vérifier l'étape « Publish ONLY the existing public starting place », `versionNumber`, SHA publié, cible universe/place, artefact de preuve.
- Sur Android, ouvrir la véritable expérience et vérifier à minima : arrivée, 1 humain + 7 bots si rigs disponibles, READY, une catastrophe, élimination ou survie, résultat, nouvelle manche. La publication `success` ne remplace pas cette qualification sur appareil.
- Si l'exécution des Actions n'est pas autorisée depuis l'outil connecté, utiliser les **trois liens ci-dessus** : l'accès manuel reste gratuit. Ne jamais contourner une condition du workflow en production.

**Terminé lorsque :** Build + Cloud verts pour le SHA candidat, publish `success` sur ce SHA, numéro de version Roblox reçu, et au moins une partie réelle Android complète sans erreur S0. Sinon `P0 BLOQUÉ`, pas « publié ».

### P1 — dix premières secondes : un objectif et une action physique

**Sources à modifier :** `src/client/round-focus.client.lua`, `rookie-world-guide.client.lua`, `ArenaGuide.client.lua`, `hazard-route-readability.client.lua`, `src/shared/FirstTimeExperience.lua`, `CoreLocalization.lua`.

**Lot vertical :**
- Une consigne prioritaire à la fois : **SURVIS JUSQU'À 0** puis **évite ce danger / rejoins cette vraie issue**. Le chronomètre et l'avertissement imminent dominent les badges de défi, shards et décor.
- Parcours d'initiation court en trois manches, avec signalisation spatiale **vers un accès physiquement franchissable**, jamais vers un MeshPart décoratif, une passerelle fermée ou une plateforme menacée.
- Boutons Android : saut, dash, caméra, spectateur vérifiés sur petit écran ; états FR/EN cohérents, texte accessible sans audio, respect `ReduceMotion`.
- À la première mort : cause de défaite compréhensible et **une seule action utile** pour la prochaine manche. Ne pas empiler cinq coachmarks.

**Réception :** cible « le novice explique l'objectif et réalise une action défensive valide ≤10 s après prise de contrôle » sur observation réelle ; zéro faux chemin indiqué sur les cinq mondes, consignes lisibles en portrait et paysage, rien d'important masqué en Double Chaos.

### P2 — crédibilité des sept rivaux

**Sources :** `src/server/AISurvivorService.lua`, `AISurvivorRules.lua`, `AISurvivorNetworkOwnership.lua`, `ArenaVariants.lua`, `GameAnalytics.lua`.

**Lot vertical :**
- Consolider un pipeline par bot **perception de l'avertissement → choix d'un objectif praticable → trajectoire physique → reprise sur blocage → nouvelle intention**. Dédupliquer les consignes urgentes : un dodge n'est jamais remplacé par du tourisme ni un itinéraire périmé.
- Couvrir les situations difficiles avec les **raycasts/route cache existants** : mur, passage étroit, plate-forme mouvante, chute, porte Towers, itinéraire Harbor, hauteurs Orbital, warning double. Ne jamais « résoudre » en téléportant ni en accordant une immunité IA.
- Utiliser les compteurs serveur déjà présents (`BotStallRecoveryCount`, `BotEmergencyResumeCount`, `BotShockDodges/Hits`, etc.) pour séparer **tentative** d'**évitement réellement réussi** ; limiter la cardinalité et la fréquence.
- Les bots rejoignent la partie à READY, pas après leur élimination. Les vrais humains disposent des places en priorité. La finale n'est pas rallongée artificiellement lorsque le dernier humain meurt.
- Gestuelles et changements de direction motivés par les vraies décisions, non des animations de hasard qui masquent un blocage.

**Réception :** une manche par carte avec 1+7, puis un scénario multi ; aucun bot collé à un obstacle >3 s **sans reprise engagée**, aucun bot qui marche vers une plateforme réellement disparue, aucune victoire/évasion simulée ; pas de régression de coût serveur ni de résultats.

### P3 — cinq arènes, cinq interactions dont l'effet compte

**Sources :** `ArenaMechanics`, `GridCircuitService`, `SkybridgeShutters`, `CrossroadsFluxRelay`, `OrbitalHelix`, `HarborCargoSweep`, `TeamDashRelay`, `ArenaSkyShieldNetwork`, clients de guidage existants.

| Monde | Décision signature à consolider | Alternative équitable |
| --- | --- | --- |
| **Classic** | Contrôler le vrai Grid Circuit pour déplacer son itinéraire vers une zone plus sûre | Parcours extérieur plus lent et sans interaction |
| **Towers** | Profiter des passages et des shutters physiques à bon moment pour gagner de la hauteur | Escaliers / route basse accessibles |
| **Crossroads** | Actionner le relais de flux ou un aiguillage pour éviter une voie exposée | Contournement sans activation |
| **Orbital** | Exploiter l'hélix et la route haute pour anticiper une catastrophe | Route au sol plus prudente |
| **Harbor** | Tirer parti des sweeps/cargos et d'une couverture réelle pour traverser les quais | Long détour dégagé |

**Règle de design :** pas de nouvelle monnaie ou de dispositif fictif ; chaque action doit modifier un chemin, un couvert ou un choix de survie **constatable côté serveur**. Deux options viables par monde, même pour un débutant. Coopération facultative par `TeamDashRelay`, sans supprimer l'autonomie du solo.

**Réception :** démonstration en partie (vidéo/état serveur) de cinq interactions distinctes, mêmes règles pour IA et humains, entrée/sortie toujours possible, aucune action payante nécessaire.

### P4 — grande transformation visuelle, au premier plan

**Sources :** vrais modèles créateur approuvés et générateurs source existants ; `OriginalMeshScenery`, `PremiumRouteMeshAssets`, `PremiumLargeStructureAssets`, `PremiumPlatformSideAssets`, `scenery-lod.client.lua`, `arena-lighting.client.lua`, `ArenaFocalLightingRules`.

**Lot de production artistique, pas un empilement de primitives :**
1. Photographier/capturer en jeu **cinq zones de contact visuel par monde** : sol, entrée de parcours, premier saut, passerelle et point de décision. Identifier les formes basiques encore dominantes, trous de revêtement et différences entre collider réel et coque 3D.
2. Reprendre les **25 éléments de premier plan les plus visibles**, avec vraie géométrie 3D, matériaux cohérents, UV/PBR lorsque réellement autorisés, surfaces dangereuses bien contrastées et fallback natif si source absente. Prioriser voies praticables, bordures, piliers et portiques **avant** l'horizon.
3. Direction par monde : Classic réseaux et structure lisible ; Towers métallurgie verticale ; Crossroads transit industriel ; Orbital science/anneaux et profondeur ; Harbor quais, cargaisons, eau et grandes machines animées.
4. Rééquilibrer soleil, matériaux indirects, ombres et météo : **pas de carte illisible**, mais Darkness reste sombre avec alertes contrastées ; LOD Low honnête et fonctionnel.
5. Nettoyer les objets visuels persistants après changement de carte, destruction, streaming et variation Low↔High ; aucun cache 3D ne doit masquer une collision ou un danger réel.

**Réception :** 5 confrontations avant/après par monde (25), panoramas des cinq, aucune coque partiellement installée qui cache le sol physique, avertissements visibles, compatibilité mobile. Une note « AAA » ne peut être attribuée qu'après une revue de captures/parties.

### P5 — catastrophes et mise en scène émotionnelle

**Sources :** 11 modules `src/server/Disasters/`, `hazard-warning-visuals.client.lua`, `hazard-impact-feedback.client.lua`, `audio.client.lua`, `ResultPresentation`, `spectator.client.lua`.

- Pour chaque danger, fixer une signature reconnaissable **anticipation → impact réel → conséquence visible → nettoyage**, sans collision imaginaire.
- En Double Chaos, réduire la surcharge visuelle et hiérarchiser le signal mortel, même au niveau Low et sans son.
- Donner du mouvement à l'environnement **par les assets 3D déjà autorisés** ; audio spatial, animations de bot/terrain et caméra paramétrable, avec alternatives accessibles.
- L'élimination doit expliquer **cause réelle + résultat honnête + prochaine tentative** ; le spectateur suit effectivement les survivants encore présents, pas un mannequin.

**Réception :** 11 dangers enregistrés en vidéo, scénarios de Double Chaos, même dommage serveur humain/IA, aucune fuite VFX/audio après dix manches consécutives.

### P6 — performances et stabilité de session

**Sources :** `VisualBudgetRules`, `VisualBudgetPressureRules`, `PerformancePulseRules`, `scenery-lod.client.lua`, `visual-budget-pressure.client.lua`, `AISurvivorRules.brainCadence`, `GameAnalytics`.

- Comparer le **vrai client** Android modeste, Android moyen et PC, à 1+7, pour les cinq cartes ; capturer FPS médian, p95 frame time, frames >50 ms, mémoire et résidences Mesh/PBR. Faire aussi un scénario de 30 minutes et reprendre Roblox après arrière-plan.
- **Cibles indicatives, non mesurées :** Android moyen FPS médian ≥30, p95 ≤40 ms, <5 % des frames >50 ms ; PC ≥60 FPS, p95 ≤22 ms, <2 % des frames >50 ms. Adapter l'attendu à un appareil modeste réellement identifié, ne pas inventer 60 FPS.
- Si le profilage montre une charge élevée, étager les reconstructions visuelles coûteuses et amortir les imports ; préserver le collecteur d'inventaire existant, les quotas Low/Medium/High et les limites d'effets. **Aucune boucle par objet ni scanner Workspace supplémentaire**.
- Vérifier serveur, 7 rigs R15, Pathfinding, DataStore, changements de carte, téléportation légale de spawn seulement, remotes anti-abus et chargements tardifs.

**Réception :** tableau de mesures avec modèle appareil/tier/date/SHA, aucun crash connu, aucune fuite croissante après 30 minutes, aucun nouveau signal critique sous Android, données avant/après comparables.

### P7 — boucle de revanche et retour au jeu

**Sources :** `RoundChallenge`, `RoundMedals`, `SessionStreak`, `Mastery`, `DailyQuests`, `DailyRewards`, `PlayerData`, UI résultat.

- Rendre immédiatement visible **ce que le joueur a appris**, une récompense réellement acquise et le prochain objectif utile (route, catastrophe ou maîtrise).
- Utiliser d'abord les systèmes de quêtes/cosmétiques existants ; ne pas empiler monnaies, annonces commerciales ou pass donnant un avantage de survie.
- Mesurer `TimeToFirstRoundSeconds`, part des premières manches complétées, retour à une deuxième/troisième manche, abandon en lobby, usage réel des mécaniques et rétention D1/D7 si échantillon valable.

**Réception :** abandon des manches réduit par rapport à un vrai point de référence, progression persistante vérifiée et résultat compris sur Android ; aucune revendication de D1/D7 sans données.

## D. Cadence, qualité et décision de passage

**Une phase = un objectif complet, une PR cohérente, une réception observable.** Pendant l'itération, pas de nouveaux tests unitaires et pas de suppression des existants. Exécuter à un **jalon de publication** : lint/syntaxe, build Rojo, Roblox Open Cloud du SHA exact, puis un test manuel Android/PC lorsque nécessaire. Un échec S0/S1 arrête l'ajout de fonctionnalités.

**Grille de réception par lot (remplir avec preuve, sinon `NON MESURÉ`) :**
- [ ] Source réellement présente sur la bonne branche ; diff limité et réversible.
- [ ] Défaillance principale traitée de bout en bout sans mock/fonction fictive.
- [ ] Aucune régression évidente du gameplay serveur, des remotes, des récompenses ni des collisions.
- [ ] Scénario humain/IA, scène 5 mondes et Android couvert selon le lot.
- [ ] Mesures/captures/vidéos disponibles ; résultat attendu distingué du résultat observé.
- [ ] Gate de livraison réussi sur le commit `main` exact ; `versionNumber` Roblox obtenu avant tout « publié ».

**Ordre de travail imposé :** P0 → P1 → P2 → P3 → P4 → P5 → P6 → P7. Les corrections urgentes S0/S1 et l'observabilité performance minimale sont transversales ; elles passent avant tout nouveau visuel si elles empêchent de jouer.

## E. Prochaine action directement exécutable

**Priorité unique : achever P0.** La PR #705 a corrigé l'unique assertion de récupération incohérente observée. Faire passer Build Validation puis Roblox Open Cloud sur `0d334571...` ; si un autre test échoue, conserver le build public précédent et corriger le cas réel avant de republier. Lorsque le gate est vert, effectuer le workflow public avec numéro de version et session Android réelle. **Ensuite seulement**, ouvrir le lot P1 « première manche immédiatement comprise » ; ne pas rouvrir simultanément dix sous-projets de graphismes, de bots et d'économie.

### Documents conservés en référence

- `docs/GAMEPLAY_AUDIT_ACTION_PLAN_2026-11-06.md` et `docs/GAMEPLAY_REAUDIT_EVOLUTION_2026-11-08.md` : cas de jeu, bots, interactivité et transitions.
- `docs/PERFORMANCE_AUDIT_EVOLUTION_PLAN_2026-11-06.md` : instrumentations, budgets et objectifs de performance.
- `docs/PREMIUM_V3_PRODUCT_ROADMAP_2026-11-05.md`, `docs/URGENT_AAA_VISUAL_BACKLOG_2026-11-03.md` et `docs/VISUAL_FILE_BY_FILE_PLAN.md` : identité visuelle, liste d'assets/fallbacks et preuve de qualité.
- `docs/ROADMAP_POST_PUBLIC_2026-11-05.md` : validation commerciale et post-publication.

Cette roadmap **remplace leur ordre de priorité** sans effacer leurs constats, sources ou tâches encore pertinentes. Les sources non mesurées restent explicitement non certifiées.
