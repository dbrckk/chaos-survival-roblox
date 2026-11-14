#!/usr/bin/env python3
"""Original short Sky Spine undercarriage: genuine open seven-material 3D.

Source only until its Roblox Model is uploaded, moderated, and registered.
Fits the SHORT ~18-stud Sky Spine decks; it never creates a physical path.
The existing 22-stud LongCradle remains the better fit for longer decks.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture


def build(art: Sculpture) -> None:
    """Detailed 17 x 10-stud open truss, entirely BELOW the real walkway."""
    for side in (-1, 1):
        tag = "Port" if side < 0 else "Starboard"
        x = side * 4.53
        art.beveled_block(tag + "CastArmoredLongeron", "ARMOR",
                          x, -.35, 0, .72, .53, 16.52, .17)
        art.beveled_block(tag + "MachinedSatinShoulder", "BRUSHED",
                          side * 4.91, -.36, 0, .17, .20, 15.85, .045)
        art.beveled_block(tag + "RecessedCarbonRace", "CARBON",
                          side * 4.63, -.76, 0, .31, .14, 14.96, .058)
        art.beveled_block(tag + "ElastomerCableSeat", "GRIP",
                          side * 4.21, -.68, 0, .23, .16, 16.12, .055)
        for k in range(7):
            z = -6.96 + k * 2.32
            art.beveled_block(tag + "CeramicShockShield" + str(k),
                              "CERAMIC", side * 4.94, -.57, z,
                              .21, .32, .70, .045)
            art.rod(tag + "DiagonalLoadWeb" + str(k), "ALLOY",
                    (side * 4.28, -.45, z-.83),
                    (side * 2.70, -1.94, z+.82),
                    .105, 8)
            art.beveled_block(tag + "WearPin" + str(k),
                              "BRUSHED", side * 4.96, -.33, z,
                              .12, .15, .22, .033)
        for k in range(3):
            z = -4.74 + k * 4.74
            art.beveled_block(tag + "EmbeddedRouteTelemetry" + str(k),
                              "SIGNAL", side * 5.02, -.37, z,
                              .09, .095, .93, .023)

    for k in range(8):
        z = -7.35 + k * 2.10
        art.beveled_block("OpenForgedCrossMember" + str(k),
                          "BRUSHED", 0, -1.38, z, 8.82, .35, .34, .13)
        art.beveled_block("FloatingVibrationDamper" + str(k),
                          "GRIP", 0, -1.73, z, 1.06, .27, .57, .11)
        art.rod("TriangulatedCompressionBrace" + str(k), "ALLOY",
                (-3.52, -.49, z-.72), (3.50, -1.88, z+.67),
                .081, 8)

    for side in (-1, 1):
        art.beveled_block("LowerLoadSpine" + str(side), "ALLOY",
                          side * 1.21, -2.10, 0,
                          .47, .32, 15.77, .12)
        art.beveled_block("LongitudinalCarbonVent" + str(side), "CARBON",
                          side * 1.73, -1.94, 0,
                          .21, .16, 14.55, .07)
        for k in (-1, 0, 1):
            art.beveled_block("UnderseatCeramicBuffer%d_%d" % (side, k),
                              "CERAMIC", side * 1.23, -2.34,
                              k * 5.05, .80, .17, .59, .065)

    art.beveled_block("HollowServiceInspectionPod", "ARMOR",
                      0, -1.90, 0, 2.58, .55, 2.72, .30)
    art.beveled_block("CentralRecessedToolPort", "CARBON",
                      0, -2.20, 0, 1.62, .08, 1.74, .09)


def export(output: Path) -> dict:
    art = Sculpture()
    art.lines[0] = "# Chaos Survival creator original short Sky Spine open lattice"
    art.lines[2] = "o ChaosAuthored_short_sky_spine_cradle"
    build(art)
    dimensions = [round(art.maximum[i]-art.minimum[i], 5) for i in range(3)]
    x, y, z = dimensions
    if set(art.materials) != set(MATERIALS):
        raise ValueError("All seven real original material groups are mandatory")
    if not (10.0 <= x <= 10.6 and 2.05 <= y <= 3.0 and 16.3 <= z <= 17.1):
        raise ValueError("Short Sky Spine source outside safe physical bounds: " + str(dimensions))
    if not (50 <= art.groups <= 135 and 900 <= art.triangles <= 4600):
        raise ValueError("Short Sky Spine mesh complexity outside authored envelope: " + str((art.groups, art.triangles)))
    output.parent.mkdir(parents=True, exist_ok=True)
    content = "\n".join(art.lines) + "\n"
    output.write_text(content, encoding="utf8")
    return {
        "name": "short_sky_spine_cradle",
        "original_creator_source_only": True,
        "requires_moderated_roblox_id": True,
        "can_collide": False,
        "geometry": "triangulated 3D OBJ, open underframe",
        "dimensions": dimensions,
        "materials": sorted(art.materials),
        "groups": art.groups,
        "triangles": art.triangles,
        "vertices": art.vertices,
        "sha256": hashlib.sha256(content.encode()).hexdigest(),
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    print(json.dumps(export(args.output), sort_keys=True))
