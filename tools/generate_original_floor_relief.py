#!/usr/bin/env python3
"""Six original shallow, physically triangulated machinist floor modules.

A shared Low-tier six-place service plate plus five distinct arena signatures.
All surfaces are cosmetic BELOW the existing hazard-warning layers; no Roblox
collision, touch, query, event script, decal, or unrelated asset is authored.
Each choice exports UV/tangent-ready OBJ with seven verified materials.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

KINDS = (
    "relief_essential", "relief_classic", "relief_towers",
    "relief_crossroads", "relief_orbital", "relief_harbor",
)


def frame(m, name, length, width, material="ARMOR"):
    # Lightweight layered relief. Nothing projects more than 0.19 studs
    # above the bottom face; the client fits the TOP under warning overlays.
    m.beveled_block(name+"MachinedBase",material,0,0,0,
                    length,.12,width,.18)
    m.beveled_block(name+"CarbonTrench","CARBON",0,.067,0,
                    length*.79,.022,width*.73,.07)
    m.beveled_block(name+"LoadBearingCore","CERAMIC",0,.089,0,
                    length*.66,.038,width*.55,.08)


def bolt(m,name,x,z):
    # Eight-sided tiny retaining heads, no fake Part cylinder.
    m.rod(name,"BRUSHED",(x,.09,z),(x,.155,z),.052,8)


def essential(m):
    frame(m,"UniversalSixWay",8.8,3.08)
    for side in (-1,1):
        m.beveled_block("AnchorSaddle_%d"%side,"ALLOY",
                        side*3.41,.12,0,1.04,.055,2.25,.18)
        for z in (-.87,.87):
            bolt(m,"SaddleBolts%d_%d"%(side,int(z*100)),side*3.43,z)
    for i in range(6):
        m.beveled_block("CentralTractionTooth%d"%i,"GRIP",
                        -2.36+i*.92,.143,.32,.34,.052,.45,.045)
    m.beveled_block("RecessedStatusBand","SIGNAL",
                    0,.115,-.93,3.0,.028,.105,.015)


def classic(m):
    frame(m,"ArmoredServiceHatch",8.00,4.34)
    for side in (-1,1):
        m.beveled_block("PressureLockHinge%d"%side,"BRUSHED",
                        side*3.13,.14,.07,.42,.072,1.55,.13)
        for z in (-1.24,1.24):
            bolt(m,"HatchRivet%d_%d"%(side,int(z*100)),side*3.38,z)
    for i in range(5):
        m.beveled_block("PassiveDrainVent%d"%i,"GRIP",
                        -2.2+i*1.10,.14,-.47,.55,.055,.22,.043)
        m.beveled_block("HatchWeatherSeal%d"%i,"ALLOY",
                        -2.2+i*1.10,.131,.97,.34,.046,.38,.043)
    m.beveled_block("HatchSurveyNotch","SIGNAL",0,.138,1.32,1.42,.033,.12,.013)


def towers(m):
    # Narrow cast interlock rib: visible faceted longitudinal extrusions.
    frame(m,"TowerExpansionRail",10.22,.94,"ALLOY")
    for side in (-1,1):
        m.beveled_block("RidgePressureLand%d"%side,"ARMOR",
                        side*4.33,.139,0,.72,.065,.65,.09)
        bolt(m,"RailCornerLock%d"%side,side*4.55,0)
    for i in range(9):
        m.beveled_block("ForgedRailShoe%d"%i,"GRIP",
                        -4.08+i*1.02,.142,0,.36,.08,.78,.06)
    m.beveled_block("CapillaryServiceReadout","SIGNAL",
                    0,.177,0,2.4,.023,.115,.02)
    for side in (-1,1):
        m.rod("OuterTensionPin%d"%side,"BRUSHED",
              (side*2.92,.17,-.26),(side*2.92,.17,.26),.032,8)


def crossroads(m):
    frame(m,"StreetTactileInterlock",3.50,.66)
    for i in range(5):
        x=-1.19+i*.59
        m.beveled_block("RoadGripCrossHatch%d"%i,"GRIP",
                        x,.14,0,.32,.073,.48,.036)
    for side in (-1,1):
        m.beveled_block("EdgeHighFrictionPad%d"%side,"BRUSHED",
                        side*1.49,.138,0,.23,.033,.58,.031)
        bolt(m,"TactilePin%d"%side,side*1.48,0)
    m.beveled_block("NonWarningLaneDatum","SIGNAL",
                    0,.16,0,.75,.025,.095,.018)
    m.beveled_block("DovetailRail","ALLOY",
                    0,-.072,0,2.5,.09,.40,.044)
    m.beveled_block("LateralReturnNotch","ALLOY",
                    0,.092,.21,1.10,.021,.09,.018)


def orbital(m):
    frame(m,"OrbitalMagneticTrack",5.42,1.08,"CERAMIC")
    m.beveled_block("MagnetInsulatingArmor","ARMOR",
                    0,.118,0,4.6,.041,.57,.07)
    for side in (-1,1):
        m.beveled_block("DielectricGuide%d"%side,"ALLOY",
                        0,.119,side*.37,4.60,.067,.15,.032)
        for x in (-2.09,2.09):
            bolt(m,"MagnetGuardBolt%d_%d"%(side,int(x*100)),x,side*.30)
    for k in range(7):
        m.beveled_block("SegmentedFluxShield%d"%k,"GRIP",
                        -2.18+k*.73,.151,0,.39,.066,.36,.066)
    m.beveled_block("FluxDiagnosticTrace","SIGNAL",
                    0,.157,0,2.85,.025,.11,.019)
    m.rod("EndResonator","BRUSHED",(-2.29,.16,0),(-2.1,.16,0),.05,8)


def harbor(m):
    frame(m,"DockForgedTieDown",7.55,2.74,"ARMOR")
    for side in (-1,1):
        m.beveled_block("DockCastCleat%d"%side,"BRUSHED",
                        side*2.62,.15,0,1.10,.077,1.83,.19)
        m.beveled_block("SaltWeatherGuard%d"%side,"GRIP",
                        side*3.25,.11,0,.37,.048,2.05,.07)
        for z in (-.82,.82):
            bolt(m,"DockAnchor%d_%d"%(side,int(z*100)),side*3.05,z)
    for k in range(6):
        m.beveled_block("TimberAndSteelGroove%d"%k,"CARBON",
                        -1.95+k*.78,.134,.34,.25,.035,1.06,.034)
    m.beveled_block("BerthReadoutInset","SIGNAL",
                    0,.13,-.87,1.95,.022,.15,.025)
    m.rod("CastLoadRoller","ALLOY",(-1.25,.18,1.07),
          (1.25,.18,1.07),.08,12)


BUILD = {
    "relief_essential":essential,
    "relief_classic":classic,
    "relief_towers":towers,
    "relief_crossroads":crossroads,
    "relief_orbital":orbital,
    "relief_harbor":harbor,
}


def export(kind: str, output: Path) -> dict:
    if kind not in BUILD:
        raise ValueError("Unregistered floor machinery source")
    art = Sculpture()
    art.lines[0] = "# Original shallow 3D machinist floor: "+kind
    art.lines[2] = "o ChaosOriginal_"+kind
    BUILD[kind](art)
    dimensions = [
        round(art.maximum[i]-art.minimum[i],5) for i in range(3)
    ]
    if not (180 <= art.triangles <= 2600 and 15 <= art.groups <= 160):
        raise ValueError("Floor sculpture exceeds triangle/group budget: "
                         + str((art.triangles,art.groups)))
    if art.materials != set(MATERIALS):
        raise ValueError("All seven original material groups are required")
    if not (.08 <= dimensions[1] <= .38
            and .5 <= dimensions[2] <= 5
            and 3 <= dimensions[0] <= 11):
        raise ValueError("Unsafe source floor bounds: "+str(dimensions))
    output.parent.mkdir(parents=True,exist_ok=True)
    data = "\n".join(art.lines)+"\n"
    output.write_text(data,encoding="utf-8")
    return {
        "asset":kind,"triangles":art.triangles,
        "groups":art.groups,"vertices":art.vertices,
        "materials":sorted(art.materials),
        "dimensions":dimensions,
        "bounds_min":art.minimum,"bounds_max":art.maximum,
        "sha256":hashlib.sha256(data.encode()).hexdigest(),
    }


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--model",required=True,choices=KINDS)
    parser.add_argument("--output",required=True,type=Path)
    opts=parser.parse_args()
    print(json.dumps(export(opts.model,opts.output),sort_keys=True))
