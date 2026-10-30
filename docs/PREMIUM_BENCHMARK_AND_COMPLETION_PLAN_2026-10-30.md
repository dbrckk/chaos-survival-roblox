# Chaos Survival — benchmark Roblox et feuille de route premium AAA

**Audit révisé : 30 octobre 2026.** État analysé : source du dépôt `dbrckk/chaos-survival-roblox` à partir de `531e863d2e4169a2a9ba6e0d31810cafde9a0414`, plus le chantier non publié des portillons physiques de Tower Run. L'implémentation de ce dernier n'a pas encore passé la validation Roblox sur son SHA définitif.

> Le jeu n'a pas été exécuté sur un appareil Android/PC par cet audit. Les notes sont des **estimations d'ingénierie** et non des mesures de satisfaction, d'audience ou de FPS. Elles ne certifient pas une parité AAA. La version actuellement publique ne contient pas les dernières améliorations non publiées.

## 1. Références comparables, vérifiées sur les pages officielles

| Référence (expérience originale) | Force confirmée | Enseignement applicable |
| --- | --- | --- |
| [Tower of Hell — YXceptional Studios](https://www.roblox.com/games/1962086868/Tower-of-Hell) | Obby à sections générées, objectif immédiatement clair, **sans checkpoint** | Sections maîtrisables et renouvelables, risque/récompense clair et lisibilité |
| [Flood Escape 2 — Crazyblox Games](https://www.roblox.com/games/738339342/Flood-Escape-2) | **150+ cartes communautaires**, boutons coopératifs, nage, glissade, saut mural, tyroliennes, modificateurs, badges | Diversité de mouvements et coopération : chaque carte présente sa propre grammaire de jeu |
| [Speed Run 4 — Vurse](https://www.roblox.com/games/183364845/Speed-Run-4) | Plusieurs dizaines de niveaux de speedrun, chacun avec une apparence et une musique propres, chrono et course entre amis | Fluidité, flow de déplacement, identité audio-visuelle et progression explicite |
| [Natural Disaster Survival — Stickmasterluke](https://www.roblox.com/games/189707/Natural-Disaster-Survival) | Boucle de survie simple, durée courte, résultats de survie facilement compréhensibles | Une menace lisible, une décision de survie immédiate et l'envie de rejouer |

**Éviter le clonage** : reprendre des principes éprouvés, jamais leurs cartes, scripts, personnages, marques ou médias protégés.

## 2. Scorecard — source candidate /10

| Axe pondéré | Poids | Note indicative | Preuve / limite |
| --- | ---: | ---: | --- |
| Sensations des sauts, caméra et contrôle | 20% | **5,0** | Coyote/buffer, effets et prévisualisation présents ; aucune mesure tactile Android ni revue caméra |
| Parcours physiques et obstacles interactifs | 15% | **6,5** | 5 cartes × 320 studs, routes, ponts et mécanismes ; nouveau portillon temporisé non encore validé en moteur |
| Variété / justice des catastrophes | 15% | **7,0** | Onze types et fusions ; pas de courbes mesurées d'élimination ni contre-mesures observées |
| Lisibilité des objectifs et première session | 10% | **7,0** | Coaching, panneaux physiques, traduction ; compréhension en partie non mesurée |
| Direction artistique / modélisation 3D | 10% | **6,0** | Architecture originale et PBR ; aucun audit perceptif comparatif sur screenshots Android |
| Audio, animations et micro-feedback | 5% | **5,5** | Systèmes présents ; qualité et synchronisation à certifier à l'oreille et sur téléphone |
| Compétitivité des bots et jeu social | 5% | **6,0** | Bots dirigés vers les vrais parcours ; aucun score de perception / équité enregistré |
| Rejouabilité et progression | 10% | **6,5** | Médailles de sauts, records, quêtes quotidiennes/hebdomadaires, récompenses plafonnées |
| FPS, latence et accessibilité Android | 5% | **5,0** | Budgets LOD et qualité Low/Medium/High ; aucune donnée thermique/FPS récente |
| Qualité de livraison et instrumentation | 5% | **5,0** | Suite moteur et publication publique authentifiées ; candidat actuel non encore testé ou publié |

**Note pondérée provisoire ≈ 6,2/10**, fiabilité **faible à moyenne**. Comparaison cible : **9/10 ou mieux**, chaque axe critique ≥8/10, aucune panne bloquante, expériences réelles réussies et métriques vérifiées. La note du précédent audit (6/10) ne doit pas progresser artificiellement parce qu'un fichier a été modifié.

## 3. Avancement concret P1 — portillon physique Tower Run (code non publié)

Le gameplay de Tower Run disposait déjà de **Skyrail Slipstream** (accélération) et de **Skybridge Pressure** (pont escamotable), mais pas d'un obstacle central à franchir activement par un saut normal.

Le nouveau `src/server/SkybridgeShutters.lua` comporte :

1. **Quatre vrais portillons métalliques**, un par pont physique, 2,05 studs de haut, couvrant la largeur du pont sans le faire disparaître. La géométrie reste physiquement franchissable par un saut Roblox ordinaire ; attendre son ouverture reste possible.
2. Un seul portillon menacé à la fois, cycle d'avertissement **2,6 s**, levée **0,32 s**, maintien **1,8 s**, puis retour au calme. Une **bande métallique ambre affleurante**, visible avant la levée et sans collision, signale la position réelle de l'obstacle (quatre bandes et quatre portillons au total). Trois autres ponts et leurs issues restent praticables. Aucun événement ne débute s'il ne peut terminer avant la fin de la manche.
3. Éligibilité *uniquement* aux manches avancées, solo-hazard et sans calamités conflictuelles. **Alternance avec Skybridge Pressure**, jamais de cumul des deux événements sur une manche.
4. Un obstacle devient **réellement collidable uniquement lorsqu'il est visible et levé** ; le serveur vérifie qu'aucun joueur/bot vivant n'occupe le passage avant d'activer la collision. Un occupant tardif annule la fermeture.
5. **Skyrail Slipstream ne propulse pas** un joueur/bot vers un portillon en avertissement/levée/fermeture ; le boost revient après réouverture. Les bots déjà engagés dans la traversée ne continuent plus vers un portillon qui apparaît en cours de route : leur IA examine seulement les vrais portillons du pont actuel, respecte leur propre temps de réaction, puis se replie vers une extrémité physiquement supportée ou attend si elle se trouve déjà au centre. Ni téléportation, ni changement de vitesse ou de hauteur du saut.
6. Affichage local discret **SAUTE OU ATTENDS / JUMP OR WAIT** sur le portillon réellement présent, uniquement pendant sa phase pertinente et les manches actives. Les labels se créent via `CollectionService` et sont nettoyés à la disparition du modèle. Le joueur proche d'un portillon à l'état `Warning` reçoit aussi une seule courte alerte sonore, via l'asset déjà utilisé `PlatformWarning` et le mixage existant (muet / volume effets). L'alerte est calculée dans la diffusion RoundState existante, sans nouvelle boucle, et ne s'applique pas aux spectateurs ni aux personnages hors du pont.
7. Scénarios Roblox écrits dans `tests/engine/arena-mechanics.spec.luau` et `tests/engine/ai-survivor-rules.spec.luau` (non exécutés pendant l'amélioration) : phases, vraies collisions, fenêtre temporelle, contre-mesure humaine/IA, exclusion météo, alternance, cleanup, désactivation des boosts et retraite réelle selon orientation / altitude / phase du portillon.

**Garde-fou** : après tests moteur, vérifier réellement sur Android que les utilisateurs peuvent sauter au-dessus d'une barrière levée, que les portillons ne les traversent pas lors d'un lag, et que les noms/couleurs restent lisibles en faible qualité. Ajouter un protocole de 15 captures à intervalles réguliers du point de vue d'un bot traversant Tower Run, avec au moins deux fermetures successives : confirmer que le bot déjà engagé **ne traverse pas le métal**, ne quitte pas la vraie passerelle, et réessaie normalement lorsque le portillon redevient `Idle`. Vérifier les deux orientations physiques des ponts et une pluie de météores simultanée (priorité de survie conservée). Pour l'audio : écouter à proximité immédiate, à distance, en spectateur et avec effets coupés ; aucune alerte en double pour un même horodatage serveur. **Aucun résultat d'essai réel n'est actuellement revendiqué**.

## 4. Plan ordonné : de 6,2 à ≥9/10

### M0 — Stabiliser le candidat fonctionnel [bloquant]

- **Code** : revoir `SkybridgeShutters.lua`, `ArenaMechanics.lua`, `SkyrailSlipstream.lua`, `skybridge-shutters.client.lua`, `JumpRouteCueRules.lua`, `ParkourFlow.lua`, et les régressions de la migration DataSchema v9.
- **Validation au prochain jalon majeur** : Build Validation + **toutes** les suites Roblox Open Cloud sur le même SHA (aucun test pendant les modifications). Vérifier les cinq arènes et la conservation des données. Refuser la publication sur une seule panne réelle.
- **Sortie** : aucune erreur de build, aucune régression moteur, aucun exploit évident de score/XP, tous les obstacles redonnent une collision saine après un round, pas de portillon fantôme.

### M1 — Contrôle et caméra au niveau des références [priorité gameplay]

- **Code cible** : `src/client/jump-assist.client.lua`, `movement-feel.client.lua`, `mobile-camera-sightline.client.lua`, `JumpLandingPreviewKit.lua`, `src/shared/MovementAssistRules.lua`, `JumpLandingPreviewRules.lua`.
- **Travail** : enregistrer la latence des appuis, les sauts ignorés, les atterrissages aux bords des plateformes et les angles de caméra ; corriger une cause à la fois. Garder l'autorité du serveur pour l'XP et les impacts.
- **Critères d'acceptation proposés** : 0 saut physiquement impossible ; ≥90% de réussite sur la première section par des joueurs ayant compris le contrôle ; p95 commande→réaction visuelle ≤100 ms dans les conditions de test fixées ; aucune zone cachée par caméra / HUD sur Android.
- **Dépendance** : M0.

**Avancement M1 source (non publié) :** le cycle de vie des sauts a été corrigé pour les `Humanoid` qui apparaissent après l'ancien délai de 5 s. Les entrées mises en mémoire attendent désormais un vrai état `Landed` / `Running`, même si `FloorMaterial` est arrivé dans l'autre ordre. Une stabilisation des perturbations cosmétiques de caméra tactile intervient seulement pendant la descente. Voir [la matrice de vérification Android M1](PREMIUM_ANDROID_JUMP_CAMERA_2026-10-30.md).

**Sécurité et lisibilité des atterrissages :** le même indicateur physique Android/PC à quatre segments distingue désormais un atterrissage dans un vrai **Grid Sweep, Cargo Sweep ou portillon actif de Towers** d'une plateforme réellement sûre. Les zones hors du couloir de danger et les plateformes surélevées échappant à l'onde restent indiquées comme sûres ; les marques de danger sont des X rouges et non une simple couleur. Voir [les règles, performances et cas de validation](PREMIUM_HAZARD_AWARE_LANDING_PREVIEW_2026-10-30.md). **Il reste à exécuter les tests moteur du commit final et à mesurer le ressenti sur de vrais appareils avant toute hausse de note.**

### M2 — Véritable variété de parcours et compétences physiques

- **Code cible** : `ArenaVariants.lua`, `ArenaMechanics.lua`, `MapBuilder.lua`, `SkybridgeShutters.lua`, `SkybridgePressure.lua`, `CrossroadsSwitchyard.lua`, `HarborCargoSweep.lua`.
- **Travail** : finaliser **une mécanique signature solide par arène** : Classic = rythme des lignes de choc ; Towers = saut de portillon + Skyrail ; Crossroads = aiguillage latéral ; Orbital = transfert Helix ; Harbor = traversée de docks sous balayage. Pour chaque mécanique : anticipation visuelle et sonore, parade évidente, bot soumis aux mêmes règles, mécanisme de récupération, interaction avec les catastrophes.
- **Contenu** : quatre routes réelles par carte, plusieurs décisions praticables, entrée novice, sommet expert, aucun parcours décoratif présenté comme jouable.
- **Sortie** : 100% des transitions de routes vérifiées en moteur, 0 passage condamné par une combinaison de catastrophes, et au moins une raison tactique distincte de revisiter chaque carte. Tester les combinaisons les plus risquées.

### M3 — Visuel 3D, animation et son [un pipeline artistique complet]

- **Code cible** : `ArenaDistrictArchitecture.lua`, `HeroArchitecture.lua`, `MapBuilder.lua`, `src/client/pbr-district-materials.client.lua`, `arena-hero-motion.client.lua`, `audio.client.lua`.
- **Travail** : une silhouette immédiatement reconnaissable par arène, vrais modèles sculptés plutôt que de simples blocs, matériaux métal/béton/bois avec normal/roughness/metalness quand utile, lumières et brouillard contrôlés. Créer une bibliothèque cohérente de transitions, impacts, glissements et atterrissages, et une signature audio distincte par catastrophe.
- **Perf** : LOD pour modèles éloignés, compression et limitation des textures lourdes, limite d'effets simultanés, pas de flash agressif ni d'alerte uniquement fondée sur la couleur.
- **Sortie** : captures réelles validées dans 5 arènes × 3 éclairages × 3 tiers graphiques ; les dangers et zones d'atterrissage restent lisibles ; aucun asset sans licence maîtrisée.

### M4 — Rétention, objectifs et équité

- **Code cible** : `RoundSettlement.lua`, `ParkourFlow.lua`, `DailyQuests.lua`, `WeeklyChallenges.lua`, `lobby-round-recap.client.lua`, `RoundResultState.lua`, `AISurvivorService.lua`.
- **Travail** : fin de manche immédiate et gratifiante, explication de la cause d'échec, objectif suivant, record personnel, une relance facile. Récompenser les vraies réussites de maîtrise plutôt que le temps de connexion. Éviter les obstacles qui pénalisent systématiquement les débutants.
- **Bots** : navigation naturelle, erreurs crédibles, aucune résistance/dégât immérités, vérification de la progression sur les parcours réels, aucune récompense gagnée à la place des humains.
- **Métriques à instrumenter** : arrivée→premier saut, premier objectif compris, première victoire, causes de chute, carte/étape abandonnée, conversion vers deuxième manche, durée session, rétention J1/J7. **Pas de chiffres de rétention actuellement connus.**
- **Sortie** : compréhension de l'objectif ≥90% dans un échantillon de nouveaux joueurs ; ≥70% reviennent volontairement pour une seconde manche **dans la séance de test** (objectif de conception, non prédiction de rétention réelle).

### M5 — Android / PC, sécurité et lancement public unique

- **Équipements** : Android entrée de gamme, Android intermédiaire, PC standard ; portrait/paysage selon support, connexion instable, accessoires cosmétiques chargés, effets météo et rounds avec bots.
- **Instrumentation** : p50/p95 frame-time, mémoire, CPU/GPU, temps d'apparition, saturation des remotes, erreurs serveur, crash rate, temps d'attente, FPS pendant les effets simultanés.
- **Cibles techniques proposées** : p95 ≤33,3 ms sur Android d'entrée de gamme (≈30 FPS) ; p95 ≤16,7 ms sur Android intermédiaire compatible (≈60 FPS), avec graphiques adaptés ; zéro crash bloquant pendant la campagne de validation ; p95 interaction du saut suffisamment bas pour un parcours expert.
- **Campagne** : minimum **20 manches Android + 10 manches PC** instrumentées, couvrant toutes les cartes et phases, plus des parcours bots avec 15 captures par session ; revue des défauts et correction jusqu'à stabilité. Cet échantillon valide la stabilité de base, pas statistiquement une rétention J7.
- **Publication** : Build + Engine + capture Android/PC + sécurité + art + audio **sur un commit final figé** ; ensuite seulement publication Open Cloud sur l'expérience Roblox publique EXISTANTE. **Aucune version privée ou intermédiaire publiée.** Documenter un retour arrière si la santé des serveurs se dégrade.

## 5. Règles de décision

1. Un système commencé se termine **code + contraintes + affichage + persistance si nécessaire + scénarios + documentation**, avant la fonctionnalité suivante.
2. Les suites coûteuses s'exécutent **uniquement aux jalons importants**, jamais après chaque édition de fichier ; les revues statiques n'empêchent pas de corriger des incohérences évidentes.
3. L'étiquette **9/10** nécessite des données de partie vérifiées et une comparaison observée, et non une simple hausse subjective à chaque PR.
4. Fiabilité > jeu réellement fonctionnel > sécurité/équité > architecture > performance > interface > gadgets.
5. Pas de pay-to-win, pas d'achat nécessaire pour franchir un obstacle ou gagner un record. Préférer assets originaux et outils gratuits/open source.

**Statut** : le code du portillon Tower Run est candidat à la prochaine validation majeure ; il n'est **ni certifié par des tests exécutés ni publié**.
