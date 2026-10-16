# Arena aerial survey fleet — art direction and QA

New original **3D drone squadron**, separate from the existing ArenaSignature sculptures and hero landmarks. Each arena has its own silhouette geometry as well as color: Classic's
broad survey wings, Towers' stockier service fuselage, Crossroads'
elongated transit wing, and Orbital's long slender gyrocourier
wing profile, with an armored ellipsoid body, shaped delta wings, cockpit glass, polished spine and a dorsal threat beacon. Medium adds paired metal turbines, actual emissive exhausts and a split tail; High adds structural vertical fins, starboard/port beacons, rotating turbine blades, one compact fill light and one short engine filament Trail per vehicle.

**Per-map animation:** Classic orbit watch, Towers high-altitude maintenance flyover, Crossroads transit escort, Orbital faster orbital patrol. Vehicles fly **outside the playable deck bounds**, including wide/rotated maps (the ellipse scales only when needed to preserve at least 8 studs of horizontal clearance during disaster sway), with no collision, touch or query, and do not change player speed, rewards, hazard damage or AI routing. During live rounds drone beacons change to the active disaster color. The
hover/choreography now reacts differently to disaster categories without
adding parts: climb +7 studs above Rising Lava, bank in Tornado, evasive
sway around Meteors/Bombs, buoyant Low Gravity rise, slower circulation
during Freeze and faster patrol under Speed Surge. Final Rush adds a
deliberately steady amber urgent color (no high-frequency strobing). This makes disaster urgency visible in the world without creating fake safe places.

**Android budget:** High = 3 drones / 51 noncolliding parts / at most 3 PointLights and 3 short Trails. Medium = 2 drones / 22 parts / no new Lights or Trails. Low = 1 stationary 6-part silhouette, no animations, lights or trails. Reduced motion freezes the fleet and disables lights/trails. Updates are time-sliced at 0.10s / 0.22s / 0.60s. Clients far from the arena run an idle cadence of 0.65s; global LOD hides the folder when distant. Every map/tier rebuild destroys the old fleet before constructing the new; gameplay state and production DataStores are untouched.

**QA required before publication:** inspect actual mobile silhouette readability, camera clipping on all aspect ratios, scene part count with **all** effects and all disasters active, fleet visibility through Darkness and Meteor bursts, 3D depth sorting, unexpected material rendering and actual Android FPS (goal >=30 stable). Automated tests check exact part caps, non-physical construction, spatial patrol transforms, reduced-motion freeze, tiered lights/trails and VisualBudget inclusion. Passing scripted tests cannot certify AAA art quality or a published Roblox asset.

**Continuous animation and Android idle optimization:** Flight phase now integrates bounded elapsed time (at most 0.30 seconds per update) rather than multiplying wall-clock uptime by a changing hazard speed. Switching between Tornado, Freeze, Speed Surge and normal patrol therefore does not jump the fleet to a new orbit angle. ReduceMotion, Low, inactive phases and distance culling retain the last position instead of teleporting drones to their start pose; the first resumed tick only resynchronizes its clock. Stationary fleets skip redundant part CFrame writes, and unchanged warning colors skip part/Trail/Light color assignments. If the physical arena base moves or resizes, the frozen fleet realigns to it. Engine regression checks cover speed changes, paused/resumed time, bounded stalls and 3D pose preservation; physical Android FPS remains unmeasured.


## Explicit distance culling (12 October 2026)

Previously the drone controller paused distant animation but retained
visible client-owned drone geometry. The existing 145/215/300-stud
Low/Medium/High camera thresholds now also mask parts using
`LocalTransparencyModifier` on visibility transitions only, without
changing authored Transparency or the exact 6/22/51-part budgets.
High-tier PointLights and Trails are disabled while culled and restored
on re-entry. The existing bounded flight clock prevents catch-up jumps.
No new parts, remotes, per-frame listeners, gameplay or server changes.

The existing `aerial-survey.spec.luau` verifies reversible masking,
unchanged alpha, collision safety and effects for all tiers. Physical
Roblox Studio/Android GPU, FPS, thermal and visual tests remain pending.

## Single-owner drone distance visibility and mobile hysteresis (12 October 2026)

The survey controller's 145/215/300-stud Low/Medium/High camera cutoffs
already hid drone Parts using `LocalTransparencyModifier` and gated the
High-tier Trail/PointLight. The generic scene LOD controller also
registered `AerialSurveyLocal`, giving two independent writers ownership
of the same visibility masks. At the camera cutoff the writers could
alternately reveal/hide a drone, creating flicker and repeated GPU-mask
property writes.

`AerialSurveyLocal` is no longer registered as a generic LOD folder.
The fleet builder/controller is its sole visibility owner and reuses the
exact same 145/215/300 thresholds. A pure `AerialSurveyRules.inRange`
policy adds 8-stud hysteresis (initial cutoff exact, previously visible
until +8, previously hidden until -8), including NaN/infinity/distance
guards. It keeps the previous decision on the fleet object; no new
instances, render loops, light sources, remotes, gameplay geometry or
per-frame table allocations are introduced. The generic
`VisualBudgetRules.collect` still counts all aerial geometry and
effects in the total mobile budget.

The engine aerial survey regression checks boundaries and invalid
inputs for Low/Medium/High; the existing scene test already checks
reversible local Part masks and High effects without alpha corruption.
Studio camera-edge and physical Android FPS/GPU measurements remain
unverified.

## Survey craft servo articulation without extra assets (12 October 2026)

The Medium/High service turbines now perform small independent 3D bank
gestures (maximum 0.85 degree); the existing split tail counterbalances
with a quieter pitch (maximum 0.60 degree). The gestures are applied in
the drone's already-running, already-writing geometry update after its
authored flight frame, not in another loop or Tween. Low has neither
component. A reduced-motion, inactive or distance-culled fleet does not
advance or write these servo poses; it preserves its last accessible
static position under the existing freeze contract.

No new Part, Trail, Attachment, Light, sound, collision, network event,
DataStore access or animation cycle is introduced. The engine regression
checks valid poses, all three drone indices, both handed nacelles,
rotated-frame composition, hard angular bounds, and invalid inputs.
Visual clearance, real Android frame time and subjective AAA fidelity
remain unverified pending device/Studio review.

## Coherent turbine group animation (12 October 2026)

The servo movement now applies identically to an existing turbine
nacelle, its paired emissive exhaust and its High-tier rotor. The rotor
adds its previous local spin *after* the shared bounded servo tilt,
preserving the distinct rotor silhouette and a consistent engine group.
The existing split-tail counter-motion is unchanged. Engine tests verify
that all three group pieces return the same local servo transform for
both handed turbines at all three drone indices. No extra parts,
connections, loops, tweens, lights or emitters are added; the fleet
still has 6/22/51 parts across quality tiers. Studio camera clearance
and Android visual performance remain to be tested.

## Immediate accessibility and round-end effect cutoff (12 October 2026)

High-tier survey Trails and PointLights were previously disabled only on
the fleet's next update, which could occur up to 0.65 seconds after
a ReduceMotion toggle or phase transition. The existing RoundState and
LocalPlayer attribute event handlers now call a small
`AerialSurveyKit.suspendEffects` method synchronously when a round becomes
inactive, ReduceMotion becomes true, or VfxQualityTier drops to Low.
This switches off existing High effects immediately while leaving
the 51/22/6 client-local Parts and their authored geometry unchanged.
The regular update and rebuild still own all later animation/resumption.

Core engine tests confirm all 3 Lights and 3 Trails become disabled,
repeated suspend does no work, Low/Medium remain unaffected and no
geometry is allocated or destroyed. No server calls, extra render
loops, new VFX objects or persistent state are added. Physical Android
frame timing and visual response are not yet observed.

## Rapid pause/resume clock normalization (12 October 2026)

An accessibility or round-end event can pause the drone effects and
resume them before the next 0.1–0.65-second update. Effect suspension
now also clears the fleet's previous wall-clock sample, leaving its
already accumulated animation phase intact. On the first resumed tick,
the integration rule therefore re-baselines at the current clock
without applying a stale interval or visually jumping the patrol.
The engine regression explicitly simulates a long pause, asserts that
the flight phase is unchanged on resumption and that the three existing
Trails/PointLights are still safely gated.

## Physically coherent drone gimbal pivots (12 October 2026)

The original service-nacelle motion rotated each turbine, its attached
exhaust and its rotor blade about a *different part center*. Despite
shared angles, offset geometry could slide apart visibly during motion.
`AerialSurveyRules.articulatedSectionFrame` now composes the three
existing pieces about the same authored turbine hinge
(`X = side * 1.08, Y = -0.35, Z = 1.65` in local drone space).
The tail retains its own smaller pitch. Rotor spin remains centered
around the rotor after the shared hinge rotation, with no additional
art geometry, network calls, loops or gameplay colliders.

The dedicated engine regression checks two handed nacelles, three
time samples, exact exhaust/rotor offsets at the shared hinge,
world-frame composition on a rotated rig and invalid roles/inputs.
Low-tier geometry and ReduceMotion/paused or distant poses never run
the new articulation path; real device visual QA is still outstanding.

## Authored wing pose preservation in pivot animation

The shared-gimbal compose path must write a CFrame for **every** section,
not only for the engine/tail branch. The code now computes an optional
articulated local frame then performs one common CFrame write for every
wing, hull, rotor, exhaust, tail and beacon. A regression exercises
wing position and orientation against a corresponding flight frame on
Low/Medium/High. This also preserves the hazard-warning color path for
exhausts.

## Open Cloud test corrections for drone pose and alpha (12 October 2026)

Core B2's first live Roblox engine run at e2890d65 exposed two test
assumptions rather than a runtime drone regression: Low-quality survey
craft never animate, so their authored wing positions must be compared
against the initial non-disaster flight frame (not the Meteors sway
frame); and Roblox BasePart.Transparency is stored with floating-point
rounding (0.22 reads back as approximately 0.2199999988). The engine
regression now explicitly checks Low's frozen flight clock versus
Medium/High motion, applies disaster offsets only to animated tiers,
and compares transparency with a narrow 1e-5 tolerance. Exact tier
budgets, zero-collision geometry, alert colors and ReduceMotion behavior
remain unchanged. Studio/physical Android visual and frame-time QA
are still required.

## Fail-closed drone animation culling (12 October 2026)

`AerialSurveyKit.update` independently gates animation with its explicit
`visible` parameter, rather than relying exclusively on the caller to
translate a distant camera into `reduced=true`. This prevents off-screen
CFrame work, associated orbit calculations and accidentally enabled
High-tier Lights/Trails if another client caller supplies
`visible=false, reduced=false`. The existing on-screen flight phase,
ReduceMotion contract, 6/22/51-part limits and authored 3D geometry are
unchanged. An Open Cloud regression covers Medium/High hiding, long
pauses without catch-up, return and effect restoration. This is a
source-level safeguard, not a measured Android FPS improvement.

## Arena-local drone heading on rotated platforms (12 October 2026)

Survey patrol positions already followed the arena Base's full CFrame, but
the tangent heading was accidentally left in world axes. Consequently a
rotated Crossroads/Towers arena could show visually sideways drone flight.
The flight frame now rotates the local tangent and UpVector through the
same Base CFrame before applying its existing bounded bank. An engine
regression checks rigid-transform invariance of position, forward vector
and up vector for all four maps, all three slots, several timestamps,
and a combined hazard reaction under yaw, pitch and roll. This changes
only cosmetic headings; flight clearance, non-collision, server state,
quality tiers and 6/22/51 geometry budgets remain unchanged. Roblox
Studio/Android perceptual QA is still required.
