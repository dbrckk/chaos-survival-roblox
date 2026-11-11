# P4 — Priorité au sommet 3D de l'arène active

**11 novembre 2026 — modification du chargeur de modèles propriétaires.**
Le commit GitHub servant de base à cette modification est
`e7995187d2bde737da54112c4e1fb34a60c8a029` : **il n'était pas
publié sur Roblox**. La dernière publication publique confirmée
avant ce lot correspond à `7c1f89efabc4a6142cc46c21a9e645e27333dd6f`.
Le changement P4 de ce document a ensuite été fusionné dans `main`
au commit `f3e3f1355a84e5ff4c2de5a75cc23109fa366e20`, sans nouvelle
publication. Les contrôles source ne constituent ni une preuve de
publication Roblox ni une validation de rendu ou de FPS Android.

## Problème identifié dans le code

Les quatre modèles 3D approuvés de sommets de station étaient chargés
à partir de 132 secondes après le démarrage du chargeur, dans
l'ordre fixe **Towers, Orbital, Crossroads, Relay**. Classic et
Harbor partageant `Relay`, leur modèle pouvait arriver après
les trois autres, sans compter les durées réseau et les nouvelles
tentatives. Le remplacement 3D était donc prêt côté client, mais
attendait la présence de son modèle sur le serveur.

## Livraison

- À 60 secondes, choisir **une seule source** sur la base de
  `workspace.GeneratedMap.Arena.VariantId`, en vérifiant
  que la carte et l'arène appartiennent bien à Workspace.
- Pour **Classic/Harbor**, choisir le modèle Relay original
  `110237986522853`. Pour Towers, Orbital et Crossroads,
  utiliser leurs propres modèles approuvés respectivement
  `131413152501235`, `131188899020391` et `134533469777794`.
- Préserver le début de chargement des autres modèles à
  **132 secondes depuis le lancement du chargeur** et conserver
  le délai de 5 secondes entre imports tardifs.
- Si l'arène active a changé au second créneau, favoriser cette
  nouvelle arène avant de finir les sources restantes.
- Conserver la limite de **trois tentatives par modèle**, même
  si l'import anticipé échoue, en mémorisant les IDs déjà tentés.
- Garder un seul worker `task.spawn` et le
  `PremiumApprovedAssetImportGate` global, limitant à **deux**
  les demandes AssetService simultanées.

La source est encore facultative. Un service réseau lent ou une file
globale occupée peut repousser le modèle après le seuil de 60 secondes.
Le jeu ne bloque ni ses rounds, ni les bots, ni son environnement
natif dans cette attente.

Les cinq cartes et les deux primitives par sommet restent
**identiques**. Aucun nouveau MeshPart, ID Roblox, texture,
collision, effet, RemoteEvent ou boucle par image n'est introduit.

## Vérifications

Le contrat source préexistant
`tools/verify_premium_approved_asset_import_queue.py`
surveille l'identité de l'arène, les deux créneaux, l'unicité des
tentatives et la file globale. Avant une nouvelle publication publique,
Build Validation et Roblox Open Cloud Engine Tests devront être
exécutés sur le SHA exact de `main`, puis le rendu et les FPS réels
sur Android devront être contrôlés.
