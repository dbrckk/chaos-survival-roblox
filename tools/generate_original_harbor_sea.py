#!/usr/bin/env python3
"""Author a REAL triangulated ocean around Storm Harbor's playable 320x320.

Not a flat Roblox Part, texture decal, toolbox mesh, physics Terrain water,
or a hidden fake solid platform. An actual single seven-material glTF model
with 4 continuous wave-sculpted coastal bands, hand-authored wavefront
ribbons, shoals, drift currents, surf foam and maritime glints.

Source space 1:20: dry playable center is the untouched +/-164 stud square
(source +/-8.2), sea reaches +/-480 studs (source +/-24.0).
All geometry lies OUTSIDE the 320x320 authoritative floor.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import Sculpture, MATERIALS

NAME = "harbor_sea_apron"
SOURCE_SCALE = .05
OUTER = 24.0
INNER = 8.24
PALETTE = "chaos_harbor_sea.mtl"


def wave(x: float, z: float) -> float:
    # Three relatively prime, weak large-period modes avoid the unmistakable
    # perfectly flat rectangle without introducing a mesh-deforming timer.
    return (
        .0120 * math.sin(.93 * x + .37 * z)
        + .0080 * math.sin(1.36 * z - .25 * x)
        + .0045 * math.cos(.55 * x - 1.19 * z)
    )


def create() -> Sculpture:
    art = Sculpture()
    art.lines[0] = "# Original Chaos Survival tessellated Storm Harbor SEA"
    art.lines[1] = "mtllib " + PALETTE
    art.lines[2] = "o ChaosOriginalStormHarborSeaCoastalAnnulus"

    def grid(name, material, xa, xb, za, zb, nx, nz, lift=0):
        if not (-OUTER<=xa<xb<=OUTER and -OUTER<=za<zb<=OUTER):
            raise ValueError("Ocean mesh bounds crossed")
        verts=[]
        for zi in range(nz+1):
            z=za+(zb-za)*zi/nz
            for xi in range(nx+1):
                x=xa+(xb-xa)*xi/nx
                verts.append((x,wave(x,z)+lift,z))
        faces=[]
        stride=nx+1
        for zi in range(nz):
            for xi in range(nx):
                a=zi*stride+xi
                b=a+1
                d=a+stride
                c=d+1
                # All surfaces have CCW winding seen from ABOVE.
                faces.extend(((a,d,b),(b,d,c)))
        art.add(name,material,verts,faces)

    def crest(name, material, side, offset, span, width, phase, lift):
        # Continuous but *bent*, sculpted finite-duration ripples, not a
        # straight line painted onto a Part. Each has a real ribbon width
        # and independent upward triangle normals.
        segments=11
        vertices=[]
        horizontal=side in ("north","south")
        sign=-1 if side in ("north","west") else 1
        for i in range(segments+1):
            t=-1+2*i/segments
            lateral=t*span + .15*math.sin(t*4.2+phase)
            offshore=sign*offset + sign*.12*math.sin(t*5.3+phase)
            if horizontal:
                x=lateral
                z=offshore
                left=(x,z-width*.5)
                right=(x,z+width*.5)
            else:
                x=offshore
                z=lateral
                left=(x-width*.5,z)
                right=(x+width*.5,z)
            for px,pz in (left,right):
                y=wave(px,pz)+lift+ .004*math.sin(t*8+phase)
                vertices.append((px,y,pz))
        faces=[]
        for i in range(segments):
            a=i*2;b=a+1;c=a+2;d=a+3
            if horizontal:
                faces.extend(((a,b,c),(b,d,c)))
            else:
                faces.extend(((a,c,b),(b,c,d)))
        art.add(name,material,vertices,faces)

    # Four EDGE-TO-EDGE wave-sculpted ocean panels. The inner square has
    # no geometry whatsoever: no invisible false landing pad, flooding
    # of the real playable floor, or interference with ShrinkingArena.
    for side in ("north","south","west","east"):
        if side=="north":
            bounds=(-OUTER,OUTER,-OUTER,-INNER)
            near=(-OUTER,OUTER,-10.1,-INNER)
            far=(-OUTER,OUTER,-OUTER,-20.8)
            subdivisions=(34,13)
        elif side=="south":
            bounds=(-OUTER,OUTER,INNER,OUTER)
            near=(-OUTER,OUTER,INNER,10.1)
            far=(-OUTER,OUTER,20.8,OUTER)
            subdivisions=(34,13)
        elif side=="west":
            bounds=(-OUTER,-INNER,-INNER,INNER)
            near=(-10.1,-INNER,-INNER,INNER)
            far=(-OUTER,-20.8,-INNER,INNER)
            subdivisions=(13,22)
        else:
            bounds=(INNER,OUTER,-INNER,INNER)
            near=(INNER,10.1,-INNER,INNER)
            far=(20.8,OUTER,-INNER,INNER)
            subdivisions=(13,22)
        grid("OceanBlueFacetedWaveSheet_"+side,"ARMOR",*bounds,
             *subdivisions)
        grid("ShallowQuaysideTidalShelf_"+side,"BRUSHED",*near,
             18 if side in ("north","south") else 3,
             3 if side in ("north","south") else 12,
             .0055)
        grid("DeepOffshoreShadowField_"+side,"CARBON",*far,
             18 if side in ("north","south") else 3,
             3 if side in ("north","south") else 12,
             .0045)

        for k in range(8):
            offset=10.3+k*1.55
            span=7.0+(k%4)*2.65
            crest("LongWindCarvedSurfaceRipples_%s_%d"%(side,k),
                  "GRIP",side,offset,span,
                  .12+(k%3)*.05,k*.71+(.6 if side in ("west","south") else 0),
                  .0115)
        for k in range(5):
            offset=9.60+k*2.2
            crest("HarmonicCrossCurrentRidge_%s_%d"%(side,k),
                  "ALLOY",side,offset,9.4+(k%2)*3.6,
                  .060,k*.91+1.4,.015)
        # Inshore white-capped breakup is discontinuous, deliberately:
        # no rectangular beam looks like an artificial walkable edge.
        for k in range(7):
            center=(k-3)*2.77
            crest("IntermittentMaritimeShoreFoam_%s_%d"%(side,k),
                  "CERAMIC",side,8.43+(k%2)*.21,
                  1.12+.13*(k%3),.037,k*.44+center,.021)

        for k in range(7):
            offset=12.2+(k*1.61)%8.6
            span=1.08+(k%3)*.29
            crest("DistantBrokenSunGlint_%s_%d"%(side,k),
                  "SIGNAL",side,offset,span,.032,
                  k*.86 + (0 if side in ("north","east") else 1.9),.021)

    # Real V-shaped prop wash around the approved original 88-stud cargo
    # ship, located northwest at (x=-2.88,z=-11.4) in source units.
    # These are short, transparent surface wake contours, NOT a synthetic
    # second cargo ship or an invented gameplay route.
    for i in range(6):
        z=-11.0-(i*.66)
        for flank in (-1,1):
            x=-2.90+flank*(3.35+i*.73)
            # A short changing wave ridge with actual triangulated area.
            side="north" if flank<0 else "south"
            # Real 'north/south' crest direction is X; choose phase to
            # distinguish the starboard from the port wake.
            if -OUTER<x<OUTER and -OUTER<z<-INNER:
                vertices=[]
                for u in range(7):
                    t=u/6
                    px=x+flank*t*.76
                    pz=z-t*.35
                    for delta in (-.035,.035):
                        xx=px+delta
                        vertices.append((xx,wave(xx,pz)+.026,pz))
                faces=[]
                for u in range(6):
                    a=u*2;b=a+1;c=a+2;d=a+3
                    faces.extend(((a,c,b),(b,c,d)))
                art.add(f"OriginalFreighterWaveWake_{i}_{flank}",
                        "ALLOY",vertices,faces)

    assert art.materials==set(MATERIALS),art.materials
    assert 45<=art.groups<=220,art.groups
    assert 2000<=art.triangles<=8500,art.triangles
    assert art.minimum[0]>=-OUTER and art.maximum[0]<=OUTER
    assert art.minimum[2]>=-OUTER and art.maximum[2]<=OUTER
    return art


def export(path:Path)->dict:
    art=create()
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    center=[round((art.minimum[i]+art.maximum[i])*.5,5) for i in range(3)]
    assert 47.95<=dims[0]<=48.0,dims
    assert 47.95<=dims[2]<=48.0,dims
    assert 0.03<=dims[1]<=0.18,dims
    path.parent.mkdir(parents=True,exist_ok=True)
    obj="\n".join(art.lines)+"\n"
    path.write_text(obj,encoding="utf-8")
    return {"asset":NAME,"scale":SOURCE_SCALE,"source_units_to_studs":20,
            "inner_dry_halfwidth_studs":INNER/SOURCE_SCALE,
            "outer_halfwidth_studs":OUTER/SOURCE_SCALE,
            "groups":art.groups,"triangles":art.triangles,
            "vertices":art.vertices,"materials":sorted(art.materials),
            "palette":PALETTE,"dimensions":dims,"bbox_center":center,
            "source_min":art.minimum,"source_max":art.maximum,
            "sha256":hashlib.sha256(obj.encode()).hexdigest()}


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))
