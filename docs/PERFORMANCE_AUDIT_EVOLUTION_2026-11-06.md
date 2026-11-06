# Chaos Survival — audit de performance et plan d'évolution fondé sur les mesures

**Date : 6 novembre 2026**  
**Dépôt :** `dbrckk/chaos-survival-roblox`  
**Base auditée :** `main` @ `c7692f6ff818574c3e9e01a42da07e974ccd1124`  
**Périmètre :** expérience publique Universe `10771083668`, Place `95351659174730`, cinq arènes 320×320, onze catastrophes, huit survivants au lancement dont jusqu'à sept NPC R15.

## 0. Conclusions et limites de preuve

- **Publication et intégrité : vérifiées.** Les workflows *Build Validation* #42167481232, *Roblox Open Cloud Engine Tests* #42167488891 (85 fichiers de spécification) et *Publish Existing Chaos Survival* #42168030166 sont terminés en succès sur le **même SHA** `c7692f6f`.
- **FPS, GPU, mémoire, temps de chargement, heartbeat serveur, bande passante, OOM et chauffe : NON MESURÉS depuis cet audit.** Aucun verdict « 60 FPS Android », « zéro fuite » ou « GPU faible » ne peut être avancé à partir d'un feu vert CI. Les captures Android précédentes prouvent du gameplay et des problèmes de lisibilité, pas un budget frame-time.
- **Évaluation de source :** garde-fous graphiques et télémétrie existants, mais accumulation de propriétaires et de boucles de mise à jour susceptible de pénaliser les appareils modestes. **Hypothèse à mesurer** : cadence cumulée des synchronisations 3D/LOD et animations > poids d'un script isolé.
- **Principe :** ne pas réduire la qualité AAA par défaut, ne pas enlever le contrôle serveur des dangers, ne pas changer la physique des bots pour économiser quelques images, pas de tests lourds à chaque édition. **Un lot terminé puis validé à son jalon.**

## 1. Relevé vérifié du dépôt

| Domaine | Fait prouvé par la source | Conséquence pour l'audit |
|---|---|---|
| Démarrage client | `src/client` contient **117 fichiers `*.client.lua`** et 93 modules `*.lua` (env. **2 776 KiB** de source client) ; Rojo mappe le dossier vers `StarterPlayerScripts/Client` dans `default.project.json` | Risque d'initialisation, de connexions persistantes et de duplication de responsabilités ; **pas** la preuve que 117 scripts travaillent à chaque frame |
| Monde serveur | `src/server` comporte **105 fichiers**, dont six `*.server.lua`; cinq arènes avec socles 320×320 et 23 intervalles coopératifs ouvrables | Réplication initiale, pics de génération et changements de manche à mesurer |
| LOD principal | `scenery-lod.client.lua` effectue **24 appels de synchronisation** à des kits 3D distincts dans une boucle unique **0,65 s Low / 0,90 s Medium-High** | P0 : profiler coût CPU, cache, nombre de candidats et activité caméra avant d'optimiser |
| Détail décoratif | `world-polish.client.lua` suit une cadence de **15–30 Hz** selon qualité ; autres scripts de mouvement/VFX ont des boucles propres | P1 : chercher mises à jour inutiles hors champ/hors phase, synchroniser l'arrêt sur `ReduceMotion` et LOD |
| Inventaire des effets | `VisualBudgetRules` prévoit **Low 440 Parts / 32 Lights / 56 Effects**, **Medium 680 / 48 / 82**, **High 900 / 64 / 110** | Il s'agit d'un **inventaire de propriétaires locaux**, ni d'un plafond total de Parts de la carte, ni de draw calls, triangles, mémoire GPU ou FPS réels |
| Pression mobile | `visual-budget-pressure.client.lua` exploite la fenêtre FPS/p95 toutes les **5 s** et fait un inventaire coopératif du décor toutes les **20 s** (pendant `round`) | Points positifs : cadence bornée, suspension Android gérée. Chercher la redondance avec le relevé de 45 s |
| Cadence FPS | `juice.client.lua` mesure les frames via son propriétaire existant `RenderStepped`, actualise FPS/p95 toutes les **2,5 s**, puis émet une mesure au bout de **12 s** et toutes les **45 s** | Données clientes diagnostiques, non preuve indépendante de GPU ; les erreurs de Stats sont tolérées |
| Double inventaire | `juice.client.lua` appelle aussi `VisualBudgetRules.collect` en tâche coopérative sur le pouls 45 s ; le contrôleur de pression a son propre inventaire 20 s | Risque **deux traversées des mêmes propriétaires** lorsqu'elles coïncident ; mesurer puis mutualiser |
| Textures | Quatre familles PBR approuvées, **16 cartes 2K** au total, budgets globaux documentés **32** surfaces Medium Android et **72** High Android | Risque texture/cache et draw calls à confirmer ; recopier des instances d'apparence ne signifie pas allouer une copie GPU des pixels |
| Sols 3D | `PremiumGroundMeshKit` autorise jusqu'à **2 / 12 / 36** modèles décoratifs Low / Medium / High puis baisse sous pression. Les cartes de PBR supplémentaires sont plafonnées séparément | Compter MeshParts, triangles et mémoire réellement rendus par variante ; éviter les îlots de détail hors caméra |
| Bots | `AISurvivorRules.brainCadence` garde une boucle décisionnelle commune : si sept bots, intervalle **0,42 s** pour l'ensemble, environ **16,7 décisions individuelles/s** ; Pathfinding est asynchrone avec cooldown | Profil serveur et observation de réaction aux dangers ; ne pas augmenter aveuglément la cadence et les raycasts |
| Télémétrie | `PerformancePulseRules` sanitise les valeurs ; `init.server.lua` envoie FPS et mémoire à `GameAnalytics` avec quota réseau serveur **45 s** | Bon socle, mais FPS et mémoire agrégés ne donnent pas un profil par sous-système ; métriques GPU/CPU ponctuelles parfois indisponibles selon Android |
| Analytics | `ClientMemoryPulse` place plusieurs mesures numériques (`FrameMs`, `P95`, `CPU`, `GPU`, etc.) dans **une chaîne de dimension custom** ; `ClientPerformancePulse` concatène nombre de manche et comptes d'instances | **Cardinalité et exploitation à auditer** ; préférer cohortes stables et valeurs numériques agrégables, sans collecter d'identifiants sensibles |
| Streaming | Les scripts prennent en charge des éléments arrivant tard, mais `default.project.json` ne précise pas `Workspace.StreamingEnabled` | **Configuration effective de la place publiée non vérifiée** ; vérifier en Studio/Creator Dashboard avant tout réglage |
| CI | **183 workflows** dans `.github/workflows` | Dette de maintenance/checkout possible, mais ces fichiers **ne s'exécutent pas dans le client Roblox** |

### Éléments déjà correctement traités

- Un seul propriétaire `RenderStepped` pour l'adaptation FPS principale et comptage d'instances différé hors frame.
- Qualité adaptative Low/Medium/High avec hystérésis ; reprise d'application Android et réduction du mouvement prises en compte.
- LOD sous pression, source d'assets authentifiée, restauration des géométries natives en cas de streaming/modèle manquant.
- IA serveur partagée (pas sept boucles IA indépendantes), appels `ComputeAsync` asynchrones avec restrictions physiques.
- QA en vraie DataModel Roblox et trois workflows concluants sur le SHA publié.

**Ce qui reste non prouvé :** équivalence visuelle des cinq cartes Low/Medium/High en jeu, FPS et mémoire sur téléphone, métriques de serveur réel, fuite d'instances après plusieurs changements de carte, stutter au premier affichage des PBR.

## 2. Décision guidée par les goulots réels

Avant de toucher aux assets ou à la cadence d'IA, classer un échantillon **par contrainte prédominante** :

| Signal de profilage | Cause prioritaire à investiguer | Ne pas optimiser en premier |
|---|---|---|
| Temps **GPU/render** dominant | Nombre de MeshParts rendus, lumières avec ombres, fragments transparents, PBR 2K hors champ, particules | Logique de résultat/médailles |
| Temps **Lua/client** dominant | `scenery-lod`, 24 `sync`, ateliers cinématiques et leur cadence, `GetChildren` fréquents, rebuild UI | Résolution des textures sans preuve |
| **Mémoire** augmente après 5 cycles de carte | Connexions, instances locales non détruites, appareils d'apparence PBR, audio et effets résiduels | FPS moyen seul |
| **Server heartbeat** baisse avec 7 bots | IA `stepRecord`, raycasts, pathfinding, replication Humanoids, catastrophes simultanées | Post-traitement visuel client |
| Ping / réseau augmente en événements | `RoundState`, attributs répliqués, modèles et effets réseau, volume et fréquence des remotes | CPU des kits graphiques locaux |
| Entrée en partie lente | Streaming, taille de la scène serveur et des modèles, scripts init et assets non prioritaires | Un détail de lumière en manche |

## 3. Roadmap de performance priorisée

### P0 — Lot A : obtenir le profil Android/PC REPRODUCTIBLE

**Objectif :** distinguer les problèmes réels des hypothèses, sans nouveau service payant ni nouvelle boucle d'instrumentation.

1. Lire le tableau **Performance** du Creator Dashboard : FPS client, mémoire, heartbeat serveur, crash/OOM, temps de chargement et tendances par appareil si disponibles.
2. Réutiliser les attributs déjà produits par `juice.client.lua` : `ClientObservedFps`, `ClientObservedP95FrameMs`, `ClientObservedSlowFramePercent`, `OptionalVfxPressure`, `LocalOriginal*Count`, `PbrActiveSurfaceCount`, `PbrActiveSurfaceBudget`.
3. Pour le chronométrage : utiliser le **MicroProfiler / Script Profiler** de Roblox sur un Android de référence et un PC ; instrumenter uniquement aux jalons, via les propriétaires existants. Ne pas lancer de profiler permanent en production.
4. Scénarios identiques : entrée froide, lobby, READY, cinq arènes, lave, Tornado, météores, Double Chaos, huit participants, deux retours lobby, changement Low→Medium, caméra mobile, retour Android après suspension.
5. **30 minutes continues**, captures d'échantillons à 0, 5, 15, 30 min. Journaliser pour chaque segment version exacte, classe d'appareil, VFX, FPS médian, p95 temps d'image, mémoire totale / GraphicsTexture / GraphicsMeshParts si disponible, nombre d'instances, temps d'entrée, heartbeat serveur, qualité perçue.
6. Établir une matrice reproductible de **15 cellules minimum** (5 arènes × Low/Medium/High), puis cinq scènes extrêmes ciblées, sans prétendre couvrir 55 combinaisons.

**Livrable :** tableau de bord/baseline horodaté et matrice des goulots. **Acceptation :** chaque optimisation ultérieure cite un symptôme mesuré, un propriétaire et une métrique avant/après.

### P0 — Lot B : réduire le CPU d'animation et de LOD sans perdre le visuel

**Cible première d'enquête :** `scenery-lod.client.lua` + ses **24 kits de sync**.

1. Établir pour chacun le temps CPU p95, le nombre de candidats, le nombre de montages/démontages, les objets réellement visibles. Utiliser de courts segments `debug.profilebegin/end` uniquement dans le profil de test ou les outils de Studio.
2. Reprendre **le propriétaire unique existant** ; mettre en cache les `sync` lorsque carte, tier, pression, liste d'assets et cône caméra sont inchangés. Cadence de recalcul graduée selon distance/taille d'écran, réactivation événementielle sur streaming, retrait, danger et mouvements rapides. **Pas** de 24 nouveaux threads.
3. Garantir que les Parts/matériaux du gameplay et les warnings d'effondrement ne sont jamais retardés par le cache ; jamais de masque de surface praticable sur un mesh manquant.
4. Fusionner ou partager si pertinent les deux passages `VisualBudgetRules.collect` **20 s / 45 s** par snapshot horodaté, avec borne d'âge ; ne jamais exécuter un census synchrone en `RenderStepped`.
5. Réduire l'activité hors champ/hors manche des boucles `world-polish`, mouvements de grande architecture et accents de surface ; préserver les fonctions d'accessibilité et le rendu premium quand visible.

**Acceptation visée :** **−25 % de coût CPU p95 des propriétaires décoratifs** à scène et qualité identiques, sans baisse de FPS attribuable au remplacement de tâches et sans disparition de signalisation. Valeur cible, pas un résultat actuel.

### P1 — Lot C : qualité 3D/PBR fondée sur la valeur visible

1. Sur appareil Low/Medium, mesurer **GraphicsTexture** et **GraphicsMeshParts**, triangles, draw calls et cadres où l'écran montre réellement les 3D approuvés. Ne pas assimiler le budget de Parts locaux à la mémoire GPU.
2. Prioriser automatiquement les éléments proches du joueur et les surfaces de parcours devant la caméra ; réduire d'abord la densité des silhouettes lointaines, pas les premiers plans ni les avatars.
3. Conserver les quatre atlas PBR 2K approuvés **sur les éléments proches** ; si mémoire saturée, utiliser une sélection de matériaux plus modestes/hors champ ou créer des variantes authorisées moins lourdes après comparaison visuelle. Aucun ID 3D fictif ni texture inexistante.
4. Éviter les mutations de `MaterialVariant` et les démontages/réassemblages quand le résultat visuel n'a pas changé ; protéger les transitions StreamingEnabled et les fallbacks natifs.
5. Distinguer faible RAM/OOM et limite GPU/render : leurs solutions diffèrent.

**Acceptation visée :** baisse mémoire ou GPU démontrée, **même lisibilité de la lave, des vrais sauts, des bots et des dangers**, aucune nouvelle lacune 3D.

### P1 — Lot D : IA et simulation serveur stables à huit participants

1. Profiler `AISurvivorService.stepRecord` et le coût total `AISurvivorRules.brainCadence` en manches à 1, 4 et 7 bots, sans changer les colliders ni retirer l'IA visible.
2. Mesurer séparément temps de raycasts, appels de pathfinding et nombre de récupérations de bots bloqués. Réutiliser les résultats sûrs, échéancer les scans non urgents et conserver une réaction immédiate aux dangers critiques.
3. Traiter **d'abord les bots immobiles/coincés** signalés par les joueurs et toute collision de géométrie ; la cadence lente n'est acceptable que si elle ne dégrade pas la survie et les objectifs coopératifs.
4. Profiling serveur heartbeat, simulation physique, réseau R15, latence p95, coût des trois dernières secondes d'une manche Double Chaos.

**Acceptation visée :** heartbeat au moins **55 Hz** dans les scénarios cible où c'est tenable, **aucune téléportation**/collision trichée, bots sans immobilité durable non gérée et interactions cohérentes.

### P1 — Lot E : démarrage, mémoire, stabilité et réseau

1. Profiler cold join et chargement de `GeneratedMap` à cinq reprises, notamment premier passage d'une arène encore non mise en cache. Vérifier le **vrai réglage** Workspace StreamingEnabled de la place publiée ; ne pas activer/modifier à l'aveugle.
2. Inventorier le coût d'initialisation des **117 LocalScripts** ; les scripts purement Studio peuvent rester immédiatement inertes en production. Fusionner seulement les propriétaires redondants vérifiés, sans remplacer 117 modules robustes par un script monolithique.
3. Comparer la mémoire stabilisée après deux, cinq et dix cycles de manche/map, après perte de connexion et suspension/reprise Android. Surveiller listeners, Particles, Sound et MeshPart 2K résidents.
4. Mesurer trafic et tailles `RoundState`, `RemoteEvent` et attributs de bot, puis coalescer uniquement ce qui ne diminue pas l'information essentielle du joueur.
5. Remplacer progressivement les dimensions Analytics « FrameMs/P95/CPU/GPU concaténés en texte libre » par **cohortes peu cardinales** et mesures numériques exploitables, sans nouveaux identifiants personnels ; préserver le RateLimiter 45 s et la validation serveur.

**Acceptation visée :** absence de dérive mémoire anormale après **30 minutes**, chargement sur bas de gamme sans erreur, retour au jeu après suspension, aucune perte de récompense ni de résultat.

### P2 — Lot F : nettoyage et maintenance

- Supprimer/archiver uniquement après audit les anciens workflows one-shot non réutilisables parmi les **183** fichiers `.github/workflows`. Ils n'ont **aucun impact FPS client** et ne doivent pas passer devant le CPU/VRAM réels.
- Documenter chaque propriétaire visuel, son intervalle et ses budgets dans un registre ; signaler toute nouvelle boucle périodique ou `GetDescendants` fréquent à la revue.
- Conserver le manifeste exact des sources 3D approuvées, leurs fallbacks et la politique anti-abus serveur.

## 4. Critères cibles (proposés, PAS encore atteints)

| Indicateur | Android faible / Low | Android moyen / Medium | PC approprié / High |
|---|---|---|---|
| FPS médian en pleine manche | **≥30** | **≥45** | **≥60** |
| Temps d'image p95 | **≤50 ms** | **≤33 ms** | **≤20 ms** |
| Stabilité mémoire | Pas de crash OOM ; pas de croissance continue après stabilisation | Idem | Idem |
| Entrée en session | p75 **≤12 s** sur connexion de référence documentée | Idem | Idem |
| Gameplay | Huit participants au démarrage, danger et routes réelles lisibles, aucun faux sol | Idem | Idem |

Seuils proposés comme **objectifs de travail**, à ajuster après mesure réelle de la classe de téléphones visée. Un FPS moyen seul n'est pas un feu vert si le p95, l'input ou la mémoire se dégradent. Le p95 est à lire avec les statistiques client, le GPU avec MicroProfiler/console et le heartbeat côté serveur.

## 5. Ordre d'exécution et validation

1. **Lot A** : instrumentation et captures de référence, sans mutation du gameplay.
2. **Lot B** : une seule intervention sur le gestionnaire LOD et la synchronisation des visuels ; mesurer les différences *avec le même scénario*.
3. **Lot C OU D** selon profil CPU/GPU : textures si GPU/mémoire ; bots si serveur ; ne jamais optimiser sur une simple intuition.
4. **Lot E** : démarrage, longévité, réseau et qualité de données.
5. **Lot F** : dette CI / documentation.

Les tests Roblox Engine, Build Validation, tests Studio et publication publique se font **uniquement aux jalons significatifs**. Bloquer une publication si le SHA testé diffère de celui publié, si un des 85 tests échoue, si l'Android perd des surfaces sûres ou si les résultats/monnaies régressent. La version publique actuelle `c7692f6f` reste la référence de comparaison et le retour arrière possible.

**Sources internes principales :** `src/client/scenery-lod.client.lua`, `src/client/juice.client.lua`, `src/client/visual-budget-pressure.client.lua`, `src/shared/VisualBudgetRules.lua`, `src/shared/VfxQuality.lua`, `src/shared/PbrDistrictRules.lua`, `src/client/PremiumGroundMeshKit.lua`, `src/server/AISurvivorService.lua`, `src/server/AISurvivorRules.lua`, `src/server/init.server.lua`, `src/server/GameAnalytics.lua`, `default.project.json`.

**Référence externe :** Roblox Creator Hub, *Identify performance issues*, *Improve performance*, *MicroProfiler*, *Design for performance* ; ne pas confondre diagnostics du studio et performances du client public.
