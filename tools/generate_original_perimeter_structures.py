#!/usr/bin/env python3
"""Two forged original non-colliding perimeter-station structural details.

Genuine triangulated source geometry with a seven-material PBR palette.
Only an approved moderated Roblox Model ID may enter the runtime allowlist.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture

PROFILES = {
    "perimeter_crossbrace": (9.1, .65, 1.25),
    "perimeter_generator_shield": (4.0, .55, 1.4),
}


def brace(art: Sculpture):
    # Open-load girder: two *separate* longitudinal rails, with actual gaps
    # across the web rather than a painted stripe on a block.
    for side in (-1, 1):
        art.beveled_block("ClosedForgedLongitudinalRail%s" % side, "ARMOR",
                          0, -.05, side*.415, 8.94, .43, .22, .065)
        art.beveled_block("InnerCarbonLoadGroove%s" % side, "CARBON",
                          0, .172, side*.415, 7.52, .045, .10, .018)
    for x in (-4.15, 4.15):
        art.beveled_block("MilledTerminalCoupler%s" % x, "BRUSHED",
                          x, 0, 0, .55, .54, 1.12, .08)
        art.rod("VerticalCaptiveLock%s" % x, "CERAMIC",
                (x, -.275, -.32), (x, .267, -.32), .070, 8)
    for index in range(7):
        x = -3.54 + index * 1.18
        art.rod("OpenTriangulatedWeb%d" % index, "ALLOY",
                (x-.40, .025, -.42), (x+.40, .025, .42), .078, 8)
        art.rod("OpposedTrussLink%d" % index, "GRIP",
                (x-.34, -.06, .42), (x+.34, -.06, -.42), .047, 8)
    for x in (-3.3, 0, 3.3):
        art.beveled_block("RecessedDiecastLoadCell%s" % x, "BRUSHED",
                          x, .185, 0, .47, .09, .60, .05)
    art.beveled_block("StructuralSafetyCode","SIGNAL",
                      0, .265, -.425, 1.85, .055, .075, .018)


def shield(art: Sculpture):
    # Two raised cross-rails leave a real channel for the rotor's center.
    for side in (-1, 1):
        art.beveled_block("GeneratorShockAbsorberRail%s" % side, "ARMOR",
                          0, -.035, side*.47, 3.86, .36, .26, .07)
        art.beveled_block("InnerUndertrayCarbonSocket%s" % side, "CARBON",
                          0, -.22, side*.47, 2.98, .045, .13, .03)
    for x in (-1.70, 1.70):
        art.beveled_block("ProtectedEndFork%s" % x, "BRUSHED",
                          x, .01, 0, .53, .49, 1.30, .085)
        art.rod("ArmoredShieldBolt%s" % x, "ALLOY",
                (x,-.25,.36),(x,.258,.36),.072,8)
    for index in range(5):
        x = -.99 + index*.495
        art.rod("ClosedDiagonalHeatBridge%d" % index, "ALLOY",
                (x-.14,-.005,-.48), (x+.14,.065,.48), .054, 8)
        art.rod("BackstressWeb%d" % index, "GRIP",
                (x-.10,-.06,.48),(x+.10,-.06,-.48),.041,8)
    for x in (-.86,.86):
        art.beveled_block("CeramicHeatDeflector%s" % x, "CERAMIC",
                          x,.230,0,.31,.075,.40,.05)
    art.beveled_block("ProtectedStatusWindow","SIGNAL",
                      0,.268,-.47,.69,.045,.09,.022)


def export(kind: str, output: Path):
    if kind not in PROFILES:
        raise ValueError("Unknown structural model")
    art=Sculpture()
    art.lines[0]="# Original Chaos Survival structural perimeter "+kind
    art.lines[2]="o ChaosOriginal_"+kind
    (brace if kind=="perimeter_crossbrace" else shield)(art)
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    target=PROFILES[kind]
    if set(art.materials)!=set(MATERIALS):
        raise ValueError("Missing one of seven original materials")
    if not (15<=art.groups<=80 and 400<=art.triangles<=3500):
        raise ValueError("Unexpected forged girder geometry envelope")
    for actual,bound in zip(dims,target):
        if actual < bound*.77 or actual > bound*1.02:
            raise ValueError("Model exceeds or undersizes target: %r" % dims)
    raw="\n".join(art.lines)+"\n"
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(raw,encoding="utf-8")
    return {
        "asset":kind, "triangles":art.triangles, "groups":art.groups,
        "vertices":art.vertices, "materials":sorted(art.materials),
        "dimensions":dims, "bounds_min":art.minimum,
        "bounds_max":art.maximum,
        "sha256":hashlib.sha256(raw.encode()).hexdigest(),
    }


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--model",choices=PROFILES,required=True)
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.model,args.output),sort_keys=True))

if __name__=="__main__":
    main()
