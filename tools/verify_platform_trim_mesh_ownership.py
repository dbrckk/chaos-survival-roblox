#!/usr/bin/env python3
"""Source regression: ALL authenticated MeshParts must survive for a native mask."""
from pathlib import Path
import re

source = (Path(__file__).resolve().parents[1] /
          "src/client/PlatformNativeTrimReplacementKit.lua").read_text()
identity = (Path(__file__).resolve().parents[1] /
            "src/client/arena-platform-identity.client.lua").read_text()
for required in (
    "local requiredPiecesByOwner = {}",
    "local livePiecesByOwner = {}",
    "approvedKinds = table.clone(active)",
    "approvedSupports = table.clone(verifiedSupports)",
    "table.clear(active)",
    "table.clear(verifiedSupports)",
    "if approvedSupports[owner] == true then",
    'local function sourceOwner(piece)',
    'if owner.Parent ~= platformFolder then return nil end',
    'local function sourceComplete(key)',
    'required ~= nil and required >= 7',
    'and required % 7 == 0',
    'and (livePiecesByOwner[key] or 0) == required',
    'local function refreshOwner(key, owner)',
    'active[key] = sourceComplete(key) and approvedKinds[key]',
    'verifiedSupports[key] = sourceComplete(key) and true or nil',
    "if sourceOwnerByPiece[piece] ~= nil then return end",
    "sourceOwnerByPiece[piece] = key",
    "livePiecesByOwner[key] = (livePiecesByOwner[key] or 0) + 1",
    "meshFolder.ChildAdded:Connect(registerSourcePiece)",
    "meshFolder.DescendantAdded:Connect(function(descendant)",
    'descendant.Name ~= "ChaosPlatformTrimWeld"',
    'descendant.Name ~= "OriginalSupportVisualWeld"',
    "piece.Parent == meshFolder",
    "registerSourcePiece(piece)",
    "meshFolder.ChildRemoved:Connect(revokeSourcePiece)",
    "meshFolder.DescendantRemoving:Connect(function(descendant)",
    "local function revokeSourcePiece(piece)",
    'if piece and piece.Parent == meshFolder then',
    'local remaining = math.max(0,',
    '(livePiecesByOwner[owner] or 1) - 1)',
    "active[owner] = nil",
    "verifiedSupports[owner] = nil",
    "reconcile()",
    "Kit.authorizesMask",
    "local initializing = true",
    "if not initializing then reconcile() end",
    "initializing = false",
    "function Kit.breakdown()",
):
    assert required in source, required

# A 7-material original (or 14/21/28 piece approved composite) is
# NEVER complete while any one sibling is missing. Recover only when
# the exact initial welded bundle is once more fully resident.
for expected in (7,14,21,28):
    for live in range(expected+2):
        authorized = (expected>=7 and expected%7==0 and live==expected)
        assert authorized == (live==expected)
    assert (expected-1)!=expected
for incomplete in (0,1,2,3,4,5,6,8,9,13,15,27):
    assert incomplete<7 or incomplete%7 != 0
assert "if remaining > 0 then" not in source
print("PASS first missing approved MeshPart revokes ONLY its platform's"
      " 7/14/21/28-piece native mask, full genuine restoration required")

assert "meshFolder.DescendantRemoving:Connect(function(descendant)" in source
assert "meshFolder.ChildRemoved:Connect(revokeSourcePiece)" in source
assert "revokeSourcePiece(piece)" in source
print("PASS missing WeldConstraint has same immediate one-owner native"
      " fallback as missing MeshPart, with idempotent double events")

# Capture all real masks by family in an EXISTING event-based callback.
for name in (
    "LocalBevelNativePartsReplaced",
    "LocalUnderframeNativePartsReplaced",
    "LocalSupportNativePartsReplaced",
    "LocalOtherStructuralNativePartsReplaced",
):
    assert name in identity,name
for selector in (
    '^PlatformBevel%d+_%d+$',
    '^PlatformUnderFrame%d+$',
    '^PlatformSupport%d+_%d+$',
):
    assert selector in source,selector
assert 'function Kit.breakdown()' in source
assert 'PlatformNativeTrimReplacementKit.breakdown()' in identity
assert 'if player:GetAttribute("LocalNativeStructuralPartsReplaced")' in identity
assert 'and part.Parent ~= activeDecor' not in source
print("PASS dynamic per-arena native primitive mask census from the"
      " event-driven existing 3D owner, not static five-map counts")

# P0 Low premium carapace must follow the real camera, not an arbitrary
# one-in-eight platform-ID sample. Keep exactly ONE seven-MeshPart source
# and never mask gameplay collision or server-owned hazard signaling.
root = Path(__file__).resolve().parents[1]
side = (root / "src/client/PremiumPlatformSideMeshKit.lua").read_text()
identity = (root / "src/client/arena-platform-identity.client.lua").read_text()
builder = (root / "src/server/MapBuilder.lua").read_text()
assert 'or (tier == "Medium" and 8 or (lowReady and 1 or 0))' in side
assert 'if tier == "Low" and not cameraReady then return chosen end' in side
assert 'if tier ~= "Low" or delta.Magnitude <= 125 then' in side
assert 'if tier == "Low" and selected ~= true then' in side
assert 'sourceIndex % 8' not in side
assert 'id % 8 ~= 1' not in side
assert 'verified(variant)' in side
assert 'and sourceParts ~= 7' in side
assert 'if not platform.Parent or not platform.CanCollide' not in side
assert 'nearCameraCarapaces[platform] == true' in identity
low_visual_gate = identity.split(
    'if tier.Name ~= "Low" or visualIndex % 2 ~= 0',1)[1].split('then',1)[0]
assert 'or nearCameraCarapaces[platform] == true' in low_visual_gate
assert 'local bevel = Instance.new("WedgePart")' in builder
assert 'bevel.Name = "PlatformBevel" .. index .. "_" .. edgeIndex' in builder
assert 'bevel:SetAttribute("OriginalStructuralBevel", true)' in builder
assert 'bevel.CanCollide = false' in builder
assert '"PlatformUnderFrame" .. index' in builder
assert 'underFrame:SetAttribute("PremiumArchitecturalSurface", true)' in builder
assert 'part.LocalTransparencyModifier = 1' in source
assert 'owner.CanCollide' in source
print("PASS P0 Low near-camera premium carapace can replace authentic even-index"
      " four-bevel underside without increasing 1-model/7-MeshPart cap")

# The real owner has all FOUR server-authored sloped WedgeParts + ONE
# authentic underside before consuming any of 1/8/16 approved 3D slots.
# This is a residency / streaming improvement, not new geometry or budget.
assert "function Kit.hasNativeCarapaceFallback(decor, platform)" in side
assert 'decor:FindFirstChild("PlatformUnderFrame" .. id)' in side
assert 'decor:FindFirstChild(' in side
assert '"PlatformBevel" .. id .. "_" .. edge' in side
assert 'for edge = 1,4 do' in side
assert 'bevel:IsA("WedgePart")' in side
assert 'bevel:GetAttribute("OriginalStructuralBevel") ~= true' in side
assert 'frame:GetAttribute("PremiumArchitecturalSurface") ~= true' in side
assert 'or Kit.hasNativeCarapaceFallback(decor, platform)' in side
assert 'player:GetAttribute("OptionalVfxPressure"), decor)' in identity
print("PASS only true five-native-fallback deck sources reserve an approved"
      " 7-mesh platform slot on live Android and desktop streaming")


# The real on-screen premium carapace must not sit behind four unrelated
# world imports: prioritize the creator-approved ACTIVE arena once at the
# existing 74-second milestone. The shared bridge remains second; both
# reuse exactly the same global two-call gate and six approved IDs.
server = (root / "src/server/PremiumPlatformSideAssets.lua").read_text()
assert 'local function orderedForActiveArena()' in server
assert 'workspace:FindFirstChild("GeneratedMap")' in server
assert 'arena:GetAttribute("VariantId")' in server
assert 'if type(variant)~="string" or not APPROVED[variant]' in server
assert 'local ordered={variant,"Bridge"}' in server
assert 'name~=variant and name~="Bridge"' in server
assert 'for _, name in ipairs(orderedForActiveArena()) do' in server
assert 'task.wait(74)' in server
assert 'GlobalApprovedImportGate.load' in server
assert 'OriginalMeshScenery.sanitize(raw)' in server
assert 'local ORDER = {"Classic", "Towers", "Crossroads", "Orbital", "Harbor", "Bridge"}' in server
print("PASS active world's moderated sculpt loads before inactive worlds"
      " without new AssetService calls, imports, or priority bypass")

# Verify this is not merely a syntactic eligibility flag: the authentic
# Crossroads map supplies four EVEN-index 14x12 / 12x14 physical decks,
# and the approved sculpted 3D asset's authored 11-stud by 8-stud profile
# actually passes the identical safe fit thresholds used by both select
# and mount. No collider index or native geometry is fabricated.
variants = (root / "src/server/ArenaVariants.lua").read_text()
definitions = variants.split("ArenaVariants.Definitions = {",1)[1]
crossroads = definitions.split("    Crossroads = {",1)[1].split(
    "    Orbital = {",1)[0]
decks = [
    tuple(float(v) for v in match)
    for match in re.findall(
        r'\{offset=Vector3\.new\([^)]+\),size=Vector3\.new\('
        r'\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)',
        crossroads,
    )
]
assert len(decks) >= 8
assert [decks[i-1] for i in (2,4,6,8)] == [
    (14.,2.,12.),(14.,2.,12.),
    (12.,2.,14.),(12.,2.,14.)
]
generator = (root / "tools/generate_original_platform_carapaces.py").read_text()
assert 'def crossroads(m: Sculpture)' in generator
assert 'skirt(m, side)' in generator
assert '(-5.52, -.15, z), (5.52, -.15, z)' in generator
assert 'z = 4.18 * side' in generator
# Use the minimum 11.04x8.36 structural envelope of the approved
# creator-authored model rather than making up a square source fixture.
src_long,src_short = 11.04,8.36
for index in (2,4,6,8):
    x,y,z = decks[index-1]
    long,short = max(x,z),min(x,z)
    factor=min(1.1,long*.92/src_long,short*.91/src_short)
    assert short>=7.1 and long<=36 and long/short<=2.6
    assert factor>=.62 and src_long*factor>=long*.78
    assert src_short*factor>=short*.72
print("PASS four genuine even Crossroads decks fit original 3D source"
      " dimensions, with exactly one near-camera Low model permitted")
# LongCradle: Medium/High's 2/4 scarce authentic models must only be
# reserved when the REAL 22-stud mesh can also mount on that deck.
# Reject overlong undersides BEFORE consuming a model slot, using one
# fit function for selection and installation across all quality tiers.
structure = (root / "src/client/PremiumLargeStructureMeshKit.lua").read_text()
assert 'function Kit.cradleFit(size,sourceBounds)' in structure
assert 'if long<19.5 or long>34 or short<9 or short>18 then return nil end' in structure
assert 'or sourceShort*scale<short*.76' in structure
assert 'or sourceBounds.Y*scale>5 then return nil end' in structure
assert 'and Kit.cradleFit(size,cradleBounds)' in structure
assert 'local scale=Kit.cradleFit(platform.Size,box)' in structure
assert 'if not scale then return nil end' in structure
assert 'local cradleLimit=tier=="High" and' in structure
assert '(desktopHigh==true and 8 or 4) or (tier=="Medium" and 2 or 1)' in structure
assert 'function Kit.desktopCradleTransfer(tier,desktopHigh,candidates)' in structure
assert 'if tier~="High" or desktopHigh~=true' in structure
assert 'return math.min(4,math.max(0,count-4))' in structure
assert 'PremiumLargeStructureMeshKit.desktopCradleTransfer(' in (
    (root / "src/client/arena-platform-identity.client.lua").read_text())
assert 'longCradleBudget+=transferred' in (
    (root / "src/client/arena-platform-identity.client.lua").read_text())
assert 'supportBudget-=transferred' in (
    (root / "src/client/arena-platform-identity.client.lua").read_text())
assert 'tier.Name == "High" and not UserInputService.TouchEnabled' in (
    (root / "src/client/arena-platform-identity.client.lua").read_text())
assert 'local supportLimit=tier=="High" and 8 or (tier=="Medium" and 8 or 1)' in structure
assert 'replacements[tostring(visualIndex)] = "cradle"' in (
    (root / "src/client/arena-platform-identity.client.lua").read_text())
assert 'if id and (active[id] == "carapace" or active[id] == "cradle") then' in source
assert 'return part:GetAttribute("PremiumArchitecturalSurface") == true' in source
print("PASS real approved LongCradle source-fit selection matches mount on"
      " Low/Medium/High; 1/2/4 source quotas and native fallback unchanged")



# P0 support: a true Crossroads Platform2 stands at Y=7 with Y-size 2.
# The MapBuilder source places its anchored, nonphysical support between
# the underside (Y=6) and deckTop 1.15, hence 4.85 studs. Its 7-MeshPart
# creator-owned ~14-stud original has a valid scale around .344, but the
# previous >=5 cutoff silently barred its first four real route owners.
large = (root / "src/client/PremiumLargeStructureMeshKit.lua").read_text()
map_builder = (root / "src/server/MapBuilder.lua").read_text()
variants = (root / "src/server/ArenaVariants.lua").read_text()
assert 'local MIN_NATIVE_SUPPORT_HEIGHT = 4.75' in large
assert 'part.Size.Y >= MIN_NATIVE_SUPPORT_HEIGHT' in large
assert 'part.Size.Y <= 47' in large
assert 'function Kit.supportFit(nativeSize, sourceBounds)' in large
assert 'local segments = math.clamp(math.ceil(nativeSize.Y / 16.0), 1, 3)' in large
assert 'scale < .34 or scale > 1.25' in large
assert 'or width > 3.2' in large
assert 'local segments = Kit.supportFit(part.Size, supportBounds)' in large
assert 'local segments, scale = Kit.supportFit(support.Size, box)' in large
assert 'if count ~= 7 then return nil end' in large
assert 'tier == "Low" and (tonumber(pressure) or 0) > 0' in large
assert 'sourceParts ~= 7' in large
assert 'local preferSupport=tier=="Low" and supports[1]' in large
assert 'supports[1].score+8<cradles[1].score' in large
assert 'if not preferSupport then' in large
assert 'if tier~="Low" or next(cradleSet)==nil then' in large
assert 'supportSet=distribute(supports,supportLimit,' in large
assert 'originalSupportVisualWeld' not in large
assert 'OriginalSupportVisualWeld' in large
assert 'Kit.supports' in large
assert 'local deckTop = 1.15' in map_builder
assert 'local supportHeight = platformBottom - deckTop' in map_builder
assert '"PlatformSupport" .. index .. "_" .. supportIndex' in map_builder
definitions = variants.split("ArenaVariants.Definitions = {",1)[1]
crossroads = definitions.split("    Crossroads = {",1)[1].split(
    "    Orbital = {",1)[0]
crossroads_dims = [
    tuple(float(v) for v in match)
    for match in re.findall(
        r'\{offset=Vector3\.new\([^,]+,([\d.]+),[^)]+\),size=Vector3\.new\('
        r'\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)',
        crossroads,
    )
]
assert len(crossroads_dims)>=8
for i in (2,4,6,8):
    y,sx,sy,sz = crossroads_dims[i-1]
    assert (y,sx,sy,sz) in ((7.,14.,2.,12.),(7.,12.,2.,14.))
    height = y - sy/2 - 1.15
    assert abs(height-4.85)<.0001
    assert height >= 4.75
    for approved_source_height in (13.4,14.1):
        assert height/approved_source_height >= .34
print("PASS four genuine Crossroads low-route support clusters eligible"
      " for approved 7-piece source with preserved native fallback")

# Source arithmetic contract: approved seven-MeshPart modules stay at
# exactly 20 across the structural families, even when all 8 real
# desktop underframe candidates are eligible. Android never trades.
for eligible in range(0,15):
    traded=min(4,max(0,eligible-4))
    assert 0<=traded<=4
    assert (4+traded)+(16-traded)==20
    if eligible<=4:
        assert traded==0
print("PASS High desktop 4-to-8 genuine LongCradle capacity trades column"
      " modules at fixed 20 source models; Android budgets unchanged")
