# Visual QA scorecard — subjective art quality requires visual evidence

Use this file to review a **rendered build**, not its source code. Do not assign arbitrary AAA/10 ratings without screenshots and a tester.

| Area | Reviewer discipline | Required evidence | Gate |
| --- | --- | --- | --- |
| Silhouette per arena | Environment art | Low/High distance capture for all four maps | Distinct without neon |
| Composition & pacing | Art direction | Lobby, Ready, Round, Result footage | One focal point per phase |
| Materials & detail | Technical art | Close/medium-range side-by-side captures | Plausible layered forms |
| Character animation | Animation | R6/R15 walk, pivot, jump, land, death, emote | No broken poses |
| VFX signature | VFX | 11 hazards under Low/High and Double Chaos | Clarity precedes spectacle |
| UI interaction | UX | 320/360/400/440px tap-safe video | No overlap and clear next action |
| Accessibility | QA | Reduced Motion, audio muted, color-only signals | Usable without motion/color |
| Mobile performance | Performance | Model, session, tier, FPS, memory, temperature | No crash or persistent hitch |
| Streaming & cleanup | Engine QA | Map swap, reconnect, 30-minute session | No ghost objects or leaks |

**Rating scale:** 0 = absent, 1 = broken, 2 = generic but functional, 3 = intentional, 4 = polished, 5 = production showcase. Require a source screenshot, reviewer, date, candidate commit for each rating. Treat performance, accessibility and gameplay readability as hard gates regardless of the art rating.

Release blocks: unlicensed assets, unreadable warnings, visual blockers/colliders, persistent camera seizure, severe mobile frame drops, missing model after replication, duplicated UI/lighting, dangling VFX after multiple rounds.
