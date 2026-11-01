# Android first action — no-modal control cue and clean HUD lanes (1 November 2026)

## Scope and evidence

Candidate branch `feat/first-minute-actionable-controls-20261101` based on `main` `fa7a17e15da18739f2869cc6db7e9e80930c671d`.
Source implementation only: no Studio, device screenshots, measured time-to-first-jump, retention or gameplay certification in this change. Last verified public publish remains `e8767c98c475a3efb39ed53ed7bbe16efa1865d2`.

## Existing features preserved

- A full four-step guide exists behind the explicitly tapped `AIDE/HELP` button. It never opens automatically or blocks thumb movement.
- The single `RookieCoach` TextLabel already displays a phase-specific first-session objective; voting, READY, result and hazard HUD have precedence.
- On touchscreen, the rookie coach remains hidden during live gameplay and when actionable vote cards are present.
- Actual jumping, camera, round state, achievements, server persistence and analytics remain unchanged.

## Corrected first-minute issues

1. The old WAIT copy contained only "automatic start / survive until zero", without telling an arriving player how to MOVE or JUMP. It now reuses the current rookie banner to display real input hints with distinct, localized text for touch (joystick + right jump button), keyboard (WASD/ZQSD + Space) and gamepad (left stick + A). A two-line short touch copy limits footprint on narrow phones.
2. In the first quiet lobby, the current nonmodal `AIDE` button is 68px wide at x=6, but the original centred rookie banner began at x=~54 on a 320px-wide screen. This covered 20px of the **actual help button**. For narrow touch viewports (<680px), the banner is now placed in the remaining horizontal lane: x=82, width=viewportWidth−94. At 320px: banner spans x=82..308, 8px clear of the AIDE button.
3. During READY, the alive counter is 5px under TopHUD and 24px tall. Both the counter and rookie banner previously started near the same Y coordinate. The READY beginner banner now starts at `topHeight+42` (screen coordinate); the alive counter ends at `topHeight+36` after the TopHUD +7 inset, leaving 6px clearance. READY has no central countdown overlay on touch by preexisting policy.
4. The initially hidden rookie banner no longer initializes with an English string before authoritative RoundState/localization assigns its text.

## Acceptance at next important milestone

- 320/360/400/440px and landscape Android native screenshots: quiet-lobby input instructions remain readable, x-lanes never overlap `AIDE`, first avatar and native jump button remain uncovered.
- READY with 1 player, 4 players and AI: survivor chip and beginner objective never overlap, and round warning stays readable. Check both FR and EN.
- Verify gamepad/keyboard controls copy on supported desktop/gamepad clients; avoid claiming ZQSD as the only keyboard mapping.
- Vote opens: rookie coach hides on touch; cards remain fully tappable. Round starts: beginner coach hides on touch; warnings and camera are unobstructed. Result: verified rewards and next-round cue persist.
- Preserve Reduce Motion, visual quality tiers and the no-modal policy.
- Use existing milestone Build Validation + five Open Cloud suites on the exact candidate SHA, then authenticated Studio E2E and real Android/PC. No routine unit-test run during iterative development.

## Limitations

This is a bounded onboarding legibility fix, not a claim of improved retention or first-jump success. Device screenshots and instrumentation must determine whether future changes to the 30-second learning flow are justified.
