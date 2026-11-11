# P4 — Contreforts des stations : vraies sculptures sur Android Low

**Date :** 11 novembre 2026. Baseline GitHub `f9293267861d959dbbc583ae920d741d1443a384`, dernière version publique confirmée après publication réussie de ce commit. Ce lot postérieur **n'est pas encore publié**.

## Audit : primitives encore visibles

Chacune des quatre stations périmétriques possède deux blocs décoratifs
`LeftButtress` et `RightButtress` de dimensions 1,5 × 9 × 2 studs,
sans collision, en marge des zones jouables. La source
`ApprovedPerimeterButtressMeshKit` sait déjà remplacer **les deux
simultanément**, avec restitution atomique des blocs en cas d'asset
absent, map changée ou géométrie invalide, mais le cap Android Low
était zéro.

La source de ces sculptures n'est pas une forme primitive déguisée.
Les modèles originaux de `PremiumLargeStructureAssets` sont
créateur-approuvés, avec matériaux PBR en maillages forgés
provenant de `tools/generate_original_large_supports.py`.

| Arène | Asset source Approved |
| --- | --- |
| Classic | `91626128452597` |
| Towers | `107521411452905` |
| Crossroads | `93993697329658` |
| Orbital | `119010829781313` |
| Harbor | `76194593490199` |

## Modification

- Android Low autorise désormais **une seule paire** de contreforts
  remplacée par les modèles approuvés, dans un rayon de **150 studs**
  avec rétention des 18 studs existants.
- Les deux modèles sont clonés et validés *avant* la dissimulation
  des deux primitives. Aucune paire incomplète n'est affichée.
- En condition de pression graphique niveau 1 :
  `math.floor(1 * 0.5) = 0` ; le kit restaure les deux blocs.
  Sous pression niveau 2 : cap zéro.
- Medium (1 station, 185 studs) et High (4 stations, 275 studs)
  restent **inchangés**, y compris la limite High tactile (2).
- **Aucun nouveau modèle ou texture importé** : ce kit réutilise
  les cinq modèles de colonnes répliqués à partir de 29 secondes
  par le chargeur serveur existant. Toutes les MeshParts restent
  non physiques, sans ombres dynamiques supplémentaires, et comptées
  dans le quota Android partagé 440/680/900 Parts.
- Chaque clone est déjà validé à **1–12 MeshParts**, soit au plus
  **24 MeshParts supplémentaires** si la paire est montée sur Low,
  et seulement si le budget et l'asset le permettent.
- Les panneaux, dangers, instructions, éclairages, sol physique,
  bots et logique de manche sont conservés.

Le contrat préexistant
`tools/verify_original_3d_budget_census.py` est enrichi
(aucun nouveau test unitaire) pour vérifier le cap Low, la
distance, le montage des deux sculptures **avant** masquage,
le repli natif, les attributs de provenance et le comptage
dans la télémetrie Android.

## Limites de preuve

La source approuvée doit être disponible via AssetService, située
à proximité, et sa géométrie doit respecter les dimensions
du bloc d'origine. Une condition non remplie conserve la forme
native, plutôt que d'étirer l'asset de manière incorrecte.
Les contrôles GitHub ne certifient pas les FPS réels
ni une capture Roblox Studio. Une nouvelle version publique
exige Build Validation et Roblox Engine Tests verts sur
le commit `main` exact avant publication.
