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
