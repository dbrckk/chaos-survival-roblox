#!/usr/bin/env python3
"""Creator-authored 3D forged bridge for the Towers signature monument.

A single true continuous sculpted 3D structure spans and replaces the
OverheadServiceBridge and LowerTruss original decorative Parts as one model.
HangingSignal, elevator towers, and all real gameplay platforms stay intact.
No Roblox asset ID is invented. Source bounds in source-union coordinates.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NAME = "signature_towers_forged_bridge"


def continuous_bridge(art: Sculpture):
    # The bridge extends along X, with an actual swept metal cross-section
    # featuring rails, side chines, a deep V-keel and an elevated runway.
    # Its deep central trough is not two rectangular Roblox Parts.
    profile = [
        (-2.98, .42),(-2.66, -.05),(-2.38, -.32),
        (-2.13,-.66),(-1.87,-.79),(-1.29,-.70),
        (1.37,-.70),(1.92,-.84),(2.27,-.42),
        (2.70,-.05),(2.98,.42),(2.95,1.88),
        (2.73,2.24),(-2.73,2.24),(-2.95,1.88),
    ]
    # Each pair is (z,y); y uses union center of native bridge+truss.
    stations=[
        (-20.32,.93),(-18.2,1.0),(-12.1,.97),
        (-5.4,1.0),(0,1.01),(5.4,1.0),
        (12.1,.97),(18.2,1.0),(20.32,.93),
    ]
    verts=[]
    for x,scale in stations:
        for z,y in profile:
            verts.append((x,y*scale+.22,z+.25))
    n=len(profile)
    faces=[]
    for layer in range(len(stations)-1):
        for i in range(n):
            j=(i+1)%n
            a=layer*n+i
            b=layer*n+j
            c=(layer+1)*n+j
            d=(layer+1)*n+i
            faces.extend(((a,b,c),(a,c,d)))
    for i in range(1,n-1):
        faces.append((0,i+1,i))
        last=(len(stations)-1)*n
        faces.append((last,last+i,last+i+1))
    art.add("ForgedContinuousSweptTransitDeck","ARMOR",verts,faces)

    # Long open-framed lower girder follows the authored nonphysical
    # LowerTruss at y=-2.1, z=-2.925 (union-centered).
    for side in (-1,1):
        art.beveled_block("UnderdeckHollowRail%s"%side,"BRUSHED",
                          0,-2.12,-2.96+side*.35,34.65,.38,.18,.07)
        art.rod("ContinuousDiagonalCounterChord%s"%side,"ALLOY",
                (-17.1,-2.16,-3.23+side*.13),
                (17.1,-2.16,-3.23+side*.13),.10,10)
    for j in range(11):
        x=-15.8+j*3.16
        art.rod("OpenAngledUndercarriageWeb%02d"%j,"ALLOY",
                (x-.88,-2.31,-3.17),
                (x+.88,-1.72,-2.89),.09,8)
        art.rod("BackOpposedStrut%02d"%j,"GRIP",
                (x-.70,-1.86,-3.21),(x+.68,-2.24,-2.75),.065,8)
        art.beveled_block("StampedBracketPlate%02d"%j,"CARBON",
                          x,-1.85,-2.80,.40,.30,.27,.06)

    # Real lane relief, strips and cast ribs are independent geometry,
    # not a painted 2D plane with false shading.
    for i in range(9):
        x=-17.6+i*4.4
        art.beveled_block("RecessedLaneTractionModule%02d"%i,"GRIP",
                          x,2.38,.24,2.85,.10,3.82,.10)
        for side in (-1,1):
            art.beveled_block("DiecastLateralDeckHinge%s_%02d"%(side,i),
                              "BRUSHED",x,1.66,side*2.93+.25,
                              .44,.50,.26,.06)

    for side in (-1,1):
        z=side*2.92+.25
        art.rod("LongitudinalHollowSafetyHandrail%s"%side,"ALLOY",
                (-19.4,2.12,z),(19.4,2.12,z),.12,10)
        art.beveled_block("CeramicContinuousSideStripe%s"%side,"CERAMIC",
                          0,2.37,side*2.56+.25,38.6,.045,.12,.022)
        for index in range(7):
            x=-17.4+index*5.8
            art.rod("ForgedRailGuardPost%s_%s"%(side,index),"BRUSHED",
                    (x,.68,z),(x,2.09,z),.087,8)

    for x in (-19.5,19.5):
        art.beveled_block("OriginalEndConnection%s"%x,"CARBON",
                          x,.42,.25,.64,2.70,5.80,.18)
        art.beveled_block("RetainedCeramicAnchor%s"%x,"CERAMIC",
                          x,2.30,-2.33,.38,.14,.46,.05)

    for i in range(12):
        x=-17.75+i*3.22
        art.beveled_block("InsetOriginalServiceStatus%02d"%i,"SIGNAL",
                          x,2.44,-2.25,.49,.024,.13,.018)


def export(path: Path):
    art=Sculpture()
    art.lines[0]="# Original source 3D Towers suspended forged span"
    art.lines[2]="o ChaosOriginalTowersForgedBridge"
    continuous_bridge(art)
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    assert art.materials==set(MATERIALS),art.materials
    assert 35<=art.groups<=250 and 1400<=art.triangles<=9000,(art.groups,art.triangles)
    assert 40.3<=dims[0]<=40.9,dims
    assert 4.45<=dims[1]<=5.15,dims
    assert 6.30<=dims[2]<=6.90,dims
    # Native union midpoint is at +37.7 y and -.275 z relative to arena
    # signature origin; authored geometry is centered on that exact volume.
    for a,b in zip(art.minimum,art.maximum):
        assert abs((a+b)/2)<.28,(art.minimum,art.maximum)
    source="\n".join(art.lines)+"\n"
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(source,encoding="utf-8")
    return {
        "asset":NAME,"triangles":art.triangles,"groups":art.groups,
        "vertices":art.vertices,"materials":sorted(art.materials),
        "bounds":dims,"min":art.minimum,"max":art.maximum,
        "sha256":hashlib.sha256(source.encode()).hexdigest(),
    }


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))


if __name__=="__main__":
    main()
