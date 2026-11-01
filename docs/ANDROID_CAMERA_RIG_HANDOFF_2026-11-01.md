# Camera ownership and streamed rig replacement — Android source fix (2026-11-01)

## Evidence and scope

Baseline `main`: `44c1aca6f039488503f12b4d97e3e39f672e2522`. This patch fixes real client-source edge cases; it does **not** claim an in-engine Studio run, Android frame-rate change, lower input latency, or a new published Roblox version. Release publication remains gated on the next important milestone.

## Defects found

1. **Foreign camera still faded local arena:** `mobile-camera-sightline.client.lua` checked `RoundParticipant` and `RoundEliminated` plus `CameraType ~= Scriptable`, but NOT the actual `CameraSubject`. During a spectator/cinematic/handoff, Roblox may give another character or director camera ownership before attributes catch up. The local-avatar camera fade then targeted the wrong world while the camera looked at somebody else.
2. **Moving camera/body effects lost after rig replacement:** `movement-feel.client.lua` only watched `ChildAdded` for delayed `Humanoid`/`HumanoidRootPart`. When the replacement was added *before* the old rig part was removed, the add event could bind (or keep) the old part, but the later removal never retried. That left the movement/landing camera owner disconnected until a full respawn. Old impact/landing/FOV impulses could also remain when the script switched a bound part.

## Corrections

- Android occlusion now requires a live local Humanoid in the current character, a valid viewport and a **non-Scriptable CameraSubject following that Humanoid or one of this character's own parts**. Foreign spectated subject, dead rig, unreplicated rig, and invalid camera restore the actual preexisting local avatar/structure transparency and clear raycast filter ownership. No camera rotation/zoom/physics writes are introduced.
- The existing `movement-feel` character connection owner now listens to both child arrival and removal. Removal invalidates its old Humanoid/Root state listener and schedules one deferred rebind of the current character. Existing `bindVersion` and character equality checks suppress events from a previous respawn; existing `disconnectCharacter` cleans both subscriptions.
- When a new Humanoid/Root pair actually differs, `suspendCameraMotion()` clears the previous impact, landing, FOV, and preview state before attaching the new pose/velocity baseline. No extra render step, network event, additional game physics or AI advantage.

## Acceptance at major release

1. Freeze exact candidate SHA. Run Build Validation + all five Open Cloud engine suites (full gate).
2. Authenticated Studio: enter READY and RUN as a participant; change `CameraSubject` from the local Humanoid to a living AI survivor, then to Scriptable and back. No localized arena parts/avatars should stay faded while spectating; no foreign-body landing pitch/FOV.
3. Recreate root/humanoid replacement **new-before-old removal** and **old-before-new insertion** on R15, including delayed Android streaming and same-player respawns. Movement camera restores on the latest rig, without another `CharacterAdded` and without old landing particles/impulse.
4. On Android Low/Medium/High, perform twenty regular jumps and edge landings; ensure the existing 0.10s coyote / 0.12s buffer, real platform collision, native jump control, hazard telegraphs, result animations and accessibility/ReduceMotion still work.
5. Observe device frame-times/allocations and actual photos/video; **do not claim improved FPS or measured jump accuracy** until the test evidence exists.

## Release

This is a targeted integrity fix, not a rebalancing: `MovementAssistRules`, character speed/jump force, safety hitboxes, game progression, bot logic and the public Roblox place are unchanged.
