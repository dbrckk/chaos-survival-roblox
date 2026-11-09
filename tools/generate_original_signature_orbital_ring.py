#!/usr/bin/env python3
"""Original closed 3D axial megareactor ring of Chaos Survival: Orbital.

A 72-segment continuous TORUS is true topology rather than 16 rectangular
Roblox Parts. All source meshes carry existing original PBR materials.
The original ring occupies a nonphysical outboard landmark only.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture

PROFILE = "signature_orbital_reactor_ring"


def torus(art: Sculpture, name: str, material: str,
          radius: float, tube: float, depth: float,
          segments: int = 72, sides: int = 10):
    vertices = []
    for i in range(segments):
        theta = math.tau*i/segments
        ct, st = math.cos(theta), math.sin(theta)
        for j in range(sides):
            phi = math.tau*j/sides
            radial = radius + tube*math.cos(phi)
            vertices.append((radial*ct,radial*st,
                             depth + tube*math.sin(phi)))
    faces = []
    for i in range(segments):
        for j in range(sides):
            a=i*sides+j
            b=((i+1)%segments)*sides+j
            c=((i+1)%segments)*sides+(j+1)%sides
            d=i*sides+(j+1)%sides
            faces.extend(((a,b,c),(a,c,d)))
    art.add(name,material,vertices,faces)


def create() -> Sculpture:
    art=Sculpture()
    art.lines[0]="# Chaos Survival original full 3D orbital megareactor ring"
    art.lines[2]="o ChaosOriginal_OrbitalSignatureReactorRing"
    # Closed nested toroidal casings: continuous circular mass with a truly
    # hollow center. Source size about 17 studs; game uniformly scales
    # ~2.4x to the actual 40-stud vertical landmark.
    torus(art,"ForgedContinuousSeventyTwoSegmentMainTorus","ARMOR",
          8.06,.43,0)
    torus(art,"MachinedInnerFluxContainmentRim","BRUSHED",
          7.57,.17,-.06)
    torus(art,"SealedBackDielectricInsulator","CARBON",
          7.85,.17,.37)
    torus(art,"CeramicCryogenicShieldFlange","CERAMIC",
          8.26,.11,-.35)
    for i in range(16):
        angle=math.tau*i/16
        ct,st=math.cos(angle),math.sin(angle)
        root=7.30
        tip=8.13
        art.rod("CurvedForgedFieldLink%02d"%i,"ALLOY",
                (root*ct,root*st,-.39),(tip*ct,tip*st,-.66),
                .082,10)
        art.beveled_block("EmbossedFluxVentCassette%02d"%i,"GRIP",
                          7.93*ct,7.93*st,-.55,
                          .30,.32,.20,.050)
        art.beveled_block("RadiantSegmentReader%02d"%i,"SIGNAL",
                          8.10*ct,8.10*st,-.70,
                          .18,.19,.09,.026)
    dimensions=[round(art.maximum[i]-art.minimum[i],4)
                for i in range(3)]
    assert art.materials==set(MATERIALS),art.materials
    assert 45<=art.groups<=65,art.groups
    assert 5500<=art.triangles<=10000,art.triangles
    assert 16.8<=dimensions[0]<=17.4,dimensions
    assert 16.8<=dimensions[1]<=17.4,dimensions
    assert 1.1<=dimensions[2]<=1.9,dimensions
    # The center axis must remain open, not a fake flat texture.
    assert not any("CoreFiller" in line for line in art.lines)
    return art


def export(out: Path):
    art=create()
    raw="\n".join(art.lines)+"\n"
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(raw,encoding="utf-8")
    return {
        "asset":PROFILE,
        "triangles":art.triangles,
        "groups":art.groups,
        "vertices":art.vertices,
        "materials":sorted(art.materials),
        "bounds":[round(art.maximum[i]-art.minimum[i],5) for i in range(3)],
        "min":art.minimum,"max":art.maximum,
        "sha256":hashlib.sha256(raw.encode()).hexdigest(),
    }


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))


if __name__=="__main__":
    main()
