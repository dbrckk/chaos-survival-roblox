#!/usr/bin/env python3
"""Two authentic nonphysical seven-material 3D identity mast sculptures.

Classic replaces four plain GridMarker 2.2x12x2.2 bodies ONLY; retain
the four GridMarkerGlow caps, which are animated by arena-identity-motion.

Towers replaces four plain TowerSpine 2.6x20x2.6 bodies ONLY; retain
the twelve independently animated TowerBand pieces at -1.5/+3/+7.5.

True tapered 12-gon longitudinal hulls, cast metal joints, winding load
ribs, cooling cassette relief and material-distinct inset signal lines.
The native colliders are untouched; any missing asset yields native art.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture

CLASSIC="variant_classic_grid_marker_sculpt"
TOWERS="variant_towers_spine_sculpt"
SPEC={
    CLASSIC:(2.16,11.92,2.16),
    TOWERS:(2.52,19.92,2.52),
}


def forge_loft(art:Sculpture,name:str,profiles:list[tuple],material:str):
    """A continuously varying 12-facet, closed loft; not Roblox Part boxes."""
    segments=12
    vertices=[]
    for y,rx,rz,twist in profiles:
        for index in range(segments):
            angle=2*math.pi*index/segments+twist
            vertices.append((rx*math.cos(angle),y,rz*math.sin(angle)))
    faces=[]
    for layer in range(len(profiles)-1):
        for index in range(segments):
            nxt=(index+1)%segments
            a=layer*segments+index
            b=layer*segments+nxt
            c=(layer+1)*segments+nxt
            d=(layer+1)*segments+index
            faces.extend(((a,b,c),(a,c,d)))
    end=(len(profiles)-1)*segments
    for index in range(1,segments-1):
        faces.append((0,index+1,index))
        faces.append((end,end+index,end+index+1))
    art.add(name,material,vertices,faces)


def classic() -> Sculpture:
    art=Sculpture()
    art.lines[0]="# Original Chaos Survival Classic four-marker sculpted identity masts"
    art.lines[2]="o ChaosOriginalClassicGridMarkerMast"
    forge_loft(art,"HelicalDodecagonalClassicSurveyBody",[
        (-5.76,.83,.78,-.07),(-4.94,.97,.89,-.035),
        (-3.02,.88,.93,-.012),(-1.03,.91,.87,.015),
        (1.04,.85,.94,.035),(3.12,.94,.85,.063),
        (4.94,.88,.94,.08),(5.76,.82,.81,.105),
    ],"ARMOR")
    # Exactly 2.16x11.92x2.16; original glow has its own
    # animation and extends from +5.94 to +6.26, above this source.
    for side in (-1,1):
        y=side*5.83
        art.beveled_block("ClassicForgedEndSocket"+str(side),"BRUSHED",
                          0,y,0,2.16,.26,2.16,.18)
        for xside in (-1,1):
            x=xside*.79
            art.rod("ClassicRunicVerticalSpar%s_%s"%(side,xside),
                    "ALLOY",(x,-4.80,side*.67),
                    (xside*.68,4.80,side*.68),.064,10)
        for n in range(4):
            elevation=-3.96+n*2.52
            art.beveled_block("ClassicBeveledCeramicMonitor%s_%02d"%(side,n),
                              "CERAMIC",0,elevation,side*.92,
                              1.13,.68,.14,.07)
            art.beveled_block("ClassicCarbonInlaidMonitor%s_%02d"%(side,n),
                              "CARBON",0,elevation,side*1.006,
                              .92,.40,.07,.023)
            art.beveled_block("ClassicTelemetryStatus%s_%02d"%(side,n),
                              "SIGNAL",0,elevation,side*1.051,
                              .33,.075,.03,.009)
    for axis in (-1,1):
        for n in range(8):
            h=-4.85+n*1.35
            x=axis*.81
            art.rod("ClassicDiagonalTension%s_%02d"%(axis,n),
                    "GRIP",(x,h,-.54),(x*.85,h+.88,.51),.045,10)
            art.beveled_block("ClassicForgedRivet%s_%02d"%(axis,n),
                              "ALLOY",x*.86,h+.48,-.75,
                              .19,.16,.15,.045)
    for n in range(5):
        h=-4.45+n*2.12
        art.beveled_block("ClassicOpenArcBackplate%02d"%n,"GRIP",
                          0,h,-.84,1.38,.14,.24,.048)
        art.beveled_block("ClassicShieldSeparator%02d"%n,"BRUSHED",
                          0,h+.55,.84,1.20,.13,.19,.055)
    return art


def towers() -> Sculpture:
    art=Sculpture()
    art.lines[0]="# Original Chaos Survival Towers four sculpted identity spines"
    art.lines[2]="o ChaosOriginalTowersIdentitySpine"
    forge_loft(art,"TwelveFluteTowersCrystallineLoadCore",[
        (-9.76,1.02,1.06,0),(-8.20,1.15,1.12,.02),
        (-5.80,1.03,1.08,.045),(-2.90,1.12,1.02,.069),
        (.05,1.01,1.12,.093),(2.84,1.14,1.06,.11),
        (5.80,1.04,1.09,.14),(8.18,1.14,1.02,.16),
        (9.76,1.01,1.04,.18),
    ],"ARMOR")
    for side in (-1,1):
        art.beveled_block("TowersForgedMainTerminal"+str(side),"BRUSHED",
                          0,side*9.83,0,2.52,.26,2.52,.20)
    for face in (-1,1):
        for stripe in range(7):
            h=-8.15+stripe*2.54
            art.beveled_block("TowersCarvedReactorCassette%s_%02d"%(face,stripe),
                              "CERAMIC",0,h,face*1.04,
                              1.35,1.22,.23,.065)
            art.beveled_block("TowersCoolingRecess%s_%02d"%(face,stripe),
                              "CARBON",0,h,face*1.168,
                              .99,.64,.065,.022)
            art.beveled_block("TowersSensorLine%s_%02d"%(face,stripe),
                              "SIGNAL",0,h+.30,face*1.205,
                              .64,.11,.023,.007)
        for pillar in (-1,1):
            x=pillar*.80
            art.rod("TowersHardenedTensionChine%s_%s"%(face,pillar),
                    "ALLOY",(x,-9.14,face*.72),
                    (x*.92,9.15,face*.72),.075,10)
            for step in range(6):
                y=-8.04+step*3.22
                art.rod("TowersOpenDiagonalBrace%s_%s_%02d"%
                        (face,pillar,step),"GRIP",
                        (x,y,face*.69),
                        (x*.82,y+1.95,face*.78),.065,10)
    # Native three bands at y=-1.5/3/7.5 pulse independently; they are
    # NOT part of this source and keep their original visual behavior.
    for bandY in (-1.5,3.0,7.5):
        for side in (-1,1):
            art.beveled_block("TowersBandUnderframe%s_%s"%(bandY,side),
                              "ALLOY",0,bandY-.20,side*.85,
                              1.47,.11,.26,.045)
            art.beveled_block("TowersBandUpperRail%s_%s"%(bandY,side),
                              "GRIP",0,bandY+.21,side*.84,
                              1.45,.11,.20,.045)
    for i in range(10):
        h=-8.65+i*1.86
        for face in (-1,1):
            art.beveled_block("TowersEngravedSideFastener%s_%02d"%(face,i),
                              "BRUSHED",face*.89,h,0,
                              .19,.26,.67,.055)
    return art


def export(path:Path,name:str)->dict:
    art=classic() if name==CLASSIC else towers() if name==TOWERS else None
    if art is None:raise ValueError("Unknown original identity sculpture")
    raw="\n".join(art.lines)+"\n"
    bounds=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    midpoint=[round((art.maximum[i]+art.minimum[i])*.5,5)
              for i in range(3)]
    if set(art.materials)!=set(MATERIALS):
        raise ValueError(("Missing seven source materials",art.materials))
    if not 1300<=art.triangles<=16000 or not 60<=art.groups<=400:
        raise ValueError(("Unexpected 3D source complexity",
                          art.triangles,art.groups))
    if any(abs(x-y)>.08 for x,y in zip(bounds,SPEC[name])):
        raise ValueError(("3D source bounds mismatch",bounds,SPEC[name]))
    if max(abs(v) for v in midpoint)>.08:
        raise ValueError(("Miscentered original identity sculpture",midpoint))
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(raw,encoding="utf8")
    return {"asset":name,"triangles":art.triangles,
            "groups":art.groups,"vertices":art.vertices,
            "materials":sorted(art.materials),
            "bounds":bounds,"center":midpoint,
            "sha256":hashlib.sha256(raw.encode()).hexdigest()}


if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--model",choices=(CLASSIC,TOWERS),required=True)
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    print(json.dumps(export(args.output,args.model),sort_keys=True))
