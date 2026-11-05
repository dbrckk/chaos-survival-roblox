# VIS-010 / VIS-027 — remplacer les quatre grands portiques Sky Spine par des modèles 3D authentiques

**5 novembre 2026.** Base de travail validée : `d418a704d7436ab950b11192302d93cba7cc2f44`. Code source uniquement, non publié.

## Problème confirmé

Chaque arène possède quatre grands portiques Sky Spine **sur les plateformes physiques des étapes 2 / 5 / 6 / 9**, créés dans `SkySpineArchitecture`. Seules les deux arches centrales 5/6 exploitaient le vrai modèle UV/tangentes du propriétaire `OriginalSkySpineCrown` — Roblox **Approved `71492051540032`**, 1 696 triangles, sept groupes matériaux. Les étapes 2 et 9 conservaient les pylônes, croix et enseignes natifs, très visibles en hauteur.

## Correction intégrée

- L'owner existant accepte désormais les quatre emplacements authentifiés `PlatformN` avec `ChaosPermanentRoute`, `SkySpineInterchange`, `SkySpineStep` = 2/5/6/9, vraie collision et empreinte d'origine. **Aucun nouveau Part de collision, pont fictif, asset ou chargement client.**
- Les portions natives supérieures correspondantes sont masquées **localement après montage réussi** du modèle approuvé, tout en préservant rails, supports, surfaces de marche et télégraphie des catastrophes.
- **Quota par proximité de caméra Low 1 / Medium 2 / High 4**, dans la même comptabilité Android. Sous `OptionalVfxPressure` : Medium 2→1→0, High 4→2→1, Low maximal→0. Aucun nouveau `Heartbeat`, `RenderStepped`, RemoteEvent ou minuterie.
- **Restauration immédiate** des pièces natives en cas de disparition inattendue du Model approuvé ; protection contre les réentrances pendant démontage normal. Warning, `CollapsePhase`, volet, shrinking, tiers et streaming conservent la priorité.
- Le client expose `LocalOriginalSkySpineCrownCount` (tous les vrais modèles montés) et le nouveau `LocalOriginalSkySpineOuterCrownCount` (étapes 2/9 effectivement montées), sans inventer de preuve de rendu ou de FPS.

## Vérification moteur et Android

Le scénario moteur préexistant `tests/engine/mapbuilder-advanced.spec.luau` teste les quatre étapes **pour chacune des cinq arènes**, les quotas par tier, la disparition du modèle, la restauration de la plateforme native, les avertissements, les variations de pression, la perte de route permanente et `ShrinkingArena`. Un seul jalon doit lancer `Build Validation` + sept suites réelles Roblox Cloud sur SHA identique. Sur Android, comparer les silhouettes des étapes 2/9, la répétition des motifs, la performance et la lisibilité des routes.

**Ni déploiement public, ni capture Studio, ni certification Android ne sont affirmés par ce fichier.**
