#!/usr/bin/env python3
"""Genuinely hollow original 3D SOUTH Orbital observation ring.

Replaces fourteen primitive rectangular observation arcs of the southern
outboard landmark (not the separate northern reactor signature ring).
All artwork belongs to Chaos Survival, using the established 7 PBR materials.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture
from generate_original_signature_orbital_ring import torus

NAME="south_orbital_observation_torus"


def build():
    art=Sculpture()
    art.lines[0]="# Creator-owned SOUTH Orbital continuous observatory torus"
    art.lines[2]="o ChaosSouthOrbitalObservatoryRing"
    # The source radius is ~7.1 and is uniformly scaled by 34.55 / 14.84.
    # An OPEN center and 14 genuinely curved independently sculpted magnetic
    # link elements distinguish this from the northern 16-arc reactor.
    torus(art,"ContinuousSouthSeventyTwoSegmentForgedHull","ARMOR",
          7.09,.33,.02)
    torus(art,"BrushedSouthInnerObservationTrack","BRUSHED",
          6.75,.13,-.12)
    torus(art,"SubsurfaceCarbonRearContainment","CARBON",
          6.98,.14,.33)
    torus(art,"SatinCeramicSouthShield","CERAMIC",
          7.23,.11,-.34)
    for i in range(14):
        angle=math.tau*i/14
        ct,st=math.cos(angle),math.sin(angle)
        art.rod("BracedSouthAngularFieldCoupler%02d"%i,"ALLOY",
                (6.65*ct,6.65*st,-.37),
                (7.13*ct,7.13*st,-.62),.078,10)
        art.beveled_block("SouthRadialVentedMetalCassette%02d"%i,"GRIP",
                          7.02*ct,7.02*st,-.49,
                          .24,.25,.18,.044)
        art.beveled_block("SouthCeramicLightReader%02d"%i,"SIGNAL",
                          7.18*ct,7.18*st,-.69,
                          .16,.17,.085,.023)
    bounds=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    assert art.materials==set(MATERIALS),art.materials
    assert 44<=art.groups<=58,(art.groups,bounds)
    assert 5700<=art.triangles<=8700,art.triangles
    assert 14.65<=bounds[0]<=15.10,bounds
    assert 14.65<=bounds[1]<=15.10,bounds
    assert 1.0<=bounds[2]<=1.6,bounds
    return art,bounds


def export(out):
    art,bounds=build()
    obj="\n".join(art.lines)+"\n"
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(obj,encoding="utf-8")
    return {
        "asset":NAME,"triangles":art.triangles,
        "groups":art.groups,"vertices":art.vertices,
        "materials":sorted(art.materials),"bounds":bounds,
        "sha256":hashlib.sha256(obj.encode()).hexdigest()
    }


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))


if __name__=="__main__":
    main()
