#!/usr/bin/env python3
"""Source contract for real nearfield approved 2K surface finishes.

No simulated Android GPU timing, visuals or fake asset upload.
"""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
KIT = (ROOT/"src/client/PremiumNearfieldPbrKit.lua").read_text()
LOD = (ROOT/"src/client/scenery-lod.client.lua").read_text()
ENGINE = (ROOT/"tests/engine/arena-material-rules.spec.luau").read_text()
CLOUD = (ROOT/".github/workflows/roblox-cloud-test.yml").read_text()
PROJECT = json.loads((ROOT/"default.project.json").read_text())
REGISTRY = json.loads((ROOT/"assets/source/roblox-asset-registry.json").read_text())
ids = {int(model["asset_id"]) for model in REGISTRY["models"]
       if model["moderation"] == "Approved"}
BUCKETS = {
    "Classic": [("ApprovedPerimeterStationDeckInlaysLocal",72507987666671,
                   "ApprovedPerimeterStationDeckInlayMeshKit.lua"),
("ApprovedPerimeterVariantApexLocal",110237986522853,
                   "ApprovedPerimeterVariantApexMeshKit.lua"),
                ("ApprovedPerimeterArmorLocal",88962643359267,
                   "ApprovedPerimeterArmorMeshKit.lua"),
                ("ApprovedPerimeterArmorLocal",138096293972093,
                   "ApprovedPerimeterArmorMeshKit.lua"),
                ("ApprovedPerimeterStructuresLocal",108452611210970,
                   "ApprovedPerimeterStructuresMeshKit.lua"),
                ("ApprovedPerimeterStructuresLocal",113687802206554,
                   "ApprovedPerimeterStructuresMeshKit.lua"),
                ("ApprovedPerimeterRotorsLocal",133526819668194,
                   "ApprovedPerimeterRotorMeshKit.lua"),
                ("ApprovedPerimeterMachineryLocal",127295681925871,
                   "ApprovedPerimeterMachineryMeshKit.lua"),
                ("ApprovedPerimeterMachineryLocal",106083832432833,
                   "ApprovedPerimeterMachineryMeshKit.lua"),
                ("ApprovedPerimeterButtressesLocal",91626128452597,
                   "ApprovedPerimeterButtressMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",123836720232695,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",83853948389204,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",108491064314671,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",83023096720529,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",137744886537150,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",74958476744494,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",97864559770371,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",112172520488996,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedAtmosphereColumnsLocal",91626128452597,
                 "ApprovedAtmosphereColumnsMeshKit.lua"),
                ("ApprovedClassicBroadcastFinLocal",123049626693705,
                 "ApprovedClassicBroadcastFinMeshKit.lua"),
                ("ApprovedOriginalIdentitySpinesLocal",105555650820011,
                 "ApprovedVariantIdentitySpineMeshKit.lua")],
    "Towers": [("ApprovedPerimeterStationDeckInlaysLocal",72507987666671,
                   "ApprovedPerimeterStationDeckInlayMeshKit.lua"),
("ApprovedPerimeterVariantApexLocal",131413152501235,
                   "ApprovedPerimeterVariantApexMeshKit.lua"),
                ("ApprovedPerimeterArmorLocal",88962643359267,
                   "ApprovedPerimeterArmorMeshKit.lua"),
                ("ApprovedPerimeterArmorLocal",138096293972093,
                   "ApprovedPerimeterArmorMeshKit.lua"),
                ("ApprovedPerimeterStructuresLocal",108452611210970,
                   "ApprovedPerimeterStructuresMeshKit.lua"),
                ("ApprovedPerimeterStructuresLocal",113687802206554,
                   "ApprovedPerimeterStructuresMeshKit.lua"),
                ("ApprovedPerimeterRotorsLocal",133526819668194,
                   "ApprovedPerimeterRotorMeshKit.lua"),
                ("ApprovedPerimeterMachineryLocal",127295681925871,
                   "ApprovedPerimeterMachineryMeshKit.lua"),
                ("ApprovedPerimeterMachineryLocal",106083832432833,
                   "ApprovedPerimeterMachineryMeshKit.lua"),
                ("ApprovedPerimeterButtressesLocal",107521411452905,
                   "ApprovedPerimeterButtressMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",123836720232695,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",83853948389204,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",108491064314671,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",83023096720529,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedAtmosphereCrownLocal",125070862497818,
                   "ApprovedAtmosphereCrownMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",137744886537150,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",74958476744494,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",97864559770371,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",112172520488996,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedAtmosphereColumnsLocal",107521411452905,
                "ApprovedAtmosphereColumnsMeshKit.lua"),
               ("ApprovedTowersMachineryLocal",72143366927826,
                "ApprovedVariantTowersLandmarkMeshKit.lua"),
               ("ApprovedOriginalIdentitySpinesLocal",86423178125318,
                "ApprovedVariantIdentitySpineMeshKit.lua")],
    "Crossroads": [("ApprovedPerimeterStationDeckInlaysLocal",72507987666671,
                   "ApprovedPerimeterStationDeckInlayMeshKit.lua"),
("ApprovedPerimeterVariantApexLocal",134533469777794,
                   "ApprovedPerimeterVariantApexMeshKit.lua"),
                ("ApprovedPerimeterArmorLocal",88962643359267,
                   "ApprovedPerimeterArmorMeshKit.lua"),
                ("ApprovedPerimeterArmorLocal",138096293972093,
                   "ApprovedPerimeterArmorMeshKit.lua"),
                ("ApprovedPerimeterStructuresLocal",108452611210970,
                   "ApprovedPerimeterStructuresMeshKit.lua"),
                ("ApprovedPerimeterStructuresLocal",113687802206554,
                   "ApprovedPerimeterStructuresMeshKit.lua"),
                ("ApprovedPerimeterRotorsLocal",133526819668194,
                   "ApprovedPerimeterRotorMeshKit.lua"),
                ("ApprovedPerimeterMachineryLocal",127295681925871,
                   "ApprovedPerimeterMachineryMeshKit.lua"),
                ("ApprovedPerimeterMachineryLocal",106083832432833,
                   "ApprovedPerimeterMachineryMeshKit.lua"),
                ("ApprovedPerimeterButtressesLocal",93993697329658,
                   "ApprovedPerimeterButtressMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",123836720232695,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",83853948389204,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",108491064314671,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",83023096720529,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",137744886537150,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",74958476744494,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",97864559770371,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",112172520488996,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedAtmosphereColumnsLocal",93993697329658,
                   "ApprovedAtmosphereColumnsMeshKit.lua"),
                  ("ApprovedCrossroadsEntrancePortalsLocal",127067628128103,
                   "ApprovedCrossroadsEntrancePortalMeshKit.lua"),
                   ("ApprovedCrossroadsOpenGantryLocal",90844491148907,
                    "ApprovedCrossroadsOpenGantryMeshKit.lua")],
    "Orbital": [("ApprovedPerimeterStationDeckInlaysLocal",72507987666671,
                   "ApprovedPerimeterStationDeckInlayMeshKit.lua"),
("ApprovedPerimeterVariantApexLocal",131188899020391,
                   "ApprovedPerimeterVariantApexMeshKit.lua"),
                ("ApprovedPerimeterArmorLocal",88962643359267,
                   "ApprovedPerimeterArmorMeshKit.lua"),
                ("ApprovedPerimeterArmorLocal",138096293972093,
                   "ApprovedPerimeterArmorMeshKit.lua"),
                ("ApprovedPerimeterStructuresLocal",108452611210970,
                   "ApprovedPerimeterStructuresMeshKit.lua"),
                ("ApprovedPerimeterStructuresLocal",113687802206554,
                   "ApprovedPerimeterStructuresMeshKit.lua"),
                ("ApprovedPerimeterRotorsLocal",133526819668194,
                   "ApprovedPerimeterRotorMeshKit.lua"),
                ("ApprovedPerimeterMachineryLocal",127295681925871,
                   "ApprovedPerimeterMachineryMeshKit.lua"),
                ("ApprovedPerimeterMachineryLocal",106083832432833,
                   "ApprovedPerimeterMachineryMeshKit.lua"),
                ("ApprovedPerimeterButtressesLocal",119010829781313,
                   "ApprovedPerimeterButtressMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",123836720232695,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",83853948389204,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",108491064314671,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",83023096720529,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",137744886537150,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",74958476744494,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",97864559770371,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",112172520488996,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedAtmosphereColumnsLocal",119010829781313,
                "ApprovedAtmosphereColumnsMeshKit.lua"),
               ("ApprovedOrbitalReactorLandmarksLocal",104654294187035,
                 "ApprovedOrbitalReactorLandmarkMeshKit.lua"),
                ("ApprovedOrbitalReactorLandmarksLocal",138666009076890,
                 "ApprovedOrbitalReactorLandmarkMeshKit.lua")],
    "Harbor": [("ApprovedPerimeterStationDeckInlaysLocal",72507987666671,
                   "ApprovedPerimeterStationDeckInlayMeshKit.lua"),
("ApprovedPerimeterVariantApexLocal",110237986522853,
                   "ApprovedPerimeterVariantApexMeshKit.lua"),
                ("ApprovedPerimeterArmorLocal",88962643359267,
                   "ApprovedPerimeterArmorMeshKit.lua"),
                ("ApprovedPerimeterArmorLocal",138096293972093,
                   "ApprovedPerimeterArmorMeshKit.lua"),
                ("ApprovedPerimeterStructuresLocal",108452611210970,
                   "ApprovedPerimeterStructuresMeshKit.lua"),
                ("ApprovedPerimeterStructuresLocal",113687802206554,
                   "ApprovedPerimeterStructuresMeshKit.lua"),
                ("ApprovedPerimeterRotorsLocal",133526819668194,
                   "ApprovedPerimeterRotorMeshKit.lua"),
                ("ApprovedPerimeterMachineryLocal",127295681925871,
                   "ApprovedPerimeterMachineryMeshKit.lua"),
                ("ApprovedPerimeterMachineryLocal",106083832432833,
                   "ApprovedPerimeterMachineryMeshKit.lua"),
                ("ApprovedPerimeterButtressesLocal",76194593490199,
                   "ApprovedPerimeterButtressMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",123836720232695,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",83853948389204,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",108491064314671,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorRidgesLocal",83023096720529,
                   "ApprovedExteriorRidgeMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",137744886537150,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",74958476744494,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",97864559770371,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedExteriorTowerMeshesLocal",112172520488996,
                   "ApprovedExteriorTowerMeshKit.lua"),
                ("ApprovedAtmosphereColumnsLocal",76194593490199,
                "ApprovedAtmosphereColumnsMeshKit.lua")],
}
for variant, pairs in BUCKETS.items():
    assert f"{variant} = {{" in KIT
    for folder,asset_id,owner in pairs:
        assert asset_id in ids,(variant, asset_id)
        assert f'folder = "{folder}", id = {asset_id}' in KIT,(variant, folder,asset_id)
        src = (ROOT/"src/client"/owner).read_text()
        assert f'"{folder}"' in src, (folder,owner)
        assert f'{asset_id}' in src,(asset_id,owner)
        assert 'Original3DAssetId' in src and '"CosmeticOnly"' in src
        print("PASS approved owner",variant,folder,asset_id)

# The approved floor tile is reused as a 3D station inlay, so only its
# existing seven MeshParts may enter the ALREADY capped nearfield PBR
# system. Do not PBR-coat the six native warning/identity parts.
INLAY=(ROOT/"src/client/ApprovedPerimeterStationDeckInlayMeshKit.lua").read_text()
MAP=(ROOT/"src/server/MapBuilder.lua").read_text()
assert 'local SOURCE_ID = 72507987666671' in INLAY
assert 'bucket.Name = "ApprovedPerimeterStationDeckInlaysLocal"' in INLAY
assert 'bucket:SetAttribute("CosmeticOnly",true)' in INLAY
assert 'clone:SetAttribute("Original3DAssetId",SOURCE_ID)' in INLAY
assert 'clone:SetAttribute("CosmeticOnly",true)' in INLAY
assert 'model:GetAttribute("OwnerVerified")~=true' in INLAY
assert 'if count~=7 then return nil end' in INLAY
assert 'part.CanCollide=false' in INLAY
assert 'part.CanTouch=false' in INLAY
assert 'part.CanQuery=false' in INLAY
assert 'part.CastShadow=false' in INLAY
assert 'clone.Parent=bucket' in INLAY
assert 'native.Transparency=1' in INLAY
assert 'state.native.Transparency = state.alpha' in INLAY
assert 'clone.DescendantRemoving:Connect(' in INLAY
assert 'ApprovedPerimeterStationDeckInlayMeshKit.sync(arena, cameraPoint,' in LOD
assert 'PremiumNearfieldPbrKit.reconcile(' in LOD
assert LOD.index('ApprovedPerimeterStationDeckInlayMeshKit.sync(') < LOD.index(
    'PremiumNearfieldPbrKit.reconcile(')
for marker in ("LeftLightNotch","RightLightNotch","CoreLens",
               "WayfindingInset","PodDataRailL","PodDataRailR"):
    assert marker in MAP
    assert f'FindFirstChild("{marker}")' not in KIT
assert KIT.count('id = 72507987666671') == 5
assert KIT.count('folder = "ApprovedPerimeterStationDeckInlaysLocal"') == 5
assert KIT.count('task.wait(') == 0
assert 'Kit.budget(tier, pressure, touch, disabled)' in KIT
assert 'if disabled == true or tier == "Low" then return 0 end' in KIT
assert '"SIGNAL", "CARBON", "GRIP", "GLASS"' in KIT
print("PASS authentic deck-inlay UV meshes reuse the original capped 2K nearfield PBR")

pbr = PROJECT["tree"]["ReplicatedStorage"]["OriginalGroundPbrTemplates"]
needed = ("BrushedTitanium","OxidizedSteel","DiamondArmor","ReactorCeramic")
unique_images=set()
for name in needed:
    p = pbr[name]
    assert p["$className"]=="SurfaceAppearance"
    for field in ("ColorMap","NormalMap","RoughnessMap","MetalnessMap"):
        val=p["$properties"][field]
        assert re.fullmatch(r"rbxassetid://[0-9]+",val)
        unique_images.add(val)
assert len(unique_images)==16,("Expected same 16 approved images",len(unique_images))
assert 'OriginalGroundPbrTemplates' in KIT
assert 'PremiumNearfieldPbrKit.reconcile(' in LOD
assert 'require(script.Parent.PremiumNearfieldPbrKit)' in LOD
assert 'player:GetAttribute("PbrMaterialsDisabled")' in LOD
assert 'player:GetAttribute("OptionalVfxPressure")' in LOD
assert 'LocalPremiumNearfieldPbrModelCount' in LOD
assert 'LocalPremiumNearfieldPbrSurfaceCount' in LOD
assert 'ApprovedExteriorRidgesLocal' in KIT
assert 'Low=1,Medium=2,High=4' in (ROOT/'src/client/ApprovedExteriorRidgeMeshKit.lua').read_text()
assert 'ApprovedExteriorTowerMeshesLocal' in KIT
assert 'Low=1,Medium=2,High=4' in (ROOT/'src/client/ApprovedExteriorTowerMeshKit.lua').read_text()
assert KIT.count('task.wait(')==0
assert 'RenderStepped' not in KIT and 'Heartbeat' not in KIT
assert 'LoadAssetAsync' not in KIT and 'HttpService' not in KIT
assert 'Instance.new(' not in KIT
# Source model pivots may remain at export coordinates after seven
# MeshParts have been positioned individually at actual stations.
assert 'local position = model:GetBoundingBox()' in KIT
assert 'local distance = (position.Position - cameraPoint).Magnitude' in KIT
assert 'model:GetPivot().Position' not in KIT
assert 'if #pieces ~= 7 then return nil end' in KIT
assert 'model:GetAttribute("Original3DAssetId") ~= id' in KIT
assert 'model:GetAttribute("CosmeticOnly") ~= true' in KIT
assert 'folder:GetAttribute("CosmeticOnly") == true' in KIT
assert 'model.Parent ~= folder' in KIT
assert 'if not scanned[model] then' in KIT
assert KIT.index('scanned[model] = true')>KIT.index('if pieces then')
assert 'local success = pcall(function()' in KIT
assert 'if not success then' in KIT and 'release(model)' in KIT
assert 'states[model] = nil' in KIT
assert 'if not selected[model] then release(model) end' in KIT
assert 'part:FindFirstChildOfClass("SurfaceAppearance")' in KIT
assert 'original.Parent = nil' in KIT and 'appearance.Parent = part' in KIT
assert 'OriginalNearfieldPbr2K' in KIT
assert '"SIGNAL", "CARBON", "GRIP", "GLASS"' in KIT
assert 'if disabled == true or tier == "Low" then return 0 end' in KIT
assert 'if level >= 2 then return 0 end' in KIT
assert 'return touch == true and 4 or 6' in KIT
assert '"tests/engine/arena-material-rules.spec.luau"' in CLOUD
assert 'Authentic P4 nearfield 2K sculpture finishes' in ENGINE
assert 'PremiumNearfieldPbrKit.finishFor' in ENGINE
assert 'PremiumNearfieldPbrKit.budget' in ENGINE
print("PASS 16 previously moderated image IDs reused, no new imports or renderer")
print("PASS bounded PBR originals, hazard signals and release-on-pressure")
print("LIMIT no studio/Android pixels or FPS were measured in source CI")
