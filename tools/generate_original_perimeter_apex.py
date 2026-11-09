#!/usr/bin/env python3
"""Four wholly original 3D apex sculptures for all five perimeter arenas.

Each authored mesh replaces the TWO native variant-only silhouettes as one
source-verified assembly. No Roblox Part is used to manufacture the geometry.
Seven independent industrial PBR material meshes per approved Model.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from generate_original_skyfleet_carrier import MATERIALS, Sculpture

PROFILES = {
    "perimeter_towers_apex": (2.2, 8.1, 1.8),
    "perimeter_orbital_apex": (3.4, 3.975, 3.4),
    "perimeter_crossroads_apex": (2.5, 3.175, 8.5),
    "perimeter_relay_apex": (2.4, 6.1, 2.0),
}


def column(art, name, material, stations, facets=12):
    """Closed, continuously tapered 12-facet structural extrusion on Y."""
    verts = []
    for y, rx, rz in stations:
        for i in range(facets):
            a = math.tau * i / facets
            verts.append((rx * math.cos(a), y, rz * math.sin(a)))
    faces = []
    for j in range(len(stations)-1):
        for k in range(facets):
            a = j*facets+k
            b = j*facets+(k+1)%facets
            c = (j+1)*facets+(k+1)%facets
            d = (j+1)*facets+k
            faces.extend(((a,b,c),(a,c,d)))
    for k in range(1,facets-1):
        faces.append((0,k+1,k))
        top = (len(stations)-1)*facets
        faces.append((top,top+k,top+k+1))
    art.add(name, material, verts, faces)


def ring(art, name, material, inner, outer, ylo, yhi, facets=32):
    """A closed hollow annular casing; center remains completely empty."""
    verts = []
    for i in range(facets):
        a = math.tau*i/facets
        c,s = math.cos(a),math.sin(a)
        verts.extend(((inner*c,ylo,inner*s),(outer*c,ylo,outer*s),
                      (inner*c,yhi,inner*s),(outer*c,yhi,outer*s)))
    faces = []
    for k in range(facets):
        i,j=4*k,4*((k+1)%facets)
        faces.extend(((i,j+1,j),(i,i+1,j+1),
                      (i+2,j+2,j+3),(i+2,j+3,i+3),
                      (i+1,i+3,j+3),(i+1,j+3,j+1),
                      (i,j,j+2),(i,j+2,i+2)))
    art.add(name,material,verts,faces)


def towers(art):
    column(art,"TenRingTaperedSignalMast","ARMOR",[
        (-4.025,.36,.33),(-3.65,.39,.35),(-1.25,.28,.29),
        (.95,.25,.27),(2.71,.34,.31)])
    for y in (-3.4,-2.1,-.8,.5,1.9,2.55):
        art.beveled_block("StampedMastJunction%s"%y,"BRUSHED",
                          0,y,0,.72,.16,.67,.09)
    for side in (-1,1):
        art.rod("TensionedSideControlRod%s"%side,"ALLOY",
                (side*.32,-3.60,-.28),(side*.31,2.50,-.26),.060,10)
        art.beveled_block("RecessedPowerCell%s"%side,"CARBON",
                          side*.30,-.20,-.34,.17,2.02,.09,.035)
        art.beveled_block("SignalCapSweptFin%s"%side,"GRIP",
                          side*.86,3.25,0,.42,1.15,1.68,.12)
        art.beveled_block("CapForgedOutboardBrace%s"%side,"BRUSHED",
                          side*.78,2.95,0,.52,.27,1.62,.075)
        art.beveled_block("CeramicInsulator%s"%side,"CERAMIC",
                          side*.68,3.84,-.47,.26,.16,.38,.055)
    for k in range(4):
        a = (-1 if k%2==0 else 1)
        z = (-.56 if k<2 else .56)
        art.rod("CrownDuctTruss%02d"%k,"ALLOY",
                (a*.24,2.75,z*.72),(a*.93,3.62,z*.67),.052,8)
    art.beveled_block("CrownClosedOverheadCanopy","ARMOR",
                      0,3.51,0,2.13,.85,1.72,.20)
    art.beveled_block("CrownCentralSignalCell","SIGNAL",
                      0,3.988,-.48,.62,.06,.19,.025)


def orbital(art):
    # Source Y=0 at joint union center (native dish center Y=-1.6625).
    ring(art,"HollowThirtyTwoFacetReceiverRim","ARMOR",
         1.34,1.678,-1.955,-1.635)
    ring(art,"DiecastReceiverInnerRim","BRUSHED",
         .86,1.08,-1.82,-1.66)
    for k in range(12):
        a=math.tau*k/12
        dx,dz=math.cos(a),math.sin(a)
        art.rod("ParabolicDishRadialRib%02d"%k,"ALLOY",
                (dx*.25,-1.52,dz*.25),
                (dx*1.53,-1.76,dz*1.53),.045,8)
    column(art,"TaperedClosedOrbitalReceiver","CARBON",[
        (-1.40,.17,.17),(-1.10,.19,.19),(.10,.14,.14),
        (1.52,.095,.095),(1.965,.04,.04)],16)
    for k in (0,1,2,3):
        a=math.tau*k/4
        dx,dz=math.cos(a),math.sin(a)
        art.rod("AntennaInsulatedStay%d"%k,"GRIP",
                (dx*.69,-1.72,dz*.69),(dx*.12,.62,dz*.12),.058,8)
    art.beveled_block("LowerCeramicFeedModule","CERAMIC",
                      0,-1.48,0,.45,.28,.45,.075)
    art.beveled_block("SkywardSignalHead","SIGNAL",
                      0,1.82,0,.17,.18,.17,.045)
    for i in range(8):
        a=math.tau*i/8
        art.beveled_block("CeramicRimIndex%02d"%i,"CERAMIC",
                          1.50*math.cos(a),-1.62,1.50*math.sin(a),
                          .13,.07,.13,.03)


def crossroads(art):
    # Long 8.5-stud Z-axis transit beam with a separate upright signal.
    for side in (-1,1):
        art.beveled_block("RailwayContinuousSideFrame%s"%side,"ARMOR",
                          side*.92,-1.21,0,.57,.68,8.36,.13)
        art.beveled_block("InboardConductiveSpline%s"%side,"BRUSHED",
                          side*.56,-.98,0,.22,.13,7.94,.05)
        art.beveled_block("StaggeredCeramicStop%s"%side,"CERAMIC",
                          side*.90,-1.02,3.78,.32,.22,.50,.065)
    for index in range(11):
        z=-3.88+index*.776
        art.rod("OpenCrossTransitStrut%02d"%index,"ALLOY",
                (-.70,-1.15,z-.18),(.70,-1.15,z+.18),.060,8)
        if index%2==0:
            art.beveled_block("InsetTractionDiode%02d"%index,"SIGNAL",
                              0,-.92,z,.30,.065,.30,.045)
    column(art,"SwitchyardOctagonalControlSpire","CARBON",[
        (-.41,.50,.53),(-.14,.66,.67),(.60,.50,.51),
        (1.31,.32,.40),(1.56,.13,.17)])
    for side in (-1,1):
        art.beveled_block("StackedInterchangeGuard%s"%side,"GRIP",
                          side*.60,.32,.06,.25,1.27,1.82,.09)
        art.beveled_block("SideSignalPorthole%s"%side,"CERAMIC",
                          side*.66,.77,-.61,.13,.24,.33,.035)
    art.beveled_block("JunctionHeadwaySignal","SIGNAL",
                      0,1.526,-.20,.31,.06,.21,.018)


def relay(art):
    # Shared silhouette between Classic and Harbor, preserving variant paint.
    column(art,"ForgedTwelveFacetRelaySpine","ARMOR",[
        (-3.02,.34,.34),(-2.30,.34,.31),(-.25,.24,.26),
        (.94,.29,.29),(1.34,.36,.34)])
    for k in range(6):
        y=-2.50+k*.72
        art.beveled_block("RibbedRelayDriveCollar%02d"%k,"BRUSHED",
                          0,y,0,.68,.13,.68,.075)
    for side in (-1,1):
        art.rod("RoutedConductor%s"%side,"ALLOY",
                (side*.27,-2.81,-.26),(side*.27,1.31,-.27),.053,8)
        art.beveled_block("FinnedRelayCrown%s"%side,"GRIP",
                          side*.83,2.18,.0,.54,1.52,1.86,.135)
        art.beveled_block("CarbonCradleInset%s"%side,"CARBON",
                          side*.61,2.55,-.82,.31,.41,.12,.04)
        art.beveled_block("CeramicLightningShield%s"%side,"CERAMIC",
                          side*.84,2.88,0,.40,.23,1.33,.08)
    for k in range(5):
        a=math.tau*k/5
        art.beveled_block("RelayPerimeterFinBolt%02d"%k,"ALLOY",
                          .71*math.cos(a),2.55,.71*math.sin(a),
                          .16,.17,.16,.038)
    art.beveled_block("RelayClosedApexCap","BRUSHED",
                      0,2.36,0,2.26,1.28,1.89,.22)
    art.beveled_block("ProtectedDirectionalPilot","SIGNAL",
                      0,3.01,-.70,.69,.059,.19,.02)


MAKERS = {
    "perimeter_towers_apex": towers,
    "perimeter_orbital_apex": orbital,
    "perimeter_crossroads_apex": crossroads,
    "perimeter_relay_apex": relay,
}


def export(profile: str, output: Path):
    if profile not in MAKERS:
        raise ValueError("Unknown creator-authored station topology")
    art=Sculpture()
    art.lines[0]="# Original Chaos Survival district-specific station apex"
    art.lines[2]="o ChaosOriginal_"+profile
    MAKERS[profile](art)
    dims=[round(art.maximum[i]-art.minimum[i],5) for i in range(3)]
    target=PROFILES[profile]
    assert set(art.materials)==set(MATERIALS),art.materials
    assert 20<=art.groups<=120 and 500<=art.triangles<=7000,(profile,art.groups,art.triangles)
    for got,wanted in zip(dims,target):
        assert .78*wanted<=got<=1.04*wanted,(profile,dims,target)
    # Source placements are centered on the union's known local elevation;
    # client uses its true source bounds + native base to locate the assembly.
    for low,high in zip(art.minimum,art.maximum):
        assert abs((low+high)/2) < .2,(profile,art.minimum,art.maximum)
    data="\n".join(art.lines)+"\n"
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(data,encoding="utf-8")
    return {"asset":profile,"triangles":art.triangles,"groups":art.groups,
            "vertices":art.vertices,"materials":sorted(art.materials),
            "dimensions":dims,"min":art.minimum,"max":art.maximum,
            "sha256":hashlib.sha256(data.encode()).hexdigest()}


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--model",choices=MAKERS,required=True)
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(export(args.model,args.output),sort_keys=True))


if __name__=="__main__":
    main()
