# Android — urgent survival warnings own the foreground notification lane

31 October 2026. Source-level follow-up to real 1536x~700 Android captures and PRs #459–#463.

## Confirmed race in existing runtime

The `hazard-route-readability.client.lua` module renders an immediate near-impact / global JumpShock / Harbor-sweep instruction `HazardReadabilityCue` every 75–120 ms (on Low it uses 120 ms), while the optional `district-expedition-navigator.client.lua` checks the visible warning via `hazardCueVisible()` only on its **250 ms** polling cadence. The navigator already listens to `MobileHudNotices.Changed` and can hide instantly, but *real impending hazard messages did not claim the existing shared priority lane*. This allowed a visible cash route, near-miss card, shard reward or escalation event to persist briefly behind the urgent cue. In addition, `round-events.client.lua` dismissed an already-visible escalation card only when `intro` claimed the lane, not when any other higher-ranked alert preempted it.

## Completed code correction

- Reuse the **existing** `MobileHudNotices` client-only, BindableEvent-based foreground owner. While an actual in-round actionable danger cue is shown, `hazard-route-readability` claims `imminent-hazard` at priority **85**: above escalation (70), near-miss (30), and shard (10), but below initial round intro (100).
- All already-existing branches that hide the hazard cue (round ended, no warning, server marker disappeared, player eliminated, no HumanoidRootPart) **also release** the claim, so optional routes and rewards can return. The `claim` call for an unchanged owner does **not** fire another Changed event.
- `round-events` now clears a displayed escalation when **any other active notification owner** preempts its lane, rather than waiting for `intro` exclusively. Its existing generation token invalidates delayed fades and prevents a stale event card lingering underneath a hazard warning.
- The navigator, near-miss and shard modules already listen to `MobileHudNotices.Changed`, so no additional UI component changes, polling loops, remote events or server trust are introduced.
- **No changes to the actual hazard calculations**, hitboxes, time-to-impact, escape direction, beam visibility, avatar buttons, timer, touch controls, desktop HUD or main world geometry.

## Acceptance contract at next significant gate

1. On Android during Meteors/Bombs with an overlapping district signal objective, urgent direction replaces the optional navigator **in the same event turn**, without a 250-ms extra period of competing panels.
2. During global Jump Shock and Harbor sweep, only the actionable warning remains visible in the nonpersistent mobile notification lane. Main hazard header and bottom progress meter remain unchanged.
3. During a new-round introduction the intro still outranks the hazard owner by rank, preserving the previous first-time-player experience.
4. When the warning expires, player dies or round ends, `imminent-hazard` releases and optional navigation resumes normally. No stuck foreground claim across map replacement.
5. On desktop, no layout or claim behavior changes. On Android Low/Medium/High and ReduceMotion, no extra allocations or per-frame work beyond the **existing** hazard loop.
6. **Run actual exact-SHA Build Validation + five existing Roblox engine suites before public release**, then confirm legibility in a real Android playthrough. This branch has not yet run those checks or been published.

Public Roblox game remains at the last verified publication source `97a2533cf57e33f74fc2abe9948922e7ac1d8a4f`.
