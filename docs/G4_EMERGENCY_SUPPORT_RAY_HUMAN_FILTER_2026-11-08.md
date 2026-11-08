# G4 – Hazard escape support probes in populated rounds

Source change: `9f5f3394fc1e5486f708cfffcf650f6c983541ae`

## Defect
`saferThreatEscape` performs real physical support raycasts (current high deck plus two samples on each candidate heading). These rays already ignored the NPC folder, but **did not ignore connected human characters**. When a player is standing above a platform or at the sampling point, a ray can hit a mobile character rather than the immutable floor, causing an otherwise safe landing to be rejected. If multiple directions fail, the bot holds its current position in an active Meteor/Bomb footprint.

## Correction
Use one `RaycastParams` exclusion list per genuine escape-plan computation:
- Exclude the existing NPC folder (or the bot's rig if that folder is absent).
- Exclude each currently connected player's `Character` model.
- Keep `RespectCanCollide = true`, the original physical floor/platform checks, six headings, two sampled landings and original plan timing.

No additional raycasts, fake support parts, teleportation, immunity, movement speed changes, repeated Workspace scans or client authority.

## Engine acceptance
1. Stand a real player on a bot's low-floor emergency sample, spawn MeteorWarning nearby, and check that the bot finds a physically supported evacuation instead of interpreting the player as missing footing.
2. Stand several human participants on a valid sky platform near the proposed departure/landing samples. Confirm the bot continues using the **real** same platform; never route onto empty space or across unconnected decks.
3. Introduce a genuine missing/collapsing platform with human avatars nearby. Verify filtering humans does **not** make an invalid surface pass the floor and `platformAvailable` checks.
4. Repeat with multiple Meteor/Bomb warnings and a group of eight participants; monitor the number of emergency choices, actual survival and Android frame time.
5. Confirm no avatar suppression of collision in gameplay: the exclusion changes **raycast results only**. Physical collisions stay owned by Roblox.
6. Confirm when `botsFolder` is temporarily missing, the bot's own rig is still excluded.

## Verification gate
Eight source-structure checks passed, including no change in the number of raycast sites or authored floor conditions. This is not an Engine or Android runtime test. Run the repository's exact-SHA Cloud/build checks at release milestone before merging/publishing, or accept owner gameplay validation with that limitation clearly stated.
