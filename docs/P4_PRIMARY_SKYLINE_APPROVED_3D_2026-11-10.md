# P4 — Remplacement 3D de la première ligne d'horizon

10 novembre 2026 — modification du code du jeu sans changer les collisions.

## Périmètre exact

`MapBuilder.addDistantSkyline` construit, pour chacune des cinq
variantes, **quatre** modèles `SkylineStructureNorth/East/South/West`.
Le kit `ApprovedPrimarySkylineMeshKit` permet de substituer dans chacun
les quatre éléments natifs `StructuralCore`, `TopCap`,
`OuterRibL`, `OuterRibR` par une sculpture 3D originale à sept
MeshParts, dont le propriétaire et l'import sont déjà confirmés.

Les quatre assets réutilisés dans le registre de l'expérience :
`exterior_tower_21` (137744886537150),
`exterior_tower_24` (74958476744494),
`exterior_tower_27` (97864559770371),
`exterior_tower_30` (112172520488996).
Aucun nouveau MeshId inventé ni nouvelle opération d'import externe.

Sur les cinq variantes, il existe **20 structures cibles source** et
**80 Parts/WedgeParts natives éligibles** (4 × 4 × 5) dans cette seule
famille. Le calcul ne mesure PAS le jeu entier, les plateformes,
les props supplémentaires ou le nombre rendu à un instant donné.

## Sécurité, gameplay et performance

- `Foundation`, `InsetL`, `InsetR`, les antennes et tous les
  signaux de variante restent dans leur forme native.
- Vérification exacte du modèle, de la variante, du parent d'arène,
  de la position/rotation/échelle des morceaux, de la vraie source
  `OwnerVerified`, des sept MeshParts et de l'absence de collision.
- Clonage complet avant de cacher les quatre primitives. En cas
  d'interruption de streaming, de changement de carte ou de corruption
  du modèle : restauration des natives, suppression des 3D locales.
- Les modèles sont sélectionnés à partir de l'échantillonnage LOD
  partagé ; aucun nouveau `RenderStepped` ni requête côté client.
- Budget simultané : Low Android/PC 1 à 315 studs ; Medium Android 1 et PC 2 ;
  High Android 2 et PC 4. Sur Low, ce seul modèle à sept MeshParts
  ne monte que si la source approuvée est prête et proche de la caméra.
  La pression visuelle réduit le budget de
  moitié puis à zéro. Les montages ne changent jamais la physique.
- Les attributs `LocalPrimarySkylineMeshCount` et
  `LocalPrimarySkylinePrimitivesReplaced` comptent les instances
  effectivement montées et les primitives effectivement cachées.

## Tests et limites

Régression source déterministe sur les 20 couples
variante/direction : enveloppe du mesh, limites de mise à l'échelle,
réversibilité, contrat d'assets approuvés et branchement LOD.

Cette vérification **ne remplace pas** les tests Roblox Studio/Android :
pas de FPS réel, pas de photographie de l'horizon et pas de nouvelle
publication Roblox Place attestée par ce lot.

**Suite du plan :** inventaire et remplacement des `addVariantLandmarks`
et formes de signal les moins lisibles, puis test visuel in-engine
avec seuils de performance Android.
