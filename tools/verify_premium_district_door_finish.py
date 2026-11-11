#!/usr/bin/env python3
"""P4 five-arena in-world door microdetail and streamed-door recovery.

Checks actual creator-owned Material/SurfaceGui path without treating
source QA as a visual screenshot or claim of new approved Roblox maps.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KIT = (ROOT / "src/client/DistrictMaterialFinishKit.lua").read_text()
CLIENT = (ROOT / "src/client/district-architecture-materials.client.lua").read_text()
BUILDER = (ROOT / "src/server/ArenaDistrictArchitecture.lua").read_text()
ENGINE = (ROOT / "tests/engine/arena-material-rules.spec.luau").read_text()
CLOUD = (ROOT / ".github/workflows/roblox-cloud-test.yml").read_text()
PBR = (ROOT / "src/shared/PbrDistrictRules.lua").read_text()

profiles = {
    "Classic": ("SURVEY / GRID", "SurveyGauge"),
    "Towers": ("LIFT / LOAD", "HoistReinforcement"),
    "Crossroads": ("ROUTE / XFER", "ExchangeRoute"),
    "Orbital": ("REACTOR / SEAL", "ContainmentCollar"),
    "Harbor": ("QUAY / HATCH", "QuayHatchRib"),
}
for variant, (label, element) in profiles.items():
    assert f"{variant} = {{" in KIT,variant
    assert f'label = "{label}"' in KIT,variant
    assert f'"{element}"' in KIT,variant
    assert f'"{variant}"' in ENGINE,variant
    assert f'"{label}"' in ENGINE,variant

assert "local identity = DOOR_FINISH[variant] or DOOR_FINISH.Classic" in KIT
assert "function DistrictMaterialFinishKit.stencil(surface, serial, accent, tier, style, face, variant)" in KIT
for node in (
    'ForgedDoorRecess', 'ForgedDirectionalGrain', 'UpperMachinedLip',
    'LowerMachinedLip', 'CentralManufacturingSeam',
    'ForgedFastener', 'DistrictTechnicalBand', 'IndustrialFamilyMark'
):
    assert node in KIT,node
assert 'surface:IsA("BasePart")' in KIT
assert 'or tier == "Low"' in KIT
assert 'gui.MaxDistance = tier == "High" and 145 or 115' in KIT
assert 'gui.PixelsPerStud = tier == "High" and 24 or 16' in KIT
assert 'gui.AlwaysOnTop = false' in KIT
assert 'gui.LightInfluence = 0.70' in KIT
assert 'return gui' in KIT
assert 'Instance.new("SurfaceGui")' in KIT
assert 'Instance.new("Frame")' in KIT
assert 'Instance.new("UIGradient")' in KIT
assert 'Instance.new("UICorner")' in KIT
assert 'Instance.new("UIStroke")' in KIT
for forbidden in (
    'Instance.new("Part")', 'Instance.new("MeshPart")',
    'Instance.new("ImageLabel")', 'LoadAssetAsync', 'AssetService',
    'RenderStepped', 'Heartbeat', 'RemoteEvent', 'HttpService',
):
    assert forbidden not in KIT, forbidden

# Only the existing 16 canonical ServiceEntryDoor native cosmetic Parts,
# with unchanged collision, approved PBR and creator provenance.
assert '"ServiceEntryDoor"' in BUILDER
assert 'Vector3.new(4.65, 4.68, 0.18)' in BUILDER
assert 'part.Name ~= "ServiceEntryDoor"' in PBR or '"ServiceEntryDoor"' in PBR
assert 'local plate = model:FindFirstChild("ServiceEntryDoor")' in CLIENT
assert 'if tier == "Low" then return end' in CLIENT
assert 'if tier == "Medium" and index % 2 ~= 0 then return end' in CLIENT
assert 'or details[plate] then' in CLIENT
assert 'accent, tier, "service-door", Enum.NormalId.Front, variant' in CLIENT
assert 'plate.LocalTransparencyModifier < 0.95' in CLIENT
assert 'GetPropertyChangedSignal(' in CLIENT
assert 'local lateDoorConnection = nil' in CLIENT
assert 'local removedDoorConnection = nil' in CLIENT
assert 'lateDoorConnection = folder.DescendantAdded:Connect(' in CLIENT
assert 'removedDoorConnection = folder.DescendantRemoving:Connect(' in CLIENT
assert 'if part.Name ~= "ServiceEntryDoor"' in CLIENT
assert 'and part.Parent == model then' in CLIENT
assert 'if watchedFolder == folder and model' in CLIENT
assert 'details[part] = nil' in CLIENT
assert CLIENT.count('lateDoorConnection:Disconnect()') == 1
assert CLIENT.count('removedDoorConnection:Disconnect()') == 1
assert 'folder.ChildRemoved:Connect(retire)' in CLIENT
assert 'workspace.DescendantRemoving:Connect(' in CLIENT

# Engine test belongs to an existing manually dispatched shard; no
# new license, asset upload, or fake runtime screenshot is implied.
assert '"tests/engine/arena-material-rules.spec.luau"' in CLOUD
assert 'Five authored PBR-safe near-field industrial service door finishes' in ENGINE
assert 'expect(door.Material).toBe(beforeMaterial)' in ENGINE
assert 'expect(#gui:GetDescendants() <= 55).toBe(true)' in ENGINE
assert 'expect(medium.PixelsPerStud).toBe(16)' in ENGINE
print("PASS five separate detailed metal/cargo/ceramic industrial door finishes")
print("PASS streaming-late doors recover stencil and connections are cleaned")
print("PASS Low off; Medium half facades, high all; no extra 3D/Roblox assets")
print("LIMIT Studio screenshots and Android FPS still need release QA")
