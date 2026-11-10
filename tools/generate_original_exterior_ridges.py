#!/usr/bin/env python3
"""Four distinct original sculpted exterior ridge models, not Roblox wedges.

Each authored corner profile models precisely the three nonphysical native
ExteriorRidgeNW/NE/SW/SE WedgeParts, including source-dependent crest
heights, yaw and corner offsets. Seven real material groups are generated
in OBJ, later built into separate glTF MeshParts and owner-moderated assets.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

CORNERS={"NW":(-1,-1),"NE":(1,-1),"SW":(-1,1),"SE":(1,1)}
SCALE=1.0


def native_height(index,sx,sz):
    return 9+((index*7+sx*3+sz*5+20)%11)


def transform(sx,sz,index,x,y,z):
    yaw=math.atan2(sx,sz)+(index-2)*.32
    c,t=math.cos(yaw),math.sin(yaw)
    return (c*x+t*z+(index-2)*sx*8,
            y-1.5,
            -t*x+c*z+(index-2)*sz*6)


def make_ridge(a,sx,sz,index):
    height=native_height(index,sx,sz)
    width=11+index*3
    depth=13+index*2
    def at(x,y,z):
        return transform(sx,sz,index,x,y,z)
    # Original irregular lofted-rock plate with a sloping roof and seven
    # longitudinal sectors; the planar wedge is only a source fallback.
    nx,nz=8,7
    verts=[]
    for j in range(nz):
        v=-1+2*j/(nz-1)
        for i in range(nx):
            u=-1+2*i/(nx-1)
            # native slope in +Z, relieved with a broken shoulder
            slope=.16+.79*(v+1)/2
            edge=1-.21*abs(u)**1.4
            fracture=(math.sin((index*3+i)*1.9+j*.7)
                      +math.cos((j+index)*2.3+i*.6))*.041
            top=height*max(.09,min(.94,slope*edge+fracture))
            verts.append(at(u*width*.48,top,v*depth*.47))
    base_indices=[]
    for j in range(nz):
        v=-1+2*j/(nz-1)
        for i in range(nx):
            u=-1+2*i/(nx-1)
            base_indices.append(len(verts))
            verts.append(at(u*width*.48,.08,v*depth*.47))
    faces=[]
    for j in range(nz-1):
        for i in range(nx-1):
            q=j*nx+i
            faces.extend(((q,q+1,q+nx),(q+1,q+nx+1,q+nx)))
            qb=base_indices[q]
            faces.extend(((qb,qb+nx,qb+1),
                          (qb+1,qb+nx,qb+nx+1)))
    # watertight four exterior sidewalls
    for j in range(nz-1):
        for i in (0,nx-1):
            q=j*nx+i
            v=q+nx
            qb=base_indices[q]
            vb=base_indices[v]
            if i==0:
                faces.extend(((q,v,vb),(q,vb,qb)))
            else:
                faces.extend(((v,q,qb),(v,qb,vb)))
    for i in range(nx-1):
        for j in (0,nz-1):
            q=j*nx+i
            v=q+1
            qb=base_indices[q]
            vb=base_indices[v]
            if j==0:
                faces.extend(((v,q,qb),(v,qb,vb)))
            else:
                faces.extend(((q,v,vb),(q,vb,qb)))
    a.add("JaggedSculptedRidgeRock%s"%(index),"ARMOR",verts,faces)

    def block(name,material,x,y,z,dx,dy,dz,bevel=.12):
        xx,yy,zz=at(x,y,z)
        # Blocks are intentionally small and oriented as individual
        # forged features; rock's larger irregular surface carries silhouette.
        a.beveled_block(name,material,xx,yy,zz,dx,dy,dz,bevel)

    def rod(name,material,p,q,radius=.11,sides=10):
        a.rod(name,material,at(*p),at(*q),radius,sides)

    # Dense original manufactured reinforcement, embedded in the rock.
    for side in (-1,1):
        ux=side*width*.435
        for k in range(4):
            v=-.83+k*.53
            z=v*depth*.46
            y=height*(.16+.79*(v+1)/2)*(.82)+.02
            block("ForgedSideArmor%s_%s_%d"%(index,side,k),"BRUSHED",
                  ux,y*.46,z, .33,max(1.3,y*.66),.42,.08)
            rod("BraidedSideRib%s_%s_%d"%(index,side,k),"GRIP",
                (ux-.1,y*.25,z-1.0),(ux+.1,max(.8,y*.85),z+.85),.105,8)
        rod("HorizonLongitudinalEdge%s_%s"%(index,side),"ALLOY",
            (ux,.8,-depth*.45),
            (ux,height*.78,depth*.45),.17,10)

    # Ribbed brace plates traverse the angled upper surface, not a
    # uniform row of primitive rectangular columns.
    for k in range(6):
        v=-.72+k*.285
        z=v*depth*.45
        slope=(.16+.79*(v+1)/2)*.79
        y=height*slope
        for side in (-1,1):
            x=side*width*.20
            rod("ForgedCrestSpine%s_%d_%s"%(index,k,side),"ALLOY",
                (x,y*.86,z-.42),(x,y*.92,z+.42),.145,10)
            block("RecessedTitaniumStud%s_%d_%s"%(index,k,side),
                  "CERAMIC",x,y*.80,z,.38,.24,.28,.07)

    # Fine carapace vents and segmented signal lights, visibly displaced
    # at different heights and slopes, no single flat decal texture.
    for k in range(8):
        x=-width*.31+k*width*.089
        z=depth*.32
        y=height*.74*(1-.17*abs(x)/(width*.5))
        block("CarbonFracturePanel%s_%02d"%(index,k),"CARBON",
              x,y,z,.42,.26,.73,.075)
        block("RecessedWarningEmber%s_%02d"%(index,k),"SIGNAL",
              x,y+.20,z+.16,.26,.10,.12,.027)
    for k in range(4):
        z=-depth*.39+k*depth*.24
        y=height*(.16+.79*((z/depth*.47)+1)/2)*.77
        rod("SculptedCrystallineRidgeCrown%s_%d"%(index,k),"CERAMIC",
            (0,max(.4,y-.75),z),(0,y+.45,z+.22),.19,9)


def export(path,corner):
    sx,sz=CORNERS[corner]
    a=Sculpture()
    a.lines[0]="# Chaos Survival original carved exterior ridge "+corner
    a.lines[2]="o ChaosOriginalExteriorRidges"+corner
    for idx in (1,2,3):
        make_ridge(a,sx,sz,idx)
    mn=list(a.minimum);mx=list(a.maximum)
    center=[(mn[k]+mx[k])/2 for k in range(3)]
    dims=[round(mx[k]-mn[k],5) for k in range(3)]
    assert set(a.materials)==set(MATERIALS),a.materials
    assert 100<=a.groups<=900,(a.groups,a.triangles)
    assert 2000<=a.triangles<=18000,a.triangles
    assert 15<dims[0]<55 and 8<dims[1]<22 and 15<dims[2]<55,dims
    assert all(abs(v)<29.4 for v in mn+mx),(mn,mx)
    # Source model is centred on the enclosing box; the EXACT original
    # source-world offset is metadata used by the runtime placement.
    raw=[]
    for line in a.lines:
        if line.startswith("v "):
            pt=[float(v) for v in line.split()[1:]]
            raw.append("v "+" ".join(f"{pt[k]-center[k]:.6f}" for k in range(3)))
        else:
            raw.append(line)
    obj="\n".join(raw)+"\n"
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(obj,encoding="utf-8")
    return {
        "asset":"exterior_ridges_"+corner.lower(),
        "corner":corner,"corner_signs":[sx,sz],
        "native_heights":[native_height(i,sx,sz) for i in (1,2,3)],
        "triangles":a.triangles,"groups":a.groups,"vertices":a.vertices,
        "materials":sorted(a.materials),
        "bounds":dims,"offset":[round(c,5) for c in center],
        "sha256":hashlib.sha256(obj.encode()).hexdigest(),
    }


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--model",choices=["exterior_ridges_"+x.lower()
                        for x in CORNERS],required=True)
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output,args.model.split("_")[-1].upper()),
                     sort_keys=True))
