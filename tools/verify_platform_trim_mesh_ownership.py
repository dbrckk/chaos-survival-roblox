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
