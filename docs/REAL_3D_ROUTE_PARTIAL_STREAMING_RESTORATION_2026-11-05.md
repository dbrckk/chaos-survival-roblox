# VIS-009 / VIS-010 — Genuine route shell integrity on partial streaming

Date: 2026-11-05. Source-only milestone, no public publication.

The current route owner already restores the genuine server landing paint when a complete model leaves `PremiumRouteMeshLocal`. An internal MeshPart could nevertheless disappear without a top-level Model removal, while a partially rendered 3D route still hides its server-native landing panel. PBR's own coverage check cannot restore a missing non-texture shell.

The client now records the original authenticated MeshParts in each mounted `PremiumJumpDeck`, `PremiumSkybridgeModule` and optional `OriginalUnderdeckChassis`, rejects native Parts inside the premium source, and listens to the resident model's `DescendantRemoving` event. Losing a single genuine BasePart fully dismounts that physical route's cosmetic owner, restores the genuine native landing immediately and releases optional PBR. The shared camera LOD tick also refuses any incomplete cached owner. All colliders, server danger indicators, jump physics and route choices remain authoritative and unchanged. No new heartbeat, raycast, network calls, asset IDs or camera budgets.

Acceptance still required: exact-SHA build and seven genuine Roblox Cloud suites; authenticated Studio + Android verification on five arenas, StreamingEnabled, shrink, skybridge shutter and collapse; visual/30-minute FPS gate. No source commit alone implies live public deployment, AAA completion or tested Android visuals.
