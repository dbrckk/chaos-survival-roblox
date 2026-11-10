#!/usr/bin/env python3
"""P4 Classic fin runtime contract for Roblox owner-approved 3D cosmetics.

This is code-source validation (no Studio rendered screenshot or Android FPS).
Four fin sources can be hidden only when seven authentic MeshParts are mounted;
all independent glow markers and gameplay collision must remain untouched.
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
NAME="variant_classic_sculpted_broadcast_fin"
ID="123049626693705"
RUN=42866820903
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
SERVER=(ROOT/"src/server/PremiumClassicBroadcastFinAssets.lua").read_text()
CLIENT=(ROOT/"src/client/ApprovedClassicBroadcastFinMeshKit.lua").read_text()
MAP=(ROOT/"src/server/MapBuilder.lua").read_text()
LOD=(ROOT/"src/client/scenery-lod.client.lua").read_text()
INIT=(ROOT/"src/server/init.server.lua").read_text()

row=next(m for m in REG["models"] if m["name"]==NAME)
assert row["asset_id"]==ID
assert row["moderation"]=="Approved"
assert row["workflow_run_id"]==RUN
assert row["source"]=="tools/generate_original_variant_classic_broadcast_fin.py"
assert row["source_materials"]=="assets/source/chaos_route_kit.mtl"
assert ID in SERVER and ID in CLIENT
assert 'OriginalMeshScenery.sanitize(raw)' in SERVER
assert 'if pieces ~= 7 then return false end' in SERVER
assert 'if count~=7 then return nil end' in CLIENT
for tag in ('"OwnerVerified"','"CosmeticOnly"','"Original3DAssetId"',
            '"OriginalClassicBroadcastFin3D"'):
    assert tag in SERVER and tag in CLIENT,tag
assert 'task.defer(PremiumClassicBroadcastFinAssets.start)' in INIT
assert 'require(script.PremiumClassicBroadcastFinAssets)' in INIT
assert 'ApprovedClassicBroadcastFinMeshKit.sync(arena,cameraPoint,' in LOD
assert 'LocalClassicFinMeshCount' in LOD
assert 'LocalClassicFinPrimitivesReplaced' in LOD

# Exactly original four Classic native source parts, two Z-major and
# two X-major, and distinct 10-stud native light strips.
for expected in (
    '"ClassicBroadcastFin" .. i',
    '"ClassicBroadcastGlow" .. i',
    "Vector3.new(-halfX - 5, 8, -18)",
    "Vector3.new(halfX + 5, 8, 18)",
    "Vector3.new(-18, 8, halfZ + 5)",
    "Vector3.new(18, 8, -halfZ - 5)",
    "Vector3.new(1.8, 16, 5.5)",
    "Vector3.new(5.5, 16, 1.8)",
):
    assert expected in MAP,expected
for check in (
    '"ClassicBroadcastFin"..index','"ClassicBroadcastGlow"..index',
    '"Classic"','index<=2','nativeX=index>=3',
    'sourceX=bounds.X>=bounds.Z',
    'CFrame.Angles(0,yaw,0)',
    'Vector3.new(1.8,16,5.5)','Vector3.new(5.5,16,1.8)',
    'Vector3.new(.22,10,5.58)','Vector3.new(5.58,10,.22)',
    'Vector3.new(0,.5,0)',
    'math.abs(glow.Transparency-.24)',
    'math.abs(fin.Transparency-.05)',
    'fin.Transparency=1','native.Transparency=entry.original',
    'source.DescendantRemoving:Connect',
    'clone.DescendantRemoving:Connect',
    'piece.CanCollide=false','piece.CanTouch=false',
    'piece.CanQuery=false','piece.CastShadow=false',
):
    assert check in CLIENT,check
assert 'glow.Transparency=1' not in CLIENT
assert 'glow:Destroy()' not in CLIENT
assert CLIENT.index("clone.Parent=bucket") < CLIENT.index("fin.Transparency=1")
assert 'Low=0,Medium=2,High=4' in CLIENT
assert 'Low=0,Medium=285,High=415' in CLIENT
assert 'math.min(cap,2)' in CLIENT
assert 'math.min(cap,1)' in CLIENT
assert 'if stress>=2 then cap=0 end' in CLIENT
assert 'if cap==0 or not cameraReady' in CLIENT
for forbidden in ('game:GetService("AssetService")',
                  'AssetService.LoadAssetAsync',
                  'RenderStepped','Heartbeat:Connect',
                  'RemoteEvent','RemoteFunction'):
    assert forbidden not in CLIENT,forbidden

# The actual creator's original source is deterministic and aligned exactly
# with both native body orientations. No invented package/mesh identifiers.
with tempfile.TemporaryDirectory(prefix="chaos-p4-classic-fin-live-") as tmp:
    output=Path(tmp)/"original.obj"
    run=subprocess.run([sys.executable,str(ROOT/
        "tools/generate_original_variant_classic_broadcast_fin.py"),
        "--output",str(output)],cwd=ROOT,capture_output=True,text=True,
        check=True)
    meta=json.loads(run.stdout)
    assert meta["asset"]==NAME
    assert tuple(meta["bounds"])==(5.46,15.92,1.76)
    assert tuple(meta["center"])==(0.0,0.0,0.0)
    assert meta["triangles"]==3052
    assert len(meta["materials"])==7
    print("PASS original 7-material Classic mesh",meta["triangles"],
          meta["bounds"],meta["sha256"])
print("PASS validated Roblox owner asset and four correct Classic positions")
print("PASS glow always visible, no colliders, reversible Android LOD")
