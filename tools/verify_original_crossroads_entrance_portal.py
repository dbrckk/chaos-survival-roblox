#!/usr/bin/env python3
"""Validate sculpted, nonblocking Crossroads portals before owner import.

Genuine original OBJ and glTF 7-part geometry, exact 4-gate source layout,
and no Roblox Place publish. This is not an in-engine FPS/screenshot test.
"""
from pathlib import Path
import json
import base64
import hashlib
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
GEN=ROOT/"tools/generate_original_variant_crossroads_entrance_portal.py"
CONVERT=ROOT/"tools/obj_to_gltf.py"
MTL=ROOT/"assets/source/chaos_route_kit.mtl"
BUILDER=(ROOT/"src/server/MapBuilder.lua").read_text()
UP=(ROOT/".github/workflows/upload-original-3d-models.yml").read_text()
NAME="variant_crossroads_sculpted_entrance_portal"
with tempfile.TemporaryDirectory(prefix="chaos-crossroads-interior-") as tmp:
    obj=Path(tmp)/"chaos_variant_crossroads_sculpted_entrance_portal.obj"
    gltf=Path(tmp)/"original.gltf"
    run=subprocess.run([sys.executable,str(GEN),"--output",str(obj)],
        cwd=ROOT,capture_output=True,text=True)
    if run.returncode:
        raise RuntimeError(run.stderr)
    data=json.loads(run.stdout)
    assert data["asset"]==NAME
    assert 1600<=data["triangles"]<=16000
    assert 60<=data["groups"]<=380
    assert all(abs(a-b)<.12 for a,b in
               zip(data["bounds"],(19.2,10.6,1.72))),data
    assert max(abs(c) for c in data["center"])<.08
    assert set(data["materials"])=={
        "ARMOR","BRUSHED","CARBON","GRIP","ALLOY","CERAMIC","SIGNAL"}
    raw=obj.read_bytes()
    assert hashlib.sha256(raw).hexdigest()==data["sha256"]
    for text in (
        b"VariableThicknessOpenHeader",b"TaperedForgedGateJamb",
        b"ContinuousPulseStrip",b"RecessedJambTelemetry",
        b"DiagonalSuspensionWeb",b"ExteriorMooringFoot",
    ):
        assert text in raw,text
    run=subprocess.run([sys.executable,str(CONVERT),
        "--source",str(obj),"--materials",str(MTL),
        "--output",str(gltf)],cwd=ROOT,capture_output=True,text=True)
    if run.returncode:
        raise RuntimeError(run.stderr)
    g=json.loads(gltf.read_text())
    assert g["asset"]["version"]=="2.0"
    assert len(g["meshes"][0]["primitives"])==7
    assert set(m["name"] for m in g["materials"])==set(data["materials"])
    assert sum(g["accessors"][p["attributes"]["POSITION"]]["count"]//3
               for p in g["meshes"][0]["primitives"])==data["triangles"]
    assert all({"POSITION","NORMAL","TEXCOORD_0","TANGENT"}
               <=set(p["attributes"]) for p in g["meshes"][0]["primitives"])
    blob=g["buffers"][0]
    assert len(base64.b64decode(blob["uri"].split(",",1)[1],
                                validate=True))==blob["byteLength"]
    print("PASS original portal: ",data["triangles"],
          data["groups"],data["bounds"],data["sha256"])

# Four rail positions and eight columns are genuine map-authoring pieces.
for marker in (
    '"CrossroadGate" .. i', '"CrossroadPost" .. i',
    'Vector3.new(0, 6, -halfZ + 7)',
    'Vector3.new(0, 6, halfZ - 7)',
    'Vector3.new(-halfX + 7, 6, 0)',
    'Vector3.new(halfX - 7, 6, 0)',
    'Vector3.new(18, 1.2, 1.4)',
    'Vector3.new(1.4, 1.2, 18)',
    'Vector3.new(1.2, 10, 1.2)',
    'Vector3.new(8.5, -5, 0)',
    'Vector3.new(0, -5, 8.5)',
    'rail.Transparency = 0.18',
    'post.Transparency = 0.05',
):
    assert marker in BUILDER,marker
assert NAME in UP
assert 'python3 tools/generate_original_variant_crossroads_entrance_portal.py' in UP
print("PASS four actual Crossroads interior gates and eight original posts")
