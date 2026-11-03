#!/usr/bin/env python3
"""Five genuinely triangulated, owner-authored premium service machines.

No Roblox Part-based imitation and no invented Model/MeshId. Generates one
small, purpose-built OBJ with 7 glTF-compatible materials per invocation.
Roblox upload/moderation must succeed before runtime integration.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

KINDS = ("service_camera", "service_maintenance", "service_wayfinder",
         "service_orbital", "service_mooring")


def common(m):
    # Different colored machining strata, a grounded service base,
    # inset bolts, and visible drain channels shared across the art set.
    m.beveled_block("CastServiceFoot", "ARMOR", 0, .12, 0, 1.55, .24, 1.25, .13)
    m.beveled_block("UnderbodyCarbonRecess", "CARBON",
                    0, .29, 0, 1.20, .12, .88, .11)
    for x in (-.59, .59):
        for z in (-.43, .43):
            m.rod("FootBolt_%s_%s" % (x, z), "BRUSHED",
                  (x, .24, z), (x, .41, z), .065, 8)


def camera(m):
    common(m)
    m.beveled_block("TripodCentralHydraulic", "ALLOY",
                    0, 1.11, 0, .40, 1.75, .42, .15)
    for side in (-1, 1):
        m.rod("SplayedOpticSupport%s" % side, "BRUSHED",
              (side*.59, .37, .27), (side*.20, 1.87, 0), .095, 8)
        m.beveled_block("GimbalCheek%s" % side, "CERAMIC",
                        side*.91, 2.43, -.12, .15, .91, 1.15, .07)
    m.rod("AzimuthGimbal", "GRIP", (-1, 2.44, -.12), (1, 2.44, -.12), .12, 12)
    m.beveled_block("CameraArmoredTaper", "ARMOR",
                    0, 2.54, -.14, 1.75, .83, 1.35, .22)
    m.beveled_block("OpticalFrontSeal", "CARBON",
                    0, 2.56, -.86, 1.27, .64, .10, .06)
    for x in (-.37, .37):
        m.rod("DualProtectedLens%s" % x, "SIGNAL",
              (x, 2.56, -.92), (x, 2.56, -1.00), .18, 16)
    for k in range(4):
        m.beveled_block("HeatSinkChannel%d" % k, "BRUSHED",
                        -.55+k*.36, 3.01, .27, .14, .22, .61, .05)
    m.rod("AntennaAft", "ALLOY", (.48, 2.93, .40),
          (.48, 3.71, .44), .04, 8)


def maintenance(m):
    common(m)
    # A separate stepped cast case with physically cut horizontal relief.
    m.beveled_block("CargoEquipmentCase", "ARMOR",
                    0, 1.32, .02, 2.86, 1.86, 2.24, .36)
    m.beveled_block("RecessedServiceDoor", "CARBON",
                    0, 1.36, -1.13, 2.26, 1.24, .13, .16)
    for x in (-1.25, 1.25):
        m.rod("RetainedDoorEdge%s" % x, "BRUSHED",
              (x, .69, -1.2), (x, 2.12, -1.2), .065, 8)
    for k in range(4):
        m.beveled_block("VentGrille%d" % k, "GRIP",
                        -.93+k*.61, 2.29, .39, .31, .06, 1.0, .05)
    m.beveled_block("ProtectedLockHousing", "CERAMIC",
                    .78, 1.28, -1.27, .48, .53, .21, .10)
    m.rod("LockActuator", "ALLOY",
          (.78, 1.18, -1.40), (.78, 1.48, -1.40), .10, 10)
    for side in (-1, 1):
        m.beveled_block("SideGrip%s" % side, "BRUSHED",
                        side*1.49, 1.50, .08, .10, .38, 1.15, .06)
        m.beveled_block("InsetWearPlate%s" % side, "GRIP",
                        side*.82, .31, .68, .42, .10, .55, .08)
    m.beveled_block("ServiceStatusInset", "SIGNAL",
                    -.57, 1.71, -1.275, .46, .09, .025, .01)


def wayfinder(m):
    common(m)
    m.beveled_block("RoadSentinelCore", "ARMOR",
                    0, 1.20, 0, .96, 1.88, .92, .22)
    for side in (-1, 1):
        m.beveled_block("ArmoredEdgeFlange%s" % side, "BRUSHED",
                        side*.52, 1.17, 0, .19, 1.65, 1.10, .08)
    m.beveled_block("DirectionalOpticsHead", "CERAMIC",
                    0, 2.36, -.09, 1.62, .47, 1.25, .14)
    for k in range(3):
        m.beveled_block("SignalChevron%d" % k, "SIGNAL",
                        -.37+k*.37, 1.57-k*.24, -.51,
                        .25, .14, .06, .05)
    for k in range(3):
        m.beveled_block("UpperRadiatorFin%d" % k, "GRIP",
                        -.49+k*.49, 2.72, .18, .28, .18, .69, .04)
    for x in (-.32, .32):
        m.rod("VehicleDetectionProbe%s" % x, "ALLOY",
              (x, 2.73, .30), (x, 3.13, .30), .07, 8)


def orbital(m):
    common(m)
    m.beveled_block("CeramicMagneticContainment", "CERAMIC",
                    0, 1.52, 0, 1.60, 2.32, 1.55, .26)
    for side in (-1, 1):
        m.beveled_block("CoolingFin%s" % side, "ARMOR",
                        side*.98, 1.60, 0, .30, 1.84, 1.38, .13)
        m.rod("EnergyTransferRail%s" % side, "ALLOY",
              (side*.91, .50, -.49), (side*.91, 2.60, -.49), .085, 10)
    for level in (.59, 1.59, 2.49):
        for side in (-1, 1):
            m.beveled_block("SecuredPowerRing_%s_%s" % (level, side),
                            "BRUSHED", 0, level, side*.77,
                            1.97, .19, .23, .08)
    m.beveled_block("ReactorWindow", "SIGNAL",
                    0, 1.76, -.81, .55, .80, .08, .09)
    for k in range(6):
        a = k*math.tau/6
        x, z = .66*math.cos(a), .66*math.sin(a)
        m.rod("HelicalFluxLink%d" % k, "GRIP",
              (x, .66, z), (x*.90, 2.55, z*.90), .075, 8)
    m.beveled_block("CapacitorUpperLock", "CARBON",
                    0, 2.84, 0, 1.25, .30, 1.18, .13)


def mooring(m):
    common(m)
    m.beveled_block("PierIronFooting", "ARMOR",
                    0, .27, 0, 3.30, .32, 2.48, .22)
    for x in (-1.23, 1.23):
        for z in (-.84, .84):
            m.rod("PierAnchor%s_%s" % (x, z), "BRUSHED",
                  (x, .36, z), (x, .54, z), .10, 8)
    for x in (-.88, .88):
        m.rod("BollardCastColumn%s" % x, "ALLOY",
              (x, .48, 0), (x, 1.48, 0), .35, 14)
        m.beveled_block("TaperedBollardCrown%s" % x, "CERAMIC",
                        x, 1.54, 0, .98, .31, .91, .16)
        m.beveled_block("RubbedBollardNeck%s" % x, "GRIP",
                        x, .98, 0, 1.0, .16, 1.06, .09)
    m.rod("MooringCapstanCrossbar", "BRUSHED",
          (-1.42, 1.51, 0), (1.42, 1.51, 0), .20, 14)
    for z in (-.65, .65):
        m.beveled_block("SaltGuardRib%s" % z, "CARBON",
                        0, .41, z, 2.3, .24, .14, .06)
    m.beveled_block("BerthIndicator", "SIGNAL",
                    0, .46, -1.25, .48, .08, .06, .04)


BUILDERS = {
    "service_camera": camera,
    "service_maintenance": maintenance,
    "service_wayfinder": wayfinder,
    "service_orbital": orbital,
    "service_mooring": mooring,
}


def export(kind: str, output: Path):
    if kind not in BUILDERS:
        raise ValueError("Unknown service model")
    art = Sculpture()
    art.lines[0] = "# Authored original industrial service geometry: " + kind
    art.lines[2] = "o ChaosOriginal_" + kind
    BUILDERS[kind](art)
    dimensions = [round(art.maximum[i] - art.minimum[i], 4) for i in range(3)]
    if not (240 <= art.triangles <= 4200 and 15 <= art.groups <= 128):
        raise ValueError("Service mesh triangle/group envelope failure")
    if set(art.materials) != set(MATERIALS):
        raise ValueError("Missing 7 original PBR materials")
    if min(dimensions) < .8 or max(dimensions) > 5:
        raise ValueError("Unexpected service geometry bounds")
    output.parent.mkdir(parents=True, exist_ok=True)
    source = "\n".join(art.lines) + "\n"
    output.write_text(source, encoding="utf-8")
    return {
        "asset": kind, "triangles": art.triangles, "groups": art.groups,
        "vertices": art.vertices, "materials": sorted(art.materials),
        "bounds_min": art.minimum, "bounds_max": art.maximum,
        "dimensions": dimensions,
        "sha256": hashlib.sha256(source.encode("utf-8")).hexdigest(),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", choices=KINDS, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(export(args.model, args.output), sort_keys=True))


if __name__ == "__main__":
    main()
