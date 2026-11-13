#!/usr/bin/env python3
"""Creator-authored industrial side-rim shells for rectangular Chaos platforms.

These meshes represent the FOUR decorative perimeter WedgeParts together,
not a walkable deck. Both variants are true triangulated OBJ source assets
with seven UV/tangent-ready materials. NEVER hide server-native geometry
until Roblox approves a matching Model and runtime checks its actual fit.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

MODELS = {
    "platform_rim_rect": (17.0, 10.0),
    "platform_rim_long": (26.0, 8.0),
}


def faceted_skirt(art: Sculpture, face: int, along_z: bool,
                  hx: float, hz: float) -> None:
    """Eight-sided closed sloping fascia, wholly below the true deck top."""
    if along_z:
        edge = face * (hz - .18)
        inset = face * (hz - .92)
        v = [
            (-hx+.22,-.12,edge), (hx-.22,-.12,edge),
            (hx-.78,-1.04,inset), (-hx+.78,-1.04,inset),
            (-hx+.22,-.31,edge-face*.12), (hx-.22,-.31,edge-face*.12),
            (hx-.78,-1.23,inset-face*.12), (-hx+.78,-1.23,inset-face*.12),
        ]
    else:
        edge = face * (hx - .18)
        inset = face * (hx - .92)
        v = [
            (edge,-.12,-hz+.22),(edge,-.12,hz-.22),
            (inset,-1.04,hz-.78),(inset,-1.04,-hz+.78),
            (edge-face*.12,-.31,-hz+.22),
            (edge-face*.12,-.31,hz-.22),
            (inset-face*.12,-1.23,hz-.78),
            (inset-face*.12,-1.23,-hz+.78),
        ]
    tris = [
        (0,1,2),(0,2,3),(4,6,5),(4,7,6),
        (0,4,5),(0,5,1),(1,5,6),(1,6,2),
        (2,6,7),(2,7,3),(3,7,4),(3,4,0),
    ]
    if face < 0:
        tris = [(a,c,b) for a,b,c in tris]
    art.add("CastSlopedRim_%s_%s" % (along_z,face), "ARMOR", v, tris)


def edge_detail(art: Sculpture, face: int, along_z: bool,
                hx: float, hz: float, count: int) -> None:
    span = (hx if along_z else hz)
    distance = (hz if along_z else hx)
    # Permanent rail, inset carbon recess, grip detail, shadow cuts and
    # machined ceramic shields: true bevelled polygon meshes, not Parts.
    for material, label, y, inside, depth in (
        ("BRUSHED", "SatinForgedLip", -.24, .29, .13),
        ("CARBON", "ShadowReveal", -.65, .38, .17),
        ("GRIP", "SerratedLowerEdge", -.91, .55, .15),
    ):
        if along_z:
            art.beveled_block("%s_%s_%s" % (label,along_z,face),
                              material,0,y,face*(distance-inside),
                              span*1.82,.14,depth,.035)
        else:
            art.beveled_block("%s_%s_%s" % (label,along_z,face),
                              material,face*(distance-inside),y,0,
                              depth,.14,span*1.82,.035)
    for k in range(count):
        run = (-.79 + 1.58*(k+.5)/count)*span
        if along_z:
            px,pz = run,face*(distance-.48)
            outer = (run,-.27,face*(distance-.30))
            inner = (run*.92,-1.48,face*(distance-1.22))
        else:
            px,pz = face*(distance-.48),run
            outer = (face*(distance-.30),-.27,run)
            inner = (face*(distance-1.22),-1.48,run*.92)
        art.rod("ShearBolt_%s_%s_%s" % (along_z,face,k),
                "ALLOY",outer,inner,.085,8)
        if along_z:
            art.beveled_block("CeramicShield_%s_%s_%s" %
                              (along_z,face,k),"CERAMIC",
                              px,-.52,pz,.46,.25,.21,.07)
        else:
            art.beveled_block("CeramicShield_%s_%s_%s" %
                              (along_z,face,k),"CERAMIC",
                              px,-.52,pz,.21,.25,.46,.07)
    # Subtle side-mounted instrument markers, NOT a replacement for the
    # genuine illuminated route/hazard cues owned by the server.
    for k in (0,1):
        run = span*( -.47 if k == 0 else .47 )
        if along_z:
            art.beveled_block("EmbeddedMarker_%s_%s_%s" %
                              (along_z,face,k),"SIGNAL",
                              run,-.41,face*(distance-.23),.38,.10,.065,.02)
        else:
            art.beveled_block("EmbeddedMarker_%s_%s_%s" %
                              (along_z,face,k),"SIGNAL",
                              face*(distance-.23),-.41,run,.065,.10,.38,.02)


def sculpt(art: Sculpture, kind: str) -> None:
    sx,sz=MODELS[kind]
    hx,hz=sx*.5,sz*.5
    for along_z in (True,False):
        for face in (-1,1):
            faceted_skirt(art,face,along_z,hx,hz)
            edge_detail(art,face,along_z,hx,hz,
                        5 if along_z and sx>20 else 3)
    # Low-overdraw, open-bottom interlocking corners: real diagonal struts
    # and mechanically distinct inset sockets visible under jump platforms.
    for i in (-1,1):
        for j in (-1,1):
            x,z=i*(hx-.94),j*(hz-.94)
            art.beveled_block("CastCornerSocket_%s_%s"%(i,j),"BRUSHED",
                              x,-1.13,z,.71,.29,.71,.13)
            art.beveled_block("TorsionIsolator_%s_%s"%(i,j),"GRIP",
                              x,-1.30,z,.49,.16,.49,.09)
            art.rod("TriangulatedCornerWeb_%s_%s"%(i,j),"ALLOY",
                    (i*(hx-.52),-.58,j*(hz-.55)),
                    (i*(hx-2.10),-2.14,j*(hz-1.86)),.105,10)
    # No solid false underside. Players still see the REAL server
    # collidable landing, and warning platforms still disappear on demand.
    art.beveled_block("RecessedMidlineServiceSpine","ALLOY",
                      0,-2.12,0,sx*.64,.23,.48,.09)
    for i in range(5 if sx>20 else 3):
        x = (-.32 + .64*i/(4 if sx>20 else 2))*sx
        art.beveled_block("ServiceCrossTie_%d"%i,"CARBON",
                          x,-1.89,0,.24,.21,sz*.55,.08)


def emit(kind: str, path: Path) -> dict:
    if kind not in MODELS:
        raise ValueError("Unknown approved source candidate")
    art=Sculpture()
    art.lines[0]="# Chaos Survival original perimeter 3D: "+kind
    art.lines[2]="o ChaosAuthored_"+kind
    sculpt(art,kind)
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    if set(art.materials) != set(MATERIALS):
        raise ValueError("Seven material MeshPart families required")
    if not (38 <= art.groups <= 155 and 500 <= art.triangles <= 6500):
        raise ValueError("Original perimeter mesh invalid polygon budget")
    x,y,z=dims
    ex,ez=MODELS[kind]
    if not (ex-1.0 <= x <= ex+.1 and ez-1.0 <= z <= ez+.1
            and 2.0 <= y <= 2.6):
        raise ValueError("Invalid authored perimeter geometry: "+repr(dims))
    path.parent.mkdir(parents=True,exist_ok=True)
    obj="\n".join(art.lines)+"\n"
    path.write_text(obj,encoding="utf-8")
    return {
        "asset":kind, "triangles":art.triangles, "groups":art.groups,
        "vertices":art.vertices,"dimensions":dims,
        "materials":sorted(art.materials),
        "sha256":hashlib.sha256(obj.encode()).hexdigest(),
        "source_is_author_3d":True,
        "client_replaces_server_colliders":False,
    }


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--model",choices=tuple(MODELS),required=True)
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(emit(args.model,args.output),sort_keys=True))
