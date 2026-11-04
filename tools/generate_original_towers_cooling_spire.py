#!/usr/bin/env python3
"""Original *real* industrial cooling station of Tower Run (not Roblox Parts).

One source-authored 7-MeshPart UV+tangent glTF artifact replaces 5 giant
square midground mass/roof-block silhouettes on Medium/High. These are
decorative only. Source shape: 40-stud 12-sided tapered shell + 26-stud
ventilator loft and structural pressure piping. Runtime scales to each
existing cooling mass's current source height, without modifying routes.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

SOURCE_SCALE=.42
SOURCE_Y_SHIFT=31.0
NAME="towers_cooling_spire"


def build() -> Sculpture:
    art=Sculpture()
    art.lines[0]="# Chaos Survival ORIGINAL Tower Run monumental industrial cooling spire"
    art.lines[2]="o ChaosTowerRunOriginalCoolingSpire"
    def at(x,y,z):
        return (x*SOURCE_SCALE,(y-SOURCE_Y_SHIFT)*SOURCE_SCALE,z*SOURCE_SCALE)
    def block(name,mat,x,y,z,sx,sy,sz,bevel=.17):
        px,py,pz=at(x,y,z)
        art.beveled_block(name,mat,px,py,pz,
                          sx*SOURCE_SCALE,sy*SOURCE_SCALE,sz*SOURCE_SCALE,
                          bevel*SOURCE_SCALE)
    def rod(name,mat,start,end,r=.13,sides=8):
        art.rod(name,mat,at(*start),at(*end),r*SOURCE_SCALE,sides)
    def tapered(name,mat,cx,cz,stations,sides=12):
        # A continuous CLOSED twelve-sided industrial shell. Unlike a
        # primitive Cylinder, per-level radii are different, with forged
        # constrictions and a broad reactor-diameter stabilizing base.
        verts=[]
        for y,rx,rz in stations:
            for i in range(sides):
                a=math.tau*i/sides
                verts.append(at(cx+rx*math.cos(a),y,cz+rz*math.sin(a)))
        fs=[]
        for k in range(len(stations)-1):
            for i in range(sides):
                j=(i+1)%sides
                a=k*sides+i;b=k*sides+j;c=(k+1)*sides+j;d=(k+1)*sides+i
                fs.extend(((a,b,c),(a,c,d)))
        for i in range(1,sides-1):
            fs.append((0,i+1,i))
            top=(len(stations)-1)*sides
            fs.append((top,top+i,top+i+1))
        art.add(name,mat,verts,fs)
    def torus(name,mat,cx,y,cz,major,minor,radial=16,tube=6):
        pts=[]
        for i in range(radial):
            a=math.tau*i/radial
            for j in range(tube):
                b=math.tau*j/tube
                r=major+minor*math.cos(b)
                pts.append(at(cx+r*math.cos(a),
                              y+minor*math.sin(b),
                              cz+r*math.sin(a)))
        fs=[]
        for i in range(radial):
            for j in range(tube):
                a=i*tube+j;b=((i+1)%radial)*tube+j
                c=((i+1)%radial)*tube+(j+1)%tube
                d=i*tube+(j+1)%tube
                fs.extend(((a,b,c),(a,c,d)))
        art.add(name,mat,pts,fs)

    # Shaft body: original true volumetric facets, not a decorative
    # flat-printed cylinder. The below-ground anchor is NOT walkable.
    tapered("TwelveSidedTaperedPressureCore","ARMOR",0,0,[
        (-.7,5.20,5.25),(1.9,5.48,5.38),(6.8,4.55,4.65),
        (12,4.23,4.25),(23,4.00,4.06),(32,4.26,4.40),
        (38.4,4.98,4.98),(40.8,5.32,5.34)])
    block("CastReactorFootprintPlate","BRUSHED",
          0,.18,0,11.72,1.12,11.70,.44)
    block("SubterraneanPressurePlinth","CARBON",
          0,-.62,0,10.6,.34,10.58,.25)
    block("FirstPressureRingLowerDeck","GRIP",
          0,5.8,0,10.46,.40,10.45,.28)
    block("SecondPressureRingCrown","BRUSHED",
          0,39.18,0,11.40,.66,11.45,.43)
    block("LoadBearingServiceSupport","ARMOR",
          0,41.35,0,10.2,1.8,10.3,.39)
    # Equally spaced forged angular fin arrays on two concentric stages,
    # with machined horizontal rib-fasteners and insulated feed pipes.
    for i in range(12):
        a=math.tau*i/12
        co,si=math.cos(a),math.sin(a)
        x,z=co*4.47,si*4.47
        rod(f"PrecisionVerticalCoolingFin{i}","BRUSHED",
            (x,6.4,z),(co*4.88,38.2,si*4.88),.24,10)
        rod(f"FinnedOuterDrainPipe{i}","ALLOY",
            (co*5.13,5.0,si*5.13),
            (co*5.44,39.80,si*5.44),.090,8)
        for level in (10.2,22.3,34.0):
            block(f"GalvanizedRibFastener_{i}_{int(level)}","GRIP",
                  x,level,z,.80,.20,.78,.045)
        for n in range(3):
            y=8.4+n*11.5
            block(f"MachinedTowerVentInsert_{i}_{n}","CERAMIC",
                  co*4.12,y,si*4.12,.79,2.2,.36,.105)
    for y,r in ((12,4.33),(23.5,4.21),(34.1,4.45)):
        torus(f"ClosedExternalReinforcingBand{int(y*10)}","BRUSHED",
              0,y,0,r,.24,16,6)
    # Exposed 16-sided *tapered chimney assembly*, not a rectangular
    # topper. The opening is sculpted as a dark recessed inner exhaust.
    tapered("SixteenSidedPrimaryVentilationChimney","CARBON",0,0,[
        (41.15,3.25,3.25),(43.2,4.38,4.42),
        (51.2,3.70,3.75),(59.6,2.98,3.04),
        (64.4,3.1,3.15),(66.8,3.70,3.72)],16)
    torus("WideForgedVentTorusCap","ALLOY",0,66.9,0,3.36,.44,20,8)
    block("RecessedVentAirOutlet","CARBON",
          0,67.01,0,4.9,.15,4.9,.19)
    torus("TurbineRotorServiceRing","BRUSHED",
          0,59.7,0,3.13,.26,16,6)
    for i in range(12):
        a=math.tau*i/12
        x,z=math.cos(a)*3.31,math.sin(a)*3.31
        rod(f"ExhaustSpiralProtectiveBracing{i}","ALLOY",
            (x,45, z),(math.cos(a+.21)*2.82,63.8,
                       math.sin(a+.21)*2.82),.115,8)
    for sign in (-1,1):
        # Low silhouette reads as a true machinery installation with
        # asymmetrically mounted feed tanks and a separately braced gantry.
        x=sign*6.26
        tapered("DualAuxiliaryRegulationVessel"+str(sign),"ARMOR",x,0,[
            (5.5,1.28,1.32),(7.3,1.52,1.55),
            (16.5,1.48,1.55),(20.0,1.13,1.15)],12)
        for y in (7.05,13.7,19.4):
            torus(f"PressureReservoirBand_{sign}_{y}","BRUSHED",
                  x,y,0,1.50,.15,12,6)
        rod("SlopedServiceFeed"+str(sign),"ALLOY",
            (x,19.0,.6),(sign*3.92,36.3,1.18),.22,12)
        rod("SecondPressureCutoffPipe"+str(sign),"ALLOY",
            (x,7.2,-.8),(sign*5.42,40.2,-1.02),.11,8)
        block("SideControlCabinet"+str(sign),"CERAMIC",
              sign*5.65,30.25,-1.14,1.35,3.05,1.20,.27)
        block("DangerSignalPlate"+str(sign),"SIGNAL",
              sign*5.68,31.1,-1.83,.84,.26,.09,.045)
        rod("CabinetInsulatedCantilever"+str(sign),"BRUSHED",
            (x,28.8,1.2),(sign*3.8,34.0,1.6),.17,10)
    # Dynamic airflow can be represented by the static 3D turbine
    # blades without one more RenderStepped or nonessential particle emitter.
    for i in range(8):
        a=math.tau*i/8
        x,z=math.cos(a)*2.22,math.sin(a)*2.22
        rod(f"RotorGuideFin{i}","GRIP",
            (x,66.8,z),(math.cos(a+.29)*.92,68.4,
                        math.sin(a+.29)*.92),.22,8)
    block("HighLevelStormSafetyMark","SIGNAL",
          0,39.75,-5.89,2.15,.13,.12,.03)
    assert art.materials==set(MATERIALS), art.materials
    assert 120 <= art.groups <= 255, art.groups
    assert 3000 <= art.triangles <= 9500, art.triangles
    return art


def export(output:Path):
    model=build()
    bounds=[round(model.maximum[i]-model.minimum[i],5) for i in range(3)]
    mid=[round((model.minimum[i]+model.maximum[i])*.5,5) for i in range(3)]
    assert 5.0<=bounds[0]<=7.5,bounds
    assert 28.2<=bounds[1]<=31.0,bounds
    assert 4.7<=bounds[2]<=7.5,bounds
    output.parent.mkdir(parents=True,exist_ok=True)
    body="\n".join(model.lines)+"\n"
    output.write_text(body,encoding="utf8")
    return {"name":NAME,"triangles":model.triangles,"groups":model.groups,
            "vertices":model.vertices,"materials":sorted(model.materials),
            "bounds_min":model.minimum,"bounds_max":model.maximum,
            "bounds_center":mid,"dimensions":bounds,
            "source_scale":SOURCE_SCALE,"source_y_shift":SOURCE_Y_SHIFT,
            "sha256":hashlib.sha256(body.encode()).hexdigest()}


if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))
