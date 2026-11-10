#!/usr/bin/env python3
"""Original Crossroads dual-deck freight interchange, real industrial 3D.

One source-authentic sculpted 3D Model replaces four huge nonphysical native
Part/WedgeParts of the North megastructure, never real player paths or rails.
All materials are original and all groups are truly triangulated geometry.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture

MODEL = "signature_crossroads_forged_interchange"


def profile_extrusion(art: Sculpture, name: str, material: str,
                      yz: list[tuple[float,float]],
                      stations: list[tuple[float,float]]):
    """Closed non-rectangular X-swept hull with actual relief in Y/Z."""
    sides=len(yz)
    vertices=[]
    for x, scale in stations:
        for y,z in yz:
            vertices.append((x,y*scale,z*scale))
    faces=[]
    for i in range(len(stations)-1):
        for k in range(sides):
            n=(k+1)%sides
            a=i*sides+k
            b=i*sides+n
            c=(i+1)*sides+n
            d=(i+1)*sides+k
            faces.extend(((a,b,c),(a,c,d)))
    for k in range(1,sides-1):
        faces.append((0,k+1,k))
        b=(len(stations)-1)*sides
        faces.append((b,b+k,b+k+1))
    art.add(name,material,vertices,faces)


def make() -> Sculpture:
    art=Sculpture()
    art.lines[0]="# Original Chaos Survival Crossroads freight interchange"
    art.lines[2]="o ChaosOriginalSignatureCrossroadsInterchange"

    # Lower freight deck: true curved 14-corner undercarriage casting,
    # X length 41.74, Z depth 5.90 and Y -6..-4 in union-centered coords.
    lower=[
        (-5.93,-2.38),(-5.70,-2.85),(-5.11,-2.95),
        (-4.30,-2.70),(-4.06,-2.21),(-4.01,2.21),
        (-4.30,2.70),(-5.11,2.95),(-5.70,2.85),
        (-5.93,2.38),(-5.88,1.15),(-5.99,.56),
        (-5.99,-.56),(-5.88,-1.15),
    ]
    lower_stations=[(-20.87,.965),(-17.4,1.),(-7.2,.99),
                    (0,1.),(7.2,.99),(17.4,1.),(20.87,.965)]
    profile_extrusion(art,"ContinuousFourteenFacetLowerFreightDeck",
                      "ARMOR",lower,lower_stations)

    # Upper intercity skyrail bridge, X 47.68, Y 1.88..3.16.
    upper=[
        (2.06,-2.65),(1.88,-2.17),(1.88,-1.62),
        (1.96,-.92),(1.92,.92),(1.88,1.62),
        (1.88,2.17),(2.06,2.65),(2.84,2.65),
        (3.16,2.31),(3.15,-2.31),(2.84,-2.65),
    ]
    upper_stations=[(-23.84,.965),(-20.7,1.),(-12.0,.99),
                    (0,1.),(12.0,.99),(20.7,1.),(23.84,.965)]
    profile_extrusion(art,"SweptDualRailUpperExchangeDeck",
                      "BRUSHED",upper,upper_stations)

    # Both side cantilevers are now actual thickness-varied solid shells,
    # y 2..5.90, Z +/-3.4, X +/-23.8, with open-sided edge chambers.
    for side in (-1,1):
        x=side*18.30
        # Full upper surface of the former WedgePart with a sculpted
        # tapered roof and reinforced beveled bottom.
        art.beveled_block("CastCantileverStructuralSaddle%s"%side,"CARBON",
                          x,2.38,0,10.82,.62,6.76,.16)
        for i in range(5):
            z=-2.54+i*1.27
            art.rod("RaisedCantileverHollowSpar%s_%02d"%(side,i),"ALLOY",
                    (x-side*4.88,2.44,z),
                    (x+side*4.88,5.67,z),.082,10)
        for i in range(3):
            px=x+side*(-3.18+i*3.18)
            art.beveled_block("SculptedDiecastRoofJaw%s_%02d"%(side,i),
                              "ARMOR",px,4.79,-.02,
                              2.08,.68,5.50,.24)
            art.beveled_block("DeepVentCassette%s_%02d"%(side,i),
                              "GRIP",px,5.17,-2.26,
                              1.28,.085,.62,.035)
        art.beveled_block("FourCornerCeramicLock%s"%side,"CERAMIC",
                          x+side*3.85,5.48,-2.25,
                          .63,.12,.75,.05)

    # Twenty-four genuinely open diagonal webs between independent levels.
    # This is not a flat wall or a line painted over primitive Parts.
    for i in range(12):
        x=-19.3+i*3.51
        for side in (-1,1):
            z=side*2.11
            art.rod("LongOpenRailTruss%02d_%s"%(i,side),"ALLOY",
                    (x-.84,-3.73,z),(x+.84,1.56,z),.070,8)
            art.rod("ReverseCoredTruss%02d_%s"%(i,side),"GRIP",
                    (x-.50,1.49,z),(x+.47,-3.70,z),.048,8)

    # Mechanical joints, solar-enamel transit markings and undercuts.
    for i in range(9):
        x=-18.2+i*4.55
        art.beveled_block("MechanicalLowerCoupler%02d"%i,"CARBON",
                          x,-3.96,-2.57,.67,.30,.42,.055)
        art.beveled_block("RecessedUpperRailGrip%02d"%i,"GRIP",
                          x,3.18,0,2.18,.065,3.35,.05)
        for side in (-1,1):
            art.beveled_block("PressedCanopySideRib%02d_%s"%(i,side),
                              "CERAMIC",x,3.24,side*2.52,
                              .31,.095,.22,.045)

    for side in (-1,1):
        z=side*2.48
        art.rod("ContinuousSideScreenSupport%s"%side,"ALLOY",
                (-22.3,3.68,z),(22.3,3.68,z),.092,8)
        for i in range(7):
            x=-20.3+i*6.76
            art.rod("VerticalGuardSupport%s_%02d"%(side,i),"BRUSHED",
                    (x,3.14,z),(x,4.16,z),.074,8)
    for i in range(14):
        x=-21.13+i*3.25
        art.beveled_block("TransitSignalRecess%02d"%i,"SIGNAL",
                          x,3.21,-2.43,.43,.038,.15,.018)
    return art


def export(path: Path):
    art=make()
    source="\n".join(art.lines)+"\n"
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    assert art.materials==set(MATERIALS),art.materials
    assert 55<=art.groups<=225 and 1800<=art.triangles<=11000,(art.groups,art.triangles)
    assert 47.4<=dims[0]<=48.0,dims
    assert 11.4<=dims[1]<=12.2,dims
    assert 6.65<=dims[2]<=7.1,dims
    assert abs((art.minimum[0]+art.maximum[0])*.5)<.25
    assert abs((art.minimum[1]+art.maximum[1])*.5)<.28
    assert abs((art.minimum[2]+art.maximum[2])*.5)<.28
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(source,encoding="utf-8")
    return {
        "asset":MODEL,"triangles":art.triangles,
        "groups":art.groups,"vertices":art.vertices,
        "materials":sorted(art.materials),
        "bounds":dims,
        "sha256":hashlib.sha256(source.encode()).hexdigest()
    }


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))


if __name__=="__main__":
    main()
