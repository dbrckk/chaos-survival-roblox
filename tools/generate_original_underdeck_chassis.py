#!/usr/bin/env python3
"""Original multi-layered Chaos Survival underdeck engineering MeshPart source.

No primitive Roblox Parts, borrowed meshes or live physics. This generator
makes a real 3D, UV-ready, 7-material triangulated OBJ that must be approved
as a Roblox creator-owned MODEL before runtime cosmetic mounting.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

# Reuse the *verified* parametric chamfer/pipe authoring algorithms, not
# any exported skyfleet asset. Every chassis vertex/group is newly specified.
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

NAME = "underdeck_chassis"


def construct():
    m = Sculpture()
    m.lines[0] = "# Original Chaos Survival multi-web playable underdeck machinery"
    m.lines[2] = "o ChaosOriginalUnderdeckChassis"

    # True 24-stud open-frame silhouette. The cavity above these parts is
    # intentionally EMPTY: the genuine server platform remains the only
    # collider / safe surface, including on collapse and shrinking bridges.
    for side in (-1, 1):
        label = "P" if side < 0 else "S"
        m.beveled_block("MainSweptChassis" + label, "ARMOR",
                        0, -1.25, side * 4.48, 23.3, 0.95, .88, .23)
        m.beveled_block("LowerTorqueFlange" + label, "BRUSHED",
                        0, -3.85, side * 3.50, 20.8, .66, .72, .19)
        m.rod("HollowTorsionSpar" + label, "CARBON",
              (-11, -2.0, side * 3.78), (11, -2.0, side * 3.78), .23, 10)
        for k in range(6):
            x = -9.5 + k * 3.8
            # Every bay has a true diagonal, two staggered pressure
            # flanges and visible negative space between the trusses.
            m.rod("DiagonalWeld" + label + str(k), "ALLOY",
                  (x - 1.5, -1.6, side * 4.37),
                  (x + 1.4, -3.75, side * 3.45), .24, 8)
            m.beveled_block("JointArmor" + label + str(k), "CERAMIC",
                            x, -1.02, side * 4.49, 1.18, .28, 1.02, .18)
            m.beveled_block("CompressionShoe" + label + str(k), "GRIP",
                            x, -4.03, side * 3.50, 1.1, .27, 1.0, .15)
            if k in (1, 4):
                m.beveled_block("LoadWitness" + label + str(k), "SIGNAL",
                                x, -0.84, side * 4.49,
                                1.4, .11, .32, .04)

    # Cross-beam cassettes: real chamfered meshes, cantilever ribs and
    # encapsulated material inserts; never a single featureless rectangle.
    for k in range(7):
        x = -10.0 + k * (20 / 6)
        m.beveled_block("OverheadRib" + str(k), "ARMOR",
                        x, -.62, 0, 1.13, .54, 9.9, .24)
        m.beveled_block("NestedWeb" + str(k), "CARBON",
                        x, -2.36, 0, .72, 2.70, .75, .18)
        m.rod("UnderAngle" + str(k), "BRUSHED",
              (x - .38, -2.2, -3.4), (x + .3, -3.8, 3.4), .17, 8)
        m.beveled_block("WebServiceMarker" + str(k), "SIGNAL",
                        x, -2.52, .42, .40, .80, .15, .04)

    # Sculpted central service tunnel and machine bays. The slots and gaps
    # are open cavities, not fake playable ledges or painted illusions.
    m.beveled_block("MainCentralServiceConduit", "CARBON",
                    0, -1.72, 0, 18.8, 1.38, 2.40, .40)
    m.beveled_block("KeelLowerArmor", "ARMOR",
                    0, -3.52, 0, 16.5, .56, 2.0, .38)
    for side in (-1, 1):
        for i in range(4):
            x = -6.6 + i * 4.4
            m.beveled_block("TorqueMachine" + str(side) + "_" + str(i),
                            "ALLOY", x, -2.36, side * 1.86,
                            2.05, 1.1, 1.27, .29)
            m.beveled_block("MachineInset" + str(side) + "_" + str(i),
                            "BRUSHED", x, -1.68, side * 1.87,
                            1.38, .16, .68, .10)
            m.rod("HydraulicFeed" + str(side) + "_" + str(i),
                  "GRIP", (x - .5, -2.7, side * 2.4),
                  (x + .42, -3.87, side * 3.0), .12, 8)

    # Heavy trapezoidal corner torque lugs; 3D diagonals leave visible
    # negative space from the jump camera, not just neon overlays.
    for side in (-1, 1):
        for end in (-1, 1):
            tag = ("P" if side < 0 else "S") + ("F" if end < 0 else "R")
            x = end * 10.85
            m.beveled_block("StrutToe" + tag, "CERAMIC",
                            x, -2.7, side * 3.25, 1.5, .85, 1.75, .23)
            m.rod("CornerDiagonal" + tag, "ARMOR",
                  (x, -.6, side * 4.40),
                  (x - end * 2.4, -3.86, side * 3.54), .29, 10)
    return m


def export(path: Path):
    m = construct()
    dims = tuple(m.maximum[i] - m.minimum[i] for i in range(3))
    if not (1400 <= m.triangles <= 8500 and 40 <= m.groups <= 250):
        raise ValueError("Underdeck must be detailed real triangulated geometry")
    if m.materials != set(MATERIALS):
        raise ValueError("All seven original material families must be used")
    if not (22 <= dims[0] <= 25 and 3 <= dims[1] <= 8
            and 8 <= dims[2] <= 12):
        raise ValueError(f"Underdeck bounds not safe: {dims}")
    if m.maximum[1] > .001:
        raise ValueError("Cosmetic mesh must stay below the physical landing")
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = "\n".join(m.lines) + "\n"
    path.write_text(payload, encoding="utf-8")
    return {
        "name": NAME, "triangles": m.triangles, "vertices": m.vertices,
        "groups": m.groups, "materials": sorted(m.materials),
        "bounds_min": m.minimum, "bounds_max": m.maximum,
        "dimensions": dims,
        "source_sha256": hashlib.sha256(payload.encode()).hexdigest(),
    }


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--output",
        default="assets/source/chaos_underdeck_chassis.obj")
    args = p.parse_args()
    print(json.dumps(export(Path(args.output)), indent=2, sort_keys=True))
