#!/usr/bin/env python3
"""Six original production 3D meshes for visible high-deck structural retrofit.

Five arena-unique load columns with tapered real polygonal shafts, forged
lattices, bolted shoes and inset graphics. One 22 x 10 stud trussed underdeck
cradle for long elevated routes. All are cosmetic imported seven-material
MeshParts; real platform physics, hazards and connectivity remain server-owned.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

KINDS=(
    "column_classic", "column_towers", "column_crossroads",
    "column_orbital", "column_harbor", "long_route_cradle",
)


def tapered_pillar(art: Sculpture, name: str, material: str, profile) -> None:
    """A 10-sided, non-prismatic forged vertical column (real tapered mesh)."""
    sides=10
    vertices=[]
    for y,width,depth in profile:
        for k in range(sides):
            ang=2*math.pi*k/sides
            vertices.append((width*math.cos(ang),y,depth*math.sin(ang)))
    faces=[]
    for ring in range(len(profile)-1):
        for k in range(sides):
            a=ring*sides+k
            b=ring*sides+(k+1)%sides
            c=(ring+1)*sides+(k+1)%sides
            d=(ring+1)*sides+k
            faces.extend(((a,b,c),(a,c,d)))
    for k in range(1,sides-1):
        faces.append((0,k+1,k))
        base=(len(profile)-1)*sides
        faces.append((base,base+k,base+k+1))
    art.add(name,material,vertices,faces)


def core(art:Sculpture,kind:str) -> None:
    # Framed 14-stud height, external envelope at most 2.25 x 14.2 x 2.25.
    waists={
        "column_classic":(.54,.56,.61),
        "column_towers":(.51,.46,.66),
        "column_crossroads":(.67,.57,.69),
        "column_orbital":(.46,.47,.69),
        "column_harbor":(.62,.60,.70),
    }
    foot,waist,cap=waists[kind]
    tapered_pillar(art,kind+"_ForgedPolyshaft","ARMOR",(
        (-6.78,foot,foot),(-5.43,foot+.06,foot+.06),
        (-2.7,waist,waist*.88),(0,waist*.89,waist*.95),
        (2.7,waist,waist*.88),(5.43,cap,cap),
        (6.78,cap+.10,cap+.10)))
    for side in (-1,1):
        # 14-stud constrained side channels and diagonal welded trusses.
        art.beveled_block("VerticalLoadEdge%d"%side,"BRUSHED",
                          side*.76,0,0,.23,12.40,.27,.08)
        art.beveled_block("SideDielectricInsert%d"%side,"CERAMIC",
                          side*.81,0,.18,.10,8.3,.17,.04)
        for k in range(5):
            y=-5.2+k*2.6
            art.rod("ForgedCrossStay%d_%d"%(side,k),"ALLOY",
                    (side*.73,y-.74,-.68),
                    (side*.73,y+.79,.62),.065,8)
    for y in (-6.66,6.66):
        art.beveled_block("ServiceCollar%.2f"%y,"BRUSHED",
                          0,y,0,1.92,.31,1.93,.20)
        art.beveled_block("RubberSeismicBoot%.2f"%y,"GRIP",
                          0,y+(.21 if y>0 else -.21),0,
                          1.61,.17,1.63,.18)
    art.beveled_block("CentralCarbonInspectionDoor","CARBON",
                      0,1.68,.65,.93,2.15,.10,.07)
    art.beveled_block("InlaidSignalStripe","SIGNAL",
                      0,2.20,.73,.57,.13,.09,.03)


def classic(art:Sculpture) -> None:
    core(art,"column_classic")
    for k in range(7):
        y=-5.0+k*1.62
        art.beveled_block("ClassicPressureSlat%d"%k,"CARBON",
                          0,y,.77,.76,.36,.10,.07)
        for side in (-1,1):
            art.rod("ClassicForgedRivet%d_%d"%(side,k),"ALLOY",
                    (side*.45,y,.73),(side*.45,y+.16,.73),.045,8)
    art.beveled_block("ClassicWarningPlaque","SIGNAL",
                      0,-3.6,.77,.77,.18,.10,.05)


def towers(art:Sculpture) -> None:
    core(art,"column_towers")
    for side in (-1,1):
        art.beveled_block("HoistHydraulicGuide%d"%side,"ALLOY",
                          side*.78,.10,-.23,.31,11.8,.27,.11)
        art.rod("HoistHydraulicConduit%d"%side,"BRUSHED",
                (side*.67,-5.7,-.64),(side*.67,5.7,-.64),.094,12)
        for k in range(4):
            art.beveled_block("HoistGuideShoe%d_%d"%(side,k),"GRIP",
                              side*.81,-3.9+k*2.56,-.18,.31,.49,.38,.06)
    art.beveled_block("TowerServiceHatch","CARBON",
                      0,0,.78,.68,2.25,.1,.05)


def crossroads(art:Sculpture) -> None:
    core(art,"column_crossroads")
    for k in range(6):
        y=-5.1+k*2.04
        art.beveled_block("HighwayCrashCassette%d"%k,"CERAMIC",
                          0,y,.72,1.22,.92,.16,.13)
        art.beveled_block("HighwaySafetyPad%d"%k,"CARBON",
                          0,y,.82,.86,.30,.08,.06)
    for side in (-1,1):
        art.rod("HighwayRoadStay%d"%side,"ALLOY",
                (side*.70,-5.5,.57),(side*.72,5.1,-.53),.080,10)
    art.beveled_block("HighwayReturnMarker","SIGNAL",
                      0,-4.42,.89,.75,.1,.06,.02)


def orbital(art:Sculpture) -> None:
    core(art,"column_orbital")
    for k in range(6):
        y=-5.35+k*2.13
        art.beveled_block("FluxCooledShell%d"%k,"CERAMIC",
                          0,y,.68,1.24,.65,.19,.11)
        art.beveled_block("FluxEmitterChamber%d"%k,"CARBON",
                          0,y,.79,.65,.35,.11,.08)
        art.beveled_block("FluxTelemetryLens%d"%k,"SIGNAL",
                          0,y,.89,.27,.12,.08,.035)
    for side in (-1,1):
        art.rod("OrbitalCryoManifold%d"%side,"ALLOY",
                (side*.62,-5.7,-.62),(side*.62,5.7,-.62),.084,12)


def harbor(art:Sculpture) -> None:
    core(art,"column_harbor")
    for side in (-1,1):
        for k in range(5):
            y=-4.6+k*2.28
            art.beveled_block("DockWeldedClasp%d_%d"%(side,k),"BRUSHED",
                              side*.72,y,.25,.34,.39,1.05,.10)
            art.rod("DockTensionChain%d_%d"%(side,k),"ALLOY",
                    (side*.70,y-.7,-.57),(side*.70,y+.72,.53),
                    .091,9)
    for k in range(4):
        y=-3.67+k*2.5
        art.beveled_block("TreatedTimberCompositeBand%d"%k,"GRIP",
                          0,y,.73,1.38,.30,.25,.08)
    art.beveled_block("HarborLowTideSignal","SIGNAL",
                      0,-4.7,.87,.82,.12,.08,.04)


def cradle(art:Sculpture) -> None:
    # Exactly one physical, wide UNDERDECK assembly in the source:
    # ~22 x 10, a genuine OPEN lattice; no collidable top, bridge or lane.
    for side in (-1,1):
        art.beveled_block("SweptPortStarboardLongeron%d"%side,"ARMOR",
                          0,-.27,side*4.62,21.76,.46,.77,.25)
        art.beveled_block("CeramicFlankArmor%d"%side,"CERAMIC",
                          0,-.50,side*4.92,18.60,.20,.16,.07)
        art.beveled_block("DarkVentBackplate%d"%side,"CARBON",
                          0,-1.04,side*4.54,20.00,.22,.24,.07)
    for i in range(9):
        x=-9.72+i*2.43
        art.beveled_block("RibbedCrossStrut%d"%i,"BRUSHED",
                          x,-1.37,0,.30,.42,8.88,.11)
        art.rod("DiagonalCantilever%d"%i,"ALLOY",
                (x-.34,-.38,3.74),(x+.53,-2.15,-3.61),.077,8)
        art.beveled_block("CradleAbsorberFoot%d"%i,"GRIP",
                          x,-2.23,0,.39,.22,1.14,.07)
    art.beveled_block("RecessedCentralLoadSpine","ALLOY",
                      0,-2.51,0,17.95,.46,.62,.18)
    for i in range(3):
        art.beveled_block("TrafficCableSignalPanel%d"%i,"SIGNAL",
                          (-1+i)*6.12,-.55,4.96,2.64,.10,.09,.03)
    art.beveled_block("CentralHollowServicePod","CARBON",
                      0,-1.72,0,4.55,.34,3.40,.18)


BUILD={
    "column_classic":classic,
    "column_towers":towers,
    "column_crossroads":crossroads,
    "column_orbital":orbital,
    "column_harbor":harbor,
    "long_route_cradle":cradle,
}

def export(kind:str,output:Path):
    if kind not in BUILD: raise ValueError("Unknown original support source")
    art=Sculpture()
    art.lines[0]="# Chaos original source-authored structural support "+kind
    art.lines[2]="o Chaos_"+kind
    BUILD[kind](art)
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    if art.materials!=set(MATERIALS): raise ValueError("Missing real material group")
    if not(19<=art.groups<=150 and 380<=art.triangles<=5500):
        raise ValueError("Invalid support complexity "+str((kind,art.groups,art.triangles)))
    if kind=="long_route_cradle":
        ok=21.5<=dims[0]<=23.0 and 2.0<=dims[1]<=4.0 and 9.4<=dims[2]<=10.5
    else:
        ok=1.7<=dims[0]<=2.4 and 13.6<=dims[1]<=14.5 and 1.6<=dims[2]<=2.4
    if not ok: raise ValueError("Invalid support envelope "+str((kind,dims)))
    output.parent.mkdir(parents=True,exist_ok=True)
    blob="\n".join(art.lines)+"\n"
    output.write_text(blob,encoding="utf-8")
    return {"asset":kind,"groups":art.groups,"triangles":art.triangles,
            "vertices":art.vertices,"materials":sorted(art.materials),
            "dimensions":dims,"sha256":hashlib.sha256(blob.encode()).hexdigest()}

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--model",choices=tuple(BUILD),required=True)
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    print(json.dumps(export(args.model,args.output),sort_keys=True))
