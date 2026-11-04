#!/usr/bin/env python3
"""Original sculpted 3D load-bearing faces for Chaos Survival platforms.

Five arena-specific open-bottom carapaces plus a repeatable bridge edge girder.
Collision, bridge shutters, danger decals and navigation remain Roblox-server
owned. The imported meshes are ART only, with all seven original industrial
materials and deterministic UV/tangent-ready glTF export.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

KINDS = (
    "deck_carapace_classic", "deck_carapace_towers",
    "deck_carapace_crossroads", "deck_carapace_orbital",
    "deck_carapace_harbor", "bridge_side_girder",
)


def skirt(m: Sculpture, side: int) -> None:
    """Triangulated true sloped, structural skirt with finite thickness."""
    z = 4.18 * side
    inner_z = 3.52 * side
    points = [
        (-5.52, -.15, z), (5.52, -.15, z),
        (5.52, -1.16, inner_z), (-5.52, -1.16, inner_z),
        (-5.52, -.28, z - side * .10),
        (5.52, -.28, z - side * .10),
        (5.52, -1.33, inner_z - side * .10),
        (-5.52, -1.33, inner_z - side * .10),
    ]
    faces = [(0,1,2),(0,2,3),(4,6,5),(4,7,6),
             (0,4,5),(0,5,1),(1,5,6),(1,6,2),
             (2,6,7),(2,7,3),(3,7,4),(3,4,0)]
    if side < 0:
        faces = [(a,c,b) for a,b,c in faces]
    m.add("TaperedForgedSideSkirt%d" % side,"ARMOR",points,faces)


def common_deck(m: Sculpture) -> None:
    for side in (-1, 1):
        skirt(m, side)
        # No surfaces exceed the original 11.5 x 8.7 deck footprint.
        m.beveled_block("TopEdgeCaptiveRail%d"%side, "BRUSHED",
                        0, -.17, side*3.92, 10.8, .14, .23, .065)
        m.beveled_block("CeramicImpactGuard%d"%side, "CERAMIC",
                        0, -.51, side*3.95, 9.30, .31, .12, .06)
        m.beveled_block("ServiceBayDarkRecess%d"%side, "CARBON",
                        0, -.98, side*3.66, 8.66, .12, .24, .04)
    m.beveled_block("CentralOpenUnderkeel","ALLOY",
                    0,-2.04,0,7.05,.62,3.44,.28)
    for side in (-1,1):
        for i in range(3):
            x = -3.35+i*3.32
            m.rod("AngledWeightStrut_%d_%d"%(side,i),"BRUSHED",
                  (x,-.91,side*3.40),
                  (x*.76,-2.02,side*.94),.087,10)
    for i in range(6):
        m.beveled_block("UndersideTractionRib%d"%i,"GRIP",
                        -4.32+i*1.73,-2.41,0,.32,.15,2.75,.06)
    m.beveled_block("InboardMaintenanceMarker","SIGNAL",
                    0,-.26,4.00,2.26,.07,.095,.02)


def classic(m: Sculpture) -> None:
    common_deck(m)
    for side in (-1,1):
        for i in range(5):
            x=-4.2+i*2.08
            m.beveled_block("MachinedPressureVent%d_%d"%(side,i),
                            "CARBON",x,-.67,side*4.02,1.1,.14,.09,.035)
            m.rod("ForgedCaptiveRivet%d_%d"%(side,i),"ALLOY",
                  (x,-.37,side*4.12),(x,-.27,side*4.12),.065,8)
    m.beveled_block("ClassicCentralPressureStamp","CERAMIC",
                    0,-2.45,0,2.8,.12,1.32,.07)


def towers(m: Sculpture) -> None:
    common_deck(m)
    for side in (-1,1):
        for i in range(4):
            x=-4.0+i*2.65
            m.beveled_block("TowerVerticalGuideShoe%d_%d"%(side,i),
                            "ALLOY",x,-.72,side*3.90,.38,1.1,.33,.085)
            m.rod("TowerLiftRetainer%d_%d"%(side,i),"BRUSHED",
                  (x,-.33,side*3.96),(x,-1.28,side*3.71),.095,8)
        m.beveled_block("TowersSectorInsulator%d"%side,
                        "GRIP",0,-1.17,side*3.43,2.75,.18,.44,.04)
    m.beveled_block("TowerUndersideDamper","CARBON",
                    0,-2.49,0,4.2,.25,2.9,.13)


def crossroads(m: Sculpture) -> None:
    common_deck(m)
    for side in (-1,1):
        for i in range(5):
            x = -4.4+i*2.19
            m.beveled_block("TrafficCrashCassette%d_%d"%(side,i),
                            "ALLOY",x,-.75,side*4.02,1.32,.23,.19,.065)
            m.beveled_block("LaminarRoadShockPad%d_%d"%(side,i),
                            "GRIP",x,-1.07,side*3.73,1.02,.16,.31,.075)
    m.beveled_block("CrossroadMechanicalSwitchCase","CERAMIC",
                    0,-2.49,0,3.10,.15,1.05,.1)


def orbital(m: Sculpture) -> None:
    common_deck(m)
    for side in (-1,1):
        for i in range(4):
            x=-4.1+i*2.72
            m.beveled_block("FluxShieldedFieldCell%d_%d"%(side,i),
                            "CERAMIC",x,-.63,side*3.99,1.50,.33,.23,.07)
            m.rod("SuperconductiveManifold%d_%d"%(side,i),
                  "ALLOY",(x-.50,-1.24,side*3.59),
                  (x+.50,-1.24,side*3.59),.072,10)
    m.beveled_block("DielectricCoreHeatSink","BRUSHED",
                    0,-2.48,0,4.44,.19,2.2,.09)


def harbor(m: Sculpture) -> None:
    common_deck(m)
    for side in (-1,1):
        for i in range(4):
            x=-4.12+i*2.72
            m.beveled_block("RivetedDockCrossbar%d_%d"%(side,i),
                            "BRUSHED",x,-.69,side*4.03,1.38,.25,.24,.08)
            m.rod("WeatherResistantStay%d_%d"%(side,i),
                  "ALLOY",(x-.42,-.47,side*3.92),
                  (x+.42,-1.36,side*3.49),.075,8)
        m.beveled_block("TimberCompositeSplashBarrier%d"%side,
                        "GRIP",0,-1.38,side*3.55,8.9,.22,.26,.075)
    m.beveled_block("UnderquayCargoReceiver","CARBON",
                    0,-2.50,0,4.04,.21,1.20,.09)


def bridge(m: Sculpture) -> None:
    # A compact 9.8-stud *side-only* girder. Repeat sparingly on two real
    # skybridge side faces; no top rail that could imply a walkable edge.
    m.beveled_block("SawtoothCappedStructuralSide","ARMOR",
                    0,-.25,0,9.62,.39,.55,.13)
    m.beveled_block("InnerCarbonDampingStrip","CARBON",
                    0,-.54,0,8.82,.22,.34,.10)
    m.beveled_block("LowerLoadSpine","ALLOY",
                    0,-1.35,0,9.18,.42,.34,.12)
    for side in (-1,1):
        m.beveled_block("SideWearCap%d"%side,"CERAMIC",
                        side*4.48,-.34,0,.52,.56,.49,.10)
        for k in range(4):
            x=-3.40+k*2.26
            m.rod("TrussWeb%d_%d"%(side,k),"BRUSHED",
                  (x+side*.46,-.37,0),(x,-1.27,0),.077,10)
            m.beveled_block("ServiceCutoutMarker%d_%d"%(side,k),
                            "GRIP",x,-.79,side*.18,.66,.14,.095,.03)
    m.beveled_block("ServiceGaugeEmbedded","SIGNAL",
                    0,-.25,.30,2.34,.05,.085,.018)


BUILD = {
    "deck_carapace_classic":classic,
    "deck_carapace_towers":towers,
    "deck_carapace_crossroads":crossroads,
    "deck_carapace_orbital":orbital,
    "deck_carapace_harbor":harbor,
    "bridge_side_girder":bridge,
}


def export(kind: str, output: Path) -> dict:
    if kind not in BUILD:
        raise ValueError("Unexpected sculpted 3D model choice")
    art = Sculpture()
    art.lines[0] = "# Chaos original 3D suspended platform assembly: " + kind
    art.lines[2] = "o ChaosOriginal_" + kind
    BUILD[kind](art)
    dims = [round(art.maximum[i] - art.minimum[i], 5) for i in range(3)]
    if art.materials != set(MATERIALS):
        raise ValueError("Seven real UV-authored industrial material groups required")
    if not (18 <= art.groups <= 145 and 350 <= art.triangles <= 5000):
        raise ValueError("Platform/bridge structure incomplete or too heavy")
    if kind == "bridge_side_girder":
        accepted = (9.3 <= dims[0] <= 10.6
                    and 1.3 <= dims[1] <= 2.3
                    and .5 <= dims[2] <= 1.3)
    else:
        accepted = (10.8 <= dims[0] <= 12.0
                    and 2.1 <= dims[1] <= 3.5
                    and 8.1 <= dims[2] <= 9.1)
    if not accepted:
        raise ValueError("Unsafe open-underside silhouette " + str((kind,dims)))
    output.parent.mkdir(parents=True, exist_ok=True)
    data = "\n".join(art.lines) + "\n"
    output.write_text(data, encoding="utf-8")
    return {
        "asset":kind, "triangles":art.triangles,
        "groups":art.groups, "vertices":art.vertices,
        "materials":sorted(art.materials),
        "dimensions":dims, "bounds_min":art.minimum,
        "bounds_max":art.maximum,
        "sha256":hashlib.sha256(data.encode()).hexdigest(),
    }


if __name__ == "__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--model",choices=KINDS,required=True)
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    print(json.dumps(export(args.model,args.output),sort_keys=True))
