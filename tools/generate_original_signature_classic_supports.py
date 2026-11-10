#!/usr/bin/env python3
"""Original five-element architectural support complement for Classic.

A real triangulated, seven-PBR-material creator-owned Model replacing:
RelayButtressWest/East, RelaySparWest/East, ServicePanel. Main seven-piece
twin-dish observatory remains independently approved and untouched.
Original real-world positions are uniformly normalized 1:2 for import.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NAME = "signature_classic_forged_supports"
SCALE = 2.0
CENTER_Y = 19.25


def p(x, y, z):
    return (x / SCALE, (y - CENTER_Y) / SCALE, z / SCALE)


def rod(art, name, material, a, b, radius, sectors=8):
    art.rod(name, material, p(*a), p(*b), radius / SCALE, sectors)


def block(art, name, material, x, y, z, sx, sy, sz, edge=.08):
    art.beveled_block(name, material, *p(x, y, z),
                      sx / SCALE, sy / SCALE, sz / SCALE, edge / SCALE)


def buttress(art, side):
    """Long real twelve-facet taper, not a rectangular tower primitive."""
    x=side*11.8
    stations=[
        (.06,1.65,2.12),(2.2,1.67,2.15),
        (6.8,1.53,2.04),(14.0,1.49,1.93),
        (22.0,1.48,1.89),(30.5,1.49,1.84),
        (32.95,1.64,2.03),
    ]
    n=12
    verts=[]
    for y,rx,rz in stations:
        for i in range(n):
            angle=2*math.pi*i/n
            verts.append(p(x+rx*math.cos(angle),y,rz*math.sin(angle)))
    faces=[]
    for j in range(len(stations)-1):
        for i in range(n):
            a=j*n+i
            b=j*n+(i+1)%n
            c=(j+1)*n+(i+1)%n
            d=(j+1)*n+i
            faces.extend(((a,b,c),(a,c,d)))
    for i in range(1,n-1):
        faces.append((0,i+1,i))
        last=(len(stations)-1)*n
        faces.append((last,last+i,last+i+1))
    art.add("OriginalTwelveFacetTaperedLoadButtress%s"%side,
            "ARMOR",verts,faces)

    for j,y in enumerate((2.5,9.4,16.3,23.2,30.5)):
        # Original profiled collar inset to prevent adding false floating
        # terrain geometry outside the existing cosmetic monument.
        block(art,"MechanicalForgedButtressCollar%s_%02d"%(side,j),
              "BRUSHED",x,y,0,3.28,.21,4.24,.16)
        for face in (-1,1):
            z=face*2.17
            block(art,"CarbonVentilationPanel%s_%s_%02d"%(side,face,j),
                  "CARBON",x,y+1.7,z,2.13,2.65,.085,.07)
            for k in range(3):
                px=x+(k-1)*.57
                block(art,"ReliefVentLouver%s_%s_%02d_%02d"%
                      (side,face,j,k),"GRIP",
                      px,y+1.70,z+face*.058,.27,2.22,.045,.026)
    for k in range(11):
        y=3.15+k*2.61
        block(art,"CeramicAccessCode%s_%02d"%(side,k),"CERAMIC",
              x-.52,y,-2.206,.48,.085,.045,.021)
    for k in range(8):
        y=4.8+k*3.40
        block(art,"InlaidLoadIndicator%s_%02d"%(side,k),"SIGNAL",
              x+.82,y,-2.209,.18,.33,.050,.017)


def inclined_spar(art, side):
    angle=side*math.radians(21)
    origin=(side*7.5,24,-.8)
    lateral=(math.cos(angle),math.sin(angle),0)
    upward=(-math.sin(angle),math.cos(angle),0)
    def pt(s,rv,rz):
        return (
            origin[0]+upward[0]*s+lateral[0]*rv,
            origin[1]+upward[1]*s+lateral[1]*rv,
            origin[2]+rz,
        )
    stations=[
        (-15.45,.47,.59),(-12.1,.54,.66),(-7.1,.44,.52),
        (0,.50,.62),(7.1,.44,.52),(12.1,.54,.66),(15.45,.47,.59)
    ]
    sides=10
    v=[]
    for height,rx,rz in stations:
        for k in range(sides):
            theta=2*math.pi*k/sides
            v.append(p(*pt(height,rx*math.cos(theta),
                            rz*math.sin(theta))))
    f=[]
    for j in range(len(stations)-1):
        for k in range(sides):
            a=j*sides+k
            b=j*sides+(k+1)%sides
            c=(j+1)*sides+(k+1)%sides
            d=(j+1)*sides+k
            f.extend(((a,b,c),(a,c,d)))
    for k in range(1,sides-1):
        f.append((0,k+1,k))
        last=(len(stations)-1)*sides
        f.append((last,last+k,last+k+1))
    art.add("InclinedTenFacetOpenLoadSpar%s"%side,"BRUSHED",v,f)

    # Forged external load cables and regularly spaced latches are
    # physically distinct 3D cylinders and metal trim, not an emissive decal.
    for face in (-1,1):
        rod(art,"ParallelStructuralCable%s_%s"%(side,face),"ALLOY",
            pt(-14.4,face*.29,-.71),pt(14.4,face*.29,-.71),.078,10)
    for i,s in enumerate((-12.6,-8.0,-3.4,1.2,5.8,10.4,14.0)):
        for face in (-1,1):
            a=pt(s,face*.45,-.55)
            b=pt(s+.65,face*.43,.45)
            rod(art,"ChanneledShearCoupler%s_%s_%02d"%(side,face,i),
                "CARBON",a,b,.095,8)
    for index,s in enumerate((-9.5,-3.5,3.2,9.8)):
        a=pt(s,-.35,.51)
        b=pt(s+.68,.35,.52)
        rod(art,"BespokeSurfaceBrace%s_%02d"%(side,index),
            "ALLOY",a,b,.095,8)


def telemetry_panel(art):
    # True extruded octagonal enclosure and readable recessed telemetry,
    # positioned exactly where MapBuilder's original flat ServicePanel was.
    block(art,"ForgedRelayServicePanelChassis","ARMOR",
          0,35,-2.25,4.92,3.12,.52,.19)
    block(art,"CeramicRecessedPanelFront","CERAMIC",
          0,35,-2.524,4.48,2.69,.046,.10)
    block(art,"CarbonFullHeightSwitchboardGlass","CARBON",
          0,35,-2.555,4.14,2.36,.034,.07)
    for i in range(8):
        x=-1.83+i*.52
        block(art,"EmbossedDiagnosticBand%02d"%i,"SIGNAL",
              x,35.65,-2.578,.18,.46,.022,.012)
    for i in range(6):
        x=-1.55+i*.63
        block(art,"MachinedBottomActuator%02d"%i,"GRIP",
              x,34.20,-2.580,.30,.16,.027,.014)
    for side in (-1,1):
        for y in (33.79,36.16):
            rod(art,"RetainedStainlessPanelBolt%s_%s"%(side,y),"ALLOY",
                (side*2.20,y,-2.570),(side*2.20,y,-2.614),.075,8)


def export(path: Path):
    art=Sculpture()
    art.lines[0]="# Original Chaos Survival Classic industrial support sculpture"
    art.lines[2]="o ChaosOriginalClassicForgedSignatureSupports"
    for side in (-1,1):
        buttress(art,side)
        inclined_spar(art,side)
    telemetry_panel(art)
    dimensions=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    center=[round((art.minimum[i]+art.maximum[i])*.5,5)
            for i in range(3)]
    assert set(art.materials)==set(MATERIALS),art.materials
    assert 85<=art.groups<=480,(art.groups,art.triangles)
    assert 1400<=art.triangles<=10000,art.triangles
    assert 13.35<=dimensions[0]<=14.05,dimensions
    assert 19.0<=dimensions[1]<=19.9,dimensions
    assert 2.25<=dimensions[2]<=2.60,dimensions
    assert abs(center[0])<.15 and abs(center[1])<.30,center
    path.parent.mkdir(parents=True,exist_ok=True)
    raw="\n".join(art.lines)+"\n"
    path.write_text(raw,encoding="utf-8")
    return {
        "asset":"signature_classic_forged_supports",
        "triangles":art.triangles,"groups":art.groups,
        "vertices":art.vertices,"materials":sorted(art.materials),
        "bounds":dimensions,"center":center,
        "sha256":hashlib.sha256(raw.encode()).hexdigest()
    }


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))


if __name__=="__main__":
    main()
