#!/usr/bin/env python3
"""Runtime source regression for verified Crossroads boundary gantry 3D.

No claims of real Roblox Studio/Android FPS: source integrity and reversible
nonphysical placement only, plus verified creator moderation provenance.
"""
from pathlib import Path
import json
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
MODEL="variant_crossroads_forged_gantry"
ID="90844491148907"
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
CLIENT=(ROOT/"src/client/ApprovedCrossroadsOpenGantryMeshKit.lua").read_text()
LOADER=(ROOT/"src/server/PremiumCrossroadsGantryAssets.lua").read_text()
MAP=(ROOT/"src/server/MapBuilder.lua").read_text()
INIT=(ROOT/"src/server/init.server.lua").read_text()
LOD=(ROOT/"src/client/scenery-lod.client.lua").read_text()
REQUIRED={
    "name":MODEL, "asset_id":ID, "moderation":"Approved",
    "workflow_run_id":42864120791,
    "source":"tools/generate_original_variant_crossroads_gantry.py",
    "source_materials":"assets/source/chaos_route_kit.mtl",
}
reg=next(m for m in REG["models"] if m["name"]==MODEL)
for key,value in REQUIRED.items():
    assert reg[key]==value,(key,reg[key],value)
assert ID in CLIENT and ID in LOADER
assert '"ApprovedCrossroadsGantryTemplates"' in LOADER
assert '"ApprovedCrossroadsGantryTemplates"' in CLIENT
assert '"OriginalCrossroadsGantry3D"' in CLIENT
assert '"OriginalCrossroadsGantry3D"' in LOADER
assert '"OwnerVerified"' in CLIENT and '"OwnerVerified"' in LOADER
assert '"Original3DAssetId"' in CLIENT and '"Original3DAssetId"' in LOADER
assert 'OriginalMeshScenery.sanitize(raw)' in LOADER
assert "parts ~= 7" in LOADER
assert "n~=7" in CLIENT and "#parts~=7" in CLIENT
assert 'ActiveSignatureSchedule.waitFor("Crossroads",46,98)' in LOADER
assert 'require("./PremiumActiveVariantImportSchedule")' in LOADER
assert 'task.wait(98)' not in LOADER
assert LOADER.count('task.spawn(function()') == 1
assert LOADER.count('GlobalApprovedImportGate.load') == 1
assert "GlobalApprovedImportGate.load" in LOADER
assert 'require("./PremiumApprovedAssetImportGate")' in LOADER
assert "game:GetService(\"AssetService\")" not in CLIENT
assert "AssetService.LoadAssetAsync" not in CLIENT
assert "task.defer(PremiumCrossroadsGantryAssets.start)" in INIT
assert "require(script.PremiumCrossroadsGantryAssets)" in INIT
assert "ApprovedCrossroadsOpenGantryMeshKit.sync(arena,cameraPoint," in LOD
assert "LocalCrossroadsGantryMeshCount" in LOD
assert "LocalCrossroadsGantryPrimitivesReplaced" in LOD

# Verify all four original prefabs are inspected before conversion, and
# both orthogonal placements use exactly the same source geometry.
for literal in (
    '"CrossroadGantry"..index','"CrossroadSignal"..index',
    'originalZ*.5+4','originalX*.5+4',
    'originalFootprint(base, arena)',
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    'Vector3.new(28,2,2)','Vector3.new(2,2,28)',
    'Vector3.new(18,.34,2.12)','Vector3.new(2.12,.34,18)',
    'index<=2','desiredX=index<=2',
    'CFrame.Angles(0,yaw,0)','ASSET_ID=90844491148907',
    'math.abs(size.Y-SIZE.Y)>.4',
    'piece.CanCollide=false','piece.CanTouch=false',
    'piece.CanQuery=false','piece.CastShadow=false',
    'body.Transparency=1','body.Transparency=entry.original',
    'source.DescendantRemoving:Connect',
    'clone.DescendantRemoving:Connect',
):
    assert literal in CLIENT,literal
for native in ('"CrossroadGantry" .. i','"CrossroadSignal" .. i',
               'Vector3.new(0, 8, -halfZ - 4)',
               'Vector3.new(0, 8, halfZ + 4)',
               'Vector3.new(-halfX - 4, 8, 0)',
               'Vector3.new(halfX + 4, 8, 0)'):
    assert native in MAP,native
assert 'signal.Transparency=1' not in CLIENT
assert 'signal:Destroy()' not in CLIENT
assert 'if tier=="High" and touch then' not in CLIENT
assert 'Low=1,Medium=2,High=4' in CLIENT
assert 'Low=180,Medium=290,High=410' in CLIENT
assert 'math.min(cap,2)' in CLIENT and 'math.min(cap,1)' in CLIENT
assert 'if touch and tier~="Low" then' in CLIENT
assert 'if stress==1 then cap=math.floor(cap*.5) end' in CLIENT
assert 'if stress>=2 then cap=0 end' in CLIENT
assert CLIENT.index("clone.Parent=folder")<CLIENT.index("body.Transparency=1")
for forbidden in ("RenderStepped","Heartbeat","LoadAssetAsync",
                  "RemoteEvent","RemoteFunction","CanCollide=true"):
    assert forbidden not in CLIENT,forbidden

# Genuine source bounds exact and consistent with server loader envelope.
with tempfile.TemporaryDirectory(prefix="chaos-crossroads-live-") as d:
    out=Path(d)/"model.obj"
    p=subprocess.run([sys.executable,
        str(ROOT/"tools/generate_original_variant_crossroads_gantry.py"),
        "--output",str(out)],cwd=ROOT,capture_output=True,text=True,
        check=True)
    metadata=json.loads(p.stdout)
    assert metadata["asset"]==MODEL
    assert tuple(metadata["bounds"])==(27.92,3.6,2.74)
    assert tuple(metadata["center"])==(0.0,0.0,0.0)
    assert len(metadata["materials"])==7
    print("PASS genuine original source",metadata["triangles"],
          metadata["bounds"])
print("PASS approved owner asset and four orthogonal Crossroads placements")
print("PASS 4 reversible native gantries; signals untouched; mobile LOD caps")
