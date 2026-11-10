#!/usr/bin/env python3
"""P4 Classic: validate genuine forged 3D fins, centered envelope and glTF.

Source-only gates. Does not assert Roblox import approval or in-game rendering.
"""
from pathlib import Path
import base64
import hashlib
import json
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
NAME="variant_classic_sculpted_broadcast_fin"
GEN=ROOT/"tools/generate_original_variant_classic_broadcast_fin.py"
CONVERTER=ROOT/"tools/obj_to_gltf.py"
MTL=ROOT/"assets/source/chaos_route_kit.mtl"
MAP=(ROOT/"src/server/MapBuilder.lua").read_text()
UP=(ROOT/".github/workflows/upload-original-3d-models.yml").read_text()

with tempfile.TemporaryDirectory(prefix="chaos-classic-fin-") as work:
    obj=Path(work)/"chaos_variant_classic_sculpted_broadcast_fin.obj"
    gltf=Path(work)/"asset.gltf"
    done=subprocess.run([sys.executable,str(GEN),"--output",str(obj)],
        cwd=ROOT,capture_output=True,text=True,check=True)
    meta=json.loads(done.stdout)
    assert meta["asset"]==NAME
    assert 1300<=meta["triangles"]<=15000,meta
    assert 50<=meta["groups"]<=400,meta
    assert set(meta["materials"])=={
        "ARMOR","BRUSHED","CARBON","GRIP","ALLOY","CERAMIC","SIGNAL"}
    assert all(abs(g-e)<.07 for g,e in
               zip(meta["bounds"],(5.46,15.92,1.76))),meta
    assert max(map(abs,meta["center"]))<.06
    raw=obj.read_bytes()
    assert hashlib.sha256(raw).hexdigest()==meta["sha256"]
    for marker in (
        b"SweptAerodynamicBroadcastCheekFront",
        b"SweptAerodynamicBroadcastCheekRear",
        b"MachinedLowerTransmissionFoundation",
        b"MachinedCrownWindDeflector",
        b"ForgedOuterAeroRib",
        b"EmbeddedFrequencyTick",
        b"InsetAccessPanel",
    ):
        assert marker in raw,marker
    subprocess.run([sys.executable,str(CONVERTER),
        "--source",str(obj),"--materials",str(MTL),
        "--output",str(gltf)],cwd=ROOT,capture_output=True,
        text=True,check=True)
    doc=json.loads(gltf.read_text())
    assert doc["asset"]["version"]=="2.0"
    assert len(doc["meshes"][0]["primitives"])==7
    assert {m["name"] for m in doc["materials"]}==set(meta["materials"])
    assert sum(doc["accessors"][part["attributes"]["POSITION"]]["count"]//3
               for part in doc["meshes"][0]["primitives"])==meta["triangles"]
    assert all({"POSITION","NORMAL","TEXCOORD_0","TANGENT"}
               <=set(part["attributes"])
               for part in doc["meshes"][0]["primitives"])
    buf=doc["buffers"][0]
    assert len(base64.b64decode(buf["uri"].split(",",1)[1],
                                validate=True))==buf["byteLength"]
    print("PASS sculpted Classic source",meta["triangles"],
          meta["groups"],meta["bounds"],meta["sha256"])

for name in (
    '"ClassicBroadcastFin" .. i', '"ClassicBroadcastGlow" .. i',
    "Vector3.new(-halfX - 5, 8, -18)",
    "Vector3.new(halfX + 5, 8, 18)",
    "Vector3.new(-18, 8, halfZ + 5)",
    "Vector3.new(18, 8, -halfZ - 5)",
    "Vector3.new(1.8, 16, 5.5)",
    "Vector3.new(5.5, 16, 1.8)",
    "Vector3.new(0.22, 10, def.size.Z + 0.08)",
    "Vector3.new(def.size.X + 0.08, 10, 0.22)",
):
    assert name in MAP,name
assert NAME in UP
assert "python3 tools/generate_original_variant_classic_broadcast_fin.py" in UP
assert '"Chaos Classic Sculpted Broadcast Fin 3D"' in UP
print("PASS four native fins, four independent glow strips, guarded uploader")
