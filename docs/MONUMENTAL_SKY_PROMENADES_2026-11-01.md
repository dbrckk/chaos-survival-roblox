# Chaos Survival — deux viaducs monumentaux réellement jouables par arène

**Date :** 1er novembre 2026. **Statut :** source candidate sur GitHub, non publiée et non certifiée en jeu. Conformément aux règles du dépôt, aucune suite de tests n'est lancée pendant ce lot de création ; le jalon de validation majeur sera exécuté avant une éventuelle mise en ligne.

## Problème résolu en conception

Chacune des cinq arènes possède une base de 320 × 320 studs, quatre montées de périphérie et quatre belvédères latéraux physiquement accessibles, mais ces derniers se terminent en impasse. Le ciel et les zones de combats périphériques ne possèdent pas de traversée haute continue. Les gros aéronefs du lot #534 restent volontairement cosmétiques ; ils ne peuvent remplacer une nouvelle boucle de parkour réelle.

## Transformation majeure

- **Deux longues traversées aériennes**, nord et sud, par carte, chacune connectant deux anciens belvédères `BranchStep=4` de même altitude.
- **8 plateformes avec collision serveur** par traversée, soit **16 decks additionnels par arène**, **80 sur l'ensemble des cinq variantes** de carte (une seule arène instanciée à la fois).
- Franchissement par de véritables **sauts R15 ordinaires** : les centres sont répartis sur les huit segments d'un span proche de 200–220 studs. Chaque section mesure `espacement - 2,4` studs en longueur et laisse **exactement 2,4 studs de vide** entre deux decks voisins. Les plateformes d'extrémité se superposent en plan aux véritables belvédères, avec le même sommet. Aucun boost, équipement ou téléporteur n'est requis.
- Les nouveaux decks sont **2 studs d'épaisseur**, placés à la hauteur des belvédères. Ils ne forment pas une muraille de 30 studs de haut qui bloquerait les parcours de fuite au niveau du sol.
- **Six arches monumentales 3D par carte**, trois par viaduc, construites en vrais volumes natifs Roblox : portiques métalliques, piliers, tirants et sous-structures. Équipements sculptés propres à chaque univers :
  - Classic : antennes de surveillance et radars
  - Towers : ponts de levage et cabines de maintenance
  - Crossroads : signalisation d'aiguillage et structures de transit
  - Orbital : noyaux et ailettes de confinement
  - Harbor : grues, chaînes et charges suspendues
- Les arches ne créent **aucune collision, touche, raycast ou fausse plateforme** ; leurs pieds sont visuellement de part et d'autre de la zone de saut, avec de la place au-dessus de la silhouette R15. Aucun modèle externe, achats, nouveaux RemoteEvents, boucles ou lumières.

## Compatibilité avec le jeu existant

- Le catalogue `ArenaVariants` est généré depuis les **quatre vrais sommets** existants, sans coordonnées codées en dur différentes selon la carte. Les 16 decks sont ajoutés **après tous les anciens indices** (Harbor `SkywayPlatforms` et `SpokePlatforms` compris).
- Toutes les nouvelles géométries passent par `MapBuilder` et le dossier serveur `Arena/Platforms`. Les bots, capteurs de hauteur, caméra de réception et catastrophes peuvent donc inspecter de **vrais BaseParts** et non des proxies visuels.
- Les nouveaux decks ont `RouteTier=4`, `PromenadeLane`, `PromenadeStep`, `ChaosPermanentRoute=true`. Ce dernier attribut les exclut du tirage de `DisappearingPlatforms` : une route longue n'est jamais coupée arbitrairement au milieu. **Ne pas mettre** `ChaosSkybridge=true` : ce marqueur appartient à l'ancienne mécanique des quatre ponts de Towers.
- En `ShrinkingArena`, les decks sont déplacés et leurs dimensions X/Z réduites par le propriétaire existant (grâce à `RouteTier`). Les arches possèdent `PerimeterPlatformIndex` et le système existant les déplace/réduit **avec leurs decks physiques**, sans art flottant après rétrécissement.
- Aucune modification des 8 spawns, places humaines, IA, boutons Android, dégâts, monnaie, sauvegarde, progression ou durée des manches.
- `MapBuilder` appelle `PromenadeArchitecture.decorate` uniquement pour les 6 plateformes marquées (steps 2/4/7) ; chaque arche comporte au maximum 9 Parts purement décoratives. **54 Parts décoratives maximum** par carte pour l'architecture supplémentaire, en plus des 16 colliders et des finitions des decks déjà gérées par MapBuilder.

## Pièces modifiées

- `src/server/ArenaVariants.lua` : génération géométrique paramétrique.
- `src/server/MapBuilder.lua` : installation des seize decks serveur, métadonnées et équipements 3D.
- `src/server/PromenadeArchitecture.lua` : ensemble architectural natif modulable par univers.
- `src/server/Disasters/DisappearingPlatforms.lua` : protection équitable contre les effondrements aléatoires.
- Spécifications moteur **existantes** `mapbuilder.spec.luau` et `mapbuilder-advanced.spec.luau` mises à jour pour conserver les attentes de nombre de decks et de tier 4 ; **pas de nouveaux tests unitaires**.

## Validation unique avant publication majeure

1. `Build Validation` et **5 suites Roblox Open Cloud Engine Tests** sur le même SHA, sans retirer ni masquer les assertions historiques. La moindre erreur bloque la publication.
2. Avec Studio authentifié, faire une partie sur chacune des **5 cartes** : réellement monter par `PerimeterRoute` jusqu'à `BranchStep=4`, effectuer les **8 traversées de saut** sans boost et atteindre l'autre côté. Vérifier les collisions R6/R15, les spawn clearances, la lisibilité des grands portiques, le coût réseau et la protection des vrais dangers.
3. Vérifier `DisappearingPlatforms` et `ShrinkingArena` avec au moins 2 joueurs humains et 6 bots : les traversées doivent rester praticables/visuellement cohérentes, aucun décolement d'arches. Capturer **15 images réelles par arène** si le runner est disponible.
4. Sur Android Low/Medium : viser une expérience fluide pendant une partie complète avec 7 bots (FPS, p95 frame time, thermique, mémoire). Si le rendu tombe sous les cibles sur appareil modeste, optimiser les arcs et les panneaux cosmétiques **avant** publication, jamais la collision serveur ou les avertissements vitaux.
5. Contrôler la fin de manche, la prochaine manche, les récompenses et la fiabilité des cinq rotations ; conserver le rollback de la dernière publication certifiée.

**Ne pas confondre** intégration du code sur `main`, Build Validation, test moteur authentique, captures Android et publication de l'expérience publique. Seule une publication authentifiée du SHA validé mettra ces nouveaux viaducs en ligne.
