#!/usr/bin/env python3
"""P4 interior Crossroads: approved source and reversible runtime contract.

This is a deterministic source CI gate, NOT a Roblox Studio/Android
visual inspection or public Place publication verification.
"""
from pathlib import Path
import json
import math
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
NAME="variant_crossroads_sculpted_entrance_portal"
ID="127067628128103"
RUN=42872132972
REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
CLIENT=(ROOT/"src/client/ApprovedCrossroadsEntrancePortalMeshKit.lua").read_text()
SERVER=(ROOT/"src/server/PremiumCrossroadsEntrancePortalAssets.lua").read_text()
BUILDER=(ROOT/"src/server/MapBuilder.lua").read_text()
INIT=(ROOT/"src/server/init.server.lua").read_text()
LOD=(ROOT/"src/client/scenery-lod.client.lua").read_text()
row=next(x for x in REG["models"] if x["name"]==NAME)
assert row["asset_id"]==ID and row["moderation"]=="Approved"
assert row["workflow_run_id"]==RUN
assert row["source"]=="tools/generate_original_variant_crossroads_entrance_portal.py"
assert row["source_materials"]=="assets/source/chaos_route_kit.mtl"
assert ID in CLIENT and ID in SERVER
assert 'OriginalMeshScenery.sanitize(raw)' in SERVER
assert 'if n~=7 then return false end' in SERVER
assert 'if n~=7 then return nil end' in CLIENT
assert '#meshParts~=7' in CLIENT
assert 'ActiveSignatureSchedule.waitFor("Crossroads",44,92)' in SERVER
assert 'require("./PremiumActiveVariantImportSchedule")' in SERVER
assert 'task.wait(92)' not in SERVER
assert SERVER.count('task.spawn(function()') == 1
assert SERVER.count('GlobalApprovedImportGate.load') == 1
assert 'for attempt=1,3 do' in SERVER
assert 'GlobalApprovedImportGate.load' in SERVER
assert 'require("./PremiumApprovedAssetImportGate")' in SERVER
assert 'source:GetAttribute("OriginalCrossroadsEntrancePortal3D")~=true' in CLIENT
assert 'source:GetAttribute("Original3DAssetId")~=ID' in CLIENT
assert 'source:GetAttribute("OwnerVerified")~=true' in CLIENT
assert 'holder:GetAttribute("OwnerVerified")~=true' in CLIENT
assert 'task.defer(PremiumCrossroadsEntrancePortalAssets.start)' in INIT
assert 'require(script.PremiumCrossroadsEntrancePortalAssets)' in INIT
assert 'ApprovedCrossroadsEntrancePortalMeshKit.sync(arena,cameraPoint,' in LOD
assert 'LocalCrossroadsEntrance3DCount' in LOD
assert 'LocalCrossroadsEntranceNativePartsReplaced' in LOD
for marker in (
    'Vector3.new(0, gateY, -halfZ + 7)',
    'Vector3.new(0, gateY, halfZ - 7)',
    'Vector3.new(-halfX + 7, gateY, 0)',
    'Vector3.new(halfX - 7, gateY, 0)',
    '"CrossroadGate" .. i',
    '"CrossroadPost" .. i',
    'Vector3.new(18, 1.2, 1.4)',
    'Vector3.new(1.4, 1.2, 18)',
    'Vector3.new(1.2, 10, 1.2)',
    'Vector3.new(8.5, 0, 0)',
    'Vector3.new(0, 0, 8.5)',
    'local gateY = variant.BaseSize.Y * 0.5 + 10',
    'local postCenter = rail.Position - Vector3.new(0, 5, 0)',
    'CFrame.new(postCenter + lateral * sign)',
    'rail.Transparency = 0.18',
    'post.Transparency = 0.05',
    'base:SetAttribute("OriginalSizeX", base.Size.X)',
    'base:SetAttribute("OriginalSizeZ", base.Size.Z)',
):
    assert marker in BUILDER,marker
for marker in (
    'for index=1,4 do',
    '"CrossroadGate"..index',
    '"CrossroadPost"..index.."_"..tostring(sign)',
    'for _,sign in ipairs({-1,1}) do',
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    'alongX=index<=2',
    'nativeAlongX=index<=2',
    'sourceAlongX=size.X>=size.Z',
    'CFrame.Angles(0,yaw,0)',
    'frame*CFrame.new(0,-4.7,0)',
    'local gateY=base.Size.Y*.5+10',
    'CFrame.new(postCenter+lateral*sign)',
    'actualSize=Vector3.new(actualSize.Z,actualSize.Y,actualSize.X)',
    'Vector3.new(18,1.2,1.4)',
    'Vector3.new(1.4,1.2,18)',
    'Vector3.new(1.2,10,1.2)',
    'Vector3.new(8.5,0,0)',
    'Vector3.new(0,0,8.5)',
    'model.Parent=bucket',
    'native.Transparency=1',
    'native.Transparency=alpha',
    'part.CanCollide=false',
    'part.CanTouch=false',
    'part.CanQuery=false',
    'part.CastShadow=false',
    'source.DescendantRemoving:Connect',
    'model.DescendantRemoving:Connect',
):
    assert marker in CLIENT,marker
assert CLIENT.index('model.Parent=bucket')<CLIENT.index(
    'for native in pairs(natives) do native.Transparency=1 end')
assert 'Low=1,Medium=2,High=4' in CLIENT
assert 'Low=180,Medium=340,High=470' in CLIENT
assert 'math.min(cap,2)' in CLIENT and 'math.min(cap,1)' in CLIENT
assert 'if touch and tier~="Low" then' in CLIENT
assert 'if stress==1 then cap=math.floor(cap*.5) end' in CLIENT
assert 'if stress>=2 then cap=0 end' in CLIENT
assert 'if cap==0 or not cameraReady' in CLIENT
# Comments documenting the absence of a loop are not executable Lua.
# Detect forbidden API calls only in actual source statements.
client_code="\n".join(line.split("--",1)[0] for line in CLIENT.splitlines())
for forbidden in ('game:GetService("AssetService")',
                  'AssetService.LoadAssetAsync',
                  'RenderStepped','Heartbeat:Connect',
                  'RemoteEvent','RemoteFunction','CanCollide=true'):
    assert forbidden not in client_code,forbidden

# Validate source independently of the import receipt. Each gate should
# occupy the native 2-post span and remain an open nonphysical passage.
with tempfile.TemporaryDirectory(prefix="chaos-crossroads-portal-approved-") as tmp:
    obj=Path(tmp)/"source.obj"
    done=subprocess.run([sys.executable,str(ROOT/
        "tools/generate_original_variant_crossroads_entrance_portal.py"),
        "--output",str(obj)],cwd=ROOT,capture_output=True,text=True,check=True)
    info=json.loads(done.stdout)
    assert info["asset"]==NAME
    assert info["triangles"]==3220
    assert info["groups"]==99
    assert tuple(info["bounds"])==(19.2,10.59,1.755)
    assert max(map(abs,info["center"]))<.08
    assert len(info["materials"])==7
    print("PASS authentic 3D:",info["triangles"],
          info["groups"],info["bounds"],info["sha256"])

# Both posts touch the floor on all four sides, and the full mesh meets the
# same ground and rail envelope. Moving either horizontal sign never affects Y.
for width in (320,324,328,360):
    floor_top=1
    gate_y=floor_top+10
    edge=width*.5-7
    for along_x in (True,False):
        rail_top=gate_y+1.2/2
        for sign in (-1,1):
            side_offset=8.5*sign
            post_bottom=gate_y-5-10/2
            source_bottom=gate_y-4.7-10.59/2
            source_top=gate_y-4.7+10.59/2
            assert post_bottom==floor_top
            assert abs(post_bottom-source_bottom)<.02
            assert abs(rail_top-source_top)<.02
            post=(side_offset,edge) if along_x else (edge,side_offset)
            assert max(map(abs,post))+.6 < width*.5
print("PASS 4 portals / 8 grounded posts, matching envelope and LOD rollback")
