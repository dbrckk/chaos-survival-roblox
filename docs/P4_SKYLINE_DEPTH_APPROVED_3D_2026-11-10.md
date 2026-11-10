# P4 — Horizon lointain : 3D approuvée sur SkylineDepth

10 novembre 2026. Lot P4 après couverture des crêtes extérieures (12/12
WedgeParts éligibles) et du monument sud (73/73 formes source éligibles).

## Modification effective dans le code

- Le générateur existant `MapBuilder.addDistantSkyline` produit toujours
  huit `SkylineDepth{direction}{layer}` par variante ; chaque modèle contient
  `DistantRoofMass` (WedgePart) et `DistantAerial` (Part).
- Le nouveau kit client `ApprovedSkylineDepthMeshKit`, branché sur
  **l'échantillonnage existant** `scenery-lod.client.lua`, utilise les
  vrais Models 3D originaux déjà importés et **Moderation: Approved** :
  `exterior_tower_27` = `97864559770371`,
  `exterior_tower_30` = `112172520488996`.
- Seules les **huit masses `DistantRoofMass` par variante** sont
  candidates à une substitution par sept MeshParts approuvées,
  géométrie repositionnée et mise à l'échelle uniformément, sans nouvel
  import ni nouvel appel AssetService côté client.
- `DistantAerial` demeure native : signal géométrique distinct et non
  compté comme remplacé. Les variantes utilisent chacune des positions
  et hauteurs de bâtiments différentes.
- Les gardes valident le vrai dossier `GeneratedMap/Arena/Decor`, la
  variante, les huit positions/tailles/orientations de génération, la
  source Roblox approuvée, les MeshParts sans collision et les
  valeurs de transparence. Toute disparition de source, mutation de
  structure, streaming ou changement de carte restaure les wedges.
- **Low : 0**, **Medium : 2**, **High Android : 3**,
  **High PC : 4** sculptures simultanées maximum ; pression GPU
  intermédiaire réduit de moitié, pression forte remet 100 % des
  wedges natifs. Aucun RenderStepped supplémentaire.
- Compteurs client : `LocalApprovedSkylineDepthModelCount` et
  `LocalSkylineDepthPrimitivesReplaced` indiquent les instances
  effectivement montées, pas les objets théoriquement compatibles.

## Limites et prochaine étape

Ce lot offre **8 nouvelles cibles-source éligibles par variante**,
non pas 8 objets affichés sur tous les appareils simultanément.
Les quatre `SkylineStructure` primaires par carte, les huit
`DistantAerial`, les `addVariantLandmarks` et leurs supports
restent à auditer. Le modèle de tour est volontairement réutilisé
à court terme : un sculpt original spécifique `SkylineDepth`
augmenterait encore la diversité architecturale.

La compilation/tests source doivent être vérifiés par GitHub Actions.
Les **tests Roblox Studio, images réelles sur Android et FPS** ne sont
pas effectués ici ; aucune mise à jour de la Place publique n'est
déclarée. Le pourcentage de couverture global du jeu demeure inconnu.
