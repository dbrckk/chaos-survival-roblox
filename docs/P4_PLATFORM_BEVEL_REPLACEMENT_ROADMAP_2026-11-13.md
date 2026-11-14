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

## Lot du 14 novembre — densité des vraies sculptures P4 hors Android

**Problème identifié sur les propriétaires réels :** les modèles de
sculpture approuvés ACCESS/TRANSFER/SUMMIT, Casing et Helix possèdent
déjà leur géométrie originale complète (sept `MeshPart`/source), mais
leurs budgets PC bloquaient encore de nombreux propriétaires physiques
valides. En particulier les 12 arches d'accès des quatre routes
périmétriques et les quatre casings par arène n'étaient pas tous
éligibles en Medium PC, et six des huit rampes Orbital pouvaient
rester primitives en Medium.

**Lot réellement intégré dans `ApprovedRemainingStructureMeshKit.lua` :**

| Résidence de vrais modèles approuvés | Low | Medium PC | High PC | Medium tactile | High tactile |
|---|---:|---:|---:|---:|---:|
| Arches d'ascension | 1 | **6** (avant 3) | **10** (avant 6) | 2 | 3 |
| Carapaces de colonnes | 1 | **4** (avant 2) | 4 | 1 | 2 |
| Structures sous rampes Orbital | 0 | **4** (avant 2) | **8** (avant 6) | 1 | 3 |

- Les plafonds sont des **maxima de sources pouvant être montées**, pas
  des objets 3D constatés en session. Il faut toujours que les pièces
  non physiques natives, les colliders, les dimensions approuvées,
  la caméra, le streaming et les états de catastrophe soient valides.
- Par rapport aux plafonds précédents, Medium PC peut masquer jusqu'à
  **45 volumes natifs supplémentaires** (3 arches × 5, 2 casings × 11,
  2 sous-rampes × 4), et High PC **28 supplémentaires** (4 arches × 5,
  2 sous-rampes × 4) dans une carte pouvant accueillir ces modèles.
  Le véritable total côté client est publié par
  `LocalP4RemainingStructuralNativePiecesReplaced`.
- Les **plafonds Android restent identiques** et toute pression GPU de
  niveau 1 conserve explicitement les ANCIENS plafonds d'urgence :
  Medium PC (1/1/1), High PC (3/2/3), sans gonfler le mode stress.
  Au niveau 2, toutes les natives sont restaurées. Les anciens
  colliders, lumières de route et signaux de danger restent intacts.
- La répartition des sources sur les quatre routes physiques et les
  trois stades ACCESS/TRANSFER/SUMMIT s'applique désormais aussi à
  Medium PC sain, et toujours à High PC. Les autres clients
  conservent leur sélection locale proche caméra.
- Aucun nouveau modèle Roblox, timer de rendu, requête réseau, route
  physique, objet dynamique de collision ni nouveau budget PBR n'a
  été créé ; les tests Lest/Roblox Cloud vérifient explicitement
  les quotas sains, tactiles, et sous pression.

**Validation attendue sur le SHA exact :** recensement de source
`audit_visual_structure_sources.py`, budget
`verify_original_3d_budget_census.py`, Build Validation et les
sept suites Roblox Cloud Engine ; la publication publique ne doit
pas être couplée au workflow de validation.

## Lot 14 novembre — coût exact des supports 3D par route

Le recensement des supports existants a mis en évidence un écart entre
**la sélection caméra** et **le montage réel** : un pilier natif haut
consomme 2 ou 3 modules authentiques de sept `MeshPart`, mais la
sélection comptait un emplacement par plateforme, avec au plus un
coût minimal arbitraire. Sur High PC, la conversion facultative de
quatre modules de colonnes en berceaux LongCradle n'était pas non
plus prise en compte lors du choix des supports. Certains supports
étaient donc sélectionnés sans capacité effective de montage ;
leurs gros volumes primitifs restaient visibles.

**Correction sur les modèles approuvés déjà présents :**

- Grouper les vrais `PlatformSupportN_x` éligibles, les trier **dans
  le même ordre lexical que le monteur**, puis additionner leurs coûts
  vérifiés par `supportFit` (un sur Medium/Low, deux sur High).
- Le sélecteur spatial continue à privilégier les premiers plans, puis
  la diversité géographique de la carte, **mais exclut les plateformes
  dont les modules ne tiennent plus dans le solde**.
- Medium : 8 modules maximum, High : 16 modules moins les quatre
  éventuels transferts vers LongCradle, Low : un seul modèle ou aucun
  si un berceau occupe déjà son slot. **Aucun budget Android, MeshPart,
  asset 3D ou boucle de rendu n'est ajouté.**
- Un test Roblox Engine utilise les supports natifs générés par
  `MapBuilder` sur Crossroads. Il calcule séparément le total de
  modules des plateformes effectivement sélectionnées et garantit
  `Medium <= 8`, `High <= 16 - transfert`, sans se contenter
  du nombre de plateformes sélectionnées.
- Les contrôles statiques de budget et de propriété source vérifient
  l'ordre réel, le coût par support et le plafond après transfert ;
  toute régression bloque le contrôle de publication.

**À mesurer en client Android/PC :** nombre de piliers primitifs
encore visibles par caméra, modules authentiques réellement montés,
FPS p50/p95 et latence de reconstruction du propriétaire de plateforme.
La baisse effective de blocs visibles n'est pas quantifiée sans
échantillonnage client.

## Lot P4 — diffusion des vraies bordures 3D sur la carte entière (14 novembre)

**Défaut du propriétaire constaté :** `ApprovedPlatformRimMeshKit.selectVisibleDecks`
consommait systématiquement ses 4 résidences Medium PC ou 8 résidences
High PC sur les plateformes **les plus proches les unes des autres**.
Une première promenade fortement détaillée pouvait côtoyer une seconde
section du même champ de vision encore en `WedgePart`, bien que les deux
modèles `Rect` (131482590870627) et `Long` (127617571835277)
soient approuvés et source-vérifiés.

**Implémentation :**

- **Medium PC, sans pression :** garder les **2** plateformes authentiques
  les plus proches puis attribuer les **2** résidences restantes aux
  plateformes éligibles les plus spatialement distinctes de cette carte.
- **High PC, sans pression :** garder les **3** premières sources de
  premier plan, répartir les **5** restantes sur les autres secteurs
  éligibles. Une pénalité de distance caméra préserve la visibilité
  effective : aucun modèle n'est placé hors de la zone LOD ni sur une
  plateforme dangereuse, non répliquée ou déjà habillée.
- **Android/Touch, Low et pression GPU > 0 :** conserver exactement
  l'ancien choix des plateformes les plus proches et **les plafonds
  identiques** (Medium tactile 1, High tactile 2 ; pression 2 zéro).
- L'authentification coûteuse des deux `Model:GetBoundingBox` et sept
  régions `MeshPart` par source n'est effectuée **qu'une fois par
  reconstruction**, et non une fois pour chaque plateforme de la carte.
  `install` vérifie néanmoins de nouveau l'asset au moment réel du
  montage ; aucune source devenue invalide ne peut masquer les quatre
  biseaux natifs.
- **Aucun ajout de MeshPart, Part, AssetId, RenderStepped, Heartbeat,
  appel réseau, collider ou budget GPU.** Une résidence continue à
  remplacer précisément les **4 WedgePart** d'un deck. Les
  `PlatformUnderFrame`, signaux et vraies pièces de collision restent.
- Fixture Roblox Engine : 12 vrais colliders de deck avec chacun
  4 biseaux de repli, distribués sur les quatre quadrants d'une
  base 320 × 320. Le test exige 4 résidences Medium PC dont au moins
  2 éloignées, 8 High PC dont au moins 3 éloignées ; Android High et
  PC sous pression continuent à choisir leurs sources locales.
  La révocation d'une source `Rect` et sa restauration lors du prochain
  appel sont également couvertes.

**Indicateur existant :** `LocalOriginalPlatformRimDeckCount`
mesure les sources réellement montées ; les biseaux primitifs
effectivement masqués sont comptés par
`PlatformNativeTrimReplacementKit.breakdown().bevel`.
Ces chiffres et la mesure FPS Android doivent être relevés en session
avant d'affirmer un pourcentage de conversion ou un gain GPU.

## Lot P4 — underdeck 18 studs sculptés dans plusieurs secteurs (14 novembre)

**Défaut visuel restant :** le modèle original créateur
`LargeDeckHull` (Roblox Approved **125929150866282**, 7 vrais
`MeshPart`) était déjà importé et son propriétaire pouvait masquer
les **quatre `WedgePart` des bordures** et le sous-cadre natif.
Cependant la sélection PC dépensait toutes ses résidences sur les
premiers decks au plus près de la caméra. Les plateformes collidables
compatibles plus éloignées restaient primitives, malgré le modèle
approuvé et une zone LOD encore valide.

**Amélioration effective :**
- Medium PC, sans pression GPU : conserver les **2** plus proches puis
  choisir **1** vraie plateforme éloignée suivant l'écart spatial.
  Plafond inchangé **3** coques approuvées.
- High PC, sans pression : conserver les **3** plus proches puis
  répartir **3** autres modèles sur des zones distantes de la même
  carte 320×320. Plafond inchangé **6** coques approuvées.
- Android/Touch conserve **1 Medium / 3 High** coques maximum ;
  pression GPU 1 réduit les plafonds de moitié et conserve le tri
  proximité, pression 2 restaure les primitives ; Low inchangé.
- Pour chaque deck éligible, maintenir l'exigence d'un collidant
  `PlatformN` authentique, des quatre bordures et du
  `PlatformUnderFrame` complets, d'un ajustement de géométrie
  approuvé et d'une empreinte stable. L'installation réauthentifie
  encore la source et chaque pièce native au moment du montage.
- Aucun nouvel asset, aucune primitive de remplacement fictive,
  aucune collision ni nouvelle boucle de rendu : seulement
  l'allocation spatiale des **mêmes 3/6 modèles** précédemment
  autorisés. Les formes natives restent en place pour restaurer
  immédiatement la scène.
- Le test `platform-rim-original-3d.spec.luau` contient désormais
  **12 decks collidables** et leurs vrais quatre `WedgePart` de
  repli. Il vérifie la répartition PC, les caps Android et sous
  pression, le montage de sept `MeshPart`, et le refus d'un montage
  si une bordure native disparaît ou si l'asset est révoqué.
  L'audit statique exige explicitement la logique spatiale.
- L'impact perçu et les FPS n'ont pas été mesurés en session réelle ;
  les gains de silhouettes restent conditionnés à la présence des
  plateformes éligibles et des modèles de source streamés.

## Lot P4 — huit vrais bâtiments 3D entiers en Medium PC (14 novembre)

**Défaut visuel observé dans les propriétaires :** le même quartier
possède une façade créateur approuvée
(`PremiumDistrictFacadeMeshKit`) et une vraie coque arrière/latérale
6-`MeshPart` (`ApprovedDistrictSidewallMeshKit`). En Medium PC,
les plafonds étaient déjà **8/8**, mais leurs classements propres
pouvaient consacrer les huit façades et huit coques à des bâtiments
**différents**. Dans les plans larges, ces demi-silhouettes semblaient
toujours constituées de volumes de base.

**Implémentation sans augmenter les quotas :**

- Lors d'un échantillon **Medium PC sain**, garder **3 façades proches**,
  puis distribuer les **5 façades restantes** sur des secteurs visibles
  distincts parmi les 16 vrais bâtiments de la carte. La source, le
  profil original, la porte, la distance 205 studs et la caméra
  conservent leurs vérifications ; chaque modèle est toujours
  directement un modèle original approuvé (4 profils Roblox connus).
- Le propriétaire des coques est appelé **après** celui des façades dans
  la même passe de `scenery-lod.client.lua`. Il sélectionne en premier
  les bâtiments disposant d'une **façade effectivement montée**,
  puis utilise ses éventuels slots restants pour d'autres bâtiments
  admissibles. La petite bonification numérique antérieure ne
  garantissait pas ce résultat lorsque la façade était distante.
- Ce couplage est **exclusivement Medium, non tactile, pression 0**.
  Low conserve le besoin strict d'une façade, High garde les
  16 modèles de chaque famille, Android garde Medium **3/3** et High
  **8/8**, et les niveaux de pression GPU continuent à réduire ou
  évacuer immédiatement les vrais modèles.
- Aucun nouvel `MeshPart`, `Part`, collider, AssetId, script de
  rendu ni budget GPU. Une coque remplace toujours exactement
  **5 volumes primitifs authentiques**. Les portes, fenêtres,
  fondations, balises et collisions restent non masquées.
- Test Roblox Engine sur une vraie carte `Classic` de
  `MapBuilder` à 16 bâtiments, avec les **4 sources de façade
  authentifiées et la coque approuvée** sous forme de fixtures.
  Il exige **8 façades + 8 coques réellement montées sur les mêmes
  bâtiments**, soit 40 volumes latéraux natifs masqués,
  une diffusion sur au moins 3 secteurs, et la baisse à 3/3 sur
  Android puis à zéro sous pression 2. La source réelle des
  AssetId reste validée séparément par le registre d'assets.
- L'indicateur déjà existant `LocalCompleteDistrict3DCount`
  mesure l'évolution **en session** sans transformer le recensement
  historique des primitives serveur en taux de conversion fictif.

**Prochaine étape terrain :** comparer les captures et FPS
sur PC Medium/High et Android Medium, puis traiter les supports
d'architecture non couverts qui possèdent une source réellement
approuvée. Sans métriques client, aucune amélioration de FPS
ou conversion à 100 % n'est revendiquée.

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
