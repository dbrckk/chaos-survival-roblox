# Exact-source Build + Roblox engine milestone — NO PUBLISH

31 October 2026. Owner explicitly requested continuing to the next important verification stage after Android world-distance LOD fixes (#474 and #475) and previous visual/PBR changes (#459–#473).

## What the one-time workflow does

Workflow: `.github/workflows/one-time-qa-20261031-mobile-lod-no-publish.yml`

- Triggers **once** when that brand-new file is first merged to `main`; it does **not** add a repeat-on-every-PR test.
- Checks that the source `main` SHA exactly matches the workflow's GitHub event commit.
- Dispatches the existing `Build Validation` and `Roblox Open Cloud Engine Tests` manual workflows, using the already-supported GitHub Actions token scope. It does not write Roblox content and no publisher is ever dispatched.
- Records previously existing run IDs before dispatch and accepts **only newly created**, `workflow_dispatch`-triggered runs with exact source SHA, `main` branch and both existing workflow names. Rejects a failed, skipped, cancelled or timed-out check.
- Refuses certification if `main` changes during testing. Reports source SHA and exact successful run URLs as GitHub Actions job summary.
- The 5 engine suites may consume the configured Roblox owner quota. Only the one-time milestone requires these resources; the existing build/engine workflows remain manual.

## What it cannot certify

The workflow executes source/build checks and the existing five real Roblox Open Cloud engine test suites, **not Roblox Studio rendering**. The 75-image five-arena Studio pipeline still requires an authenticated graphical Roblox Studio session and cannot be replaced with synthetic evidence or asserted successful without real outputs.

Actual Android on-device frame rates, thermal throttling, input accuracy, and player retention also remain unverified.

## Next meaningful checks after green build + engine

1. Review actual Studio captures for each of five maps (15 per arena), including near outboard hero structures and four independently culled district landmarks; check Low/Medium/High.
2. Capture a real Android gameplay session for FPS/thermal/contact accuracy and compare the risk cases (camera close to structures at the arena rim, distant opposite-sector landmarks, map transition and low-memory streaming).
3. Before any separate public Roblox release, recheck the exact SHA evidence and publishing authorization; **this validation never publishes**.

Last independently verified public publication before this milestone remains SHA `97a2533cf57e33f74fc2abe9948922e7ac1d8a4f`. No claim of public deployment or AAA certification.
