#!/usr/bin/env python3
"""Original South Orbital monument finishing sculpture.

Replaces only Foundation, FloorInset, LeftRingSupport, RightRingSupport,
SuspendedOrb (actual sphere), and OrbClamp. The separately approved 14-arc
South observation torus remains visible and owned by its own LOD kit.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NAME = "south_orbital_forged_finishing"
SCALE = 2.5
CENTER_Y = 12.35


def p(x, y, z):
    return x/SCALE, (y-CENTER_Y)/SCALE, z/SCALE


def block(a, name, material, x,y,z,sx,sy,sz,edge=.07):
    a.beveled_block(name,material,*p(x,y,z),
                    sx/SCALE,sy/SCALE,sz/SCALE,edge/SCALE)


def rod(a,name,material,origin,target,radius=.12,faces=10):
    a.rod(name,material,p(*origin),p(*target),radius/SCALE,faces)


def ellipsoid(a,name,material,cx,cy,cz,rx,ry,rz,longitudes=28,latitudes=14):
    verts=[]
    faces=[]
    for j in range(latitudes+1):
        theta=math.pi*j/latitudes
        for i in range(longitudes):
            angle=math.tau*i/longitudes
            verts.append(p(cx+rx*math.sin(theta)*math.cos(angle),
                           cy+ry*math.cos(theta),
                           cz+rz*math.sin(theta)*math.sin(angle)))
    for j in range(latitudes):
        for i in range(longitudes):
            k=j*longitudes+i
            nxt=j*longitudes+(i+1)%longitudes
            below=(j+1)*longitudes+i
            below_n=(j+1)*longitudes+(i+1)%longitudes
            if j>0:
                faces.append((k,nxt,below_n))
            if j<latitudes-1:
                faces.append((k,below_n,below))
    a.add(name,material,verts,faces)


def armored_plinth(a):
    # Chamfered stacked forged stone skin and real tactile floor relief.
    block(a,"BeveledOrbitalPlinthChassis","ARMOR",
          0,-1.12,0,46.35,1.57,12.42,.27)
    for side in (-1,1):
        z=side*6.26
        rod(a,"ExtrudedLongitudinalAlloyPlinthRim%s"%side,"ALLOY",
            (-22.83,-.42,z),(22.83,-.42,z),.20,10)
        for i in range(14):
            x=-21.27+i*3.27
            block(a,"MachinedPlinthReliefPanel%s_%02d"%(side,i),"GRIP",
                  x,-1.04,side*6.28,2.67,.63,.12,.055)
            rod(a,"PrecisionTensionRivet%s_%02d"%(side,i),"BRUSHED",
                (x,-1.47,z+side*.13),(x,-.71,z+side*.13),.063,8)
    block(a,"RecessedCarbonAssemblyFloor","CARBON",
          0,.12,0,38.62,.18,9.60,.12)
    for i in range(16):
        x=-18.05+i*2.407
        block(a,"RadialCeramicFloorInlay%02d"%i,"CERAMIC",
              x,.255,0,2.04,.056,8.89,.024)
        for side in (-1,1):
            block(a,"DeckNavigationLight%s_%02d"%(side,i),"SIGNAL",
                  x,.291,side*4.48,1.02,.043,.14,.022)
    for x in (-21.6,21.6):
        for z in (-4.6,4.6):
            block(a,"BoltOnAnchorShoe%s_%s"%(x,z),"BRUSHED",
                  x,-.39,z,1.29,.22,1.29,.09)


def profiled_supports(a):
    # Two tapered twelve-sided pylons; real rods, collars, vented panels.
    for side in (-1,1):
        x=side*15.5
        levels=[
            (.05,1.14,1.31),(2.0,1.19,1.33),
            (7.0,.97,1.18),(14.0,1.04,1.25),
            (21.4,1.18,1.29),(22.96,1.24,1.35),
        ]
        sides=12
        verts=[]
        for y,rx,rz in levels:
            for i in range(sides):
                angle=i*math.tau/sides
                verts.append(p(x+rx*math.cos(angle),y,rz*math.sin(angle)))
        tris=[]
        for level in range(len(levels)-1):
            for i in range(sides):
                start=level*sides+i
                next_v=level*sides+(i+1)%sides
                upper=(level+1)*sides+(i+1)%sides
                end=(level+1)*sides+i
                tris.extend(((start,next_v,upper),(start,upper,end)))
        for i in range(1,sides-1):
            tris.append((0,i+1,i))
            cap=(len(levels)-1)*sides
            tris.append((cap,cap+i,cap+i+1))
        a.add("ForgedTwelveFacetOrbitalRingPylon%s"%side,"ARMOR",verts,tris)
        for i in range(6):
            y=2.5+i*3.65
            block(a,"DieCastPylonRim%s_%02d"%(side,i),"BRUSHED",
                  x,y,0,2.51,.26,2.84,.095)
            for face in (-1,1):
                z=face*1.39
                block(a,"InsetPylonCarbonVent%s_%s_%02d"%(side,face,i),
                      "CARBON",x,y+1.13,z,1.62,1.78,.095,.035)
                for j in range(3):
                    xx=x+(j-1)*.40
                    block(a,"WeldedPylonVentRib%s_%s_%02d_%02d"%
                          (side,face,i,j),"GRIP",
                          xx,y+1.16,z+face*.06,.14,1.40,.055,.022)
        for index in range(6):
            y=3.25+index*3.44
            for face in (-1,1):
                rod(a,"PylonPowerLead%s_%s_%02d"%(side,face,index),
                    (x+side*1.16,y,face*.79),
                    (x+side*1.16,y+2.3,face*.79),.085,8)
            block(a,"PylonRetainedCeramicStatus%s_%02d"%(side,index),
                  "SIGNAL",x,y+.68,-1.44,.36,.28,.065,.025)


def reactor_sphere(a):
    # The center stays a real multilayer SPHERE, not a square plate/disc.
    ellipsoid(a,"GeodesicOrbitalGlassCore","CERAMIC",0,23,0,
              3.14,3.14,3.14,36,18)
    ellipsoid(a,"InnerShieldedEnergyNucleus","SIGNAL",0,23,0,
              2.62,2.62,2.62,28,14)
    # Sculpted lateral jewel ribs and external curved retaining louvres.
    for latitude in (-.75,0,.75):
        radius=math.sqrt(max(0.001,3.19**2-latitude**2))
        count=32
        for i in range(count):
            angle=i*math.tau/count
            nxt=(i+1)*math.tau/count
            rod(a,"CurvedOrbitalRetainingRim%s_%02d"%(latitude,i),
                "ALLOY",
                (radius*math.cos(angle),23+latitude,
                 radius*math.sin(angle)),
                (radius*math.cos(nxt),23+latitude,
                 radius*math.sin(nxt)),.082,8)
    for i in range(24):
        angle=i*math.tau/24
        x,z=3.18*math.cos(angle),3.18*math.sin(angle)
        rod(a,"RadialOrbitalGlassFacet%s"%i,"BRUSHED",
            (x,22.73,z),(x,23.27,z),.046,8)
    for i in range(12):
        angle=i*math.tau/12
        x,z=3.12*math.cos(angle),3.12*math.sin(angle)
        block(a,"CeramicOrbitalSensor%s"%i,"GRIP",
              x,23.04,z,.16,.17,.17,.035)


def forged_orb_clamp(a):
    # Split saddle around original 9.5x0.8x2.4 clamp. The sphere stays
    # exposed; neither this clamp nor the supports fill the torus center.
    for side in (-1,1):
        x=side*3.74
        rod(a,"PressForgedClampJaw%s"%side,"ARMOR",
            (x,22.58,-1.14),(x,23.41,1.04),.30,10)
        rod(a,"ClampAxisLockPin%s"%side,"BRUSHED",
            (x,22.40,-1.39),(x,23.59,-1.39),.18,10)
    for face in (-1,1):
        z=face*1.11-.2
        rod(a,"ForgedTransverseClampChord%s"%face,"ALLOY",
            (-4.58,23,z),(4.58,23,z),.18,10)
        for i in range(11):
            x=-4.1+i*.82
            block(a,"AnodizedLockTeeth%s_%02d"%(face,i),"GRIP",
                  x,23.15,z,.33,.32,.22,.047)
    for i in range(8):
        x=-3.6+i*1.04
        block(a,"ClampCeramicRelayContact%02d"%i,"SIGNAL",
              x,23.36,-.22,.29,.19,.68,.038)


def export(path):
    a=Sculpture()
    a.lines[0]="# Original Chaos Survival South Orbital six-part finishing sculpture"
    a.lines[2]="o ChaosOriginalSouthOrbitalForgedFinishing"
    armored_plinth(a)
    profiled_supports(a)
    reactor_sphere(a)
    forged_orb_clamp(a)
    dims=[round(a.maximum[i]-a.minimum[i],5) for i in range(3)]
    center=[round((a.maximum[i]+a.minimum[i])*.5,5) for i in range(3)]
    assert set(a.materials)==set(MATERIALS),a.materials
    assert 150<=a.groups<=850,(a.groups,a.triangles)
    assert 3500<=a.triangles<=16000,a.triangles
    assert 18.35<=dims[0]<=19.1,dims
    assert 11.0<=dims[1]<=11.7,dims
    assert 4.95<=dims[2]<=5.35,dims
    assert all(abs(v)<.35 for v in center),center
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
