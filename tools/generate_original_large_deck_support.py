#!/usr/bin/env python3
"""Two real original Chaos Survival 3D structural art families.

large_deck_hull: 18-stud landmark platform underside with open triangular
facia, machined load ring, support junctions and separate detailing.
support_lattice: tall four-rail open structural pylon replacing a native
rectangular hanging support; scale uniformly to the TRUE vertical span.
These are authored visible models, not new colliders or Roblox native Parts.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

MODELS = ("large_deck_hull", "support_lattice")


def support(m: Sculpture) -> None:
    # Original 16.3-stud lattice: actual triangulated diagonal tubes,
    # four beams, separate compression rings and mechanical hardware.
    for sx in (-1,1):
        for sz in (-1,1):
            m.beveled_block("FramedVerticalChord_%s_%s"%(sx,sz),
                            "ARMOR",sx*.42,0,sz*.42,.19,15.7,.19,.065)
            m.beveled_block("LowerCastFoot_%s_%s"%(sx,sz),
                            "ALLOY",sx*.44,-7.92,sz*.44,.31,.37,.31,.07)
            m.beveled_block("UpperForgedSeat_%s_%s"%(sx,sz),
                            "BRUSHED",sx*.44,7.92,sz*.44,.33,.38,.33,.06)
    for level in range(6):
        y=-6.7+level*2.68
        m.beveled_block("GussetHardenedCollar_%s"%level,"BRUSHED",
                        0,y,0,1.0,.24,1.0,.15)
        m.beveled_block("AntiSlipMarker_%s"%level,"GRIP",
                        0,y+.16,.48,.66,.06,.10,.02)
        m.beveled_block("CarbonInspectionPlug_%s"%level,"CARBON",
                        0,y-.18,-.48,.47,.09,.10,.03)
        for side in (-1,1):
            m.rod("DiagonalLateralWeb_%s_%s"%(level,side),"ALLOY",
                  (side*.42,y-1.23,-.42),
                  (-side*.42,y+1.23,.42),.061,8)
            m.rod("BackedShearWeb_%s_%s"%(level,side),"CERAMIC",
                  (-.42,y-1.23,side*.42),
                  (.42,y+1.23,-side*.42),.049,8)
    for level in (0,1,2):
        m.beveled_block("RecessedInspectionDisplay_%d"%level,"SIGNAL",
                        .0,-4.9+level*4.9,.53,.38,.12,.08,.025)
    m.beveled_block("TopBearingCollar","ALLOY",
                    0,8.11,0,1.13,.16,1.13,.13)
    m.beveled_block("BottomCastCollar","ARMOR",
                    0,-8.11,0,1.13,.16,1.13,.13)


def skirt(m:Sculpture, face:int, along_z:bool) -> None:
    # Entire underside stays inside the 18-stud collidable deck footprint.
    edge=8.55*face
    inner=7.69*face
    if along_z:
        verts=[(-8.4,-.14,edge),(8.4,-.14,edge),
               (7.7,-1.42,inner),(-7.7,-1.42,inner),
               (-8.4,-.29,edge-face*.15),(8.4,-.29,edge-face*.15),
               (7.7,-1.57,inner-face*.15),(-7.7,-1.57,inner-face*.15)]
    else:
        verts=[(edge,-.14,-8.4),(edge,-.14,8.4),
               (inner,-1.42,7.7),(inner,-1.42,-7.7),
               (edge-face*.15,-.29,-8.4),(edge-face*.15,-.29,8.4),
               (inner-face*.15,-1.57,7.7),(inner-face*.15,-1.57,-7.7)]
    faces=((0,1,2),(0,2,3),(4,6,5),(4,7,6),
           (0,4,5),(0,5,1),(1,5,6),(1,6,2),
           (2,6,7),(2,7,3),(3,7,4),(3,4,0))
    if face<0: faces=[(a,c,b) for a,b,c in faces]
    m.add("ForgedOpenEdgeSkirt_%s_%s"%(face,along_z),"ARMOR",verts,list(faces))


def hull(m:Sculpture) -> None:
    for side in (-1,1):
        skirt(m,side,True)
        skirt(m,side,False)
        m.beveled_block("NorthSouthShearDeck_%d"%side,"BRUSHED",
                        0,-.48,side*8.20,16.4,.29,.33,.10)
        m.beveled_block("EastWestShearDeck_%d"%side,"BRUSHED",
                        side*8.20,-.48,0,.33,.29,16.4,.10)
        m.beveled_block("FrictionTreadBand_%d"%side,"GRIP",
                        0,-.62,side*8.16,13.8,.12,.18,.055)
        m.beveled_block("ShieldedCableRaceway_%d"%side,"CARBON",
                        side*8.12,-.80,0,.15,.16,12.4,.05)
    # The real collidable surface stays entirely server-owned above Y=0.
    m.beveled_block("ReinforcedUnderdeckSpine","ALLOY",
                    0,-2.45,0,12.3,.82,7.6,.48)
    m.beveled_block("OpenUndercarriageNucleus","CARBON",
                    0,-2.95,0,6.5,.22,6.5,.28)
    for j in range(4):
        x=-6.0+j*4
        m.beveled_block("VentilatedArmorGrill_%d"%j,"CERAMIC",
                        x,-1.88,0,.95,.23,10.6,.10)
        for side in (-1,1):
            m.rod("SweptForgedRib_%d_%d"%(j,side),"ALLOY",
                  (x,-.83,side*7.46),
                  (x*.70,-2.42,side*2.68),.105,10)
    for sx in (-1,1):
        for sz in (-1,1):
            x,z=sx*6.45,sz*6.45
            m.beveled_block("CastSupportJunction_%d_%d"%(sx,sz),
                            "BRUSHED",x,-1.44,z,1.8,.34,1.8,.16)
            m.beveled_block("InsetLatticeSocket_%d_%d"%(sx,sz),
                            "CARBON",x,-1.66,z,1.27,.12,1.27,.13)
            m.beveled_block("EmissiveMaintenancePin_%d_%d"%(sx,sz),
                            "SIGNAL",x,-1.44,z,0.36,.05,.36,.045)


def emit(kind:str,path:Path)->dict:
    if kind not in MODELS: raise ValueError("Invalid original art variant")
    m=Sculpture()
    m.lines[0]="# Chaos Survival approved-only author sculpt: "+kind
    m.lines[2]="o ChaosSculpted_"+kind
    (support if kind=="support_lattice" else hull)(m)
    sizes=[round(m.maximum[i]-m.minimum[i],5) for i in range(3)]
    if set(m.materials)!=set(MATERIALS): raise ValueError("Seven materials missing")
    if not (20<=m.groups<=160 and 350<=m.triangles<=6200):
        raise ValueError("Source too simple or excessive polygons")
    x,y,z=sizes
    if kind=="support_lattice":
        valid=0.9<=x<=1.5 and 15.9<=y<=17 and .9<=z<=1.5
    else:
        valid=16.6<=x<=18 and 2.4<=y<=4.0 and 16.6<=z<=18
    if not valid: raise ValueError("Unsafe model bounding: "+str((kind,sizes)))
    path.parent.mkdir(parents=True,exist_ok=True)
    data="\n".join(m.lines)+"\n"
    path.write_text(data,encoding="utf-8")
    return {"asset":kind,"triangles":m.triangles,"groups":m.groups,
            "vertices":m.vertices,"materials":sorted(m.materials),
            "dimensions":sizes,"bounds_min":m.minimum,"bounds_max":m.maximum,
            "sha256":hashlib.sha256(data.encode()).hexdigest()}

if __name__=="__main__":
    a=argparse.ArgumentParser()
    a.add_argument("--model",choices=MODELS,required=True)
    a.add_argument("--output",type=Path,required=True)
    v=a.parse_args()
    print(json.dumps(emit(v.model,v.output),sort_keys=True))
