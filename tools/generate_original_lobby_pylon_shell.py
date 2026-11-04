#!/usr/bin/env python3
"""Creator-authored, collision-covering sculpted lobby column.

Unlike the earlier narrow 14-stud supports, this entire 10-stud core
encases the EXISTING 2.2 x 10 x 2.2 Roblox collider. A high-detail forged
shell is triangulated, UV-ready, and assembled into seven real materials.
The native collider, decorative cap light, spawn and gameplay stay untouched.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NAME = "lobby_pylon_shell"
# Authoritative Roblox Pylon size (MapBuilder.buildLobby).
COLLIDER_WIDTH = 2.2
COLLIDER_HEIGHT = 10.0
# The closed chamfered core alone must fully occupy the collider volume.
# For an octagonal extruded square, each corner satisfies |x|+|z|
# <= (width - bevel), so an internal square with corners at 1.1 needs
# 2*1.1 <= (width - bevel). We leave substantial geometric margin.
CORE_WIDTH = 2.84
CORE_HEIGHT = 10.36
BEVEL = 0.16


def build() -> Sculpture:
    art = Sculpture()
    art.lines[0] = "# Original creator-owned collision-covering Chaos lobby column"
    art.lines[2] = "o ChaosOriginalLobbyPylonShell"
    # FULLY CLOSED central surface extends 0.18 studs beyond the native
    # collider vertically, 0.32+ horizontally, even at its beveled corners.
    art.beveled_block("ClosedCollisionEnclosingCore", "ARMOR",
                      0, 0, 0, CORE_WIDTH, CORE_HEIGHT, CORE_WIDTH, BEVEL)

    for side in (-1, 1):
        # External forged, sculpted protective ribs, behind the true cap.
        art.beveled_block("ForgedLoadSideRail%d" % side, "BRUSHED",
                          side*1.38, 0, 0, .33, 9.55, 1.02, .12)
        art.beveled_block("SideBrakeChannel%d" % side, "CARBON",
                          side*1.58, -.18, -.34, .075, 6.75, .48, .018)
        art.rod("DiagonalMachinedStay%d" % side, "ALLOY",
                (side*1.52, -3.92, -.81),
                (side*1.52, 3.82, .81), .085, 8)
        for level in range(4):
            y = -3.35 + level * 2.22
            art.beveled_block("WeldedSideShoe%d_%d" % (side, level),
                              "ALLOY", side*1.56, y, .48,
                              .24, .42, .78, .075)

    # Ground-to-roof transition has a visible metal collar, not a stack of
    # Roblox Parts. Preserve the existing purple top cap/light above.
    art.beveled_block("CastLowerFoot", "GRIP",
                      0, -4.88, 0, 3.55, .58, 3.52, .35)
    art.beveled_block("UpperMilledShoulder", "BRUSHED",
                      0, 4.83, 0, 3.39, .56, 3.36, .29)
    art.beveled_block("UpperSeismicIsolator", "GRIP",
                      0, 4.34, 0, 3.02, .23, 3.02, .13)

    # Distinct industrial identity / ceramic insulating inset at a
    # human-readable forward-facing height. Continuous opaque core below.
    art.beveled_block("FrontDielectricMainCassette", "CERAMIC",
                      0, .25, -1.46, 2.26, 5.80, .21, .17)
    art.beveled_block("FrontCarbonInspectionRecess", "CARBON",
                      0, .05, -1.584, 1.65, 2.65, .09, .06)
    art.beveled_block("InsetSafetySignal", "SIGNAL",
                      0, 2.46, -1.60, 1.46, .19, .095, .055)
    art.beveled_block("InsetMaintenanceLabel", "ALLOY",
                      0, -2.50, -1.59, 1.37, .15, .09, .06)

    # A second silhouette is visible when entering from either side of
    # the central lobby; all ornaments remain outside the sealed core.
    for level in range(5):
        y = -3.72 + level * 1.72
        art.beveled_block("RearServiceCassette%02d" % level, "CARBON",
                          0, y, 1.46, 1.78, .44, .19, .09)
        art.beveled_block("RearMaintenanceTag%02d" % level, "CERAMIC",
                          0, y, 1.577, 1.10, .10, .055, .032)
    return art


def export(output: Path) -> dict:
    # A numerical proof of positive coverage—not merely matching total
    # bounding boxes. Preserve this assertion if the artwork changes.
    assert CORE_WIDTH - BEVEL > COLLIDER_WIDTH + .25
    assert CORE_HEIGHT > COLLIDER_HEIGHT + .30
    art = build()
    assert set(MATERIALS) == art.materials
    assert 25 <= art.groups <= 96, art.groups
    assert 500 <= art.triangles <= 4200, art.triangles
    size = [round(art.maximum[i] - art.minimum[i], 5) for i in range(3)]
    assert 3.45 <= size[0] <= 4.05, size
    assert 10.25 <= size[1] <= 10.75, size
    assert 3.40 <= size[2] <= 4.05, size
    output.parent.mkdir(parents=True, exist_ok=True)
    content = "\n".join(art.lines) + "\n"
    output.write_text(content, encoding="utf-8")
    return {
        "asset": NAME,
        "groups": art.groups,
        "triangles": art.triangles,
        "vertices": art.vertices,
        "materials": sorted(art.materials),
        "dimensions": size,
        "closed_core": {
            "width": CORE_WIDTH,
            "height": CORE_HEIGHT,
            "bevel": BEVEL,
            "collider_width": COLLIDER_WIDTH,
            "collider_height": COLLIDER_HEIGHT,
            "minimum_corner_margin": round(
                (CORE_WIDTH - BEVEL - COLLIDER_WIDTH) / 2, 4),
        },
        "sha256": hashlib.sha256(content.encode()).hexdigest(),
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(export(args.output), sort_keys=True))
