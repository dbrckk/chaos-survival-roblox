#!/usr/bin/env python3
"""Prevent invisible local original-3D owners from bypassing visual budgets.

One source-level regression covering ALL direct-workspace Folder owners
created by local MeshKit / 3DKit modules, not just the eight fixed today.
No physical Studio/Android frame-time or gameplay validation is claimed.
"""
from __future__ import annotations

from collections import Counter
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
RULES=(ROOT/"src/shared/VisualBudgetRules.lua").read_text(encoding="utf8")
CLIENT=ROOT/"src/client"
begin=RULES.index("VisualBudgetRules.LocalFolders = {")
end=RULES.index("\n}",begin)
ledger=RULES[begin:end]
registered=re.findall(r'^\s*"([^"]+Local)",\s*$',ledger,re.MULTILINE)
counts=Counter(registered)
assert len(registered)>=115,("Unexpected visual census coverage",len(registered))
assert all(n==1 for n in counts.values()),{
    name:count for name,count in counts.items() if count!=1
}

EXPECTED={
    "ApprovedClassicBroadcastFinMeshKit.lua":
        "ApprovedClassicBroadcastFinLocal",
    "ApprovedCrossroadsEntrancePortalMeshKit.lua":
        "ApprovedCrossroadsEntrancePortalsLocal",
    "ApprovedCrossroadsOpenGantryMeshKit.lua":
        "ApprovedCrossroadsOpenGantryLocal",
    "ApprovedOrbitalReactorLandmarkMeshKit.lua":
        "ApprovedOrbitalReactorLandmarksLocal",
    "ApprovedPrimarySkylineMeshKit.lua":
        "ApprovedPrimarySkylineLocal",
    "ApprovedSkylineDepthMeshKit.lua":
        "ApprovedSkylineDepthLocal",
    "ApprovedVariantIdentitySpineMeshKit.lua":
        "ApprovedOriginalIdentitySpinesLocal",
    "ApprovedVariantTowersLandmarkMeshKit.lua":
        "ApprovedTowersMachineryLocal",
}
DECLARATION=re.compile(
    r'\b(?:local\s+)?([a-zA-Z_][a-zA-Z_0-9]*)\s*=\s*'
    r'Instance\.new\(["\']Folder["\']\)')
observed={}
for source in sorted(CLIENT.glob("*.lua")):
    if not (source.name.endswith("MeshKit.lua")
            or source.name.endswith("3DKit.lua")):
        continue
    code=source.read_text(encoding="utf8")
    # Match only a literal named Folder with its actual Parent=workspace.
    # Do not confuse a nested child Folder or server-owned model with a
    # separate workspace root and accidentally double-count descendants.
    for declaration in DECLARATION.finditer(code):
        var=declaration.group(1)
        initialization=code[declaration.end():declaration.end()+1800]
        name=re.search(
            rf'\b{re.escape(var)}\.Name\s*=\s*["\']([^"\']+)["\']',
            initialization)
        parent=re.search(
            rf'\b{re.escape(var)}\.Parent\s*=\s*workspace\b',
            initialization)
        if name and parent and name.group(1).endswith("Local"):
            owner=name.group(1)
            observed.setdefault(owner,[]).append(source.name)
            assert owner in counts,(source.name,owner,
                "client MeshParts not counted in adaptive Android census")

# Gameplay-safe improvement for real promenade / Sky Spine undercarriages.
# Previously Low had only ONE 3D bridge segment and ZERO actual approved
# underdeck chassis models. A 22-23 stud REAL crossing rarely fitted one
# short imported module. Low now allows two imported top segments plus ONE
# source-verified 7-MeshPart lower sculpt when the actual route geometry
# fits, and never behind Harbor caissons, square hulls or LongCradles.
ROUTE=(CLIENT/"PremiumRouteMeshKit.lua").read_text(encoding="utf8")
BEAMS=(CLIENT/"UnderstructureBeamMeshKit.lua").read_text(encoding="utf8")
LOD=(CLIENT/"scenery-lod.client.lua").read_text(encoding="utf8")
VARIANTS=(ROOT/"src/server/ArenaVariants.lua").read_text(encoding="utf8")
assert 'OriginalUnderdeckChassis = 84582262145054' in ROUTE
assert 'local BUDGET = {' in ROUTE
assert 'Low = {decks = 2, bridges = 1, segments = 2, underdecks = 1,' in ROUTE
assert 'Medium = {decks = 8, bridges = 3, segments = 3, underdecks = 2,' in ROUTE
assert 'High = {decks = 12, bridges = 5, segments = 4, underdecks = 4,' in ROUTE
assert 'if stress == 1 then' in ROUTE
assert 'underdeckCap = math.floor(underdeckCap*.50)' in ROUTE
assert 'underdeckCap = 0' in ROUTE
assert 'if quality == "Low" then' in ROUTE
assert 'if stress > 0 or arena:GetAttribute("VariantId") == "Harbor"' in ROUTE
assert 'underdeckTemplate:GetAttribute("PremiumUnderdeck3D") ~= true' in ROUTE
assert 'underdeckTemplate:GetDescendants()' in ROUTE
assert 'if authentic~=7 then underdeckSlots=0 end' in ROUTE
assert 'or child.CanCollide or child.CanTouch' in ROUTE
assert 'elseif child:IsA("LuaSourceContainer") then' in ROUTE
assert 'if entry.strictLowUnderdeck then' in ROUTE
assert 'if parts ~= 7 then return false end' in ROUTE
assert '(entry.strictLowUnderdeck and #pieces ~= 7)' in ROUTE
assert 'if platform:GetAttribute("LocalOriginalLongCradleMounted") == true then' in ROUTE
assert 'platform:GetAttributeChangedSignal(' in ROUTE
assert '"LocalOriginalLongCradleMounted"):Connect(function()' in ROUTE
assert 'restore(entry)' in ROUTE
assert 'if mounted[platform] == entry then' in ROUTE
assert 'mounted[platform] = nil' in ROUTE
assert 'length >= (quality == "Low" and 19.5 or 17)' in ROUTE
assert 'length/width >= 1.35' in ROUTE
assert 'item.platform:GetAttribute("ChaosSkybridge") ~= true' in ROUTE
# One axis-invariant source-fit contract for BOTH the pre-selection
# AND the actual clone assembly. Roblox can import source X/Z swapped.
assert 'local function fitUnderdeck(platform, sourceSize)' in ROUTE
assert 'local sourceLong=math.max(sourceSize.X,sourceSize.Z)' in ROUTE
assert 'local sourceShort=math.min(sourceSize.X,sourceSize.Z)' in ROUTE
assert 'local scale=math.min(length*.88/sourceLong,' in ROUTE
assert 'width*.88/sourceShort,1.06)' in ROUTE
assert 'local sourceAlongZ=sourceSize.Z>sourceSize.X' in ROUTE
assert 'local platformAlongZ=platform.Size.Z>platform.Size.X' in ROUTE
assert 'local yaw=sourceAlongZ==platformAlongZ and 0 or math.pi*.5' in ROUTE
assert 'local fit=fitUnderdeck(platform,sourceSize)' in ROUTE
assert 'local underdeckFit=fitUnderdeck(item.platform,underdeckBounds)' in ROUTE
assert 'if underdeckFit' in ROUTE
assert 'local yaw=fit.yaw' in ROUTE
assert 'or math.max(size.X,size.Z)>32' in ROUTE
assert 'or math.min(size.X,size.Z)>18 or size.Y > 9' in ROUTE
assert 'PremiumRouteMeshKit.underdeckFit = fitUnderdeck' in ROUTE
assert 'sourceSize.X < 20' not in ROUTE
assert 'underdeckBounds.X>=20' not in ROUTE
# Numeric footprint proof across both approved 24x10 source orientations
# and both REAL physical promenade / Sky Spine rotations.
from math import pi
for px,pz in ((22.85,12),(12,22.85)):
    for sx,sz in ((24,10),(10,24)):
        scale=min(max(px,pz)*.88/max(sx,sz),
                  min(px,pz)*.88/min(sx,sz),1.06)
        sourceAlongZ=sz>sx
        deckAlongZ=pz>px
        yaw=0 if sourceAlongZ==deckAlongZ else pi/2
        afterLong=max(sx,sz)*scale
        afterShort=min(sx,sz)*scale
        assert scale>=.56
        assert afterLong<=max(px,pz)*.88+1e-9
        assert afterShort<=min(px,pz)*.88+1e-9
        assert yaw in (0,pi/2)
# Invalid source families or inadequate tiny landings remain unqualified.
for px,pz,sx,sz in ((12,12,24,10),(22,12,32,10),(22,8,24,10)):
    length,width=max(px,pz),min(px,pz)
    sourceLong,sourceShort=max(sx,sz),min(sx,sz)
    valid=20<=sourceLong<=26 and 8<=sourceShort<=13 and (
        length>=17 and width>=9.5)
    assert not valid,(px,pz,sx,sz)
assert 'desired.underdeck, quality == "Low")' in ROUTE
# A requested source is NOT the same as a successful import. If a
# clone fails, do not claim a 3D undercarriage and do not tear down valid
# top-cover meshes repeatedly on each 0.65-second LOD sample.
assert 'underdeckRequested = underdeckTemplate ~= nil' in ROUTE
assert 'underdeck = false,' in ROUTE
assert 'entry.underdeck=addUnderdeckModel(' in ROUTE
assert 'if entry.underdeck then' in ROUTE
assert 'or (desired.underdeck ~= nil) ~= entry.underdeckRequested' in ROUTE
assert 'or (desired.underdeck ~= nil) ~= entry.underdeck' not in ROUTE
assert 'clone:SetAttribute("OriginalUnderdeckArt", true)' in ROUTE

assert 'model:SetAttribute("OriginalUnderdeckArt", true)' not in ROUTE
assert 'clone:SetAttribute("OriginalUnderdeckArt", true)' in ROUTE
assert 'PremiumRouteMeshKit.underdeckCount()' in LOD
assert '"PremiumRouteMeshLocal"' in ledger
assert counts["PremiumRouteMeshLocal"] == 1
# Both sky routes are 100% real server colliders, not new phantom bridges.
assert 'variant.PromenadePlatforms = promenades' in VARIANTS
assert 'variant.SkySpinePlatforms = spine' in VARIANTS
assert 'size = Vector3.new(laneSpacing - 2.4, 2, 12)' in VARIANTS
assert 'size = Vector3.new(12, 2, interval - 2.4)' in VARIANTS
# Example genuine Classic promenade: left/right service lookouts are
# 202 studs apart, eight 25.25-stud centers -> real deck 22.85 x 12.
length,width=202/8-2.4,12
scale=min(length*.88/24,width*.88/10,1.06)
assert length>19.5 and length/width>1.35 and scale>=.56
print("PASS authentic healthy Low Sky Promenade undercarriage: 2 bridge",
      "segments + 1 optional 7-MeshPart underdeck, no stacking")

# Previously the independent understructure-beam owner ignored GPU
# pressure even on Low. No visual-only clone may survive a stressed phone
# or remain floating if its source/native/clone streams away.
assert 'Low = {count = 1, distance = 140, retention = 14}' in BEAMS
assert 'Medium = {count = 4, distance = 225, retention = 22}' in BEAMS
assert 'High = {count = 12, distance = 290, retention = 25}' in BEAMS
assert 'function Kit.sync(arena, cameraPoint, tier, cameraReady, pressure)' in BEAMS
assert 'if tier=="Low" and stress>=1 then cap=0 end' in BEAMS
assert 'if not source or (tier=="Low" and pieces~=7) then' in BEAMS
assert 'for i = 1, math.min(#ranked, cap) do' in BEAMS
assert 'bucket.Name = "OriginalUnderstructureBeamsLocal"' in BEAMS
assert '"OriginalUnderstructureBeamsLocal"' in ledger
assert counts["OriginalUnderstructureBeamsLocal"] == 1
assert 'bucket.ChildRemoved:Connect(function(child)' in BEAMS
assert 'local function release(name)' in BEAMS
assert 'mounted[name]=nil' in BEAMS
assert 'entry.native.Transparency == 1' in BEAMS
assert 'source.AncestryChanged:Connect' in BEAMS
assert 'source.DescendantRemoving:Connect' in BEAMS
assert 'clone.DescendantRemoving:Connect' in BEAMS
assert 'native.AncestryChanged:Connect' in BEAMS
assert 'if mounted[name]==entry' in BEAMS
assert 'if entry.model then entry.model:Destroy() end' in BEAMS
assert 'for _,name in ipairs(evicted) do release(name) end' in BEAMS
assert 'UnderstructureBeamMeshKit.sync(arena, cameraPoint,' in LOD
beam_call=LOD.split('UnderstructureBeamMeshKit.sync(',1)[1].split(
    'local beamMeshes',1)[0]
assert 'player:GetAttribute("OptionalVfxPressure"))' in beam_call
assert 'CanCollide = false' in BEAMS
assert 'CanTouch = false' in BEAMS and 'CanQuery = false' in BEAMS
assert "RenderStepped" not in BEAMS and "Heartbeat" not in BEAMS
assert "RenderStepped" not in ROUTE and "Heartbeat:Connect" not in ROUTE
print("PASS original understructure beams pressure-one rollback and",
      "streaming/budget immediate native restoration")

# A truly visible exterior industrial foundation in Android Low must be
# an approved SEVEN-MeshPart original, not a partial/repeated Part stack.
# The parent of Low clones is a *workspace-local* Folder in the SAME 440
# part cooperative census. The legacy Medium/High parent stays intact.
# Its 3K-triangle mesh may mask all ELEVEN native blocks only when both
# footprint axes match and streaming has delivered all native elements.
FOUNDATION=(CLIENT/"ApprovedFoundationChassisMeshKit.lua").read_text(
    encoding="utf8")
FOUNDATION_SERVER=(ROOT/"src/server/OriginalMeshScenery.lua").read_text(
    encoding="utf8")
FOUNDATION_LOD=(CLIENT/"scenery-lod.client.lua").read_text(
    encoding="utf8")
assert 'local CHASSIS_ID = 84582262145054' in FOUNDATION
assert 'Approved' in (ROOT/"assets/source/roblox-asset-registry.json").read_text()
assert 'Low = {count = 1, distance = 128}' in FOUNDATION
assert 'Medium = {count = 1, distance = 215}' in FOUNDATION
assert 'High = {count = 2, distance = 300}' in FOUNDATION
assert 'if tier == "Low" and stress >= 1 then cap = 0 end' in FOUNDATION
assert 'if source and cap > 0 and (tier ~= "Low" or parts == 7)' in FOUNDATION
assert 'local function fitFoundation(shoulder, sourceSize)' in FOUNDATION
assert 'sx * scale >= shoulder.Size.X * .80' in FOUNDATION
assert 'sz * scale >= shoulder.Size.Z * .78' in FOUNDATION
assert 'select(3, fitFoundation(shoulder, sourceSize))' in FOUNDATION
assert 'if scale < .48 or (tier == "Low" and not covers)' in FOUNDATION
assert 'or (tier == "Low" and count ~= 7)' in FOUNDATION
assert 'owner:GetAttribute("OriginalFoundationPieceCount") ~= 11' in FOUNDATION
assert 'or foundationCount ~= 11' in FOUNDATION
assert 'model:SetAttribute("OriginalFoundationBuilt", true)' in FOUNDATION_SERVER
assert 'model:SetAttribute("OriginalFoundationPieceCount", #specs + details)' in FOUNDATION_SERVER
for piece in (
    "FoundationShoulder", "FoundationInset", "FoundationBallast",
    "FoundationGroundPad", "OriginalChassisFrontIBeam",
    "OriginalChassisRearIBeam", "OriginalTaperedLoadButtress",
    "OriginalVerticalServiceRail",
):
    assert piece in FOUNDATION_SERVER, piece
assert 'source:GetAttribute("Original3DAssetId") ~= CHASSIS_ID' in FOUNDATION
assert 'source:GetAttribute("OwnerVerified") ~= true' in FOUNDATION
assert 'source:GetAttribute("CosmeticOnly") ~= true' in FOUNDATION
assert 'source:GetAttribute("PremiumUnderdeck3D") ~= true' in FOUNDATION
assert 'if not part:IsA("MeshPart") then return nil end' in FOUNDATION
assert 'part.CanCollide = false' in FOUNDATION
assert 'part.CanTouch = false' in FOUNDATION
assert 'part.CanQuery = false' in FOUNDATION
assert 'part.CastShadow = false' in FOUNDATION
assert 'local parent = tier == "Low" and bucket or owner' in FOUNDATION
assert 'clone.Parent = parent' in FOUNDATION
assert FOUNDATION.index('clone.Parent = parent') < FOUNDATION.index(
    'for part in pairs(native) do part.Transparency = 1 end')
assert 'bucket.Name = "ApprovedFoundationChassisLocal"' in FOUNDATION
assert '"ApprovedFoundationChassisLocal"' in ledger
assert counts["ApprovedFoundationChassisLocal"] == 1
assert 'bucket.Parent = workspace' in FOUNDATION
assert 'bucket.ChildRemoved:Connect(function(child)' in FOUNDATION
assert 'if entry.mesh == child then' in FOUNDATION
assert 'source.DescendantRemoving:Connect' in FOUNDATION
assert 'clone.DescendantRemoving:Connect' in FOUNDATION
assert 'shoulder:GetAttributeChangedSignal("SceneryLodHidden")' in FOUNDATION
assert 'shoulder:GetPropertyChangedSignal("LocalTransparencyModifier")' in FOUNDATION
assert 'if entry.mesh then entry.mesh:Destroy() end' in FOUNDATION
assert 'mounted[owner] = nil' in FOUNDATION
assert 'or entry.mesh.Parent ~= entry.parent or entry.source ~= source' in FOUNDATION
assert 'entry and entry.mesh.Parent == entry.parent' in FOUNDATION
assert 'ApprovedFoundationChassisMeshKit.sync(arena, imported, cameraPoint,' in FOUNDATION_LOD
foundation_call=FOUNDATION_LOD.split(
    'ApprovedFoundationChassisMeshKit.sync(',1)[1].split(
    'local foundationMeshes',1)[0]
assert 'player:GetAttribute("OptionalVfxPressure"))' in foundation_call
assert 'LocalApprovedFoundationChassis3DCount' in FOUNDATION_LOD
assert 'RenderStepped' not in FOUNDATION and 'Heartbeat' not in FOUNDATION
assert 'AssetService' not in FOUNDATION
print("PASS 11 source-native pedestal shapes -> one genuine 7-MeshPart",
      "Low exterior chassis, 128 studs, GPU rollback and live census")

# Perimeter armor has four big native WedgeParts on every station.
# Android Low may show only TWO genuine wing originals, never all four
# (28 meshes), and MUST keep both native top-caps present. Medium/High
# still retain all four approved source replacements. Count actual
# masked native wedges, not inferred four-per-station on mobile.
ARMOR=(CLIENT/"ApprovedPerimeterArmorMeshKit.lua").read_text(
    encoding="utf8")
ARMOR_SERVER=(ROOT/"src/server/PremiumPerimeterArmorAssets.lua").read_text(
    encoding="utf8")
for word in ("88962643359267","138096293972093"):
    assert word in ARMOR and word in ARMOR_SERVER
assert 'local CAPS = {Low=1,Medium=1,High=3}' in ARMOR
assert 'local RANGE = {Low=105,Medium=170,High=245}' in ARMOR
assert 'local RETENTION = 16' in ARMOR
assert 'if tier=="High" and touch then cap=2 end' in ARMOR
assert 'if stress==1 then cap=math.floor(cap*.5) end' in ARMOR
assert 'if stress>=2 then cap=0 end' in ARMOR
assert 'if cap==0 or not cameraReady' in ARMOR
assert 'local first=tier=="Low" and 3 or 1' in ARMOR
assert 'for i=first,#NATIVE_NAMES do' in ARMOR
assert 'local kind=MODEL_NAMES[first+i-1]' in ARMOR
assert 'local wingNative=tier=="Low" and natives[1] or natives[3]' in ARMOR
assert 'local capSource=tier~="Low" and sourceFor("Cap") or nil' in ARMOR
assert 'if not wing or (tier~="Low" and not capSource) then' in ARMOR
assert 'or (tier~="Low" and (not sources.Cap or not sources.Cap.Parent))' in ARMOR
assert 'expected=tier=="Low" and 2 or 4' in ARMOR
assert 'or entry.tier~=tier' in ARMOR
assert 'or #entry.models~=entry.expected' in ARMOR
assert 'if #entry.models~=entry.expected then return false end' in ARMOR
assert 'if complete(entry) then n+=1 end' in ARMOR
assert 'for native in pairs(entry.original) do' in ARMOR
assert 'if native.Transparency==1 then n+=1 end' in ARMOR
assert 'return Kit.count()*4' not in ARMOR
for native in ("LeftAngledCap","RightAngledCap",
               "AngledServiceWingL","AngledServiceWingR"):
    assert '"'+native+'"' in ARMOR
assert 'if count ~= 7 then return nil end' in ARMOR
assert 'if #parts~=7 then clone:Destroy();return nil end' in ARMOR
assert 'if count ~= 7 then return false end' in ARMOR_SERVER
assert 'source:GetAttribute("OwnerVerified") ~= true' in ARMOR
assert 'source:GetAttribute("CosmeticOnly") ~= true' in ARMOR
assert 'source:GetAttribute("OriginalPerimeterArmor3D") ~= true' in ARMOR
assert 'source:GetAttribute("Original3DAssetId") ~= IDS[kind]' in ARMOR
assert ARMOR.index('for _,model in ipairs(models) do model.Parent=bucket end') < (
    ARMOR.index('for _,native in ipairs(natives) do native.Transparency=1 end'))
assert 'bucket.ChildRemoved:Connect(function(child)' in ARMOR
assert 'native.Transparency = alpha' in ARMOR
assert 'piece.CanCollide=false' in ARMOR
assert 'piece.CanTouch=false' in ARMOR
assert 'piece.CanQuery=false' in ARMOR
assert 'piece.CastShadow=false' in ARMOR
assert 'local sources={Wing=wing,Cap=capSource}' in ARMOR
assert 'mount(arena,station,index,sources,tier)' in ARMOR
assert 'bucket.Name = "ApprovedPerimeterArmorLocal"' in ARMOR
assert '"ApprovedPerimeterArmorLocal"' in ledger
assert counts["ApprovedPerimeterArmorLocal"]==1
assert 'ApprovedPerimeterArmorMeshKit.sync(arena, cameraPoint,' in (
    CLIENT/"scenery-lod.client.lua").read_text(encoding="utf8")
assert 'LocalPerimeterPrimitiveWedgesReplaced' in (
    CLIENT/"scenery-lod.client.lua").read_text(encoding="utf8")
assert "RenderStepped" not in ARMOR and "Heartbeat" not in ARMOR
assert "AssetService" not in ARMOR
print("PASS two genuine 7-MeshPart near-camera Low perimeter wings,",
      "unchanged cap wedges, pressure-one rollback, accurate native census")

# One authenticated creator-original perimeter CrossBrace + GeneratorShield
# pair can replace TWO primitive native blocks on a camera-near Low station.
# Each material-split model contains 7 MeshParts: exactly 14 across BOTH
# models in the only permitted resident station. Pressure 1 restores both.
PERIM=(CLIENT/"ApprovedPerimeterStructuresMeshKit.lua").read_text(
    encoding="utf8")
PERIM_SERVER=(ROOT/"src/server/PremiumPerimeterStructuresAssets.lua").read_text(
    encoding="utf8")
PERIM_MAP=(ROOT/"src/server/MapBuilder.lua").read_text(
    encoding="utf8")
assert 'local CAPS = {Low=1,Medium=1,High=3}' in PERIM
assert 'local RANGE = {Low=112,Medium=170,High=245}' in PERIM
assert 'local RETENTION = 16' in PERIM
assert 'if tier=="High" and touch then cap=2 end' in PERIM
assert 'if stress==1 then cap=math.floor(cap*.5) end' in PERIM
assert 'if stress>=2 then cap=0 end' in PERIM
assert 'if cap==0 or not cameraReady' in PERIM
assert 'Brace = 108452611210970' in PERIM
assert 'Shield = 113687802206554' in PERIM
assert 'id=108452611210970' in PERIM_SERVER
assert 'id=113687802206554' in PERIM_SERVER
assert 'if parts~=7 then return false end' in PERIM_SERVER
assert 'if count ~= 7 then return nil end' in PERIM
assert 'if #parts~=7 then clone:Destroy();return nil end' in PERIM
assert 'holder:GetAttribute("OwnerVerified") ~= true' in PERIM
assert 'source:GetAttribute("CosmeticOnly") ~= true' in PERIM
assert 'source:GetAttribute("OriginalPerimeterStructure3D") ~= true' in PERIM
assert 'source:GetAttribute("Original3DAssetId") ~= IDS[kind]' in PERIM
assert 'if not model then' in PERIM and 'for _,old in ipairs(models) do old:Destroy() end' in PERIM
assert PERIM.index('for _,model in ipairs(models) do model.Parent=bucket end') < (
    PERIM.index('for _,native in ipairs(natives) do native.Transparency=1 end'))
assert 'if table.find(entry.models,child) then' in PERIM
assert 'native.Transparency = alpha' in PERIM
assert 'local NATIVE_NAMES = {"CrossBrace", "GeneratorShield"}' in PERIM
for name in ('CrossBrace','GeneratorShield','CoreLens',
             'WayfindingInset','LeftLightNotch','RightLightNotch'):
    assert '"'+name+'"' in PERIM_MAP
for fragment in ('piece.CanCollide=false','piece.CanTouch=false',
                 'piece.CanQuery=false','piece.CastShadow=false'):
    assert fragment in PERIM
assert 'station:GetAttribute("ChaosPerimeterStation") ~= true' in PERIM
assert 'station:GetAttribute("StationIndex") ~= index' in PERIM
assert 'OriginalPerimeterStructure3D_' in PERIM
assert 'bucket.Name = "ApprovedPerimeterStructuresLocal"' in PERIM
assert '"ApprovedPerimeterStructuresLocal"' in ledger
assert counts['ApprovedPerimeterStructuresLocal']==1
assert 'ApprovedPerimeterStructuresMeshKit.sync(arena, cameraPoint,' in (
    CLIENT/"scenery-lod.client.lua").read_text(encoding="utf8")
assert 'LocalPerimeterPrimitiveStructuralBlocksReplaced' in (
    CLIENT/"scenery-lod.client.lua").read_text(encoding="utf8")
assert 'RenderStepped' not in PERIM and 'Heartbeat' not in PERIM
assert 'AssetService' not in PERIM
print("PASS original two seven-MeshPart station structures on healthy Low",
      "one 112-stud station, pressure 1 atomic native restore")

# Two creator-approved 12/20-stud identity spines previously had a
# double Low OFF switch: CAP.Low=0 plus touch-branch forced zero.
# Ensure a single actual 7-MeshPart original can replace ONE rigid body
# on Android touch Low without hiding its animated glow/bands. An
# evicted local clone must release its original Part immediately.
MAST=(CLIENT/"ApprovedVariantIdentitySpineMeshKit.lua").read_text(
    encoding="utf8")
MAST_SERVER=(ROOT/"src/server/PremiumVariantIdentitySpineAssets.lua").read_text(
    encoding="utf8")
for asset in ("105555650820011","86423178125318"):
    assert f'id={asset}' in MAST
    assert f'id={asset}' in MAST_SERVER
assert 'local CAP={Low=1,Medium=2,High=4}' in MAST
assert 'local RANGE={Low=165,Medium=295,High=425}' in MAST
assert 'or tier=="Low" and math.min(budget,1) or 0' in MAST
assert 'if stress==1 then budget=math.floor(budget*.5) end' in MAST
assert 'if stress>=2 then budget=0 end' in MAST
assert 'if n~=7 then return nil end' in MAST
assert 'if #meshes~=7 then model:Destroy();return end' in MAST
assert 'source:GetAttribute("OriginalVariantIdentitySpine3D")~=true' in MAST
assert 'source:GetAttribute("Original3DAssetId")~=spec.id' in MAST
assert 'source:GetAttribute("OwnerVerified")~=true' in MAST
assert 'model.Parent=bucket' in MAST
assert MAST.index('model.Parent=bucket') < MAST.index('native.Transparency=1')
assert 'bucket.ChildRemoved:Connect(function(child)' in MAST
assert 'if entry.model==child then' in MAST
assert 'native.Transparency=entry.original' in MAST
assert 'part.CanCollide=false' in MAST
assert 'part.CanTouch=false' in MAST
assert 'part.CanQuery=false' in MAST
assert 'part.CastShadow=false' in MAST
for lighting in ("GridMarkerGlow","TowerBand"):
    assert lighting in MAST
for prohibited in ("signal.Transparency=","signal.CFrame=","signal.Color="):
    assert prohibited not in MAST
assert '"ApprovedOriginalIdentitySpinesLocal"' in ledger
assert 'bucket.Name="ApprovedOriginalIdentitySpinesLocal"' in MAST
assert 'ApprovedVariantIdentitySpineMeshKit.sync(arena,cameraPoint,' in (
    CLIENT/"scenery-lod.client.lua").read_text()
assert "RenderStepped" not in MAST and "Heartbeat" not in MAST
assert "AssetService" not in MAST
print("PASS one approved 7-MeshPart Classic/Towers original identity mast",
      "on healthy touch Low, 165-stud camera limit and immediate fallback")

# Source-authenticated 3D undersides replace the visibly blocky side
# surfaces of ONE near-camera Harbor cargo landing on healthy Android Low.
# This never hides the server's walkable top, native collision or dangers.
# A seven-material original is accepted on Low only if the imported
# source contains EXACTLY seven real MeshParts, with pressure rollback.
DOCK=(CLIENT/"HarborDockCaissonMeshKit.lua").read_text(encoding="utf8")
DOCK_SERVER=(ROOT/"src/server/PremiumHarborDockCaissonAssets.lua").read_text(encoding="utf8")
DOCK_SOURCE=(ROOT/"tools/generate_original_harbor_dock_caisson.py").read_text(
    encoding="utf8")
assert 'local ASSET_ID = 101457508594609' in DOCK
assert 'local ID = 101457508594609' in DOCK_SERVER
assert 'Low = {models = 1, distance = 108, retention = 14}' in DOCK
assert 'Medium = {models = 5, distance = 150, retention = 24}' in DOCK
assert 'High = {models = 12, distance = 215, retention = 34}' in DOCK
assert 'elseif quality == "Low" and stress > 0 then' in DOCK
assert 'maximum = 0' in DOCK
assert '(quality == "Low" and expected ~= 7)' in DOCK
assert 'if not item:IsA("MeshPart") then return nil end' in DOCK
assert 'item:IsA("LuaSourceContainer")' in DOCK
assert 'holder:GetAttribute("OwnerVerified") ~= true' in DOCK
assert 'source:GetAttribute("OwnerVerified") ~= true' in DOCK
assert 'source:GetAttribute("CosmeticOnly") ~= true' in DOCK
assert 'source:GetAttribute("OriginalHarborDockCaisson3D") ~= true' in DOCK
assert 'source:GetAttribute("Original3DAssetId") ~= ASSET_ID' in DOCK
assert 'deck.Name:match("^Platform%d+$")' in DOCK
assert 'or not deck.CanCollide or deck.Transparency >= .75' in DOCK
assert 'or deck:GetAttribute("ChaosSkybridge") == true' in DOCK
assert 'if collapse ~= nil and collapse ~= "Normal" and collapse ~= "Safe"' in DOCK
assert 'if shutter ~= nil and shutter ~= "Idle" then return false end' in DOCK
assert '0, deck.Size.Y * .5 - .14 - box.Y * .5, 0' in DOCK
assert 'part.CanCollide = false' in DOCK
assert 'part.CanTouch = false' in DOCK
assert 'part.CanQuery = false' in DOCK
assert 'part.CastShadow = false' in DOCK
assert 'joint.Part0 = deck' in DOCK and 'joint.Part1 = piece' in DOCK
assert 'if #pieces ~= expected then clone:Destroy(); return nil end' in DOCK
assert 'part.LocalTransparencyModifier = show and 0 or 1' in DOCK
assert 'deck:GetAttributeChangedSignal(attr):Connect(changed)' in DOCK
assert 'clone.DescendantRemoving:Connect' in DOCK
assert 'HarborDockCaissonMeshKit.sync(arena,cameraPoint,profile.Name,' in (CLIENT/"scenery-lod.client.lua").read_text()
assert '"OriginalHarborDockCaissonsLocal"' in ledger
assert 'folder.Name = "OriginalHarborDockCaissonsLocal"' in DOCK
assert 'Seven forged material families' in DOCK_SOURCE
assert 'under_top_limit' in DOCK_SOURCE
assert 'if pieces < 1 or pieces > 12 then return false end' in DOCK_SERVER
assert 'RenderStepped' not in DOCK and 'Heartbeat' not in DOCK
assert 'AssetService' not in DOCK
print("PASS one authentic seven-MeshPart Harbor dock underside on healthy Low,",
      "108-stud camera range, safe original collision and GPU rollback")

# A real 20-stud Harbor cargo gantry imported by the existing server
# can replace NINE native structural blocks on ONE nearby Low skywalk.
# Strictly seven verified MeshParts, no extra texture on Low, no extra
# sampler: first optional VFX pressure must reinstate native primitives.
HARBOR=(CLIENT/"HarborPromenadePortalMeshKit.lua").read_text(encoding="utf8")
HARBOR_SERVER=(ROOT/"src/server/PremiumHarborPromenadePortalAssets.lua").read_text(encoding="utf8")
SCENERY=(CLIENT/"scenery-lod.client.lua").read_text(encoding="utf8")
assert 'local ID = 134157110756659' in HARBOR
assert 'local ID = 134157110756659' in HARBOR_SERVER
assert 'Low = {count = 1, distance = 118, retention = 14}' in HARBOR
assert 'Medium = {count = 2, distance = 205, retention = 25}' in HARBOR
assert 'High = {count = 6, distance = 280, retention = 34}' in HARBOR
assert 'elseif tier=="Low" and stress>0 then' in HARBOR
assert 'maximum=0' in HARBOR
assert '(tier=="Low" and partCount~=7)' in HARBOR
assert 'holder:GetAttribute("OwnerVerified") ~= true' in HARBOR
assert 'source:GetAttribute("OwnerVerified") ~= true' in HARBOR
assert 'source:GetAttribute("Original3DAssetId") ~= ID' in HARBOR
assert 'source:GetAttribute("OriginalHarborPromenadePortal3D") ~= true' in HARBOR
assert 'if not piece:IsA("MeshPart") then return nil end' in HARBOR
assert 'part:IsA("LuaSourceContainer")' in HARBOR or 'piece:IsA("LuaSourceContainer")' in HARBOR
assert 'if #pieces ~= expected then copy:Destroy(); return nil end' in HARBOR
for name in ('LoadPylon-1','LoadPylon1','DiagonalStay-1','DiagonalStay1',
    'MonumentalCrosshead','UnderdeckTruss','FreightHoistArm',
    'SuspendedCrate','CargoChain'):
    assert name in HARBOR,name
assert 'native.part.LocalTransparencyModifier =' in HARBOR
assert 'visible and 1 or native.original' in HARBOR
assert 'decor.ChildAdded:Connect(watchNative)' in HARBOR
assert 'PremiumRoutePbrKit.entryBudget(' in HARBOR
assert 'if stress > 0 then slots = 0 end' in HARBOR
assert 'HarborPromenadePortalMeshKit.sync(arena,cameraPoint,profile.Name,' in SCENERY
assert '"OriginalHarborPromenadePortalsLocal"' in ledger
assert 'folder.Name = "OriginalHarborPromenadePortalsLocal"' in HARBOR
assert '.RenderStepped:Connect(' not in HARBOR
assert '.Heartbeat:Connect(' not in HARBOR
assert 'AssetService' not in HARBOR
print("PASS Harbor Low original seven-mesh cargo gantry, nine native block fallback and pressure 1 demotion")

# Secondary SOUTH silhouettes have giant native lifts and ring mechanics,
# but the authenticated originals were previously disabled on Low. Two
# arena-exclusive 7-MeshPart models replace 4/6 exact native elements
# only at 152 studs (not at the 290-stud long-distance skyline range).
SOUTH_NEAR_MECHANICS={
    "Towers": (
        "ApprovedSouthTowersLiftTwinsMeshKit.lua",
        "ApprovedSouthTowersLiftTwinsLocal",
        114886409893890, "OriginalSouthTowersForgedLiftTwins3D", 4,
        ("WestLift","EastLift","WestCrown","EastCrown"),
    ),
    "Orbital": (
        "ApprovedSouthOrbitalFinishingMeshKit.lua",
        "ApprovedSouthOrbitalFinishingLocal",
        96266711661930, "OriginalSouthOrbitalForgedFinishing3D", 6,
        ("Foundation","FloorInset","LeftRingSupport","RightRingSupport",
         "SuspendedOrb","OrbClamp"),
    ),
}
assert len(SOUTH_NEAR_MECHANICS)==2
for variant,(filename,owner,asset,flag,replace_count,names) in (
        SOUTH_NEAR_MECHANICS.items()):
    kit=(CLIENT/filename).read_text(encoding="utf8")
    assert f'local MODEL_ID={asset}' in kit,(variant,"approved ID")
    assert 'local QUALITIES={Low=1,Medium=1,High=1}' in kit
    assert 'local DISTANCE={Low=152,Medium=420,High=580}' in kit
    assert 'local RETENTION=26' in kit
    assert 'if stress==1 and tier~="High" then cap=0 end' in kit
    assert 'if stress>=2 then cap=0 end' in kit
    assert f'arena:GetAttribute("VariantId")~="{variant}"' in kit
    assert f'owner:GetAttribute("SignatureVariant")~="{variant}"' in kit
    assert f'source:GetAttribute("{flag}")~=true' in kit
    assert 'source:GetAttribute("Original3DAssetId")~=MODEL_ID' in kit
    assert 'source:GetAttribute("OwnerVerified")~=true' in kit
    assert 'source:GetAttribute("CosmeticOnly")~=true' in kit
    assert 'if not p:IsA("MeshPart") or p.CanCollide' in kit
    assert 'if n~=7 then return nil end' in kit
    assert 'if #pieces~=7 then' in kit
    assert f'#currentNatives~={replace_count}' in kit
    assert all('"'+name+'"' in kit for name in names),(variant,"native names")
    assert 'part.CanCollide=false' in kit
    assert 'part.CanTouch=false' in kit and 'part.CanQuery=false' in kit
    assert 'model.Parent=bucket' in kit
    assert kit.index('model.Parent=bucket')<kit.index('native.Transparency=1'),(
        variant,"mount before primitive hide")
    assert 'part.Transparency=alpha' in kit
    assert 'source.DescendantRemoving:Connect' in kit
    assert 'model.DescendantRemoving:Connect' in kit
    assert 'if cap==0 or not cameraReady' in kit
    assert f'bucket.Name="{owner}"' in kit
    assert counts[owner]==1,(variant,"Android census registration")
    assert '"'+owner+'"' in ledger
    assert "RenderStepped" not in kit and "Heartbeat" not in kit
    assert "AssetService" not in kit
    print("PASS original South",variant,
          "Low 152-stud near machinery: 7 MeshParts /",
          replace_count,"native shapes, fallback pressure 1")

# The four SOUTH skyline monuments have source-verified seven-piece
# sculptures already approved on Medium/High. Promote exactly one per
# active arena to Low only when camera-near and optional GPU pressure 0.
# Their native 2/13/13/14 geometric sources remain available atomically.
SOUTH_SIGNATURES={
    "Classic": (
        "ApprovedSouthClassicObservatoryMeshKit.lua",
        "ApprovedSouthClassicObservatoryLocal",
        105516749001927,"OriginalSouthClassicSculptedObservatory3D",13
    ),
    "Towers": (
        "ApprovedSouthTowersSkytransferMeshKit.lua",
        "ApprovedSouthTowersSkytransferLocal",
        120959181274080,"OriginalSouthTowersForgedSkytransfer3D",2
    ),
    "Crossroads": (
        "ApprovedSouthCrossroadsExchangeMeshKit.lua",
        "ApprovedSouthCrossroadsExchangeLocal",
        77870668100712,"OriginalSouthCrossroadsForgedExchange3D",13
    ),
    "Harbor": (
        "ApprovedSouthHarborDrydockMeshKit.lua",
        "ApprovedSouthHarborDrydockLocal",
        125428569657840,"OriginalSouthHarborSculptedDrydock3D",14
    ),
}
assert len(SOUTH_SIGNATURES)==4
assert len({record[2] for record in SOUTH_SIGNATURES.values()})==4
for variant,(filename,owner,asset,flag,native_count) in SOUTH_SIGNATURES.items():
    kit=(CLIENT/filename).read_text(encoding="utf8")
    assert f'local MODEL_ID={asset}' in kit,(variant,"actual approved asset")
    assert 'local QUALITIES={Low=1,Medium=1,High=1}' in kit,(variant,"Low cap")
    assert 'local DISTANCE={Low=290,Medium=420,High=580}' in kit,(
        variant,"Low near-camera visibility")
    assert 'if stress==1 and tier~="High" then cap=0 end' in kit
    assert 'if stress>=2 then cap=0 end' in kit
    assert f'arena:GetAttribute("VariantId")~="{variant}"' in kit
    assert f'owner:GetAttribute("SignatureVariant")~="{variant}"' in kit
    assert f'source:GetAttribute("{flag}")~=true' in kit
    assert 'source:GetAttribute("Original3DAssetId")~=MODEL_ID' in kit
    assert 'source:GetAttribute("OwnerVerified")~=true' in kit
    assert 'source:GetAttribute("CosmeticOnly")~=true' in kit
    assert 'if not p:IsA("MeshPart") or p.CanCollide' in kit
    assert 'if n~=7 then return nil end' in kit
    assert 'if #pieces~=7 then' in kit
    assert f'#currentNatives~={native_count}' in kit,(variant,"native count")
    assert 'part.CanCollide=false' in kit
    assert 'part.CanTouch=false' in kit and 'part.CanQuery=false' in kit
    assert 'model.Parent=bucket' in kit
    assert kit.index('model.Parent=bucket')<kit.index('native.Transparency=1'),(
        variant,"mount before hiding natives")
    assert 'part.Transparency=alpha' in kit
    assert 'source.DescendantRemoving:Connect' in kit
    assert 'model.DescendantRemoving:Connect' in kit
    assert 'if cap==0 or not cameraReady' in kit
    assert f'bucket.Name="{owner}"' in kit
    assert counts[owner]==1,(variant,"Android visual census")
    assert 'RenderStepped' not in kit and 'Heartbeat' not in kit
    assert 'AssetService' not in kit
    print("PASS original southern Low",variant,
          "seven approved MeshParts for",native_count,"nonphysical primitives")

# Each arena has ONE exterior "hero" signature (never three at once).
# On Android Low one source-approved 7-MeshPart sculpture replaces only
# its own exact native nonphysical geometry. Other map variants have
# different active Arena folders, so they do not accumulate these models.
# First optional VFX pressure must restore original source silhouettes.
SIGNATURES={
    "Classic": {
        "file":"ApprovedClassicSignatureObservatoryMeshKit.lua",
        "owner":"ApprovedClassicSignatureObservatoryLocal",
        "asset":112493873850364,"range":290,
        "sourceFlag":"OriginalClassicDualDishObservatory3D",
        "originals":7,"high":615,
        "masked":"for _,part in ipairs(originals) do part.Transparency=1 end",
        "sourceKey":"OWNER_ID",
    },
    "Towers": {
        "file":"ApprovedTowersSignatureBridgeMeshKit.lua",
        "owner":"ApprovedTowersSignatureBridgeLocal",
        "asset":126298311664881,"range":290,
        "sourceFlag":"OriginalTowersSignatureBridge3D",
        "originals":2,"high":575,
        "masked":"bridge.Transparency=1",
        "sourceKey":"MODEL_ID",
    },
    "Harbor": {
        "file":"ApprovedHarborSignatureGantryMeshKit.lua",
        "owner":"ApprovedHarborSignatureGantryLocal",
        "asset":124368710235343,"range":290,
        "sourceFlag":"OriginalHarborSignatureGantry3D",
        "originals":3,"high":610,
        "masked":"for _,native in ipairs(natives) do native.Transparency=1 end",
        "sourceKey":"MODEL_ID",
    },
}
assert len(SIGNATURES)==3
for variant,spec in SIGNATURES.items():
    kit=(CLIENT/spec["file"]).read_text(encoding="utf8")
    assert f'local {spec["sourceKey"]}={spec["asset"]}' in kit,(variant,"asset")
    assert 'local QUALITY={Low=1,Medium=1,High=1}' in kit,(variant,"quality")
    assert f'local RANGE={{Low={spec["range"]},Medium=' in kit,(variant,"range")
    assert f',High={spec["high"]}}}' in kit,(variant,"high unchanged")
    demotion={
        "Classic":'if stress>=2 or (stress==1 and tier~="High") then cap=0 end',
        "Towers":'if load>=2 or (load==1 and tier~="High") then cap=0 end',
        "Harbor":'if stress>=2 or (stress==1 and tier~="High") then count=0 end',
    }[variant]
    assert demotion in kit,(variant,"pressure one native fallback")
    assert spec["sourceFlag"] in kit,(variant,"signature provenance")
    assert 'OwnerVerified' in kit and 'CosmeticOnly' in kit
    assert 'Original3DAssetId' in kit
    assert 'if count~=7 then return nil end' in kit or (
        'if meshes~=7 then return nil end'),(variant,"true 7 pieces")
    assert 'LuaSourceContainer' in kit
    assert 'part.CanCollide=false' in kit or 'item.CanCollide=false' in kit
    assert 'part.CanTouch=false' in kit or 'item.CanTouch=false' in kit
    assert 'part.CanQuery=false' in kit or 'item.CanQuery=false' in kit
    assert spec["masked"] in kit,(variant,"full source before mask")
    restoreNative={
        "Classic":"native.Transparency=alpha",
        "Towers":"native.Transparency=original",
        "Harbor":"native.Transparency=alpha",
    }[variant]
    assert restoreNative in kit,(variant,"native restore")
    # Each kit publishes its Model under a differently named owner.
    # Test the precise publish statement, not a missing generic token
    # (str.index raises ValueError before an 'or' expression can retry).
    publish={
        "Classic":"model.Parent=folder",
        "Towers":"clone.Parent=bucket",
        "Harbor":"model.Parent=bucket",
    }[variant]
    assert kit.index(publish)<kit.index(spec["masked"]),(variant,"atomic mask")
    assert spec["owner"] in kit and counts[spec["owner"]]==1
    assert '.RenderStepped:Connect(' not in kit
    assert '.Heartbeat:Connect(' not in kit
    assert 'AssetService' not in kit
    print("PASS seven-piece original Android Low signature:",variant,
          "replaces",spec["originals"],"nonphysical primitives at <=290 studs")

# The existing authenticated structure owner can replace exactly TWO
# static perimeter cuboids on the ONE nearest Low-tier station.
# It must remain in the global Android Part census and return natives
# at first optional-VFX pressure tier, without AssetService client calls.
BUTTRESS=(CLIENT/"ApprovedPerimeterButtressMeshKit.lua").read_text()
assert 'local LIMITS = {Low = 1, Medium = 1, High = 4}' in BUTTRESS
assert 'local RANGE = {Low = 150, Medium = 185, High = 275}' in BUTTRESS
assert 'if stress == 1 then cap = math.floor(cap * .5) end' in BUTTRESS
assert 'if stress >= 2 then cap = 0 end' in BUTTRESS
assert 'local first, firstParts = fittedClone(source, left, APPROVED[variant])' in BUTTRESS
assert 'if not second then first:Destroy(); return end' in BUTTRESS
assert 'first.Parent = bucket' in BUTTRESS
assert 'second.Parent = bucket' in BUTTRESS
assert BUTTRESS.index('second.Parent = bucket') < BUTTRESS.index(
    'left.Transparency = 1')
assert 'right.Transparency = 1' in BUTTRESS
assert 'native.Transparency = alpha' in BUTTRESS
assert 'item.CastShadow = false' in BUTTRESS
assert 'item.CanCollide = false' in BUTTRESS
assert 'item.CanTouch = false' in BUTTRESS
assert 'item.CanQuery = false' in BUTTRESS
assert 'source:GetAttribute("Original3DAssetId") ~= approvedId' in BUTTRESS
assert 'source:GetAttribute("OwnerVerified") ~= true' in BUTTRESS
assert 'source:GetAttribute("OriginalLargeStructure3D") ~= true' in BUTTRESS
assert 'bucket.Name = "ApprovedPerimeterButtressesLocal"' in BUTTRESS
assert '"ApprovedPerimeterButtressesLocal"' in ledger
assert 'RenderStepped' not in BUTTRESS and 'Heartbeat' not in BUTTRESS
assert 'AssetService' not in BUTTRESS

# Original rotor sculpt: a single near-camera Low station may
# replace exactly THREE inert cylinder Parts with THREE owner-approved
# seven-MeshPart models (21 optional local MeshParts maximum). On Low,
# the first GPU pressure tier must restore ALL three native cylinders.
# No source import, new render-step or physics/collision owner is added.
ROTOR=(CLIENT/"ApprovedPerimeterRotorMeshKit.lua").read_text()
ROTOR_LOADER=(ROOT/"src/server/PremiumPerimeterRotorAssets.lua").read_text()
assert 'local CAPS = {Low = 1, Medium = 1, High = 3}' in ROTOR
assert 'local RANGE = {Low = 130, Medium = 170, High = 245}' in ROTOR
assert 'local APPROVED = 133526819668194' in ROTOR
assert 'local ID = 133526819668194' in ROTOR_LOADER
assert 'local NAMES = {"IntakeTurbineL", "IntakeTurbineR", "GeneratorRotor"}' in ROTOR
assert 'if count ~= 7 then return nil end' in ROTOR
assert 'if #parts ~= 7 then' in ROTOR
assert 'for _, native in ipairs(natives) do' in ROTOR
assert 'local model, pieces = fit(source, native)' in ROTOR
assert 'for _, old in ipairs(models) do old:Destroy() end' in ROTOR
assert 'if not genuineStation(arena, station, index) or not source.Parent then' in ROTOR
assert 'for _, model in ipairs(models) do model.Parent = bucket end' in ROTOR
assert 'for _, native in ipairs(natives) do native.Transparency = 1 end' in ROTOR
assert ROTOR.index('for _, model in ipairs(models) do model.Parent = bucket end') < ROTOR.index(
    'for _, native in ipairs(natives) do native.Transparency = 1 end')
assert 'if stress == 1 then cap = math.floor(cap * .5) end' in ROTOR
assert 'if stress >= 2 then cap = 0 end' in ROTOR
assert 'native.Transparency = alpha' in ROTOR
assert 'bucket.ChildRemoved:Connect' in ROTOR
assert 'part.CastShadow = false' in ROTOR
assert 'part.CanCollide = false' in ROTOR
assert 'part.CanTouch = false' in ROTOR
assert 'part.CanQuery = false' in ROTOR
assert 'source:GetAttribute("OwnerVerified") ~= true' in ROTOR
assert 'source:GetAttribute("Original3DAssetId") ~= APPROVED' in ROTOR
assert 'source:GetAttribute("OriginalPerimeterRotor3D") ~= true' in ROTOR
assert '"ApprovedPerimeterRotorsLocal"' in ledger
assert 'RenderStepped' not in ROTOR and 'Heartbeat' not in ROTOR
assert 'AssetService' not in ROTOR
assert 'GlobalApprovedImportGate.load, AssetService, ID' in ROTOR_LOADER
assert ROTOR_LOADER.count('task.spawn(function()') == 1
assert ROTOR_LOADER.count('GlobalApprovedImportGate.load') == 1
print("PASS Android Low: genuine owner-approved 3-rotor sculpt with atomic rollback")

# Android Low allows ONE source-authenticated service-machinery set,
# replacing three cuboids atomically with 3x7 approved MeshParts. The
# same camera pass makes the three approved turbine clones exclusive:
# there must never be 42 machinery + rotor MeshParts on Low.
MACHINE=(CLIENT/"ApprovedPerimeterMachineryMeshKit.lua").read_text()
SERVICE=(ROOT/"src/server/PremiumServiceEquipmentAssets.lua").read_text()
LOD=(CLIENT/"scenery-lod.client.lua").read_text()
assert 'local CAPS = {Low = 1, Medium = 1, High = 3}' in MACHINE
assert 'local DISTANCE = {Low = 125, Medium = 170, High = 245}' in MACHINE
assert 'local IDS = {Core = 127295681925871, Pod = 106083832432833}' in MACHINE
assert 'local function sourceFor(kind, strictSeven)' in MACHINE
assert 'or (strictSeven and count ~= 7) then return nil end' in MACHINE
assert 'local strictSeven = tier == "Low"' in MACHINE
assert 'local core = sourceFor("Core", strictSeven)' in MACHINE
assert 'local pod = sourceFor("Pod", strictSeven)' in MACHINE
assert 'local model, pieces = fit(sources[kind], native, kind)' in MACHINE
assert 'if not model then' in MACHINE
assert 'for _, prior in ipairs(models) do prior:Destroy() end' in MACHINE
assert 'for _, model in ipairs(models) do model.Parent = bucket end' in MACHINE
assert 'for _, native in ipairs(natives) do native.Transparency = 1 end' in MACHINE
assert MACHINE.index('for _, model in ipairs(models) do model.Parent = bucket end') < MACHINE.index(
    'for _, native in ipairs(natives) do native.Transparency = 1 end')
assert 'if stress == 1 then cap = math.floor(cap * 0.5) end' in MACHINE
assert 'native.Transparency = originalAlpha' in MACHINE
assert 'item.CanCollide = false' in MACHINE
assert 'item.CanTouch = false' in MACHINE
assert 'item.CanQuery = false' in MACHINE
assert 'item.CastShadow = false' in MACHINE
assert 'source:GetAttribute("OwnerVerified") ~= true' in MACHINE
assert 'source:GetAttribute("Original3DAssetId") ~= IDS[kind]' in MACHINE
assert 'source:GetAttribute("OriginalService3D") ~= true' in MACHINE
assert 'bucket.Name = "ApprovedPerimeterMachineryLocal"' in MACHINE
assert '"ApprovedPerimeterMachineryLocal"' in ledger
assert 'ApprovedPerimeterMachineryMeshKit.sync(arena, cameraPoint,' in LOD
assert 'local machineStations = ApprovedPerimeterMachineryMeshKit.count()' in LOD
assert 'profile.Name == "Low" and machineStations > 0)' in LOD
assert 'function Kit.sync(arena, cameraPoint, tier, cameraReady, touch, pressure, suppressLow)' in ROTOR
assert 'if tier == "Low" and suppressLow == true then cap = 0 end' in ROTOR
assert LOD.index('local machineStations = ApprovedPerimeterMachineryMeshKit.count()') < LOD.index(
    'ApprovedPerimeterRotorMeshKit.sync(arena, cameraPoint,')
assert 'if stress == 1 then cap = math.floor(cap * .5) end' in ROTOR
assert 'local APPROVED = 133526819668194' in ROTOR
assert 'Towers = 106083832432833' in SERVICE
assert 'Orbital = 127295681925871' in SERVICE
assert 'GlobalApprovedImportGate.load' in SERVICE
assert 'RenderStepped' not in MACHINE and 'Heartbeat' not in MACHINE
assert 'RenderStepped' not in ROTOR and 'Heartbeat' not in ROTOR
assert 'AssetService' not in MACHINE and 'AssetService' not in ROTOR
print("PASS Low machinery/rotor exclusive 21-mesh slot and atomic native fallback")

# Visible original 3D FLOOR: four more sculpted Medium tiles, but
# no change to Low or High resident ceilings and no new 2K PBR textures.
# The existing camera sampler selects foreground before equally distant
# off-screen tiles, preserves the original far-behind penalty and nearby
# underfoot stability. Pressure 1/2 must be able to reclaim added tiles.
GROUND=(CLIENT/"PremiumGroundMeshKit.lua").read_text()
GROUND_PBR=(CLIENT/"PremiumGroundPbrKit.lua").read_text()
assert 'local APPROVED_GROUND_ID = 72507987666671' in GROUND
assert 'Low = {count = 2, distance = 125, retention = 18}' in GROUND
assert 'Medium = {count = 16, distance = 195, retention = 24}' in GROUND
assert 'High = {count = 36, distance = 260, retention = 28}' in GROUND
assert 'Low = {2, 2, 1}' in GROUND
assert 'Medium = {16, 10, 4}' in GROUND
assert 'High = {36, 24, 16}' in GROUND
assert 'if hasFacing and horizontal.Magnitude > 24 then' in GROUND
assert 'if horizontal.Magnitude > 54 and facing < -0.15 then' in GROUND
assert 'priority += 72' in GROUND
assert 'elseif facing > 0.18 then' in GROUND
assert 'priority -= 18 * ahead * facing' in GROUND
assert 'if distance <= budget.distance' in GROUND
assert 'residentLimit = PremiumGroundMeshKit.residencyCount(tier, pressure)' in GROUND
assert 'math.min(budget.count, residentLimit, #candidates)' in GROUND
assert 'if not entry or not wanted[ground]' in GROUND
assert 'or not safeAfterMount(entry, base)' in GROUND
assert 'suppressOverlays(entry)' in GROUND
assert 'PremiumGroundPbrKit.tileBudget(' in GROUND
assert 'if disabled == true or tier == "Low" then return 0 end' in GROUND_PBR
assert '"OriginalPremiumGroundMeshesLocal"' in ledger
# Comments mention RenderStepped for documentation; disallow actual
# callback registration or new frame owners, not harmless comments.
assert '.RenderStepped:Connect(' not in GROUND
assert '.Heartbeat:Connect(' not in GROUND
assert 'AssetService' not in GROUND
print("PASS 16 Medium original floor bays, 2 Low, 36 High, camera-forward ranking")
print("PASS shared floor pressure and native fallback with unchanged 2K atlases")

# One true original station base replacement; reuse the already
# approved seven-MeshPart ground tile without modifying six neon/glass
# warning and navigation cues or adding a renderer/collision owner.
INLAY=(CLIENT/"ApprovedPerimeterStationDeckInlayMeshKit.lua").read_text()
LOD=(CLIENT/"scenery-lod.client.lua").read_text()
MAP=(ROOT/"src/server/MapBuilder.lua").read_text()
assert 'local SOURCE_ID = 72507987666671' in INLAY
assert 'local CAPS = {Low=1,Medium=2,High=4}' in INLAY
assert 'local RANGE = {Low=95,Medium=165,High=225}' in INLAY
assert 'if tier=="High" and touch then cap=2 end' in INLAY
assert 'if p==1 then cap=math.floor(cap*.5) end' in INLAY
assert 'if p>=2 then cap=0 end' in INLAY
assert 'model:GetAttribute("Original3DAssetId")~=SOURCE_ID' in INLAY
assert 'model:GetAttribute("OwnerVerified")~=true' in INLAY
assert 'holder:GetAttribute("OwnerVerified") ~= true' in INLAY
assert 'if count~=7 then return nil end' in INLAY
assert 'source:Clone()' in INLAY and 'clone:ScaleTo(scale)' in INLAY
assert '0,.162-actual.Y*.5,.90' in INLAY
assert INLAY.index('clone.Parent=bucket') < INLAY.index('native.Transparency=1')
assert 'state.native.Transparency = state.alpha' in INLAY
assert 'clone.DescendantRemoving:Connect(' in INLAY
assert 'base:GetPropertyChangedSignal("Size"):Connect(invalid)' in INLAY
assert 'part.CanCollide=false' in INLAY
assert 'part.CanTouch=false' in INLAY
assert 'part.CanQuery=false' in INLAY
assert 'part.CastShadow=false' in INLAY
assert 'bucket.Name = "ApprovedPerimeterStationDeckInlaysLocal"' in INLAY
assert '"ApprovedPerimeterStationDeckInlaysLocal"' in ledger
assert 'ApprovedPerimeterStationDeckInlayMeshKit.sync(arena, cameraPoint,' in LOD
assert 'LocalApprovedStationDeckInlay3DCount' in LOD
assert 'LocalPerimeterPrimitiveBasesReplaced' in LOD
assert 'InlaidStationBase' in MAP and 'WayfindingInset' in INLAY
for label in ('LeftLightNotch','RightLightNotch','CoreLens',
              'WayfindingInset','PodDataRailL','PodDataRailR'):
    assert label in MAP
assert '.RenderStepped:Connect(' not in INLAY
assert '.Heartbeat:Connect(' not in INLAY
assert 'AssetService' not in INLAY
print("PASS authentic original station deck 3D and six protected cues")

# The five existing creator-approved service-hatch models can replace
# ONE foreground Low route surface, not add another seven-piece source
# family on top of carapace/hub or a two-sided Towers Skybridge.
# Catch budget, provenance and native-fallback regressions on every
# change to the actual platform visual owner.
FINISH=(CLIENT/"PlatformFinishKit.lua").read_text(encoding="utf8")
OWNER=(CLIENT/"arena-platform-identity.client.lua").read_text(encoding="utf8")
assert 'local lowReady = tier == "Low" and (tonumber(pressure) or 0) == 0' in FINISH
assert 'if not source or (lowReady and sourceParts ~= 7) then return chosen end' in FINISH
assert 'if lowReady and not hasCamera then return chosen end' in FINISH
assert '(platform.Position-cameraPoint).Magnitude' in FINISH
assert '<= 100' in FINISH
assert 'quota = 1' in FINISH
assert 'or (tier == "Low" and expectedPieces ~= 7)' in FINISH
assert 'or (tier == "Low" and selected ~= true)' in FINISH
assert 'if tier == "Low" then return {} end' in FINISH
assert 'part.CanCollide = false' in FINISH
assert 'part.CanTouch = false' in FINISH
assert 'part.CanQuery = false' in FINISH
# A priority decision must not consume Android Low's scarce 7+7
# genuine 3D source budget until a valid source is ACTUALLY MOUNTED.
# Four finite attempts try the next approved family when a creator asset
# fails ScaleTo, bridge staging, dimensions or mesh clone construction.
# The winner is adopted in the existing platform owner without cloning it
# twice. Medium/High and structural VFX budgets are unchanged.
assert 'local nearServiceHatches = PlatformFinishKit.selectOriginalServiceHatches(' in OWNER
assert 'local lowPreMounted = {}' in OWNER
assert 'if tier.Name == "Low" then' in OWNER
assert 'local function nearest(set)' in OWNER
assert 'if platform.Parent == platforms then' in OWNER
assert 'for _ = 1, 4 do' in OWNER
assert 'local bridge, bridgeDistance = nearest(nearBridgeGirders)' in OWNER
assert 'local carapace, carapaceDistance = nearest(nearCameraCarapaces)' in OWNER
assert 'local hatch, hatchDistance = nearest(nearServiceHatches)' in OWNER
assert 'local foregroundDistance = math.min(' in OWNER
assert 'bridgeDistance <= foregroundDistance + 16' in OWNER
assert 'cameraLook.Y < -0.50' in OWNER
assert 'if lowHubDeck and hullDistance <= math.min(' in OWNER
assert 'elseif carapace and carapaceDistance <= hatchScore + 8 then' in OWNER
assert 'elseif hatch then' in OWNER
assert 'pieces = PremiumPlatformSideMeshKit.bridgeGirders(' in OWNER
assert 'pieces = PremiumLargeDeckHullMeshKit.install(' in OWNER
assert 'pieces = PremiumPlatformSideMeshKit.carapace(' in OWNER
assert 'pieces = PlatformFinishKit.buildServiceHatch(' in OWNER
assert 'local expected = choice == "bridge" and 14 or 7' in OWNER
assert 'if pieces and #pieces == expected then' in OWNER
assert 'lowPreMounted[target] = {kind = choice, parts = pieces}' in OWNER
assert 'for _, piece in ipairs(pieces or {}) do' in OWNER
assert 'piece:Destroy()' in OWNER
assert 'if next(lowPreMounted) == nil then' in OWNER
assert 'local staged = lowPreMounted[platform]' in OWNER
assert 'staged.kind == "hull"' in OWNER
assert 'staged.kind == "carapace"' in OWNER
assert 'staged.kind == "bridge"' in OWNER
assert 'staged.kind == "hatch"' in OWNER
assert 'nearBridgeGirders = {}' in OWNER
assert 'nearCameraCarapaces = {}' in OWNER
assert 'nearServiceHatches = {}' in OWNER
assert 'lowHubDeck = nil' in OWNER
assert 'local lowBridgeChosen = tier.Name == "Low"' in OWNER
assert 'if lowBridgeChosen then' in OWNER
assert 'longCradleBudget = 0' in OWNER
assert 'supportBudget = 0' in OWNER
assert 'or nearServiceHatches[platform] == true' in OWNER
# Regression: the old half-density Low gate filtered EVEN numbered
# real route decks AFTER the source owner selected a seven-MeshPart
# LongCradle or support column. Its mask/collapse/resize registration
# could never execute, leaving primitive posts and wasting the quota.
# Keep half-density primitive paint while opening the structural gate.
gate_start=OWNER.index('if tier.Name ~= "Low" or visualIndex % 2 ~= 0')
gate_end=OWNER.index(' then',gate_start)
low_gate=OWNER[gate_start:gate_end]
for selected in (
    'nearBridgeGirders[platform] == true',
    'nearServiceHatches[platform] == true',
    'nearCradles[platform] == true',
    'nearSupports[platform] == true',
):
    assert selected in low_gate,("even-index real 3D eligibility",selected)
assert OWNER.index('PremiumLargeStructureMeshKit.selectNearRouteStructures(') < gate_start
assert OWNER.index('PremiumLargeStructureMeshKit.longCradle(',gate_end) > gate_end
assert OWNER.index('PremiumLargeStructureMeshKit.supports(',gate_end) > gate_end
assert OWNER.index('registerVisual(platform, piece)',gate_end) > gate_end
assert 'if tier.Name ~= "Low" or visualIndex % 2 ~= 0 then' in (
    OWNER[gate_end:gate_end+900])
assert 'PlatformFinishKit.bindRouteFootprint(' in OWNER
assert 'PlatformFinishKit.applyCollapseVisibility(' in OWNER
assert 'PlatformNativeTrimReplacementKit.bind(' in OWNER
# Streaming a nearby native support later than its collidable PlatformN
# should no longer permanently strand a genuine Low sculpture. Faraway
# posts, pressure>0, and already-funded Low columns must not trigger work.
support_watch=OWNER.split('local function supportChanged(part)',1)[1].split(
    'decorAddedConnection = decor.ChildAdded',1)[0]
assert 'quality == "Low"' in support_watch
assert 'local mountedSupportNatives = {}' in OWNER
assert 'table.clear(mountedSupportNatives)' in OWNER
assert 'mountedSupportNatives[support] = true' in OWNER
assert 'if part.Parent ~= decor then' in support_watch
assert 'if mountedSupportNatives[part] == true then' in support_watch
assert support_watch.index('if part.Parent ~= decor then') < (
    support_watch.index('LocalOriginalNearSupportColumnCount'))

assert 'part.Name:match(' in support_watch
assert '"^PlatformSupport(%d+)_%d+$"' in support_watch
assert 'LocalOriginalNearSupportColumnCount' in support_watch
assert 'OptionalVfxPressure' in support_watch
assert 'platforms:FindFirstChild("Platform"..tostring(index))' in support_watch
assert '(deck.Position-camera.CFrame.Position).Magnitude > 125' in support_watch
assert 'queueSupportRebuild()' in support_watch
assert 'task.delay(0.18, function()' in OWNER
assert 'task.delay(0.12, function()' in OWNER
assert '.RenderStepped:Connect(' not in OWNER
print("PASS Low even-index original undercradle/support adoption, native",
      "half-density retained, late-near support streaming bounded/rebuilt")


assert 'LocalOriginalServiceHatch3DCount' in OWNER
assert '"ArenaPlatformIdentityLocal"' in ledger
assert 'player:GetAttributeChangedSignal("OptionalVfxPressure")' in OWNER
assert '.RenderStepped:Connect(' not in FINISH
assert 'AssetService' not in FINISH
print("PASS atomic Low source mount, four-step retry, shared 7+7 budget and zero native hatch fallback")

for source,owner in EXPECTED.items():
    code=(CLIENT/source).read_text(encoding="utf8")
    assert owner in observed,(source,owner,
        "expected source-level direct workspace mesh owner not discovered")
    assert counts[owner]==1,(source,owner,
        "duplicate or missing LocalFolders entry")
    assert '"'+owner+'"' in code,source
    print("PASS counted real original 3D owner:",source,owner)

# The existing cooperative Android census owns every source, without
# adding another traversal or violating the single-pass owner ledger.
for snippet in (
    "function VisualBudgetRules.collect(root, cooperativeCheckpoint)",
    "for _, folderName in ipairs(VisualBudgetRules.LocalFolders) do",
    "local folder = root:FindFirstChild(folderName)",
    "for _, descendant in ipairs(folder:GetDescendants()) do",
    'descendant:IsA("BasePart")',
    'add(folderName, "Parts")',
    "checkpoint()",
):
    assert snippet in RULES,snippet
pressure=(CLIENT/"visual-budget-pressure.client.lua").read_text(
    encoding="utf8")
assert "VisualBudgetRules.collect(workspace" in pressure
assert "local CENSUS_SECONDS = 20" in pressure
assert "PressureRules.desired(" in pressure
assert "player:SetAttribute(\"OptionalVfxPressure\", nextValue)" in pressure

assert len(observed)>=8,observed
print("PASS",len(observed),"direct-workspace MeshKit/3DKit owners included")
print("PASS unique LocalFolders entries and shared cooperative Android census")
print("LIMIT: static coverage, not measured FPS or Studio screenshot validation")
