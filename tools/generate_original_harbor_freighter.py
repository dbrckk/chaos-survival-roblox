#!/usr/bin/env python3
"""Original Harbor's 88-stud ocean freighter, authored as seven real 3D meshes.

Art scale is 1:3.5 for the importer (<30-stud sculptor limit); runtime
scales the approved Model to the server's genuine 88-stud static silhouette.
No platform, physics, animation or sound. Not a renamed skyfleet spaceship.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

NAME="harbor_freighter"
SCALE=3.5


def hull(art: Sculpture):
    # Non-rectangular, closed tapered displacement hull with deck sheer.
    stations=[
        (-14.65,1.25,-.60),(-13.5,2.75,-.54),(-11.9,3.05,-.53),
        (-6.0,3.15,-.53),(0,3.20,-.54),(7.2,3.18,-.53),
        (11.0,3.0,-.50),(13.0,2.10,-.46),(14.6,.48,-.36),
    ]
    ring=[]
    for x,w,top in stations:
        ring.extend([(x,top,-w),(x,top,w),
                     (x,top-1.0,w*.91),(x,top-1.75,w*.70),
                     (x,top-2.05,0),(x,top-1.75,-w*.70),
                     (x,top-1.0,-w*.91)])
    faces=[]
    for k in range(len(stations)-1):
        for j in range(7):
            a=k*7+j;b=k*7+(j+1)%7;c=(k+1)*7+(j+1)%7;d=(k+1)*7+j
            faces.extend(((a,b,c),(a,c,d)))
    for j in range(1,6):
        faces.append((0,j+1,j))
        end=(len(stations)-1)*7
        faces.append((end,end+j,end+j+1))
    art.add("NineStationChinedDisplacementHull","ARMOR",ring,faces)


def create():
    art=Sculpture()
    art.lines[0]="# Chaos Survival original Storm Harbor working cargo freighter"
    art.lines[2]="o ChaosOriginalHarborContainerFreighter"
    hull(art)
    art.beveled_block("RaisedCargoDeck","BRUSHED",
                      0,-.38,0,25.4,.32,5.45,.20)
    art.beveled_block("LongitudinalKeel","CARBON",
                      -.45,-2.46,0,23.6,.23,1.0,.15)
    for side in (-1,1):
        art.beveled_block("ChinedWaterlineArmor"+str(side),"ALLOY",
                          0,-1.40,side*2.85,24.4,.23,.16,.045)
        art.beveled_block("Gunwale"+str(side),"BRUSHED",
                          0,-.04,side*2.89,25.5,.22,.24,.06)
        for x in (-10,-6,-2,2,6,10):
            art.rod("CargoRailStanchion_%s_%s"%(side,x),"ALLOY",
                    (x,-.03,side*2.9),(x,.65,side*2.9),.042,8)
        art.rod("RailHandline"+str(side),"ALLOY",
                (-11.5,.65,side*2.9),(11.5,.65,side*2.9),.044,8)
    # Five distinct stacked container bays, each with real corner
    # castings, recessed doors, corrugated roof and non-flat roof ridges.
    for bay in range(5):
        x=-4.75+bay*3.5
        for side in (-1,1):
            z=side*1.28
            for level in range(2):
                y=.36+level*1.34
                tag=f"{bay}_{side}_{level}"
                art.beveled_block("ISOContainerBody"+tag,"CERAMIC",
                                  x,y,z,3.17,1.22,2.31,.12)
                art.beveled_block("ISOContainerDoor"+tag,"CARBON",
                                  x+1.60,y,z,.07,1.01,2.09,.03)
                for rib in range(3):
                    art.beveled_block("StampedContainerRib"+tag+"_"+str(rib),
                                      "ALLOY",x-.93+rib*.92,y,
                                      z+side*1.167,.07,.93,.055,.02)
                for cx in (-1,1):
                    art.beveled_block("Twistlock"+tag+"_"+str(cx),"GRIP",
                                      x+cx*1.48,y-.53,z+side*.98,
                                      .14,.12,.14,.03)
    # Original bridge, canted windscreen, roof, navigation radar,
    # exhaust, two enclosed ventilation pods and safety strips.
    art.beveled_block("AftercastleBridgeBase","BRUSHED",
                      -10.6,1.15,0,5.2,3.4,4.85,.35)
    art.beveled_block("CommandBridgeGlazing","CARBON",
                      -10.2,3.15,0,4.4,1.24,5.12,.30)
    art.beveled_block("CommandBridgeRoof","ARMOR",
                      -10.2,3.96,0,5.1,.31,5.5,.22)
    art.beveled_block("Stack","ARMOR",
                      -12.0,4.92,-.95,1.65,2.05,1.45,.24)
    art.beveled_block("StackRim","CARBON",
                      -12.0,6.01,-.95,1.91,.23,1.66,.09)
    art.rod("RadarMast","ALLOY",(-10.1,4.15,1.4),(-10.1,7.12,1.4),.075,10)
    art.rod("RadarBoom","BRUSHED",(-11.5,6.86,1.4),(-8.8,6.86,1.4),.065,8)
    for side in (-1,1):
        art.beveled_block("PortStarboardSafetyStripe"+str(side),"SIGNAL",
                          -10.35,3.13,side*2.62,2.2,.13,.085,.025)
        art.beveled_block("VentilationBlower"+str(side),"GRIP",
                          -7.3,.66,side*2.15,1.45,.65,.75,.14)
    assert set(art.materials)==set(MATERIALS)
    assert 115<=art.groups<=220,art.groups
    assert 3700<=art.triangles<=8500,art.triangles
    return art


def export(path: Path):
    art=create()
    dims=[round(art.maximum[i]-art.minimum[i],4) for i in range(3)]
    assert 28.8<=dims[0]<=29.4,dims
    assert 9.3<=dims[1]<=10.4,dims
    assert 6.1<=dims[2]<=6.6,dims
    path.parent.mkdir(parents=True,exist_ok=True)
    obj="\n".join(art.lines)+"\n"
    path.write_text(obj,encoding="utf-8")
    return {"asset":NAME,"groups":art.groups,"triangles":art.triangles,
            "vertices":art.vertices,"materials":sorted(art.materials),
            "dimensions":dims,"runtime_scale":SCALE,
            "sha256":hashlib.sha256(obj.encode()).hexdigest()}


if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--output",required=True,type=Path)
    a=p.parse_args()
    print(json.dumps(export(a.output),sort_keys=True))
