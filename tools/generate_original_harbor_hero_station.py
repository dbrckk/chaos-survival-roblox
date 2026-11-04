#!/usr/bin/env python3
"""Original true 3D near-camera Storm Harbor maritime control & hoist station.

The existing HarborHero... native scene remains the *sole* animation driver.
Three mutually exclusive UV/tangent material groups isolate the moving
radar sweep, hoist cable, and suspended service load from four STATIC
manufactured/cast-aluminum hull, superstructure, glazing and signal groups.
One 7-MeshPart approved Roblox Model, nonphysical. No extra fake platform.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

NAME="harbor_hero_station"
SCALE=.74
SHIFT_Y=20.0
STATIC_MATERIALS={"ARMOR","BRUSHED","CERAMIC","SIGNAL"}
MOVING={"Radar":"CARBON","Cable":"ALLOY","Weight":"GRIP"}


def create()->Sculpture:
    art=Sculpture()
    art.lines[0]="# ORIGINAL Chaos Survival Storm Harbor 3D signal tower"
    art.lines[2]="o ChaosOriginalHarborMaritimeControlStation"

    def at(x,y,z):
        return (x*SCALE,(y-SHIFT_Y)*SCALE,z*SCALE)

    def block(name,mat,x,y,z,sx,sy,sz,edge=.16):
        assert mat in MATERIALS
        px,py,pz=at(x,y,z)
        art.beveled_block(name,mat,px,py,pz,
                          sx*SCALE,sy*SCALE,sz*SCALE,edge*SCALE)

    def rod(name,mat,start,end,radius=.16,sides=10):
        art.rod(name,mat,at(*start),at(*end),radius*SCALE,sides)

    def taperedPier(side):
        x=side*7.80
        stations=[
            (2.30,1.18,1.28),(3.7,1.30,1.25),
            (7.4,1.10,1.00),(13.0,.86,.95),
            (18.6,.92,1.0),(21.70,1.36,1.36),
        ]
        verts=[]
        for y,rx,rz in stations:
            for k in range(10):
                angle=k*math.tau/10
                verts.append(at(x+rx*math.cos(angle),
                                y,rz*math.sin(angle)))
        faces=[]
        for level in range(len(stations)-1):
            for k in range(10):
                a=level*10+k;b=level*10+(k+1)%10
                c=(level+1)*10+(k+1)%10;d=(level+1)*10+k
                faces.extend(((a,b,c),(a,c,d)))
        for k in range(1,9):
            faces.append((0,k+1,k))
            top=(len(stations)-1)*10
            faces.append((top,top+k,top+k+1))
        art.add("MaritimeTenFacetedLoadPier"+str(side),"ARMOR",
                verts,faces)

    # Massive false-walkway-free plinth: the original collision-free
    # foundation remains structurally and visually sealed in this model.
    block("ShapedBreakwaterControlFoundation","ARMOR",
          0,1.40,0,23.4,2.10,8.85,.48)
    block("ElevatedPlinthPerimeterArmoring","BRUSHED",
          0,2.24,0,24.7,.46,9.7,.31)
    block("UnderFoundationDarkMechanicalRecess","CERAMIC",
          0,.35,0,20.2,.24,6.3,.18)
    for side in (-1,1):
        taperedPier(side)
        block("SolidBaseDiecastFoot"+str(side),"BRUSHED",
              side*7.8,3.0,0,3.3,.88,3.6,.23)
        block("CrenellatedBearingAtGantryTop"+str(side),"BRUSHED",
              side*7.8,21.58,0,3.4,1.13,4.0,.24)
        block("GalvanicFenderPlate"+str(side),"CERAMIC",
              side*10.7,1.8,0,.42,2.5,7.2,.15)
        rod("SwagedDiagonalStrut"+str(side),"BRUSHED",
            (side*9.15,4.1,-1.3),
            (side*7.1,19.4,-1.0),.23,10)
        rod("CounterbalancedOutsideXBrace"+str(side),"BRUSHED",
            (side*6.1,5.0,1.2),
            (side*8.58,18.9,1.2),.18,10)
        for row in range(4):
            h=6.2+row*3.65
            block("StainlessMaritimeColumnCollar_%d_%d"%(side,row),"BRUSHED",
                  side*7.8,h,0,2.5,.23,2.8,.08)
            block("RecessedPierVentilator_%d_%d"%(side,row),"CERAMIC",
                  side*8.90,h,-.46,.12,1.17,1.34,.05)

    # Real architectural upper transfer bridge and glazed signal booth.
    block("ClosedLoadDistributionCrosshead","ARMOR",
          0,21.50,0,19.9,2.02,3.25,.38)
    block("ISectionRaisedGirderTop","BRUSHED",
          0,22.60,0,20.2,.32,3.45,.12)
    for k in range(7):
        x=-8.6+k*2.87
        rod("TrussedOverheadBridgeTriangulation"+str(k),"BRUSHED",
            (x,20.55,-1.55),(x+1.8,22.45,-1.55),.11,8)
    block("DiecastOperationsBooth","ARMOR",
          0,25.18,0,9.65,5.75,6.6,.49)
    block("AngledWeatherproofRoof","CERAMIC",
          0,28.33,0,11.14,.78,8.34,.40)
    block("DoubleGlazedBeaconOutlookFront","CERAMIC",
          0,25.91,-3.39,8.3,2.18,.23,.08)
    block("RecessedBeaconOutlookFrame","BRUSHED",
          0,26.04,-3.56,8.0,.16,.25,.085)
    for side in (-1,1):
        block("BridgeMullion"+str(side),"BRUSHED",
              side*2.5,26.02,-3.62,.23,2.06,.12,.08)
        block("MarineOverhangSupport"+str(side),"BRUSHED",
              side*4.6,29.04,-2.25,.52,2.1,.63,.18)
        block("HighDeckPerimeterHandrail"+str(side),"BRUSHED",
              side*5.2,30.08,0,.20,4.5,.20,.075)
        block("HarborSectionSignalStrap"+str(side),"SIGNAL",
              side*4.6,25.8,-3.77,.22,2.5,.085,.04)

    # The radar TOWER is fixed; only the short radial horizontal arm
    # exists inside the separate CARBON group. The live native radar
    # CFrame rotates the CARBON MeshPart; fixed mast never rotates.
    block("SculptedRadarBasePedestal","ARMOR",
          0,31.75,0,2.1,5.8,1.82,.33)
    block("UpperRadarPedestalBay","CERAMIC",
          0,34.9,0,1.45,2.85,1.35,.25)
    rod("RadiometricMastSpindle","BRUSHED",
        (0,35.5,0),(0,37.6,0),.38,12)
    block("RadarArm_ClosedOctagonalRoot","CARBON",
          0,37.7,0,11.55,.48,.62,.24)
    for side in (-1,1):
        block("RadarArm_ForgedEndCap"+str(side),"CARBON",
              side*5.8,37.7,0,.78,.85,.72,.15)
        rod("RadarArm_UnderslungStabilizer"+str(side),"CARBON",
            (side*3.3,37.50,-.14),
            (side*5.45,37.45,.16),.115,8)

    # The original HarborHeroStormLens (y39.8) remains a native glass
    # sphere with existing animated pulse & disaster tint; NO fake lamp.

    # Industrial hoist station to starboard: genuinely jointed columns,
    # asymmetrical transit arm and non-primitive open girder stays.
    block("SecondMechanicalPierRoot","ARMOR",
          15.20,11.8,0,2.4,20.8,2.4,.40)
    block("HoistForgeTopHead","BRUSHED",
          15.2,22.25,0,4.0,2.04,3.12,.30)
    block("HarborOffshoreRailCraneArm","ARMOR",
          15.20,22.25,0,19.3,1.35,1.75,.27)
    block("OneSidedHoistTrackCap","BRUSHED",
          15.20,23.11,0,19.0,.31,1.65,.10)
    for side in (-1,1):
        for bay in range(6):
            x=6.1+bay*3.55
            rod("OverheadOpenMechanism_"+str(side)+"_"+str(bay),
                "BRUSHED",
                (x,21.35,side*.86),
                (x+2.08,23.36,side*.91),.13,8)
        rod("CantileverAFrame_"+str(side),"BRUSHED",
            (15.20,19.45,side*.96),
            (21.35,22.73,side*1.04),.14,10)
    for i in range(5):
        y=5.1+i*3.35
        block("MachinedHoistPierCollar"+str(i),"BRUSHED",
              15.2,y,0,2.68,.22,2.63,.10)
    block("SuspensionRelayConsole","CERAMIC",
          14.4,15.8,-1.30,1.24,2.7,1.12,.24)
    block("CargoWarningCode","SIGNAL",
          14.40,14.95,-1.97,.96,.13,.09,.03)
    block("PortOperationsNameplate","SIGNAL",
          0,24.05,-3.68,3.2,.27,.11,.05)

    # The approved motion owner owns CFrame on three existing Parts:
    # RadarArm at (0,37.7,0); HoistCable at (22.5,16.0,0);
    # HoistWeight at (22.5,9.7,0). Three individual mesh groups follow
    # these exact existing references, with no new animation loop.
    block("Cable_TrueSwagedHoistCore","ALLOY",
          22.5,16.0,0,.32,11.0,.32,.085)
    rod("Cable_SealedSafetyLoop","ALLOY",
        (22.5,21.1,0),(22.5,21.55,0),.145,8)
    block("Weight_OriginalSuspendedMarineCase","GRIP",
          22.5,9.7,0,3.72,2.45,3.61,.40)
    block("Weight_RecessedServiceLedger","GRIP",
          22.5,9.60,-1.845,2.25,.38,.10,.025)
    for side in (-1,1):
        block("Weight_CornerCastSteel"+str(side),"GRIP",
              22.5,8.53,side*1.7,3.1,.17,.14,.050)

    assert set(art.materials)==set(MATERIALS),art.materials
    assert 55<=art.groups<=190,art.groups
    assert 1400<=art.triangles<=5800,art.triangles
    return art


def export(path:Path)->dict:
    art=create()
    sizes=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    centers=[round((art.maximum[i]+art.minimum[i])*.5,5) for i in range(3)]
    assert 27.0<=sizes[0]<=29.4,sizes
    assert 29.0<=sizes[1]<=31.0,sizes
    assert 7.0<=sizes[2]<=8.0,sizes
    assert abs(centers[2])<.5
    path.parent.mkdir(parents=True,exist_ok=True)
    blob="\n".join(art.lines)+"\n"
    path.write_text(blob,encoding="utf8")
    return dict(asset=NAME,groups=art.groups,triangles=art.triangles,
        vertices=art.vertices,materials=sorted(art.materials),size=sizes,
        bounds_min=art.minimum,bounds_max=art.maximum,bounds_center=centers,
        source_scale=SCALE,source_y_shift=SHIFT_Y,
        sha256=hashlib.sha256(blob.encode()).hexdigest())


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))
