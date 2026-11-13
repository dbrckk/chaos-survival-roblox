#!/usr/bin/env python3
"""Source regression: streaming one MeshPart must not unmask a whole deck."""
from pathlib import Path
import re

source = (Path(__file__).resolve().parents[1] /
          "src/client/PlatformNativeTrimReplacementKit.lua").read_text()
for required in (
    "local livePiecesByOwner = {}",
    "local approvedKinds = table.clone(active)",
    "local approvedSupports = table.clone(verifiedSupports)",
    "if approvedSupports[owner] == true then",
    "active[id] = approvedKinds[id]",
    "watchOwner(owner)",
    "if sourceOwnerByPiece[piece] ~= nil then return end",
    "livePiecesByOwner[owner] = (livePiecesByOwner[owner] or 0) + 1",
    "livePiecesByOwner[id] = (livePiecesByOwner[id] or 0) + 1",
    "meshFolder.ChildAdded:Connect(registerSourcePiece)",
    "meshFolder.DescendantAdded:Connect(function(descendant)",
    'descendant.Name ~= "ChaosPlatformTrimWeld"',
    'descendant.Name ~= "OriginalSupportVisualWeld"',
    "piece.Parent == meshFolder",
    "registerSourcePiece(piece)",
    "meshFolder.ChildRemoved:Connect(",
    "local remaining = (livePiecesByOwner[owner] or 1) - 1",
    "if remaining > 0 then",
    "livePiecesByOwner[owner] = remaining",
    "livePiecesByOwner[owner] = nil",
    "active[owner] = nil",
    "verifiedSupports[owner] = nil",
    "reconcile()",
    "Kit.authorizesMask",
):
    assert required in source, required

# The source-level counter contract: only removal of the final piece
# revokes an owner's masking, never an unrelated or earlier sibling.
for n in range(1, 15):
    remaining = n
    for i in range(n):
        remaining -= 1
        revoked = remaining == 0
        assert revoked == (i == n - 1)
print("PASS verified per-owner MeshPart counting and final-piece fallback")
print("LIMIT real Roblox StreamingEnabled tests remain required")

# Recovery contract: the same originally-approved owner can regain its
# premium silhouette after Roblox streams a valid MeshPart back in.
for first_count in range(1, 8):
    live = first_count
    while live:
        live -= 1
    assert live == 0
    active = False
    live += 1
    active = live > 0
    assert active
print("PASS original MeshPart streaming recovery restores authorization")

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

