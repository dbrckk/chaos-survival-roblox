#!/usr/bin/env python3
"""Original southern Crossroads freight interchange monument, thirteen primitives.

The gameplay arena, northern Crossroads signature and collision primitives
stay untouched. The approved Model replaces ONLY nonphysical scenery.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NAME="south_crossroads_forged_exchange"
SCALE=2.8
CENTER_Y=22.15


def p(x,y,z):
    return (x/SCALE,(y-CENTER_Y)/SCALE,z/SCALE)


def block(a,name,material,x,y,z,sx,sy,sz,edge=.085):
    a.beveled_block(name,material,*p(x,y,z),
                    sx/SCALE,sy/SCALE,sz/SCALE,edge/SCALE)


def rod(a,name,material,a0,b0,r=.13,n=10):
    a.rod(name,material,p(*a0),p(*b0),r/SCALE,n)


def foundation(a):
    block(a,"IndustrialCrossroadsArmoredPlatform","ARMOR",
          0,-1.15,0,46.3,1.55,12.5,.24)
    block(a,"RecessedCrossroadsWalkway","CARBON",
          0,.12,0,38.75,.18,9.67,.10)
    for face in (-1,1):
        z=face*6.29
        rod(a,"ContinuousForgedPlatformRim%s"%face,"BRUSHED",
            (-22.9,-.51,z),(22.9,-.51,z),.15,10)
        for index in range(14):
            x=-21.22+index*3.25
            block(a,"ReinforcedPlatformSkirt%s_%02d"%(face,index),
                  "GRIP",x,-1.17,face*6.23,2.64,.52,.16,.06)
            rod(a,"ArcWeldedDeckBolt%s_%02d"%(face,index),"ALLOY",
                (x-.17,-1.52,face*6.31),
                (x+.17,-.86,face*6.31),.07,8)
    for index in range(15):
        x=-17.83+index*2.54
        block(a,"DiamondStampedDeckSlab%02d"%index,"CERAMIC",
              x,.246,0,2.16,.08,8.76,.037)
        for z in (-4.63,4.63):
            block(a,"NavigationLine%s_%02d"%(z,index),"SIGNAL",
                  x,.306,z,1.55,.041,.15,.017)


def exchange_core(a):
    # 12-sided tapered factory monocoque with vertical industrial profiles.
    stations=[(.1,3.52,3.53),(2,3.60,3.60),
              (12,3.25,3.18),(26,3.19,3.20),
              (37.0,3.58,3.59),(38.94,3.64,3.64)]
    sides=12
    v=[]
    for y,rx,rz in stations:
        for j in range(sides):
            t=j*math.tau/sides
            v.append(p(rx*math.cos(t),y,rz*math.sin(t)))
    faces=[]
    for station in range(len(stations)-1):
        for j in range(sides):
            n=station*sides+j
            m=station*sides+(j+1)%sides
            z=(station+1)*sides+(j+1)%sides
            o=(station+1)*sides+j
            faces.extend(((n,m,z),(n,z,o)))
    for j in range(1,sides-1):
        faces.append((0,j+1,j))
        n=(len(stations)-1)*sides
        faces.append((n,n+j,n+j+1))
    a.add("ForgedDodecagonFreightControlShaft","ARMOR",v,faces)
    for index in range(7):
        y=4+index*4.7
        block(a,"RingForgedControlShaftCollar%02d"%index,"BRUSHED",
              0,y,0,7.08,.22,7.0,.105)
        for face in (-1,1):
            z=face*3.60
            block(a,"InlaidCarbonServicePanel%s_%02d"%(face,index),
                  "CARBON",0,y+1.6,z,2.65,2.80,.085,.035)
            for slat in range(4):
                x=(slat-1.5)*.67
                block(a,"ServiceVentGrille%s_%02d_%02d"%(face,index,slat),
                      "GRIP",x,y+1.6,z+face*.047,.18,2.31,.047,.017)
    for index in range(9):
        y=4.8+index*3.58
        rod(a,"TaperedMainShaftDiode%02d"%index,"SIGNAL",
            (-3.49,y,-3.66),(-3.15,y,-3.66),.086,8)


def cantilever(a,side):
    theta=side*math.radians(14)
    cs,ss=math.cos(theta),math.sin(theta)
    def q(u,v,z):
        return (side*12+u*cs-v*ss,34+u*ss+v*cs,z)
    for zz in (-2.47,2.47):
        for vv in (-.87,.87):
            rod(a,"CantileverForgedLongChord%s_%s_%s"%(side,zz,vv),
                "BRUSHED",q(-10.1,vv,zz),q(10.1,vv,zz),.23,10)
        for i in range(11):
            u=-9.1+i*1.82
            rod(a,"WeldedCantileverDiagonals%s_%s_%02d"%(side,zz,i),
                "ALLOY",q(u-1.01,-.83,zz),q(u+.91,.85,zz),.085,8)
            rod(a,"CrossedCantileverSpine%s_%s_%02d"%(side,zz,i),
                "GRIP",q(u-1.01,.83,zz),q(u+.91,-.85,zz),.065,8)
    for i in range(10):
        u=-9.0+i*2.0
        rod(a,"BridgingGirderCrossbar%s_%02d"%(side,i),"ARMOR",
            q(u,-.65,-2.45),q(u,-.65,2.45),.13,8)


def freight_arms(a,side):
    x=side*21
    # Sculpted tapered 3D wedge-tip housing, not a WedgePart clone.
    start=x-side*4.4
    end=x+side*4.4
    vertex=[
        p(start,37.05,-2.90),p(start,37.05,2.90),
        p(start,41.0,-2.90),p(start,41.0,2.90),
        p(end,38.16,-2.32),p(end,38.16,2.32),
        p(end,40.13,-2.32),p(end,40.13,2.32),
    ]
    faces=[
        (0,1,3),(0,3,2),(0,4,5),(0,5,1),
        (0,2,6),(0,6,4),(1,5,7),(1,7,3),
        (2,3,7),(2,7,6),(4,6,7),(4,7,5),
    ]
    a.add("PressedFreightCantileverNose%s"%side,"ARMOR",vertex,faces)
    for index in range(6):
        xx=x+side*(-3.8+index*1.48)
        for z in (-2.54,2.54):
            block(a,"AngledFreightShield%s_%s_%02d"%(side,z,index),
                  "CARBON",xx,39.22,z,.53,1.70,.13,.075)
    for zz in (-2.72,2.72):
        rod(a,"AmberTransferBeacon%s_%s"%(side,zz),"SIGNAL",
            (start,40.95,zz),(end,40.08,zz),.10,10)
    for index in range(7):
        x0=x+side*(-3.72+index*1.25)
        block(a,"PrecisionWeldedShoulder%s_%02d"%(side,index),
              "CERAMIC",x0,40.38,0,.34,.16,4.65,.05)


def counterweight(a,side):
    x=side*18
    rod(a,"CastTwelveSidedFreightCounterweight%s"%side,"ARMOR",
        (x,19.05,0),(x,26.94,0),2.1,12)
    for index,y in enumerate((19.2,20.5,22,23.5,25.5,26.8)):
        block(a,"CounterweightPressedBrace%s_%02d"%(side,index),"BRUSHED",
              x,y,0,4.5,.21,4.45,.105)
        for face in (-1,1):
            block(a,"CounterweightInspectionPlate%s_%s_%02d"%(side,face,index),
                  "GRIP",x,y,face*2.26,2.23,.28,.095,.038)
    for index in range(6):
        xx=x-1.75+index*.7
        block(a,"RecessedCounterweightLiftSocket%s_%02d"%(side,index),
              "CARBON",xx,26.81,0,.38,.08,3.35,.036)


def signals(a):
    for side in (-1,1):
        x=side*15
        rod(a,"ArticulatedSevenStudRailSignal%s"%side,"SIGNAL",
            (x-3.45,36,-2.93),(x+3.45,36,-2.93),.125,10)
        for i in range(8):
            xx=x-2.95+i*.84
            block(a,"SegmentedSignalCeramicCollar%s_%02d"%(side,i),
                  "CERAMIC",xx,36,-2.93,.27,.44,.30,.046)
            block(a,"SignalColourCrystal%s_%02d"%(side,i),"SIGNAL",
                  xx,36.24,-2.93,.21,.11,.12,.033)


def command_cabin(a):
    # Full 3D cockpit: glazed slot is a recessed layered panel.
    block(a,"ArchitectedCageCabinCore","BRUSHED",0,43,0,9.35,4.55,6.55,.38)
    block(a,"InsetCommandCabinWindow","CARBON",0,43,-3.45,7.15,2.04,.22,.12)
    for i in range(8):
        x=-3.23+i*.92
        block(a,"DarkCeramicMullion%02d"%i,"CERAMIC",
              x,43,-3.61,.13,2.11,.12,.047)
    for y in (42.19,43.79):
        rod(a,"IlluminatedCabinWindowRail%s"%y,"SIGNAL",
            (-3.58,y,-3.63),(3.58,y,-3.63),.09,10)
    for x in (-4.45,4.45):
        for z in (-3.1,3.1):
            rod(a,"ForgedAccessCageStanchion%s_%s"%(x,z),"ALLOY",
                (x,40.68,z),(x,45.33,z),.21,10)
    for i in range(9):
        x=-3.7+i*.94
        block(a,"IndustrialRoofRidgeCap%02d"%i,"ARMOR",
              x,45.6,0,.42,.18,6.38,.07)
    for i in range(7):
        x=-3.1+i*1.03
        block(a,"CabinStatusDome%02d"%i,"SIGNAL",
              x,45.84,-2.60,.30,.23,.37,.062)


def export(path):
    a=Sculpture()
    a.lines[0]="# Creator-owned original Chaos Survival Crossroads south freight sculpture"
    a.lines[2]="o ChaosOriginalSouthCrossroadsForgedExchange"
    foundation(a)
    exchange_core(a)
    for side in (-1,1):
        cantilever(a,side)
        freight_arms(a,side)
        counterweight(a,side)
    signals(a)
    command_cabin(a)
    dims=[round(a.maximum[i]-a.minimum[i],5) for i in range(3)]
    center=[round((a.maximum[i]+a.minimum[i])*.5,5) for i in range(3)]
    assert set(a.materials)==set(MATERIALS),a.materials
    assert 200<=a.groups<=1250,(a.groups,a.triangles)
    assert 4500<=a.triangles<=22000,a.triangles
    assert 18.05<=dims[0]<=18.9,dims
    assert 16.6<=dims[1]<=17.8,dims
    assert 4.35<=dims[2]<=4.85,dims
    assert all(abs(v)<.85 for v in center),center
    raw="\n".join(a.lines)+"\n"
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(raw,encoding="utf-8")
    return {"asset":NAME,"triangles":a.triangles,"groups":a.groups,
            "vertices":a.vertices,"materials":sorted(a.materials),
            "bounds":dims,"center":center,
            "sha256":hashlib.sha256(raw.encode()).hexdigest()}


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    print(json.dumps(export(parser.parse_args().output),sort_keys=True))
