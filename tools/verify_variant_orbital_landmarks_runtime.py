#!/usr/bin/env python3
"""Original owner-approved Orbital reactor pair regression (source-level).

Enforce both real approved package IDs, exact 8+8 native targets, atomic
hide/restore, cosmetics-only and the bounded mobile camera-driven LOD.
Not a substitute for Roblox Studio / Android runtime rendering.
"""
from pathlib import Path
import json
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
CLIENT=(ROOT/"src/client/ApprovedOrbitalReactorLandmarkMeshKit.lua").read_text()
SERVER=(ROOT/"src/server/PremiumOrbitalReactorLandmarkAssets.lua").read_text()
MAP=(ROOT/"src/server/MapBuilder.lua").read_text()
INIT=(ROOT/"src/server/init.server.lua").read_text()
LOD=(ROOT/"src/client/scenery-lod.client.lua").read_text()
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
ROWS={m["name"]:m for m in REG["models"]}
REAL={
    "variant_orbital_sculpted_node":"104654294187035",
    "variant_orbital_trussed_strut":"138666009076890",
}
for name,id in REAL.items():
    row=ROWS[name]
    assert row["asset_id"]==id
    assert row["moderation"]=="Approved"
    assert row["workflow_run_id"]==42869295978
    assert row["source"]=="tools/generate_original_variant_orbital_landmarks.py"
    assert row["source_materials"]=="assets/source/chaos_route_kit.mtl"
    assert id in CLIENT and id in SERVER
assert 'OriginalMeshScenery.sanitize(raw)' in SERVER
assert 'if count~=7 then return false end' in SERVER
assert 'if count~=7 then return nil end' in CLIENT
assert '#entry.nodePieces~=7 or #entry.strutPieces~=7' in CLIENT
assert 'source:GetAttribute("OriginalOrbitalReactorLandmark3D")~=true' in CLIENT
assert 'source:GetAttribute("Original3DAssetId")~=id' in CLIENT
assert 'holder:GetAttribute("OwnerVerified")~=true' in CLIENT
assert 'item.CanCollide' in CLIENT and 'item.CanTouch' in CLIENT
assert 'item.CanQuery' in CLIENT
assert 'task.wait(112)' in SERVER
assert 'task.wait(8)' in SERVER
assert 'for attempt=1,3 do' in SERVER
assert 'task.defer(PremiumOrbitalReactorLandmarkAssets.start)' in INIT
assert 'require(script.PremiumOrbitalReactorLandmarkAssets)' in INIT
assert 'ApprovedOrbitalReactorLandmarkMeshKit.sync(arena,cameraPoint,' in LOD
assert 'LocalOrbitalReactorSculptPairCount' in LOD
assert 'LocalOrbitalReactorNativePartsReplaced' in LOD

for snippet in (
    '"OrbitalReactorNode" .. i',
    '"OrbitalReactorStrut" .. i',
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
    assert snippet in MAP,snippet

for snippet in (
    'for index=1,8 do',
    '"OrbitalReactorNode"..index',
    '"OrbitalReactorStrut"..index',
    'Enum.PartType.Ball,.20',
    'Enum.PartType.Block,.10',
    'Vector3.new(4.4,4.4,4.4)',
    'Vector3.new(8.5,.55,.55)',
    'math.max(base.Size.X*.5,base.Size.Z*.5)+7',
    '9+(index%2)*3',
    'cosine*(radius-4.4)',
    'sine*(radius-4.4)',
    'CFrame.Angles(0,-angle,0)',
    'node.Transparency=1',
    'strut.Transparency=1',
    'native.Transparency=alpha',
    'source.DescendantRemoving:Connect',
    'model.DescendantRemoving:Connect',
    'part.CanCollide=false',
    'part.CanTouch=false',
    'part.CanQuery=false',
    'part.CastShadow=false',
):
    assert snippet in CLIENT,snippet
assert CLIENT.index('wrapper.Parent=bucket')<CLIENT.index('node.Transparency=1')
assert CLIENT.index('node.Transparency=1')<CLIENT.index('strut.Transparency=1')
assert 'Low=0,Medium=3,High=6' in CLIENT
assert 'Low=0,Medium=340,High=460' in CLIENT
assert 'math.min(cap,3)' in CLIENT and 'math.min(cap,1)' in CLIENT
assert 'if pressureLevel>=2 then cap=0 end' in CLIENT
assert 'if cap==0 or not cameraReady' in CLIENT
for forbidden in ('game:GetService("AssetService")',
                  'AssetService.LoadAssetAsync',
                  'RenderStepped','Heartbeat:Connect',
                  'RemoteEvent','RemoteFunction'):
    assert forbidden not in CLIENT,forbidden

geometry={
    "variant_orbital_sculpted_node":((4.36,4.36,4.36),2444),
    "variant_orbital_trussed_strut":((8.46,1.24,1.10),2488),
}
with tempfile.TemporaryDirectory(prefix="chaos-orbital-approved-pair-") as tmp:
    for name,(dims,triangles) in geometry.items():
        output=Path(tmp)/(name+".obj")
        p=subprocess.run([sys.executable,str(ROOT/
            "tools/generate_original_variant_orbital_landmarks.py"),
            "--model",name,"--output",str(output)],
            cwd=ROOT,capture_output=True,text=True,check=True)
        meta=json.loads(p.stdout)
        assert meta["asset"]==name
        assert tuple(meta["bounds"])==dims
        assert tuple(meta["center"])==(0.0,0.0,0.0)
        assert meta["triangles"]==triangles
        assert len(meta["materials"])==7
        print("PASS approved original source",name,meta["triangles"],meta["bounds"])
print("PASS 8 genuine Orbital pairs, atomic hide AFTER 14 MeshParts, rollback")
print("PASS zero gameplay collision and camera/mobile pressure budgets")
