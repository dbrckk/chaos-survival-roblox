#!/usr/bin/env python3
"""Original South Classic twin radar telescope observatory sculpture.

A creator-owned sculpted 13-target nonphysical monument. Curved parabolic
radar dishes replace primitive cylinders and keep an unobstructed aperture.
Distinct from the already approved Classic northern twin-dish observatory.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

NAME="south_classic_sculpted_observatory"
SCALE=2.5
CENTER_Y=19.05


def p(x,y,z):
    return x/SCALE,(y-CENTER_Y)/SCALE,z/SCALE


def block(a,name,material,x,y,z,sx,sy,sz,edge=.07):
    a.beveled_block(name,material,*p(x,y,z),
                    sx/SCALE,sy/SCALE,sz/SCALE,edge/SCALE)


def rod(a,name,material,pa,pb,radius=.12,sides=10):
    a.rod(name,material,p(*pa),p(*pb),radius/SCALE,sides)


def ellipsoid(a,name,material,cx,cy,cz,rx,ry,rz,segments=20,rows=10):
    vertices=[]
    triangles=[]
    for j in range(rows+1):
        theta=math.pi*j/rows
        for i in range(segments):
            phi=math.tau*i/segments
            vertices.append(p(cx+rx*math.sin(theta)*math.cos(phi),
                              cy+ry*math.cos(theta),
                              cz+rz*math.sin(theta)*math.sin(phi)))
    for j in range(rows):
        for i in range(segments):
            u=j*segments+i
            v=j*segments+(i+1)%segments
            w=(j+1)*segments+(i+1)%segments
            z=(j+1)*segments+i
            if j>0: triangles.append((u,v,w))
            if j<rows-1: triangles.append((u,w,z))
    a.add(name,material,vertices,triangles)


def platform(a):
    block(a,"OriginalForgedClassicTelemetryPlatform","ARMOR",
          0,-1.13,0,46.35,1.56,12.35,.24)
    block(a,"CarbonUndercutObservationDeck","CARBON",
          0,.13,0,38.7,.16,9.68,.10)
    for side in (-1,1):
        z=side*6.29
        rod(a,"ContinuousMachinedPlatformRim%s"%side,"BRUSHED",
            (-22.9,-.46,z),(22.9,-.46,z),.17,10)
        for i in range(10):
            x=-21.2+i*4.70
            block(a,"MilledPlatformArmorSegment%s_%02d"%(side,i),"GRIP",
                  x,-1.15,z,2.75,.58,.20,.065)
            rod(a,"RetainedPlatformLoadStud%s_%02d"%(side,i),"ALLOY",
                (x,-1.50,z+side*.14),(x,-.80,z+side*.14),.069,8)
    for i in range(12):
        x=-18.0+i*3.27
        block(a,"CeramicOriginalRadarFloorTile%02d"%i,"CERAMIC",
              x,.26,0,2.52,.06,9.03,.031)
        for side in (-1,1):
            block(a,"InsetOriginalRadarGuideLight%s_%02d"%(side,i),
                  "SIGNAL",x,.31,side*4.65,.87,.05,.12,.018)


def tower(a,side):
    x=side*16
    n=12
    levels=[(.07,1.54,2.03),(2.0,1.63,2.11),
            (9,1.43,1.88),(21.5,1.43,1.89),
            (27.95,1.63,2.1)]
    verts=[]
    for y,rx,rz in levels:
        for i in range(n):
            t=i*math.tau/n
            verts.append(p(x+rx*math.cos(t),y,rz*math.sin(t)))
    tris=[]
    for j in range(len(levels)-1):
        for i in range(n):
            q=j*n+i
            r=j*n+(i+1)%n
            t=(j+1)*n+(i+1)%n
            u=(j+1)*n+i
            tris.extend(((q,r,t),(q,t,u)))
    for i in range(1,n-1):
        tris.append((0,i+1,i))
        cap=(len(levels)-1)*n
        tris.append((cap,cap+i,cap+i+1))
    a.add("TwelveFacetSouthernRadarLoadPylon%s"%side,"ARMOR",verts,tris)
    for i in range(6):
        y=2.6+i*4.38
        block(a,"ForgedPylonServiceCollar%s_%02d"%(side,i),"BRUSHED",
              x,y,0,3.34,.26,4.27,.125)
        for face in (-1,1):
            z=face*2.08
            block(a,"DuctedCarbonPylonVent%s_%s_%02d"%(side,face,i),
                  "CARBON",x,y+1.45,z,2.19,2.31,.10,.036)
            for slat in range(2):
                xx=x+(slat-.5)*.75
                block(a,"PressedPylonVentRib%s_%s_%02d_%02d"%
                      (side,face,i,slat),"GRIP",
                      xx,y+1.47,z+face*.067,.18,1.80,.061,.023)
    for i in range(9):
        y=3.5+i*2.52
        block(a,"OriginalTelemetryPylonIndicator%s_%02d"%(side,i),
              "SIGNAL",x+1.54,y,-2.20,.30,.27,.10,.033)


def dish(a,side):
    """Double-sided 36×7 triangulated PARABOLOID, not Cylinder/Wedge."""
    x=side*16
    radii=[0.0,.95,1.95,2.9,3.9,4.9,5.9]
    sectors=36
    def zprofile(r):
        return .78-.058*r*r
    for surface,material,offset in (
        ("ConcaveReflector","CERAMIC",0),
        ("ForgedRearDishShell","ARMOR",.18),
    ):
        verts=[]
        faces=[]
        for radius in radii:
            for i in range(sectors):
                t=math.tau*i/sectors
                verts.append(p(x+radius*math.cos(t),
                               34+radius*math.sin(t),
                               zprofile(radius)+offset))
        for level in range(len(radii)-1):
            for i in range(sectors):
                u=level*sectors+i
                v=level*sectors+(i+1)%sectors
                w=(level+1)*sectors+(i+1)%sectors
                z=(level+1)*sectors+i
                if level==0:
                    faces.append((u,z,w))
                else:
                    faces.extend(((u,v,w),(u,w,z)))
        a.add("%sClassicSouthTelescope%s"%(surface,side),
              material,verts,faces)
    # Genuinely curved segmented 3D rim, radial support ribs and wiring.
    for i in range(sectors):
        angle=i*math.tau/sectors
        nxt=(i+1)*math.tau/sectors
        rimz=zprofile(5.9)
        rod(a,"RolledDishApertureRim%s_%02d"%(side,i),"ALLOY",
            (x+5.9*math.cos(angle),34+5.9*math.sin(angle),rimz),
            (x+5.9*math.cos(nxt),34+5.9*math.sin(nxt),rimz),
            .13,8)
    for i in range(16):
        t=i*math.tau/16
        rod(a,"MachinedSpokedReflectorStay%s_%02d"%(side,i),"BRUSHED",
            (x+1.20*math.cos(t),34+1.20*math.sin(t),.98),
            (x+5.65*math.cos(t),34+5.65*math.sin(t),
             zprofile(5.65)+.20),.105,8)
        radius=5.88
        block(a,"RecessedDishApertureMarker%s_%02d"%(side,i),"SIGNAL",
              x+radius*math.cos(t),34+radius*math.sin(t),
              zprofile(radius)-.10,.19,.20,.10,.04)
    # Separate glass receiver from the dish for 3D structural authenticity.
    ellipsoid(a,"FacetedOpticalReceiver%s"%side,"CARBON",
              x,34,-2.2,1.02,1.02,1.02,20,10)
    ellipsoid(a,"OriginalSignalLens%s"%side,"SIGNAL",
              x,34,-3.06,.59,.59,.16,20,10)
    for i in range(8):
        angle=i*math.tau/8
        dx,dy=math.cos(angle),math.sin(angle)
        rod(a,"ReceiverOpticalAlignmentBoom%s_%02d"%(side,i),"GRIP",
            (x+.92*dx,34+.92*dy,-2.4),
            (x+1.70*dx,34+1.70*dy,-.23),.073,8)
    for i in range(4):
        xx=x+(i-1.5)*.35
        block(a,"CeramicReceiverIdentityMark%s_%02d"%(side,i),
              "CERAMIC",xx,33.96,-3.23,.20,.30,.08,.028)


def service_brace(a,side):
    phi=side*math.radians(28)
    vx,vy=-math.sin(phi),math.cos(phi)
    cx,cy=side*8,17
    def pos(t,dx=0,dz=0):
        return cx+vx*t+dx,cy+vy*t,dz
    for dx in (-.22,.22):
        for dz in (-.31,.31):
            rod(a,"ForgedClassicAxialServiceStay%s_%s_%s"%
                (side,dx,dz),"ALLOY",
                pos(-11.8,dx,dz),pos(11.8,dx,dz),.091,8)
    rod(a,"ClassicDuctedBraceCore%s"%side,"ARMOR",
        pos(-11.9),pos(11.9),.21,12)
    for i in range(8):
        x,y,z=pos(-11.2+i*3.14)
        block(a,"FlangedBraceElectricalClamp%s_%02d"%(side,i),
              "BRUSHED",x,y,z,.72,.26,1.18,.068)
        block(a,"InlaidServiceBraceMonitor%s_%02d"%(side,i),
              "SIGNAL",x,y+.09,-.63,.29,.16,.073,.026)


def observatory_bridge(a):
    for side in (-1,1):
        z=side*2.38
        for height in (23.24,24.74):
            rod(a,"ThickTelescopeInterconnectChord%s_%s"%(side,height),
                "ARMOR",(-17.25,height,z),(17.25,height,z),.24,10)
        for i in range(12):
            x=-16.4+i*2.83
            rod(a,"OpenServiceBridgeTruss%s_%02d"%(side,i),"ALLOY",
                (x-1.07,23.23,z),(x+1.12,24.71,z),.087,8)
    block(a,"CarbonObservationBridgeDeck","CARBON",
          0,24,0,34.55,.20,4.90,.09)
    for i in range(12):
        x=-16.5+i*3
        rod(a,"CrossedRadarBridgeBearing%02d"%i,"BRUSHED",
            (x,23.84,-2.35),(x,23.84,2.35),.093,8)
        block(a,"ServiceBridgeGripInlay%02d"%i,"GRIP",
              x,24.15,0,.39,.06,4.55,.025)
    for i in range(8):
        x=-15.2+i*4.34
        block(a,"CeramicBridgeServiceLight%02d"%i,"SIGNAL",
              x,24.86,-2.34,.31,.14,.18,.04)


def control_cabin(a):
    block(a,"BeveledClassicSouthObservationCockpit","BRUSHED",
          0,27,0,7.65,7.65,6.62,.33)
    block(a,"DeepCarbonOpticalGlassRecess","CARBON",
          0,29,-3.57,6.15,2.96,.21,.12)
    for i in range(7):
        x=-2.84+i*.95
        block(a,"PunchedObservatoryWindowMullion%02d"%i,
              "CERAMIC",x,29,-3.72,.12,3.01,.11,.043)
    for y in (27.65,30.42):
        rod(a,"ForgedCabinGlazingFrame%s"%y,"ALLOY",
            (-3.08,y,-3.74),(3.08,y,-3.74),.10,8)
    for x in (-3.61,3.61):
        for z in (-3.06,3.06):
            rod(a,"ObservationCabinSafetySpar%s_%s"%(x,z),"ARMOR",
                (x,23.27,z),(x,30.72,z),.15,10)
    for i in range(8):
        x=-3.1+i*.88
        block(a,"IndustrialCockpitRoofFin%02d"%i,"GRIP",
              x,30.95,0,.26,.28,6.10,.056)
    for i in range(5):
        x=-2.18+i*1.1
        block(a,"CabinSignalLocator%02d"%i,"SIGNAL",
              x,30.95,-2.8,.35,.18,.22,.037)


def export(path):
    a=Sculpture()
    a.lines[0]="# Original creator-owned South Classic dual parabolic telescope monument"
    a.lines[2]="o ChaosOriginalSouthClassicSculptedObservatory"
    platform(a)
    for side in (-1,1):
        tower(a,side)
        dish(a,side)
        service_brace(a,side)
    observatory_bridge(a)
    control_cabin(a)
    dims=[round(a.maximum[i]-a.minimum[i],5) for i in range(3)]
    center=[round((a.maximum[i]+a.minimum[i])*.5,5) for i in range(3)]
    assert set(a.materials)==set(MATERIALS),a.materials
    assert 160<=a.groups<=512,(a.groups,a.triangles)
    assert 4000<=a.triangles<=16000,a.triangles
    assert 18.35<=dims[0]<=19.05,dims
    assert 16.5<=dims[1]<=17.1,dims
    assert 5.00<=dims[2]<=5.35,dims
    assert all(abs(v)<.5 for v in center),center
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
