#!/usr/bin/env python3
"""Original triangulated South Towers sky-transfer: NOT a native Part.

Source-only until owner-approved Roblox Model import. Replaces the native
SouthHorizonMonument SkyTransfer and UnderslungLift shapes together, leaving
the real two lift towers, rails, suspension and signal native and intact.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

NAME="south_towers_forged_skytransfer"
# Original SkyTransfer x40 y2.1 z6, center (0,36,0).
# Original UnderslungLift x7 y7 z6, center (3.5,31.5,0).
# Union x[-20,20], y[28,37.05], z[-3,3]; center (0,32.525,0).
CENTER_Y=32.525
SCALE=2.0

def point(x,y,z):
    return (x/SCALE,(y-CENTER_Y)/SCALE,z/SCALE)

def block(a,name,mat,x,y,z,sx,sy,sz,e=.07):
    a.beveled_block(name,mat,*point(x,y,z),
                    sx/SCALE,sy/SCALE,sz/SCALE,e/SCALE)

def rod(a,name,mat,p,q,r=.10,n=8):
    a.rod(name,mat,point(*p),point(*q),r/SCALE,n)

def build():
    a=Sculpture()
    a.lines[0]="# Original Chaos Survival South Towers forged transfer"
    a.lines[2]="o ChaosOriginalSouthTowersForgedSkyTransfer"
    # Hollow, profiled twin longitudinal decks instead of a single cuboid.
    for side in (-1,1):
        z=side*2.28
        rod(a,"ContinuousTenSidedLoadChord%s"%side,"ARMOR",
            (-19.65,36.55,z),(19.65,36.55,z),.43,10)
        rod(a,"LowerSuspensionChord%s"%side,"BRUSHED",
            (-18.9,34.90,z),(18.9,34.90,z),.22,10)
        for i in range(12):
            x=-18.1+i*3.28
            rod(a,"DiagonalForgedTruss%s_%02d"%(side,i),"ALLOY",
                (x-1.3,34.91,z),(x+1.3,36.55,z),.115,8)
            rod(a,"CrossBracedTransfer%s_%02d"%(side,i),"GRIP",
                (x-1.12,36.48,z),(x+1.12,34.98,z),.063,8)
    block(a,"RecessedTreadPlate","CARBON",0,36.76,0,39.0,.22,5.1,.09)
    for i in range(18):
        x=-18.4+i*2.17
        block(a,"ForgedTreadRelief%02d"%i,"GRIP",
              x,36.89,0,.36,.07,4.54,.027)
    # 7x7x6 original hanging lift is a true cage, not a solid brick.
    for sx in (-1,1):
        for sz in (-1,1):
            rod(a,"HangingLiftCorner%s_%s"%(sx,sz),"ARMOR",
                (3.5+sx*3.23,28.25,sz*2.73),
                (3.5+sx*3.23,35.05,sz*2.73),.23,10)
    for y in (28.25,29.25,34.65,35.05):
        for side in (-1,1):
            z=side*2.73
            rod(a,"LiftDeckFrame%s_%s"%(y,side),"BRUSHED",
                (.27,y,z),(6.73,y,z),.15,8)
        for side in (-1,1):
            x=3.5+side*3.23
            rod(a,"LiftSideFrame%s_%s"%(y,side),"BRUSHED",
                (x,y,-2.73),(x,y,2.73),.15,8)
    block(a,"SuspendedLiftDeck","CERAMIC",3.5,28.32,0,6.15,.22,5.2,.12)
    block(a,"SuspendedLiftRoof","CARBON",3.5,35.02,0,6.15,.20,5.2,.12)
    for i in range(5):
        x=.95+i*1.27
        rod(a,"VisibleCableGrille%02d"%i,"ALLOY",
            (x,29.1,-2.75),(x,34.1,-2.75),.072,8)
    for i in range(7):
        x=-16.8+i*5.6
        block(a,"TransferNavigationLamp%02d"%i,"SIGNAL",
              x,36.90,-2.6,.40,.10,.10,.034)
    for i in range(6):
        x=-16.8+i*6.72
        block(a,"CeramicWeldedAnchor%02d"%i,"CERAMIC",
              x,36.48,2.52,.47,.19,.20,.05)
    return a

def export(path):
    a=build()
    dims=[round(a.maximum[i]-a.minimum[i],5) for i in range(3)]
    center=[round((a.maximum[i]+a.minimum[i])*.5,5) for i in range(3)]
    assert set(a.materials)==set(MATERIALS)
    assert 50<=a.groups<=300,(a.groups,a.triangles)
    assert 1300<=a.triangles<=9000,a.triangles
    assert 19.5<=dims[0]<=20.4,dims
    assert 4.35<=dims[1]<=4.85,dims
    assert 2.75<=dims[2]<=3.2,dims
    assert abs(center[0])<.3 and abs(center[1])<.3 and abs(center[2])<.3,center
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
