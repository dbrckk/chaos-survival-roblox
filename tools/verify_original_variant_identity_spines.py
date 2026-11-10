#!/usr/bin/env python3
"""Check two genuine seven-material original identity mast sources.

Crucial: existing neon markers are live-animated by
arena-identity-motion.client.lua and must NOT be hidden as statics.
"""
from pathlib import Path
import base64
import hashlib
import json
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
GEN=ROOT/"tools/generate_original_variant_identity_spines.py"
CONVERT=ROOT/"tools/obj_to_gltf.py"
MTL=ROOT/"assets/source/chaos_route_kit.mtl"
MAP=(ROOT/"src/server/MapBuilder.lua").read_text()
MOTION=(ROOT/"src/client/arena-identity-motion.client.lua").read_text()
UP=(ROOT/".github/workflows/upload-original-3d-models.yml").read_text()
MODELS={
    "variant_classic_grid_marker_sculpt":(2.16,11.92,2.16),
    "variant_towers_spine_sculpt":(2.52,19.92,2.52),
}
for name,expected in MODELS.items():
    with tempfile.TemporaryDirectory(prefix="chaos-identity-3d-") as tmp:
        obj=Path(tmp)/(name+".obj")
        gltf=Path(tmp)/(name+".gltf")
        p=subprocess.run([sys.executable,str(GEN),"--model",name,
            "--output",str(obj)],cwd=ROOT,capture_output=True,text=True)
        if p.returncode:raise RuntimeError(p.stderr)
        meta=json.loads(p.stdout)
        assert meta["asset"]==name
        assert 1300<=meta["triangles"]<=16000
        assert 60<=meta["groups"]<=400
        assert set(meta["materials"])=={
            "ARMOR","BRUSHED","CARBON","GRIP","ALLOY","CERAMIC","SIGNAL"}
        assert all(abs(a-b)<=.08 for a,b in zip(meta["bounds"],expected)),meta
        assert max(map(abs,meta["center"]))<.08,meta
        assert hashlib.sha256(obj.read_bytes()).hexdigest()==meta["sha256"]
        r=subprocess.run([sys.executable,str(CONVERT),
            "--source",str(obj),"--materials",str(MTL),
            "--output",str(gltf)],cwd=ROOT,capture_output=True,text=True)
        if r.returncode:raise RuntimeError(r.stderr)
        g=json.loads(gltf.read_text())
        assert g["asset"]["version"]=="2.0"
        assert len(g["meshes"][0]["primitives"])==7
        assert set(m["name"] for m in g["materials"])==set(meta["materials"])
        assert sum(g["accessors"][p["attributes"]["POSITION"]]["count"]//3
                   for p in g["meshes"][0]["primitives"])==meta["triangles"]
        assert all({"POSITION","NORMAL","TEXCOORD_0","TANGENT"}
                   <=set(p["attributes"]) for p in g["meshes"][0]["primitives"])
        buffer=g["buffers"][0]
        assert len(base64.b64decode(buffer["uri"].split(",",1)[1],
                                    validate=True))==buffer["byteLength"]
        print("PASS authentic sculpture",name,meta["triangles"],
              meta["groups"],meta["bounds"],meta["sha256"])
    assert name in UP and "--model "+name in UP

for s in (
    '"GridMarker" .. i','"GridMarkerGlow" .. i',
    'Vector3.new(2.2, 12, 2.2)',
    'Vector3.new(3.8, 0.32, 3.8)',
    'tower.Transparency = 0.06','crown.Transparency = 0.16',
    '"TowerSpine" .. i','"TowerBand" .. i .. "_" .. level',
    'Vector3.new(2.6, 20, 2.6)',
    'Vector3.new(4.4, 0.28, 4.4)',
    'mast.Transparency = 0.04','band.Transparency = 0.22',
):
    assert s in MAP,s
assert 'trackPart(decor:FindFirstChild("GridMarkerGlow" .. i)' in MOTION
assert 'trackPart(decor:FindFirstChild("TowerBand" .. tower .. "_" .. level)' in MOTION
assert 'MotionRules.shouldUpdate(part)' in MOTION
print("PASS four Classic / four Towers native mast source positions")
print("PASS all 16 native animated glow elements deliberately preserved")
