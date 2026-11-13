#!/usr/bin/env python3
"""Release readiness contract from actual French localization and test suite.

This only verifies deterministic source equivalence; the seven real Roblox
Open Cloud engine suites still run on the exact main release SHA before
the existing public publisher is ever dispatched.
"""
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
readme=(ROOT/"README.md").read_text()
cloud=(ROOT/".github/workflows/roblox-cloud-test.yml").read_text()
specs={p.as_posix().removeprefix(str(ROOT)+"/")
       for p in (ROOT/"tests/engine").glob("*.spec.luau")}
assigned=re.findall(r'"(tests/engine/[^"*]+\.spec\.luau)"',cloud)
assert len(specs)==len(assigned)==len(set(assigned))==87
assert specs==set(assigned)
assert "- 87 engine specs assigned exactly once across Open Cloud CI shards" in readme

loc=(ROOT/"src/shared/CoreLocalization.lua").read_text()
tests=(ROOT/"tests/engine/core-localization.spec.luau").read_text()
expected=[
 "Monte avec les pads cyan ; 3 ponts Skyrail différents donnent un élan bonus",
 "2 pads bleus différents en 14 s donnent un transfert bonus ; évite le balayage",
]
outdated=[
 "Monte les paliers indiqués ; les pads cyan aident à prendre de la hauteur",
 "Les pads bleus relient les quais ; évite les balayages orange ou saute",
]
for statement in expected:
    assert loc.count(statement)==1,("Real localized mechanic not unique",statement)
    assert tests.count(statement)==1,("Engine test not aligned to live text",statement)
for statement in outdated:
    assert statement not in tests,("Stale engine expectation",statement)

suite=(ROOT/"tests/engine/premium-import-diagnostics.spec.luau").read_text()
assert suite.rstrip().endswith("return nil"),"Lest bundling requires return nil"
release=(ROOT/".github/workflows/one-time-public-chaos-premium-3d-retest-20261110.yml").read_text()
assert 'name: One-time Public Chaos Survival Premium 3D Update 2026-11-10 Retest' in release
assert "'Build Validation': 'ci.yml'" in release
assert "'Roblox Open Cloud Engine Tests': 'roblox-cloud-test.yml'" in release
assert "publisher = 'publish-existing-public-playtest.yml'" in release
assert "PUBLISH_EXISTING_10771083668" in release
assert release.index("Pre-publication tests timed out; NOT published.")<release.index(
    "publisher = 'publish-existing-public-playtest.yml'")
print("PASS README and Cloud test shard count: 87 genuine engine specs")
print("PASS French Towers Skyrail and Harbor squall gameplay texts match Lest assertions")
print("PASS exact-main fail-closed release workflow dispatches owner publisher only after green build + engine")
