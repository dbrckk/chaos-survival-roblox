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

### In-game fallbacks (actual, verifiable Roblox asset IDs)

A ready-to-build Roblox `MaterialService` tree is included in
`default.project.json`, with four `MaterialVariant` instances. Each uses
**all four maps**: color, normal, roughness, and metalness. They presently
reference the **verified public Roblox-owned texture IDs** for Foil,
CorrodedMetal, DiamondPlate and CeramicTiles, rather than inventing IDs for
the project's generated images. Source of those IDs:
https://create.roblox.com/docs/parts/materials

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
reallocation. This only reuses the four MaterialService variants; it does
**not** load new 2K textures or create new geometry. The PBR helper policy
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

**Created is not the same as approved or live.** Many Image assets were
still `Reviewing` when Roblox confirmed creation. Their *current*
moderation, owner permissions and readability by the experience must be
checked before substituting original `rbxassetid://...` values into
`default.project.json`. For now, the live PBR variants retain their
verified Roblox-owned fallback maps, and the public Roblox place has
not been updated.

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

Once all 16 original Image assets are present, independently verified approved and accessible to the experience, replace the **four properties per
MaterialVariant** in `default.project.json` with the actual
`rbxassetid://...` values for the corresponding original PBR maps.
Never substitute an unverified ID or mark a texture as approved before
Roblox confirms it.

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
