#!/usr/bin/env python3
"""Original two-sided open-air broadcast fin for Chaos Survival Classic.

A single source fits the four native ClassicBroadcastFin Parts, rotating 90
degrees on the two Z-aligned specimens. Their independent Glow strips remain
visible within the recessed middle. Seven MATERIAL groups / no Roblox Part.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NAME = "variant_classic_sculpted_broadcast_fin"
BOUNDS = (5.46, 15.92, 1.76)


def aero_cheek(art: Sculpture, side: int):
    """Continuous swept 10-sided nonrectangular airfoil, each side of glow."""
    # x half-width, z-centered and overall thickness vary with height,
    # creating a real sculpted, high-relief ribbed profile.
    rings = [
        (-7.46, 2.28, .51, .24),
        (-5.42, 2.42, .58, .26),
        (-2.25, 2.20, .57, .21),
        (1.20, 2.33, .60, .23),
        (4.10, 2.07, .56, .21),
        (6.56, 2.31, .61, .25),
        (7.36, 1.90, .53, .18),
    ]
    # Convex decagonal cross section in local x,z (no degenerate faces).
    profile = [
        (-.94,-.40),(-.69,-.94),(0,-1.0),
        (.69,-.94),(.94,-.40),(.94,.40),
        (.69,.94),(0,1.0),(-.69,.94),(-.94,.40),
    ]
    verts=[]
    for y,halfX,centerZ,halfZ in rings:
        for px,pz in profile:
            verts.append((px*halfX,y,
                          side*(centerZ+pz*halfZ)))
    n=len(profile)
    faces=[]
    for k in range(len(rings)-1):
        for j in range(n):
            nj=(j+1)%n
            a=k*n+j
            b=k*n+nj
            c=(k+1)*n+nj
            d=(k+1)*n+j
            faces.extend(((a,b,c),(a,c,d)))
    for j in range(1,n-1):
        faces.append((0,j+1,j))
        last=(len(rings)-1)*n
        faces.append((last,last+j,last+j+1))
    art.add("SweptAerodynamicBroadcastCheek"+("Front" if side>0 else "Rear"),
            "ARMOR",verts,faces)


def make() -> Sculpture:
    art=Sculpture()
    art.lines[0]="# Chaos Survival — original sculpted Classic broadcast fin"
    art.lines[2]="o ChaosOriginalClassicBroadcastFin"

    for side in (-1,1):
        aero_cheek(art,side)

    # The base and crown determine the exact 5.46 x 15.92 x 1.76 envelope.
    # They are beveled castings with sculpted bridge slits, not default Parts.
    art.beveled_block("MachinedLowerTransmissionFoundation","BRUSHED",
                      0,-7.76,0,5.46,.40,1.76,.19)
    art.beveled_block("MachinedCrownWindDeflector","BRUSHED",
                      0,7.76,0,5.46,.40,1.76,.19)
    art.beveled_block("CarbonInsetLowerChannel","CARBON",
                      0,-7.45,0,4.75,.17,1.38,.10)
    art.beveled_block("CarbonInsetUpperChannel","CARBON",
                      0,7.45,0,4.75,.17,1.38,.10)

    for side in (-1,1):
        # An internal open vertical signaling corridor at z=0 keeps the
        # existing 10-stud decorative light independently legible.
        z=side*.81
        art.rod("ForgedOuterAeroRib_%s"%side,"ALLOY",
                (-2.30,-7.25,z),(2.17,7.14,z),.055,10)
        art.rod("OpposedTensionRib_%s"%side,"GRIP",
                (2.28,-7.26,z),(-2.06,7.12,z),.047,10)
        for step in range(5):
            y=-5.72+step*2.82
            art.beveled_block("InsetAccessPanel_%s_%02d"%(side,step),
                              "CARBON",0,y,side*.825,
                              3.45,1.58,.10,.034)
            for xsign in (-1,1):
                art.beveled_block(
                    "ForgedCableAnchor_%s_%02d_%s"%(side,step,xsign),
                    "CERAMIC",xsign*1.79,y,side*.83,
                    .36,.46,.08,.023)
            art.beveled_block("TelemetryChannel_%s_%02d"%(side,step),
                              "SIGNAL",0,y,side*.871,
                              2.35,.19,.018,.006)
        for i in range(10):
            y=-6.65+i*1.47
            x=(-1 if i%2 else 1)*1.96
            art.rod("OuterDiagonalStitch_%s_%02d"%(side,i),
                    "ALLOY",(x,y,side*.68),
                    (x*.65,y+.71,side*.79),.044,8)
        for x in (-2.23,2.23):
            art.rod("LongitudinalDielectricRace_%s_%s"%(side,x),"GRIP",
                    (x,-6.76,side*.68),(x,6.82,side*.68),.046,10)

    # Visible open mechanical transverse ribs and embossed terminal marks;
    # these always stay inside the native rectangular cosmetic footprint.
    for i in range(7):
        y=-6.2+i*2.06
        art.beveled_block("PorcelainMidspanCableClamp_%02d"%i,
                          "CERAMIC",0,y,0,4.19,.20,.20,.05)
        for direction in (-1,1):
            art.beveled_block(
                "EmbeddedFrequencyTick_%02d_%s"%(i,direction),
                "SIGNAL",direction*2.05,y+.20,0,.19,.34,.27,.048)

    for x in (-2.30,2.30):
        for y in (-7.17,7.17):
            art.beveled_block("TensionBolt_%s_%s"%(x,y),"ALLOY",
                              x,y,0,.29,.25,.40,.065)
    return art


def export(path: Path) -> dict:
    art=make()
    raw="\n".join(art.lines)+"\n"
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    center=[round((art.maximum[i]+art.minimum[i])*.5,5) for i in range(3)]
    if set(art.materials)!=set(MATERIALS):
        raise ValueError("Seven original material groups required")
    if not (1300<=art.triangles<=15000 and 50<=art.groups<=400):
        raise ValueError(("Source complexity outside validated envelope",
                          art.triangles,art.groups))
    if any(abs(a-b)>.07 for a,b in zip(dims,BOUNDS)):
        raise ValueError(("Incorrect exact Classic fin footprint",dims))
    if max(abs(c) for c in center)>.06:
        raise ValueError(("Classic source union is not centered",center))
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(raw,encoding="utf-8")
    return {"asset":NAME,"triangles":art.triangles,
            "groups":art.groups,"vertices":art.vertices,
            "materials":sorted(art.materials),"bounds":dims,
            "center":center,"sha256":hashlib.sha256(raw.encode()).hexdigest()}


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))
