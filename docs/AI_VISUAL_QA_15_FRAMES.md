# Chaos Survival — AI-controlled 15-frame visual QA

## What the test actually does

1. Builds **the exact Git commit** into a local Roblox Studio place with Rojo.
2. Runs one real local Studio client/server match. Three server-controlled
   **AISurvivors** use their existing independent AI navigation/animations.
3. The Studio-only spectator camera follows a living AI, switching subjects
   after every five samples. It shows chase, side and eye-level views, with
   no scripted imitation of bot movement.
4. Reports **15 Roblox-rendered camera states**, one roughly every three
   seconds. The authoritative test checks bot identity, living Humanoid,
   camera proximity, renderer frames, time gaps and presence of a live round.
5. An authenticated **interactive Windows desktop** screenshots the actual
   Roblox Studio/client window fifteen times into distinct PNGs. Every PNG
   gets a UTC timestamp, viewport size and SHA-256 provenance.
6. A Python/Pillow audit validates the fifteen PNGs, rejects identical/static
   content, quantifies brightness/contrast/frame changes, and produces a
   5 × 3 **contact sheet** for visual review with the full-resolution PNGs.
7. The GitHub Actions artifact contains all evidence, including logs,
   source SHA, fifteen PNGs, montage, JSON and Markdown review reports.

**Important:** these are REAL game-engine frames from an isolated Studio
simulation, **not** frames from the already published Roblox server and
**not** a simulated/AI-generated illustration. Desktop captures are **not**
a substitute for verifying real Android FPS, touch UX or actual mobile
GPU output. Never call a successful headless Open Cloud engine test an
authenticated GUI screenshot test.

## Security, consent and prerequisites

- GitHub workflow:
  [.github/workflows/roblox-ai-visual-review.yml](../.github/workflows/roblox-ai-visual-review.yml).
- This task **requires an online GitHub self-hosted Windows runner** with
  official signed Roblox Studio already installed and authenticated for
  the same Windows user. The runner MUST run interactively in an unlocked
  Windows desktop session; Windows service/session-0 or a fresh
  GitHub-hosted runner cannot expose guaranteed game pixels.
- No Roblox passwords, cookies, login tokens, 2FA codes or API keys should
  be provided to the script. Authenticate normally in Roblox Studio as
  its owner using the Windows UI.
- Execute `studio/self-hosted-runner-preflight.ps1` under that same user.
  It tests authentication without logging credentials.
- On GitHub **Actions → Roblox AI Visual Review → Run workflow**, choose
  the branch containing the desired candidate commit. The workflow has
  a manual trigger; an update to `studio/VISUAL_AI_TRIGGER` on `main`
  may also trigger it once a runner is online.
- The workflow never publishes the public place, writes DataStores in a
  live production session, uploads captures to Roblox galleries or
  touches other users' devices. It saves only local preview pixels into
  the runner's GitHub artifact.

## Local one-click option

With this project open in an authenticated Roblox Studio install, load
`studio/ChaosAutoplay.plugin.lua` as a local plugin, click
**Chaos Visual AI 15**. It performs the live AI-camera test and prints
`PASS: visual AI: 15 renderer frames ...` if successful. This alone
does **not** write fifteen image files: the Windows collector must also be
active to save PNGs. No user permission prompts for Roblox Captures are
bypassed.

The same test from the official Studio CLI uses
`studio/visual-ai-runner.luau` as `--runScriptFile`.

## Reviewing and fixing actual problems

Use the generated `visual-ai-contact-sheet.jpg` to rapidly identify:
- bot body/hats occluding the view;
- hazard warning visibility and reachable platforms;
- floating world text or screen GUI overlays;
- overexposed neon and dark backgrounds;
- broken/late-loaded 3D scenery across the session;
- empty arenas, abnormal object positions or camera clipping.

Inspect each original PNG before asserting a defect. The JSON report
contains numerical warnings, **not** claims that an AI performed visual
interpretation. Correct source files in a new GitHub branch, build and
run the **real Open Cloud Engine Tests**, then repeat the Studio capture
run on the exact new SHA. Never publish an untested screenshot-driven
change automatically to the public Roblox experience.

## Failure states and evidence

| Problem | Meaning |
|---|---|
| `AUTH_REQUIRED` | No signed-in Studio session on Windows runner |
| `NO_INTERACTIVE_DESKTOP` | Windows runner cannot render a visible UI |
| `NO_RENDER_MARKER` | Local Studio client/server AI test never started |
| `NO_RENDERED_WINDOW` | No visible Studio/play client window exists |
| `WINDOW_NOT_FOREGROUND` | Another desktop window would be captured |
| `STATIC_DESKTOP` | Pixels do not show enough changing game content |
| `STUDIO_TEST_FAILED` | StudioTestService did not confirm 15 live bot samples |
| `INCOMPLETE_CAPTURE` | Fewer than 15 PNG frames were saved |

An unsuccessful workflow may attach diagnostic logs and partial PNGs,
but **must never be presented as 15 verified gameplay screenshots**.
