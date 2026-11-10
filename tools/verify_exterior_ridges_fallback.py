#!/usr/bin/env python3
"""P4 source-level exterior ridge profile fidelity and rollback regression.

Not Roblox Studio simulation: verifies source OBJ geometry, four approved
asset IDs, client native WedgePart guard, coordinates, shared LOD wiring.
"""
from __future__ import annotations
import json
import math
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
CLIENT=(ROOT/"src/client/ApprovedExteriorRidgeMeshKit.lua").read_text()
SERVER=(ROOT/"src/server/PremiumExteriorRidgeAssets.lua").read_text()
BUILDER=(ROOT/"src/server/MapBuilder.lua").read_text()
REGISTRY=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
EXPECTED={
    "NW":(-1,-1,"123836720232695"),
    "NE":(1,-1,"83853948389204"),
    "SW":(-1,1,"108491064314671"),
    "SE":(1,1,"83023096720529"),
}
actual=[
    (name,int(sx),int(sz),asset,tuple(map(int,heights.split(","))),
     tuple(map(float,bounds.split(","))),
     tuple(map(float,offset.split(","))))
    for name,sx,sz,asset,heights,bounds,offset in re.findall(
        r'(NW|NE|SW|SE)=\{sx=(-?\d),sz=(-?\d),id=(\d+),'
        r'heights=\{([\d,]+)\},\s*'
        r'bounds=Vector3\.new\(([^)]+)\),\s*'
        r'offset=Vector3\.new\(([^)]+)\)',CLIENT)
]
assert len(actual)==4,actual
assert len(set(v[0] for v in actual))==4
registered={m["name"]:m for m in REGISTRY["models"]}
assert {name for name,*_ in actual}==set(EXPECTED)
with tempfile.TemporaryDirectory(prefix="chaos-exterior-ridges-") as d:
    for name,sx,sz,asset,heights,bounds,offset in actual:
        assert (sx,sz,asset)==EXPECTED[name]
        expected_heights=tuple(9+((i*7+sx*3+sz*5+20)%11)
                               for i in (1,2,3))
        assert heights==expected_heights,(name,heights)
        source=ROOT/"tools/generate_original_exterior_ridges.py"
        output=Path(d)/f"{name}.obj"
        proc=subprocess.run([sys.executable,str(source),"--model",
                             f"exterior_ridges_{name.lower()}","--output",
                             str(output)],capture_output=True,text=True,
                            check=True,cwd=ROOT)
        meta=json.loads(proc.stdout)
        assert meta["corner"]==name
        assert meta["native_heights"]==list(heights)
        assert 2000<=meta["triangles"]<=18000
        assert len(meta["materials"])==7
        assert all(abs(a-b)<.015 for a,b in zip(bounds,meta["bounds"])),name
        assert all(abs(a-b)<.015 for a,b in zip(offset,meta["offset"])),name
        for label in ("JaggedSculptedRidgeRock","CarbonFracturePanel",
                      "BraidedSideRib","ForgedCrestSpine"):
            assert label in output.read_text(),(name,label)
        key=f"exterior_ridges_{name.lower()}"
        row=registered[key]
        assert row["asset_id"]==asset and row["moderation"]=="Approved"
        assert row["workflow_run_id"]==42854203855
        assert f"id={asset}" in SERVER,(name,"loader")
        assert f"id={asset}" in CLIENT,(name,"client")
        print("PASS genuine",name,asset,meta["triangles"],
              meta["bounds"],meta["offset"])

assert '"ExteriorRidge" .. corner.id' in BUILDER
assert '"Ridge" .. index' in BUILDER
assert "corner.sx * x" in BUILDER and "corner.sz * z" in BUILDER
assert "yaw + (index - 2) * 0.32" in BUILDER
assert 'owner.Name~="ExteriorRidge"..corner' in CLIENT
assert 'ridge:IsA("WedgePart")' in CLIENT
assert 'ridge.CFrame.LookVector:Dot(expected.LookVector)' in CLIENT
assert 'ridge.CFrame.UpVector:Dot(expected.UpVector)' in CLIENT
assert 'ridge.Size-Vector3.new(11+index*3' in CLIENT
assert 'ridge.Transparency~=1' in CLIENT
assert "heights[index]" in CLIENT
assert "owner:GetAttribute(\"ChaosDistantScenery\")~=true" in CLIENT
assert 'part:IsA("WedgePart")' in CLIENT
assert "part.Transparency=alpha" in CLIENT
assert 'model.Parent=bucket' in CLIENT
assert "native.Transparency=1" in CLIENT
assert CLIENT.index("model.Parent=bucket")<CLIENT.index("native.Transparency=1")
assert "source.DescendantRemoving:Connect" in CLIENT
assert 'if cap==0 or not cameraReady' in CLIENT
assert "RenderStepped" not in CLIENT and "Heartbeat" not in CLIENT
assert "p.CanCollide=false" in CLIENT
assert "p.CanTouch=false" in CLIENT and "p.CanQuery=false" in CLIENT
assert "if n~=7 then return false end" in SERVER
assert "OriginalMeshScenery.sanitize(raw)" in SERVER
assert "OwnerVerified" in SERVER
for path in ("src/server/init.server.lua","src/client/scenery-lod.client.lua",
             "src/shared/VisualBudgetRules.lua"):
    assert "ExteriorRidge" in (ROOT/path).read_text(),path
print("PASS all four owner-authenticated seven-MeshPart models,")
print("PASS 12 distinct native WedgeParts, exact transforms, rollback, LOD")
