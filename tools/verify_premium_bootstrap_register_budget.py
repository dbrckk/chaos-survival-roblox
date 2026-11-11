#!/usr/bin/env python3
"""Release blocker regression: Luau round loop register budget + HUD hints."""
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SRC=(ROOT/"src/server/init.server.lua").read_text()
MECHANICS=(ROOT/"src/server/ArenaMechanics.lua").read_text()
start=SRC.index("local function startPremiumAssets()")
end=SRC.index("\nend\n",start)+len("\nend\n")
scoped=SRC[start:end]
requires=re.findall(
    r'^\s*local (Premium\w+Assets) = require\(script\.\1\)$',
    scoped,re.M)
deferred=re.findall(r'task\.defer\((Premium\w+Assets)\.start\)',scoped)
assert len(requires)==47,(len(requires),requires)
assert len(set(requires))==47
assert requires==deferred,(requires,deferred)
for module in requires:
    assert (ROOT/"src/server"/(module+".lua")).is_file(),module
assert not re.search(
    r'^local Premium\w+Assets = require\(script\.',
    SRC[:start]+SRC[end:],re.M)
assert 'task.defer(startPremiumAssets)' in SRC
assert SRC.count('task.defer(startPremiumAssets)')==1
assert SRC.index('task.defer(OriginalMeshScenery.start)') < SRC.index(
    'task.defer(startPremiumAssets)') < SRC.index('LobbySpawnSafety.start()')
assert SRC.index('if not isStudioE2E then\n    task.defer(OriginalMeshScenery.start)') < SRC.index(
    'task.defer(startPremiumAssets)')
assert 'startPremiumAssets()' not in SRC[end:] # callback only, not blocking
assert 'local eliminated, endedEarly, roundElapsed, eliminationCauses,' in SRC
assert 'balanceMetrics, roundChallenge =' in SRC
assert 'runDisasterSet(selectedSet, contestants, roundSettings)' in SRC
assert 'RoundSettlement.snapshot(' in SRC

start_def=MECHANICS.index('ArenaMechanics.Definitions = {')
end_def=MECHANICS.index('-- Optional dynamic challenges',start_def)
defs=MECHANICS[start_def:end_def]
entries=re.findall(
    r'(Classic|Towers|Crossroads|Orbital|Harbor)\s*=\s*\{\s*'
    r'Name\s*=\s*"([^"]+)",\s*Hint\s*=\s*"([^"]+)"',
    defs,re.S)
assert len(entries)==5
assert len({entry[0] for entry in entries})==5
assert len({entry[1] for entry in entries})==5
for arena,name,hint in entries:
    assert len(name)>=4
    assert 24<=len(hint)<=96,(arena,len(hint),hint)
assert "two blue squall pads in 14s" in dict((x[0],x[2]) for x in entries)["Harbor"]
print("PASS 47 real premium art requires scoped away from main round loop")
print("PASS optional art is deferred without changing per-owner start order")
print("PASS all five arena mechanic hints obey real in-engine HUD limits")
