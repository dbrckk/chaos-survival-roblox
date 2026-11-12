#!/usr/bin/env python3
"""Creator-authored, genuinely triangulated 3D side/back shell for 16 districts.

Not a Roblox Part, a built-in primitive, or a fake asset ID. Its origin and
axes match ArenaDistrictArchitecture.fixture (the door-derived origin used
by PremiumDistrictFacadeMeshKit). Replaces ONLY native nonphysical Core,
SupportL/R and two side cassettes AFTER Roblox approval and validation.
The actual door, recess, sector sign, windows, vanes and footings remain.
Uses existing original 7-family metal palette and UV/tangent glTF exporter.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from generate_district_profile_meshes import Mesh


MODEL = "district_sidewall_shell"
REPLACED = ("ServiceCore", "ArmoredSupportL", "ArmoredSupportR",
            "SideCassette-1", "SideCassette1")
# Exact physical-independent server-authored massing:
# Core              6.8 x 7.3 x 6.8 @ (0,8.4,0)
# ArmoredSupport±    1.4 x 12.6 x 2.3 @ (±4.4,7.1,1.8)
# SideCassette±     .85 x 4.8 x 4.6 @ (±3.68,7.6,.48)
# No mesh is put across the 4.65 x 4.68 service door at z=-4.36.
# The sign, source windows and two side windows remain native and visible.


def authored_shell(m: Mesh) -> None:
    """Solid manufactured envelope and distinctly machined 3D cladding."""
    # This SOLID UV-ready bevelled core supplies the native volume from
    # both sides, behind the service door (front edge z=-3.4, door z=-4.36).
    m.faceted("OriginalLoadBearingMachinedCore", "ARMOR",
              0, 8.4, 0, 6.8, 7.3, 6.8, 0.50)
    m.faceted("RecessedCoreCapBevel", "BRUSHED",
              0, 12.12, 0, 7.2, .25, 7.0, .16)
    m.faceted("OriginalFoundationCoreShoe", "ALLOY",
              0, 4.73, 0, 7.15, .32, 6.95, .16)

    for side in (-1, 1):
        letter = "L" if side < 0 else "R"

        # Existing supports are real VOLUMES, not empty braces. Clone
        # their exact occupied envelope, with chamfered section and rings.
        # A real floor-contact shoe gives the imported package a true
        # authored minimum Y=0. This makes the existing center-based
        # original-template mounting align at exactly the intended origin.
        m.faceted("ForgedFloorContactShoe" + letter, "ALLOY",
                  side * 4.4, .16, 1.8, 1.54, .32, 2.45, .10)
        m.faceted("ClosedForgedSupport" + letter, "ARMOR",
                  side * 4.4, 7.1, 1.8, 1.4, 12.6, 2.3, .38)
        for y in (1.2, 4.8, 10.9, 13.0):
            m.faceted("SupportForgedCollar" + letter + str(int(y*10)),
                      "BRUSHED", side * 4.4, y, 1.8,
                      1.62, .24, 2.47, .14)

        # Exactly replace the native side-cassette physical footprint.
        # The existing 0.18-wide real SideGlass pane faces x=±4.22;
        # our cassette outer face stays inside ±4.105, not over glass.
        m.faceted("OriginalSideCassetteShell" + letter, "ALLOY",
                  side * 3.68, 7.6, .48, .85, 4.8, 4.6, .12)
        m.faceted("LowDadoTread" + letter, "GRIP",
                  side * 4.10, 5.12, .48, .13, .28, 4.48, .045)
        m.faceted("HighWeatherSeal" + letter, "BRUSHED",
                  side * 4.10, 10.13, .48, .14, .24, 4.48, .045)

        # True 3D window frame hardware ABOVE/BELOW the existing
        # glass rectangle y=7.2..9.4. No new opaque panel in that range.
        for y in (6.57, 9.88):
            m.faceted("SideGlassSeat" + letter + str(int(y*10)),
                      "CERAMIC", side * 4.18, y, .48,
                      .15, .18, 3.72, .045)
        for z in (-1.44, 2.40):
            m.faceted("SideGlassEndJamb" + letter + str(int((z+2)*10)),
                      "BRUSHED", side * 4.18, 8.30, z,
                      .16, 2.55, .18, .055)

        # One rounded, physically modeled bar between rear/service bays:
        # not a glowing arrow, GUI billboard or new dynamic light.
        for y in (2.15, 11.85):
            m.rod("RoutedExteriorPipe" + letter + str(int(y*10)),
                  "BRUSHED", (side * 5.09, y, .82),
                  (side * 5.09, y, 2.72), .085, 8)
        for y in (3.5, 6.8, 10.1):
            m.faceted("RearRecessedBoltedPlate" + letter + str(int(y*10)),
                      "CARBON", side * 3.45, y, 3.54,
                      .69, 1.52, .18, .055)

        # Thin back-wall ribs are BEHIND the front service entry. They
        # never obscure the 4.65-stud door or its native signage.
        for i in range(5):
            y = 6.0 + i * 1.08
            m.faceted("RearCoolingFin" + letter + str(i), "GRIP",
                      side * 1.82, y, 3.55, 2.44, .13, .30, .04)
            m.faceted("CoolingFinEdge" + letter + str(i), "ALLOY",
                      side * 1.82, y + .095, 3.73,
                      2.43, .045, .065, .012)

        # Precisely manufacturable bolted back-side rails, not
        # artificial full-height transparent blocks or face decals.
        m.rod("BackRail" + letter, "BRUSHED",
              (side * 3.35, 5.25, 3.5),
              (side * 3.35, 11.55, 3.5), .115, 8)
        m.faceted("RearLatticeMount" + letter, "CERAMIC",
                  side * 2.7, 10.75, 3.62, 1.25, .54, .22, .07)


def generate(output: Path) -> dict:
    art = Mesh(MODEL)
    authored_shell(art)
    # Important: actual watertight volumes do not include the player's
    # real service door; source is cosmetic/ noncolliding after approval.
    if not (480 <= art.triangles <= 5200):
        raise ValueError(f"Unexpected original sidewall GPU size: {art.triangles}")
    if not (30 <= art.groups <= 180):
        raise ValueError(f"Unexpected source groups: {art.groups}")
    result = art.write(output)
    result["replaces_native_only"] = REPLACED
    result["door_preserved"] = True
    result["side_glass_preserved"] = True
    result["asset_id"] = None  # Not owned or approved until Roblox imports it
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path,
                        default=Path("assets/source/chaos_district_sidewall_shell.obj"))
    args = parser.parse_args()
    print(json.dumps({"district_sidewall_original": generate(args.output)}, indent=2))


if __name__ == "__main__":
    main()
