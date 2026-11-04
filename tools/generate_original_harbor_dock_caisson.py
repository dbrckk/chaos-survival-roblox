#!/usr/bin/env python3
"""Original, real 3D armored dock-caisson skin for Harbor's physical landings.

Open/nonwalkable cargo casement wraps the SIDES and UNDERSIDE of the
existing, authoritative square platform. Never claims an extra landing:
all top geometry remains BELOW the true Part's +1 stud walkable plane.
Seven forged material families, coherent loading-corner silhouette,
weathered vents, armor facets, recessed service machinery, true triangulation.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from generate_original_skyfleet_carrier import Sculpture, MATERIALS

NAME = "harbor_dock_caisson"


def create() -> Sculpture:
    art = Sculpture()
    art.lines[0] = "# Chaos original industrial Harbor dock-caisson side and underside 3D"
    art.lines[2] = "o ChaosHarborDockCargoCaisson"
    # Native Harbor decks measure 9.6..12 x 2 x 9.6..12.
    # All authored y values are relative to true physical deck CENTER.
    # OPAQUE FORGED CORE: top y=.89 < true top y=1.0; actual gameplay
    # Part remains visually present on top and is NEVER locally hidden.
    art.beveled_block("TwelveStudSealedUndersideCassette","ARMOR",
                      0,-.18,0,12.82,2.12,12.82,.28)
    # Side scarp shaping outside the native 12-stud footprint. Every
    # above-deck element is avoided; all details stop at y < +.98.
    for side in (-1,1):
        for axis in ("X","Z"):
            x = side*6.50 if axis=="X" else 0
            z = side*6.50 if axis=="Z" else 0
            sx = .54 if axis=="X" else 11.4
            sz = 11.4 if axis=="X" else .54
            tag = axis + str(side)
            art.beveled_block("ForgedOuterDockWall"+tag,"BRUSHED",
                              x,-.38,z,sx,1.85,sz,.16)
            art.beveled_block("CarbonHydraulicSeat"+tag,"CARBON",
                              x*1.062,-.38,z*1.062,
                              .11 if axis=="X" else 8.2, .60,
                              8.2 if axis=="X" else .11,.035)
            art.beveled_block("RubberUpperImpactBumper"+tag,"GRIP",
                              x,.72,z,sx,.35,sz,.12)
            art.beveled_block("MachinedServiceWarning"+tag,"SIGNAL",
                              x*1.073,.32,z*1.073,
                              .11 if axis=="X" else 3.25,.13,
                              3.25 if axis=="X" else .11,.045)
            for slot in range(3):
                t=(-3.8,0,3.8)[slot]
                art.beveled_block("CargoLockClasp"+tag+"_"+str(slot),"ALLOY",
                                  x if axis=="X" else t, -.73,
                                  t if axis=="X" else z,
                                  .74 if axis=="X" else 1.02,
                                  .69,
                                  1.02 if axis=="X" else .74,.15)
                art.beveled_block("DielectricAccessPort"+tag+"_"+str(slot),"CERAMIC",
                                  x*1.075 if axis=="X" else t,
                                  -.73,
                                  t if axis=="X" else z*1.075,
                                  .095 if axis=="X" else .57,
                                  .42,
                                  .57 if axis=="X" else .095,.032)

    # Underneath the REAL floor: tiered load ring, opposing support
    # channels and articulated X braces. All visually readable from
    # beneath the elevated Harbor jumps, no extra collision.
    art.beveled_block("DualRailLowerBulkhead","ARMOR",
                      0,-1.46,0,11.7,.70,11.7,.34)
    art.beveled_block("RecessedCargoPowerCase","CARBON",
                      0,-2.04,0,7.15,.40,7.15,.25)
    for side in (-1,1):
        for axis in ("X","Z"):
            x = side*4.55 if axis=="X" else 0
            z = side*4.55 if axis=="Z" else 0
            art.beveled_block("SuspendedLongitudinalGirder"+axis+str(side),
                              "ALLOY",x,-1.72,z,
                              .72 if axis=="X" else 9.0,
                              .95,9.0 if axis=="X" else .72,.19)
            art.rod("RealDiagonalLoadPath"+axis+str(side),"BRUSHED",
                    (-4.9,-1.35,side*4.6) if axis=="Z"
                        else (side*4.6,-1.35,-4.9),
                    (4.9,-2.28,side*4.6) if axis=="Z"
                        else (side*4.6,-2.28,4.9),
                    .14,10)
    art.beveled_block("UndersideMaintenanceCap","CERAMIC",
                      0,-2.27,0,4.85,.23,4.85,.16)

    assert set(art.materials)==set(MATERIALS)
    assert 30<=art.groups<=125,art.groups
    assert 900<=art.triangles<=4600,art.triangles
    return art


def export(path: Path) -> dict:
    art=create()
    dimensions=[round(art.maximum[i]-art.minimum[i],5)
                for i in range(3)]
    lo,hi=art.minimum,art.maximum
    # An imported original caisson must never put a fake WALKABLE
    # surface at/above the native platform top y=1.
    assert .75<=hi[1]<=.98, (hi,lo)
    assert -2.55<=lo[1]<=-2.3,(hi,lo)
    assert 13.0<=dimensions[0]<=14.4,dimensions
    assert 2.9<=dimensions[1]<=3.55,dimensions
    assert 13.0<=dimensions[2]<=14.4,dimensions
    path.parent.mkdir(parents=True,exist_ok=True)
    content="\n".join(art.lines)+"\n"
    path.write_text(content,encoding="utf-8")
    return {
        "asset":NAME,"groups":art.groups,"triangles":art.triangles,
        "vertices":art.vertices,"materials":sorted(art.materials),
        "bounds_min":lo,"bounds_max":hi,"dimensions":dimensions,
        "top_plane_native":1.0,
        "under_top_limit":.98,
        "sha256":hashlib.sha256(content.encode()).hexdigest(),
    }


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.output),sort_keys=True))
