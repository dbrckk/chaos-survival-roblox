#!/usr/bin/env python3
"""Verify both original Orbital reactor sculptures before Roblox upload.

Pure source OBJ/glTF checks; does not grant moderation or publish a Place.
"""
from pathlib import Path
import base64
import hashlib
import json
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
GEN=ROOT/"tools/generate_original_variant_orbital_landmarks.py"
CONVERT=ROOT/"tools/obj_to_gltf.py"
MTL=ROOT/"assets/source/chaos_route_kit.mtl"
UP=(ROOT/".github/workflows/upload-original-3d-models.yml").read_text()
MAP=(ROOT/"src/server/MapBuilder.lua").read_text()
CHOICES={
    "variant_orbital_sculpted_node":(4.36,4.36,4.36),
    "variant_orbital_trussed_strut":(8.46,1.24,1.10),
}
for source,expected in CHOICES.items():
    with tempfile.TemporaryDirectory(prefix="chaos-orbital-original-") as root:
        obj=Path(root)/(source+".obj")
        gltf=Path(root)/(source+".gltf")
        try:
            run=subprocess.run([sys.executable,str(GEN),"--model",source,
                 "--output",str(obj)],cwd=ROOT,capture_output=True,
                 text=True,check=True)
        except subprocess.CalledProcessError as error:
            print("SOURCE ERROR:",source,error.stderr,file=sys.stderr)
            raise
        meta=json.loads(run.stdout)
        assert meta["asset"]==source,meta
        assert 900<=meta["triangles"]<=16000
        assert 20<=meta["groups"]<=300
        assert set(meta["materials"])=={
            "ARMOR","BRUSHED","CARBON","GRIP","ALLOY","CERAMIC","SIGNAL"}
        assert all(abs(a-b)<.12 for a,b in
                   zip(meta["bounds"],expected)),meta["bounds"]
        assert max(abs(x) for x in meta["center"])<.10,meta
        assert hashlib.sha256(obj.read_bytes()).hexdigest()==meta["sha256"]
        subprocess.run([sys.executable,str(CONVERT),
            "--source",str(obj),"--materials",str(MTL),
            "--output",str(gltf)],cwd=ROOT,capture_output=True,
            text=True,check=True)
        doc=json.loads(gltf.read_text())
        assert doc["asset"]["version"]=="2.0"
        primitives=doc["meshes"][0]["primitives"]
        assert len(primitives)==7
        assert set(m["name"] for m in doc["materials"])==set(meta["materials"])
        assert sum(doc["accessors"][p["attributes"]["POSITION"]]["count"]//3
                   for p in primitives)==meta["triangles"]
        assert all({"POSITION","NORMAL","TEXCOORD_0","TANGENT"}
                   <=set(p["attributes"]) for p in primitives)
        b=doc["buffers"][0]
        assert len(base64.b64decode(b["uri"].split(",",1)[1],
                                    validate=True))==b["byteLength"]
        print("PASS",source,"tris",meta["triangles"],
              "groups",meta["groups"],"bounds",meta["bounds"],
              "sha",meta["sha256"])
    assert source in UP
    assert "--model "+source in UP

for target in (
    '"OrbitalReactorNode" .. i','"OrbitalReactorStrut" .. i',
    'for i = 1, 8 do',
    'Vector3.new(4.4, 4.4, 4.4)',
    'Vector3.new(8.5, 0.55, 0.55)',
    'node.Shape = Enum.PartType.Ball',
    'node.Transparency = 0.20',
    'strut.Transparency = 0.10',
    'math.cos(angle) * radius',
    'math.sin(angle) * radius',
    'math.cos(angle) * (radius - 4.4)',
    'math.sin(angle) * (radius - 4.4)',
):
    assert target in MAP,target
print("PASS 8 nodes and 8 struts in Orbital authoring; two authentic sources")
