#!/usr/bin/env python3
"""Original moving 3D ambient machines for all five Chaos Survival worlds.

Only fixed deterministic geometry; no marketplace meshes, arbitrary payloads,
hidden scripts or Roblox runtime Part assemblies. Source is triangulated UV-
ready OBJ and importer-created glTF with seven original industrial materials.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

KINDS = (
    "ambient_drone", "ambient_lift", "ambient_transit",
    "ambient_satellite", "ambient_cargo",
)


def drone(m: Sculpture):
    # Aerodynamically faceted broadcaster; does NOT look like a crate.
    m.loft("TiltedBroadcastMonocoque", "ARMOR", [
        (-1.45, .46, .22, 0), (-.94, 1.48, .39, 0),
        (.64, 1.36, .38, 0), (1.42, .30, .16, .03),
    ])
    m.beveled_block("CarbonCameraBelly", "CARBON",
                    0, -.41, -.10, 1.28, .19, 1.12, .12)
    m.beveled_block("DualGlassOptics", "SIGNAL",
                    0, .14, -1.52, .87, .18, .08, .04)
    for side in (-1, 1):
        m.rod("OutboardTitaniumArm%s" % side, "BRUSHED",
              (side*.55, 0, -.45), (side*1.72, .11, -.40), .13, 10)
        m.beveled_block("RotorShroud%s" % side, "CERAMIC",
                        side*1.67, .12, -.42, .98, .16, 1.12, .23)
        m.rod("MotorSpindle%s" % side, "ALLOY",
              (side*1.67, -.29, -.42), (side*1.67, .47, -.42), .10, 12)
        m.beveled_block("CarbonRotorBaffle%s" % side, "GRIP",
                        side*1.67, .30, -.42, .65, .055, .83, .12)
        m.beveled_block("PositioningSignal%s" % side, "SIGNAL",
                        side*2.12, -.02, .18, .19, .08, .23, .04)
    m.rod("BroadbandAntenna", "BRUSHED",
          (0, .36, .62), (0, 1.25, .69), .035, 8)
    for k in range(4):
        m.beveled_block("PassiveChassisFin%d" % k, "ALLOY",
                        -.58+k*.38, -.29, .55, .13, .21, .51, .05)


def lift(m: Sculpture):
    # Real vertical cabin with layered windows, cable stay, landing sockets.
    m.beveled_block("LiftCeramicSkin", "ARMOR",
                    0, 0, 0, 2.35, 4.55, 2.35, .31)
    m.beveled_block("RecessedPassengerGlass", "CARBON",
                    0, .44, -1.19, 1.45, 2.17, .11, .08)
    m.beveled_block("InnerPassengerReflection", "SIGNAL",
                    0, .38, -1.264, .84, 1.49, .02, .01)
    m.beveled_block("ReinforcedCabinDoor", "CERAMIC",
                    0, -1.09, -1.18, 1.23, .62, .09, .05)
    m.beveled_block("CabinBellySkid", "GRIP",
                    0, -2.26, 0, 2.1, .32, 2.02, .21)
    m.beveled_block("OverheadDriveBlock", "BRUSHED",
                    0, 2.36, 0, 1.49, .34, 1.52, .16)
    for side in (-1, 1):
        m.rod("VerticalLiftCarrier%s" % side, "BRUSHED",
              (side*1.01, -2.22, .91),
              (side*1.01, 2.24, .91), .10, 10)
        m.beveled_block("EmergencyIndicator%s" % side, "SIGNAL",
                        side*.8, 1.82, -1.20, .21, .11, .07, .03)
        m.beveled_block("SideAccessGrille%s" % side, "ALLOY",
                        side*1.19, -.34, .45, .075, 2.0, .9, .04)
    for k in range(4):
        m.beveled_block("RoofCoolingSlot%d" % k, "CARBON",
                        -.61+k*.4, 2.56, .13, .18, .05, .92, .025)
    for k in range(3):
        m.beveled_block("LowerLandingIndex%d" % k, "ALLOY",
                        -.65+k*.65, -2.31, -1.01, .29, .15, .14, .035)


def transit(m: Sculpture):
    # Directional floating transit beacon, NOT a cube or painted lane.
    m.beveled_block("TransitRadialHull", "ARMOR",
                    0, 0, 0, 3.32, .73, .89, .25)
    m.beveled_block("CarbonTransponderSlit", "CARBON",
                    0, .03, -.46, 2.32, .23, .10, .04)
    m.beveled_block("FrostedSignalPlate", "SIGNAL",
                    .15, .18, -.51, 1.58, .13, .07, .04)
    m.beveled_block("ControllerUndercarriage", "GRIP",
                    0, -.44, 0, 2.72, .15, .63, .07)
    for side in (-1, 1):
        m.beveled_block("AeroEndcap%s" % side, "CERAMIC",
                        side*1.53, .05, 0, .29, .65, 1.06, .12)
        m.rod("GuidePin%s" % side, "ALLOY",
              (side*1.30, -.49, 0), (side*1.30, -.70, 0), .055, 8)
    for k in range(5):
        m.beveled_block("IndexNotch%d" % k, "BRUSHED",
                        -1.10+k*.54, .40, .05, .17, .13, .48, .04)
    for k in range(3):
        m.beveled_block("PassiveHeatSink%d" % k, "GRIP",
                        -.62+k*.62, -.16, .55, .36, .24, .12, .05)
    for k in range(3):
        m.rod("DirectionalSamplingProbe%d" % k, "ALLOY",
              (-.62+k*.62, .44, .32), (-.62+k*.62, .67, .43),
              .037, 8)


def satellite(m: Sculpture):
    # Trussed directional micro-satellite with sensor head, radiation fins,
    # telescoping arms and dished optics rather than Roblox's sphere.
    m.beveled_block("SatelliteArmoredCore", "ARMOR",
                    0, 0, 0, 1.47, 1.43, 1.47, .24)
    m.beveled_block("StarTrackerLens", "SIGNAL",
                    0, .07, -.78, .55, .51, .10, .06)
    m.beveled_block("PowerRegulator", "CARBON",
                    0, -.79, .18, .96, .25, .83, .09)
    for side in (-1, 1):
        m.rod("CarbonTruss%s" % side, "BRUSHED",
              (side*.65, 0, 0), (side*1.45, 0, 0), .065, 8)
        m.beveled_block("SolarAssembly%s" % side, "ALLOY",
                        side*1.70, 0, 0, .75, 1.03, .12, .08)
        m.beveled_block("AbsorberLattice%s" % side, "GRIP",
                        side*1.72, 0, -.075, .58, .87, .035, .03)
        m.beveled_block("ThermalSide%s" % side, "CERAMIC",
                        side*.71, .08, .53, .14, .77, .63, .06)
    for k in range(4):
        a=math.pi * .5 * k
        m.rod("DirectionalTracker%d" % k, "BRUSHED",
              (math.cos(a)*.49, .62, math.sin(a)*.49),
              (math.cos(a)*.78, 1.05, math.sin(a)*.78), .040, 8)
    m.beveled_block("PolarTelemetryChip", "SIGNAL",
                    0, 1.05, 0, .33, .08, .40, .03)
    for k in range(4):
        m.beveled_block("GyroReactionVent%d" % k, "BRUSHED",
                        -.47+k*.31, -.16, .76, .17, .31, .12, .04)


def cargo(m: Sculpture):
    # Industrial suspended load basket, four hard corners, forged upper
    # hoist eye and genuine rigging. Unlike an empty rectangular block.
    m.beveled_block("CargoBulkContainer", "ARMOR",
                    0, -.32, 0, 5.0, 2.20, 3.6, .34)
    m.beveled_block("TopLoadLid", "CERAMIC",
                    0, .82, 0, 5.12, .23, 3.72, .24)
    m.beveled_block("BlackRecessedDoor", "CARBON",
                    0, -.22, -1.82, 3.78, 1.59, .12, .13)
    m.beveled_block("HoistEye", "BRUSHED",
                    0, 1.82, .08, 1.35, .25, 1.06, .18)
    m.rod("HoistCrossBeam", "ALLOY",
          (-2.27, 1.34, 0), (2.27, 1.34, 0), .11, 12)
    for side in (-1, 1):
        m.rod("ForgedStayPort%s" % side, "BRUSHED",
              (side*2.30, .91, -.98), (side*.53, 1.84, 0), .10, 8)
        m.rod("ForgedStayAft%s" % side, "BRUSHED",
              (side*2.30, .91, .98), (side*.53, 1.84, 0), .10, 8)
        m.beveled_block("VerticalCastCorner%s" % side, "GRIP",
                        side*2.36, -.33, -1.51, .28, 2.15, .38, .07)
        m.beveled_block("EndProtectiveRidge%s" % side, "BRUSHED",
                        side*2.53, -.36, 0, .10, 2.15, 2.9, .05)
    for k in range(5):
        m.beveled_block("BulkheadTieRib%d" % k, "ALLOY",
                        -1.9+k*.95, -.29, 1.84, .21, 1.58, .095, .04)
    for k in range(3):
        m.beveled_block("LoadingPictogram%d" % k, "SIGNAL",
                        -1.06+k*1.03, .48, -1.906, .58, .12, .035, .01)
    m.beveled_block("MassDistributionBelly", "GRIP",
                    0, -1.47, .17, 4.22, .16, 2.82, .13)


BUILDERS = {
    "ambient_drone": drone, "ambient_lift": lift,
    "ambient_transit": transit, "ambient_satellite": satellite,
    "ambient_cargo": cargo,
}


def export(kind: str, output: Path):
    if kind not in BUILDERS:
        raise ValueError("Unknown original airborne machine")
    art=Sculpture()
    art.lines[0]="# Original source-authored animated world prop: "+kind
    art.lines[2]="o ChaosOriginal_"+kind
    BUILDERS[kind](art)
    dims=[round(art.maximum[i]-art.minimum[i],4) for i in range(3)]
    if not (250<=art.triangles<=5000 and 18<=art.groups<=130):
        raise ValueError("Mobile ambient mesh exceeds bounded triangle budget")
    if art.materials!=set(MATERIALS) or len(dims)!=3:
        raise ValueError("Missing original material family")
    if not (.55<=min(dims) and max(dims)<=6.0):
        raise ValueError("Unsafe animated prop dimensions")
    output.parent.mkdir(parents=True,exist_ok=True)
    content="\n".join(art.lines)+"\n"
    output.write_text(content,encoding="utf-8")
    return {"asset":kind,"triangles":art.triangles,"groups":art.groups,
        "vertices":art.vertices,"materials":sorted(art.materials),
        "bounds_min":art.minimum,"bounds_max":art.maximum,
        "dimensions":dims,
        "sha256":hashlib.sha256(content.encode()).hexdigest()}


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--model",required=True,choices=KINDS)
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.model,args.output),sort_keys=True))


if __name__ == "__main__":
    main()
