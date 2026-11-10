#!/usr/bin/env python3
"""Sculpt a truly open, forged 3D Crossroads boundary gantry (four instances).

The original 28 x 2 x 2 Part remains as a reversible fallback. This
original seven-material art sits in the same nonphysical footprint,
with an expanded 3.6-stud vertical truss and an OPEN center so the
native CrossroadSignal strip remains visible. No place/asset ID is set.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NAME = "variant_crossroads_forged_gantry"
BOUNDS = (27.92, 3.6, 2.74)


def swept_channel(art: Sculpture, name: str, material: str, sign: int):
    """Closed volume with changing chord (not a box/wedge Roblox primitive)."""
    # Polygon in the z/y plane, asymmetric forged channel with a machined
    # recessed groove. The positive/negative channel pair is mirrored.
    profile = [
        (-1.21, .33), (-1.36, .12), (-1.21, -.05),
        (-.86, -.16), (-.47, -.12), (0.0, -.23),
        (.47, -.12), (.86, -.16), (1.21, -.05),
        (1.36, .12), (1.21, .33), (0.0, .39),
    ]
    stations = [
        (-13.62,.85),(-12.8,1.0),(-9.7,.93),
        (-5.4,.98),(0,1.0),(5.4,.98),
        (9.7,.93),(12.8,1.0),(13.62,.85),
    ]
    verts = []
    for x,scale in stations:
        for z,y in profile:
            verts.append((x,sign*(1.31+y*scale),z*scale))
    faces = []
    n=len(profile)
    for j in range(len(stations)-1):
        for i in range(n):
            a=j*n+i
            b=j*n+(i+1)%n
            c=(j+1)*n+(i+1)%n
            d=(j+1)*n+i
            if sign == 1:
                faces.extend(((a,b,c),(a,c,d)))
            else:
                faces.extend(((a,c,b),(a,d,c)))
    for i in range(1,n-1):
        first=(0,i+1,i) if sign==1 else (0,i,i+1)
        last=(len(stations)-1)*n
        back=(last,last+i,last+i+1) if sign==1 else (
            last,last+i+1,last+i)
        faces.extend((first,back))
    art.add(name,material,verts,faces)


def make() -> Sculpture:
    art=Sculpture()
    art.lines[0]="# Original Chaos Survival Crossroads open forged gantry"
    art.lines[2]="o ChaosOriginalCrossroadsGantry"

    # Two truly continuous manufactured truss beams, open signal lane.
    swept_channel(art,"ContinuousForgedUpperChannel","ARMOR",1)
    swept_channel(art,"ContinuousForgedLowerKeel","BRUSHED",-1)

    # Bounding lips exactly fit 27.92 x 3.60 x 2.74 studs. These are
    # beveled volumes, NOT a replacement Roblox Part; no collider.
    for side in (-1,1):
        art.beveled_block("MachinedFullSpanWeatherFlange%s"%side,"ALLOY",
                          0,side*1.69,0,27.92,.22,2.74,.12)
        art.beveled_block("DeepInsetCarbonCableRace%s"%side,"CARBON",
                          0,side*1.29,0,26.8,.12,1.68,.05)

    # Diagonal genuine triangulated lattice keeps its center hollow and
    # shows a thick high-quality profile against the distant backdrop.
    for face in (-1,1):
        z=face*1.14
        for i in range(8):
            x=-12.3+i*3.50
            art.rod("ForgedAlternatingWeb_%s_%02d"%(face,i),"GRIP",
                    (x,-.83,z),(x+2.7,.88,z),
                    .105,10)
            art.rod("CrossstitchWeb_%s_%02d"%(face,i),"ALLOY",
                    (x+.27,.88,z),(x+2.75,-.83,z),
                    .085,10)
            art.beveled_block(
                "DieCastWebJoint_%s_%02d"%(face,i),"CERAMIC",
                x+1.35,0,face*1.24,.58,.38,.14,.05)
        for side in (-1,1):
            x=side*12.7
            art.beveled_block("EndMooringSocket_%s_%s"%(face,side),
                              "CARBON",x,0,face*.95,
                              .75,2.55,.45,.09)

    # The native 18-stud neon signal beam remains unobscured at the
    # gantry center (y=0, z=0). Edge reader lights are new real geometry.
    for i in range(11):
        x=-12+i*2.4
        for side in (-1,1):
            art.beveled_block("RecessedServiceReader_%02d_%s"%(i,side),
                              "SIGNAL",x,side*1.53,-1.08,
                              .30,.055,.24,.025)
        if i%2==0:
            art.beveled_block("CeramicConduitCover_%02d"%i,"CERAMIC",
                              x,1.43,.95,.96,.14,.30,.06)
            art.beveled_block("UnderKeelSplicePlate_%02d"%i,"CARBON",
                              x,-1.43,.95,.96,.14,.30,.06)
    # Deeply recessed tension rods below the weather lip add silhouette.
    for side in (-1,1):
        art.rod("LongitudinalOpticConduit%s"%side,"BRUSHED",
                (-13.1,side*1.06,.73),(13.1,side*1.06,.73),.065,10)
        for i in range(4):
            x=-10.4+i*6.9
            art.rod("TriangularAnchoringBolt_%s_%02d"%(side,i),"ALLOY",
                    (x,side*1.47,-.98),
                    (x+.7,side*.98,-1.14),.095,10)

    return art


def export(path: Path) -> dict:
    art=make()
    raw="\n".join(art.lines)+"\n"
    size=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    midpoint=[round((art.maximum[i]+art.minimum[i])*.5,5)
              for i in range(3)]
    if set(art.materials)!=set(MATERIALS):
        raise ValueError("Seven authored materials required")
    if not (1200 <= art.triangles <= 15000
            and 45 <= art.groups <= 400):
        raise ValueError(("Source complexity mismatch",art.groups,art.triangles))
    if any(abs(a-b)>.12 for a,b in zip(size,BOUNDS)):
        raise ValueError(("Unexpected native gantry envelope",size,BOUNDS))
    if max(abs(x) for x in midpoint)>.10:
        raise ValueError(("Gantry origin no longer centered",midpoint))
    # Keep a real open gap to preserve native CrossroadSignal near y=0.
    if "ContinuousForgedUpperChannel" not in raw or (
        "ContinuousForgedLowerKeel" not in raw):
        raise ValueError("Missing continuous hollow-channel geometry")
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(raw,encoding="utf-8")
    return {
        "asset":NAME,"triangles":art.triangles,
        "groups":art.groups,"vertices":art.vertices,
        "materials":sorted(art.materials),
        "bounds":size,"center":midpoint,
        "sha256":hashlib.sha256(raw.encode()).hexdigest(),
    }


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))
