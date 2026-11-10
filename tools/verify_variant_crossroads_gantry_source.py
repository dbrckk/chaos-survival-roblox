#!/usr/bin/env python3
"""Deterministic inspection of actual open gantry source and exported glTF.

Rejects a malformed 3D source before invoking the owner-import workflow.
No Roblox place publication, created asset claims or runtime QA.
"""
from pathlib import Path
import base64
import hashlib
import json
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
NAME="variant_crossroads_forged_gantry"
GEN=ROOT/"tools/generate_original_variant_crossroads_gantry.py"
CONVERT=ROOT/"tools/obj_to_gltf.py"
MTL=ROOT/"assets/source/chaos_route_kit.mtl"
MAP=(ROOT/"src/server/MapBuilder.lua").read_text()
UPLOADER=(ROOT/".github/workflows/upload-original-3d-models.yml").read_text()

with tempfile.TemporaryDirectory(prefix="chaos-crossroads-gantry-") as directory:
    obj=Path(directory)/"chaos_variant_crossroads_forged_gantry.obj"
    gltf=Path(directory)/"chaos_original.gltf"
    result=subprocess.run([sys.executable,str(GEN),"--output",str(obj)],
        cwd=ROOT,capture_output=True,text=True,check=True)
    meta=json.loads(result.stdout)
    assert meta["asset"]==NAME
    assert 1200<=meta["triangles"]<=15000
    assert 45<=meta["groups"]<=400
    assert set(meta["materials"])=={
        "ARMOR","BRUSHED","CARBON","GRIP","ALLOY","CERAMIC","SIGNAL"}
    assert all(abs(x-y)<.12 for x,y in
               zip(meta["bounds"],(27.92,3.6,2.74))),meta
    assert max(map(abs,meta["center"]))<.10,meta
    raw=obj.read_bytes()
    assert hashlib.sha256(raw).hexdigest()==meta["sha256"]
    for marker in (
        b"ContinuousForgedUpperChannel",
        b"ContinuousForgedLowerKeel",
        b"MachinedFullSpanWeatherFlange",
        b"ForgedAlternatingWeb",
        b"CrossstitchWeb",
        b"DeepInsetCarbonCableRace",
        b"RecessedServiceReader",
    ):
        assert marker in raw,marker
    subprocess.run([sys.executable,str(CONVERT),
        "--source",str(obj),"--materials",str(MTL),
        "--output",str(gltf)],cwd=ROOT,capture_output=True,text=True,
        check=True)
    g=json.loads(gltf.read_text())
    assert g["asset"]["version"]=="2.0"
    assert {m["name"] for m in g["materials"]}==set(meta["materials"])
    meshes=g["meshes"][0]["primitives"]
    assert len(meshes)==7
    assert sum(g["accessors"][p["attributes"]["POSITION"]]["count"]//3
               for p in meshes)==meta["triangles"]
    assert all({"POSITION","NORMAL","TEXCOORD_0","TANGENT"}
               <=set(p["attributes"]) for p in meshes)
    b=g["buffers"][0]
    assert len(base64.b64decode(b["uri"].split(",",1)[1],
                                validate=True))==b["byteLength"]
    print("PASS genuine open 3D truss",meta["triangles"],
          meta["bounds"],meta["sha256"])

# The two X-axis and two Z-axis native gantries are decorative, with
# independent 18-stud signal strips kept as a world-space reference.
for expected in ('"CrossroadGantry" .. i','"CrossroadSignal" .. i',
                 'Vector3.new(0, 8, -halfZ - 4)',
                 'Vector3.new(0, 8, halfZ + 4)',
                 'Vector3.new(-halfX - 4, 8, 0)',
                 'Vector3.new(halfX + 4, 8, 0)',
                 'Vector3.new(28, 2.0, 2.0)',
                 'Vector3.new(2.0, 2.0, 28)'):
    assert expected in MAP,expected
assert NAME in UPLOADER
assert 'python3 tools/generate_original_variant_crossroads_gantry.py' in UPLOADER
assert '"Chaos Crossroads Open Forged Gantry 3D"' in UPLOADER
print("PASS exact four Crossroads gantries, reversible source-only import")
