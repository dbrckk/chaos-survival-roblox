# P4 — Mécaniques monumentales du sud visibles sur Android Low

**12 novembre 2026. Statut : source GitHub uniquement, non publiée sur Roblox.**

## Audit du vrai code de la carte

Les deux grands monuments sud suivants possèdent déjà des modèles 3D
créateur autorisés par le serveur et montés par le `scenery-lod.client.lua`
sur Medium/High. Leur `QUALITIES.Low = 0` laissait pourtant des
éléments massifs non physiques en blocs ou wedges sur Android Low :

| Carte | Pièces natives encore basiques | Source 3D approuvée | Remplacement |
| --- | --- | --- | --- |
| Towers | Deux cages d'ascenseur de 37 et 46 studs, deux couronnes WedgePart | `114886409893890` | 4 primitives → 7 MeshParts |
| Orbital | Fondation, plaque de sol, deux appuis d'anneau, sphère suspendue et pince | `96266711661930` | 6 primitives → 7 MeshParts |

Le pont SkyTransfer Towers et l'anneau ObservationRing Orbital ont
**des propriétaires MeshKit distincts**, déjà vérifiés dans les précédents
lots : ils ne sont ni masqués ni dupliqués par ces correctifs.

## Modification effective

- Les deux vrais propriétaires `ApprovedSouthTowersLiftTwinsMeshKit`
  et `ApprovedSouthOrbitalFinishingMeshKit` autorisent **une seule
  sculpture créateur de sept MeshParts** sur leur variante d'arène
  respective, uniquement sous Android Low sans pression facultative.
- Portée Low volontairement **courte : 152 studs**, avec rétention
  d'origine de **26 studs** pour un modèle déjà monté. Cela évite de
  dépenser un modèle secondaire distant en même temps que les
  silhouettes principales à 290 studs.
- Au niveau `OptionalVfxPressure == 1` ou `2`, les deux kits
  déclenchent leur repli natif existant ; leurs modèles optionnels
  n'occupent plus de place dans `VisualBudgetRules`.
- La source est toujours vérifiée `OwnerVerified`,
  `CosmeticOnly`, `Original3DAssetId`, vrai `MeshPart`,
  exactement sept pièces, sans code embarqué et dans les
  volumes approuvés. Aucun import, ID ou modèle inventé.
- Les classes, dimensions, positions et rotations de chaque
  primitive sont vérifiées, et la géométrie est **montée avant
  de rendre transparentes les pièces natives**.
- Restauration automatique à l'absence de modèle, à la
  disparition d'une MeshPart, au remplacement de carte et aux
  modifications des éléments surveillés.
- Les modèles sont ancrés, sans collision, toucher ni requête ;
  aucun changement du serveur, des parcours, dangers,
  bots ou animations de catastrophe.
- `Medium=1` et `High=1`, avec leurs distances **420/580
  studs**, sont inchangés. Aucun nouveau système de caméra,
  `RenderStepped`, lumière, texture ou PBR.

## Critères de réception dans Roblox Engine

1. Sur Towers, camera Low à moins de 152 studs des cages
   d'ascenseur sud : un seul `OriginalSouthTowersForgedLiftTwins3D`
   de sept MeshParts authentiques doit cacher les **quatre**
   pièces natives, sans toucher au SkyTransfer ni à sa cabine.
2. Sur Orbital, caméra Low proche de l'anneau sud :
   `OriginalSouthOrbitalForgedFinishing3D` de sept MeshParts
   cache les **six** natives uniquement. Les 14 arcs appartiennent
   à l'autre véritable modèle torique et restent indépendants.
3. Reculer au-delà de 178 studs d'un montage existant,
   forcer `OptionalVfxPressure` à 1 puis 2, retirer la source
   et simuler StreamingEnabled : les pièces natives doivent
   revenir sans silhouette fantôme.
4. Confirmer `LocalApprovedSouthTowersLiftTwinsCount <= 1`,
   `LocalSouthTowersLiftPrimitivesReplaced <= 4`,
   `LocalApprovedSouthOrbitalFinishingCount <= 1` et
   `LocalSouthOrbitalFinishingPrimitivesReplaced <= 6`.
5. Mesurer sur Android : FPS réel, FPS p95,
   utilisation mémoire, temps de chargement et captures
   avant/après ; aucune de ces mesures n'est revendiquée par CI.

Le test `tools/verify_original_3d_budget_census.py` vérifie
statiquement les deux propriétaires, leur budget Low, les sources,
les six/quatre formes et la restauration. Les tests GitHub
**ne constituent pas** un test Roblox Engine ni une publication.
