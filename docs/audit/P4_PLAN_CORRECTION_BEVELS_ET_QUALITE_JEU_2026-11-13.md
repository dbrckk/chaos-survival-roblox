# P4 — Plan correctif et amélioration du jeu

Date : 2026-11-13. Branche : `main`. Périmètre : Chaos Survival, cinq variantes d'arène. Statut : correctifs source intégrés, **pas de preuve de publication ni de test Roblox Engine**.

## Diagnostic : pourquoi les bordures restent primitives

1. `MapBuilder.lua` génère par plateforme quatre `PlatformBevelN_1..4` de type `WedgePart` et un `PlatformUnderFrameN`. Ces cinq éléments sont purement cosmétiques ; le vrai `PlatformN` est le colliseur jouable.
2. Les carapaces compactes approuvées couvrent des plateformes de petite empreinte, mais ne doivent pas être étirées artificiellement sur les plateformes de 18–20 studs.
3. La coque grand format approuvée `125929150866282` n'était auparavant admise que pour `Platform1..24` ; la sélection Low était de plus limitée à `N%8==1`.
4. Une sélection initiale de coque pouvait devenir obsolète après streaming, rétrécissement du deck ou changement de taille du modèle ; sans vérification au montage, l'empreinte pouvait être insuffisante.
5. Le recensement de 2 080 bordures couvre cinq cartes distinctes, et non 2 080 éléments simultanément visibles. Il ne mesure pas la qualité effective d'une session.

## Phase 1 — Correction de sûreté visuelle (appliquée)

- [x] Sélection caméra sur tous les indices de plateformes authentiques `1..512`.
- [x] Coque 18 studs limitée à des decks de 16,3–20 studs et à une empreinte de 80–96 % sur X et Z.
- [x] Contrôle de l'empreinte lors de la sélection **et** lors du montage, avant et après `ScaleTo`.
- [x] Validation au montage des quatre WedgeParts natives + sous-cadre complet et non physique ; les modèles non conformes ne remplacent rien.
- [x] Low accepte les plateformes d'index pair et réserve une seule coque partagée.
- [x] Quotas distincts PC/Android et révocation sous pression GPU.
- [x] Rattrapage groupé des pièces natives arrivées tard par streaming.
- [x] Mesure des coques montées et des natives réellement masquées via les attributs locaux existants.
- [x] Assertions de non-régression dans `tools/audit_visual_structure_sources.py`.

## Phase 2 — Remplacer les autres bordures sans géométrie fictive (à réaliser)

1. **Inventorier les empreintes réelles** des decks par variante à l'exécution : dimensions X/Z, orientation, phase, qualité, nombre de `PlatformBevel` et sous-cadres présents, et nombre de modèles approuvés.
2. **Produire des meshes originaux dédiés** aux catégories dominantes de dimensions qui ne correspondent ni à la carapace compacte ni à la coque 18 studs. Conserver la couverture de 80–96 % et une géométrie réellement travaillée.
3. Publier ces modèles sur le compte créateur et attendre la modération Roblox ; mettre à jour `assets/source/roblox-asset-registry.json` et les allowlists. **Ne pas masquer** les primitives avant validation du modèle réel.
4. Ajouter les nouveaux kits au même propriétaire `PlatformNativeTrimReplacementKit` et aux mêmes budgets LOD, sans nouveau poller et sans changer la collision.
5. Mesurer la proportion de primitives masquées **par carte et par qualité** sur des sessions réelles, pas sur la somme des cinq cartes.

## Phase 3 — Qualité du jeu (à réaliser après stabilité)

- **Gameplay** : vérifier qu'un nouveau joueur comprend l'objectif, les dangers, la progression et les interactions joueurs/environnement en moins de 30 secondes.
- **Bots** : observer navigation, sauts, collisions, blocages et reprises après chute sur chaque variante.
- **Lisibilité** : mesurer contraste des plateformes, dangers et itinéraires sur smartphone, de jour/nuit et météo variable.
- **Performances** : mesurer FPS, mémoire et nombre de MeshParts sur Android Low/Medium, puis sur PC High, en présence de 8 participants et en phase de rétrécissement.
- **Robustesse** : tester streaming incomplet, asset non approuvé, suppression d'une soudure, changement de qualité, montée de pression GPU, `CollapsePhase` et `BridgeShutterPhase`.

## Conditions de validation et de livraison

1. Exécuter l'audit source et les vérifications de syntaxe Lua/Luau disponibles.
2. Vérifier dans Roblox Studio : aucun trou visuel, aucune bordure cachée sans coque approuvée, aucun colliseur déplacé, restauration immédiate après disparition du mesh.
3. Comparer les compteurs `LocalOriginalLargeDeckHullMountedCount`, `LocalBevelNativePartsReplaced` et `LocalUnderframeNativePartsReplaced` pour chaque qualité.
4. Mesurer FPS et mémoire sur Android, puis valider les cinq arènes.
5. Publier sur la Place seulement après contrôles ; confirmer le succès réel de la publication.

**Limite actuelle** : GitHub confirme les commits et les contrats statiques, mais ni les FPS, ni le rendu Roblox Engine, ni la publication de la nouvelle version. Ne pas présenter la Phase 2/3 comme achevée.
