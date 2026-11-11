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
