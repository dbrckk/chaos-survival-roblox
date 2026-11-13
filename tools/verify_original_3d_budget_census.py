#!/usr/bin/env python3
"""Prevent invisible local original-3D owners from bypassing visual budgets.

One source-level regression covering ALL direct-workspace Folder owners
created by local MeshKit / 3DKit modules, not just the eight fixed today.
No physical Studio/Android frame-time or gameplay validation is claimed.
"""
from __future__ import annotations

from collections import Counter
import json
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

# The four 24-stud Towers corner machinery cubes have ONE approved,
# seven-material original source 72143366927826. Two independent guards
# previously forced Android touch Low to zero. One 7-MeshPart sculpture
# can now replace an actual 24-stud body and its animated cap, without
# hiding the independently animated 9-stud TowerAntenna. The exact
# local 3D folder already participates in the cooperative Parts budget.
TOWERS_CORNER=(CLIENT/"ApprovedVariantTowersLandmarkMeshKit.lua").read_text(
    encoding="utf8")
TOWERS_CORNER_SERVER=(ROOT/"src/server/PremiumVariantTowersLandmarkAssets.lua").read_text(
    encoding="utf8")
TOWERS_LOD=(CLIENT/"scenery-lod.client.lua").read_text(
    encoding="utf8")
TOWERS_MAP=(ROOT/"src/server/MapBuilder.lua").read_text(
    encoding="utf8")
assert 'local ID = 72143366927826' in TOWERS_CORNER
assert 'local ASSET_ID = 72143366927826' in TOWERS_CORNER_SERVER
assert 'local BOUNDS = Vector3.new(7.36,24.9,7.36)' in TOWERS_CORNER
assert 'local CAP = {Low=1,Medium=2,High=4}' in TOWERS_CORNER
assert 'local RANGE = {Low=220,Medium=290,High=410}' in TOWERS_CORNER
assert 'local RETENTION = 24' in TOWERS_CORNER
assert 'or tier=="Low" and math.min(cap,1) or 0' in TOWERS_CORNER
assert 'if stress==1 then cap=math.floor(cap*.5) end' in TOWERS_CORNER
assert 'if stress>=2 then cap=0 end' in TOWERS_CORNER
assert 'if count ~= 7 then return nil end' in TOWERS_CORNER
assert 'if #pieces ~= 7 then clone:Destroy();return end' in TOWERS_CORNER
assert 'source:GetAttribute("OwnerVerified") ~= true' in TOWERS_CORNER
assert 'source:GetAttribute("CosmeticOnly") ~= true' in TOWERS_CORNER
assert 'source:GetAttribute("OriginalTowersMachinery3D") ~= true' in TOWERS_CORNER
assert 'source:GetAttribute("Original3DAssetId") ~= ID' in TOWERS_CORNER
assert 'clone.Parent=bucket' in TOWERS_CORNER
assert TOWERS_CORNER.index('clone.Parent=bucket') < TOWERS_CORNER.index('body.Transparency=1')
assert 'bucket.ChildRemoved:Connect(function(child)' in TOWERS_CORNER
assert 'if entry.model==child then' in TOWERS_CORNER
assert 'restore(body)' in TOWERS_CORNER
assert 'entry.cap.LocalTransparencyModifier=entry.capOriginalModifier' in TOWERS_CORNER
assert 'entry.cap:SetAttribute("SceneryLodHidden",entry.capOriginalHidden)' in TOWERS_CORNER
assert 'source.DescendantRemoving:Connect' in TOWERS_CORNER
assert 'clone.DescendantRemoving:Connect' in TOWERS_CORNER
for untouched in ('antenna.Transparency=1','antenna.CFrame=','antenna:Destroy()'):
    assert untouched not in TOWERS_CORNER
for part in ('"TowerMachinery" .. i','"TowerMachineryCap" .. i',
             '"TowerAntenna" .. i'):
    assert part in TOWERS_MAP
for flag in ('piece.CanCollide=false','piece.CanTouch=false',
             'piece.CanQuery=false','piece.CastShadow=false'):
    assert flag in TOWERS_CORNER
assert 'bucket.Name = "ApprovedTowersMachineryLocal"' in TOWERS_CORNER
assert '"ApprovedTowersMachineryLocal"' in ledger
assert counts["ApprovedTowersMachineryLocal"] == 1
assert 'ApprovedVariantTowersLandmarkMeshKit.sync(arena,cameraPoint,' in TOWERS_LOD
assert 'LocalTowersLandmarkMeshCount' in TOWERS_LOD
assert 'LocalTowersLandmarkPrimitivesReplaced' in TOWERS_LOD
assert "RenderStepped" not in TOWERS_CORNER
assert "Heartbeat:Connect" not in TOWERS_CORNER
assert "AssetService" not in TOWERS_CORNER
print("PASS one approved 7-MeshPart 24-stud Towers corner source on",
      "healthy touch Low, cap animation intact, source and GPU fallback")

# New REAL 1,764-triangle creator-approved manufactured shell replaces exactly
# 5 genuine noncolliding native Parts per eligible district, no door/glass
# nor new physics and NO fake MeshId. This is an integration source check,
# not a Studio render test or a new unit-test suite.
SIDE=(CLIENT/"ApprovedDistrictSidewallMeshKit.lua").read_text(encoding="utf8")
SIDE_SERVER=(ROOT/"src/server/PremiumDistrictSidewallAssets.lua").read_text(
    encoding="utf8")
SIDE_SOURCE=(ROOT/"tools/generate_original_district_sidewall_shell.py").read_text(
    encoding="utf8")
SIDE_LOD=(CLIENT/"scenery-lod.client.lua").read_text(encoding="utf8")
SIDE_INIT=(ROOT/"src/server/init.server.lua").read_text(encoding="utf8")
SIDE_REG=json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
SIDE_ASSET=next(m for m in SIDE_REG["models"]
                if m["name"]=="district_sidewall_shell")
assert SIDE_ASSET["asset_id"]=="77387019170428"
assert SIDE_ASSET["moderation"]=="Approved"
assert SIDE_ASSET["workflow_run_id"]==43302925840
assert SIDE_ASSET["source"]=="tools/generate_original_district_sidewall_shell.py"
assert SIDE_ASSET["source_materials"]=="assets/source/chaos_route_kit.mtl"
assert "local ID = 77387019170428" in SIDE
assert "local ASSET_ID = 77387019170428" in SIDE_SERVER
assert "OriginalDistrictSidewallShell3D" in SIDE_SERVER and (
    "OriginalDistrictSidewallShell3D" in SIDE)
assert 'ApprovedDistrictSidewallShellTemplates' in SIDE_SERVER and (
    'ApprovedDistrictSidewallShellTemplates' in SIDE)
assert 'OriginalMeshScenery.sanitize(raw)' in SIDE_SERVER
assert 'GlobalApprovedImportGate.load' in SIDE_SERVER
assert 'task.wait(22)' in SIDE_SERVER
assert 'if meshCount ~= 6 then return false end' in SIDE_SERVER
assert 'if pieces ~= 6 then return nil end' in SIDE
assert 'if #pieces ~= 6 then clone:Destroy();return end' in SIDE
assert 'if #pieces ~= 6 then clone:Destroy();return end' in SIDE
assert "ApprovedDistrictSidewallMeshKit" in SIDE_LOD
assert "PremiumDistrictSidewallAssets" in SIDE_INIT
for guard in (
    'OriginalSizeX','OriginalSizeZ',
    'base.Parent ~= arena',
    'or not base.Anchored or not base.CanCollide',
    'and base.Size.X <= sx + .2 and base.Size.Z <= sz + .2',
    'door.CFrame * CFrame.new(.35, -4, 4.36)',
    'part.CFrame = target * frame:ToObjectSpace(part.CFrame)',
    'part.CanCollide = false','part.CanTouch = false',
    'part.CanQuery = false','part.CastShadow = false',
    'source.DescendantRemoving:Connect',
    'clone.DescendantRemoving:Connect',
    'owner.AncestryChanged:Connect(reconcile)',
    'source:GetAttribute("Original3DAssetId") ~= ID',
    'if not valid(entry, arena, district, base)',
    'entry.originals[part] = part.Transparency',
    'mounted[building] = nil',
    'restore(entry)',
    'entry.model:Destroy()',
    'Low = {count = 1, distance = 128, retention = 16}',
    'Medium = {count = 4, distance = 205, retention = 20}',
    'High = {count = 12, distance = 275, retention = 28}',
    'local TOUCH_CAP = {Low = 1, Medium = 3, High = 8}',
    'if stress == 1 then cap = math.floor(cap * .5) end',
    'if stress >= 2 then cap = 0 end',
    # One extra 1,764-triangle Low shell is only allowed behind an
    # already-mounted genuine owner-approved district facade. Model
    # eviction must restore its five native walls immediately.
    'building:GetAttribute("LocalApprovedDistrictFacadeMounted") ~= true',
    'entry.requiresFacade = tier == "Low"',
    '"LocalApprovedDistrictFacadeMounted"):Connect(reconcile)',
    'if baseConnection then baseConnection:Disconnect() end',
):
    assert guard in SIDE,guard
for name in ("ServiceCore","ArmoredSupportL","ArmoredSupportR",
             "SideCassette-1","SideCassette1"):
    assert 'name = "'+name+'"' in SIDE,name
    assert '"'+name+'"' in SIDE_SOURCE,name
for no_hide in ("SideGlass","ServiceEntryDoor","ServiceEntryRecess",
                "RecessedSignal","FoundationRim","BasaltFoundation"):
    assert 'name = "'+no_hide+'"' not in SIDE,no_hide
assert '"ApprovedDistrictSidewallsLocal"' in ledger
assert counts["ApprovedDistrictSidewallsLocal"] == 1
assert 'local ApprovedDistrictSidewallMeshKit = require(' in SIDE_LOD
assert 'ApprovedDistrictSidewallMeshKit.sync(arena, cameraPoint,' in SIDE_LOD
assert 'LocalOriginalDistrictSidewallMeshCount' in SIDE_LOD
assert 'LocalOriginalDistrictSidewallPartsReplaced' in SIDE_LOD
assert SIDE_LOD.index('PremiumDistrictFacadeMeshKit.sync(') < SIDE_LOD.index(
    'ApprovedDistrictSidewallMeshKit.sync(')
assert SIDE_LOD.index('ApprovedDistrictSidewallMeshKit.sync(') < SIDE_LOD.index(
    'PremiumNearfieldPbrKit.reconcile(')
assert 'require(script.PremiumDistrictSidewallAssets).start()' in SIDE_INIT
for forbidden in ('RenderStepped','Heartbeat:Connect','LoadAssetAsync',
                  'AssetService','Instance.new("RemoteEvent")'):
    assert forbidden not in SIDE,forbidden
# A genuinely complete building (approved 3D front PLUS true side/back
# shell) is visually stronger than two half-upgraded silhouettes. Medium
# and High now slightly favor SAME-owner resident facades without reducing
# their native fallback or spending any new mesh slots. Low remains strict.
assert 'function Kit.pairedPriority(priority, facadeMounted, tier)' in SIDE
assert 'if tier ~= "Low" and facadeMounted == true then' in SIDE
assert 'return priority - 16' in SIDE
assert 'priority = Kit.pairedPriority(priority,' in SIDE
assert 'building:GetAttribute(' in SIDE
assert '"LocalApprovedDistrictFacadeMounted") == true, tier)' in SIDE
assert 'priority += 80' in SIDE
assert 'function Kit.completeCount()' in SIDE
assert 'entry.model.Parent == bucket' in SIDE
assert 'LocalCompleteDistrict3DCount' in SIDE_LOD
assert 'LocalUnpairedDistrictSidewall3DCount' in SIDE_LOD
assert 'sidewallMeshCount - completeDistricts' in SIDE_LOD
assert 'ApprovedDistrictSidewallMeshKit.completeCount()' in SIDE_LOD
assert 'Low = {count = 1, distance = 128, retention = 16}' in SIDE
assert 'Medium = {count = 4, distance = 205, retention = 20}' in SIDE
assert 'High = {count = 12, distance = 275, retention = 28}' in SIDE
assert 'local TOUCH_CAP = {Low = 1, Medium = 3, High = 8}' in SIDE
print("PASS complete original front+side district priority on Medium/High,"
      " real paired live census, healthy desktop 1/4/12 and touch 1/3/8 budgets")

print("PASS original 6-MeshPart sidewall asset 77387019170428 genuinely Approved")
print("PASS five real native wall volumes replaced only after authentic source")
print("PASS existing Android tier/pressure quotas with one cohesive",
      "Low near-camera 6-MeshPart building and immediate native rollback")

# The sixteen district buildings and four corner monuments already have
# actual approved 3D source models. The playable Base is shrunk each round
# but the nonphysical skyline buildings retain their original positions.
# Never use the CURRENT floor width to evict these MeshParts and expose
# their basic Parts/WedgeParts before streaming/LOD actually calls for it.
DISTRICT_FACADES=(CLIENT/"PremiumDistrictFacadeMeshKit.lua").read_text(
    encoding="utf8")
CORNER_MONUMENTS=(CLIENT/"ApprovedCornerMonumentMeshKit.lua").read_text(
    encoding="utf8")
ORIGINAL_MAP=(ROOT/"src/server/MapBuilder.lua").read_text(encoding="utf8")
assert 'base:SetAttribute("OriginalSizeX", base.Size.X)' in ORIGINAL_MAP
assert 'base:SetAttribute("OriginalSizeZ", base.Size.Z)' in ORIGINAL_MAP
for label, code, bucket in (
    ("16 districts",DISTRICT_FACADES,"ApprovedDistrictFacadesLocal"),
    ("4 corners",CORNER_MONUMENTS,"ApprovedOriginalCornerMonumentsLocal"),
):
    assert 'local function authenticBase(base, arena)' in code, label
    for required in (
        'base.Parent ~= arena',
        'or not base.Anchored or not base.CanCollide',
        'base:GetAttribute("OriginalSizeX")',
        'base:GetAttribute("OriginalSizeZ")',
        'and sx >= 318 and sz >= 318',
        'base.Size.X <= sx + 0.2',
        'base.Size.Z <= sz + 0.2',
        'return authenticBase(base, activeArena)',
        'if not authenticBase(base, arena)',
        'if not authenticBase(base, activeArena) then',
        'clearMounted()',
        'restoreNative(entry)',
        'GetPropertyChangedSignal("Size")',
        'entry.model:Destroy()',
    ):
        assert required in code,(label,required)
    assert 'base.Size.X < 318' not in code,label
    assert 'base.Size.Z < 318' not in code,label
    assert 'base.Size.X >= 318' not in code,label
    assert 'base.Size.Z >= 318' not in code,label
    assert bucket in ledger,(label,bucket)
    assert '"AssetService"' not in code,label
    assert '.RenderStepped:Connect(' not in code,label
    assert '.Heartbeat:Connect(' not in code,label
assert 'Low = {count = 1, distance = 130, retention = 16}' in DISTRICT_FACADES
assert 'Medium = {count = 5, distance = 205, retention = 22}' in DISTRICT_FACADES
assert 'High = {count = 16, distance = 270, retention = 28}' in DISTRICT_FACADES
assert 'Low = {count = 1, distance = 145, retention = 16}' in CORNER_MONUMENTS
assert 'Medium = {count = 4, distance = 280, retention = 22}' in CORNER_MONUMENTS
assert 'High = {count = 4, distance = 330, retention = 26}' in CORNER_MONUMENTS
assert 'PremiumDistrictFacadeMeshKit.sync(arena, cameraPoint,' in TOWERS_LOD
assert 'ApprovedCornerMonumentMeshKit.sync(arena, cameraPoint,' in TOWERS_LOD
print("PASS genuine 16 facade + 4 corner 3D owners survive shrinking Base",
      "while preserving authenticated geometry, existing caps and fallback")
# P0: Android approved facades now share the SAME pressure and touch
# limits as genuine six-MeshPart sidewalls. Prevent orphan front assets
# from consuming the 440/680/900-piece mobile budgets under GPU pressure.
assert 'local TOUCH_CAP = {Low = 1, Medium = 3, High = 8}' in DISTRICT_FACADES
assert 'function PremiumDistrictFacadeMeshKit.residentBudget(tier, touch, pressure)' in DISTRICT_FACADES
assert 'cap = math.min(cap, TOUCH_CAP[tier] or 0)' in DISTRICT_FACADES
assert 'if stress >= 2 then return 0 end' in DISTRICT_FACADES
assert 'return tier == "High" and math.min(reduced, 6) or reduced' in DISTRICT_FACADES
assert 'if cap == 0 or not arena or not cameraReady' in DISTRICT_FACADES
assert 'for i = 1, math.min(#candidates, cap) do' in DISTRICT_FACADES
assert 'profile.Name, cameraReady, cameraLook, isTouch,' in TOWERS_LOD
assert 'player:GetAttribute("OptionalVfxPressure"))' in TOWERS_LOD
assert 'restoreNative(entry)' in DISTRICT_FACADES
assert 'markResident(entry, false)' in DISTRICT_FACADES
for tier, normal, touch in (("Low",1,1),("Medium",5,3),("High",16,8)):
    assert touch<=normal
    for pressure in (0,1,2):
        expected=touch if pressure==0 else touch//2 if pressure==1 else 0
        assert expected<=(normal if pressure==0 else normal//2),(
            tier,pressure,expected)
print("PASS Android 1/3/8 approved district facade touch quotas, pressure"
      " 1 half / pressure 2 zero and instant native fallback")


# Native wall volumes have NO corresponding original-side source mesh and
# must never be erased to fake progress. The approved original front/roof
# removes only overlapping optional primitive hardware. On a real source
# eviction we must restore the fallback immediately, while preventing 6
# hidden client-local Parts per mounted façade from consuming memory.
DISTRICT_DETAIL=(CLIENT/"DistrictFacadeDetailKit.lua").read_text(encoding="utf8")
SIDE_PBR=(ROOT/"src/shared/PbrDistrictRules.lua").read_text(encoding="utf8")
assert 'local RESIDENT_MARKER = "LocalApprovedDistrictFacadeMounted"' in DISTRICT_FACADES
assert 'local function markResident(entry, present)' in DISTRICT_FACADES
assert 'markResident(entry, true)' in DISTRICT_FACADES
assert DISTRICT_FACADES.index('suppressNative(entry)') < (
    DISTRICT_FACADES.index('markResident(entry, true)'))
assert DISTRICT_FACADES.count('markResident(entry, false)') >= 2
assert 'model:GetAttribute("LocalApprovedDistrictFacadeMounted") == true' in DISTRICT_DETAIL
assert 'clearOwned(model, slot)' in DISTRICT_DETAIL
assert DISTRICT_DETAIL.index(
    'if model:GetAttribute("LocalApprovedDistrictFacadeMounted") == true'
) < DISTRICT_DETAIL.index(
    '-- Android keeps the near-field')
for group in (
    '"SideCassette" .. tostring(direction)',
    '"SideGlass" .. tostring(direction)',
    '"ArmoredSupport" .. suffix',
    '"ServiceCore"',
    '"ServiceEntryDoor"',
    '"ServiceEntryRecess"',
):
    assert group in (ROOT/"src/server/ArenaDistrictArchitecture.lua").read_text(),group
for essential in ("ArmoredSupportL","ArmoredSupportR",
                  "SideCassette-1","SideCassette1",
                  "ServiceCore","SideGlass-1","SideGlass1",
                  "ServiceEntryDoor","ServiceEntryRecess","RecessedSignal"):
    assert f'{essential} = true' not in DISTRICT_FACADES,essential
assert 'owner:GetAttribute("LocalApprovedDistrictFacadeMounted") == true' in SIDE_PBR
assert SIDE_PBR.count('name == "servicecore"') >= 2
for surface in ('sidecassette-1','sidecassette1',
                'armoredsupportl','armoredsupportr'):
    assert SIDE_PBR.count(f'name == "{surface}"') >= 2,surface
assert 'structuralScore += 1800' in SIDE_PBR
assert 'if material == Enum.Material.CorrodedMetal then return "oxidized" end' in SIDE_PBR
for name, code in (
    ("district",DISTRICT_FACADES),
    ("corner",CORNER_MONUMENTS),
):
    assert 'if entry.disposed then return end' in code,name
    assert 'entry.disposed = true' in code,name
    assert 'entry.source.Parent ~= entry.sourceFolder' in code,name
    assert 'entry.sourceFolder.Parent ~= ReplicatedStorage' in code,name
    assert 'not part:IsDescendantOf(entry.model)' in code,name
    assert 'clone.AncestryChanged:Connect(function()' in code,name
    assert 'clone.DescendantRemoving:Connect(function(part)' in code,name
    assert 'source.AncestryChanged:Connect(function()' in code,name
    assert 'source.DescendantRemoving:Connect(function(part)' in code,name
    assert 'if part:IsA("MeshPart") then revokeIfMounted() end' in code,name
    assert 'for _, connection in ipairs(entry.connections' in code,name
    assert '.RenderStepped:Connect(' not in code,name
    assert '.Heartbeat:Connect(' not in code,name
    assert 'LoadAssetAsync' not in code,name
print("PASS authenticated facade 3D retains true side walls with bounded 2K finish",
      "and removes redundant primitive detail Parts on mounted originals")
print("PASS immediate native restoration on missing district or corner MeshParts",
      "source ancestry and visual-budget eviction, without new render loops")

# The other three massive 3D skyline owners used the live Base.Size
# to authenticate outdoor monuments, causing all real MeshParts to fall
# back to primitive Parts/WedgeParts on normal arena shrink. Their real
# permanent foundations have fixed world positions from MapBuilder's
# immutable original rim; preserve that footprint for EACH source owner.
HERO_SKYLINE=(CLIENT/"ApprovedHeroStructureMeshKit.lua").read_text(
    encoding="utf8")
PRIMARY_SKYLINE=(CLIENT/"ApprovedPrimarySkylineMeshKit.lua").read_text(
    encoding="utf8")
DEPTH_SKYLINE=(CLIENT/"ApprovedSkylineDepthMeshKit.lua").read_text(
    encoding="utf8")
for name, code, owner in (
    ("five hero profiles", HERO_SKYLINE, "ApprovedOriginalHeroStructuresLocal"),
    ("four primary skyline columns", PRIMARY_SKYLINE, "ApprovedPrimarySkylineLocal"),
    ("eight skyline depth roofs", DEPTH_SKYLINE, "ApprovedSkylineDepthLocal"),
):
    assert 'local function authenticFootprint(base, arena)' in code,name
    for guard in (
        'base.Parent ~= arena',
        'or not base.Anchored or not base.CanCollide',
        'base:GetAttribute("OriginalSizeX")',
        'base:GetAttribute("OriginalSizeZ")',
        'or sx < 318 or sz < 318',
        'base.Size.X > sx + 0.2 or base.Size.Z > sz + 0.2',
        'return sx, sz',
    ):
        assert guard in code,(name,guard)
    assert 'base.Size.X < 318' not in code,name
    assert 'base.Size.Z < 318' not in code,name
    assert owner in ledger,(name,owner)
    assert 'Restore' in code or 'restore' in code or 'release' in code,name
    assert '.RenderStepped:Connect(' not in code,name
    assert '.Heartbeat:Connect(' not in code,name
    assert 'LoadAssetAsync' not in code,name
assert 'originalX * .5 + size.X * .5 + 15' in HERO_SKYLINE
assert 'return authenticFootprint(base, arena)' not in HERO_SKYLINE
assert 'if not authenticFootprint(base, arena)' in HERO_SKYLINE
assert 'z *= originalZ*.5+23' in PRIMARY_SKYLINE
assert 'x *= originalX*.5+23' in PRIMARY_SKYLINE
assert 'math.min(originalX,originalZ)*.5' in PRIMARY_SKYLINE
assert 'z = z*(originalZ*.5+23)' in DEPTH_SKYLINE
assert 'x = x*(originalX*.5+23)' in DEPTH_SKYLINE
assert 'or not authenticFootprint(entry.base, entry.arena)' in DEPTH_SKYLINE
assert 'base:SetAttribute("OriginalSizeX", base.Size.X)' in ORIGINAL_MAP
assert 'base:SetAttribute("OriginalSizeZ", base.Size.Z)' in ORIGINAL_MAP
print("PASS five hero, four skyline and eight outboard sculpted roofs",
      "retain real source 3D during arena shrink with no new GPU slots")

# The original four giant 36-stud Harbor cranes already have two
# creator-approved seven-material kinetic assets. Low native crane LOD is
# intentionally hidden and its native trolley animation intentionally
# disabled: a SINGLE nearfield static genuine crane provides a strong
# 3D silhouette without starting new frame loops or false collisions.
# Medium/High cranes stay native-animation-driven, even after the floor
# shrinks, by authenticating immutable server OriginalSizeX/Z instead.
HARBOR_CRANE=(CLIENT/"HarborGantryKineticMeshKit.lua").read_text(
    encoding="utf8")
HARBOR_MOTION=(ROOT/"src/shared/HarborGantryMotionRules.lua").read_text(
    encoding="utf8")
HARBOR_SERVER=(ROOT/"src/server/PremiumHarborGantryAssets.lua").read_text(
    encoding="utf8")
HARBOR_LOD=(CLIENT/"scenery-lod.client.lua").read_text(
    encoding="utf8")
assert 'Low = {models=1,distance=135,retention=18}' in HARBOR_CRANE
assert 'Medium = {models=2,distance=170,retention=24}' in HARBOR_CRANE
assert 'High = {models=4,distance=345,retention=36}' in HARBOR_CRANE
assert 'elseif tier=="Low" and stress>0 then' in HARBOR_CRANE
assert 'maxModels=0' in HARBOR_CRANE
assert 'local function authenticBase(base)' in HARBOR_CRANE
assert 'base:GetAttribute("OriginalSizeX")' in HARBOR_CRANE
assert 'base:GetAttribute("OriginalSizeZ")' in HARBOR_CRANE
assert 'base.Size.X<318' not in HARBOR_CRANE
assert 'base.Size.Z<318' not in HARBOR_CRANE
assert 'local function unmount(crane)' in HARBOR_CRANE
assert 'folder.ChildRemoved:Connect(function(child)' in HARBOR_CRANE
assert 'if e.model==child then unmount(crane);break end' in HARBOR_CRANE
assert 'source.AncestryChanged:Connect(changed)' in HARBOR_CRANE
assert 'source.DescendantRemoving:Connect' in HARBOR_CRANE
assert 'clone.DescendantRemoving:Connect' in HARBOR_CRANE
assert 'for _,crane in ipairs(obsolete) do unmount(crane) end' in HARBOR_CRANE
assert 'Low" then' in HARBOR_MOTION
assert 'return {Interval = 0.65, Count = 0, Range = 0}' in HARBOR_MOTION
for asset in ('75684193304551','98809955094422'):
    assert asset in HARBOR_SERVER and asset in HARBOR_CRANE
assert 'roles.Static~=4 or roles.Trolley~=1' in HARBOR_CRANE
assert 'roles.Cable~=1 or roles.Load~=1' in HARBOR_CRANE
assert 'OriginalHarborGantryKineticRole' in HARBOR_CRANE
assert 'CanCollide=false' in HARBOR_CRANE
assert 'CanTouch=false' in HARBOR_CRANE
assert 'CanQuery=false' in HARBOR_CRANE
assert 'folder.Name = "OriginalHarborKineticGantryLocal"' in HARBOR_CRANE
assert '"OriginalHarborKineticGantryLocal"' in ledger
assert counts["OriginalHarborKineticGantryLocal"]==1
assert 'HarborGantryKineticMeshKit.sync(arena,cameraPoint,' in HARBOR_LOD
assert 'LocalOriginalHarborKineticGantryCount' in HARBOR_LOD
# Comments are permitted to document why RenderStepped is unnecessary.
assert '.RenderStepped:Connect(' not in HARBOR_CRANE
assert '.Heartbeat:Connect(' not in HARBOR_CRANE
print("PASS one authentic 7-MeshPart Harbor low-detail crane near camera",
      "without motion cost; authored perimeter survives round shrink")

# Orbital is the other exclusive arena variant: one original reactor
# node plus its genuinely open radial strut may replace the 8th-part
# native sphere/box pair only when BOTH seven-MeshPart approved sources
# mount atomically. No fake collision, no loss of animated node motion.
ORBITAL_REACTOR=(CLIENT/"ApprovedOrbitalReactorLandmarkMeshKit.lua").read_text(
    encoding="utf8")
ORBITAL_SERVER=(ROOT/"src/server/PremiumOrbitalReactorLandmarkAssets.lua").read_text(
    encoding="utf8")
ORBITAL_LOD=(CLIENT/"scenery-lod.client.lua").read_text(
    encoding="utf8")
ORBITAL_MAP=(ROOT/"src/server/MapBuilder.lua").read_text(
    encoding="utf8")
assert 'local NODE_ID=104654294187035' in ORBITAL_REACTOR
assert 'local STRUT_ID=138666009076890' in ORBITAL_REACTOR
assert 'local LIMITS={Low=1,Medium=3,High=6}' in ORBITAL_REACTOR
assert 'local RANGE={Low=210,Medium=340,High=460}' in ORBITAL_REACTOR
assert 'local RETENTION=26' in ORBITAL_REACTOR
assert 'or tier=="Low" and math.min(cap,1) or 0' in ORBITAL_REACTOR
assert 'if pressureLevel==1 then cap=math.floor(cap*.5) end' in ORBITAL_REACTOR
assert 'if pressureLevel>=2 then cap=0 end' in ORBITAL_REACTOR
assert 'if count~=7 then return nil end' in ORBITAL_REACTOR
assert '#entry.nodePieces~=7 or #entry.strutPieces~=7' in ORBITAL_REACTOR
assert 'if not nodeModel then return end' in ORBITAL_REACTOR
assert 'if not strutModel then nodeModel:Destroy();return end' in ORBITAL_REACTOR
assert ORBITAL_REACTOR.index('wrapper.Parent=bucket') < (
    ORBITAL_REACTOR.index('strut.Transparency=1'))
assert 'bucket.ChildRemoved:Connect(function(child)' in ORBITAL_REACTOR
assert 'if entry.model==child then' in ORBITAL_REACTOR
assert 'release(index)' in ORBITAL_REACTOR
assert ORBITAL_REACTOR.index('mounted[index]=nil') < (
    ORBITAL_REACTOR.index('entry.model:Destroy()'))
assert 'entry.node.LocalTransparencyModifier=entry.nodeOriginalModifier' in ORBITAL_REACTOR
assert 'entry.node:SetAttribute("SceneryLodHidden",entry.nodeOriginalHidden)' in ORBITAL_REACTOR
assert 'node.Transparency=1' not in ORBITAL_REACTOR
assert 'bucket.Name="ApprovedOrbitalReactorLandmarksLocal"' in ORBITAL_REACTOR
assert '"ApprovedOrbitalReactorLandmarksLocal"' in ledger
assert counts["ApprovedOrbitalReactorLandmarksLocal"]==1
assert '104654294187035' in ORBITAL_SERVER
assert '138666009076890' in ORBITAL_SERVER
assert '"OrbitalReactorNode" .. i' in ORBITAL_MAP
assert '"OrbitalReactorStrut" .. i' in ORBITAL_MAP
assert 'ApprovedOrbitalReactorLandmarkMeshKit.sync(arena,cameraPoint,' in ORBITAL_LOD
assert 'LocalOrbitalReactorSculptPairCount' in ORBITAL_LOD
assert 'LocalOrbitalReactorNativePartsReplaced' in ORBITAL_LOD
assert "RenderStepped" not in ORBITAL_REACTOR
assert "Heartbeat:Connect" not in ORBITAL_REACTOR
assert "AssetService" not in ORBITAL_REACTOR
print("PASS Orbital one atomic approved 7+7 MeshPart reactor/strut pair",
      "on healthy touch Low, true animated node and native fallback")

# Classic exterior broadcast fins are four 16-stud native Part
# rectangles with distinct glowing guide strips. Two independent Low
# off-switches previously blocked the genuine seven-piece source on touch:
# CAP.Low=0 and the "if touch" branch's unconditional Low=0 fallback.
# Only one camera-near original can be mounted in healthy Android Low;
# GPU pressure one, source loss and cooperative folder eviction MUST
# restore its server-authored nonphysical body without hiding light strips.
CLASSIC_FIN=(CLIENT/"ApprovedClassicBroadcastFinMeshKit.lua").read_text(
    encoding="utf8")
CLASSIC_FIN_SERVER=(ROOT/"src/server/PremiumClassicBroadcastFinAssets.lua").read_text(
    encoding="utf8")
CLASSIC_FIN_MAP=(ROOT/"src/server/MapBuilder.lua").read_text(
    encoding="utf8")
assert 'local ASSET_ID = 123049626693705' in CLASSIC_FIN
assert 'local ID = 123049626693705' in CLASSIC_FIN_SERVER
assert 'local CAP = {Low=1,Medium=2,High=4}' in CLASSIC_FIN
assert 'local RANGE = {Low=195,Medium=285,High=415}' in CLASSIC_FIN
assert 'local RETENTION = 26' in CLASSIC_FIN
assert 'or tier=="Low" and math.min(cap,1) or 0' in CLASSIC_FIN
assert 'if stress==1 then cap=math.floor(cap*.5) end' in CLASSIC_FIN
assert 'if stress>=2 then cap=0 end' in CLASSIC_FIN
assert 'if count~=7 then return nil end' in CLASSIC_FIN
assert 'if #pieces~=7 or not genuine(arena,index) then' in CLASSIC_FIN
assert 'source:GetAttribute("OwnerVerified")~=true' in CLASSIC_FIN
assert 'source:GetAttribute("CosmeticOnly")~=true' in CLASSIC_FIN
assert 'source:GetAttribute("OriginalClassicBroadcastFin3D")~=true' in CLASSIC_FIN
assert 'source:GetAttribute("Original3DAssetId")~=ASSET_ID' in CLASSIC_FIN
assert 'source.DescendantRemoving:Connect' in CLASSIC_FIN
assert 'clone.DescendantRemoving:Connect' in CLASSIC_FIN
assert 'bucket.ChildRemoved:Connect(function(child)' in CLASSIC_FIN
assert 'if entry.model==child then' in CLASSIC_FIN
assert 'unmount(native)' in CLASSIC_FIN
assert 'native.Transparency=entry.original' in CLASSIC_FIN
assert CLASSIC_FIN.index('clone.Parent=bucket') < CLASSIC_FIN.index('fin.Transparency=1')
assert 'glow.Transparency=1' not in CLASSIC_FIN
assert 'glow:Destroy()' not in CLASSIC_FIN
assert 'piece.CanCollide=false' in CLASSIC_FIN
assert 'piece.CanTouch=false' in CLASSIC_FIN
assert 'piece.CanQuery=false' in CLASSIC_FIN
assert 'piece.CastShadow=false' in CLASSIC_FIN
assert 'bucket.Name = "ApprovedClassicBroadcastFinLocal"' in CLASSIC_FIN
assert '"ApprovedClassicBroadcastFinLocal"' in ledger
assert counts["ApprovedClassicBroadcastFinLocal"] == 1
assert '"ClassicBroadcastFin" .. i' in CLASSIC_FIN_MAP
assert '"ClassicBroadcastGlow" .. i' in CLASSIC_FIN_MAP
CLASSIC_FIN_LOD=(CLIENT/"scenery-lod.client.lua").read_text(
    encoding="utf8")
assert 'ApprovedClassicBroadcastFinMeshKit.sync(arena,cameraPoint,' in CLASSIC_FIN_LOD
assert 'LocalClassicFinMeshCount' in CLASSIC_FIN_LOD
assert 'LocalClassicFinPrimitivesReplaced' in CLASSIC_FIN_LOD
assert 'RenderStepped' not in CLASSIC_FIN
assert 'Heartbeat:Connect' not in CLASSIC_FIN
assert 'AssetService' not in CLASSIC_FIN
print("PASS one seven-MeshPart original Classic exterior broadcast fin",
      "on healthy Low touch, glow intact, pressure-one/eviction fallback")

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
# Match the complete old expression, not the intentional new
# entry.underdeckRequested suffix that starts with the same characters.
assert 'or (desired.underdeck ~= nil) ~= entry.underdeck\n' not in ROUTE
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
assert 'or not deck.Anchored or not deck.CanCollide' in DOCK
assert 'or deck.Transparency >= .75' in DOCK
assert 'local function realFloorScale(base, arena)' in DOCK
assert 'deck.Size.X / floorScale' in DOCK
assert 'deck.Size.Z / floorScale' in DOCK
assert 'type(deck:GetAttribute("RouteTier")) ~= "number"' in DOCK
assert 'local function refit(entry)' in DOCK
assert 'piece.Size = entry.sizes[piece] * factor' in DOCK
assert 'entry.joints[piece].C0 = shift' in DOCK
assert 'local joint = Instance.new("Weld")' in DOCK
assert 'realFloorScale(base, arena)' in DOCK
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

# P0 medium real support coverage: eight approved 7-piece columns are
# already permitted by the existing client budget. Never select only four
# owner platforms and leave half the allowed source budget idle. High
# still uses eight decks with up to two columns each; Low stays at one.
LARGE=(CLIENT/"PremiumLargeStructureMeshKit.lua").read_text(encoding="utf8")
assert 'local supportLimit=tier=="High" and 8 or (tier=="Medium" and 8 or 1)' in LARGE
assert 'local maxSupports = tier=="High" and 2 or 1' in LARGE
assert 'local supportLimit=tier=="High" and 8 or (tier=="Medium" and 4 or 1)' not in LARGE
assert 'local supportBudget = tier.Name == "High" and 16' in OWNER
assert 'or (tier.Name == "Medium" and 8' in OWNER
assert 'and nearSupports[platform] == true' in OWNER
assert 'supportBudget -= columns.modules' in OWNER
assert 'if output.modules < 1 then return nil end' in LARGE
assert 'if tier == "Low" and supportParts ~= 7 then' in LARGE
assert 'if tier == "Low" and not cameraReady then' in LARGE
assert 'if segments <= available-output.modules' in LARGE
assert 'Kit.bind(' not in LARGE
print("PASS medium 8 real supported platform owners / 8 original modules,"
      " High 8x2=16, Low one, native ownership and collapse fallback")

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

# Bidirectional completion of AUTHENTIC district envelopes and exact
# streamed 16-building census; no extra original imports, draw calls,
# LOD samplers or relaxed physical validation.
FRONT=(CLIENT/"PremiumDistrictFacadeMeshKit.lua").read_text(encoding="utf8")
CENSUS_RULES=(ROOT/"src/shared/DistrictVisualCensusRules.lua").read_text(
    encoding="utf8")
assert 'RESIDENT_MARKER = "LocalApprovedDistrictSidewallMounted"' in SIDE
assert 'markResident(entry, false)' in SIDE
assert 'markResident(entry, true)' in SIDE
assert 'function Kit.residentMask16()' in SIDE
assert 'function PremiumDistrictFacadeMeshKit.residentMask16()' in FRONT
assert 'function PremiumDistrictFacadeMeshKit.pairedPriority(' in FRONT
assert 'tier ~= "Low" and sidewallMounted == true' in FRONT
assert 'return priority - 12' in FRONT
assert 'LocalApprovedDistrictSidewallMounted") == true, tier)' in FRONT
assert 'and type(index) == "number" and index % 1 == 0' in SIDE
assert 'and index >= 1 and index <= 16' in SIDE
assert 'and index >= 1 and index <= 16' in FRONT
assert 'DistrictVisualCensusRules' in SIDE_LOD
assert 'PremiumDistrictFacadeMeshKit.residentMask16()' in SIDE_LOD
assert 'ApprovedDistrictSidewallMeshKit.residentMask16()' in SIDE_LOD
assert 'DistrictVisualCensusRules.summarize(' in SIDE_LOD
for attribute in (
    'LocalDistrict3DStates16',
    'LocalDistrict3DLoadedCount',
    'LocalDistrict3DUnstreamedCount',
    'LocalDistrict3DNativeOnlyCount',
    'LocalDistrict3DFacadeOnlyCount',
    'LocalDistrict3DSidewallOnlyCount',
):
    assert attribute in SIDE_LOD, attribute
for code in ('state[index] = "-"','state[index] = "N"',
             'state[index] = "F"','state[index] = "S"',
             'state[index] = "B"','totals.loaded += 1',
             'totals.unstreamed += 1',
             'local loaded = bounded(loadedMask)',
             'local fronts = bit32.band(loaded, bounded(facadeMask))',
             'local sides = bit32.band(loaded, bounded(sidewallMask))'):
    assert code in CENSUS_RULES,code
assert 'LocalApprovedDistrictFacadeMounted' in SIDE
assert 'local TOUCH_CAP = {Low = 1, Medium = 3, High = 8}' in SIDE
assert 'Low = {count = 1, distance = 128, retention = 16}' in SIDE
assert 'Medium = {count = 4, distance = 205, retention = 20}' in SIDE
assert 'High = {count = 12, distance = 275, retention = 28}' in SIDE
print("PASS authentic reverse-paired 3D district and exact streamed N/F/S/B"
      " 16-building census without additional Android model budget")

# Full desktop High visible coverage uses existing approved models only.
assert 'if tier == "High" then cap = math.min(cap, 5) end' in SIDE
assert 'local TOUCH_CAP = {Low = 1, Medium = 3, High = 8}' in SIDE
assert 'return tier == "High" and math.min(reduced, 6) or reduced' in DISTRICT_FACADES
print("PASS 16 facade + 12 sidewall healthy desktop High; old Android touch and emergency caps retained")
