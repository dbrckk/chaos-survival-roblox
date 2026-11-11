# P4 — Close-up door finish, five art identities and StreamingEnabled recovery

11 novembre 2026 — Second visible-quality milestone following the
[verified visual audit](P4_PUBLIC_VISUAL_ASSET_AUDIT_2026-11-10.md).

## Real in-world change

All five playable variants have 16 original, nonphysical, server-authored
district door Parts (`ServiceEntryDoor`) with real metal/ceramic
material families and existing approved PBR quota. The client added
only a small, uniform top-of-door sector-number label.

`DistrictMaterialFinishKit.stencil` now adds a bounded, local,
translucent forged-metal inset, directional surface sheen, recessed
manufacturing joints, small fasteners and a second technical identity
band to the **existing SurfaceGui on the actual 3D door**.

Five distinct near-field designs are used:

| Arena | Microdetail / architectural cue |
| --- | --- |
| Classic | etched survey calibration ticks |
| Towers | diagonal hoist-load reinforcement |
| Crossroads | switchyard transfer wiring and cross-link |
| Orbital | concentric ceramic containment collars |
| Harbor | salt-worn quay hatch plating and bolted seams |

These are **actual 2D SurfaceGui industrial details attached to real
3D surfaces**, not new Roblox-approved texture maps, physically embossed
MeshParts, or fake PBR normals. Approved 2K MaterialVariants still
render beneath the translucent overlay. The door's original `Material`,
`MaterialVariant`, `Color`, `Size`, `CFrame`, `CanCollide` and
hazard warnings are not changed.

## Streaming fix

A subtle defect was confirmed in
`district-architecture-materials.client.lua`:
`folder.ChildAdded` ran `task.defer(attach)` only once, but under
StreamingEnabled a district `Model` may arrive first and its
`ServiceEntryDoor` descendant several scheduler turns later.
The previous one-time attach could miss that facade indefinitely.

Now a **single folder-level** `DescendantAdded` filter watches only
the canonical door's arrival. It retries `attach` for that model
without reprocessing every part or scanning the entire map. A paired
`DescendantRemoving` observer releases the exact owned GUI and LOD
property listener when a door streams away; both folder-level
connections are disconnected on tier/map rebuild.

## Strict mobile budget retained

The existing owner still installs no rich door stencils on Android
**Low**, up to **8** on Medium (even-numbered district indices)
and up to **16** on High. One `SurfaceGui` is attached to each
eligible door; `PixelsPerStud` remains 16/24 and automatic
`MaxDistance` remains 115/145 studs. The panel itself is **not**
new collision geometry and adds no network ownership, extra renderer
loop, light, audio effect, animated decal or Roblox asset upload.
The higher detail is intentionally restricted to nearby visible
facade doors, not stretched over every far-out skyline element.

## Verification

- Existing engine suite `arena-material-rules.spec.luau` contains
  five-variant real Instance-tree assertions, Low/Medium checks,
  legacy caller compatibility and preservation of native door material.
- Dedicated source regression matches door owner, StreamingEnabled
  cleanup, UI limits, prohibition on fake external texture IDs, and
  the existing Open Cloud engine suite registration.
- GitHub source CI is necessary but cannot certify **actual image
  quality or FPS**. Visual comparison still needs genuine Studio /
  Android screenshot passes at 115/145-stud limits.

The changes do not publish a Roblox Place automatically.
