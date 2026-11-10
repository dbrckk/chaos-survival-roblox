#!/usr/bin/env python3
"""Original 24.9-stud, seven-material sculpted machinery crown for Towers.

Replaces the native 5.2x24x5.2 shaft and 7.4x1x7.4 cap as one
nonphysical 3D art source (four corner instances, same exact sculpt).
The navigation antenna remains native and visible above the new crown.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NAME = "variant_towers_sculpted_machinery"
CENTER_Y = 12.45


def make() -> Sculpture:
    art = Sculpture()
    art.lines[0] = "# Original Chaos Survival Towers corner machinery sculpture"
    art.lines[2] = "o ChaosOriginalTowersCornerMachinery"

    # 12-facet continuously stepped, six-section industrial core:
    # neither a cylinder primitive nor a rectangular column.
    facets = 12
    levels = [
        (0.0,2.35,2.35),(0.95,2.65,2.64),
        (3.45,2.27,2.30),(6.9,2.40,2.34),
        (12.0,2.27,2.40),(17.8,2.43,2.24),
        (22.85,2.33,2.39),(24.0,2.22,2.32),
    ]
    vertices = []
    for y,rx,rz in levels:
        for i in range(facets):
            a = math.tau*i/facets
            vertices.append((rx*math.cos(a),y-CENTER_Y,
                             rz*math.sin(a)))
    faces = []
    for n in range(len(levels)-1):
        for i in range(facets):
            a = n*facets+i
            b = n*facets+(i+1)%facets
            c = (n+1)*facets+(i+1)%facets
            d = (n+1)*facets+i
            faces.extend(((a,b,c),(a,c,d)))
    for i in range(1,facets-1):
        faces.append((0,i+1,i))
        last=(len(levels)-1)*facets
        faces.append((last,last+i,last+i+1))
    art.add("DodecagonalVariableRadiusMachineryCore","ARMOR",
            vertices,faces)

    # Exact native crown envelope: 7.36 x 1.00 x 7.36, top at 24.90.
    # The 24.0-stud inner shaft ends beneath this sculpted open lip.
    art.beveled_block("ForgedTwelveStudStormCanopy","BRUSHED",
                      0,24.4-CENTER_Y,0,7.36,1.0,7.36,.38)
    art.beveled_block("CarbonRecessedCanopyUndertray","CARBON",
                      0,23.92-CENTER_Y,0,6.76,.14,6.76,.22)

    for side in (-1,1):
        x=side*2.65
        # Non-planar load frame: diagonal stainless fins and tapering spines.
        art.rod("BraidedLongLoadSpar%s"%side,"ALLOY",
                (x,1.5-CENTER_Y,-1.45),
                (side*2.92,21.6-CENTER_Y,-1.45),.16,10)
        art.rod("TriangulatedExternalCrownStrut%s"%side,"GRIP",
                (side*2.94,18.2-CENTER_Y,1.9),
                (side*2.35,23.7-CENTER_Y,2.6),.12,10)
        art.beveled_block("MilledBlackVerticalHeatPlate%s"%side,
                          "CARBON",side*2.37,11.3-CENTER_Y,0,
                          .28,16.2,2.45,.08)
        for step in range(6):
            y=4.9+step*2.92
            art.beveled_block("EmbossedSideHeatDissipator%s_%d"%(side,step),
                              "GRIP",side*2.57,y-CENTER_Y,.15,
                              .27,.55,2.55,.07)

    for direction in (-1,1):
        z=direction*2.42
        for i in range(5):
            y=3.75+3.75*i
            art.beveled_block("CarbonFrontControlCassette%d_%02d"%(direction,i),
                              "CERAMIC",0,y-CENTER_Y,z,
                              2.75,1.28,.17,.13)
            art.beveled_block("DeepForgedTelemetryVent%d_%02d"%(direction,i),
                              "CARBON",0,y-CENTER_Y,z+direction*.105,
                              1.98,.48,.07,.025)
            for side in (-1,1):
                art.beveled_block("InsetStatusPixel%d_%02d_%d"%(direction,i,side),
                                  "SIGNAL",side*1.2,y-CENTER_Y,
                                  z+direction*.13,.17,.34,.08,.035)

    for level in range(4):
        y=3+level*5.9
        for side in (-1,1):
            art.rod("CrossLockedTorqueDiagonal%d_%s"%(level,side),
                    "ALLOY",(side*1.77,y-CENTER_Y,-2.13),
                    (side*2.38,y+2.35-CENTER_Y,-1.93),.085,8)

    # A visibly carved metal crown rim and isolated signal bearing.
    for i in range(8):
        a=math.tau*i/8
        x,z=3.1*math.cos(a),3.1*math.sin(a)
        art.beveled_block("CrownCornerGusset%02d"%i,"CERAMIC",
                          x,24.83-CENTER_Y,z,.38,.12,.39,.055)
    art.beveled_block("SealedCentralAntennaFoot","ALLOY",
                      0,24.87-CENTER_Y,0,.76,.04,.76,.07)

    return art


def export(path: Path) -> dict:
    art=make()
    raw="\n".join(art.lines)+"\n"
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    center=[round((art.minimum[i]+art.maximum[i])*.5,5) for i in range(3)]
    if set(art.materials)!=set(MATERIALS):
        raise ValueError("Incomplete seven-material source")
    if not 900<=art.triangles<=15000 or not 55<=art.groups<=400:
        raise ValueError(("Unexpected triangulation",art.triangles,art.groups))
    if abs(dims[0]-7.36)>.10 or abs(dims[2]-7.36)>.10:
        raise ValueError(("Unexpected crown width",dims))
    if abs(dims[1]-24.9)>.10:
        raise ValueError(("Incorrect native union height",dims))
    if any(abs(c)>.08 for c in center):
        raise ValueError(("Asset must be centered on native union",center))
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(raw,encoding="utf-8")
    return {"asset":NAME,"triangles":art.triangles,"groups":art.groups,
            "vertices":art.vertices,"materials":sorted(art.materials),
            "bounds":dims,"center":center,
            "sha256":hashlib.sha256(raw.encode()).hexdigest()}


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))
