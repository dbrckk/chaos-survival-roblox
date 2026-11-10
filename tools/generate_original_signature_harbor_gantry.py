#!/usr/bin/env python3
"""Original Harbor sculpted port crane with authentic cabin and counterweight.

Replaces three enormous nonphysical primitive Parts of Harbor's northern
signature landmark; leaves playable docks, rope hoists and lifting legs intact.
True triangulated mesh, original seven industrial PBR materials.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NAME="signature_harbor_sculpted_gantry"


def swept_beam(art: Sculpture):
    """Closed forged 14-corner X-extrusion, not a rectangular Part."""
    # Source centered on union of three exact original Harbor shapes:
    # original world-local Y 36.8..50.9, Z -2.6..6.5.
    # Model-local center therefore Y43.85, Z1.95.
    yz=[
        (-1.34,-3.96),(-1.25,-4.10),(-.98,-4.14),
        (-.52,-4.06),(.30,-3.84),(.67,-3.40),
        (.69,-.31),(.35,.22),(-.25,.21),
        (-.55,-.12),(-1.04,-.19),(-1.40,-.60),
        (-1.43,-2.45),(-1.36,-3.12),
    ]
    stations=[(-20.40,.97),(-17.1,1.0),(-9.3,.99),
              (0,1.0),(9.3,.99),(17.1,1.0),(20.40,.97)]
    vertices=[]
    for x,scale in stations:
        for y,z in yz:
            vertices.append((x,y*scale,z*scale))
    n=len(yz)
    faces=[]
    for k in range(len(stations)-1):
        for i in range(n):
            a=k*n+i
            b=k*n+(i+1)%n
            c=(k+1)*n+(i+1)%n
            d=(k+1)*n+i
            faces.extend(((a,b,c),(a,c,d)))
    for i in range(1,n-1):
        faces.append((0,i+1,i))
        last=(len(stations)-1)*n
        faces.append((last,last+i,last+i+1))
    art.add("SweptSeventySixFacetForgeCraneGirder","ARMOR",vertices,faces)


def make() -> Sculpture:
    art=Sculpture()
    art.lines[0]="# Original Chaos Survival Harbor port mega-crane"
    art.lines[2]="o ChaosOriginalSignatureHarborGantry"
    swept_beam(art)
    # Deep open lattice on both sides of the overhead crane.
    for side in (-1,1):
        z=-1.95+side*1.88
        art.rod("ContinuousForgedCraneChord%s"%side,"ALLOY",
                (-19.65,.48,z),(19.65,.48,z),.13,10)
        art.rod("ShadowedUnderslungCraneRail%s"%side,"CARBON",
                (-19.2,-1.36,z),(19.2,-1.36,z),.10,10)
        for k in range(11):
            x=-18.2+k*3.64
            art.rod("TriangulatedGantryWeb%s_%02d"%(side,k),"BRUSHED",
                    (x-.94,-1.21,z),(x+.94,.46,z),.085,8)
            art.rod("CounterbracedGantryWeb%s_%02d"%(side,k),"GRIP",
                    (x-.72,.38,z),(x+.72,-1.12,z),.053,8)
    # Real sculpted enclosed counterweight: original x=-10,y48,z3.0;
    # source relative center=-10,+4.15,+1.05.
    art.beveled_block("ContinuousCounterweightCore","ARMOR",
                      -10,4.12,1.05,6.82,5.73,6.78,.29)
    art.beveled_block("FramedCounterweightOuterShell","BRUSHED",
                      -10,4.13,4.42,5.98,5.03,.18,.07)
    art.beveled_block("CounterweightProtectiveCarbonSpine","CARBON",
                      -10,4.22,-2.36,5.24,4.13,.14,.05)
    for k in range(7):
        x=-12.66+k*.89
        art.beveled_block("MilledCounterbalanceCoolingFin%02d"%k,"GRIP",
                          x,4.28,4.51,.42,3.77,.052,.02)
    for k in range(4):
        x=-12.22+k*1.46
        art.beveled_block("CeramicCounterweightClamp%02d"%k,"CERAMIC",
                          x,6.96,2.42,.40,.095,1.21,.042)
        art.rod("CounterweightRetainedBolt%02d"%k,"ALLOY",
                (x,6.65,-.58),(x,6.98,-.58),.079,8)

    # Separate glazed/forged control cab: x=4.8,y=39.5,z=0,
    # source-relative cabin center=(4.8,-4.35,-1.95).
    art.beveled_block("ClosedPilotHouseFraming","BRUSHED",
                      4.8,-4.39,-1.95,7.00,5.28,5.00,.23)
    art.beveled_block("RecessedCockpitGlassLamination","CARBON",
                      4.8,-4.43,-4.48,6.01,3.77,.08,.035)
    art.beveled_block("ProtectedForwardVisor","CERAMIC",
                      4.8,-6.98,-2.05,6.44,.11,4.74,.045)
    for side in (-1,1):
        x=4.8+side*3.28
        art.beveled_block("SideCabinFlangedGlazing%s"%side,"CARBON",
                          x,-4.30,-1.93,.12,3.30,3.82,.037)
        art.rod("ForgedPilotCabinAFrame%s"%side,"ALLOY",
                (x,-6.75,-4.22),(x,-2.18,-4.22),.090,8)
    for k in range(4):
        x=2.45+k*1.56
        art.rod("FrontCabinWindshieldStrut%02d"%k,"ALLOY",
                (x,-6.34,-4.52),(x,-2.39,-4.53),.075,8)

    # Shock-isolated crane hoist attachment/hardpoints, not the existing
    # active hoist lines which must remain native for visual readability.
    for x in (-17.0,-8.5,0,8.5,17.0):
        art.beveled_block("OverheadHoistLoadCassette%s"%x,"CARBON",
                          x,-1.37,-1.93,.89,.24,3.21,.08)
        art.beveled_block("StampedSecondaryTiePlate%s"%x,"CERAMIC",
                          x,.74,-1.96,.44,.07,2.02,.025)
    for i in range(10):
        x=-17.9+i*3.98
        art.beveled_block("RecessedPortSignalIndicator%02d"%i,"SIGNAL",
                          x,.749,-3.60,.56,.035,.16,.022)
    return art


def export(output: Path):
    art=make()
    raw="\n".join(art.lines)+"\n"
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    assert art.materials==set(MATERIALS),art.materials
    assert 60<=art.groups<=260 and 1800<=art.triangles<=10000,(art.groups,art.triangles)
    assert 40.5<=dims[0]<=41.05,dims
    assert 13.85<=dims[1]<=14.35,dims
    assert 8.75<=dims[2]<=9.30,dims
    center=[(art.minimum[i]+art.maximum[i])*.5 for i in range(3)]
    assert all(abs(v)<.25 for v in center),(dims,center)
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(raw,encoding="utf-8")
    return {
        "asset":NAME,"triangles":art.triangles,
        "groups":art.groups,"vertices":art.vertices,
        "materials":sorted(art.materials),
        "bounds":dims,"center":center,
        "sha256":hashlib.sha256(raw.encode()).hexdigest(),
    }


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))


if __name__=="__main__":
    main()
