# Android real gameplay captures — critical UI legibility pass, 2 Nov 2026

## Reproduced on physical Android screenshots

Owner supplied four **actual landscape Roblox gameplay captures** from the public Chaos Survival experience. A published GitHub workflow run **41428449036** successfully uploaded exact commit `a3e414bea21d6dec9e0d8bed7a454c8b42415699`, previously green in Build Validation **41423662463** and all five Open Cloud engine suites **41423748297**.

Directly visible in those genuine captures:

- **8/8 EN VIE** round-status chip, multiple distinct animated humanoid survivors, playable Crossroads magenta and Towers/Classic cyan arenas, large multilevel 3D structures, dash control and real disaster countdown.
- The core gameplay hazard header remains visible, but **multiple world-space billboard texts, native bot overhead names and optional FLUX mechanic panel compete for the same central field of view**. The 320×320 arenas have enough geometry, but HUD overlap makes the actual action difficult to read.
- On a high-altitude Sky Spine sign, Roblox visibly prints literal **`\\n`** characters between two sentences rather than a line break. The source had Luau literal `"SKY SPINE OPEN\\\\nHOLD TO CONNECT"`; that incorrectly escapes a backslash instead of producing a newline.
- High-intensity magenta/cyan **noninteractive neon environment decoration** competes visually with players, their jump trajectory and real hazards.
- A **floating Android mini-window on the extreme right** belongs to another app over Roblox. It is NOT our HUD and must not trigger destructive fixes to dash/button placements.

The screenshots do **not** prove p95 mobile FPS, all five map routes, real bridge activation, collision after activation, persistence, D1/D7, or latency. Do not interpret 8/8 en vie as proof all eight are humans or the bots' underlying server identities.

## Direct production changes

1. **Correct all three Sky Spine server sign newlines** to actual Luau `\\n` escape sequences in source, producing real 2-line text. Reduce sign screen-space size **210×52 → 160×38** and 3D draw range **90 → 48 studs**. The actual physically interactive `ProximityPrompt` still uses the unchanged **10-stud reach and 0.7-second hold**. Both connected and pre-connected signs use the same rule.
2. **Cut distant world billboard clutter**: Team Dash range **95 → 56 studs**, Shield activator **90 → 55**, simultaneous linked-shield status **100 → 55**; small world-status label dimensions tightened. Activation reach and shield volume/damage logic unaffected.
3. **Reduce Android-only AI overhead name clutter without hiding nearby teammates.** Live survival names max visibility **54 → 42 studs** on Medium/High touch; Low **42 → 33 studs**. READY/intermission name emphasis remains. Desktop unchanged; nameplates remain depth-tested and actual bots keep their independent identities.
4. **Mobile FLUX mechanic panel moves out of the center avatar lane** on wide Android landscape (`centerXScale=0.315`), its max width is capped at **218px**, and its inactive discovery visibility is narrowed to a real gate within **26 studs instead of 42**. Once a player makes the first gate crossing, the timed `1/3–3/3` progression remains clearly visible; short touch text reads `FLUX • PASSE L'ARCHE`. Desktop layout and mechanics unchanged.
5. **Android decorative luminance balance**: reduce only *noninteractive*, non-hazard Neon decor prominence (by raising client-only `LocalTransparencyModifier` from **0.13–0.28** to **0.30–0.50**, depending on quality tier). Do not tamper with actual hazard-warning parts or physically operative controls. Explicitly exempt real **Sky Spine edge strips**, original **Promenade chevrons** and author-tagged **ChaosWayfinding** so jump routes continue to be visible.
6. Update existing `ui-responsive.spec.luau` and `mapbuilder.spec.luau` rather than adding unit-test files; check viewport-safe side lane, distance culling and actual newline rendering in the **real-world Sky Spine BillboardGui**.

## Safety, regression and live release

All work is strictly presentation-only except text parsing of the prompt. No changed server damage, AI navigation, gameplay physics, placement, player-fill, token, RemoteEvent, saving or rewards. No extra per-frame UI canvases, network traffic, particles, public external images or keys.

Do not describe these changes as visually validated until the new source SHA is compiled, all five Roblox Cloud engine suites pass, and **new** real Android screenshots show the actual revised labels, the shifted FLUX panel and readable cyan/magenta arenas. The historical user screenshots describe the **pre-fix public release**.

Public publication has its own **manual-only, authenticated, exact-SHA gated** workflow. Finishing CI does not overwrite the current public place. The public link stays `https://www.roblox.com/games/95351659174730/Chaos-Survival`.
