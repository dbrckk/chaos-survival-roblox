#!/usr/bin/env python3
"""Two genuine creator-original Orbital landmark meshes, never Roblox Parts.

Node: closed 16-sided multi-ring core, three interlocking open toroidal
containment collars, milled lugs, insulated hardware and signal markers.
Strut: four continuous forged spars, alternating trusses, nested stabilizers
and separate end joints. Both original models are seven-material cosmetic
sources, to be owner-imported separately after deterministic validation.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture

NODE="variant_orbital_sculpted_node"
STRUT="variant_orbital_trussed_strut"


def sphere(art: Sculpture):
    segments=16
    # No degenerate pole triangles: open radius at the two ends, capped.
    latitudes=(-1.49,-1.14,-.78,-.4,0,.4,.78,1.14,1.49)
    verts=[]
    for theta in latitudes:
        for j in range(segments):
            phi=math.tau*j/segments
            rx=1.48*math.cos(theta)
            verts.append((rx*math.cos(phi),1.48*math.sin(theta),
                          rx*math.sin(phi)))
    faces=[]
    for k in range(len(latitudes)-1):
        for i in range(segments):
            j=(i+1)%segments
            a=k*segments+i
            b=k*segments+j
            c=(k+1)*segments+j
            d=(k+1)*segments+i
            faces.extend(((a,b,c),(a,c,d)))
    top=(len(latitudes)-1)*segments
    for i in range(1,segments-1):
        faces.append((0,i+1,i))
        faces.append((top,top+i,top+i+1))
    art.add("ForgedMultiLatitudeReactorCore","ARMOR",verts,faces)


def ring(art: Sculpture, label: str, axis: int, material: str):
    """Full torus, true through-hole, ring plane orthogonal to axis."""
    seg,minorseg=24,8
    R,r=1.86,.195
    verts=[]
    for i in range(seg):
        theta=math.tau*i/seg
        for j in range(minorseg):
            phi=math.tau*j/minorseg
            radius=R+r*math.cos(phi)
            a,b=radius*math.cos(theta),radius*math.sin(theta)
            out=r*math.sin(phi)
            if axis==0: xyz=(out,a,b)
            elif axis==1: xyz=(a,out,b)
            else: xyz=(a,b,out)
            verts.append(xyz)
    faces=[]
    for i in range(seg):
        ip=(i+1)%seg
        for j in range(minorseg):
            jp=(j+1)%minorseg
            a=i*minorseg+j
            b=ip*minorseg+j
            c=ip*minorseg+jp
            d=i*minorseg+jp
            faces.extend(((a,b,c),(a,c,d)))
    art.add(label,material,verts,faces)


def node_art() -> Sculpture:
    art=Sculpture()
    art.lines[0]="# Original Chaos Survival Orbital multi-collar reactor node"
    art.lines[2]="o ChaosOriginalOrbitalSculptedReactorNode"
    sphere(art)
    ring(art,"HollowEquatorialForgedCollar",2,"BRUSHED")
    ring(art,"OrthogonalRotatingContainmentTrackX",0,"ALLOY")
    ring(art,"OrthogonalRotatingContainmentTrackY",1,"GRIP")
    # Six pinned axial bearings define reliable symmetric 4.36-stud
    # bounds; all details are nonphysical MeshPart art after import.
    for axis in range(3):
        for sign in (-1,1):
            coord=[0.,0.,0.]
            coord[axis]=sign*2.07
            sx,sy,sz=[.38,.38,.38]
            if axis==0: sx=.22
            elif axis==1: sy=.22
            else: sz=.22
            art.beveled_block("SixAxisMilledBearing%d_%s"%(axis,sign),
                              "CERAMIC",*coord,sx,sy,sz,.08)
            coord2=[0.,0.,0.]
            coord2[axis]=sign*2.16
            dims=[.16,.16,.16]
            if axis==0:dims[0]=.04
            elif axis==1:dims[1]=.04
            else:dims[2]=.04
            art.beveled_block("AxialTelemetryEye%d_%s"%(axis,sign),
                              "SIGNAL",*coord2,*dims,.02)
    for i in range(12):
        a=i*math.tau/12
        x,z=1.39*math.cos(a),1.39*math.sin(a)
        art.beveled_block("CarbonReactorCoolingBaffle%02d"%i,
                          "CARBON",x,0,z,.19,.46,.12,.04)
        art.rod("AntennaTrimStrut%02d"%i,"ALLOY",
                (x,-.43,z),(x*.93,.46,z*.93),.055,8)
    return art


def strut_art() -> Sculpture:
    art=Sculpture()
    art.lines[0]="# Original Chaos Survival Orbital open-truss reactor strut"
    art.lines[2]="o ChaosOriginalOrbitalOpenTrussSupport"
    # 8.46 x 1.24 x 1.10 : pronounced sculpted undercarriage, without
    # turning the original decorative 8.5 x .55 x .55 Part into a collider.
    for signY in (-1,1):
        for signZ in (-1,1):
            y,z=signY*.45,signZ*.39
            art.rod("ContinuousForgedReactorSpar%s_%s"%(signY,signZ),
                    "ARMOR",(-4.02,y,z),(4.02,y,z),.075,10)
    for i in range(9):
        x=-3.73+i*.93
        for side in (-1,1):
            z=side*.39
            y0=.40 if i%2 else -.40
            y1=-y0
            art.rod("DiagonalReactorTruss%s_%02d"%(side,i),
                    "ALLOY",(x,y0,z),(x+.77,y1,z),.066,10)
            art.rod("DiagonalCounterbrace%s_%02d"%(side,i),
                    "GRIP",(x,y1,z),(x+.77,y0,z),.046,8)
        art.beveled_block("DieCastCrossMember%02d"%i,"CERAMIC",
                          x+.38,0,0,.20,.68,.84,.05)
        art.beveled_block("CarbonAxialCableTray%02d"%i,"CARBON",
                          x+.38,-.52,0,.66,.08,.55,.03)
        for side in (-1,1):
            art.beveled_block("InlaidStrutPulse%s_%02d"%(side,i),
                              "SIGNAL",x+.38,.54,side*.27,.24,.09,.13,.03)
    for sign in (-1,1):
        x=sign*4.09
        art.beveled_block("MilledLoadSocket%s"%sign,"BRUSHED",
                          x,0,0,.28,1.24,1.10,.11)
        art.beveled_block("SocketRetainer%s"%sign,"GRIP",
                          sign*3.89,0,0,.18,.66,.69,.07)
    for sign in (-1,1):
        art.rod("OpenSpanOpticalConduit%s"%sign,"BRUSHED",
                (-3.72,sign*.25,0),(3.72,sign*.25,0),.062,10)
    return art


def export(path: Path, model: str) -> dict:
    art=node_art() if model==NODE else strut_art() if model==STRUT else None
    if art is None: raise ValueError("Unknown original model")
    raw="\n".join(art.lines)+"\n"
    bounds=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    center=[round((art.maximum[i]+art.minimum[i])*.5,5) for i in range(3)]
    expected=(4.36,4.36,4.36) if model==NODE else (8.46,1.24,1.10)
    if set(art.materials)!=set(MATERIALS):
        raise ValueError(("Seven material source incomplete",art.materials))
    if not (900<=art.triangles<=16000 and 20<=art.groups<=300):
        raise ValueError(("Sculpture complexity outside safe envelope",
                          art.triangles,art.groups))
    if any(abs(a-b)>.12 for a,b in zip(bounds,expected)):
        raise ValueError(("Unexpected source bounds",model,bounds,expected))
    if any(abs(v)>.10 for v in center):
        raise ValueError(("Miscentered source",model,center))
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(raw,encoding="utf8")
    return {"asset":model,"triangles":art.triangles,
            "groups":art.groups,"vertices":art.vertices,
            "materials":sorted(art.materials),
            "bounds":bounds,"center":center,
            "sha256":hashlib.sha256(raw.encode()).hexdigest()}


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--model",choices=(NODE,STRUT),required=True)
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output,args.model),sort_keys=True))
