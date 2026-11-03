#!/usr/bin/env python3
"""Original suspended arena keel: real authored 3D triangulated sculpture.

An open-frame, four-sided, 56-stud service lattice with deep hanging
transmission machinery, hollow bays and six-way radial bracing. It cannot
be a Roblox playable floor: every source vertex stays below y=-0.5.
This source must pass Roblox owner upload and moderation before any
public runtime references its Model ID. Seven authored PBR material groups.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from generate_original_skyfleet_carrier import Sculpture, MATERIALS

NAME = "arena_keel"


def build():
    m = Sculpture()
    m.lines[0] = "# Original Chaos Survival sculpted suspended arena undercarriage"
    m.lines[2] = "o ChaosOriginalSuspendedArenaKeel"

    # A full-size 56 x 55-stud mechanical frame, not a square plate.
    # Interlocking beams and hanging ring expose genuine negative space.
    for axis in ("X", "Z"):
        for side in (-1, 1):
            tag = axis + ("N" if side < 0 else "P")
            if axis == "X":
                x, z, sx, sz = 0, side * 26.0, 56.2, 1.6
                x2, z2, sx2, sz2 = 0, side * 24.2, 51.5, 1.2
            else:
                x, z, sx, sz = side * 26.0, 0, 1.6, 54.0
                x2, z2, sx2, sz2 = side * 24.2, 0, 1.2, 51.0
            m.beveled_block("CastOuterRace" + tag, "ARMOR",
                            x, -1.2, z, sx, 1.7, sz, .40)
            m.beveled_block("RecessedLowerRace" + tag, "CARBON",
                            x2, -4.1, z2, sx2, .95, sz2, .29)
            m.beveled_block("BrushedLip" + tag, "BRUSHED",
                            x, -2.29, z, sx*.97, .16, sz*.83, .16)

    # Deep open truss grid. Every rail has a real volumetric box AND
    # visible thin cylindrical diagonal webs (not textures on a cube).
    for i in range(9):
        p = -21 + i * 5.25
        name = f"{i:02d}"
        m.beveled_block("TransverseUpper" + name, "ALLOY",
                        0, -2.15, p, 50.0, .85, .80, .21)
        m.beveled_block("TransverseLower" + name, "BRUSHED",
                        0, -5.5, p, 47.5, .62, .62, .19)
        for side in (-1, 1):
            m.rod("AngledWeb" + name + str(side), "CARBON",
                  (side * 21.8, -2.5, p),
                  (side * 17.1, -5.4, p), .23, 8)
        if i % 2 == 0:
            m.beveled_block("InspectionPlate" + name, "CERAMIC",
                            0, -2.0, p, 4.6, .32, 1.65, .29)
            m.beveled_block("RecessedIndex" + name, "GRIP",
                            0, -1.80, p, 2.55, .09, .34, .06)

    for side in (-1, 1):
        for lane in (8.0, 18.0):
            m.beveled_block("LongitudinalKeel" + str(side) + str(lane),
                            "ARMOR", side*lane, -3.1, 0,
                            1.0, 1.4, 48.0, .25)
            m.rod("UnderslungPressureTube" + str(side) + str(lane),
                  "BRUSHED", (side*lane, -5.15, -22),
                  (side*lane, -5.15, 22), .23, 8)

    # Four differentially triangulated corner machine nodes.
    for sx in (-1, 1):
        for sz in (-1, 1):
            tag = ("L" if sx < 0 else "R") + ("F" if sz < 0 else "B")
            x, z = sx * 23.4, sz * 22.8
            m.beveled_block("ShockPivot" + tag, "CERAMIC",
                            x, -4.0, z, 4.2, 4.9, 4.6, .86)
            m.beveled_block("VerticalDrive" + tag, "ARMOR",
                            x, -10.4, z, 2.4, 8.0, 2.5, .43)
            m.beveled_block("HangingTorqueClamp" + tag, "GRIP",
                            x, -14.8, z, 3.9, 1.1, 3.9, .55)
            m.beveled_block("LateralSignalInlay" + tag, "SIGNAL",
                            x, -7.8, z+sz*1.5, .45, 2.5, .11, .065)
            for alpha in (-1, 1):
                m.rod("SweptDiagonalTendon" + tag + str(alpha), "ALLOY",
                      (x-sx*alpha*3.0, -2.2, z-sz*2.6),
                      (x-sx*alpha*1.4, -14.2, z), .31, 8)

    # Open 16-segment alloy rotor below the keel, genuinely hollow.
    import math
    segments = 16
    radius = 10.8
    for i in range(segments):
        a = 2*math.pi*i/segments
        b = 2*math.pi*(i+1)/segments
        start = (radius*math.cos(a), -12.4, radius*math.sin(a))
        end = (radius*math.cos(b), -12.4, radius*math.sin(b))
        m.rod("SuspendedRing%02d" % i, "ALLOY", start, end, .42, 8)
        if i % 4 == 0:
            m.rod("RotorRadialStabilizer%02d" % i, "BRUSHED",
                  (7*math.cos(a), -8.3, 7*math.sin(a)),
                  start, .22, 8)
    m.beveled_block("OpenCoreTransmission", "CARBON",
                    0, -9.2, 0, 8.5, 2.4, 7.4, .90)
    m.beveled_block("TurbineBearing", "CERAMIC",
                    0, -11.8, 0, 5.1, 2.9, 5.1, .71)
    for angle in range(0, 360, 60):
        a = math.radians(angle)
        m.rod("VentedSixAxisBlade" + str(angle), "ARMOR",
              (3.3*math.cos(a), -12.6, 3.3*math.sin(a)),
              (9.4*math.cos(a+0.2), -12.6, 9.4*math.sin(a+0.2)),
              .29, 8)
    m.beveled_block("InspectionBeacon", "SIGNAL",
                    0, -13.6, 0, 2.3, .15, 1.0, .14)
    return m


def export(path: Path):
    m = build()
    bounds = [round(m.maximum[i]-m.minimum[i], 3) for i in range(3)]
    if not (1800 <= m.triangles <= 8000 and 55 <= m.groups <= 250):
        raise ValueError(f"Engineered keel source outside triangle/group budget: {m.triangles}/{m.groups}")
    if set(MATERIALS) != m.materials:
        raise ValueError("Missing premium authored PBR material classes")
    if not (54 <= bounds[0] <= 60 and 14 <= bounds[1] <= 20
            and 52 <= bounds[2] <= 60):
        raise ValueError(f"Imported Model exceeds 65-stud sanitizer envelope: {bounds}")
    if m.maximum[1] > -0.48:
        raise ValueError("Keel must stay UNDER the real collision platform")
    result = m.write(path)
    result["asset"] = NAME
    result["dimensions"] = bounds
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path,
                        default=Path("assets/source/chaos_arena_keel.obj"))
    options = parser.parse_args()
    print(json.dumps(export(options.output), sort_keys=True, indent=2))
