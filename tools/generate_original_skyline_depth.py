#!/usr/bin/env python3
"""Author a genuine sculpted skyline silhouette for eight distant roof masses.

This creates original, seven-material triangulated OBJ geometry, NOT a Roblox
Part or an external creator model. Roblox owner upload/moderation is separate.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture


def build():
    art = Sculpture()
    art.lines[0] = "# Chaos Survival original faceted industrial skyline depth"
    art.lines[2] = "o ChaosOriginalSkylineDepth"

    # Eight-facet cast concrete/metal shell with a real stepped/tapered crown.
    # The tower is centered at origin so a verified future Model clone can
    # fit one of the native WedgePart owners without an arbitrary offset.
    rings = [
        (-16.9, 5.45, 3.36), (-15.3, 5.70, 3.47),
        (5.7, 5.05, 3.12), (11.2, 4.31, 2.75),
        (15.65, 2.77, 2.08), (17.05, 1.45, 1.35),
    ]
    vertices = []
    for y, half_x, half_z in rings:
        e = .38
        cross = [
            (-half_x+e,-half_z), (half_x-e,-half_z),
            (half_x,-half_z+e), (half_x,half_z-e),
            (half_x-e,half_z),(-half_x+e,half_z),
            (-half_x,half_z-e),(-half_x,-half_z+e)
        ]
        vertices.extend((x,y,z) for x,z in cross)
    faces = []
    for layer in range(len(rings)-1):
        for k in range(8):
            a=layer*8+k
            d=layer*8+(k+1)%8
            c=(layer+1)*8+(k+1)%8
            e=(layer+1)*8+k
            faces.extend(((a,d,c),(a,c,e)))
    for k in range(1,7):
        faces.append((0,k+1,k))
        end=(len(rings)-1)*8
        faces.append((end,end+k,end+k+1))
    art.add("TaperedOctagonalForgedHull", "ARMOR", vertices, faces)

    # True inset facade relief and suspended service rail frames. All
    # panel geometry occupies its own volume, not shader-only coloring.
    for side in (-1, 1):
        sx=side*4.25
        for lane in (0, 1):
            art.rod("ExteriorVerticalTruss_%s_%s"%(side,lane),
                    "ALLOY", (sx+side*lane*.55,-14.1,-2.60+lane*5.20),
                    (sx+side*lane*.34,10.9,-2.40+lane*4.80), .14, 8)
        art.beveled_block("RaisedVentSpine%s"%side, "CARBON",
                          side*4.76,-.6,0,.25,21.2,1.15,.06)
        for row in range(6):
            y=-11.0+row*3.75
            art.beveled_block("ForgeCassette_%s_%02d"%(side,row),
                              "BRUSHED",side*3.36,y,-3.32,
                              1.55,1.65,.15,.12)
            art.beveled_block("VentOpenInset_%s_%02d"%(side,row),
                              "GRIP",side*3.36,y,-3.415,
                              .91,.58,.13,.08)
            # Actual angled stainless grille ribs instead of flat decal.
            for slot in range(2):
                art.rod("SlottedCoolingFin_%s_%02d_%s"%(side,row,slot),
                        "ALLOY",
                        (side*3.74,y-.20+slot*.31,-3.54),
                        (side*2.98,y-.20+slot*.31,-3.54),.047,6)

    # Camera-facing multi-layer glazed service windows and metal shutters.
    for row in range(5):
        y=-10.4+row*4.2
        art.beveled_block("ViewportArmorFrame_%02d"%row,
                          "BRUSHED",0,y,-3.47,
                          3.2,1.82,.20,.14)
        art.beveled_block("RecessedCeramicLens_%02d"%row,
                          "CERAMIC",0,y,-3.595,
                          2.34,.85,.10,.10)
        for x in (-1.26,1.26):
            art.beveled_block("CaptiveForgeBolt_%02d_%s"%(row,x),
                              "ALLOY",x,y,-3.58,.17,.19,.17,.045)

    # Crown has a sculpted fork instead of the old triangular Wedge top.
    for side in (-1,1):
        art.rod("CrownTensionBrace%s"%side,"ALLOY",
                (side*4.26,10.7,-2.12),
                (side*1.80,16.38,-1.01),.26,10)
        art.beveled_block("TopTelemetryGuard%s"%side,"CERAMIC",
                          side*1.93,16.42,-1.12,
                          1.14,.62,.73,.12)
    art.beveled_block("RecessedChassisFoot","GRIP",
                      0,-16.65,0,11.0,.42,7.05,.55)
    art.beveled_block("SignalCodeOnly","SIGNAL",
                      0,12.64,-2.45,2.12,.22,.14,.055)

    dimensions=[round(art.maximum[i]-art.minimum[i],5)
                for i in range(3)]
    if set(art.materials)!=set(MATERIALS):
        raise ValueError("Source must contain all seven approved palette groups")
    if not (35 <= art.groups <= 150 and 450 <= art.triangles <= 3200):
        raise ValueError("Unexpected sculpture detail density")
    if not (11.0 <= dimensions[0] <= 12.7 and
            33.0 <= dimensions[1] <= 35.0 and
            7.0 <= dimensions[2] <= 8.0):
        raise ValueError("Unexpected authored 3D model bounding box: "+str(dimensions))
    return art, dimensions


def export(output: Path):
    art,dimensions=build()
    raw="\n".join(art.lines)+"\n"
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(raw,encoding="utf-8")
    return {
        "asset":"skyline_depth_sculpt",
        "triangles":art.triangles,
        "groups":art.groups,
        "materials":sorted(art.materials),
        "dimensions":dimensions,
        "sha256":hashlib.sha256(raw.encode("utf-8")).hexdigest(),
    }


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",required=True,type=Path)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))


if __name__=="__main__":
    main()
