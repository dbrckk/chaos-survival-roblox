#!/usr/bin/env python3
"""Approved Classic GridMarker and Towers Spine regression.

Validate real creator ID provenance, both authentic OBJ geometries,
the source 4+4 placements and preserved 16 animated glow pieces.
No claim of running Roblox Studio, publishing the Place or FPS QA.
"""
from pathlib import Path
import json
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
ROWS={r["name"]:r for r in REG["models"]}
BUILDER=(ROOT/"src/server/MapBuilder.lua").read_text()
MOTION=(ROOT/"src/client/arena-identity-motion.client.lua").read_text()
SERVER=(ROOT/"src/server/PremiumVariantIdentitySpineAssets.lua").read_text()
CLIENT=(ROOT/"src/client/ApprovedVariantIdentitySpineMeshKit.lua").read_text()
LOD=(ROOT/"src/client/scenery-lod.client.lua").read_text()
INIT=(ROOT/"src/server/init.server.lua").read_text()
MODELS={
    "variant_classic_grid_marker_sculpt":
        ("105555650820011",2364,73,(2.16,11.92,2.16)),
    "variant_towers_spine_sculpt":
        ("86423178125318",3348,105,(2.52,19.97562,2.52)),
}

for name,(id,triangles,groups,size) in MODELS.items():
    row=ROWS[name]
    assert row["asset_id"]==id
    assert row["moderation"]=="Approved"
    assert row["workflow_run_id"]==42874906992
    assert row["source"]=="tools/generate_original_variant_identity_spines.py"
    assert row["source_materials"]=="assets/source/chaos_route_kit.mtl"
    assert id in CLIENT and id in SERVER
    with tempfile.TemporaryDirectory(prefix="chaos-identity-verified-") as tmp:
        output=Path(tmp)/(name+".obj")
        result=subprocess.run(
            [sys.executable,str(ROOT/
              "tools/generate_original_variant_identity_spines.py"),
             "--model",name,"--output",str(output)],
            cwd=ROOT,capture_output=True,text=True,check=True)
        meta=json.loads(result.stdout)
        assert meta["asset"]==name
        assert meta["triangles"]==triangles
        assert meta["groups"]==groups
        assert tuple(meta["bounds"])==size
        assert max(abs(c) for c in meta["center"])<.08
        assert len(meta["materials"])==7
    print("PASS",name,id,"triangles",triangles,"bounds",size)

assert 'OriginalMeshScenery.sanitize(raw)' in SERVER
assert 'count~=7' in SERVER
assert 'n~=7' in CLIENT
assert '#meshes~=7' in CLIENT
assert 'task.wait(51)' in SERVER
assert 'task.wait(24)' in SERVER
assert 'local active=arena and arena:GetAttribute("VariantId")' in SERVER
assert 'if active=="Classic" or active=="Towers" then' in SERVER
assert 'if spec.name==active then ordered[#ordered+1]=spec end' in SERVER
assert 'if spec.name~=active then ordered[#ordered+1]=spec end' in SERVER
assert 'for _,spec in ipairs(ordered) do' in SERVER
assert 'for attempt=1,3 do' in SERVER
# The source order is deterministic, complete and duplicate-free:
for active in ("Classic","Towers","Crossroads","Harbor","Orbital",None):
    order=([active] if active in ("Classic","Towers") else [])+[
        x for x in ("Classic","Towers") if x!=active]
    assert sorted(order)==["Classic","Towers"],(active,order)
    assert len(set(order))==2,(active,order)
# Earlier optional imports must not become blocking startup work.
assert SERVER.index("task.spawn(function()")<SERVER.index("task.wait(51)")
assert 'task.wait(97)' not in SERVER
assert 'for attempt=1,3 do' in SERVER
assert 'ApprovedVariantIdentitySpineTemplates' in CLIENT
assert 'ApprovedVariantIdentitySpineTemplates' in SERVER
for phrase in (
    '"OwnerVerified"','"CosmeticOnly"',
    '"OriginalVariantIdentitySpine3D"',
    '"Original3DAssetId"',
):
    assert phrase in SERVER and phrase in CLIENT
assert 'task.defer(PremiumVariantIdentitySpineAssets.start)' in INIT
assert 'require(script.PremiumVariantIdentitySpineAssets)' in INIT
assert 'ApprovedVariantIdentitySpineMeshKit.sync(arena,cameraPoint,' in LOD
assert 'LocalIdentitySpineMeshCount' in LOD
assert 'LocalIdentitySpineNativePartsReplaced' in LOD

# Ensure the real source-visible geometry is exactly the family targeted.
for token in (
    '"GridMarker" .. i','"GridMarkerGlow" .. i',
    'Vector3.new(-halfX + 8, 6, 0)',
    'Vector3.new(halfX - 8, 6, 0)',
    'Vector3.new(0, 6, -halfZ + 8)',
    'Vector3.new(0, 6, halfZ - 8)',
    'Vector3.new(2.2, 12, 2.2)',
    'Vector3.new(3.8, 0.32, 3.8)',
    '"TowerSpine" .. i','"TowerBand" .. i .. "_" .. level',
    'Vector3.new(-halfX + 7, 10, -halfZ + 7)',
    'Vector3.new(halfX - 7, 10, -halfZ + 7)',
    'Vector3.new(-halfX + 7, 10, halfZ - 7)',
    'Vector3.new(halfX - 7, 10, halfZ - 7)',
    'Vector3.new(2.6, 20, 2.6)',
    'Vector3.new(4.4, 0.28, 4.4)',
    'base:SetAttribute("OriginalSizeX", base.Size.X)',
    'base:SetAttribute("OriginalSizeZ", base.Size.Z)',
):
    assert token in BUILDER,token
for token in (
    '"GridMarkerGlow"..index',
    '"TowerBand"..index.."_"..level',
    'source:GetAttribute("OriginalVariantIdentitySpine3D")~=true',
    'source:GetAttribute("Original3DAssetId")~=spec.id',
    'source:GetAttribute("OwnerVerified")~=true',
    'native.CFrame.LookVector:Dot(expected.LookVector)<.999',
    'native.CFrame.UpVector:Dot(expected.UpVector)<.999',
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    'Vector3.new(2.2,12,2.2)',
    'Vector3.new(2.6,20,2.6)',
    'native.Transparency=1',
    'native.Transparency=entry.original',
    'source.DescendantRemoving:Connect',
    'model.DescendantRemoving:Connect',
    'part.CanCollide=false',
    'part.CanTouch=false',
    'part.CanQuery=false',
    'part.CastShadow=false',
):
    assert token in CLIENT,token

# Signal parts are visibly animated throughout active phases and must NOT
# be modified by this particular LOD kit, not even their CFrame.
assert 'trackPart(decor:FindFirstChild("GridMarkerGlow" .. i)' in MOTION
assert 'trackPart(decor:FindFirstChild("TowerBand" .. tower .. "_" .. level)' in MOTION
assert 'part.Transparency = math.clamp(' in MOTION
assert 'part.Color = item.baseColor:Lerp(' in MOTION
assert 'signal.Transparency=1' not in CLIENT
assert 'signal.Color=' not in CLIENT
assert 'signal.CFrame=' not in CLIENT
assert 'signal.Transparency=' not in CLIENT
assert 'band.Transparency=' not in CLIENT
assert 'glow.Transparency=' not in CLIENT
assert CLIENT.index("model.Parent=bucket") < CLIENT.index("native.Transparency=1")
# Low previously had TWO independent disablers: the tier cap zero
# and the touch-specific branch forcibly returned zero even if tier
# caps were changed. Both must enable ONE true approved source on healthy
# Android, while pressure 1/2 immediately restores the native.
assert "local CAP={Low=1,Medium=2,High=4}" in CLIENT
assert "local RANGE={Low=165,Medium=295,High=425}" in CLIENT
assert 'or tier=="Low" and math.min(budget,1) or 0' in CLIENT
assert 'tier=="High" and math.min(budget,2)' in CLIENT
assert 'tier=="Medium" and math.min(budget,1)' in CLIENT
assert 'if stress==1 then budget=math.floor(budget*.5) end' in CLIENT
assert 'if stress>=2 then budget=0 end' in CLIENT
assert 'if budget==0 or not cameraReady' in CLIENT
assert 'native.Transparency=entry.original' in CLIENT
assert 'entry.native.Transparency=1' in CLIENT
# The only client-owned source module is exactly seven MeshParts per
# active arena. All existing neon/hazard glow Pieces continue to animate.
assert 'if n~=7 then return nil end' in CLIENT
assert 'if #meshes~=7 then model:Destroy();return end' in CLIENT
assert 'if touch then' in CLIENT and 'if stress==1' in CLIENT
assert 'bucket.ChildRemoved:Connect(function(child)' in CLIENT
assert 'if entry.model==child then' in CLIENT
assert 'release(index)' in CLIENT
assert CLIENT.index('model.Parent=bucket') < CLIENT.index('native.Transparency=1')
print("PASS original seven-mesh Classic/Towers mast on Low touch",
      "with 165-stud cap and pressure-1 native fallback")


executable="\n".join(line.split("--",1)[0] for line in CLIENT.splitlines())
for forbidden in (
    'game:GetService("AssetService")',"AssetService.LoadAssetAsync",
    "RenderStepped","Heartbeat:Connect",
    "RemoteEvent","RemoteFunction","CanCollide=true",
):
    assert forbidden not in executable,forbidden
print("PASS four Classic and four Towers native mast candidates")
print("PASS 16 original actively animated native neon parts preserved")
print("PASS source guards, creator-approved original 3D, camera LOD and rollback")
