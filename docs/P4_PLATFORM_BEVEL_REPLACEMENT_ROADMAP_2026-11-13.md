# Chaos Survival — plan d'achèvement des bordures et de la 3D premium

Date : 13 novembre 2026. Dépôt : `dbrckk/chaos-survival-roblox`, branche `main`.

## Objectif produit

Faire disparaître les bordures et les structures `WedgePart` manifestement
primitives à proximité du joueur, dans les cinq arènes, en employant de
**véritables maillages 3D originaux**, sans aucune modification des zones
collisionnables, des signaux de catastrophe ou de la sécurité du parkour.

La fiabilité prime sur un faux pourcentage de conversion. Le chiffre
historique de **2 080 bordures** est le total généré lors de cinq reconstructions
de cartes différentes. Ce n'est ni le total visible dans une session, ni
le nombre de bordures restant à remplacer en temps réel.

## Diagnostic confirmé

- `MapBuilder` génère quatre `PlatformBevelN_1..4` par véritable
  `PlatformN`, en `WedgePart` non physique, ainsi qu'un
  `PlatformUnderFrameN`.
- Le masque client existant fonctionne uniquement avec un modèle 3D
  réellement monté, complet et soudé au propriétaire physique.
- Les carapaces compactes approuvées ne couvrent pas tous les rapports
  longueur/largeur. Les coques de 18 studs étaient auparavant limitées
  aux premiers indices et ont reçu un correctif de sélection caméra.
- L'absence historique de deux géométries dédiées empêchait de masquer
  légitimement les quatre bordures des decks rectangulaires et longs.

## Jalons, critères de sortie et état

| Priorité | Lot | État GitHub | Critère de validation |
|---|---|---|---|
| P0 | Mesurer les natives et distinguer les signaux | Fait, recensement client | `LocalBevelNativePartsReplaced` reflète des masques réellement posés |
| P0 | Corriger la sélection des vraies coques 18 studs sur tous les indices | Fait, source | Sélection locale bornée, intégrité des 4 Wedges et sous-cadre |
| P0 | Sculpter deux familles Rect / Long | Fait | OBJ triangulé + glTF 7 groupes avec vérification géométrie |
| P0 | Import Roblox propriétaire | Fait, **Approved** | Deux ID réels, preuve GitHub Actions, pas de placeholder |
| P0 | Chargeur serveur et propriétaire de remplacement client | Fait, source | Source allowlist, sept MeshParts complets, masque des 4 seuls Wedges |
| P0 | Fallback, streaming et sécurité des catastrophes | Fait, source | Collision inchangée, masque révoqué si source perdue, warning et shrink |
| P0 | Suites sources, Lint, Build Validation | **Validé** sur `01306e9` | [Build Validation](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43505241568) |
| P0 | Tests Roblox Cloud Engine | **7/7 suites et 1 146/1 146 assertions réussies** sur `01306e9` | [Validation moteur](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43505256785) : montage Rect + Long, repli natif, collisions et shrink |
| P0 | Publication jeu public | **Non effectuée** | Pipeline de publication validé sur SHA testé, contrôle de la Place cible |
| P1 | Captures Android Low/Medium/High | À mesurer | Capture en mouvement, danger warning/gone/restauré, stabilité du streaming |
| P1 | Performances Android, 8 joueurs | À mesurer | Éviter régressions FPS, pics de MeshParts/GC et surcouches PBR |
| P1 | Autres rapports et très grandes plateformes | À inventorier | Créer des meshes spécialisés seulement si la géométrie authentique ne couvre pas déjà les natives |
| P1 | Supports / socles / quartiers | Suite du chantier AAA | Prioriser grandes silhouettes primitives qui restent visibles en session |

## Deux nouveaux assets authentiques

| Famille | Source originale validée | Nombre de triangles | Roblox ID | Modération |
|---|---|---:|---|---|
| Rect | `16.64 × 2.115 × 9.64` studs | 1760 | `131482590870627` | Approved |
| Long | `25.64 × 2.115 × 7.64` studs | 2040 | `127617571835277` | Approved |

Sources reproductibles : `tools/generate_original_platform_rims.py` et
`assets/source/roblox-asset-registry.json`. Import Roblox :
[workflow 43499366621](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43499366621).
Validation des sources :
[workflow 43499193335](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43499193335).

## Contrat d'intégration

1. Serveur : `PremiumPlatformRimAssets.start()` importe les deux Model
   approuvés derrière le système partagé de restriction des importations.
   Il refuse scripts, `Part`, géométrie non conforme et modèles avec
   plus/moins de sept `MeshPart`.
2. Client : `ApprovedPlatformRimMeshKit` choisit des plateformes réellement
   visibles et physiquement sûres ; il refuse les plateformes sans leurs
   quatre Wedges et leur sous-cadre d'origine.
3. Montage : sept MeshParts non physiques sont soudés au vrai colliseur ;
   `PlatformNativeTrimReplacementKit` masque localement **uniquement**
   les quatre `WedgePart` de ce deck et ne touche jamais au sous-cadre.
4. Sécurité : `CollapsePhase`, `BridgeShutterPhase`, streaming,
   destruction de source, rétrécissement du plancher et baisse de qualité
   restaurent la géométrie native appropriée.
5. LOD : Low une seule source visuelle premium à la fois ; Medium
   jusqu'à 4 PC/1 tactile ; High 8 PC/2 tactile. Pression GPU 1 :
   quotas divisés par 2 ; pression 2 : aucune nouvelle sculpture.
   Ce sont des maxima conditionnels, pas une mesure en session.
6. Mesure : `LocalOriginalPlatformRimDeckCount` signale le nombre
   de decks avec maillage réellement monté et
   `LocalBevelNativePartsReplaced` le nombre total de bordures
   effectivement masquées, incluant les autres systèmes existants.

## Procédure de validation avant publication

- Exécuter `tools/audit_visual_structure_sources.py`,
  `tools/verify_original_3d_budget_census.py` et
  `tools/verify_public_release_registry.py` à l'identique sur le SHA final.
- Exécuter le Build Validation Rojo/Luau et la suite Lest
  `native-premium-fallback.spec.luau` dans un **vrai moteur Roblox**.
- Contrôler le compteur de remplacements avec une arène réelle 8 joueurs
  et vérifier les plateformes de 17×10 et 26×8 dans les cinq variantes,
  y compris à la disparition et au rétrécissement.
- Ne pas lancer la publication publique sur une simple source Python
  ou une validation « Approved » d'asset ; conserver le rollback.

## Lot suivant appliqué — supports de plateformes P0

**Situation mesurée par inspection du propriétaire 3D :** `PremiumLargeStructureMeshKit` sélectionnait auparavant des `PlatformSupportN_K` sur la seule base d'une hauteur acceptable. Le vrai installateur exige pourtant un rapport de dimension, une largeur et un facteur d'échelle précis. Des candidats impossibles à monter pouvaient monopoliser une des **8 allocations Medium ou 16 modules High**. De plus, l'authentification du modèle tolérait 1–12 MeshParts, alors que le propriétaire de masquage de la primitive exige strictement des groupes de **7**.

**Corrections appliquées à `main` :**

- Une fonction pure `Kit.supportFit(nativeSize, sourceBounds)` détermine **avant réservation** la validité exacte et le coût d'une colonne originale : 1, 2 ou 3 segments de sept MeshParts selon la hauteur. Le montage utilise la **même** fonction, sans divergence entre le sélecteur et le résultat.
- Les piliers trop étroits et les sources trop petites/grandes sont écartés. Low refuse les supports nécessitant deux/trois segments, car il ne peut dépenser qu'un module. Medium/High conservent leurs plafonds et n'augmentent pas la densité GPU.
- Le modèle source doit appartenir au dossier répliqué attendu, être un véritable paquet de **7 MeshParts** non physiques et ne contenir aucun script. Sans ce paquet complet, le client conserve les supports natifs.
- Le test Roblox `tests/engine/native-premium-fallback.spec.luau` contrôle les coûts 1/2/3 segments et les cas invalides.
- Les vérificateurs statiques `verify_original_3d_budget_census.py` et `verify_platform_trim_mesh_ownership.py` vérifient maintenant le partage du calcul, pas une ancienne chaîne littérale de `if`.

**Critère de sortie de ce lot :** tests moteur Roblox Cloud exact-SHA, deux scripts de régression statique et Build Validation réussis. Aucune publication de la Place ni mesure FPS Android n'est revendiquée avant preuves séparées.

### Suites restantes dans l'ordre

1. Vérifier en session que les supports incompatibles sont rejetés et que les **8/16 modules disponibles** peuvent être consommés par des remplacements admissibles (plutôt que gaspiller des allocations).
2. Couvrir davantage de coques arrière et volumes sous les bâtiments de districts, en conservant portes, lumières, signaux et physics serveur.
3. Mesurer une session Android à huit joueurs : `LocalP4VisibleNativePlatformSupportStructure`, compteurs de mesh résidents, mémoire et FPS pendant shrink et catastrophes.
4. Réserver la publication publique au SHA exact dont le Build et les suites Roblox sont verts.

## Lot P4 suivant — bâtiments premium entièrement sculptés en Medium PC (14 novembre)

**Objectif visuel :** les budgets séparés de façade avant et de coque arrière
n'autorisaient que **5 modèles chacun** en Medium PC. Alors que les
16 bâtiments de chaque arène disposent des quatre profils approuvés
`132020956214241`, `88725004643299`, `84217436280282`,
`135791763112202` et de la coque approuvée
`77387019170428`, une grande partie de l'horizon restait sous forme
de volumes Roblox natifs même sur PC Medium.

**Mise en œuvre :**
- Autoriser jusqu'à **8 façades et 8 coques** authentiques en qualité
  Medium **non tactile** dans la même zone de 205 studs. L'augmentation
  n'affecte pas High (16), Low (1), les collisions ni les sources Roblox.
- Sur Android/tactile Medium, **3 façades et 3 coques maximum** ; sur High
  tactile **8 de chaque** ; sous pression visuelle Medium desktop 1, plafonds
  réduits à 4 ; sous pression 2, **0** avec restauration native. L'algorithme
  exploite uniquement les mêmes cinq vrais modèles approuvés et la même
  cadence LOD que précédemment.
- Capacité nouvelle conditionnelle : **3 bâtiments sculptés complets
  supplémentaires**, donc **15 volumes natifs de cœur/cassette/support
  supplémentaires** masqués via le propriétaire de coque, auxquels
  s'ajoutent les éventuels éléments de toiture redondants déjà masqués
  par les façades. Il s'agit d'un **plafond théorique**, pas d'une mesure
  en session ni d'une promesse de FPS.
- Test moteur : la carte Classic réelle doit présenter 8 coques
  Medium desktop au centre contre 3 sur tactile ; pression 1 desktop 4,
  pression 2 zéro avec réapparition native. Les quotas de façade tactiles
  sont vérifiés dans `native-premium-fallback.spec.luau`.
- Les vérificateurs de régression statique valident les deux plafonds et
  leur limitation tactile inchangée ; tout échec de build ou moteur bloque
  la publication.

**Suites à exécuter :** Build Validation Rojo, recensement P4,
vérification Android, 7 suites Roblox Cloud Engine sur le SHA final.
**Mesures Android** toujours requises avant tout changement de plafond
tactile. Aucun modèle artificiel `Part`/`WedgePart` n'est utilisé comme
remplacement : seules les sources réellement importées font disparaître
les natives.

## Autres chantiers visuels prioritaires

**P0 :** finir les structures de quartiers visibles non couvertes (le
catalogue historique contient 2 248 natives), ensuite les supports de
plateformes (800) et sous-cadres (520). Les lumières et balisages sont
exclus du compteur des structures à masquer lorsqu'ils indiquent un
danger ou une route.

**P1 :** renforcer les textures et normales PBR réellement compatibles
Android, contrôler la lisibilité des chemins, la taille des zones
d'atterrissage, les transitions météo et l'effet des événements
catastrophes sur chaque mesh importé.

**P2 :** polissage des animations, effets d'ambiance et optimisation
visuelle après preuve de stabilité et de fluidité sur smartphone.
