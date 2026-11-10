#!/usr/bin/env python3
"""Original South Towers finishing sculpture replacing SEVEN cosmetic primitives.

A single original creator-owned seven-material Model covers:
Foundation, FloorInset, WestLiftRail, EastLiftRail, WestSuspension,
EastSuspension and TransferSignal. The six previously approved original
bridge/crown meshes and their independent LOD kits remain untouched.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

NAME = "south_towers_forged_finishing"
SCALE = 2.5
CENTER_Y = 20.25


def p(x, y, z):
    return (x / SCALE, (y - CENTER_Y) / SCALE, z / SCALE)


def block(a, name, material, x, y, z, sx, sy, sz, edge=.07):
    a.beveled_block(name, material, *p(x, y, z),
                    sx / SCALE, sy / SCALE, sz / SCALE, edge / SCALE)


def rod(a, name, material, a0, b0, radius=.11, sides=10):
    a.rod(name, material, p(*a0), p(*b0), radius / SCALE, sides)


def detailed_foundation(a):
    """Carved plated exterior, not a plain monolithic Part/flat decal."""
    block(a, "BeveledArmoredFoundryFooting", "ARMOR",
          0, -1.21, 0, 46.25, 1.43, 12.35, .26)
    for face in (-1, 1):
        z = face * 6.26
        rod(a, "DieCastLongitudinalRim%s" % face, "BRUSHED",
            (-22.85, -.59, z), (22.85, -.59, z), .16, 10)
        for index in range(14):
            x = -21.18 + index * 3.26
            block(a, "NestedArmorSkirt%s_%02d" % (face, index),
                  "GRIP", x, -1.1, face * 6.22,
                  2.77, .54, .14, .07)
            block(a, "RivetedStrut%s_%02d" % (face, index),
                  "ALLOY", x, -.62, face * 6.22,
                  .19, .40, .21, .045)
        for x in (-22.2, 22.2):
            rod(a, "BaseEndCapDiagonal%s_%s" % (face, x), "ALLOY",
                (x, -1.70, face * 5.85),
                (x, -.50, face * 4.55), .13, 8)

    # Distinct modular walkable-looking skin; all scenery remains nonphysical.
    block(a, "DeepRecessedCarbonDeck", "CARBON",
          0, .11, 0, 38.7, .15, 9.65, .13)
    for index in range(16):
        x = -18.1 + index * 2.42
        block(a, "AntiSlipCeramicDeckTile%02d" % index, "CERAMIC",
              x, .231, 0, 2.1, .067, 8.9, .035)
        for face in (-1, 1):
            z = face * 4.61
            block(a, "InsetElectricalWarning%s_%02d" % (face, index),
                  "SIGNAL", x, .284, z, 1.28, .041, .13, .019)
    for index in range(10):
        x = -16.8 + index * 3.74
        for z in (-5.4, 5.4):
            block(a, "UnderdeckRaisedServiceHatch%s_%02d" % (z, index),
                  "BRUSHED", x, -.36, z, 1.96, .13, .73, .055)


def lift_guides(a):
    """Two real parallel guide rods, machined grip clamps and relief."""
    for side in (-1, 1):
        x = side * 17.5
        top = 33.5 if side < 0 else 42.5
        z = -3.7
        for index, dx in enumerate((-.14, .14)):
            rod(a, "MachinedVerticalGuide%s_%s" % (side, index),
                "BRUSHED", (x+dx, 3.62, z), (x+dx, top-.10, z),
                .095, 10)
        for index in range(13 if side < 0 else 17):
            y = 4.1 + index * (top - 4.8) / (12 if side < 0 else 16)
            block(a, "GuideShoeRetainer%s_%02d" % (side, index),
                  "GRIP", x, y, z, .55, .19, .67, .055)
            block(a, "InlaidGuideServiceLamp%s_%02d" % (side, index),
                  "SIGNAL", x, y, z-.355, .29, .075, .075, .025)
        for index in range(7 if side < 0 else 10):
            y = 5.3 + index*(top-7.2)/(6 if side < 0 else 9)
            rod(a, "CarriageReleasePin%s_%02d" % (side, index),
                "ALLOY", (x-.46, y, z+.11), (x+.46, y, z+.11),
                .061, 8)


def forged_suspension(a):
    """Twin 26-degree cable stays with three-dimensional coupling rings."""
    for side in (-1, 1):
        phi = side*math.radians(26)
        ux, uy = -math.sin(phi), math.cos(phi)
        cx, cy = side*10, 31
        def pos(dist, dx=0, dz=0):
            return (cx+ux*dist+dx, cy+uy*dist, dz)
        for index, dx in enumerate((-.22, .22)):
            for dz in (-.22, .22):
                rod(a, "TwistedSuspensionStrand%s_%s_%s" % (side,index,dz),
                    "ALLOY", pos(-7.85, dx, dz), pos(7.85, dx, dz),
                    .074, 10)
        rod(a, "SuspensionPowerCore%s" % side, "ARMOR",
            pos(-7.88), pos(7.88), .24, 12)
        for index in range(8):
            d = -7.25 + index*2.07
            posx, posy, posz = pos(d)
            block(a, "PressedSuspensionCoupler%s_%02d" % (side,index),
                  "BRUSHED", posx, posy, posz, .76, .28, .83, .09)
            for dz in (-.36,.36):
                rod(a, "CableRivet%s_%02d_%s" % (side,index,dz),
                    "GRIP", (posx-.30,posy-.15,dz),
                    (posx+.30,posy+.15,dz), .053, 8)
        for d in (-7.95,7.95):
            x,y,z = pos(d)
            rod(a, "ForgedSuspensionTermination%s_%s" % (side,d),
                "CERAMIC", (x-.48,y-.21,z), (x+.48,y+.21,z),
                .19, 10)


def signal_cab(a):
    """Sculpted lower beacon, not a solid rotated wedge."""
    x,y,z = 3.5,26.5,-3
    block(a, "ForgedTransferBeaconBody", "CARBON", x,y,z,
          6.65,1.55,1.70,.22)
    for face in (-1,1):
        zz = z + face*.86
        rod(a, "BeaconRecessedRail%s" % face,"ALLOY",
            (x-3.26,y-.66,zz),(x+3.26,y-.66,zz),.095,8)
        for index in range(9):
            xx=x-2.85+index*.71
            block(a,"BeaconRaisedDiode%s_%02d" % (face,index),
                  "SIGNAL", xx,y+.24,zz,.32,.27,.085,.04)
    for index in range(7):
        xx=x-2.6+index*.86
        block(a, "BeaconCeramicOptics%02d" % index,"CERAMIC",
              xx,y+.82,z,.42,.21,1.55,.06)
    # Actual triangular roof fins, with double-sided triangles and depth.
    for index in range(6):
        xx=x-2.75+index*1.10
        vertices=[p(xx-.40,y+.80,z-.71),p(xx+.40,y+.80,z-.71),
                  p(xx,y+1.38,z-.71),
                  p(xx-.40,y+.80,z-.48),p(xx+.40,y+.80,z-.48),
                  p(xx,y+1.38,z-.48)]
        faces=[(0,1,2),(5,4,3),(0,3,4),(0,4,1),
               (1,4,5),(1,5,2),(2,5,3),(2,3,0)]
        a.add("PiercedSignalBeaconFin%02d" % index,"BRUSHED",
              vertices,faces)


def export(path):
    a = Sculpture()
    a.lines[0] = "# Chaos Survival original south Towers complete finishing sculpture"
    a.lines[2] = "o ChaosOriginalSouthTowersForgedFinishing"
    detailed_foundation(a)
    lift_guides(a)
    forged_suspension(a)
    signal_cab(a)
    dims = [round(a.maximum[i] - a.minimum[i], 5) for i in range(3)]
    center = [round((a.maximum[i] + a.minimum[i])*.5, 5)
              for i in range(3)]
    assert set(a.materials) == set(MATERIALS), a.materials
    assert 120 <= a.groups <= 900, (a.groups, a.triangles)
    assert 3000 <= a.triangles <= 18000, a.triangles
    assert 18.4 <= dims[0] <= 19.1, dims
    assert 17.3 <= dims[1] <= 18.2, dims
    assert 4.95 <= dims[2] <= 5.32, dims
    assert all(abs(v) < .55 for v in center), center
    raw = "\n".join(a.lines) + "\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(raw, encoding="utf-8")
    return {
        "asset": NAME, "triangles": a.triangles, "groups": a.groups,
        "vertices": a.vertices, "materials": sorted(a.materials),
        "bounds": dims, "center": center,
        "sha256": hashlib.sha256(raw.encode()).hexdigest()
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(export(args.output), sort_keys=True))
