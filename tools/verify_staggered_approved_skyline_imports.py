#!/usr/bin/env python3
"""P4 static regression: earlier approved tower availability, no API burst.

Only source timing/load contract; not proof of observed Roblox join FPS.
"""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[1]
LOADER=(ROOT/"src/server/PremiumExteriorTowerAssets.lua").read_text()
INIT=(ROOT/"src/server/init.server.lua").read_text()
SCENERY=(ROOT/"src/client/scenery-lod.client.lua").read_text()
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
rows={m["name"]:m for m in REG["models"]}
ids=[(21,"137744886537150"),(24,"74958476744494"),
     (27,"97864559770371"),(30,"112172520488996")]
for height,asset in ids:
    assert f"height = {height}, id = {asset}" in LOADER
    assert rows[f"exterior_tower_{height}"]["asset_id"]==asset
    assert rows[f"exterior_tower_{height}"]["moderation"]=="Approved"
assert 'local PRIORITY_BY_VARIANT = {' in LOADER
for variant, heights in {"Classic":"{21}", "Harbor":"{21}",
                         "Crossroads":"{21,24}", "Orbital":"{24,27}",
                         "Towers":"{27,30}"}.items():
    assert f"{variant} = {heights}" in LOADER
assert 'local ordered, activeCount = prioritizedSources()' in LOADER
assert 'for index, entry in ipairs(ordered) do' in LOADER
assert 'task.wait(26)' in LOADER
assert 'task.wait(index <= activeCount and 10 or 34)' in LOADER
assert 'selected[entry.height]' in LOADER
assert 'generated.Parent == workspace' in LOADER
assert 'task.wait(145)' not in LOADER
assert LOADER.count('GlobalApprovedImportGate.load')==1
assert 'require("./PremiumApprovedAssetImportGate")' in LOADER
assert LOADER.count('task.spawn')==1
assert 'task.wait(5)' in LOADER
assert 'for attempt = 1, 3 do' in LOADER
assert 'task.wait(attempt*5)' in LOADER
assert 'OriginalMeshScenery.sanitize(raw)' in LOADER
assert 'if n ~= 7 then return false end' in LOADER
assert '"OwnerVerified"' in LOADER
assert '"OriginalExteriorTower3D"' in LOADER
assert 'task.defer(PremiumExteriorTowerAssets.start)' in INIT
assert 'ApprovedExteriorTowerMeshKit.sync(arena,cameraPoint,' in SCENERY
assert 'ApprovedPrimarySkylineMeshKit.sync(arena,cameraPoint,' in SCENERY
assert 'ApprovedSkylineDepthMeshKit.sync(arena,cameraPoint,' in SCENERY
assert 'task.wait(62)' in (ROOT/"src/server/PremiumVariantTowersLandmarkAssets.lua").read_text()
print("PASS four original verified Models, same 1 serialized AssetService lane")
print("PASS active variant imported first after 26s; inactive sources staggered")
print("NOTE actual start times include network latency and retry waits")
