#!/usr/bin/env python3
"""Two wholly authored, fully triangulated Storm Harbor container-port cranes.

These are REAL original seven-material MeshPart source models, not exports
of Roblox Parts or a recycled floating skyfleet model. One carries an ISO
container and the other a sealed industrial cable spool. Both are entirely
NONPHYSICAL scenery outboard of the 320-stud playable arena.

Source coordinate Y = native crane world-local height - 18.0 studs.
The native gantry's real MainCrossgirder center is at (0, 30, 0).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

PROFILES = (
    "harbor_gantry_container", "harbor_gantry_drum",
    "harbor_gantry_kinetic_container", "harbor_gantry_kinetic_drum",
)
# The kinetic version uses ONE distinctive material per moving assembly
# and FOUR for the static bridge, so Roblox imports exactly seven genuine
# MeshParts. Each moving component has its own closed triangles/UV/tangents.
KINETIC_MATERIAL_ROLES = {
    "ALLOY": "Cable", "CARBON": "Trolley", "GRIP": "Load",
    "ARMOR": "Static", "BRUSHED": "Static",
    "CERAMIC": "Static", "SIGNAL": "Static",
}
MOVING_TROLLEY = (
    "TravelingTrolleyForge", "TrolleyPowerCabinet",
    "PanoramicHoistWindow", "CablePulleyHousing",
)
MOVING_CABLE = ("StainlessHoistCable",)
MOVING_LOAD = (
    "LoadSpreaderCasting", "SafeSpreaderSling",
    "TwentyFootSuspendedISOBody", "RecessedFreightDoor",
    "ContainerUpperChine", "ISOVerticalPressing",
    "ContainerCornerCasting", "CargoOwnerMark",
    "SpoolCoreCylinder", "SixteenSidedSpoolEndplate",
    "ReelEndLock", "TrueRopeWinding", "ReelSafetyOwnerBadge",
)
CENTERING_Y = 18.0


def create(profile: str) -> Sculpture:
    if profile not in PROFILES:
        raise ValueError("Unknown original Harbor gantry profile")
    art = Sculpture()
    art.lines[0] = "# Original Chaos Survival Harbor 3D shore container crane"
    art.lines[2] = "o OriginalHarborGantry_" + profile
    if "_kinetic_" in profile:
        # The importer groups primitives by MATERIAL. Deliberately give
        # trolley/cables/load three exclusive original material groups:
        # these may then follow the already-running native crane animation
        # without moving the real structural columns or starting a new loop.
        original_add = art.add

        def add_by_role(name, material, vertices, faces):
            if name.startswith(MOVING_TROLLEY):
                chosen = "CARBON"
            elif name.startswith(MOVING_CABLE):
                chosen = "ALLOY"
            elif name.startswith(MOVING_LOAD):
                chosen = "GRIP"
            else:
                # Four authentic static materials, never reused by movers.
                chosen = {
                    "ALLOY": "BRUSHED", "CARBON": "ARMOR",
                    "GRIP": "CERAMIC",
                }.get(material, material)
            return original_add(name, chosen, vertices, faces)

        art.add = add_by_role

    def block(name,material,x,y,z,sx,sy,sz,bevel=.18):
        art.beveled_block(name,material,x,y-CENTERING_Y,z,
                          sx,sy,sz,bevel)

    def rod(name,material,a,b,radius,sides=8):
        a=(a[0],a[1]-CENTERING_Y,a[2])
        b=(b[0],b[1]-CENTERING_Y,b[2])
        art.rod(name,material,a,b,radius,sides)

    def pier(side: int):
        # True 10-sided continuously tapered, closed gravity structure:
        # 6 vertically offset rings plus machined horizontal load-flanges.
        xs=side*8.0
        stations=((0.05,1.31,1.22),(2.0,1.46,1.31),
                  (5.8,.97,.98),(16.0,.76,.73),
                  (27.8,.90,.93),(30.55,1.48,1.20))
        points=[]
        for h,rx,rz in stations:
            for i in range(10):
                theta=2*math.pi*i/10
                points.append((xs+rx*math.cos(theta),h-CENTERING_Y,
                               rz*math.sin(theta)))
        faces=[]
        for level in range(len(stations)-1):
            for i in range(10):
                v=level*10+i; nxt=level*10+(i+1)%10
                upper=(level+1)*10+i; un=(level+1)*10+(i+1)%10
                faces.extend(((v,nxt,un),(v,un,upper)))
        for i in range(1,9):
            faces.append((0,i+1,i))
            top=(len(stations)-1)*10
            faces.append((top,top+i,top+i+1))
        art.add("TaperedTenSidedQuayPier"+str(side),"ARMOR",points,faces)
        block("WideDiecastFoundation"+str(side),"GRIP",
              xs,.32,0,3.15,.74,3.28,.24)
        block("HeadBearingSaddle"+str(side),"BRUSHED",
              xs,30.58,0,3.4,1.20,3.1,.33)
        block("PierVentilationInset"+str(side),"CARBON",
              xs,20.6,-.95,1.10,7.75,.15,.09)
        block("IdentificationCeramic"+str(side),"CERAMIC",
              xs,24.65,-1.07,.78,1.12,.12,.09)
        # Two forged diagonals make the piers recognizable at a distance.
        rod("UnderloadedForwardBrace"+str(side),"ALLOY",
            (xs+side*1.7,1.0,-.7),(xs-side*.75,28.75,-1),.225,10)
        rod("OuterCounterbrace"+str(side),"ALLOY",
            (xs-side*2.1,1.1,1.1),(xs+side*.65,28.7,1.2),.155,8)
        for level in range(6):
            h=4.4+level*4.18
            block("StampedJointCollar_%s_%s"%(side,level),"BRUSHED",
                  xs,h,0,2.00,.23,2.05,.095)
        for k in range(3):
            h=7.3+k*7.4
            rod("StiffenerLattice_%s_%s"%(side,k),"ALLOY",
                (xs-1.0,h,-1.6),(xs+1.0,h+3.2,-1.6),.09,8)
        block("LoadWarningStrip"+str(side),"SIGNAL",
              xs,29.12,-1.61,1.24,.12,.12,.045)

    for side in (-1,1):
        pier(side)

    # Overhead main portal crosshead, with real hollow welded truss cells.
    block("ForgedOverheadMainGirder","ARMOR",
          0,30.65,0,20.6,1.58,2.60,.53)
    block("UpperInterlockDeck","GRIP",
          0,31.67,0,20.1,.26,2.65,.15)
    block("SealedSwitchCabinet","CARBON",
          -5.1,31.96,-1.32,4.4,1.32,1.13,.15)
    for side in (-1,1):
        for k in range(4):
            x=side*(1.9+k*1.8)
            rod("OverheadTriangularBrace_%s_%s"%(side,k),"ALLOY",
                (x,29.91,-1.28),(x+side*1.4,32.45,-1.3),.135,8)
        block("CrossheadDiecastEndCap"+str(side),"BRUSHED",
              side*10.55,30.52,0,.76,2.0,3.6,.18)

    # Long z-axis boom, forward loading span and rear counterweighted
    # service span. No invisible routes over actual land.
    block("ContinuousContainerBoom","ARMOR",
          0,33.18,0,3.7,1.22,44.0,.38)
    block("ForgedBoomTopTrack","GRIP",
          0,34.03,0,3.55,.27,43.2,.16)
    for side in (-1,1):
        block("ParallelCraneWheelRail"+str(side),"BRUSHED",
              side*1.28,33.92,-.4,.35,.32,41.0,.10)
        rod("BoomInclinedUpperCable"+str(side),"ALLOY",
            (side*1.38,34.1,-21.0),(side*1.4,35.9,0),.14,8)
        rod("BoomRearLoadCable"+str(side),"ALLOY",
            (side*1.42,35.9,0),(side*1.38,34.1,21.0),.14,8)
        for bay in range(8):
            z=-18.2+bay*5.2
            rod("BoomDiagonalTriangulation_%d_%d"%(side,bay),"ALLOY",
                (side*1.48,32.56,z),
                (side*1.49,35.3,z+2.6),.10,8)
    for idx in range(11):
        z=-20+4*idx
        block("OverheadCrossRib"+str(idx),"BRUSHED",
              0,34.35,z,3.8,.20,.30,.065)
    # The rear maintenance mass offsets the forward suspended cargo.
    block("MechanicalCounterweightHousing","CARBON",
          0,31.6,17.95,6.30,3.4,5.15,.49)
    for side in (-1,1):
        block("RecessedCounterweightArmor"+str(side),"ALLOY",
              side*3.23,31.6,17.95,.23,2.90,4.0,.085)
    block("CounterweightRearLouver","GRIP",
          0,31.5,20.66,4.8,1.9,.12,.055)

    # Overhead traveling hoist and fully suspended original load.
    block("TravelingTrolleyForge","BRUSHED",
          0,31.35,-13.5,4.20,2.40,4.0,.41)
    block("TrolleyPowerCabinet","CARBON",
          0,29.93,-13.55,3.2,.60,3.10,.15)
    block("PanoramicHoistWindow","CERAMIC",
          0,31.55,-15.56,2.9,.65,.12,.06)
    for side in (-1,1):
        rod("StainlessHoistCable"+str(side),"ALLOY",
            (side*3.6,28.15,-15),
            (side*3.6,15.7,-15),.105,10)
        block("CablePulleyHousing"+str(side),"GRIP",
              side*3.6,28.35,-15,.75,.75,.78,.13)
    block("LoadSpreaderCasting","ARMOR",
          0,15.55,-15,9.15,.82,1.42,.23)
    for side in (-1,1):
        rod("SafeSpreaderSling"+str(side),"ALLOY",
            (side*3.5,15.22,-15),
            (side*3.6,12.82,-15),.13,8)

    if profile.endswith("_container"):
        # Honest shipping ISO container, not an untextured slab.
        block("TwentyFootSuspendedISOBody","CERAMIC",
              0,10.07,-15,8.65,4.92,5.12,.39)
        block("RecessedFreightDoor","CARBON",
              4.34,10.07,-15,.15,4.24,4.49,.075)
        block("ContainerUpperChine","BRUSHED",
              0,12.62,-15,9.02,.31,5.5,.14)
        for side in (-1,1):
            for rib in range(5):
                x=-3.4+rib*1.7
                block("ISOVerticalPressing_%s_%d"%(side,rib),"ALLOY",
                      x,10.04,-15+side*2.64,.15,4.20,.12,.04)
            for x in (-3.83,3.83):
                block("ContainerCornerCasting_%s_%s"%(side,x),"GRIP",
                      x,7.67,-15+side*2.37,.42,.38,.49,.075)
        block("CargoOwnerMark","SIGNAL",
              -1.1,10.18,-17.65,3.28,.48,.095,.03)
    else:
        # An ACTUAL cylindrical reel on a horizontal X-axis. Sculptural
        # 16-facet steel drums, visible cable wraps and bolted endplates.
        rod("SpoolCoreCylinder","CARBON",
            (-3.32,10.25,-15),(3.32,10.25,-15),1.84,16)
        for side in (-1,1):
            rod("SixteenSidedSpoolEndplate"+str(side),"BRUSHED",
                (side*3.34,10.25,-15),
                (side*3.63,10.25,-15),2.32,16)
            for k in range(8):
                angle=k*math.pi/4
                y=10.25+2.05*math.cos(angle)
                z=-15+2.05*math.sin(angle)
                block("ReelEndLock_%d_%d"%(side,k),"ALLOY",
                      side*3.72,y,z,.22,.18,.18,.046)
        for turn in range(7):
            x=-2.79+turn*.91
            for seg in range(12):
                a=seg*math.tau/12
                b=(seg+1)*math.tau/12
                rod("TrueRopeWinding_%d_%d"%(turn,seg),"GRIP",
                    (x,10.25+1.93*math.cos(a),-15+1.93*math.sin(a)),
                    (x,10.25+1.93*math.cos(b),-15+1.93*math.sin(b)),
                    .085,6)
        block("ReelSafetyOwnerBadge","SIGNAL",
              3.85,10.25,-15,.10,.35,.93,.04)

    assert art.materials==set(MATERIALS), art.materials
    assert 90<=art.groups<=270,art.groups
    assert 2500<=art.triangles<=9500,art.triangles
    return art


def export(profile: str,output: Path):
    art=create(profile)
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    center=[round((art.minimum[i]+art.maximum[i])/2,5)
            for i in range(3)]
    assert 20.5<=dims[0]<=24.8,dims
    assert 35.7<=dims[1]<=37.2,dims
    assert 43.0<=dims[2]<=45.4,dims
    assert abs(center[0])<.5 and abs(center[2])<.9, center
    assert -19.2<=art.minimum[1]<=-17.5
    output.parent.mkdir(parents=True,exist_ok=True)
    text="\n".join(art.lines)+"\n"
    output.write_text(text,encoding="utf-8")
    return {"name":profile,"triangles":art.triangles,"groups":art.groups,
            "vertices":art.vertices,"materials":sorted(art.materials),
            "dimensions":dims,"bounds_center":center,
            "bounds_min":art.minimum,"bounds_max":art.maximum,
            "source_y_shift":CENTERING_Y,
            "kinetic_material_roles": (
                KINETIC_MATERIAL_ROLES if "_kinetic_" in profile else {}),
            "sha256":hashlib.sha256(text.encode()).hexdigest()}


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--model",choices=PROFILES,required=True)
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    print(json.dumps(export(args.model,args.output),sort_keys=True))


if __name__=="__main__":
    main()
