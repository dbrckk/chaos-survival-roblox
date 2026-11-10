#!/usr/bin/env python3
"""Original 14-target South Harbor lightship drydock monument.

A physically noninteractive original seven-material sculpted landmark for
the southern Harbor silhouette; not copied or recycled from NORTH Harbor.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NAME="south_harbor_sculpted_drydock"
SCALE=2.8
CENTER_Y=23.80


def p(x,y,z):
    return x/SCALE,(y-CENTER_Y)/SCALE,z/SCALE


def block(a,name,material,x,y,z,sx,sy,sz,edge=.07):
    a.beveled_block(name,material,*p(x,y,z),
                    sx/SCALE,sy/SCALE,sz/SCALE,edge/SCALE)


def rod(a,name,material,pa,pb,radius=.12,sides=10):
    a.rod(name,material,p(*pa),p(*pb),radius/SCALE,sides)


def foundation(a):
    block(a,"ArmoredSouthernDrydockPlatform","ARMOR",
          0,-1.14,0,46.3,1.58,12.35,.25)
    block(a,"RibbedCarbonServiceDeck","CARBON",
          0,.10,0,38.5,.18,9.72,.12)
    for face in (-1,1):
        z=face*6.27
        rod(a,"ContinuousForgedDrydockRim%s"%face,"ALLOY",
            (-22.9,-.51,z),(22.9,-.51,z),.15,10)
        for i in range(14):
            x=-21.24+i*3.26
            block(a,"DrydockHullSegment%s_%02d"%(face,i),"GRIP",
                  x,-1.13,z,2.71,.56,.19,.057)
            rod(a,"DrydockClampingRivet%s_%02d"%(face,i),"BRUSHED",
                (x,-1.51,z+face*.11),(x,-.78,z+face*.11),.061,8)
    for i in range(16):
        x=-18.0+i*2.40
        block(a,"AntiSlipCeramicLoadingDeck%02d"%i,"CERAMIC",
              x,.243,0,2.09,.076,9.02,.036)
        for face in (-1,1):
            z=face*4.61
            block(a,"AerialMooringGuidelight%s_%02d"%(face,i),
                  "SIGNAL",x,.302,z,1.38,.05,.14,.021)


def quay_columns(a):
    for side in (-1,1):
        x=side*16
        # Pierced 12-sided tubular piers, machine collars and vents.
        for height in (.12,4.0,13.2,23.8,32.5,34.94):
            if height<34.9:
                block(a,"HarborPierVerticalCollar%s_%s"%(side,height),
                      "BRUSHED",x,height,0,4.40,.28,4.40,.13)
        n=12
        levels=[(.04,2.02,2.02),(3,2.06,2.08),
                (15,1.85,1.87),(29,1.95,1.97),
                (34.95,2.03,2.03)]
        verts=[]
        for y,rx,rz in levels:
            for k in range(n):
                t=k*math.tau/n
                verts.append(p(x+rx*math.cos(t),y,rz*math.sin(t)))
        tris=[]
        for level in range(len(levels)-1):
            for k in range(n):
                u=level*n+k
                v=level*n+(k+1)%n
                w=(level+1)*n+(k+1)%n
                z=(level+1)*n+k
                tris.extend(((u,v,w),(u,w,z)))
        for k in range(1,n-1):
            tris.append((0,k+1,k))
            first=(len(levels)-1)*n
            tris.append((first,first+k,first+k+1))
        a.add("CastTwelveFacetQuayColumn%s"%side,"ARMOR",verts,tris)
        for i in range(9):
            y=4+i*3.17
            for face in (-1,1):
                z=face*2.08
                block(a,"QuayPierCarbonInset%s_%s_%02d"%(side,face,i),
                      "CARBON",x,y,z,2.27,2.13,.095,.036)
                for j in range(3):
                    block(a,"DockVentilationLouvre%s_%s_%02d_%02d"%
                          (side,face,i,j),"GRIP",
                          x+(j-1)*.62,y,z+face*.069,.19,1.69,.055,.022)
        for i in range(10):
            y=3.4+i*2.77
            block(a,"HarborLoadLevelSignal%s_%02d"%(side,i),"SIGNAL",
                  x+side*1.85,y,-2.13,.24,.31,.11,.03)


def cargo_container(a,side):
    x=side*16
    # Multi-shell 11x7x8 cargo structure with genuine corrugation.
    block(a,"CastDrydockCargoContainment%s"%side,"ARMOR",
          x,5.48,0,10.65,6.63,7.66,.22)
    for face in (-1,1):
        z=face*3.87
        block(a,"SuspendedCargoInsulatingSide%s_%s"%(side,face),
              "CARBON",x,5.48,z,10.28,5.98,.15,.066)
        for i in range(15):
            xx=x-4.82+i*.69
            block(a,"DeepCorrugatedContainerRib%s_%s_%02d"%
                  (side,face,i),"BRUSHED",
                  xx,5.47,z+face*.105,.25,5.92,.18,.055)
        for i in range(5):
            xx=x-3.99+i*1.99
            block(a,"CargoISOInspectionPlacard%s_%s_%02d"%
                  (side,face,i),"CERAMIC",
                  xx,7.42,z+face*.215,.88,.32,.08,.037)
    for z in (-3.78,3.78):
        for y in (2.25,8.74):
            rod(a,"CargoExteriorSafetyRail%s_%s_%s"%(side,z,y),
                "ALLOY",(x-5.05,y,z),(x+5.05,y,z),.13,10)
    for i in range(6):
        xx=x-4.25+i*1.7
        block(a,"LowerCargoBeacon%s_%02d"%(side,i),"SIGNAL",
              xx,1.95,-3.78,.31,.19,.21,.038)


def container_hoist(a,side):
    x=side*12.5
    # Two tensioned lines, collar sleeves and visible tackle wheel.
    for dx in (-.23,.23):
        rod(a,"MultiStrandCargoHoist%s_%s"%(side,dx),"ALLOY",
            (x+dx,17.51,0),(x+dx,36.47,0),.105,10)
    for i in range(12):
        y=18.0+i*1.60
        block(a,"MachinedCargoHoistCoupler%s_%02d"%(side,i),
              "GRIP",x,y,0,.76,.23,.87,.057)
        block(a,"TensionLoadGauge%s_%02d"%(side,i),"SIGNAL",
              x,y+.04,-.48,.32,.16,.07,.027)
    rod(a,"DieCastHoistDriveWheel%s"%side,"ARMOR",
        (x-.54,36.30,0),(x+.54,36.30,0),.49,16)
    for i in range(8):
        t=i*math.tau/8
        xx=.45*math.cos(t)
        yy=.45*math.sin(t)
        rod(a,"HoistDriveWheelSpoke%s_%02d"%(side,i),"BRUSHED",
            (x-.47,36.3+yy,xx),(x+.47,36.3+yy,xx),.055,8)


def rig(a,side):
    # Sculpted open metallic triangular roof rig, not a solid WedgePart.
    x=side*17
    for face in (-1,1):
        z=face*2.15
        rod(a,"ForgedQuayRigMainChord%s_%s"%(side,face),"ARMOR",
            (x-3.93,36.20,z),(x+3.93,39.72,z),.23,10)
        rod(a,"QuayRigLowerChord%s_%s"%(side,face),"BRUSHED",
            (x-3.9,36.2,z),(x+3.9,36.2,z),.17,10)
        for i in range(8):
            xx=x-3.4+i*.95
            yy=36.4+i*.42
            rod(a,"QuayRigDiagonalWeld%s_%s_%02d"%(side,face,i),
                "ALLOY",(xx,36.3,z),(xx+.78,yy+.32,z),.098,8)
    for i in range(7):
        xx=x-3.36+i*1.11
        rod(a,"QuayRigTransverseCarrier%s_%02d"%(side,i),"GRIP",
            (xx,38.18,-2.15),(xx,38.18,2.15),.105,8)
        block(a,"QuayRigCeramicSkid%s_%02d"%(side,i),"CERAMIC",
              xx,39.52,0,.28,.19,3.84,.062)


def lightship_bridge(a):
    # Four longitudinal forged chords and cross bracing make an open truss.
    for face in (-1,1):
        z=face*2.43
        for yy in (33.59,35.40):
            rod(a,"ForgedHarborLightshipMainChord%s_%s"%(face,yy),
                "ARMOR",(-20.23,yy,z),(20.23,yy,z),.30,12)
        for i in range(18):
            x=-19.1+i*2.15
            rod(a,"PiercedHarborBridgeTruss%s_%02d"%(face,i),"ALLOY",
                (x-1.15,33.64,z),(x+.92,35.35,z),.108,8)
    block(a,"AntiSlipHarborOverpassDeck","CARBON",
          0,34.55,0,40.1,.25,5.12,.11)
    for i in range(20):
        x=-19.0+i*2
        rod(a,"LightshipCrossTraverse%02d"%i,"BRUSHED",
            (x,34.29,-2.38),(x,34.29,2.38),.10,8)
        block(a,"InlaidBridgeServiceTile%02d"%i,"GRIP",
              x,34.72,0,.48,.065,4.75,.030)
    for i in range(10):
        x=-17.8+i*3.93
        block(a,"HarborBeaconStrip%02d"%i,"SIGNAL",
              x,35.59,-2.4,.37,.16,.20,.047)


def storm_cabin(a):
    block(a,"BeveledLightshipCommandCabin","BRUSHED",
          0,39,0,8.64,4.14,5.72,.27)
    block(a,"DarkenedStormLensOpticalHousing","CARBON",
          0,39.3,-3.06,6.56,1.79,.27,.11)
    for i in range(9):
        x=-2.96+i*.74
        block(a,"StormWindowForgedMullion%02d"%i,"CERAMIC",
              x,39.28,-3.27,.115,1.78,.11,.042)
    for y in (38.50,40.05):
        rod(a,"StormSafetyGlassBracket%s"%y,"ALLOY",
            (-3.21,y,-3.29),(3.21,y,-3.29),.10,8)
    for x in (-4.0,4.0):
        for z in (-2.5,2.5):
            rod(a,"LightshipCabCornerSupport%s_%s"%(x,z),"ARMOR",
                (x,37.1,z),(x,41.1,z),.19,10)
    # Original seven-stud beacon, with an open machined aerial tip.
    rod(a,"StormAntennaForgedShaft","ARMOR",
        (0,42.51,0),(0,49.49,0),.34,12)
    for i in range(8):
        y=43.2+i*.80
        rod(a,"DieCastStormAerialCollar%02d"%i,"BRUSHED",
            (-.49,y,0),(.49,y,0),.12,10)
        for dx in (-.45,.45):
            block(a,"SignalBeaconDiode%s_%02d"%(dx,i),"SIGNAL",
                  dx,y,0,.10,.18,.42,.026)
    for face in (-1,1):
        rod(a,"PiercedStormTelemetryCrossarm%s"%face,"ALLOY",
            (face*.09,46.98,-1.18),(face*.09,46.98,1.18),.07,8)
    for i in range(5):
        y=44.18+i*.98
        block(a,"AntennaCeramicFrequencyBaffle%02d"%i,"CERAMIC",
              0,y,-.43,.48,.12,.15,.026)


def export(path):
    a=Sculpture()
    a.lines[0]="# Original creator-owned Chaos Survival Harbor South drydock lightship"
    a.lines[2]="o ChaosOriginalSouthHarborSculptedDrydock"
    foundation(a)
    quay_columns(a)
    for side in (-1,1):
        cargo_container(a,side)
        container_hoist(a,side)
        rig(a,side)
    lightship_bridge(a)
    storm_cabin(a)
    dims=[round(a.maximum[i]-a.minimum[i],5) for i in range(3)]
    center=[round((a.maximum[i]+a.minimum[i])*.5,5) for i in range(3)]
    assert set(a.materials)==set(MATERIALS),a.materials
    assert 200<=a.groups<=1450,(a.groups,a.triangles)
    assert 4500<=a.triangles<=27000,a.triangles
    assert 16.45<=dims[0]<=17.25,dims
    assert 17.6<=dims[1]<=18.8,dims
    assert 4.45<=dims[2]<=4.95,dims
    assert all(abs(v)<.75 for v in center),center
    raw="\n".join(a.lines)+"\n"
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(raw,encoding="utf-8")
    return {"asset":NAME,"triangles":a.triangles,"groups":a.groups,
            "vertices":a.vertices,"materials":sorted(a.materials),
            "bounds":dims,"center":center,
            "sha256":hashlib.sha256(raw.encode()).hexdigest()}

if __name__=="__main__":
    arg=argparse.ArgumentParser()
    arg.add_argument("--output",type=Path,required=True)
    print(json.dumps(export(arg.parse_args().output),sort_keys=True))
