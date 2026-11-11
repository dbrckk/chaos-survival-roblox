# P4 — Remplacement des trappes natives au premier plan

**11 novembre 2026 — source, non publiée dans Roblox.**

## Défaut observé

`PlatformFinishKit.originalServiceHatch` chargeait l'un des cinq
vrais modèles de relief métalliques déjà approuvés, mais uniquement pour
les plateformes d'indice `1 modulo 9` en High ou `1 modulo 18` en
Medium. Les autres plateformes dont l'indice vaut `1 modulo 3`
gardent trois Parts de trappe natives. Le contenu à l'écran et le trajet
réel du joueur ne participaient pas à cette sélection.

## Correction

- Un recensement dans **le rebuild existant de l'arène**, sans tâche
  ni boucle supplémentaire, évalue uniquement les plateformes
  `PlatformN` existantes, sûres et équipées d'une trappe native.
- Le **quota exact** reste égal au nombre de plateformes saines et
  compatibles sur lesquelles l'ancienne règle aurait monté un Model.
  Les templates absents/incomplets ne réservent pas de quota.
- Les modèles sont sélectionnés selon la distance et l'orientation de
  la caméra, avec une faible préférence pour les éléments visibles
  devant le joueur. Aucun traitement de visibilité par raycast.
- Le montage garde les cinq `Original3DAssetId` préexistants et
  vérifie le dossier `OwnerVerified`, le Model créateur original et
  ses véritables MeshParts non physiques avant tout clone.
- Une trappe source remplace les **trois éléments natifs** exactement
  comme auparavant ; les plateformes non choisies gardent leur fallback.
  Aucun modèle supplémentaire n'est créé sur Low.
- Les soudures, le nettoyage de la carte et le rétrécissement utilisent
  les mêmes propriétaires existants. Le changement de grand secteur
  déclenche déjà `LocalPremiumNearFieldEpoch`, donc le classement se
  met à jour sans échantillonneur supplémentaire.

## Mesure et acceptation

Le nombre maximal de vrais Models ne doit pas augmenter par rapport
à l'ancien `1/9` High ou `1/18` Medium sur la même carte chargée.
Les signaux `CollapsePhase`/`BridgeShutterPhase` continuent de
désactiver les cosmétiques immédiatement. La sélection dépend de l'état
des plateformes effectivement répliquées au client.

**Non vérifié pour publication :** Build Validation sur SHA exact,
Roblox Engine, rendu d'une vraie carte sur Android et cadence mémoire/GPU.
