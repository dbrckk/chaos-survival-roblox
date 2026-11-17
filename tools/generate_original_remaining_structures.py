#!/usr/bin/env python3
"""Reproducible sculpted, real-triangle originals for remaining structural P0 art.

Not Roblox Parts, mock asset IDs or camera-facing decals. Five independent
UV-ready OBJ sources with seven approved material families. Real gameplay
colliders, wayfinding and hazard visuals are NOT included in these meshes.
Do not activate a source in Roblox until a creator-owned Model is Approved.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_original_skyfleet_carrier import MATERIALS, Sculpture

ASCENSION = {
    "ascension_access_arch": (12.1, 1.30, 2.8),
    "ascension_transfer_arch": (12.9, 1.30, 3.5),
    "ascension_summit_arch": (14.0, 1.90, 4.6),
}
PROFILES = (
    *ASCENSION,
    "architectural_column_casing",
    "orbital_helix_underframe",
    "orbital_access_chassis",
)


def ascending_arch(art: Sculpture, model: str) -> None:
    """True 10-facet X/Z arches, open unobstructed R15 route under the beam.

    Source axes: X=route deck width, Z=route deck length, Y=vertical from
    REAL deck CFrame. Footprint is outboard: posts at Z=+/-7.55, while
    the source reference platform's safe interior remains |Z| <=6.0.
    Exact deck-fitting is validated later by the Roblox client owner.
    """
    height, thickness, roof_width = ASCENSION[model]
    top_y = 1.0 + height
    for side in (-1, 1):
        label = "Neg" if side < 0 else "Pos"
        z = side * 7.55
        art.beveled_block("CastFoundationFork" + label, "ARMOR",
                          0, 0.70, z, 3.9, 1.40, 2.20, 0.45)
        art.beveled_block("TaperedVerticalPylon" + label, "BRUSHED",
                          0, 1.2 + (height - 1.5) / 2, z,
                          1.35, height - 1.5, 1.40, 0.30)
        art.beveled_block("PylonOuterCarbonCassette" + label, "CARBON",
                          -0.78, 7.5, z, .16, 6.3, .95, .06)
        art.beveled_block("CableGuardLiner" + label, "GRIP",
                          .79, 7.5, z, .12, 6.6, 1.10, .045)
        art.beveled_block("UpperForgedSplice" + label, "ALLOY",
                          0, top_y - .30, z, 2.4, 1.48, 2.15, .32)
        art.rod("OutboardLoadStay" + label, "ALLOY",
                (-1.32, 2.5, z + side*.58),
                (-.68, top_y-.50, z-side*.45), .18, 10)
        art.rod("TensionCable" + label, "CARBON",
                (1.15, 2.1, z - side*.50),
                (.60, top_y-1.0, z+side*.25), .085, 8)
        for k in range(4):
            y = 3.0 + k*2.25
            art.beveled_block("MachinedSafetyClamp" + label + str(k),
                              "CERAMIC", 0, y, z+side*.86,
                              2.1, .25, .43, .09)
            art.beveled_block("NeutralServiceIndicator" + label + str(k),
                              "SIGNAL", -.84, y, z+side*.90,
                              .06, .12, .23, .022)
    # This is an overhead gateway; never create an additional walkable top.
    art.beveled_block("FullSpanUpperBridgingGirder", "ARMOR",
                      0, top_y, 0, roof_width, thickness, 17.6, .52)
    art.beveled_block("MachinedCrossheadCrown", "CERAMIC",
                      0, top_y+thickness*.5+.34, 0,
                      roof_width+.6, .45, 16.8, .20)
    art.beveled_block("OpenLowerIBeam", "BRUSHED",
                      0, top_y-thickness*.5-.44, 0,
                      roof_width*.76, .28, 16.6, .12)
    for k in range(9):
        z=-7.2 + k*1.8
        art.rod("CrossheadTrussRib"+str(k), "ALLOY",
                (-roof_width*.43,top_y-.36,z),
                (roof_width*.43,top_y+.24,z+.57), .10, 8)
        art.beveled_block("RoofVentSerration"+str(k), "GRIP",
                          0, top_y+thickness*.5+.62,z,
                          roof_width*.63,.10,.35,.045)
    art.beveled_block("HighMechanicalServiceHousing","CARBON",
                      0,top_y+thickness*.5+1.25,0,
                      roof_width*.8,1.24,2.25,.25)
    art.beveled_block("RecessedIdentityPlaque","SIGNAL",
                      -roof_width*.40,top_y+thickness*.5+1.20,0,
                      .055,.38,1.12,.017)
    # An original non-walkable underdeck keel: below the server collider.
    art.beveled_block("UnderslungCoreKeel","ARMOR",
                      0,-1.55,0,3.1,.72,10.0,.22)
    for side in (-1,1):
        art.rod("TrussedUnderdeckBrace"+str(side),"ALLOY",
                (-1.15,-1.4,side*4.5),(1.10,-1.4,0),.10,8)


def architectural_casing(art: Sculpture) -> None:
    """Four nonphysical original ArchitecturalCladding casings per world.

    Coordinates centered on native ArchitecturalCasing origin, which is
    FoundationFoot.CFrame * CFrame.new(0, 3.55, 0). Keep the original
    LandmarkNavigationHead and 4 main FrameColumn colliders intact.
    """
    art.beveled_block("SolidMachineFoundationSocket","ARMOR",
                      0,-3.55,0,5.45,.98,5.30,.52)
    art.beveled_block("ChamferedFrontArmorBulkhead","ARMOR",
                      0,-.05,-1.73,3.35,6.3,.71,.36)
    art.beveled_block("FlutedRearCoolantCase","CERAMIC",
                      0,.19,1.60,3.08,5.85,.62,.28)
    for side in (-1,1):
        lab="Port" if side<0 else "Starboard"
        art.beveled_block("ObliqueLoadShroud"+lab,"BRUSHED",
                          side*2.08,-.14,.03,1.20,5.65,2.20,.38)
        art.rod("TensionLattice"+lab,"ALLOY",
                (side*2.32,-3.22,-1.15),
                (side*.81,3.11,-1.15),.18,10)
        art.rod("OpposingLoadStay"+lab,"CARBON",
                (side*2.24,-3.20,.88),
                (side*1.00,3.12,.82),.14,8)
        for i in range(6):
            y=-2.8+i*1.08
            art.beveled_block("RecessedCoolingBlade"+lab+str(i),
                              "GRIP",side*2.41,y,1.10,
                              .18,.17,.93,.07)
        for z in (-1.15,1.15):
            art.beveled_block("ForgeSideLock"+lab+str(z),
                              "ALLOY",side*2.23,2.6,z,
                              .26,.42,.38,.08)
        art.rod("AirborneAerialStrut"+lab,"BRUSHED",
                (side*1.04,4.62,.0),
                (side*4.12,6.10,-2.05),.27,10)
    art.beveled_block("PrecisionUpperJoint","ARMOR",
                      0,4.12,0,5.87,.66,5.0,.36)
    art.beveled_block("RecessedLiftingCap","CERAMIC",
                      0,4.59,0,4.50,.44,3.80,.28)
    art.beveled_block("ManufacturerSurveyModule","CARBON",
                      0,5.42,-.74,2.48,.74,1.47,.18)
    art.beveled_block("DiagnosticLight","SIGNAL",
                      0,5.42,-1.54,1.46,.18,.08,.036)
    art.beveled_block("CrownMechanicalRidge","GRIP",
                      0,5.03,1.65,2.5,.20,.48,.08)
    # Native crown / navigation head remains outside this authored source.


def orbital_helix_underframe(art: Sculpture) -> None:
    """Original trussed underside for one actual collidable Orbital ramp.

    X = source ramp width 5.4, Z = 24-stud sample ramp length.
    Imported art should be oriented with the TRUE ramp.CFrame, not axes
    inferred from the world. No part ever touches a walkable top.
    """
    for side in (-1,1):
        label="Port" if side<0 else "Starboard"
        x=side*2.22
        art.beveled_block("LongitudinalLoadLattice"+label,"ARMOR",
                          x,-.65,0,.48,.48,23.6,.17)
        art.beveled_block("CarbonGutterChannel"+label,"CARBON",
                          x,-.30,0,.26,.11,22.9,.045)
        art.beveled_block("CeramicMaintenanceTrack"+label,"CERAMIC",
                          x,-.89,0,.31,.13,22.8,.055)
        for k in range(9):
            z=-10.25+k*2.56
            art.rod("UnderslungDiagonal"+label+str(k),"ALLOY",
                    (x,-.49,z-.72),(x-side*.58,-1.33,z+.72),.085,8)
            art.beveled_block("StructuralGusset"+label+str(k),"BRUSHED",
                              x,-.69,z,.64,.25,.35,.08)
    for k in range(7):
        z=-10.7+k*3.56
        art.beveled_block("TraversingForgedCrossTension"+str(k),"ALLOY",
                          0,-1.26,z,5.02,.28,.30,.085)
        art.beveled_block("IsolatedInlaidRivetPair"+str(k),"GRIP",
                          0,-1.43,z,1.35,.15,.31,.044)
    art.beveled_block("NonwalkableCentralPowerKeel","CARBON",
                      0,-1.47,0,1.11,.34,23.10,.20)
    art.beveled_block("RecessedInspectionStripe","SIGNAL",
                      0,-1.67,0,.26,.055,8.5,.025)


def orbital_access_chassis(art: Sculpture) -> None:
    """Low-profile Orbital structure after the approved brief and reference sheet."""
    block = art.beveled_block

    def span(name, x1, z1, x2, z2):
        """Closed, chamfered diagonal with rectangular load-bearing section."""
        dx, dz = x2 - x1, z2 - z1
        length = math.hypot(dx, dz)
        ux, uz = dx / length, dz / length
        wx, wz = uz, -ux
        mx, mz = (x1 + x2) / 2, (z1 + z2) / 2
        section = [(-.13, -.10), (.13, -.10), (.20, -.055), (.20, .06),
                   (.135, .115), (-.135, .115), (-.20, .06), (-.20, -.055)]
        verts = [(mx + wx * x + ux * end, y - .018, mz + wz * x + uz * end)
                 for end in (-length / 2, length / 2) for x, y in section]
        faces = [(0, i+1, i) for i in range(1, 7)]
        faces += [(8, 8+i, 9+i) for i in range(1, 7)]
        for i in range(8):
            j = (i + 1) % 8
            faces.extend(((i, j, i+8), (j, j+8, i+8)))
        art.add(name, "ALLOY", verts, faces)

    for side in (-1, 1):
        x = side * 2.22
        # Three bevel profiles give the spars raised splice points and
        # recessed service bays without blocking the open truss windows.
        block(f"CentralSpar{side}", "ARMOR", x, 0, 0, .49, .30, 5.08, .13)
        for end in (-1, 1):
            block(f"OuterSpar{side}_{end}", "ARMOR", x, -.012, end * 4.03,
                  .59, .37, 3.4, .25)
            block(f"MachinedSparSplice{side}_{end}", "BRUSHED", x, -.052,
                  end * 2.52, .66, .40, .32, .09)
            block(f"VentWell{side}_{end}", "CARBON", side * 2.512, -.015,
                  end * 4.51, .031, .18, .99, .009)
            for fin in range(4):
                block(f"VentRib{side}_{end}_{fin}", "GRIP", side * 2.533, -.015,
                      end * 4.51 + (fin-1.5)*.205, .026, .153, .055, .008)
            for screw in (-1, 1):
                block(f"SpliceFastener{side}_{end}_{screw}", "CERAMIC",
                      x + screw*.20, -.263, end * 2.52, .13, .065, .13, .054)

    for bay, (near, far) in enumerate(((-5.62, -3.48), (-3.48, -1.27),
                                        (1.27, 3.48), (3.48, 5.62))):
        center = (near + far) / 2
        for side in (-1, 1):
            span(f"ForgedDiagonal{bay}_{side}_A", side*2.08, near, 0, center)
            span(f"ForgedDiagonal{bay}_{side}_B", side*2.08, far, 0, center)
        block(f"GussetHub{bay}", "BRUSHED", 0, -.085, center, .69, .24, .64, .20)

    block("OctagonalServiceHousing", "CARBON", 0, -.014, 0, 2.72, .334, 2.50, .46)
    block("RecessedServiceCover", "BRUSHED", 0, -.194, 0, 1.79, .122, 1.64, .39)
    for z in (-1.06, 1.06):
        for i in range(5):
            block(f"CassetteVent{z}_{i}", "GRIP", (i-2)*.26, -.212, z,
                  .14, .085, .23, .040)
    for x in (-.63, .63):
        for z in (-.57, .57):
            block(f"CassetteRivet{x}_{z}", "CERAMIC", x, -.263, z,
                  .119, .055, .119, .046)
    for end in (-1, 1):
        block(f"TaperedTitaniumSaddle{end}", "BRUSHED", 0, -.015, end*5.96,
              5.17, .45, .88, .38)
        block(f"BrassInsetSeat{end}", "CARBON", 0, -.225, end*5.96,
              1.28, .09, .32, .099)
        block(f"BrassIdentificationInsert{end}", "SIGNAL", 0, -.279, end*5.96,
              1.09, .035, .23, .079)


def generate(model: str, output: Path) -> dict:
    if model not in PROFILES:
        raise ValueError("Unknown original Chaos 3D structure")
    art=Sculpture()
    art.lines[0]="# Creator-owned Chaos Survival original geometry: "+model
    art.lines[2]="o ChaosOriginal_"+model
    if model in ASCENSION:
        ascending_arch(art, model)
    elif model=="architectural_column_casing":
        architectural_casing(art)
    elif model=="orbital_helix_underframe":
        orbital_helix_underframe(art)
    elif model=="orbital_access_chassis":
        art.lines[1] = "mtllib chaos_orbital_access_chassis.mtl"
        orbital_access_chassis(art)
    if set(art.materials)!=set(MATERIALS):
        raise ValueError("All seven approved materials must be present")
    if not (500<=art.triangles<=5900 and 25<=art.groups<=190):
        raise ValueError("Original polygon budget not met")
    dims=tuple(round(art.maximum[i]-art.minimum[i],3) for i in range(3))
    if model in ASCENSION:
        if not (3.0<=dims[0]<=10 and 14.0<=dims[1]<=20
                and 17.0<=dims[2]<=21):
            raise ValueError("Unsafe ascension arch dimensions "+str(dims))
    elif model=="architectural_column_casing":
        if not (8<=dims[0]<=10 and 9.8<=dims[1]<=11.8
                and 5.0<=dims[2]<=9.0):
            raise ValueError("Unexpected architectural casing dimensions "+str(dims))
    elif model=="orbital_access_chassis":
        if not (5.1 <= dims[0] <= 5.3 and .45 <= dims[1] <= .55
                and 12.7 <= dims[2] <= 12.9 and art.triangles <= 2400):
            raise ValueError("Unsafe Orbital access chassis geometry " + str(dims))
    else:
        if not (4.5<=dims[0]<=5.7 and 1.0<=dims[1]<=2.3
                and 23.0<=dims[2]<=25.0):
            raise ValueError("Unexpected underframe geometry "+str(dims))
    # Sculpture.write() is intentionally specialized to a 50-stud
    # colossal skyfleet ship. Never weaken that existing gate to export
    # these small arches or struts: serialize the same validated triangles
    # independently after this model-specific envelope and polycount gate.
    raw="\n".join(art.lines)+"\n"
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(raw, encoding="utf-8")
    return {
        "model":model,
        "vertices":art.vertices,
        "triangles":art.triangles,
        "groups":art.groups,
        "materials":sorted(art.materials),
        "dimensions":dims,
        "bounds_min":art.minimum,
        "bounds_max":art.maximum,
        "bytes":len(raw.encode("utf-8")),
        "sha256":hashlib.sha256(raw.encode("utf-8")).hexdigest(),
        "cosmetic_only":True,
        "asset_id":None,
    }


def main()->None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--model", choices=PROFILES, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args=parser.parse_args()
    print(json.dumps(generate(args.model,args.output),sort_keys=True))


if __name__=="__main__":
    main()
