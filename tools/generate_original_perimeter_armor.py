#!/usr/bin/env python3
"""Two authored sculptural armor components for real Chaos perimeter stations.

Uses the existing owned industrial palette and source-triangulation pipeline.
Neither model is a Roblox Part mock or a downloaded third-party mesh.
Model asset IDs are assigned ONLY after Open Cloud approval.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

PROFILES = {
    "perimeter_wing": (3.36, 1.64, 5.62),
    "perimeter_cap": (2.84, 2.14, 2.34),
}


def hull(art: Sculpture, w: float, h: float, d: float):
    """Watertight segmented swept steel casting with a rising roof profile."""
    levels = (-.50, -.22, .19, .50)
    verts = []
    for z_ratio in levels:
        top = (-.16 + .66*(z_ratio+.5))*h
        bottom = -.50*h
        taper = 1.0 - .13*abs(z_ratio)
        x = .50*w*taper
        bevel = min(w*.095, h*.14)
        yz = [
            (-x+bevel,top), (x-bevel,top),
            (x,top-bevel), (x,bottom+bevel),
            (x-bevel,bottom),(-x+bevel,bottom),
            (-x,bottom+bevel),(-x,top-bevel),
        ]
        verts.extend((xx,yy,z_ratio*d) for xx,yy in yz)
    faces = []
    n=8
    for layer in range(len(levels)-1):
        for i in range(n):
            a=layer*n+i
            b=layer*n+(i+1)%n
            c=(layer+1)*n+(i+1)%n
            e=(layer+1)*n+i
            faces.extend(((a,b,c),(a,c,e)))
    for i in range(1,n-1):
        faces.append((0,i+1,i))
        back=(len(levels)-1)*n
        faces.append((back,back+i,back+i+1))
    art.add("ClosedSweptDiecastArmorHull", "ARMOR", verts, faces)


def build(profile: str) -> Sculpture:
    if profile not in PROFILES:
        raise ValueError("Unknown original station armor profile")
    w,h,d=PROFILES[profile]
    art=Sculpture()
    art.lines[0]="# Original Chaos Survival sculpted perimeter "+profile
    art.lines[2]="o ChaosOriginal_"+profile
    hull(art,w,h,d)

    # True closed metallic fittings, physically embedded into the swept
    # casting, not a flat on-top texture or a native rectangular substitute.
    for side in (-1,1):
        x=side*w*.365
        art.beveled_block("CastSideWearCassette"+str(side),"BRUSHED",
                          x,-h*.26,0,w*.135,h*.21,d*.76,w*.028)
        art.beveled_block("InsetHeatVentCarrier"+str(side),"CARBON",
                          side*w*.29,h*.08,-d*.05,w*.13,h*.12,d*.54,.055)
        art.rod("AngularForgedLoadRib"+str(side),"ALLOY",
                (side*w*.315,-h*.27,-d*.38),
                (side*w*.315,h*.08,d*.32),w*.035,10)
        for k in range(3):
            z=(-.27+k*.27)*d
            art.beveled_block("RecessedCoolingLouver_%s_%s"%(side,k),
                              "GRIP",side*w*.34,h*.035,z,
                              w*.052,h*.095,d*.12,.028)

    # Broken-up roof profile, mechanical ceramic fin and recessed inset.
    art.beveled_block("DiamondHeatReflector", "CERAMIC",
                      0,h*.13,d*.20,w*.58,h*.07,d*.22,.07)
    art.beveled_block("RecessedUpperTelemetry", "SIGNAL",
                      0,h*.155,d*.18,w*.33,h*.019,d*.07,.015)
    for n in (-1,1):
        art.rod("RetainedServicePin"+str(n),"ALLOY",
                (n*w*.27,-h*.28,-d*.365),
                (n*w*.27,-h*.17,-d*.365),w*.036,10)
    # Closed rear protective grommet under the sloping service roof.
    art.beveled_block("RearProtectedServiceSocket", "CARBON",
                      0,-h*.24,d*.36,w*.37,h*.14,d*.12,.055)

    dims=[round(art.maximum[i]-art.minimum[i],4) for i in range(3)]
    assert set(art.materials)==set(MATERIALS),art.materials
    assert 16<=art.groups<=65,art.groups
    assert 500<=art.triangles<=3200,art.triangles
    assert dims[0]>=w*.86 and dims[0]<=w*1.03,dims
    assert dims[1]>=h*.90 and dims[1]<=h*1.04,dims
    assert dims[2]>=d*.96 and dims[2]<=d*1.03,dims
    return art


def export(profile: str, output: Path):
    art=build(profile)
    data="\n".join(art.lines)+"\n"
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(data,encoding="utf-8")
    return {
        "asset":profile,"triangles":art.triangles,
        "groups":art.groups,"vertices":art.vertices,
        "materials":sorted(art.materials),
        "bounds_min":art.minimum,"bounds_max":art.maximum,
        "dimensions":[round(art.maximum[i]-art.minimum[i],4) for i in range(3)],
        "sha256":hashlib.sha256(data.encode()).hexdigest(),
    }


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--model",choices=PROFILES,required=True)
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.model,args.output),sort_keys=True))

if __name__=="__main__":
    main()
