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
assert 'local LOAD_STAGGER = {36,36,36,36}' in LOADER
assert 'for index, entry in ipairs(SOURCES) do' in LOADER
assert 'task.wait(LOAD_STAGGER[index])' in LOADER
assert 'task.wait(145)' not in LOADER
assert LOADER.count('AssetService.LoadAssetAsync')==1
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
print("PASS staged early request after 36s, exact source provenance and retry")
print("NOTE actual start times include network latency and retry waits")
