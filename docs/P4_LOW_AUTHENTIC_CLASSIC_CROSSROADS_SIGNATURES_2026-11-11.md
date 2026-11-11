# P4 — Grandes structures originales sur Android Low

11 novembre 2026. L'amélioration est fondée sur le code GitHub au
commit `e6b05dbb77511b810cb3ebc4dbe5d591335acdd7`. Elle ne constitue pas une publication du jeu.

## Structures primitives encore visibles

La carte **Classic** affichait cinq grandes pièces natives non
physiques, deux contreforts, deux barres inclinées et un panneau
de l'observatoire, même lorsque son modèle sculpté à sept
MeshParts `91717127334369` était disponible. Sur **Crossroads**,
quatre dalles/poutres natives du grand échangeur restaient à la
place du modèle original à sept MeshParts `96622579843060`.
Ces deux sources sont déjà modérées `Approved` dans le registre.

## Remplacements de proximité

| Variante | Low avant | Low après | Rayon |
| --- | --- | --- | --- |
| Classic | 0 | 1 vrai monument remplaçant 5 Parts | 320 studs |
| Crossroads | 0 | 1 vrai échangeur remplaçant 4 primitives | 320 studs |

Les profils Medium/High ne changent pas. Comme la carte active
est unique, au plus **sept MeshParts** sont ajoutées par cette
opération sur Low, dont les primitives correspondantes sont
masquées. Les neuf formes citées correspondent aux deux arènes
possibles, **jamais neuf natives simultanément**.

Les modèles restent entièrement non physiques, validés par
identité de la carte, géométrie et source approuvée. Les
collisions, routes, antennes, bots et warnings restent en
place. Le premier palier de pression sur Low force déjà le
retour immédiat des natives ; le second également. Les dossiers
sont inclus dans le quota partagé `VisualBudgetRules.LocalFolders`.
Aucune nouvelle texture, modèle, boucle ou requête client.

Le modèle Classic complémentaire, auparavant demandé à partir
de 119 s, est désormais priorisé dès **56 secondes quand Classic
est la carte active**, via le helper événementiel existant.
Le modèle Crossroads bénéficie déjà de sa priorité active à 19 s.
Les imports restent soumis à la file globale de deux appels
maximum et à trois tentatives par source ; aucune arrivée à un
instant précis n'est garantie.

## Validation

Le script `tools/verify_active_variant_signature_schedule.py`
préexistant vérifie ces budgets, la restauration native et les
identifiants Roblox approuvés. Son workflow suit maintenant
directement les fichiers concernés. Ce n'est ni une mesure FPS
sur Android ni une preuve de rendu 3D en Studio.

Pour une publication : exécuter Build Validation, tests Roblox
Engine et le workflow de Place sur le même SHA de `main`.
