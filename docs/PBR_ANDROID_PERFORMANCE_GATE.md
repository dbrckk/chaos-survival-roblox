# Original PBR — Android GPU budget and visual acceptance

This gate applies to the **16 original 2K Roblox Image maps** (four industrial
MaterialVariants), already approved and baked into `default.project.json`.
It covers the cosmetic-only PBR surfaces on the four playable sectors and
arena architecture. It does **not** certify the public Roblox experience
without native client captures.

## Implemented in code

| Client quality | Max PBR surfaces per model | Global active PBR surfaces | Maximum camera distance |
|---|---:|---:|---:|
| Low (touch/desktop) | 0 | 0 | 0 |
| Medium — Android/touch | 6 | 32 | 240 studs |
| High — Android/touch | 16 | 72 | 370 studs |
| Medium — desktop | 6 | 48 | 340 studs |
| High — desktop | 16 | 144 | 550 studs |

- All four original MaterialVariants share the **same global** surface limit:
  there is no unbounded `per-model × model-count` GPU multiplier.
- Prefer **nearby, large, prominent, camera-facing** architectural
  surfaces for the shared budget. Outside a 55-stud near-field radius,
  surfaces directly ahead gain more priority than equally distant surfaces
  behind the camera. Selection hysteresis keeps established surfaces stable.
  This changes WHICH textures receive the existing fixed GPU budget,
  never raises the per-model or global cap.
- Respect `SceneryLodHidden` and `LocalTransparencyModifier`; never override
  the existing LOD owner's visibility decisions.
- Change Material / MaterialVariant **only when the selected variant changes**.
  No full teardown/reapplication on map streaming or ordinary quality updates.
- **Android startup:** before the adaptive quality attribute exists, scenery
  LOD, cosmetic particles, industrial facade markings and mobile readability
  initialize to **Medium** on touch devices, never desktop High. Explicit
  Low/Medium/High selections always take precedence; desktop defaults to High.
- Only anchored, non-colliding, non-queryable, opaque cosmetic Parts qualify.
  No authored `SurfaceAppearance` or unrelated custom MaterialVariants are
  overwritten. An external material change revokes the local ownership claim.
- Existing streaming event listeners trigger a delayed, coalesced scan.
  The same slow camera sampler also rescans after **32 studs of movement**
  OR **28 degrees of stationary camera rotation**, so looking around reveals
  detail on newly facing buildings without needing to walk. No new
  RenderStepped or Heartbeat handler. Before a real CurrentCamera exists,
  PBR distance eligibility fails closed rather than briefly allocating all
  2K materials.
- `Player` **local-client attributes** provide three QA counters:
  `PbrActiveSurfaceCount`, `PbrActiveSurfaceBudget`,
  `PbrVisibleCandidateCount`. These are *not* frame-time or GPU memory
  measurements and do not constitute a performance certification.

## Native acceptance before final release

1. Capture **real Android** Low / Medium / High 30-second traversals through
   all four sectors (observatory, cargo, power plant, communications).
2. Confirm `PbrActiveSurfaceCount` never exceeds the listed tier budget;
   Low must remain zero even under heavy StreamingEnabled map churn.
3. At least once per sector, capture the true game camera in daylight,
   blackout and active disaster lighting. Verify normal-map handedness,
   roughness/metal response, color consistency, texture scale and no seams.
4. Record frame-time distribution, memory, GPU load when available, device
   temperature and touch responsiveness. Compare with the immediately
   preceding shipped PBR material selection implementation using identical
   scene, quality, camera route and player/bot counts. No claim of an
   Android FPS improvement is made until this paired measurement is taken.
5. Validate no material flash when new buildings stream, the camera
   turns by 28 degrees without moving, the player crosses the distance
   threshold, CurrentCamera initializes late, and quality changes
   High ↔ Medium ↔ Low.
6. Verify that hazard telegraphs, route labels, collision and the effect of
   `ReduceMotion` remain clear and correct. These take precedence over PBR.
7. Preserve fallback snapshots and release hashes. A merge to `main` is
   source integration only; **do not publish** until human/device QA and the
   independent release readiness gate pass.

## Evidence sources

- `src/shared/PbrDistrictRules.lua`: pure caps, eligibility, LOD/distance
  filters and scoring.
- `src/client/pbr-district-materials.client.lua`: minimal-diff material
  reconciliation and diagnostic counters.
- `tests/engine/vfx-quality.spec.luau`: real-engine policy assertions.
- `assets/source/roblox-pbr-upload-receipts.json` and
  `assets/source/roblox-pbr-approval-evidence.json`: actual asset IDs,
  upload provenance, and point-in-time Open Cloud moderation/owner audit.

## 30 octobre 2026 — cuirasse PBR réelle du cargo de Storm Harbor

Le navire `HarborCargoVessel` (modèle 3D original de la PR #416)
était initialement rendu avec les matériaux Roblox natifs. Le contrôleur
PBR existant reconnaissait les quatre grues `HarborGantry`, mais pas
le navire. Ce nouveau suivi utilise les **mêmes variantes 2K originales
approuvées**, contenant les quatre cartes couleur, normale, rugosité et
métallicité, sans uploader ou créer de textures supplémentaires.

Le prédicat `PbrDistrictRules.isAuthoredHarborVesselOwner` exige à la
fois le nom exact `HarborCargoVessel`, les quatre attributs de provenance
et le véritable chemin `Arena/Decor/StormHarborGantryFleet`. Il refuse
les copies, autres modèles, géométries de collision et éléments Glass.
Les grandes surfaces cuirassées (`MainHull`, `LowerKeel`) demandent la
variante acier oxydé, et le pont `MainCargoDeck` la variante anti-dérapante
sur base métal, selon la sélection **déjà implémentée**. Seules les
surfaces réellement éligibles et près de la caméra peuvent recevoir
un `MaterialVariant`.

| Qualité | Cargo : quota par modèle | Budget global Android (inchangé) |
|---|---:|---:|
| Low | 0 | 0 |
| Medium | 1 | 32 |
| High | 3 | 72 |

La même boucle de sélection toutes les 1,7/2,2 s reste seule propriétaire
des variantes locales. Aucune nouvelle boucle, physique, RemoteEvent,
texture externe, propriété serveur ou lumière. L'extérieur maritime
reçoit une **pénalité de sélection** supplémentaire pour laisser les
proches surfaces jouables prioritaires dans le budget global. Si le
navire est masqué par le LOD ou si le joueur désactive PBR sur Android,
les variantes locales sont restaurées comme avant. Les Materials déjà
validés comme source ne prouvent ni l'accessibilité actuelle des images
en jeu, ni la qualité visuelle ou les FPS sur téléphone.

Réception : vérifier sur un vrai appareil Android, à quelques dizaines
de studs du port nord et sur Medium puis High, les normales (+Y), l'échelle
des reliefs métalliques, la cohérence coque/pont, les changements de
LOD/streaming et `PbrActiveSurfaceCount <= PbrActiveSurfaceBudget`.
Le premier lancement du port doit fonctionner sur Low avec **0** PBR.
La PR correspondante doit passer la compilation et toutes les suites
Roblox Cloud sur son SHA final avant mise en ligne.
