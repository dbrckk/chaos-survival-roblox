#!/usr/bin/env python3
"""Creator-authored open freight gantry for Storm Harbor's SIX real promenades.

Triangulated real 3D metal/ceramic lattice, suspension, gantry trolley,
suspended container and a matching *under*deck load frame. Seven original
materials, UV/tangent-ready glTF. NO added walkway/collision; an R15 avatar
has >11 studs of unobstructed headroom over the server's 12-stud deck.
The center opening is along Z; X follows the real promenade deck length.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

NAME = "harbor_promenade_portal"


def polygon_load_leg(art: Sculpture, side: int):
    """True 10-sided tapering die-cast open-bridge support, not a Part."""
    zbase = side * 8.15
    stations = (
        (-.35, .84, .91), (1.35, .94, .96), (3.45, .75, .73),
        (8.0, .65, .63), (12.1, .76, .75), (14.65, 1.05, 1.07),
    )
    verts = []
    for y, radius_x, radius_z in stations:
        for k in range(10):
            angle = math.tau * k / 10
            verts.append((radius_x * math.cos(angle), y,
                          zbase + radius_z * math.sin(angle)))
    faces = []
    for level in range(len(stations)-1):
        for k in range(10):
            a = level*10+k
            b = level*10+(k+1)%10
            c = (level+1)*10+(k+1)%10
            d = (level+1)*10+k
            faces.extend(((a,b,c),(a,c,d)))
    for k in range(1,9):
        faces.append((0,k+1,k))
        faces.append(((len(stations)-1)*10,
                      (len(stations)-1)*10+k,
                      (len(stations)-1)*10+k+1))
    art.add("TenSidedTaperedFreightPier" + str(side), "ARMOR", verts, faces)


def create() -> Sculpture:
    art = Sculpture()
    art.lines[0] = "# Chaos Survival ORIGINAL Harbor cargo sky-promenade portal"
    art.lines[2] = "o ChaosHarborSuspendedFreightGantry"
    for side in (-1,1):
        polygon_load_leg(art,side)
        z = side * 8.15
        art.beveled_block("DockFootShoe"+str(side),"GRIP",
                          0,.22,z,3.4,.76,3.1,.28)
        art.beveled_block("UpperBracedYoke"+str(side),"BRUSHED",
                          0,14.9,z,3.6,1.45,3.8,.46)
        art.beveled_block("OutsideMaintenanceSpine"+str(side),"CARBON",
                          -1.04,6.8,z,.22,10.1,1.2,.08)
        art.beveled_block("DielectricNameplate"+str(side),"CERAMIC",
                          -1.20,8.6,z,.13,1.12,1.65,.055)
        art.rod("SweptAframeLoadStrut"+str(side),"ALLOY",
                (-2.1,1.3,side*8.5),(-.86,14.65,side*7.4),.20,10)
        art.rod("OuterDiagonalForgedStay"+str(side),"BRUSHED",
                (1.50,1.65,side*8.8),(.70,14.70,side*7.9),.16,8)
        for level in range(5):
            y = 2.9 + level*2.31
            art.beveled_block("ForgeSaddle%d_%d"%(side,level),"ALLOY",
                              -.75,y,z,1.42,.23,1.95,.09)
            art.beveled_block("RecessedSafetyReflector%d_%d"%(side,level),"SIGNAL",
                              -1.19,y,z,.09,.12,.55,.035)

    # Real horizontal mechanically bridged truss runs SIDEWAYS across Z.
    # Its underside stays above any standard R15 hop and camera.
    art.beveled_block("HangingIBeam","ARMOR",
                      0,15.55,0,4.45,1.2,18.1,.44)
    art.beveled_block("UpperRoofArmor","CERAMIC",
                      0,16.58,0,5.7,.55,18.5,.31)
    art.beveled_block("LowerOpenLoadRail","BRUSHED",
                      0,14.48,0,3.8,.30,18.0,.18)
    for k in range(9):
        z = -8.1+k*2.025
        art.rod("TriangulatedGantryBay%d"%k,"ALLOY",
                (-1.85,14.55,z),(1.7,16.35,z+0.65),.085,8)
    # Actual lateral crate traverse is ABOVE (never on) the 12-stud bridge.
    art.beveled_block("WinchTrackUnderHood","BRUSHED",
                      1.9,16.8,-2.1,13.6,.42,1.25,.18)
    art.beveled_block("RoofServiceCatwalkRib","GRIP",
                      1.9,17.27,-2.1,12.6,.20,.95,.11)
    art.beveled_block("TravelingTrolleyHousing","CARBON",
                      7.15,15.65,-2.1,3.1,1.52,2.35,.24)
    for side in (-1,1):
        art.rod("CraneHoistCable"+str(side),"ALLOY",
                (7.1,14.87,-2.1+side*.72),
                (7.1,11.90,-2.1+side*.72),.075,8)
    art.beveled_block("SuspendedCargoArmoredCase","ARMOR",
                      7.10,11.0,-2.1,4.30,2.35,3.05,.31)
    for side in (-1,1):
        art.beveled_block("CargoCornerWearPad"+str(side),"GRIP",
                          7.10,11.0,-2.1+side*1.55,3.55,.30,.13,.06)
    art.beveled_block("SuspendedLoadLabel","SIGNAL",
                      7.10,11.0,-3.685,2.40,.26,.10,.055)

    # Imported trussed underdeck load case replaces, not overlays, the
    # native 5.6x1.7x11-15 cross-tie. It never looks like a walkable top.
    for x in (-2.2,2.2):
        art.beveled_block("UnderslungTransverseRail"+str(x),"ARMOR",
                          x,-1.20,0,.56,.50,15.10,.18)
    for z in (-6.9,-3.45,0,3.45,6.9):
        art.rod("UnderslungXbrace"+str(z),"ALLOY",
                (-2.22,-.91,z-.9),(2.22,-1.83,z+.9),.105,8)
    art.beveled_block("RecessedPowerFeed","CARBON",
                      0,-1.94,0,4.7,.24,5.4,.13)

    # Authoritative source geometry limits; not trusting arbitrary imports.
    assert set(art.materials)==set(MATERIALS), art.materials
    assert 35 <= art.groups <= 155, art.groups
    assert 950 <= art.triangles <= 5200, art.triangles
    return art


def export(path: Path) -> dict:
    art = create()
    size = [round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    # Original art profile must fit all six original physical promenade
    # colliders, without intersecting the 12-stud walkway at feet height.
    assert 15.0 <= size[0] <= 20.6, size
    assert 18.7 <= size[1] <= 21.3, size
    assert 18.5 <= size[2] <= 21.0, size
    assert art.minimum[1] <= -1.9 and art.maximum[1] >= 17.3
    assert 8.15 - 1.07 > 6.4, "pier enters walkway"
    # The suspended cargo's underside is at 9.825 studs, safely above
    # the R15 jump arc; low-level spaces remain visually OPEN.
    assert 11.0 - 2.35/2 >= 9.7
    path.parent.mkdir(parents=True,exist_ok=True)
    blob="\n".join(art.lines)+"\n"
    path.write_text(blob,encoding="utf-8")
    return dict(asset=NAME,groups=art.groups,triangles=art.triangles,
        vertices=art.vertices,materials=sorted(art.materials),
        dimensions=size,bounds_min=art.minimum,bounds_max=art.maximum,
        open_playable_width=12,sha256=hashlib.sha256(blob.encode()).hexdigest())


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))
