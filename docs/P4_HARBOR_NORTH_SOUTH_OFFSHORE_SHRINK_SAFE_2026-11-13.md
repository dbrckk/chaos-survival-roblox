# P4 — Harbor : préserver les monuments 3D nord et sud pendant Shrinking Arena

**13 novembre 2026 — changements de code sur `main` ; non assimilables à une publication Roblox.**

## Problème vérifié dans les sources

Deux monuments extérieurs du vrai `MapBuilder` disposaient déjà d'un modèle original approuvé sur Android Low sain :

- **Mégagrue industrielle nord** : `ApprovedHarborSignatureGantryMeshKit.lua`, asset original approuvé `124368710235343`, **7 MeshParts** à la place de **3 gros Part primitifs** parmi le port industriel. Sélection jusqu'à **290 studs** sur Low et retour aux natives dès la pression graphique 1.
- **Chantier naval / lightship sud** : `ApprovedSouthHarborDrydockMeshKit.lua`, asset original approuvé `125428569657840`, **7 MeshParts** à la place de **14 Part/WedgePart** de la silhouette native. Sélection jusqu'à **290 studs** sur Low et restauration à pression 1.

Les deux kits refusaient tout `base.Size.X/Z < 318` puis positionnaient leur landmark en fonction de `base.Size.X/Z`. Or `Shrinking Arena` rétrécit uniquement la vraie plate-forme jouable : les monuments nord et sud, créés *hors* arène par le serveur, ne se déplacent pas. Après rétrécissement, leur modèle authentique était démonté, remplacé par les blocs natifs et ne pouvait pas se remonter avant une manche suivante.

## Modifications

1. Deux nouvelles validations `authenticBase(base,arena)` vérifient la **vraie base**, son ancrage, sa collision, sa parenté, ses dimensions initiales `OriginalSizeX/Z >= 318`, des dimensions actuelles positives et aucune expansion au-delà de l'original `+0.2`.
2. La mégagrue vérifie la position exacte de sa traverse par rapport au **`OriginalSizeX/Z`**, non à la taille rétrécissante.
3. Le chantier sud reconstitue le cadre des **14 natives et leurs orientations** par rapport aux **`OriginalSizeX/Z`**, sans desserrer aucune des vérifications de taille, de classe ou de collision.
4. Les connexions `Base.Size`, `CanCollide` et `AncestryChanged` n'ordonnent plus un démontage à chaque vrai rétrécissement : un plancher agrandi artificiellement, orphelin ou non collidable déclenche toujours le retour au décor natif.
5. Aucun nouvel asset, aucune pièce physique, collision, source non approuvée, appel réseau ou boucle `RenderStepped`. L'import s'appuie sur la file existante à deux requêtes max ; les **14 MeshParts au total** sont déjà recensées dans le budget visuel partagé `VisualBudgetRules`.

## Vérification

- Le test existant `tests/engine/native-premium-fallback.spec.luau` monte les deux modèles sur la **vraie carte Harbor générée par `MapBuilder.buildArena`**. Seuls les MeshParts du modèle distant sont des fixtures locales de test, nécessaires pour éviter toute dépendance au réseau Roblox. Il valide 3 et 14 primitives natives remplacées, rétrécissement `320 -> 170/174`, position fixe, pression 1, remonte à pression 0 et refus d'un plancher de 330 studs.
- Le script de régression déjà existant `tools/verify_south_harbor_drydock_fallback.py` protège désormais **les deux** monuments : type et modération des assets, coordonnées originales, repli sous pression, aucune boucle de rendu nouvelle. Son workflow GitHub écoute également la modification du kit nord.
- Les tests source/build sont distincts des tests Roblox Engine et des mesures sur un véritable Android Low. Les mesures FPS/p95 et les captures visuelles doivent encore être réalisées en session de jeu.

**Validation vérifiée :** le build `43393896388` a réussi sur `01b777149613dab153a68eafc1d71e8350c46f25` ; les contrôles de source `43390879655` ont réussi. La campagne Roblox Engine correspondante, [43393981069](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43393981069), a **réussi les sept suites** sur le commit `01b777149613dab153a68eafc1d71e8350c46f25`. La première fixture moteur avait modifié par erreur la hauteur de `Base` ; la fixture validée conserve exactement `base.Size.Y`, comme le vrai Shrinking Arena. Ces contrôles n'attestent ni des FPS sur Android réel, ni de la publication Roblox.
