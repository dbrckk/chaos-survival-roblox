#!/usr/bin/env python3
"""Original high-silhouette 3D entrance to the real Chaos Survival lobby arena.

An engineered overhead portal, not a collider. The WALKABLE center opening
and existing animated 2D ArenaGateTop text are deliberately left unobscured.
Reuses the owned 7-material route palette and proper UV/tangent glTF exporter.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from generate_district_profile_meshes import Mesh

NAME = "lobby_gate"


def create() -> Mesh:
    m = Mesh(NAME)
    # The real native ArenaGateLeft/Right are centered at x=+-10, rise 13
    # studs, and a server-owned sign hangs at y=13. Never draw art through
    # the 16-stud-wide walking aperture or in front of that text panel.
    for side, suffix in ((-1, "L"), (1, "R")):
        x = side * 10.7
        # These are truly chamfered casings, not exported Roblox Parts.
        m.faceted("PierFoot" + suffix, "ARMOR",
                  x, 0.62, 0.1, 4.4, 1.24, 5.0, 0.55)
        m.faceted("SteppedFoundation" + suffix, "CARBON",
                  x, 1.75, 0.0, 3.5, 1.10, 4.25, 0.42)
        m.faceted("DeepLoadBearingPier" + suffix, "BRUSHED",
                  x, 7.3, 0.0, 3.6, 10.6, 3.55, 0.54)
        m.faceted("RecessedFrontCassette" + suffix, "CARBON",
                  x, 7.15, -2.15, 2.75, 8.1, 0.28, 0.2)
        m.faceted("InternalHotForgedRib" + suffix, "ARMOR",
                  x, 7.1, -2.37, 1.48, 7.9, 0.20, 0.22)
        m.faceted("UpperPierHousing" + suffix, "ALLOY",
                  x, 13.15, 0, 4.1, 2.45, 4.25, 0.46)
        m.faceted("TaperedRoofSupport" + suffix, "CERAMIC",
                  x, 15.0, -0.45, 3.65, 1.6, 3.75, 0.45)
        # A visible recessed telescope/illuminated wayfinding stripe on the
        # vertical outer pier, nowhere near the existing 2D gate sign.
        m.faceted("GuideBackplate" + suffix, "CARBON",
                  x, 8.0, -2.36, 1.72, 5.8, 0.1, 0.15)
        m.faceted("WayfindingInset" + suffix, "SIGNAL",
                  x, 8.0, -2.47, 0.46, 4.65, 0.09, 0.09)
        m.faceted("AngularRailEnd" + suffix, "GRIP",
                  x, 17.0, -0.4, 3.6, 0.7, 4.0, 0.4)

        # Physical plausibility: panel seams, screws, hydraulic pistons,
        # horizontal braces. Mesh material merge yields seven GPU groups,
        # regardless of how many source features are assembled.
        for height in (3.1, 5.6, 10.7, 12.0):
            m.faceted("TensionGusset" + suffix + str(height), "ALLOY",
                      x, height, -2.5, 3.0, 0.28, 0.42, 0.1)
        for dx in (-1.35, 1.35):
            m.rod("VerticalHydraulic" + suffix + str(dx), "BRUSHED",
                  (x+dx, 2.15, -2.07), (x+dx, 12.5, -2.07), 0.12, 8)
            for y in (3.35, 9.45, 12.15):
                m.faceted("HydraulicClamp" + suffix + str(dx) + str(y),
                          "ALLOY", x+dx, y, -2.07, .43, .22, .48, .08)
        # Braced gussets terminate in the high, NON-WALKABLE arch; preserve
        # the real gate's full player opening at every head height.
        m.rod("Raker" + suffix, "ARMOR",
              (side * 11.5, 12.0, 1.2),
              (side * 7.9, 17.0, 1.0), .30, 10)
        m.rod("RakerSupport" + suffix, "BRUSHED",
              (side * 9.7, 13.5, 1.2),
              (side * 6.8, 17.5, .4), .19, 8)
        m.faceted("ApexLug" + suffix, "CERAMIC",
                  side*7.65, 17.35, 0.50, 2.0, 1.0, 2.2, .25)

    # Suspended crown BEHIND and ABOVE the server-owned arena gate status
    # plate (native top y=11.5..14.5 and Z=-1.5). None of these surfaces
    # occupy the text's viewing plane. Industrial instead of neon arch.
    m.faceted("OverheadTruss", "ARMOR",
              0, 17.8, 0.0, 18.0, 1.65, 2.9, 0.65)
    m.faceted("OverheadFrontArmor", "CERAMIC",
              0, 18.85, -0.75, 16.2, 0.65, 2.55, .35)
    m.faceted("RearCableTray", "CARBON",
              0, 16.1, 1.75, 17.5, .50, 1.10, .16)
    for i in range(-4, 5):
        x = i * 1.78
        m.faceted("CrossbeamSeam" + str(i), "GRIP",
                  x, 18.05, -1.55, 0.15, 1.55, 0.28, .06)
    # A curved, faceted flying bridge drives the visual focal point.
    # Starts at elevated y=16.4; never overlays the actual interactive arch.
    for i in range(18):
        a = math.pi * (0.11 + 0.78 * i / 18)
        b = math.pi * (0.11 + 0.78 * (i + 1) / 18)
        m.rod("CrownArc%02d" % i, "ALLOY",
              (10.25 * math.cos(a), 13.3 + 5.9 * math.sin(a), 0.75),
              (10.25 * math.cos(b), 13.3 + 5.9 * math.sin(b), 0.75),
              .24, 8)
    # Mechanical turbine lanterns and anodized trim in front of skyline.
    for side in (-1, 1):
        for y in (15.4, 16.3, 17.2):
            m.faceted("OuterHeatSink" + str(side) + str(y), "GRIP",
                      side * 12.35, y, -0.20, 0.30, 0.16, 2.85, .06)
    m.faceted("CrownBadgeBase", "CARBON",
              0, 19.38, -1.45, 3.6, .78, .50, .24)
    m.faceted("CrownBadgeLens", "SIGNAL",
              0, 19.38, -1.73, 2.7, .25, .12, .07)
    return m


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=Path("assets/source/chaos_lobby_gate.obj"))
    args = parser.parse_args()
    mesh = create()
    metadata = mesh.write(args.output)
    # Independent bounding-box proof, not only known source constants.
    points = [tuple(float(n) for n in line.split()[1:])
              for line in mesh.lines if line.startswith("v ")]
    low = [min(p[i] for p in points) for i in range(3)]
    high = [max(p[i] for p in points) for i in range(3)]
    size = [round(high[i]-low[i], 3) for i in range(3)]
    if not (24 <= size[0] <= 28 and 18 <= size[1] <= 22
            and 4 <= size[2] <= 8 and low[1] >= 0
            and 1000 <= metadata["triangles"] <= 8500):
        raise SystemExit("Gate source outside original authored bounds: " + str(size))
    print(json.dumps({"name": NAME, "dimensions": size,
                      "bounds_min": low, "bounds_max": high, **metadata},
                     sort_keys=True))


if __name__ == "__main__":
    main()
