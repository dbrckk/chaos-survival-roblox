#!/usr/bin/env python3
"""Original sculpted 28-stud shallow-draft working barge for Storm Harbor.

Seven authentic UV/tangent material MeshParts. The native near-horizon
barge hull center is (0,0,0); the existing nonphysical 28x3.5x13.2 Part
and 21x7.4x8.6 cargo box remain available as original Android Low fallback.
This script creates a real triangulated chined/fendered hull, wavecutting
bow, ISO container castings, crane anchors and an actual elevated wheelhouse.
No walkable deck or physics are created.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

NAME="harbor_midground_barge"


def create()->Sculpture:
    art=Sculpture()
    art.lines[0]="# Chaos Survival ORIGINAL near-shore Harbor 3D cargo barge"
    art.lines[2]="o ChaosHarborMidgroundCoastalFreightBarge"
    # Closed, chined 13-station displacement hull. Not a cuboid.
    stations=[
        (-14.20,2.6,-.33),(-13.55,4.52,-.32),(-12.1,5.90,-.28),
        (-9.0,6.54,-.23),(-6.2,6.64,-.21),
        (-3.2,6.65,-.21),(0,6.60,-.21),(3.3,6.6,-.22),
        (6.5,6.54,-.22),(9.5,6.40,-.25),
        (11.8,5.82,-.27),(13.6,4.10,-.27),(14.15,1.35,-.35),
    ]
    ring=[]
    for x,width,top in stations:
        ring.extend([
            (x,top,-width),(x,top,width),
            (x,-.88,width*.96),(x,-1.55,width*.76),
            (x,-1.9,0),(x,-1.55,-width*.76),
            (x,-.88,-width*.96),
        ])
    faces=[]
    for i in range(len(stations)-1):
        for k in range(7):
            a=i*7+k;b=i*7+(k+1)%7
            c=(i+1)*7+(k+1)%7;d=(i+1)*7+k
            faces.extend(((a,b,c),(a,c,d)))
    for k in range(1,6):
        faces.append((0,k+1,k))
        last=(len(stations)-1)*7
        faces.append((last,last+k,last+k+1))
    art.add("ThirteenStationChinedShallowDraftHull","ARMOR",ring,faces)
    art.beveled_block("OriginalHeavyFreightDeck","BRUSHED",
                      0,-.04,0,26.1,.35,11.6,.23)
    art.beveled_block("KeelAntiRollSpine","CARBON",
                      0,-1.92,0,24.6,.22,1.0,.14)
    for side in (-1,1):
        art.beveled_block("RubberQuayContactFender"+str(side),"GRIP",
                          -.15,-.60,side*6.40,23.6,.52,.35,.15)
        art.beveled_block("LowerWaterlineWearStrip"+str(side),"ALLOY",
                          0,-1.48,side*5.42,24.2,.12,.13,.04)
        for x in (-10,-6,-2,2,6,10):
            art.rod(f"SeaworthyRailStanchion_{side}_{x}","BRUSHED",
                    (x,.16,side*5.95),(x,1.0,side*5.95),.07,8)
        art.rod("ContinuousPerimeterRail"+str(side),"ALLOY",
                (-11.7,1.02,side*5.95),(11.7,1.02,side*5.95),.072,10)
        for x in (-10.4,10.4):
            art.beveled_block(f"WeldedTieDownBollard_{side}_{x}","GRIP",
                              x,.48,side*5.37,.52,.84,.70,.18)
            art.beveled_block(f"CleatForgedReinforcement_{side}_{x}",
                              "BRUSHED",x,.91,side*5.37,.88,.20,.85,.09)
    # The source is not a recycled freighter. A unique shallow-draft
    # two-bay harbor craft with aft wheelhouse and palletized cargo.
    art.beveled_block("CargoLowStackBed","BRUSHED",
                      0,1.1,0,20.6,.48,9.0,.12)
    for i in range(3):
        x=-6.1+i*5.9
        for side in (-1,1):
            z=side*2.14
            y=4.38
            tag=f"{i}_{side}"
            art.beveled_block("OriginalISOContainerShell"+tag,"CERAMIC",
                              x,y,z,5.5,6.72,3.85,.23)
            art.beveled_block("CargoStampedTop"+tag,"ARMOR",
                              x,7.84,z,5.65,.26,4.0,.10)
            art.beveled_block("RecessedCargoEndDoor"+tag,"CARBON",
                              x+2.82,y,z,.12,5.90,3.52,.04)
            for rib in range(4):
                xo=x-2.03+rib*1.34
                for direction in (-1,1):
                    art.beveled_block(
                        f"ForgedISOStiffener_{tag}_{rib}_{direction}","ALLOY",
                        xo,y,z+direction*1.94,.095,5.8,.095,.031)
            for direction in (-1,1):
                art.beveled_block("ContainerCornerSpreader"+tag+str(direction),
                                  "GRIP",x-2.55,7.48,
                                  z+direction*1.8,.39,.27,.35,.06)
            art.beveled_block("ContainerDangerousCargoLabel"+tag,"SIGNAL",
                              x+2.9,4.85,z,.087,.52,1.24,.03)
    # Distinctive stepped wheelhouse at aft starboard (visible side view).
    art.beveled_block("MaritimeDeckhouseRoot","BRUSHED",
                      -11.7,2.7,0,3.7,3.5,6.0,.30)
    art.beveled_block("DoubleGlazedHarborWheelhouse","CARBON",
                      -11.35,5.2,0,3.7,1.55,6.7,.24)
    art.beveled_block("OverhangingRaisedCabinRoof","ARMOR",
                      -11.30,6.13,0,4.3,.24,7.2,.14)
    for side in (-1,1):
        art.beveled_block("RedWhiteNavBand"+str(side),"SIGNAL",
                          -12.0,5.25,side*3.5,1.65,.13,.09,.03)
        art.beveled_block("WheelhouseWindowMullion"+str(side),"ALLOY",
                          -11.38,5.28,side*3.49,.13,1.23,.08,.03)
    art.rod("HarborBargeRadarMast","ALLOY",
            (-12,6.35,.8),(-12,9.15,.8),.10,10)
    art.rod("FlatEmergencyRadarBlade","BRUSHED",
            (-13.65,8.90,.8),(-10.45,8.90,.8),.12,8)
    art.beveled_block("WheelhouseRainGuard","CERAMIC",
                      -11.45,6.32,0,4.2,.16,6.8,.10)
    # A pair of physical looking mooring hooks, NOT 2D painted trim.
    for side in (-1,1):
        art.rod("MooringHawseSpoke"+str(side),"GRIP",
                (11.65,.24,side*4.3),(12.75,.70,side*3.3),.21,10)

    assert art.materials==set(MATERIALS),art.materials
    assert 110<=art.groups<=230,art.groups
    assert 2700<=art.triangles<=7500,art.triangles
    return art

def export(output:Path):
    art=create()
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    mid=[round((art.maximum[i]+art.minimum[i])*.5,5) for i in range(3)]
    assert 28.1<=dims[0]<=29.4,dims
    assert 10.4<=dims[1]<=11.6,dims
    assert 12.8<=dims[2]<=13.9,dims
    output.parent.mkdir(parents=True,exist_ok=True)
    obj="\n".join(art.lines)+"\n"
    output.write_text(obj,encoding="utf8")
    return {"asset":NAME,"triangles":art.triangles,"groups":art.groups,
            "vertices":art.vertices,"materials":sorted(art.materials),
            "size":dims,"bounds_center":mid,"bounds_min":art.minimum,
            "bounds_max":art.maximum,
            "sha256":hashlib.sha256(obj.encode()).hexdigest()}
if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))
