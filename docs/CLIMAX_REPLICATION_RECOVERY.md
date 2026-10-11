# Climax VFX and late arena replication

The local climax controller retries a RoundState snapshot if the arena Base
has not yet replicated. Delays are 0.15, 0.35 and 0.70 seconds; after that,
it waits for a fresh RoundState event. Each new event supersedes old retry
callbacks. Exiting the round cancels them. If the arena Base changes mid-round,
the new arena receives its own visual stage and previous pending bursts are
invalidated.

This is presentation-only. Damage, physics, rewards and server-side hazards
are unchanged. No polling or per-frame listeners were added.

Automated regression: tests/engine/disaster-climax.spec.luau checks the
bounded retry schedule and malformed attempts, alongside existing stale
burst guards.

Pending manual acceptance: simulate delayed Base replication in Studio;
verify no old bursts after phase/map changes; inspect Double Chaos warning
visibility and rotated arenas; profile Android FPS, GPU and thermals.
