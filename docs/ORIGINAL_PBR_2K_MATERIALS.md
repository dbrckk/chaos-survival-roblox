# Chaos Survival — physically based 2K material pipeline

## What is genuinely ready

Original, code-authored **seamless 2048 × 2048 PNG maps** can be generated for
four industrial material families, each with four separate channels:

| Material | Intended details | Metalness | Runtime use |
|---|---|---|---|
| `brushed_titanium` | Directional machined scratches and anisotropic sheen cues | Metal | Pylons, antennae and exterior brushed alloy |
| `oxidized_steel` | Rust islands, chipped roughness, microscopic pitting | Metal beneath rust; dielectric rust | Exposed framing, supports and weathered external steel |
| `armored_diamondplate` | Beveled repeating anti-slip ribs | Metal | Reinforced housings and structural armor |
| `reactor_ceramic` | Dense segmented plates, bevels and dark grout | Nonmetal | Reactor shells and inert plinth details |

The generator `tools/generate_pbr_materials.py` uses procedural reproducible
noise, normals from a periodic height derivative and physically meaningful
roughness / metalness masks. Normals are tangent-space **OpenGL +Y**, as
required by Roblox, and the metalness texture is not treated as an AO mask.

Run it locally (Python 3.11+, NumPy and Pillow):

```bash
python -m pip install numpy==2.1.3 pillow==11.1.0
python tools/generate_pbr_materials.py --size 2048 --output build/pbr-2k
```

This writes **16 square 2K PNGs**, `contact_sheet.jpg` and a SHA-256
`manifest.json` with `roblox_asset_id: null` until legitimately uploaded.
The GitHub action **Build Original 2K PBR Texture Atlas (No Upload)** runs
the exact generator and keeps a downloadable, inspectable artifact.

### Verified original 2K images in all four MaterialVariants

The Rojo `MaterialService` tree in `default.project.json` contains four
`MaterialVariant` instances. They now point to the actual **16 original
2048×2048 creator-owned Roblox Image IDs** across Color, OpenGL Normal,
Roughness and Metalness maps. This changes the *unpublished source code*,
not the live public Roblox place. The original public Roblox-owned
fallbacks remain available from Git history for a visual-acceptance
rollback if needed.

On **28 October 2026, 11:44 UTC**, a read-only authenticated Open Cloud
audit confirmed every asset as **APPROVED**, with creator ID
`9774173158`, the expected Image type and correct asset ID.
Evidence: workflow run
[40682190586](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/40682190586),
artifact `12813106994`, and immutable source record
`assets/source/roblox-pbr-approval-evidence.json`. This proves
**asset approval/ownership at audit time**, not actual visual quality,
Android frame rates, texture residency, nor private/game asset access.

`src/client/pbr-district-materials.client.lua` applies these materials
locally to static **non-colliding cosmetic** district buildings, the four
**playable-sector original 3D setpieces** (observatory, cargo depot, reactor
and communications), corner landmarks, perimeter stations and hero
architecture. Both `GeneratedMap.Decor` and
`Workspace.DistrictSectorSetpiecesLocal` are watched, including delayed
creation, map replacement and adaptive quality changes. Real terrain, jump
surfaces, weather damage, characters, original imported MeshParts with
`SurfaceAppearance` and hitboxes are never modified.

Within each eligible model the large architectural faces take precedence
over incidental small details. Model-scoped quality caps are preserved
(6 Medium / 16 High; none on Low). When switching tiers or reloading an
arena, existing native materials and authored variants are restored before
reallocation. The four MaterialService variants now reference
the independently approved original 2K images; no new geometry is created. The PBR helper policy
is tested in the existing real-engine VFX suite.

Mobile tier behavior: **Low** keeps the original lightweight Roblox
materials, **Medium** textures up to six substantial decorative pieces per
structure, and **High** textures up to sixteen. No new Parts, GPU effects,
lights, animations, remotes, server scripts, per-frame loops or particle
systems are created for PBR. The existing scenery-LOD system remains
responsible for hiding faraway decorations. When variants are unavailable,
parts retain their original materials.

### Verified image upload records (28 October 2026)

**All 16 original 2048×2048 Roblox Image assets have been created**
in the experience owner's Roblox account. The records are from GitHub
Actions run logs and real Roblox creation-operation receipts:

| Material | Source run(s) | Uploaded maps |
|---|---|---|
| `brushed_titanium` | 40674072895 | Color, Normal, Roughness, Metallic |
| `oxidized_steel` | 40674103388 | Color, Normal, Roughness, Metallic |
| `reactor_ceramic` | 40674201135 | Color, Normal, Roughness, Metallic |
| `armored_diamondplate` | 40674439392 and 40679576853 | Color, Normal, Roughness, Metallic |

Roblox created the last two diamondplate images successfully in
[the owner-approved recovery run](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/40679576853):
`roughness = 121848704472466` (creation-time status **Reviewing**) and
`metallic = 106394628880013` (creation-time status **Approved**).
The programmatic recovery used shorter, valid Image display names and
one create operation per missing channel. Its result artifact is
`chaos-owner-approved-pbr-short-name-recovery`, artifact ID
`12812710630`. The earlier POSTs failed because Roblox explicitly
returned `Asset name length is invalid.`

The **16 unique intended Image IDs**, their individual creation-time
moderation statuses, the full upload run provenance and the two duplicate
diamondplate Color/Normal IDs from previous failed runs are recorded in
`assets/source/roblox-pbr-upload-receipts.json`.
Never rerun a full-material upload or the one-shot recovery. Both
`roughness` and `metallic` are already created; no channels remain
unuploaded. The old single-channel recovery validates the receipts
and will stop before uploading if used again.

**Created is not the same as approved or live.** Several Image assets
were originally `Reviewing` at creation. The newer independent audit
confirmed **all 16 approved and creator-owned** on 28 October 2026,
11:44 UTC; the original IDs have now been committed to
`default.project.json` for source builds. Runtime readability by the
experience, device screenshots and frame-time budgets remain unverified.
The public Roblox place has **not** been updated.

### Automatic 16-image owner and moderation verification

Image creation is complete; **current approval is not established by an
upload receipt**. The independent, read-only workflow
`.github/workflows/verify-original-pbr-asset-status.yml` verifies each of
the 16 images with the existing creator-scoped `ROBLOX_ASSET_API_KEY`
using `GET https://apis.roblox.com/assets/v1/assets/{assetId}`.
No image creation, changes to permissions, Roblox place publishing or
writes to the shipped Rojo project occur.

It checks ID match, creator ownership, Image/Decal asset type, and current
`moderationResult.moderationState`. Unknown/omitted metadata, API errors,
`Reviewing`, and `Rejected` **all fail closed**. Every check is recorded
in the downloadable artifact `chaos-16-original-pbr-asset-approval-audit`.
If the API key lacks `asset:read`, the report will identify HTTP
401/403 rather than invent a moderation status. Running on a PR executes
only offline self-tests; a merge to `main` makes the authenticated GET
checks automatically.

If and only if *all sixteen* images are approved and creator-owned,
the workflow writes a **private staging-only Rojo project** under
`build/pbr-asset-audit/default.original-pbr.PRIVATE-STAGING.project.json`.
It never edits `default.project.json` or publishes the public Roblox game.
A true release still requires real in-game permission, Studio and Android
render QA and performance measurements. Roblox Open Cloud does not
substitute for these tests.

### Upload the *original* maps to Roblox

Four 2K files cannot be used as live MaterialVariant textures solely from
GitHub URLs. They must first become **Roblox Image assets belonging to the
experience owner**, with moderated, verified IDs. This cannot be inferred
from an uploaded Model ID or from a build artifact.

The new workflow **Upload One Chaos Original 2K PBR Material (Manual)**:
- defaults to `dry_run=true`;
- generates exactly one material's four maps without touching a live place;
- for real uploads requires the explicit confirmation
  `UPLOAD_CHAOS_PBR_2K` and the existing creator-scoped
  `ROBLOX_ASSET_API_KEY` secret;
- reports each actual asset ID and moderation state, with immutable
  provenance and per-image operation results.

The 16 `rbxassetid://...` properties in the four
`MaterialVariant` instances are now populated with the exact IDs
recorded in the independently approved audit. The Build Original 2K
PBR workflow rejects any mismatch with the source receipts and the
point-in-time approval evidence. Before public release, recheck live
moderation/access and verify actual material rendering in Roblox Studio
and on Android; retain a rollback path to native Roblox materials.

For original imported UV-mapped MeshParts, a `SurfaceAppearance` with
the same four verified maps can be authored/published in an approved model
package. Runtime scripts cannot write the protected PBR texture map
properties, and the older imported OBJ geometry does not yet have an
approved, checked UV/tangent pipeline; do not pretend a generated 2K PNG
alone is correctly mapped on those MeshParts.

### Required acceptance checks

1. Review all four actual PNG channels at native resolution and verify
   no inverted green normal gradients or obvious UV seams.
2. Confirm the baked Rojo `MaterialService` variants have the expected
   real asset IDs and all four texture properties.
3. Import/approve the 2K original Images, verify creator permissions and
   replace only the appropriate variant entries.
4. Run exact-head source Build Validation and Roblox engine suites.
5. Capture Studio and Android Low / Medium / High images in daylight and
   disaster lighting; compare real frame times, memory, reflection quality
   and hazard readability. Keep native materials if fidelity or FPS regresses.
6. Public Roblox place publishing remains separate and forbidden until
   the release gate is satisfied.

Technical references: [Roblox MaterialVariant](https://create.roblox.com/docs/reference/engine/classes/MaterialVariant),
[Roblox PBR texture rules](https://create.roblox.com/docs/art/modeling/surface-appearance),
[Roblox Open Cloud Assets](https://create.roblox.com/docs/cloud/guides/usage-assets).
