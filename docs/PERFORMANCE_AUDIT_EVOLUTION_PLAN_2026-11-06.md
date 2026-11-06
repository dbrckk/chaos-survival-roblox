# Audit performances & plan d'évolution — Chaos Survival

**Audit source : 2026-11-06 — commit `c7692f6ff818574c3e9e01a42da07e974ccd1124` (public, Build Validation et 85 Roblox Engine specs verts).**

## Périmètre, preuve et limite

Inspection du code réel, non d'une capture de FPS mesurée : `src/client/scenery-lod.client.lua`, `src/client/visual-budget-pressure.client.lua`, `src/client/juice.client.lua`, `src/shared/VisualBudgetRules.lua`, `src/shared/VisualBudgetPressureRules.lua`, `src/shared/PerformancePulseRules.lua`, `src/server/AISurvivorService.lua`, `src/server/AISurvivorRules.lua`, `src/server/init.server.lua`, `docs/PBR_ANDROID_PERFORMANCE_GATE.md` et les workflows. **Aucune valeur FPS, GPU, CPU, mémoire ou latence réelle n'a été obtenue** ; ne pas convertir les limites de configuration en gains mesurés.

### Constats vérifiables

- Budgets cosmétiques locaux : Low **440 Parts/32 Lights/56 Effects**, Medium **680/48/82**, High **900/64/110**. Ce sont des quotas d'inventaire local, **pas** un plafond de tout le `Workspace` ou un budget de triangles/draw calls.
- PBR actif sur Android : Low **0**, Medium **32**, High **72** surfaces globales ; 2K MaterialVariants. Priorité au near-field et à la visibilité caméra, mais la consommation GPU réelle n'est pas connue.
- `scenery-lod.client.lua` : une boucle commune de **0,65 s Low / 0,90 s autres** ; plusieurs propriétaires de meshes, bâtiments, routes, skyline, trafic et silhouettes sont synchronisés dans le même passage. Risque de pic de travail coïncident et d'écriture répétée, à profiler.
- `visual-budget-pressure.client.lua` : observation **5 s**, inventaire coopératif mis en cache **20 s**, checkpoints après **160 instances**, reprise après suspension Android, fenêtre de stabilisation **8 s**. Réutiliser cet inventaire ; ne pas introduire un second scanner `Workspace`.
- `juice.client.lua` : FPS/P95 calculés par le sampler de frame existant environ toutes les **2,5 s**. `PerformancePulseRules` : premier rapport client à **12 s**, puis **45 s**. Les rapports sont non fiables pour les décisions serveur et ne prouvent pas la charge GPU.
- `AISurvivorRules.brainCadence` : à 7 bots, **0,42 s** entre les passes de la boucle commune ; ne pas confondre ce délai avec la latence effective de réaction individuelle. La physique des 7 R15 continue en parallèle ; coût serveur à profiler.
- `src/server/AISurvivorService.lua` ~209 ko ; `MapBuilder.lua` ~147 ko ; `init.server.lua` ~120 ko ; `src/client/init.client.lua` ~133 ko. **Taille du code ≠ consommation CPU** : prioriser par traces MicroProfiler, pas par nombre de lignes.
- La publication actuelle a passé Build Validation, Roblox Open Cloud Engine Tests et le workflow public. Ces validations garantissent des comportements testés, **pas** un seuil FPS sur Android.

## Cibles de sortie (SLO proposés, non observés)

| Mesure | Android moyen | PC |
|---|---|---|
| FPS médian pendant manche complète à 8 | ≥30 | ≥60 |
| P95 frame time | ≤40 ms | ≤22 ms |
| Proportion frames >50 ms | <5 % | <2 % |
| Changement d'arène | Aucun gel prolongé visible | Idem |
| 20 minutes, 5 cartes, plusieurs manches | Pas de croissance mémoire soutenue après stabilisation | Idem |
| Catastrophes et commandes | Danger et déplacement restent immédiatement compréhensibles | Idem |

Les seuils doivent être validés sur un vrai appareil de référence. Pour le serveur, fixer la cible après mesure des budgets script/physique/réseau avec 1, 4, 7 bots.

## P0 — baseline reproductible avant de changer le rendu

1. Sur le même Android et le même PC, effectuer 3 sessions de 20 min, mêmes graphismes et conditions. Mesurer FPS médian, P95, slow frames, mémoire, render CPU/GPU si disponible, ping, temps de chargement et variation de mémoire par manche.
2. Matrice : 5 arènes × 3 qualités (Low/Medium/High) × 1 ou 2 catastrophes × 1/4/7 bots ; sélectionner une matrice réduite de scènes extrêmes pour la première mesure, puis élargir. Capturer aussi écran noir, météo et lave montante.
3. Corréler les `ClientPerformancePulse` et `ClientMemoryPulse` existants avec la scène, la phase, le nombre de bots et les inventaires visuels ; ne pas ajouter d'Analytics à cardinalité illimitée.
4. Exporter un rapport daté : appareil, version du jeu, SHA, température et état de batterie, mesures agrégées et images de MicroProfiler. **Ne pas déclarer de gain sans A/B sur le même appareil.**

**Gate P0 :** disposer d'une baseline exploitable, identifier les 3 pics CPU/GPU/mémoire dominants et le nombre de sessions valides.

## P1 — supprimer les pics de frame sans dégrader le visuel proche

1. Instrumenter le coût de chaque propriétaire du **LOD commun**, avant/après ses `sync`, avec Roblox MicroProfiler sur appareil/Studio. Distinguer traversée, montage/démontage de MeshParts, changements d'attributs et bascules de transparence.
2. Mettre en cache les inventaires d'instances quand les `ChildAdded/Removed` existants suffisent ; invalider à la mutation et à la sortie d'arène. Ne pas rescanner tout le monde à chaque frame.
3. Étaler les mutations cosmétiques coûteuses sur plusieurs passages **de la boucle existante** avec un plafond de travail temporel, en privilégiant la zone caméra et les télégraphes de danger. Ne pas retarder la physique ni les alertes.
4. Précharger seulement les assets réellement utiles au prochain round ; ne pas précharger simultanément cinq cartes 2K. Vérifier les pointes mémoire et le délai de première apparition.
5. Éviter les doubles propriétaires d'un même attribut `Transparency`, `LocalTransparencyModifier` ou `Enabled`. La sécurité et les signaux de danger restent propriétaires.

**Gate P1 :** P95 amélioré ou stable, aucune perte de visibilité des obstacles/risques, nombre de Parts et surfaces PBR dans les limites, absence de flash de streaming.

## P2 — coût 3D/PBR et qualité perceptuelle

1. Auditer triangles, textures, matériaux, lumières projetant des ombres, particules transparentes et superpositions ; les quotas Parts/Lights/Effects ne les capturent pas.
2. Priorité au joueur : surfaces jouables, premiers sauts, menaces et repères d'ascension. Réduire d'abord les éléments lointains ou hors caméra. Conserver les cinq identités visuelles.
3. Tester des LOD mesh réels pour monuments et quartiers ; garder les collisions/hauteurs serveur inchangées et le fallback natif pendant le streaming.
4. Contrôler Low/Medium/High, rotations caméra stationnaires, changements de carte, panne réseau, mode économie d'énergie, reprise Android, nuit et météo.

**Gate P2 :** aucune régression visuelle perceptible à 15–55 studs ; charge GPU réduite **mesurée**, pas supposée.

## P3 — IA et réseau à 8 participants

1. Profiler serveur avec 1, 4 et 7 bots : durée réelle des passes du cerveau, raycasts, navigation, animations, physique R15, réplication et latence des signaux.
2. Séparer conceptuellement réactions urgentes (catastrophe, lave, effondrement) des décisions sociales/non critiques. Réutiliser le budget de boucle existant ; ne pas augmenter la fréquence de tous les bots.
3. Cache des alertes spatiales partagé par manche et invalidé lors des changements de danger. Réduire les scans dupliqués uniquement si les traces montrent leur coût.
4. Vérifier absence de blocage, pas de téléportation de confort, trajectoires et interactions lisibles, maintien des huit participants sans saturation serveur.

**Gate P3 :** réaction danger et coût serveur vérifiés sous double catastrophe, sans perte de réalisme.

## P4 — fiabilité longue durée et déploiement

1. Test de 20–30 minutes : plusieurs rounds, cinq arènes, 7 bots, streaming, spectateur, changements de qualité, application Android suspendue/reprise.
2. Contrôler fuites : `RBXScriptConnection`, modèles et VFX client locaux, attributs d'ancienne carte, tweens et sons persistants.
3. Avant publication importante uniquement : Build Validation + toutes les suites Roblox Engine sur **exact SHA**, captures Android/PC et vérification des logs du vrai workflow public.
4. Après publication : comparer baseline/production ; si P95, mémoire ou gameplay régressent, revenir au SHA public précédent.

## Ordre et effort

| Ordre | Lot | Priorité | Critère de fin |
|---|---|---|---|
| 1 | Baseline et identification des pics | Critique | 3 traces comparables, top 3 coûts |
| 2 | LOD commun : travail étalé + cache ciblé | Critique | P95 sans régression visuelle |
| 3 | GPU : PBR, ombres, transparence, LOD mesh | Haute | gain GPU mesuré |
| 4 | 7 bots : coût, danger, réseau | Haute | 8 participants fluides |
| 5 | Mémoire longue durée et sortie publique | Haute | sessions 20 min + moteur + Android |

**Règles de livraison :** pas de refonte de tous les modules à l'aveugle ; une optimisation mesurée et terminée à la fois ; pas de tests moteur en continu pendant les modifications, seulement au jalon de publication ; pas de fausse affirmation de FPS ou de publication.
