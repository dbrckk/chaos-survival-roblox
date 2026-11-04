# CHAOS SURVIVAL — plan de production premium après audit du 4 novembre 2026

**Référence GitHub inspectée :** `dbrckk/chaos-survival-roblox`, branche `main`, code de départ `8cca41789a271fef629e5aefc41f082a1fcc9f0c`. Ce document est une **feuille de route décisionnelle**, pas la preuve que les changements sont publiés. Conserver les plans de détail [VIS-001…124](URGENT_AAA_VISUAL_BACKLOG_2026-11-03.md), l'[audit premium du 1er novembre](AUDIT_PREMIUM_PLAN_2026-11-01.md) et les critères [Release](../RELEASE_CHECKLIST.md) comme documents de travail ; ne pas dupliquer leurs 124 actions en micro-tâches.

**Premier grand remplacement du lot 1 — 4 novembre 2026 :** Storm Harbor possède désormais une sculpture 3D originale de **portique de promenade + sous-châssis + grue/cargo suspendu** (1 956 triangles, sept vrais MeshParts UV/tangentes ; Model Roblox **Approved `134157110756659`**, import [#41837415151](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41837415151)). Nouveau chargeur serveur certifié et remplacement client réversible des **neuf pièces natives par arche**, uniquement sur les six portiques physiques `PromenadeStep=2/4/7` des deux skywalks Harbor. LOD Medium 2/1/0, High 6/3/1, Low natif, aucun nouvel obstacle/Part de collision ni timer. **Statut : source intégrée, aucune preuve Android ni publication.** [Détails](ORIGINAL_HARBOR_PROMENADE_GANTRY_2026-11-04.md).

**Second lot visible Storm Harbor — 4 novembre 2026 :** les habillages 3D de quais d'origine (`101457508594609`) ont passé build et sept suites moteur au commit `4494482` ; puis un **véritable cargo maritime 3D** de 4 918 triangles, 20 conteneurs détaillés et sept matériaux a été créé et approuvé (`128820723471019`, [import #41851214739](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41851214739)). Source intégrée dans le chargeur sécurisé, substitution client du vieux cargo `Part/WedgePart` avec fallback Low et LOD distance ; aucune physique modifiée. **QA moteur du cargo en attente et publication publique non déclenchée.** [Contrat et preuve](ORIGINAL_HARBOR_FREIGHTER_2026-11-04.md).

**Troisième grand remplacement du lot 1 — portiques cinématiques Storm Harbor (4 novembre 2026) :** deux originaux **Approved** supplémentaires `75684193304551` (3 400 triangles) et `98809955094422` (5 232), sept MeshParts par source, isolent les quatre matériaux fixes des vrais chariots/câbles/charges mobiles. Les quatre grues industrielles natives du port sont remplacées visuellement **sans supprimer leur animation** : les 3 groupes mouvants suivent leurs CFrame natifs déjà animés, sans nouvelle boucle. Medium 2/1/0, High 4/2/0, Low zéro. Les deux assets fixes créés au préalable restent documentés comme preuves et non comme modèles runtime utilisés. Registre approuvé : **57 Models**. [QA et limitations](ORIGINAL_HARBOR_KINETIC_GANTRIES_2026-11-04.md). **Statut : source intégrée, Android et publication non certifiés.**

## 1 — État vérifié au début du plan

- **Livrable source** : dernier build GitHub Actions [#41826099598](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41826099598) **success**, sept suites du moteur Roblox [#41826112300](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41826112300) **success**, workflow source-only exact SHA [#41826079143](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41826079143) **success**. La récente coque de pylône Model `75945454705246` a été réellement modérée **Approved** [#41825253849](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41825253849). L'approbation n'est pas une capture du rendu final.
- **Base de jeu qui existe, à préserver** : cinq variantes `Classic/Towers/Crossroads/Orbital/Harbor` ; cinq sols serveur de 320 × 320 studs ; onze désastres ; phases vote / READY / manche / résultat ; solo et huit places effectives avec `AISurvivorRules.TargetVisibleParticipants=8` et sept bots au maximum (les bots peuvent mourir : huit n'est pas une population permanente) ; interactions et routes distinctes par carte, Double Chaos, progression, DataStore, quêtes, cosmétiques, statistiques d'onboarding et des manches.
- **3D déjà avancée** : modèles originaux Roblox approuvés pour grandes structures, surfaces, sous-faces, carapaces, portique et quatre coques fermées du lobby ; vraies UV/tangentes ; seize images 2K PBR originales et `SurfaceAppearance` régulés par LOD. Ne jamais remplacer ces modèles par une simple nouvelle construction de `Part`/ `WedgePart`.
- **Déficits confirmés par le source** : `src/shared/AnimationCatalog.lua` utilise toujours cinq animations génériques R15 comme fallback actif des bots ; `src/shared/AudioConfig.lua` réutilise abondamment `rbxasset://sounds/...` (même si le mixage et les composites existent) ; l'arborescence GitHub ne contient pas encore de média source `png/jpg/webp/svg/ogg/mp3/wav`, les écrans 2D et icônes sont donc surtout dessinés par script ; `StructureRetrofit`, `MapBuilder` et divers modules sculptent encore des assemblages natifs dans le premier plan. Ce sont des **chantiers de remplacement, pas une absence de fonctionnalités**.
- **Risque de vérité produit** : l'issue [#563](https://github.com/dbrckk/chaos-survival-roblox/issues/563) décrit un incident de création de serveur public le 2 novembre. L'utilisateur a par la suite indiqué que tout fonctionnait, ce qui est un signal positif ; le ticket reste ouvert, sans preuve de test public indépendant récent. Ne pas prétendre que le SHA actuel `8cca417` est publié. `assets/source/roblox-asset-registry.json` conserve encore des flags historiques `models_inserted_in_game=false` / `android_visual_qa_completed=false` ; les réconcilier avec la présence effective des clones et leurs diagnostics, **sans renommer une absence de preuve en échec technique**.
- **Audit source antérieur** : estimation 6,6/10 au 1er novembre avec faible/moyenne confiance, NON une note visuelle mesurée. Aucun nouveau score global n'est augmenté sans images, expérience humaine, sessions et FPS mesurés. La production vise un niveau perçu >= 9/10 **après validation**, pas 9/10 parce que la liste de features grandit.

## 2 — Priorités par produit, et non par nombre de fichiers

| Ordre | Lot premium fini | Importance | Objectif principal | Critère de fermeture |
|---|---|---|---|---|
| **0** | Vérité de la release et référence | **P0 bloquant** | Accès public re-testé, capture vraie du lobby + cinq cartes ; version SHA / Place / univers rapprochée | Une partie publique complète, provenance datée, captures et budget mesuré |
| **1** | Géométrie jouable et architecture du proche | **P0 visuel** | Faire disparaître l'effet « grandes dalles et blocs » : routes, escaliers, plateformes, bordures et ponts, puis lobby et façades | Aucun chemin trompeur, vrais meshes approuvés près de la caméra ; collisions/bots/effondrement intacts |
| **2** | PBR et éclairage de l'ensemble des scènes | **P0 visuel** | Une direction artistique par carte ; UV/materials réels, key/fill/rim, contrastes, pluie/nuit | Sols/avatars/bots lisibles sur Low/Medium/High, quatre canaux PBR vérifiés, pas de bloom écrasant |
| **3** | Catastrophes et environnement interactif | **P0 expérience** | Onze dangers avec silhouettes, séquences anticiper→éviter→impact→résultat ; mécanismes de carte ressentis | Vrai choix de déplacement, deux risques compatibles, aucune mort impossible/faux sol |
| **4** | Bots et animation R15 | **P1 majeur** | Trajets naturels, transitions de locomotion, clips du créateur, réduction des coincidences et blocages | Sessions réelles : 8 participants au départ, 0 bot coincé, physique et rythmes crédibles |
| **5** | Audio original + identité 2D/UI | **P1 majeur** | Retirer les sons stock les plus reconnaissables ; marque/iconographie authentique ; HUD mobile | Audio clair, musique cohérente, alertes prioritaires, aucune collision de boutons sur Android |
| **6** | Onboarding, récompenses et rejouabilité | **P1 rétention** | But immédiatement évident ; gagnant, récompenses, retour rapide, second objectif | Joueur novice comprend et joue avant 30 s utiles, voit pourquoi il a survécu/perdu et relance |
| **7** | Certification et publication unique | **P0 release** | Build + 7 suites + Studio/authentique Android + performances + publication exacte | Jeu public fonctionnel et vérifié sur appareil ; métriques et rollback archivés |

**Règle d'exécution :** un seul gros lot à la fois ; terminer sa géométrie, son matériau, sa lumière, son LOD, son interaction et sa preuve avant de passer au suivant. Pas de « v0.5 » visible publiquement pour progresser artificiellement.

## 3 — Détail des travaux non terminés

### Lot 0 — Vérité du runtime et référence visuelle (prérequis, pas une refonte)

**Existant** : build Rojo, lint, sept suites Roblox Cloud ; scripts de capture/visual QA natifs dans `src/client/visual-review-capture.client.lua` et documentation Android. **Reste :** captures *authentiques* du lobby et de chaque arène en caméra joueur et état de manche, relevé des véritables `LocalOriginal*Count`, écran d'accueil, comparaison image au SHA ; résoudre/fermer l'incident de join #563 sur preuve d'un client réel ; vérifier Roblox Creator versionNumber et le vrai contenu déployé. L'agent peut préparer code et QA GitHub ; il ne doit pas inventer des captures Android/Studio, un FPS ou la connexion Roblox.

**Sortie** : six scènes repères (lobby + cinq arènes) multipliées par proches / mi-distance / panoramiques, une scène à danger cumulatif, deux tiers graphiques minimum ; tableau d'écart réel `prévu / rendu / coût`. Une seule campagne physique de référence pour éviter les tests continus pendant création.

### Lot 1 — Terminer les vrais volumes 3D avant tout micro-polish

1. **Plateformes, paliers, passerelles et Sky Spine** (VIS-009/010/025/027) : monter des carapaces/sous-châssis vérifiés sur toutes les catégories à forte présence dans la caméra selon budget, supprimer *seulement* les rails/blocs cosmétiques équivalents réellement couverts ; créer des jonctions structurelles crédibles pour chaque hauteur/transition ; respecter orientation, mouvement, destruction, shrink et collision serveur. Couverture et draw calls vérifiés par carte, aucun faux chemin praticable.
2. **Storm Harbor comme standard visuel ET jouable** : quais et accès multi-altitude, grues, cargaisons, chemins alternatifs, supports sculptés, silhouette portuaire distincte. Le plateau est déjà 320 studs, mais largeur du terrain != occupation utile : densifier sans étendre aveuglément le sol. Mesurer les vrais choix tactiques depuis le spawn.
3. **Quatre autres cartes** : Classic = grille et repères de danger ; Towers = ponts, navettes et mécanismes de hauteur ; Crossroads = aiguillages/portiques/latérales ; Orbital = hélix/noyau/anneaux. Déployer le même niveau de finition géométrique, mais avec modèles de design uniques, pas un simple re-skin de Harbor.
4. **Lobby et 16 façades par carte** (VIS-011/012) : coques 3D nouvelles déjà créées à préserver ; terminer la scène centrale, bornes, arêtes du 74-stud Floor, mobiliers et éclairage motivé ; signalétique vrai gameplay ; façades et toitures des 16 bâtiments encore partiellement natives. Réconcilier profils 3D locaux, provenance Approved, LOD et caches de chargement.
5. **Silhouettes / répétitions** : les principaux assets importés se répètent ; réserver des modèles héros à chaque arène et variations structurelles motivées ; LOD géométrique véritable plutôt que générer cinq fois plus de petits objets.

**Sortie** : aucune grande silhouette primitive proche d'un parcours ou du lobby, 5 cartes immédiatement identifiables sans HUD, un profil géométrique/collision parfaitement cohérent pour toutes les surfaces qui semblent praticables.

### Lot 2 — Textures, matériaux et lumière (VIS-029…058)

Ne **pas** réimporter par réflexe les 16 cartes PBR déjà Approved. Auditer d'abord les vraies `SurfaceAppearance` sur les `MeshPart` UV/tangentes (mapping, tiling, normales, roughness, metallic et alpha) ; réparer les coutures/étirements et le z-fighting. Créer seulement les finitions manquantes très visibles par famille : métal peint, dalle antidérapante, béton, grille, céramique, revêtement marin, verre/isolant. Limiter 2K aux surfaces justifiant le coût ; réutiliser atlases 512/1K et Low fallback pour les autres.

Corriger perceptuellement l'éclairage **en gardant la nouvelle géométrie des `ArenaFocalLightingRules` déjà corrigée**. Les cinq ambiances doivent avoir silhouette, température, orientation solaire et météo distinctes, mais un niveau de visibilité équitable. Assurer un fill de sol/avatars/bots perceptible pendant READY/round, Darkness, pluie et Double Chaos, avec éléments critiques non masqués par profondeur de champ, bloom ou fog. Prioriser une lumière juste plutôt que des dizaines de PointLights.

**Sortie** : revue avant/après du même parcours et mêmes conditions sur les cinq cartes, qualités Low/Medium/High, pas de bots noirs ni de chemins illisibles.

### Lot 3 — Catastrophes, interactivité et animation d'environnement (VIS-059…073)

Les onze catastrophes sont en place ; l'effort va aux **formes, réactions et choix**, pas à une douzième mécanique. Priorités visibles : lave réellement mouvante plutôt que plan Neon ; météores de roche fracturée/impact ; tornade volumétrique ; fissures d'effondrement ; ponts/équipements réagissant à l'alerte. Le code des catastrophes possède déjà du VFX : vérifier dans l'image les signatures et ne pas re-fabriquer ce qui existe. Définir pour chacune avertissement identifiable sans couleur, fenêtre de réaction, effet d'impact, état résiduel et cleanup. Contrôler Double Chaos et Reducemotion avec budget de particules, et aucun décor qui ressemble à un chemin sûr lorsque la collision est supprimée.

**Sortie** : 11 signatures visuelles réellement distinctes, routes alternatives pertinentes dans les cinq cartes, compatibilité danger+obstacle+IA.

### Lot 4 — Survivants, bots et animations (VIS-074…084)

Les bots de remplissage et leur variabilité de personnalité existent (`AISurvivorRules`, `AISurvivorService`). Corriger à partir de leurs **déplacements réels**, pas des seuls calculs IA : oscillation, sauts qui touchent le bord, attente devant un portillon, changement de cible abrupt, collisions pendant sprint, récupération sur chemins bloqués. Conserver le vrai nombre `8 - humains` au départ et l'équité sans connaissance omnisciente ; ne pas simuler de faux vrais comptes Roblox.

Les cinq ID `AnimationCatalog.AISurvivor` sont encore des animations Roblox par défaut ; remplacer par clips originaux **créés/importés/licenciés sur le compte du créateur**, avec Idle/Walk/Run/Jump/Fall puis start/stop, pivot, réception, réaction de danger, victoire et élimination. Ajuster le pacing et les transitions sur R15 puis le repli R6. Budget d'animation réduit pour avatars loin de la caméra.

**Sortie** : séquences réelles d'au moins cinq manches consécutives sans bot coincé, membres qui glissent, animation figée ou victoire sans réaction.

### Lot 5 — Audio, identité 2D, HUD

**Audio** : `AudioConfig.lua` utilise des sons stock Roblox pour plusieurs événements (vote, collisions, météo, victoire, danger) malgré les bons mixeurs et composites existants. Réutiliser le système actuel de `SoundGroup`, ducking et volume et créer des SFX originaux/licenciés pour les événements les plus fréquents ainsi que thème lobby/READY/round/victoire, avec spatialisation par carte et vérification des droits. Éviter de multiplier les SoundInstances en simultané. Entendre chaque alerte même sans musique.

**2D** : dépôt encore sans fichiers source médias (png/jpg/webp/svg) ; on ne doit pas compter de petits `Frame`/ `TextLabel` comme une iconographie premium complète. Créer une vraie famille d'icônes originales Roblox-compliant (11 dangers, 5 mondes, navigation, capacité, résultats, récompenses), ainsi qu'un logo, une identité graphique et des cartes illustrées. Conserver lisibilité tactile et localisation. **Image d'icône et miniatures Roblox** : les importer à la fin sur des captures honnêtes du build courant ; ne pas utiliser d'image hors jeu comme faux screenshot.

**Sortie** : UI cohérente 320/360/400/440 px, réussite/vote/danger compréhensibles à vue, bande-son crédible, zéro alerte cruciale inaudible ou seulement colorée.

### Lot 6 — Première minute et fidélisation (VIS-085…109)

Les services `FirstTimeExperience`, `GameAnalytics`, `RoundResultState`, `RoundSettlement`, sauvegarde, quêtes/XP existent déjà. Composer un onboarding visuel **sans lecture longue** : où aller, quoi éviter, combien de temps survivre ; première action en moins de 30 s utiles même si entrée pendant une manche ; commencer par objectif>danger>action, jamais boutique>jouer. Après une défaite expliquer la cause (ex. lave, impact, chute), la route alternative et le prochain essai ; après victoire animation, survivants, récompenses exactes et retour immédiat au vote/manche. Ajouter choix sociaux utiles (invitation/revanche) seulement là où ils augmentent une seconde manche.

Exploiter les événements existants : `SessionExitStage`, `TimeToClientReadySeconds`, `TimeToFirstVoteSeconds`, `TimeToFirstRoundSeconds`, `TimeToFirstCompletionSeconds`, `ArenaSurvived`, fraction de survie bots, départ en cours de manche, ré-entrée. Le bug historique Harbor en `Arena:Unknown` a déjà été corrigé par `GameAnalytics` utilisant `ArenaVariants.Order` : **ne pas le réintroduire**. Pas de nouveau système de tracking parallèle si les événements actuels suffisent. Ne pas confondre événement codé avec valeur mesurée.

**Sortie** : objectif compris par des néophytes sans explication extérieure, entrée/join/respawn cohérents, résultat véridique et envie objectivement observée de jouer une seconde manche.

### Lot 7 — Performance, certificat réel, publication

Cible **proposée et à mesurer**, non garantie : au moins **30 FPS soutenus sur Android bas de gamme compatible**, p95 frame-time aussi stable que possible, aucune baisse progressive sur 30 min et pas d'augmentation d'instances/mémoire à chaque transition. Pour Android moyen viser **45–60 FPS** si matériel/qualité le permettent ; la lisibilité des avertissements ne s'adapte jamais vers zéro. Protéger les budgets existants de `VisualBudgetRules` : Low 440, Medium 680, High 900 parts rendus locaux, et observer GPU/draw calls (le nombre de Parts n'est pas un compteur de draw calls). Préparer des LOD/HLOD réellement géométriques, pas uniquement des éléments invisibles encore résidents.

Les vrais tests coûteux s'exécutent **aux jalons majeurs**, comme demandé : build/lint/7 suites Roblox Cloud à SHA exact, Studio authentifié si accessible, une session Android réelle Low/Medium/High, 5 cartes, 11 catastrophes + Double Chaos, bots, 8 places au départ, reconnexion, save/rewards, son et 30-minute soak. Vérifier la publication/destination Roblox Universe `10771083668` / Place `95351659174730`, permissions, histoire versionNumber, rollback. **Pas de publication sans gate réelle et vérifiée.**

## 4 — Critères d'arbitrage

1. **Fiabilité et jeu réellement jouable** avant la finition. Toute panne serveur/join/spawn/deplacement/bot bloquant la manche remonte en P0 immédiatement, avant les assets.
2. **Impact visible immédiat** : d'abord grand volume devant la caméra / fonctionnalité qui change la décision joueur ; ensuite matériaux et lumière ; enfin boulons, micro-particules et effets transitoires.
3. **Réutiliser le vrai code existant** plutôt que créer une seconde architecture d'objets, deuxième contrôleur Lighting, nouveau rendu UI ou nouveau pipeline audio ; ne pas inventer Roblox ID.
4. **Authenticité de source** : seuls vrais MeshParts approuvés remplacent les volumes ; les versions Low restent jouables/visuellement cohérentes et les collisions restent serveur.
5. **No regressions** : aucune nouvelle boucle de frame, source LoadAssetAsync non bornée, nouvelle fausse surface sûre, monde trop sombre, avertissement masqué, animation IA mensongère, son illégal, tracking de faux utilisateurs.
6. **Critère de sortie de chaque lot** : code complet sur le bon SHA ; source 3D/PBR/licences vérifiées ; compatibilité client/serveur ; scénario fonctionnel/stream/shrink ; rendu authentique comparé ; budgets Android ; document et lien d'evidence. Ne pas mettre « Done » à partir d'un commit seul.

## 5 — Première action de la suite, exécutable sans nouvelle réflexion

**Prochain lot après l'audit : `VIS-009 + VIS-010 + VIS-027` — terminer la géométrie proche caméra de Storm Harbor puis en faire le standard des quatre autres mondes.** Inspecter les vrais modules `PremiumRouteMeshKit`, `PremiumPlatformSideMeshKit`, `PremiumLargeStructureMeshKit`, `PlatformNativeTrimReplacementKit`, `PromenadeArchitecture`, `SkySpineArchitecture` et `HarborScenery`. Générer une liste de noms de Part encore visibles sur les routes, en distinguant surfaces de collision critiques vs doublons purement cosmétiques. Remplacer dans un seul lot cohérent les jonctions, les dessous et les supports prioritaires par leurs véritables assets Approved, en préservant shrink, LOD et danger. N'utiliser un upload supplémentaire que si un réel modèle indispensable n'existe pas déjà ; valider le lot une fois complet.

**Ne pas perdre une étape de la feuille de route à chaque « continue » :** la prochaine session démarre de ce document, vérifie la nouvelle HEAD et termine ce lot avant de revenir aux VFX secondaires.
