#!/usr/bin/env python3
"""Creator-owned original axial ventilation fan; never a fabricated Roblox MeshId."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture

def annulus(art: Sculpture, name: str, material: str,
            inner: float, outer: float, y0: float, y1: float, sides: int = 32):
    vertices = []
    for k in range(sides):
        a = math.tau * k / sides
        c, s = math.cos(a), math.sin(a)
        vertices.extend(((inner*c, y0, inner*s),
                         (outer*c, y0, outer*s),
                         (inner*c, y1, inner*s),
                         (outer*c, y1, outer*s)))
    faces = []
    for k in range(sides):
        i, j = 4*k, 4*((k+1)%sides)
        faces.extend(((i,j+1,j),(i,i+1,j+1),
                      (i+2,j+2,j+3),(i+2,j+3,i+3),
                      (i+1,i+3,j+3),(i+1,j+3,j+1),
                      (i,j,j+2),(i,j+2,i+2)))
    art.add(name, material, vertices, faces)

def swept_blade(art: Sculpture, index: int, count: int = 9):
    a = math.tau * index / count
    outline = ((.36,-.34),(.88,-.37),(1.02,.09),(.41,.37))
    top=[]
    for radius, angle in outline:
        t=a+angle
        top.append((radius*math.cos(t),.12+(.92-radius)*.08,
                    radius*math.sin(t)))
    bottom=[(x, y-.20, z) for x,y,z in top]
    verts=top+bottom
    faces=[(0,1,2),(0,2,3),(4,6,5),(4,7,6)]
    for k in range(4):
        nxt=(k+1)%4
        faces.extend(((k,nxt,nxt+4),(k,nxt+4,k+4)))
    art.add('SculptedSweptImpellerBlade%02d'%index, 'GRIP', verts, faces)

def create() -> Sculpture:
    art=Sculpture()
    art.lines[0]='# Original Chaos Survival sculpted perimeter machinery rotor'
    art.lines[2]='o ChaosOriginal_PerimeterRotor'
    annulus(art,'DieCastThirtyTwoFacetFanShroud','ARMOR',1.07,1.28,-.36,.36)
    annulus(art,'InnerMachinedRotorRim','BRUSHED',.98,1.055,-.29,.29)
    art.rod('ClosedArmoredDriveHub','CARBON',(0,-.34,0),(0,.34,0),.35,16)
    for n in range(9):
        swept_blade(art,n)
    for n in range(8):
        theta=math.tau*n/8
        x,z=.49*math.cos(theta),.49*math.sin(theta)
        art.rod('RetainedDriveBolt%02d'%n,'ALLOY',
                (x,-.395,z),(x,.365,z),.052,10)
    for n in range(4):
        angle=math.tau*n/4
        x,z=1.16*math.cos(angle),1.16*math.sin(angle)
        art.beveled_block('FourPointCeramicLock%02d'%n,'CERAMIC',
                          x,.393,z,.17,.055,.18,.04)
    for n in range(8):
        theta=math.tau*(n+.5)/8
        x,z=1.13*math.cos(theta),1.13*math.sin(theta)
        art.beveled_block('ProtectedAnnularStatusInset%02d'%n,'SIGNAL',
                          x,.391,z,.12,.043,.075,.018)
    dims=[round(art.maximum[i]-art.minimum[i],4) for i in range(3)]
    assert art.materials==set(MATERIALS),art.materials
    assert art.groups==32 and art.triangles==1304
    assert dims==[2.56,.8155,2.56],dims
    return art

def export(out:Path):
    art=create()
    raw='\n'.join(art.lines)+'\n'
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(raw,encoding='utf-8')
    return {'asset':'perimeter_rotor','triangles':art.triangles,
            'groups':art.groups,'vertices':art.vertices,
            'materials':sorted(art.materials),
            'bounds_min':art.minimum,'bounds_max':art.maximum,
            'dimensions':[round(art.maximum[i]-art.minimum[i],4)
                          for i in range(3)],
            'sha256':hashlib.sha256(raw.encode()).hexdigest()}

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--output',type=Path,required=True)
    args=p.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))

if __name__=='__main__':
    main()
