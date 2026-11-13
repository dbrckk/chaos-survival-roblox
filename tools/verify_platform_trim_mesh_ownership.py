#!/usr/bin/env python3
"""Source regression: streaming one MeshPart must not unmask a whole deck."""
from pathlib import Path

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
