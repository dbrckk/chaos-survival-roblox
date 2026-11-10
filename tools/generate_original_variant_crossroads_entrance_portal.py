#!/usr/bin/env python3
"""One original, open 3D signal portal for four Crossroads entrance gates.

Replaces each decorative CrossroadGate and the pair of CrossroadPost
Parts (3 native solids per gate). Keeps an unobstructed 15-stud opening
and the original luminous header silhouette. Seven separate PBR groups.
Local origin is 4.7 studs BELOW the native gate's center.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NAME = "variant_crossroads_sculpted_entrance_portal"
ENVELOPE = (19.2, 10.6, 1.72)


def sculpt_column(art: Sculpture, side: int):
    """Eleven-sided changing-radius forged jamb, not stacked box Parts."""
    n=12
    profiles=[
        (-5.20,.68,.65),
        (-4.25,.72,.69),
        (-1.50,.60,.59),
        (1.25,.65,.62),
        (3.65,.56,.58),
        (4.54,.71,.66),
    ]
    verts=[]
    for y,sx,sz in profiles:
        for i in range(n):
            theta=math.tau*i/n
            verts.append((side*8.5+sx*math.cos(theta),
                          y,sz*math.sin(theta)))
    faces=[]
    for j in range(len(profiles)-1):
        for i in range(n):
            other=(i+1)%n
            a=j*n+i
            b=j*n+other
            c=(j+1)*n+other
            d=(j+1)*n+i
            faces.extend(((a,b,c),(a,c,d)))
    for i in range(1,n-1):
        faces.extend(((0,i+1,i),
                     ((len(profiles)-1)*n,
                      (len(profiles)-1)*n+i,
                      (len(profiles)-1)*n+i+1)))
    art.add("TaperedForgedGateJamb"+str(side),"ARMOR",verts,faces)


def sculpt_beam(art: Sculpture):
    """Genuine swept octagonal truss rail, variable thickness along X."""
    outline=[
        (-.54,-.55),(-.30,-.75),(.26,-.75),(.56,-.48),
        (.56,.48),(.26,.75),(-.30,.75),(-.54,.55),
    ]
    stations=[
        (-9.10,.91),(-7.9,1),(-4.6,.95),(0,1),
        (4.6,.95),(7.9,1),(9.10,.91),
    ]
    verts=[]
    for x,stretch in stations:
        for y,z in outline:
            verts.append((x,4.70+y*stretch,z*stretch))
    n=len(outline)
    faces=[]
    for j in range(len(stations)-1):
        for i in range(n):
            k=(i+1)%n
            a=j*n+i
            b=j*n+k
            c=(j+1)*n+k
            d=(j+1)*n+i
            faces.extend(((a,b,c),(a,c,d)))
    for i in range(1,n-1):
        faces.extend(((0,i+1,i),((len(stations)-1)*n,
                      (len(stations)-1)*n+i,
                      (len(stations)-1)*n+i+1)))
    art.add("VariableThicknessOpenHeader","BRUSHED",verts,faces)


def build() -> Sculpture:
    a=Sculpture()
    a.lines[0]="# Original Chaos Survival Crossroads four-gate industrial portal"
    a.lines[2]="o ChaosOriginalCrossroadsInteriorPortal"
    sculpt_beam(a)
    for side in (-1,1):
        sculpt_column(a,side)
        x=side*8.5
        # Edge castings define an exactly centered 19.2-stud envelope.
        a.beveled_block("ExteriorMooringFoot%s"%side,"ALLOY",
                        x,-5.05,0,2.2,.50,1.72,.16)
        a.beveled_block("HeaderShoulder%s"%side,"BRUSHED",
                        x,4.83,0,2.2,.92,1.72,.22)
        a.beveled_block("RecessedJambCarbonLiner%s"%side,"CARBON",
                        x-side*.74,-.22,-.73,.14,7.8,.13,.033)
        a.rod("ForgedJambTensionSpar%s"%side,"GRIP",
              (x-side*.43,-4.74,-.48),
              (x-side*.43,4.2,-.48),.085,10)
        a.rod("TaperedJambSecondarySpar%s"%side,"ALLOY",
              (x+side*.30,-4.48,.45),
              (x+side*.52,4.25,.42),.08,10)
        for i in range(5):
            y=-3.76+i*1.67
            a.beveled_block("JambCeramicBand%s_%02d"%(side,i),
                            "CERAMIC",x,y,.63,1.19,.31,.13,.04)
            a.beveled_block("RecessedJambTelemetry%s_%02d"%(side,i),
                            "SIGNAL",x,y,.72,.63,.15,.08,.026)
            a.rod("CantedTorsionBrace%s_%02d"%(side,i),"GRIP",
                  (x-side*.37,y-.55,-.55),
                  (x+side*.24,y+.52,-.60),.055,8)
        for j in range(3):
            y=-3.2+j*3.2
            a.beveled_block("JambServicePort%s_%02d"%(side,j),
                            "CARBON",x+side*.56,y,0,
                            .17,1.16,.65,.05)
    # Top rail has actual depth, metal framing and repeated die-cast
    # modules; the neon signal line is sculpted, not an untextured Part.
    for side in (-1,1):
        z=side*.82
        a.beveled_block("ContinuousSignalChannel%s"%side,"CARBON",
                        0,4.68,z,16.7,.38,.08,.032)
        a.beveled_block("ContinuousPulseStrip%s"%side,"SIGNAL",
                        0,4.69,z+side*.04,16.12,.11,.035,.01)
        for i in range(7):
            x=-7.03+i*2.35
            a.beveled_block("CrownedRailBearing%s_%02d"%(side,i),
                            "CERAMIC",x,5.09,side*.60,
                            .41,.17,.25,.055)
            a.rod("DiagonalSuspensionWeb%s_%02d"%(side,i),
                  "ALLOY",(x-.66,4.12,side*.59),
                  (x+.61,5.07,side*.58),.052,10)
    for i in range(9):
        x=-7.6+i*1.9
        a.beveled_block("MachinedDataCartridge%02d"%i,
                        "CARBON",x,4.19,-.68,1.17,.18,.12,.045)
        a.beveled_block("DataCartridgePulse%02d"%i,
                        "SIGNAL",x,4.19,-.76,.67,.08,.035,.01)
    return a


def export(path:Path) -> dict:
    art=build()
    raw="\n".join(art.lines)+"\n"
    bounds=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    center=[round((art.maximum[i]+art.minimum[i])*.5,5) for i in range(3)]
    if set(art.materials)!=set(MATERIALS):
        raise ValueError(("Missing approved material groups",art.materials))
    if not 1600<=art.triangles<=16000 or not 60<=art.groups<=380:
        raise ValueError(("Unexpected triangle/group budget",
                          art.triangles,art.groups))
    if any(abs(v-e)>.12 for v,e in zip(bounds,ENVELOPE)):
        raise ValueError(("Unexpected 3D portal bounds",bounds,ENVELOPE))
    if max(abs(x) for x in center)>.08:
        raise ValueError(("Portal local origin no longer centered",center))
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(raw,encoding="utf8")
    return {"asset":NAME,"triangles":art.triangles,"groups":art.groups,
            "vertices":art.vertices,"materials":sorted(art.materials),
            "bounds":bounds,"center":center,
            "sha256":hashlib.sha256(raw.encode()).hexdigest()}


if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--output",type=Path,required=True)
    a=p.parse_args()
    print(json.dumps(export(a.output),sort_keys=True))
