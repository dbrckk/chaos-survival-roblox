# Live Ops & Incident Runbook

## Purpose

Premium quality includes what happens when production goes wrong.

## Incident classes

### SEV-0
- data corruption/loss;
- exploit causing major economy/power abuse;
- game broadly unplayable.

Action:
- stop risky rollout;
- disable affected system if possible;
- rollback to known-good;
- preserve logs/evidence.

### SEV-1
- major gameplay blocker;
- severe mobile performance regression;
- monetization delivery failure;
- widespread save outage.

### SEV-2
- degraded feature;
- isolated map/hazard issue;
- cosmetic/UI bug.

## Incident response

1. identify exact production version;
2. reproduce/confirm;
3. define player impact;
4. decide rollback vs hotfix;
5. fix smallest possible scope;
6. run relevant automated gate;
7. smoke test;
8. deploy;
9. verify telemetry;
10. record postmortem.

## Rollback discipline

Every release must know:
- previous good commit/tag;
- what data migrations occurred;
- whether rollback is schema-safe;
- whether paid entitlements remain safe.

## Kill-switch mindset

Where reasonable, risky optional systems should be capable of being disabled without rebuilding the whole experience.

Candidates:
- paid offers;
- experimental social CTA;
- nonessential decorative effect;
- rotating challenge.

Do not add complex remote configuration solely for theoretical flexibility; use it where incident value is real.

## Postmortem template

- what happened?
- player impact?
- start/end?
- detection?
- root cause?
- why tests missed it?
- mitigation?
- permanent prevention?
- documentation/test changed?

No blame language.

## Content/balance cadence

After launch:
- separate bugfix releases from experimental balance changes;
- measure before/after;
- avoid changing many independent variables simultaneously;
- preserve rollback.

## Live-ops scorecard /10

- detection;
- rollback;
- data safety;
- hotfix discipline;
- communication readiness;
- postmortem quality;
- operational simplicity.
