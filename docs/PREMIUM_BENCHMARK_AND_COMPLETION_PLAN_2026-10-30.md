# Premium round pacing — three-act authored pressure

30 October 2026. The previous smoothstep ramp started increasing intensity immediately and gave every part of a match a nearly uniform change of pressure. The updated server-owned `RoundIntensity.factor` has three continuous acts: opening 0–22% (only 18% of total ramp), escalation 22–76% (57%), climax 76–100% (25%). The start/end intensity, solo limits, double-chaos limits and minimum spawn delay remain **unchanged**. No extra disasters or network traffic are introduced.

Acceptance at major release: validate the new curve at 0%, 22%, 76%, 100%; monotonicity and continuity; solo/double-chaos caps; real Android survival curves, disaster reaction time and late-match frame pacing. Engine tests are deliberately deferred during improvements, as requested.

## Benchmark scorecard (engineering estimate, NOT measured user satisfaction)

Against top-performing Roblox platform/survival experiences such as Tower of Hell, Flood Escape 2 and Natural Disaster Survival. This is a provisional audit from code and history; no current live gameplay recordings or retention analytics were available. Scores are **not factual live performance metrics**.

| Dimension | Chaos Survival /10 | Premium target /10 | Evidence and gap |
|---|---:|---:|---|
| Real physical parkour routes | 7 | 9 | Five 320-stud maps; graded jumps, branches and rescue crosslinks; still little authored obstacle motion |
| Controls and movement feel | 5 | 9 | Standard R15 motion; needs Android latency and camera playtests |
| Visual identity and 3D composition | 6 | 9 | Distinct 3D landmarks and PBR; requires screenshot/lighting/art direction QA |
| Disaster variety and counterplay | 7 | 9 | Eleven hazard kits and combinations; interaction readability unmeasured |
| Round pacing and fairness | 6 | 9 | This three-act curve improves predictable tension; actual death rates unknown |
| AI rivals | 6 | 9 | Route-aware bots; needs measured human-like navigation, fall recovery and honest labeling |
| First-session clarity | 7 | 9 | Physical arrows, bilingual cues and survival briefing; measure comprehension |
| Long-term replayability | 6 | 9 | XP, verified jump chains, daily/weekly mastery; needs distinctive goals and real retention |
| Android performance | 5 | 9 | LOD architecture exists; FPS, thermal and memory measurements missing |
| Release confidence | 5 | 9 | Automated engine suite exists; exact candidate SHA not yet tested or published |

Unweighted indicative score: **6.0/10**, confidence **low–medium** because no empirical mobile/PC session data. Do not claim the game is at AAA parity.

## Priority-ordered completion plan

**P0 — release blockers (1–3 engineering days, estimate).** Fix any test failures; run full Open Cloud engine suite, Rojo/build validation and source security checks on the *exact same SHA*. Instrument and run 20 Android + 10 PC complete rounds; verify survival start/end, reward once-only, respawn, bots, disaster combinations, 5 maps, network reconnection and no catastrophic crashes. No public update until green.

**P1 — movement and interaction (3–6 days).** Profile camera follow, jump buffering, landing readability and touch target layout on low/mid Android; define and implement a single server-authoritative moving-obstacle family with predictable telegraph, physically reachable bypass and AI awareness; include accessible static alternative where appropriate. Target ≥95% successful intended jumps on easy route for practiced testers, 0 impossible gaps, p95 input-to-response ≤100ms on representative Android hardware (requires measurement).

**P2 — art and sound direction (4–8 days).** Per-map 3D hero composition and coherent material/lighting pass, ambient SFX, per-disaster warning sound and restrained landing feedback. Test contrast in rain/night, avoid confusing hazard-red with route guidance, maintain low-end LOD. Target 30 fps p95 frame pacing on low-end Android and 60 fps on mid-range where feasible; measure rather than assert.

**P3 — content and retention (5–10 days).** Add one distinctive signature traversal mechanic per map, challenge tiers with practice/safe route, varied round finales, earned cosmetics with no pay-to-win, visible milestones, concise post-match reason-for-death and one-tap replay. Target first-session goal understanding ≥90% in observed playtests, ≥70% of first matches completed without a navigation dead-end. Measure D1/D7 retention; do not invent baseline or promises.

**P4 — balance, polish and public release (3–5 days).** Balance catastrophe combinations, bot success distribution and economy across repeated seeded sessions; fix regressions; final mobile accessibility and localization review; optimize memory, network and streaming; run exact-SHA checks and public Open Cloud publication once authorized gates pass. Monitor crash rate and completion metrics post-release.

All durations are **rough engineering estimates**, not a guaranteed schedule. Do not start multiple unfinished feature families in parallel.
