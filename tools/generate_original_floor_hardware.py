#!/usr/bin/env python3
"""Three owner-original, triangulated floor micro-machinery sculpt families.

High-detail *geometry*, not Roblox Part/WedgePart decoration. All are
deliberately low profile: the physical server Arena/Base, warnings, real
platforms and hazard regions remain untouched. Seven distinct source
material groups, UV/normals/tangents provided by the repo glTF converter.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

KINDS = ("floor_corner_guard", "floor_anchor_bolt", "floor_harbor_tie")


def corner(m: Sculpture):
    # Actual inclined wedge profile, not a beveled *block* pretending to
    # replace the old WedgePart corner silhouette. 5.1-stud plate.
    verts = [
        (-2.54,-.16,-2.54),(2.54,-.16,-2.54),
        (2.54,-.16,2.54),(-2.54,-.16,2.54),
        (-2.54,-.06,-2.54),(2.54,-.06,-2.54),
        (2.54,.17,2.54),(-2.54,.17,2.54),
    ]
    tris = [(0,2,1),(0,3,2),(4,5,6),(4,6,7),
            (0,1,5),(0,5,4),(1,2,6),(1,6,5),
            (2,3,7),(2,7,6),(3,0,4),(3,4,7)]
    m.add("CastInclinedSkeletalCorner","ARMOR",verts,tris)
    for side in (-1,1):
        m.beveled_block("ArcRidgeSeal%d"%side,"BRUSHED",
                        side*1.87,.11,.80,.38,.065,2.30,.10)
        m.beveled_block("BevelRimArmor%d"%side,"CERAMIC",
                        side*2.20,.055,-.96,.25,.064,1.61,.09)
        m.rod("BearingAnchorRail%d"%side,"ALLOY",
              (side*1.88,-.04,-1.78),
              (side*1.88,-.04,1.98),.062,8)
    for index in range(4):
        m.beveled_block("ToeStepGrip%d"%index,"GRIP",
                        -1.23+index*.82,.065,.47,.32,.048,.70,.065)
        m.beveled_block("WeatherproofJoint%d"%index,"CARBON",
                        -1.23+index*.82,.048,-.42,.24,.024,.42,.055)
    m.beveled_block("ForwardRecessedLocator","SIGNAL",
                    0,.13,1.60,1.35,.022,.105,.029)
    # These narrow surface details are fully embedded in an inert cosmetic
    # composite: no extra collision to mislead players at the rim.
    for z in (-1.90,1.90):
        for x in (-1.93,1.93):
            m.rod("CaptiveAnchor_%d_%d"%(int(x*100),int(z*100)),
                  "BRUSHED",(x,.042,z),(x,.108,z),.052,8)


def bolt(m: Sculpture):
    # Visibly six-sided forged bolt with concentric washer and recessed
    # driver slot. Scale is intentionally 0.42 studs, NOT a huge machine.
    m.beveled_block("AnchorWasher","ARMOR",
                    0,-.045,0,.405,.060,.405,.06)
    m.beveled_block("RecessedCarbonGasket","CARBON",
                    0,-.003,0,.319,.025,.319,.054)
    m.rod("SixteenFacetHead","BRUSHED",
          (0,.010,0),(0,.095,0),.152,12)
    for i in range(6):
        a=math.tau*i/6
        x=.131*math.cos(a); z=.131*math.sin(a)
        m.rod("CapturedSpline%d"%i,"ALLOY",
              (x,.036,z),(x,.102,z),.018,8)
    m.beveled_block("ToolDriverSlot","GRIP",
                    0,.105,0,.182,.015,.043,.012)
    m.beveled_block("CeramicAntiSlipInsert","CERAMIC",
                    0,-.073,0,.245,.028,.245,.044)
    m.beveled_block("InspectionIndex","SIGNAL",
                    .116,.098,0,.045,.018,.036,.01)


def tie(m: Sculpture):
    # Low-profile cast dock fitting, a real closed attachment eye with
    # triangulated metal hoop supports, not a standard square Roblox Part.
    m.beveled_block("ForgedMooringFoot","ARMOR",
                    0,-.047,0,1.04,.085,1.04,.15)
    m.beveled_block("EndgrainWeatherSeal","CARBON",
                    0,.002,0,.87,.025,.87,.12)
    for side in (-1,1):
        m.beveled_block("CastCrossHead%d"%side,"ALLOY",
                        side*.32,.079,0,.19,.08,.71,.063)
        m.rod("RetainedAnchor%d"%side,"BRUSHED",
              (side*.36,-.015,.27),
              (side*.36,.072,.27),.05,10)
        m.beveled_block("WearGuard%d"%side,"CERAMIC",
                        side*.30,.13,-.28,.23,.033,.10,.02)
    for k in range(5):
        x=-.29+k*.145
        m.beveled_block("KnurlFriction%d"%k,"GRIP",
                        x,.131,0,.067,.021,.43,.018)
    m.rod("BridgeHoopLeft","BRUSHED",(-.22,.075,.1),
          (-.22,.161,.1),.052,10)
    m.rod("BridgeHoopCrossbar","BRUSHED",(-.22,.16,.1),
          (.22,.16,.1),.052,10)
    m.rod("BridgeHoopRight","BRUSHED",(.22,.075,.1),
          (.22,.161,.1),.052,10)
    m.beveled_block("HarborLoadIndex","SIGNAL",
                    0,.101,-.35,.27,.022,.065,.01)


BUILDERS = {
    "floor_corner_guard": corner,
    "floor_anchor_bolt": bolt,
    "floor_harbor_tie": tie,
}
# Deliberate small geometry; validate by kind rather than applying the
# previous 5-to-11-stud *large floor module* envelope to bolts.
LIMITS = {
    "floor_corner_guard": ((4.8,5.4),(.25,.55),(4.8,5.4),(300,1400)),
    "floor_anchor_bolt": ((.32,.60),(.16,.29),(.32,.60),(240,1200)),
    "floor_harbor_tie": ((.92,1.20),(.23,.48),(.92,1.20),(350,1700)),
}


def export(kind: str, target: Path) -> dict:
    if kind not in BUILDERS:
        raise ValueError("Unknown original floor hardware")
    art=Sculpture()
    art.lines[0]="# Original compact 3D mechanical hardware: "+kind
    art.lines[2]="o ChaosOriginal_"+kind
    BUILDERS[kind](art)
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    limits=LIMITS[kind]
    for axis in range(3):
        if not limits[axis][0] <= dims[axis] <= limits[axis][1]:
            raise ValueError("Nonphysical hardware bounds "+
                             str((kind,dims,axis)))
    if not limits[3][0]<=art.triangles<=limits[3][1]:
        raise ValueError("Hardware triangle budget exceeded: "+
                         str((kind,art.triangles)))
    if not 12<=art.groups<=90 or art.materials!=set(MATERIALS):
        raise ValueError("Original mechanical sculpture/materials incomplete")
    target.parent.mkdir(parents=True,exist_ok=True)
    data="\n".join(art.lines)+"\n"
    target.write_text(data,encoding="utf-8")
    return {
        "asset":kind,"triangles":art.triangles,
        "groups":art.groups,"vertices":art.vertices,
        "materials":sorted(art.materials),
        "dimensions":dims,"bounds_min":art.minimum,
        "bounds_max":art.maximum,
        "sha256":hashlib.sha256(data.encode()).hexdigest(),
    }


if __name__=="__main__":
    cli=argparse.ArgumentParser()
    cli.add_argument("--model",required=True,choices=KINDS)
    cli.add_argument("--output",required=True,type=Path)
    opts=cli.parse_args()
    print(json.dumps(export(opts.model,opts.output),sort_keys=True))
