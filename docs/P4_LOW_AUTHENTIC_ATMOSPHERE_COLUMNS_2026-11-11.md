# P4 — Une colonne atmosphérique authentique sur Android Low

11 novembre 2026. Lot additionnel à la substitution atmosphérique existante.

## Constat vérifié dans le code
`ApprovedAtmosphereColumnsMeshKit.lua` possède déjà cinq modèles
originaux créateur-approuvés (Classic, Towers, Crossroads, Orbital,
Harbor), chacun composé de sept MeshParts, avec huit corps
de piliers/silhouettes éligibles par carte. La qualité Low
interdisait entièrement ces sculptures (`cap=0`).

## Modification ciblée
- Low autorise **un seul** corps 3D à 175 studs, choisi par distance
  à la caméra parmi les quatre piliers et quatre silhouettes.
- Pression graphique ≥1 : budget Low = 0 et restitution immédiate
  de la Part native. Medium/High conservent leurs plafonds et leur
  logique existante.
- Le kit ne change ni les lumières, ni les caps de balisage, ni les
  deux bandes des silhouettes, ni le périmètre, ni les collisions.
- En cas de suppression d'un clone 3D par un autre propriétaire
  du budget local, `bucket.ChildRemoved` déclenche la restauration
  de la primitive d'origine sans attendre la prochaine cadence LOD.
  Le gestionnaire se déconnecte proprement des observateurs par
  `remove` ; aucune nouvelle boucle, RemoteEvent, source Roblox
  ou requête AssetService.
- Le nouveau modèle potentiel est **déjà compté** dans
  `VisualBudgetRules.LocalFolders` via
  `ApprovedAtmosphereColumnsLocal`. Aucune double comptabilisation.

## Limites
Ce lot remplace potentiellement **une primitive par sept MeshParts**
sur Low : l'intérêt est la **qualité d'une sculpture proche**,
pas une réduction du nombre de triangles ou d'instances.
Le budget existant peut refuser le modèle et revenir à la primitive.
L'intégration GitHub et la CI source ne certifient pas
le rendu Roblox Engine, les FPS Android ni la publication de la Place.
