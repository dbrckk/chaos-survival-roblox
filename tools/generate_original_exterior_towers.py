#!/usr/bin/env python3
"""Four exact-height original 3D exterior horizon towers for Chaos Survival.

Each source is a sculpted source-verified Mesh Model, not another rectangular
Roblox Part. Never fabricate a Model/Mesh ID: upload and moderate first.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

PROFILES = {f"exterior_tower_{h}":h for h in (21,24,27,30)}


def tower_shell(art: Sculpture, h: int, center_y: float):
    # Twelve-facet closed, continuously ribbed and tapered industrial hull.
    # Coordinates are at union center, not the native shell's center. The
    # 1.2-stud visible top eave stays protected by a separate chamfered roof.
    facets=12
    verts=[]
    levels=(
        (0,3.92,3.42),
        (1.5,4.48,3.90),
        (h*.16,4.26,3.72),
        (h*.43,4.12,3.66),
        (h*.68,4.33,3.78),
        (h*.86,4.08,3.59),
        (h,3.89,3.43),
    )
    for y,rx,rz in levels:
        for i in range(facets):
            a=math.tau*i/facets
            verts.append((rx*math.cos(a),y-center_y,rz*math.sin(a)))
    triangles=[]
    for j in range(len(levels)-1):
        for k in range(facets):
            a=j*facets+k
            b=j*facets+(k+1)%facets
            c=(j+1)*facets+(k+1)%facets
            d=(j+1)*facets+k
            triangles.extend(((a,b,c),(a,c,d)))
    for k in range(1,facets-1):
        triangles.append((0,k+1,k))
        offset=(len(levels)-1)*facets
        triangles.append((offset,offset+k,offset+k+1))
    art.add("TwelveFacetStaggeredFoundryCore","ARMOR",verts,triangles)


def make(profile: str) -> Sculpture:
    if profile not in PROFILES:
        raise ValueError("Unknown authored skyline profile")
    h=PROFILES[profile]
    center_y=(h+1.2)*.5
    art=Sculpture()
    art.lines[0]="# Original Chaos Survival exterior city tower "+profile
    art.lines[2]="o ChaosOriginal_"+profile
    tower_shell(art,h,center_y)

    # Long molded roof and deeper pressed eaves are real chamfered
    # volumetric geometry; no fake front billboard and no source texture.
    art.beveled_block("ClosedCastWeatherRoof","BRUSHED",
                      0,h+.68-center_y,0,11.84,1.04,9.84,.48)
    art.beveled_block("NestedRoofStormUndertray","CARBON",
                      0,h+.16-center_y,0,10.80,.14,8.84,.22)

    for side in (-1,1):
        # Original 1.2 x 0.75h primitive ribs become curved/split reliefs
        # on the flanks, inside the existing 12x10 roof union.
        art.rod("InclinedLeftRightLoadSpar_%s"%side,"ALLOY",
                (side*5.02,h*.12-center_y,-3.4),
                (side*4.70,h*.77-center_y,-3.4),.19,10)
        art.rod("ForgedReverseFlankStrut_%s"%side,"BRUSHED",
                (side*5.05,h*.13-center_y,-1.8),
                (side*4.50,h*.67-center_y,-2.4),.13,10)
        art.beveled_block("CastTransformerSidePanel_%s"%side,"CARBON",
                          side*4.40,h*.47-center_y,-1.45,
                          .26,h*.42,2.5,.08)
        for j in range(4):
            y=h*(.23+j*.15)-center_y
            art.beveled_block("SideHeatFin_%s_%02d"%(side,j),"GRIP",
                              side*4.68,y,-2.75,
                              .27,h*.055,1.22,.045)
        art.beveled_block("LoadBearingWeatherLip_%s"%side,"CERAMIC",
                          side*5.2,h+.04-center_y,0,
                          .46,.15,7.85,.09)

    for x in (-3.12,0,3.12):
        art.beveled_block("FrontModularArmor_%s"%x,"ARMOR",
                          x,h*.48-center_y,-3.74,
                          1.68,h*.51,.26,.07)
        art.beveled_block("DeepInsetVent_%s"%x,"GRIP",
                          x,h*.45-center_y,-3.90,
                          1.17,h*.25,.11,.045)
        for j in (-1,1):
            art.rod("FrontGusset%s_%s"%(x,j),"ALLOY",
                    (x+j*.69,h*.21-center_y,-3.84),
                    (x+j*.61,h*.72-center_y,-3.83),.065,8)
    for i in range(6):
        z=-3.0+i*1.2
        art.beveled_block("MachinedRoofDrain%02d"%i,"CERAMIC",
                          0,h+1.17-center_y,z,
                          .55,.045,.60,.04)
    art.beveled_block("RecessedRoofAssetCode","SIGNAL",
                      0,h+1.195-center_y,-4.43,
                      2.2,.009,.12,.008)
    return art


def export(profile: str, output: Path):
    art=make(profile)
    h=PROFILES[profile]
    raw="\n".join(art.lines)+"\n"
    bounds=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    if set(art.materials)!=set(MATERIALS):
        raise ValueError("Seven material groups required")
    if not (25<=art.groups<=120 and 550<=art.triangles<=7000):
        raise ValueError("Unexpected triangulated skyline complexity")
    if not (11.65<=bounds[0]<=11.99
            and h+.9<=bounds[1]<=h+1.25
            and 9.70<=bounds[2]<=9.99):
        raise ValueError("Wrong native skyline envelope %r" % bounds)
    centers=[(art.minimum[i]+art.maximum[i])*.5 for i in range(3)]
    if any(abs(x)>.18 for x in centers):
        raise ValueError("Source model must be centered at native union")
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(raw,encoding="utf-8")
    return {
        "asset":profile,"native_height":h,"groups":art.groups,
        "triangles":art.triangles,"vertices":art.vertices,
        "materials":sorted(art.materials),"bounds":bounds,
        "sha256":hashlib.sha256(raw.encode()).hexdigest()
    }


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--model",required=True,choices=PROFILES)
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.model,args.output),sort_keys=True))


if __name__=="__main__":
    main()
