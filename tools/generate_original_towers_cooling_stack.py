#!/usr/bin/env python3
"""Original authored 3D Towers skyline cooling stack for Chaos Survival.

The five Tower Run far-background cooling units were still plain 7-10-stud
wide Part columns 27-44 studs tall. This source designs a true hollow
hyperboloid ventilation tower, with 16-sided variable-radius wall, real
inner throat, eight levels of structural struts, radial extractors, intake
chambers, flange rings, service ladder, pressure pipework and status plates.
Seven exclusive UV/tangent material groups. No collision or player route.
Original reference height 44 studs; build source at scale .46 to remain
within Roblox procedural source exporter bounds, restore on client.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

ASSET = "towers_cooling_stack"
SCALE = 0.46
REFERENCE_HEIGHT = 44.0
RING_SIDES = 16


def create() -> Sculpture:
    model = Sculpture()
    model.lines[0] = "# Original Chaos Survival Towers 3D hyperboloid cooling installation"
    model.lines[2] = "o OriginalTowersIndustrialCoolingStack"

    def v(x: float, y: float, z: float) -> tuple[float, float, float]:
        return x * SCALE, y * SCALE, z * SCALE

    def block(name, material, x, y, z, sx, sy, sz, bevel=.16):
        x,y,z = v(x,y,z)
        model.beveled_block(name, material, x,y,z,
                            sx*SCALE,sy*SCALE,sz*SCALE,bevel*SCALE)

    def rod(name, material, a, b, radius=.12, sides=8):
        model.rod(name,material,v(*a),v(*b),radius*SCALE,sides)

    # Closed double-wall, truly non-rectangular variable-radius stack:
    # the 16-sided inner face remains visible down through the roof vent.
    stations = [
        (-22.0,5.15),(-19.5,5.30),(-16.0,4.65),
        (-10.0,4.25),(-4.0,3.95),(3.0,3.86),
        (10.0,4.08),(16.0,4.58),(21.5,5.12),
    ]
    verts = []
    for y, outer in stations:
        inner = outer-0.54
        for r in (outer,inner):
            for i in range(RING_SIDES):
                angle=2*math.pi*i/RING_SIDES
                verts.append(v(math.cos(angle)*r,y,math.sin(angle)*r))
    faces=[]
    step=RING_SIDES*2
    for k in range(len(stations)-1):
        for i in range(RING_SIDES):
            j=(i+1)%RING_SIDES
            oa=k*step+i
            ob=k*step+j
            oc=(k+1)*step+j
            od=(k+1)*step+i
            faces.extend(((oa,ob,oc),(oa,oc,od)))
            ia=k*step+RING_SIDES+i
            ib=k*step+RING_SIDES+j
            ic=(k+1)*step+RING_SIDES+j
            id_=(k+1)*step+RING_SIDES+i
            faces.extend(((ia,ic,ib),(ia,id_,ic)))
    for i in range(RING_SIDES):
        j=(i+1)%RING_SIDES
        bot_outer=i
        bot_inner=RING_SIDES+i
        top_outer=(len(stations)-1)*step+i
        top_inner=top_outer+RING_SIDES
        faces.extend(((bot_outer,bot_outer-i+j,bot_inner-i+j),
                      (bot_outer,bot_inner-i+j,bot_inner)))
        faces.extend(((top_outer,top_inner,top_inner-i+j),
                      (top_outer,top_inner-i+j,top_outer-i+j)))
    model.add("SixteenFacetedDoubleWalledCoolingChimney",
              "ARMOR", verts, faces)

    # Wide cast foundation, physically welded C-channel foot, grated
    # access gallery and a top pressure-retaining lip around the throat.
    block("ForgedSixteenSidedBasePedestal", "CARBON",
          0,-22.25,0,12.0,.85,12.0,.42)
    block("RecessedShaftInspectionApron", "BRUSHED",
          0,-21.82,0,11.5,.21,11.5,.22)
    for level,y in enumerate((-18.3,-11.0,-3.3,4.5,12.0,19.6)):
        radius=5.23 if level==0 else 4.68 if level in (1,4) else 4.24
        if level==5:radius=5.33
        for i in range(RING_SIDES):
            a=math.tau*i/RING_SIDES
            b=math.tau*(i+1)/RING_SIDES
            rod("TrueCircularStructuralBand_%d_%02d"%(level,i),
                "BRUSHED",
                (radius*math.cos(a),y,radius*math.sin(a)),
                (radius*math.cos(b),y,radius*math.sin(b)),
                .15,8)
    for i in range(RING_SIDES):
        angle=math.tau*i/RING_SIDES
        r=5.08
        x=math.cos(angle)*r;z=math.sin(angle)*r
        # Tapered visibly load-bearing stainless diagonals, not light FX.
        rod("OutsideVerticalLoadRib_%02d"%i,"ALLOY",
            (x,-20.3,z),
            (3.88*math.cos(angle),4.9,3.88*math.sin(angle)),.19,8)
        rod("HighCrownLatticeLeg_%02d"%i,"ALLOY",
            (3.96*math.cos(angle),3.2,3.96*math.sin(angle)),
            (5.04*math.cos(angle),20.9,5.04*math.sin(angle)),.17,8)
        for bay in range(4):
            low=-19+bay*9.2
            theta=angle+math.pi/RING_SIDES
            r1=4.50 if bay==1 else 4.8
            rod("TaperedZigzagWindBrace_%02d_%d"%(i,bay),
                "BRUSHED",
                (r1*math.cos(angle),low,r1*math.sin(angle)),
                (r1*math.cos(theta),low+8.1,
                 r1*math.sin(theta)),.105,8)

    # External mechanical extractors, vent motor bosses, safe sheltered
    # green/orange diagnostics and turbine inlet shutters around the wall.
    for i in range(8):
        angle=math.tau*i/8
        x=5.35*math.cos(angle);z=5.35*math.sin(angle)
        block("VentilationPressureDamper_%02d"%i,"CARBON",
              x,-17.1,z,1.42,3.35,1.30,.18)
        block("MachinedTurbineIntakeGrille_%02d"%i,"GRIP",
              x*1.035,-17.05,z*1.035,1.10,2.5,.33,.09)
        for rib in range(3):
            block("TrueIntakeLouver_%02d_%d"%(i,rib),"BRUSHED",
                  x*1.056,-16.31-rib*.7,z*1.056,
                  1.1,.095,.33,.04)
        block("MarineCorrosionReliefSkirt_%02d"%i,"CERAMIC",
              5.22*math.cos(angle),-20.45,
              5.22*math.sin(angle),1.37,.35,.44,.11)

    # Raised 3D roof crown with actual open center, diagonal safety stays
    # and overhanging collision-free rim. A thin cap MUST NOT fill the
    # hollow mouth, because that would revert to a plain cylinder.
    for i in range(RING_SIDES):
        a=math.tau*i/RING_SIDES
        b=math.tau*(i+1)/RING_SIDES
        rod("BracedTopExhaustRing_%02d"%i,"BRUSHED",
            (5.12*math.cos(a),21.7,5.12*math.sin(a)),
            (5.12*math.cos(b),21.7,5.12*math.sin(b)),.24,10)
        rod("TopPressureReliefStanchion_%02d"%i,"ALLOY",
            (5.16*math.cos(a),21.7,5.16*math.sin(a)),
            (5.40*math.cos(a),23.05,5.40*math.sin(a)),.10,8)
    for i in range(8):
        a=math.tau*i/8
        rod("UpperLipServiceRim_%02d"%i,"GRIP",
            (5.40*math.cos(a),23.05,5.40*math.sin(a)),
            (5.40*math.cos(a+math.tau/8),23.05,
             5.40*math.sin(a+math.tau/8)),.12,8)
    for i in range(4):
        a=math.pi*.5*i
        block("VentThroatSealedAirSampler_%d"%i,"CARBON",
              3.1*math.cos(a),20.8,
              3.1*math.sin(a),.75,1.35,.85,.16)
        rod("AirSamplerAntenna_%d"%i,"ALLOY",
            (3.1*math.cos(a),21.2,3.1*math.sin(a)),
            (3.1*math.cos(a),23.3,3.1*math.sin(a)),.08,8)
        block("AirSamplerSafetyFlag_%d"%i,"SIGNAL",
              3.1*math.cos(a),23.27,
              3.1*math.sin(a),.35,.13,.32,.035)

    # A real continuous exterior access ladder with 16 rung steps,
    # protected by grated ladder rails. Slightly offset from the wall.
    ladder_radius=5.80
    for sign in (-1,1):
        rod("GalvanizedHighServiceLadderRail_"+str(sign),"BRUSHED",
            (sign*.40,-21.3,-ladder_radius),
            (sign*.40,19.5,-ladder_radius),.12,8)
        rod("LadderSelfSupportingCage"+str(sign),"GRIP",
            (sign*1.05,-20.2,-ladder_radius),
            (sign*1.05,18.6,-ladder_radius),.07,8)
    for rung in range(17):
        y=-20.5+rung*2.37
        rod("ServiceLadderForgedRung_%02d"%rung,"ALLOY",
            (-.50,y,-ladder_radius),(.50,y,-ladder_radius),.085,8)

    # Two large equipment pods ensure a deliberate asymmetrical silhouette
    # that reads at 200+ studs. Pipework is geometry, not procedural lights.
    for side in (-1,1):
        block("AuxiliaryCoolantManifold"+str(side),"CERAMIC",
              side*5.15,-10.55,0,2.40,7.2,2.12,.36)
        block("ManifoldCentrifugalPump"+str(side),"CARBON",
              side*5.62,-12.5,0,2.36,2.5,2.5,.27)
        for section in range(4):
            y=-12.8+section*1.95
            rod("ActualGlycolPressurePipe_%s_%d"%(side,section),"ALLOY",
                (side*6.20,y,-1.4),
                (side*6.20,y+1.55,1.3),.105,10)
        block("MachinedManifoldControlPanel"+str(side),"SIGNAL",
              side*6.48,-8.7,0,.10,1.30,1.45,.04)

    assert model.materials==set(MATERIALS),model.materials
    assert 185<=model.groups<=410,model.groups
    assert 3700<=model.triangles<=12500,model.triangles
    return model


def export(path:Path)->dict:
    art=create()
    dims=[round(art.maximum[i]-art.minimum[i],6) for i in range(3)]
    center=[round((art.maximum[i]+art.minimum[i])/2,6) for i in range(3)]
    # Modeled 44-stud native stack is authored at .46 source ratio.
    assert 5.4<=dims[0]<=6.5,dims
    assert 20.5<=dims[1]<=21.5,dims
    assert 5.0<=dims[2]<=6.5,dims
    path.parent.mkdir(parents=True,exist_ok=True)
    data="\n".join(art.lines)+"\n"
    path.write_text(data,encoding="utf-8")
    return {"asset":ASSET,"groups":art.groups,"triangles":art.triangles,
            "vertices":art.vertices,"materials":sorted(art.materials),
            "bounds_min":art.minimum,"bounds_max":art.maximum,
            "size":dims,"bounds_center":center,
            "source_scale":SCALE,"reference_height":REFERENCE_HEIGHT,
            "sha256":hashlib.sha256(data.encode("utf-8")).hexdigest()}


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    arguments=parser.parse_args()
    print(json.dumps(export(arguments.output),sort_keys=True))
