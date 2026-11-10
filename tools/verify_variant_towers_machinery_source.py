#!/usr/bin/env python3
"""Generate real Towers landmark art and reject malformed 3D before upload.

Pure stdlib validation of native envelope and seven glTF material partitions;
does NOT claim Roblox approval, visibility or in-engine performance.
"""
from pathlib import Path
import base64
import hashlib
import json
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
NAME="variant_towers_sculpted_machinery"
SOURCE=ROOT/"tools/generate_original_variant_towers_machinery.py"
CONVERT=ROOT/"tools/obj_to_gltf.py"
MTL=ROOT/"assets/source/chaos_route_kit.mtl"
UPLOADER=(ROOT/".github/workflows/upload-original-3d-models.yml").read_text()
BUILDER=(ROOT/"src/server/MapBuilder.lua").read_text()

with tempfile.TemporaryDirectory(prefix="chaos-original-towers-corner-") as directory:
    obj=Path(directory)/"chaos_variant_towers_sculpted_machinery.obj"
    gltf=Path(directory)/"chaos_original.gltf"
    built=subprocess.run([sys.executable,str(SOURCE),"--output",str(obj)],
        capture_output=True,text=True,check=True,cwd=ROOT)
    meta=json.loads(built.stdout)
    assert meta["asset"]==NAME
    assert 900<=meta["triangles"]<=15000
    assert 55<=meta["groups"]<=400
    assert set(meta["materials"])=={
        "ARMOR","BRUSHED","CARBON","GRIP","ALLOY","CERAMIC","SIGNAL"}
    assert all(abs(value-expected)<.10 for value,expected
               in zip(meta["bounds"],(7.36,24.9,7.36)))
    assert max(map(abs,meta["center"]))<.08
    raw=obj.read_bytes()
    assert hashlib.sha256(raw).hexdigest()==meta["sha256"]
    for marker in (
        b"DodecagonalVariableRadiusMachineryCore",
        b"ForgedTwelveStudStormCanopy",
        b"TriangulatedExternalCrownStrut",
        b"CarbonFrontControlCassette",
        b"DeepForgedTelemetryVent",
        b"CrownCornerGusset",
        b"SealedCentralAntennaFoot",
    ):
        assert marker in raw,marker
    converted=subprocess.run([sys.executable,str(CONVERT),
        "--source",str(obj),"--materials",str(MTL),
        "--output",str(gltf)],capture_output=True,text=True,
        check=True,cwd=ROOT)
    doc=json.loads(gltf.read_text())
    assert doc["asset"]["version"]=="2.0"
    assert {m["name"] for m in doc["materials"]}==set(meta["materials"])
    parts=doc["meshes"][0]["primitives"]
    assert len(parts)==7
    assert sum(doc["accessors"][p["attributes"]["POSITION"]]["count"]//3
               for p in parts)==meta["triangles"]
    assert all({"POSITION","NORMAL","TEXCOORD_0","TANGENT"}
               <=set(p["attributes"]) for p in parts)
    buf=doc["buffers"][0]
    assert len(base64.b64decode(buf["uri"].split(",",1)[1],
                                validate=True))==buf["byteLength"]
    print("PASS seven genuine glTF MeshParts",
          meta["triangles"],meta["bounds"],meta["sha256"])

assert '"TowerMachinery" .. i' in BUILDER
assert '"TowerMachineryCap" .. i' in BUILDER
assert '"TowerAntenna" .. i' in BUILDER
assert "Vector3.new(5.2, 24, 5.2)" in BUILDER
assert "Vector3.new(7.4, 1.0, 7.4)" in BUILDER
assert "Vector3.new(0.55, 9, 0.55)" in BUILDER
assert "variant.Id == \"Towers\" then" in BUILDER
assert NAME in UPLOADER
assert "python3 tools/generate_original_variant_towers_machinery.py" in UPLOADER
assert '"Chaos Towers Sculpted Corner Machinery 3D"' in UPLOADER
print("PASS verified four native Towers corner parts; source only, no fake IDs")
