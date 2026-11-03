#!/usr/bin/env python3
"""Original authored sculpted 3D sky-spine interchange crown.

Replaces the visual silhouette of the two CENTER high-bridge interchanges,
never the physical walking surface, nav collider, hazard or wayfinding.
Source is deliberately bounded to an open, pass-through arch: supports
stand beyond a 12-stud wide real walkway; crosshead >12 studs overhead.
Seven authored metallic/ceramic material regions, real triangulated faces,
UV/tangent-ready conversion through the existing approved OBJ/glTF pipeline.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from generate_district_profile_meshes import Mesh

NAME = "sky_spine_crown"


def create() -> Mesh:
    m = Mesh(NAME)
    # Coordinate origin is on top of the true SkySpineStep=5/6 deck.
    # Keep the R15 lane open: no material intersects |X| < 6.0 at Y<12.
    # A centerline badge sits above the 13-stud roof line, not in the
    # player's camera-height path or on the hazard warning surface.
    for side, label in ((-1, "L"), (1, "R")):
        x = side * 8.0
        m.faceted("OutboardCastFoot" + label, "ARMOR",
                  x, 0.9, 0, 2.8, 1.8, 3.8, .48)
        m.faceted("FloatingVerticalSpar" + label, "BRUSHED",
                  x, 6.8, 0, 1.65, 11.7, 2.3, .35)
        m.faceted("RecessedCarbonCassette" + label, "CARBON",
                  x, 6.9, -1.23, 1.1, 8.2, .20, .12)
        m.faceted("WayfindingLuminaire" + label, "SIGNAL",
                  x, 7.0, -1.36, .30, 6.7, .09, .07)
        m.faceted("HighSuspensionHousing" + label, "CERAMIC",
                  x, 13.4, 0, 2.5, 2.7, 3.5, .45)
        m.faceted("SideCoolingGrille" + label, "GRIP",
                  x, 13.3, -1.85, 1.65, 1.55, .22, .08)
        m.rod("ExternalDiagonalStay" + label, "ALLOY",
              (side * 8.9, 2.2, 1.0),
              (side * 7.5, 12.5, 1.0), .19, 8)
        m.rod("BackTensionLine" + label, "BRUSHED",
              (side * 8.8, 3.0, -1.0),
              (side * 7.5, 13.2, -1.0), .14, 8)
        for y in (3.3, 5.8, 8.3, 10.8):
            m.faceted("LoadBearingClamp" + label + str(y), "ALLOY",
                      x, y, 0.75, 1.95, .22, 1.8, .10)
        for z in (-1.2, 1.2):
            m.faceted("UpperCastShoulder" + label + str(z), "ARMOR",
                      side * 7.1, 14.2, z, 3.4, 1.4, 1.1, .28)
        # Cross-bracing high above the playable crossing.
        m.rod("TaperedUpperStay" + label, "ARMOR",
              (side * 7.8, 12.2, 0.0),
              (side * 5.0, 15.6, 0.0), .32, 10)

    m.faceted("UpperCompositeBeam", "ARMOR",
              0, 15.35, 0, 17.7, 1.8, 3.25, .65)
    m.faceted("UpperArmoredCrown", "CERAMIC",
              0, 16.6, 0, 14.8, .95, 2.65, .45)
    m.faceted("RecessedTruss", "CARBON",
              0, 14.15, 1.35, 15.0, .52, .60, .18)
    for i in range(-6, 7):
        x = i * 1.15
        m.faceted("RibbedHeatSink" + str(i), "GRIP",
                  x, 16.75, -1.45, .13, .72, .24, .055)
    m.faceted("SkyInterchangeCommandPod", "CARBON",
              0, 18.3, -0.45, 4.2, 2.4, 2.5, .45)
    m.faceted("SignalLens", "SIGNAL",
              0, 18.35, -1.82, 2.6, .48, .14, .07)
    m.ring("MechanicalAzimuthRotor", "ALLOY",
           0, 18.2, 0.9, 2.2, .20, 14)
    for side in (-1, 1):
        m.rod("RoofLightningFin" + str(side), "BRUSHED",
              (side * 4.4, 16.9, .4),
              (side * 3.2, 20.4, .4), .20, 8)
    return m


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path,
                        default=Path("assets/source/chaos_sky_spine_crown.obj"))
    args = parser.parse_args()
    mesh = create()
    metadata = mesh.write(args.output)
    points = [tuple(float(n) for n in line.split()[1:])
              for line in mesh.lines if line.startswith("v ")]
    low = [min(p[i] for p in points) for i in range(3)]
    high = [max(p[i] for p in points) for i in range(3)]
    size = [round(high[i] - low[i], 3) for i in range(3)]
    if not (16 <= size[0] <= 21 and 19 <= size[1] <= 23
            and 3 <= size[2] <= 7 and low[1] >= -0.01
            and 1000 <= metadata["triangles"] <= 6500
            and metadata["groups"] <= 160):
        raise SystemExit("Original sky spine source outside bounds: " + str(size))
    print(json.dumps({"name": NAME, "dimensions": size,
                      "bounds_min": low, "bounds_max": high, **metadata},
                     sort_keys=True))


if __name__ == "__main__":
    main()
