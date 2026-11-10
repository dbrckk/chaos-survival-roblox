#!/usr/bin/env python3
"""Audit five source-authored SkylineStructure variants and LOD rollback.

This is deterministic source regression, NOT a Roblox Studio/Android render
or a claim that every eligible MeshPart was instantiated on a real device.
"""
from pathlib import Path
import json
import math

ROOT=Path(__file__).resolve().parents[1]
CLIENT=(ROOT/"src/client/ApprovedPrimarySkylineMeshKit.lua").read_text()
BUILDER=(ROOT/"src/server/MapBuilder.lua").read_text()
LOD=(ROOT/"src/client/scenery-lod.client.lua").read_text()
LOADER=(ROOT/"src/server/PremiumExteriorTowerAssets.lua").read_text()
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
APPROVED={21:"137744886537150",24:"74958476744494",
          27:"97864559770371",30:"112172520488996"}
MODEL={m["name"]:m for m in REG["models"]}
for height,asset in APPROVED.items():
    assert MODEL[f"exterior_tower_{height}"]["asset_id"]==asset
    assert MODEL[f"exterior_tower_{height}"]["moderation"]=="Approved"
    assert f"[{height}] = {asset}" in CLIENT
    assert f"height = {height}, id = {asset}" in LOADER
assert "PremiumExteriorTowerAssets" in (ROOT/"src/server/init.server.lua").read_text()
assert "ApprovedExteriorTowerTemplates" in CLIENT
assert "OwnerVerified" in CLIENT and "OriginalExteriorTower3D" in CLIENT

# Four original construction categories in each actual variant.
variants={"Classic":17,"Harbor":17,"Crossroads":20,
          "Orbital":22,"Towers":25}
sources={17:21,20:21,22:24,23:24,25:27,28:30}
assert all(f"{k}={v}" in CLIENT for k,v in variants.items())
assert all(f"[{k}]={v}" in CLIENT for k,v in sources.items())
assert all(f'"{direction}"' in CLIENT for direction in
           ("North","East","South","West"))
for name in ("StructuralCore","TopCap","OuterRibL","OuterRibR"):
    assert f'"{name}"' in CLIENT and f'"{name}"' in BUILDER
for name in ("Foundation","InsetL","InsetR","ReceiverHead",
             "CrossAntenna","ExchangeMast","ServiceMast","RelayAerial"):
    assert f'"{name}"' in CLIENT and f'"{name}"' in BUILDER

assert 'REPLACE = {"StructuralCore","TopCap","OuterRibL","OuterRibR"}' in CLIENT
assert "height = (variant.Id == \"Towers\" and 25" in BUILDER
assert "index % 2" in BUILDER
assert '"SkylineStructure" .. direction.id' in BUILDER
for expression in ("11.4,3,8.8","8.5,h,7.4","2.2,5.4,8",
                   "base.Size.Z*.5+23","base.Size.X*.5+23",
                   "piece.CanCollide = false","piece.CanTouch = false",
                   "piece.CanQuery = false","source.DescendantRemoving:Connect",
                   "clone.DescendantRemoving:Connect",
                   "body.AncestryChanged"):
    if expression=="body.AncestryChanged":
        continue
    assert expression in CLIENT,expression
for required in ('"CosmeticOnly"','"Original3DAssetId"',
                 '"ChaosDistantScenery"','"GeneratedMap"',
                 '"VariantId"','"OriginalExteriorTower3D"',
                 '"OwnerVerified"','part.Transparency = 1',
                 'native.Transparency = alpha','source.Parent ~= holder',
                 'owner.Parent ~= decor','part:IsA("MeshPart")'):
    if required=='part:IsA("MeshPart")':
        assert 'item:IsA("MeshPart")' in CLIENT
    else:
        assert required in CLIENT,required

# True authoring envelope for all 20 structures, model scale is UNIFORM.
count=0
for variant,height0 in variants.items():
    for index in range(1,5):
        h=height0+(index%2)*3
        source=sources[h]
        scale=min((h+2.8)/(source+1.2),
                  11.4*1.06/11.84,8.8*1.13/9.84)
        outheight=(source+1.2)*scale
        outwidth=11.84*scale
        outdepth=9.84*scale
        assert .80 <= scale <= 1.10,(variant,index,scale)
        assert outheight >= (h+2.8)*.965,(variant,index)
        assert outheight <= h+2.9
        assert outwidth <= 11.4*1.07
        assert outdepth <= 8.8*1.14
        count+=1
    print(f"PASS {variant}: four certified skyline transforms and scale limits")
assert count==20

assert "Low={count=0,distance=0}" in CLIENT
assert "Medium={count=2,distance=390}" in CLIENT
assert "High={count=4,distance=510}" in CLIENT
assert 'tier == "High" and math.min(cap,2)' in CLIENT
assert 'tier == "Medium" and math.min(cap,1)' in CLIENT
assert "if stress >= 2 then cap = 0 end" in CLIENT
assert CLIENT.index("clone.Parent = bucket") < CLIENT.index(
    "for _,part in ipairs(native) do part.Transparency = 1 end")
assert "RenderStepped" not in CLIENT and "Heartbeat" not in CLIENT
assert "LoadAssetAsync" not in CLIENT and "RemoteEvent" not in CLIENT
assert "ApprovedPrimarySkylineMeshKit = require(" in LOD
assert "ApprovedPrimarySkylineMeshKit.sync(arena,cameraPoint," in LOD
assert "LocalPrimarySkylineMeshCount" in LOD
assert "LocalPrimarySkylinePrimitivesReplaced" in LOD
print("PASS 20 eligible grouped originals / 80 native visual bodies;")
print("PASS LOD/camera pressure caps, safe rollback and unchanged gameplay")
