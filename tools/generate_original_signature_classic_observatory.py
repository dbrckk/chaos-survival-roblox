#!/usr/bin/env python3
"""Original 3D Classic Grid signature observatory with TWO concave dishes.

Replaces seven precise nonphysical MapBuilder primitives as ONE real
seven-material triangulated creator-owned Model. Original coordinate design
is normalized 1:4 to fit the validated Sculpture source envelope and later
uniformly scaled in Roblox without stretching/retopologizing.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NAME = "signature_classic_sculpted_observatory"
SCALE = 4.0
CENTER_Y = 30.175


def vertex(x: float, y: float, z: float):
    return (x / SCALE, (y - CENTER_Y) / SCALE, z / SCALE)


def add(art: Sculpture, name: str, material: str, vertices, triangles):
    art.add(name, material, [vertex(*v) for v in vertices], triangles)


def block(art: Sculpture, name: str, material: str,
          x, y, z, sx, sy, sz, edge=.1):
    xx, yy, zz = vertex(x, y, z)
    art.beveled_block(name, material, xx, yy, zz,
                      sx/SCALE, sy/SCALE, sz/SCALE, edge/SCALE)


def rod(art: Sculpture, name: str, material: str,
        start, end, radius, sides=10):
    art.rod(name, material, vertex(*start), vertex(*end),
            radius/SCALE, sides)


def tapered_mast(art: Sculpture):
    """Twelve-sided CLOSED original multi-facet relay mast, never a box."""
    stations = [
        (0.0, 1.48, 1.45),
        (4.5, 1.36, 1.38),
        (13.5, 1.12, 1.17),
        (24, 1.22, 1.23),
        (36, 1.31, 1.32),
        (46, 1.12, 1.18),
        (55, 1.03, 1.08),
    ]
    sectors = 12
    coords = []
    for y, rx, rz in stations:
        for i in range(sectors):
            phi=2*math.pi*i/sectors
            coords.append((rx*math.cos(phi),y,rz*math.sin(phi)))
    faces=[]
    for k in range(len(stations)-1):
        for i in range(sectors):
            a=k*sectors+i
            b=k*sectors+(i+1)%sectors
            c=(k+1)*sectors+(i+1)%sectors
            d=(k+1)*sectors+i
            faces.extend(((a,b,c),(a,c,d)))
    for i in range(1,sectors-1):
        faces.append((0,i+1,i))
        top=(len(stations)-1)*sectors
        faces.append((top,top+i,top+i+1))
    add(art,"ClosedTwelveFacetTaperedPrimaryRelayMast",
        "ARMOR",coords,faces)
    for y in (5.2,14.3,24.1,36.5,46.7,53.3):
        block(art,"ForgedServiceMastCollar_%s"%y,"BRUSHED",
              0,y,0,2.81,.24,2.79,.12)
    for side in (-1,1):
        rod(art,"RoutedLongitudinalSignalConductor_%s"%side,"ALLOY",
            (side*1.18,3.2,-1.14),(side*1.04,53.1,-1.03),.087,10)
        for k in range(6):
            y=8.4+k*7.45
            block(art,"MastRecessedCarbonHeatFin_%s_%d"%(side,k),
                  "CARBON",side*1.17,y,-.70,.19,3.34,.82,.08)
    for i in range(10):
        y=5+i*5.1
        block(art,"MastOriginalTelemetryDot_%02d"%i,"SIGNAL",
              0,y,-1.47,.46,.15,.045,.018)


def forged_crown(art: Sculpture):
    # The original RelayHead was a 7x4.7x4.2 wedge. Build a closed
    # pentagonal *profiled* metal canopy and trussed utility hood.
    edge=[
        (-3.42,55.65),(-3.42,57.12),(-1.94,59.73),
        (-.64,60.35),(.64,60.35),(1.94,59.73),
        (3.42,57.12),(3.42,55.65),
    ]
    verts=[(x,y,z) for z in (-2.06,2.06) for x,y in edge]
    n=len(edge)
    faces=[]
    for i in range(1,n-1):
        faces.extend(((0,i,i+1),(n,n+i+1,n+i)))
    for i in range(n):
        j=(i+1)%n
        faces.extend(((i,j,n+j),(i,n+j,n+i)))
    add(art,"SculptedWedgeFreeCrownCanopy","ARMOR",verts,faces)
    for side in (-1,1):
        rod(art,"CrownSweptCrossbrace_%s"%side,"ALLOY",
            (side*2.83,56.30,-1.82),
            (side*.49,59.90,-1.76),.102,10)
        block(art,"CrownCeramicLiner_%s"%side,"CERAMIC",
              side*2.18,56.40,-1.88,.52,.22,.25,.055)
    block(art,"CrownSkywardSignalCap","SIGNAL",
          0,60.32,-.21,.72,.035,.45,.01)


def profiled_receiver_bridge(art: Sculpture):
    # Decorative 30-stud dish bridge at y=37 (native 30x1.2x2).
    # Profiled X-swept deck, positive structural thickness in Y.
    yz=[(-.59,-.88),(-.59,.88),(-.39,.99),
        (.39,.99),(.59,.88),(.59,-.88),
        (.42,-.99),(-.42,-.99)]
    stations=[(-14.86,.98),(-12.1,1),(0,1),
              (12.1,1),(14.86,.98)]
    coords=[(x,37+y*t,z*t) for x,t in stations for y,z in yz]
    n=len(yz)
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
        q=(len(stations)-1)*n
        faces.append((q,q+i,q+i+1))
    add(art,"EightFacetContinuousReceiverSkybridge","BRUSHED",coords,faces)
    for side in (-1,1):
        z=side*.86
        for i in range(8):
            x=-12.7+i*3.63
            rod(art,"SkybridgeOpenLattice_%s_%02d"%(side,i),"ALLOY",
                (x-.61,36.58,z),(x+.61,37.46,z),.080,8)
        rod(art,"SkybridgeForgedLongitudinalCordon_%s"%side,"CERAMIC",
            (-14.45,37.61,z),(14.45,37.61,z),.070,10)
    for i in range(8):
        x=-12.7+i*3.63
        block(art,"BridgeServiceHatch%02d"%i,"GRIP",
              x,37.61,0,1.93,.055,1.35,.05)


def dish_shell(art: Sculpture, side: int):
    # The authored native Part Cylinder's physical axis is WORLD Z,
    # disk diameter 10.5 studs. Make an actual 3D concave bowl in XY
    # (front points toward negative Z), not a flat cylinder or billboard.
    x = 13.0*side
    y = 44.0+3.0*side
    label="West" if side<0 else "East"
    radii=(.18,.88,2.08,3.49,4.70,5.14)
    sectors=48
    faces=[]
    coords=[]
    for r in radii:
        z = -.36+.024*r+.020*r*r
        for k in range(sectors):
            a=math.tau*k/sectors
            coords.append((x+r*math.cos(a),
                           y+r*math.sin(a),z))
    for j in range(len(radii)-1):
        for k in range(sectors):
            a=j*sectors+k
            b=j*sectors+(k+1)%sectors
            c=(j+1)*sectors+(k+1)%sectors
            d=(j+1)*sectors+k
            faces.extend(((a,b,c),(a,c,d)))
    add(art,"TrueConcaveParabolicReceiverFront"+label,"CERAMIC",
        coords,faces)

    # Actual closed back shell, continuously curved; slight thickness,
    # not a paper-thin fake dish. The two surfaces are separate PBR meshes.
    backside=[]
    for r in radii:
        z = -.16+.024*r+.020*r*r
        for k in range(sectors):
            a=math.tau*k/sectors
            backside.append((x+r*math.cos(a),
                             y+r*math.sin(a),z))
    add(art,"ParabolicForgedDishBackHousing"+label,"CARBON",
        backside,[(a,c,b) for a,b,c in faces])

    # A closed hollow toroidal rim, recognizable from the side on Android.
    ringverts=[]
    ringfaces=[]
    maj=5.125
    tube=.085
    for k in range(sectors):
        theta=math.tau*k/sectors
        co,si=math.cos(theta),math.sin(theta)
        for j in range(8):
            phi=math.tau*j/8
            radius=maj+tube*math.cos(phi)
            z=.25+tube*math.sin(phi)
            ringverts.append((x+radius*co,y+radius*si,z))
    for k in range(sectors):
        for j in range(8):
            a=k*8+j
            b=((k+1)%sectors)*8+j
            c=((k+1)%sectors)*8+(j+1)%8
            d=k*8+(j+1)%8
            ringfaces.extend(((a,b,c),(a,c,d)))
    add(art,"TrueContinuousHollowMachinedReceiverRim"+label,
        "BRUSHED",ringverts,ringfaces)

    # Real open 3D radial spars, floating mechanically above back of bowl.
    for i in range(12):
        a=math.tau*i/12
        co,si=math.cos(a),math.sin(a)
        rod(art,"BackRadialDishWeb%s_%02d"%(label,i),"ALLOY",
            (x+.55*co,y+.55*si,.025),
            (x+4.95*co,y+4.95*si,.36),.058,8)

    # Genuine metal receiver hub (old sphere Part at Z=-0.8) and signal.
    rod(art,"ForgedReceiverFeedHub"+label,"GRIP",
        (x,y,-1.78),(x,y,-.28),.88,16)
    for i in range(6):
        a=math.tau*i/6
        co,si=math.cos(a),math.sin(a)
        rod(art,"FeedHornGuyBrace%s_%d"%(label,i),"ALLOY",
            (x+.32*co,y+.32*si,-1.65),
            (x+1.45*co,y+1.45*si,-.27),.054,8)
    block(art,"BeaconTelemetricDiode"+label,"SIGNAL",
          x,y,-1.79,.47,.47,.065,.024)


def export(path: Path):
    art=Sculpture()
    art.lines[0]="# Original true 3D Classic Grid signature observatory"
    art.lines[2]="o ChaosOriginalSignatureClassicObservatory"
    tapered_mast(art)
    forged_crown(art)
    profiled_receiver_bridge(art)
    for side in (-1,1):
        dish_shell(art,side)
    raw="\n".join(art.lines)+"\n"
    bounds=[round(art.maximum[i]-art.minimum[i],5)
            for i in range(3)]
    center=[round((art.maximum[i]+art.minimum[i])/2,5)
            for i in range(3)]
    if set(art.materials)!=set(MATERIALS):
        raise ValueError("All 7 original PBR materials required")
    if not (70<=art.groups<=240 and 3400<=art.triangles<=12500):
        raise ValueError(("Invalid genuine 3D count",art.groups,art.triangles))
    if not (8.96<=bounds[0]<=9.23
            and 15.06<=bounds[1]<=15.13
            and 1.01<=bounds[2]<=1.11):
        raise ValueError(("Classic native union mismatch",bounds))
    if any(abs(v)>.12 for v in center):
        raise ValueError(("Off-center sculpted observatory",center))
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(raw,encoding="utf-8")
    return {
        "asset":NAME,
        "triangles":art.triangles,
        "groups":art.groups,
        "vertices":art.vertices,
        "materials":sorted(art.materials),
        "bounds":bounds,
        "center":center,
        "sha256":hashlib.sha256(raw.encode()).hexdigest(),
    }


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))


if __name__=="__main__":
    main()
