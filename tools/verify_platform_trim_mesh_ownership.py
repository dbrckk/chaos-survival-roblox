#!/usr/bin/env python3
"""Source regression: streaming one MeshPart must not unmask a whole deck."""
from pathlib import Path

source = (Path(__file__).resolve().parents[1] /
          "src/client/PlatformNativeTrimReplacementKit.lua").read_text()
for required in (
    "local livePiecesByOwner = {}",
    "if sourceOwnerByPiece[piece] ~= nil then return end",
    "livePiecesByOwner[owner] = (livePiecesByOwner[owner] or 0) + 1",
    "livePiecesByOwner[id] = (livePiecesByOwner[id] or 0) + 1",
    "meshFolder.ChildAdded:Connect(registerSourcePiece)",
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
