#!/usr/bin/env python3
"""Original four-profile engineered district facade / roofline OBJ source.

Real authored triangles (no Roblox Part/WedgePart export). All elements are
cosmetic and must be imported as an approved creator-owned Roblox Model
before any client may mount them. Shared low-overdraw UV-ready metal palette.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

PROFILES = ("observatory", "freight", "turbine", "aerial")
MATERIALS = {"ARMOR", "BRUSHED", "CARBON", "GRIP", "ALLOY", "CERAMIC", "SIGNAL"}
LIMITS = (14.0, 46.0, 13.0)


class Mesh:
    def __init__(self, profile):
        self.profile = profile
        self.lines = [
            "# Original Chaos Survival real 3D district facade / roofline",
            "# Designed as safe cosmetic art over existing district buildings",
            "mtllib chaos_route_kit.mtl",
            "o ChaosDistrictFacade_" + profile,
        ]
        self.vertices = 0
        self.triangles = 0
        self.groups = 0

    def add(self, name, material, vertices, faces):
        if material not in MATERIALS or not vertices or not faces:
            raise ValueError("Invalid original source material/geometry")
        for x, y, z in vertices:
            if not all(math.isfinite(c) for c in (x, y, z)):
                raise ValueError("Non-finite vertices")
            if abs(x) > LIMITS[0] or y < -0.05 or y > LIMITS[1] or abs(z) > LIMITS[2]:
                raise ValueError("Geometry outside cosmetic facade limits")
        for tri in faces:
            if len(tri) != 3 or len(set(tri)) != 3:
                raise ValueError("Non-triangular or repeated face")
            if min(tri) < 0 or max(tri) >= len(vertices):
                raise ValueError("Triangle references missing vertex")
            a, b, c = (vertices[i] for i in tri)
            ab = [b[i] - a[i] for i in range(3)]
            ac = [c[i] - a[i] for i in range(3)]
            cross = (ab[1] * ac[2] - ab[2] * ac[1],
                     ab[2] * ac[0] - ab[0] * ac[2],
                     ab[0] * ac[1] - ab[1] * ac[0])
            if sum(v * v for v in cross) <= 1e-10:
                raise ValueError("Degenerate source triangle in " + name)
        self.groups += 1
        self.lines.extend(("g " + name, "usemtl " + material))
        for x, y, z in vertices:
            self.lines.append(f"v {x:.6f} {y:.6f} {z:.6f}")
        for a, b, c in faces:
            self.lines.append(f"f {self.vertices+a+1} {self.vertices+b+1} {self.vertices+c+1}")
        self.vertices += len(vertices)
        self.triangles += len(faces)

    def faceted(self, name, material, x, y, z, width, height, depth, bevel=0.25):
        """True 8-sided chamfered 3D alloy casing (28 triangles)."""
        if min(width, height, depth) <= 0:
            raise ValueError("Nonpositive engineered dimension")
        hx, hz = width / 2, depth / 2
        chamfer = min(bevel, hx * 0.45, hz * 0.45)
        ring = [(-hx+chamfer,-hz), (hx-chamfer,-hz),
                (hx,-hz+chamfer), (hx,hz-chamfer),
                (hx-chamfer,hz), (-hx+chamfer,hz),
                (-hx,hz-chamfer), (-hx,-hz+chamfer)]
        v = [(x+xx,y-height/2,z+zz) for xx,zz in ring]
        v += [(xx,y+height/2,zz) for xx,_,zz in v]
        faces = []
        for i in range(1, 7):
            faces.extend(((0,i,i+1), (8,8+i+1,8+i)))
        for i in range(8):
            j = (i+1) % 8
            faces.extend(((i,i+8,j+8),(i,j+8,j)))
        self.add(name, material, v, faces)

    def rod(self, name, material, a, b, radius, sides=8):
        """Real radial extrusion, with closed caps and flat-shaded sides."""
        axis = tuple(b[i] - a[i] for i in range(3))
        length = math.sqrt(sum(v*v for v in axis))
        if length <= 1e-5 or radius <= 0 or sides < 6:
            raise ValueError("Invalid real strut")
        d = tuple(v / length for v in axis)
        ref = (0., 0., 1.) if abs(d[1]) > 0.9 else (0., 1., 0.)
        u = (d[1]*ref[2]-d[2]*ref[1],
             d[2]*ref[0]-d[0]*ref[2],
             d[0]*ref[1]-d[1]*ref[0])
        mag = math.sqrt(sum(v*v for v in u))
        u = tuple(v/mag for v in u)
        w = (d[1]*u[2]-d[2]*u[1],
             d[2]*u[0]-d[0]*u[2],
             d[0]*u[1]-d[1]*u[0])
        v = []
        for center in (a,b):
            for i in range(sides):
                angle = 2 * math.pi * i / sides
                v.append(tuple(center[k]+radius*(u[k]*math.cos(angle)+w[k]*math.sin(angle))
                               for k in range(3)))
        faces = []
        for i in range(1, sides-1):
            faces.extend(((0,i+1,i),(sides,sides+i,sides+i+1)))
        for i in range(sides):
            j = (i+1) % sides
            faces.extend(((i,j,sides+j),(i,sides+j,sides+i)))
        self.add(name, material, v, faces)

    def ring(self, name, material, cx, cy, cz, radius, thickness, segments=16):
        """Segmented genuine 3D metal hoop on the vertical X/Y plane."""
        for i in range(segments):
            a = 2*math.pi*i/segments
            b = 2*math.pi*(i+1)/segments
            self.rod(name+"_%02d"%i, material,
                     (cx+radius*math.cos(a),cy+radius*math.sin(a),cz),
                     (cx+radius*math.cos(b),cy+radius*math.sin(b),cz),
                     thickness, 6)

    def triangles_count(self):
        return self.triangles

    def write(self, path):
        if not (200 <= self.triangles <= 12000 and self.groups <= 512):
            raise ValueError("Invalid 3D size for mobile")
        path.parent.mkdir(parents=True, exist_ok=True)
        data = "\n".join(self.lines) + "\n"
        path.write_text(data, encoding="utf-8")
        return {
            "profile":self.profile, "vertices":self.vertices,
            "triangles":self.triangles, "groups":self.groups,
            "bytes":len(data.encode()), "sha256":hashlib.sha256(data.encode()).hexdigest(),
        }


def base_facade(m):
    """Shared articulated industrial building face; door opening remains open."""
    for side in (-1,1):
        tag = "L" if side == -1 else "R"
        x = side * 5.65
        m.faceted("CastFacadeRail"+tag,"ARMOR",x,7.8,-4.3,2.15,14.7,1.45,0.35)
        m.faceted("InsetServicePilaster"+tag,"BRUSHED",
                  side*3.8,5.35,-5.4,0.68,9.5,0.65,0.15)
        m.faceted("RecessedImpactCassette"+tag,"CARBON",
                  side*6.4,9.1,-5.28,0.32,5.9,0.30,0.10)
        for y in (4.5,9.0,13.2):
            m.faceted("StructuralTie"+tag+str(int(y*10)),"ALLOY",
                      x,y,-5.36,2.55,0.34,0.68,0.12)
        for y in (5.6,8.5,11.3):
            m.faceted("BrushedVentInlay"+tag+str(int(y*10)),"GRIP",
                      side*5.6,y,-5.62,1.45,0.18,0.25,0.06)
        m.rod("VerticalHydraulicLine"+tag,"BRUSHED",
              (side*7.0,1.8,-4.75),(side*7.0,14.5,-4.75),0.11)
        for y in (2.1,7.6,13.7):
            m.faceted("ServicePipeClamp"+tag+str(int(y*10)),"ALLOY",
                      side*7.0,y,-4.75,0.7,0.24,0.7,0.09)
    # The middle 5.8-stud-wide, 6.8-stud-high doorway stays free of new
    # cosmetic forward faces. It remains the existing server-owned door.
    m.faceted("DoorCrosshead","ARMOR",0,8.15,-5.25,8.4,1.2,2.0,0.45)
    m.faceted("CenterRoofVault","CARBON",0,14.9,-2.2,11.8,1.55,8.2,0.75)
    m.faceted("FrontRoofDripEdge","ALLOY",0,15.5,-5.8,13.5,0.5,1.0,0.28)
    for side in (-1,1):
        m.rod("VaultAngle"+str(side),"ARMOR",
              (side*6.3,14.4,-5.55),(side*3.9,17.0,-1.4),0.38)
        m.faceted("RoofSeam"+str(side),"BRUSHED",
                  side*4.2,16.08,-1.5,0.27,0.35,7.6,0.1)


def observatory(m):
    base_facade(m)
    for side in (-1,1):
        m.rod("SurveyHanger"+str(side),"ARMOR",
              (side*4.7,15.5,-2.6),(side*4.0,22.6,-2.4),0.52)
        m.faceted("SurveyInstrumentPod"+str(side),"CERAMIC",
                  side*4.15,22.8,-2.4,3.25,3.0,3.4,0.63)
        m.faceted("InstrumentSlit"+str(side),"SIGNAL",
                  side*4.15,22.95,-4.18,2.15,0.37,0.18,0.05)
    m.ring("OriginalSurveyReticle","BRUSHED",0,25.5,-2.25,3.35,0.22,16)
    m.faceted("ObservatoryFocusingCore","CERAMIC",
              0,25.5,-2.25,2.0,2.3,1.75,0.42)
    m.rod("AntennaNeedle","SIGNAL",(0,28.8,-2.25),(0,35.0,-2.25),0.15)
    for side in (-1,1):
        m.rod("AntennaBrace"+str(side),"ALLOY",
              (side*3.5,18.5,-1.6),(0,28.4,-2.25),0.22)


def freight(m):
    base_facade(m)
    m.faceted("CargoSpanningCrossbeam","ARMOR",
              0,19.1,-1.8,15.8,2.15,3.25,0.85)
    for side in (-1,1):
        m.faceted("FreightLiftHousing"+str(side),"CARBON",
                  side*5.9,20.1,-2.8,3.5,4.2,3.6,0.6)
        m.rod("FreightSuspensionCable"+str(side),"BRUSHED",
              (side*5.9,18.3,-3.4),(side*5.9,8.3,-3.4),0.12)
        m.rod("HeavyDiagonalTriangulation"+str(side),"BRUSHED",
              (side*7.0,18.0,-2.1),(side*4.0,13.5,-2.1),0.3)
        m.ring("WinchDrum"+str(side),"ALLOY",
               side*5.9,21.15,-4.5,1.06,0.20,12)
    m.faceted("CraneDriveAssembly","CERAMIC",0,21.0,-1.8,4.5,2.4,3.3,0.48)
    for x in (-5,-2,2,5):
        m.faceted("HoistRoofFork"+str(x),"BRUSHED",
                  x,23.35,-1.5,0.5,2.9,2.4,0.17)


def turbine(m):
    base_facade(m)
    for index,x in enumerate((-4.3,0.,4.3)):
        m.faceted("ExhaustCowl"+str(index),"CERAMIC",
                  x,20.5,-1.6,3.65,5.5,3.45,0.64)
        m.ring("TurbineGuard"+str(index),"ALLOY",
               x,21.3,-3.45,1.55,0.19,12)
        for vane in range(6):
            angle = 2*math.pi*vane/6
            m.rod("TurbineVane%d_%d"%(index,vane),"GRIP",
                  (x,21.3,-3.55),
                  (x+math.cos(angle)*1.28,21.3+math.sin(angle)*1.28,-3.55),
                  0.15,6)
        m.faceted("CowlBackMount"+str(index),"ARMOR",
                  x,17.2,0.25,2.9,1.55,2.0,0.36)
    for side in (-1,1):
        m.rod("ExhaustDiagonal"+str(side),"BRUSHED",
              (side*6.1,14.8,-4.2),(side*4.3,20.3,-1.6),0.33)
    m.faceted("ThermalExtractionManifold","ARMOR",0,26.0,0.15,12.4,1.0,3.4,0.36)


def aerial(m):
    base_facade(m)
    m.faceted("MastBaseArmour","ARMOR",0,20,-1.25,3.4,9.4,3.6,0.63)
    m.rod("OriginalSignalMast","ALLOY",
          (0,15.7,-1.25),(0,39.0,-1.25),0.37,12)
    for y,r in ((23.0,3.25),(30.1,2.3),(35.9,1.4)):
        m.ring("SignalArray"+str(int(y*10)),"BRUSHED",
               0,y,-1.25,r,0.15,16)
        for side in (-1,1):
            m.rod("RadarCantilever"+str(side)+str(int(y*10)),"ARMOR",
                  (0,y,-1.25),(side*(r+2.0),y,-1.25),0.21)
            m.faceted("ReceiverModule"+str(side)+str(int(y*10)),
                      "CERAMIC",side*(r+1.85),y,-1.25,
                      1.2,1.95,1.6,0.24)
    for side in (-1,1):
        m.rod("LatticeMastTie"+str(side),"ARMOR",
              (side*5.8,15.7,-2.0),(0,30.1,-1.25),0.25)
    m.rod("AerialCapNeedle","SIGNAL",(0,39,-1.25),(0,44.3,-1.25),0.12)


def generate(output_dir):
    summaries = []
    for profile, builder in (("observatory",observatory),
                             ("freight",freight),
                             ("turbine",turbine),
                             ("aerial",aerial)):
        m = Mesh(profile)
        builder(m)
        summaries.append(m.write(output_dir / ("chaos_district_" + profile + ".obj")))
    return summaries


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=Path("assets/source"))
    args = parser.parse_args()
    print(json.dumps({"original_district_3d_models":generate(args.output_dir)},
                     indent=2))


if __name__ == "__main__":
    main()
