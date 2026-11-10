#!/usr/bin/env python3
"""Original South Towers twin lift shafts and crowns, seven real PBR groups.

Cosmetic replacement candidates: WestLift, EastLift, WestCrown, EastCrown.
The approved skytransfer and all rails/suspensions remain independent.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

NAME="south_towers_forged_lift_twins"
SCALE=2.5
CENTER_Y=25.0

def pt(x,y,z):
    return x/SCALE,(y-CENTER_Y)/SCALE,z/SCALE

def block(a,n,m,x,y,z,sx,sy,sz,edge=.09):
    a.beveled_block(n,m,*pt(x,y,z),sx/SCALE,sy/SCALE,sz/SCALE,edge/SCALE)

def rod(a,n,m,p,q,r=.12,sides=10):
    a.rod(n,m,pt(*p),pt(*q),r/SCALE,sides)

def tapered_shell(a,side,height):
    x=side*17.5
    # Real 12-facet tapered load-bearing shell, not a Roblox Part.
    levels=[(.08,3.05,3.35),(2.1,3.14,3.43),
            (height*.30,2.94,3.22),(height*.67,2.91,3.18),
            (height-1.5,3.04,3.35),(height-.05,3.10,3.40)]
    v=[]
    for y,rx,rz in levels:
        for k in range(12):
            t=math.tau*k/12
            v.append(pt(x+rx*math.cos(t),y,rz*math.sin(t)))
    faces=[]
    for j in range(len(levels)-1):
        for k in range(12):
            u=j*12+k
            w=j*12+(k+1)%12
            z=(j+1)*12+(k+1)%12
            q=(j+1)*12+k
            faces.extend(((u,w,z),(u,z,q)))
    for k in range(1,11):
        faces.append((0,k+1,k))
        u=(len(levels)-1)*12
        faces.append((u,u+k,u+k+1))
    a.add("TwelveFacetForgedLiftShell%s"%side,"ARMOR",v,faces)
    for i in range(5):
        y=4+i*(height-8)/4
        block(a,"MachinedVerticalCollar%s_%02d"%(side,i),"BRUSHED",
              x,y,0,6.2,.28,6.7,.12)
    for face in (-1,1):
        z=face*3.39
        for i in range(7):
            y=4+i*(height-7)/7
            block(a,"RecessedVentPanel%s_%s_%02d"%(side,face,i),
                  "CARBON",x,y,z,3.55,2.7,.12,.04)
            for j in range(4):
                xx=x+(j-1.5)*.73
                block(a,"VentRib%s_%s_%02d_%02d"%(side,face,i,j),
                      "GRIP",xx,y,z+face*.085,.17,2.26,.07,.025)
    for i in range(8):
        y=2.9+i*(height-6)/8
        block(a,"InlaidLiftTelemetry%s_%02d"%(side,i),"SIGNAL",
              x+2.05,y,-3.48,.28,.49,.075,.03)
    # Crown is a sculpted multi-ring crown with a peaked machinery roof.
    crownY=height+2
    for z in (-3.15,3.15):
        rod(a,"ForgedCrownOuterChord%s_%s"%(side,z),"ALLOY",
            (x-4.42,crownY,z),(x+4.42,crownY,z),.29,10)
        for i in range(6):
            xx=x-3.9+i*1.56
            rod(a,"CrownDiagonalBrace%s_%s_%02d"%(side,z,i),"BRUSHED",
                (xx,crownY-1.75,z),(xx+1.1,crownY+1.9,z),.12,8)
    for xx in (x-4.2,x+4.2):
        rod(a,"CrownCrossbeam%s_%s"%(side,xx),"ALLOY",
            (xx,crownY,-3.25),(xx,crownY,3.25),.26,10)
    for i in range(9):
        xx=x-3.65+i*.91
        block(a,"CeramicCrownFin%s_%02d"%(side,i),"CERAMIC",
              xx,crownY+2.03,0,.23,.33,5.65,.07)
    for i in range(5):
        xx=x-2.85+i*1.42
        block(a,"CrownSafetyLamp%s_%02d"%(side,i),"SIGNAL",
              xx,crownY-1.4,-3.44,.35,.12,.10,.03)

def export(path):
    a=Sculpture()
    a.lines[0]="# Original Chaos Survival South Towers dual sculpted lift shafts"
    a.lines[2]="o ChaosOriginalSouthTowersForgedLiftTwins"
    tapered_shell(a,-1,37)
    tapered_shell(a,1,46)
    dims=[round(a.maximum[i]-a.minimum[i],5) for i in range(3)]
    center=[round((a.maximum[i]+a.minimum[i])*.5,5) for i in range(3)]
    assert set(a.materials)==set(MATERIALS),a.materials
    assert 100<=a.groups<=700,(a.groups,a.triangles)
    assert 2500<=a.triangles<=14000,a.triangles
    assert 17.4<=dims[0]<=18.0,dims
    assert 19.5<=dims[1]<=21.0,dims
    assert 2.65<=dims[2]<=3.2,dims
    assert abs(center[0])<.2 and abs(center[1])<.5 and abs(center[2])<.2,center
    raw="\n".join(a.lines)+"\n"
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(raw,encoding="utf-8")
    return {"asset":NAME,"triangles":a.triangles,"groups":a.groups,
            "vertices":a.vertices,"materials":sorted(a.materials),
            "bounds":dims,"center":center,
            "sha256":hashlib.sha256(raw.encode()).hexdigest()}

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--output",type=Path,required=True)
    print(json.dumps(export(p.parse_args().output),sort_keys=True))
