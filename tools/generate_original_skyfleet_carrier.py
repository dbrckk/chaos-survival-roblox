#!/usr/bin/env python3
"""Generate the original sculpted 3D Chaos Survival skyfleet carrier OBJ.

Seven authored materials; triangulated chamfered hull, variable chord wing
spars, enclosed engine nacelles, toroidal cooling collars, cockpit canopy,
armor ventilation/cable hardware. This is source artwork, not Roblox Parts.
Only the dedicated audited uploader may create a creator-owned Roblox Model.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

MATERIALS = ("ARMOR", "BRUSHED", "CARBON", "GRIP", "ALLOY", "CERAMIC", "SIGNAL")
LIMIT = (29.5, 20.0, 29.0)


class Sculpture:
    def __init__(self):
        self.lines = [
            "# Original 3D Chaos Survival long-range carrier silhouette",
            "mtllib chaos_route_kit.mtl",
            "o ChaosOriginalSkyfleetCarrier",
        ]
        self.vertices = 0
        self.triangles = 0
        self.groups = 0
        self.materials = set()
        self.minimum = [float("inf")] * 3
        self.maximum = [-float("inf")] * 3

    def add(self, name, material, verts, triangles):
        if material not in MATERIALS or not verts or not triangles:
            raise ValueError("Invalid art group or material")
        for vertex in verts:
            if len(vertex) != 3 or not all(math.isfinite(v) for v in vertex):
                raise ValueError("Nonfinite 3D geometry")
            x, y, z = vertex
            if abs(x) > LIMIT[0] or abs(y) > LIMIT[1] or abs(z) > LIMIT[2]:
                raise ValueError(f"Skyfleet model exceeds verified bounds: {vertex}")
            for axis, value in enumerate(vertex):
                self.minimum[axis] = min(self.minimum[axis], value)
                self.maximum[axis] = max(self.maximum[axis], value)
        for face in triangles:
            if len(face) != 3 or len(set(face)) != 3:
                raise ValueError("Skyfleet output must be triangulated")
            if min(face) < 0 or max(face) >= len(verts):
                raise ValueError("Invalid face vertex")
            a, b, c = (verts[i] for i in face)
            u = [b[i] - a[i] for i in range(3)]
            v = [c[i] - a[i] for i in range(3)]
            cross = (u[1]*v[2]-u[2]*v[1],
                     u[2]*v[0]-u[0]*v[2],
                     u[0]*v[1]-u[1]*v[0])
            if sum(t*t for t in cross) <= 1e-10:
                raise ValueError("Degenerate triangle in " + name)
        self.lines.extend(("g " + name, "usemtl " + material))
        for x, y, z in verts:
            self.lines.append(f"v {x:.6f} {y:.6f} {z:.6f}")
        for a, b, c in triangles:
            self.lines.append(
                f"f {self.vertices+a+1} {self.vertices+b+1} {self.vertices+c+1}")
        self.vertices += len(verts)
        self.triangles += len(triangles)
        self.groups += 1
        self.materials.add(material)

    def beveled_block(self, name, material, x, y, z, sx, sy, sz, edge=.28):
        """Original chamfered octagonal X/Z profile extruded through Y."""
        hx, hz, hy = sx/2, sz/2, sy/2
        e = min(edge, hx*.43, hz*.43)
        p = [(-hx+e,-hz),(hx-e,-hz),(hx,-hz+e),(hx,hz-e),
             (hx-e,hz),(-hx+e,hz),(-hx,hz-e),(-hx,-hz+e)]
        vertices = [(x+a,y-hy,z+b) for a,b in p]
        vertices += [(x+a,y+hy,z+b) for a,b in p]
        faces = []
        for i in range(1,7):
            faces.extend(((0,i+1,i), (8,8+i,8+i+1)))
        for i in range(8):
            j=(i+1)%8
            faces.extend(((i,j,i+8),(j,j+8,i+8)))
        self.add(name,material,vertices,faces)

    def loft(self, name, material, stations):
        """11-sided continuously tapered hull; genuinely sculpted silhouette."""
        cross = [(-.88,-.81),(-.36,-1),(.36,-1),(.88,-.81),
                 (1,-.27),(.93,.48),(.61,.88),(0,1),
                 (-.61,.88),(-.93,.48),(-1,-.27)]
        size=len(cross)
        vertices=[]
        for z, width, height, center in stations:
            for px,py in cross:
                vertices.append((px*width,center+py*height,z))
        faces=[]
        for k in range(len(stations)-1):
            for j in range(size):
                following=(j+1)%size
                a=k*size+j
                b=k*size+following
                c=(k+1)*size+following
                d=(k+1)*size+j
                faces.extend(((a,b,c),(a,c,d)))
        for k in range(1,size-1):
            faces.append((0,k+1,k))
            back=(len(stations)-1)*size
            faces.append((back,back+k,back+k+1))
        self.add(name,material,vertices,faces)

    def wing(self, side):
        """Variable sweep, sculpted chine and real underside thickness."""
        outline = [
            (6.0,-11.2,2.1),(11.5,-16.2,1.9),(22.4,-9.2,.4),
            (26.6,-3.0,-.7),(24.2,3.1,-.4),(13.8,10.1,1.0),
            (7.2,6.8,2.2)]
        top=[(side*x,y,z) for x,z,y in outline]
        bottom=[(x,y-1.18,z) for x,y,z in top]
        n=len(top)
        verts=top+bottom
        faces=[]
        for i in range(1,n-1):
            faces.extend(((0,i,i+1),(n,n+i+1,n+i)))
        for i in range(n):
            j=(i+1)%n
            faces.extend(((i,j,n+j),(i,n+j,n+i)))
        if side<0:
            faces=[(a,c,b) for a,b,c in faces]
        self.add("SweptArmoredWing"+("Port" if side<0 else "Starboard"),
                 "ARMOR",verts,faces)
        for k in range(6):
            x=side*(10.7+k*2.35)
            z=-6.0+k*.38
            self.beveled_block("WingPressureCassette"+str(side)+"_"+str(k),
                               "CARBON",x,1.35-k*.25,z,1.4,.12,2.9,.15)
        for k in range(5):
            x=side*(11.2+k*2.7)
            self.beveled_block("SweptWingRib"+str(side)+"_"+str(k),
                               "ALLOY",x,.58-k*.2,3.5-k*.2,
                               1.0,.16,2.5,.10)
        self.beveled_block("FinEdgeSignal"+str(side),"SIGNAL",
                           side*24.0,-.20,-3.0,1.15,.13,4.5,.10)

    def rod(self,name,material,start,end,radius,segments=10):
        delta=[end[i]-start[i] for i in range(3)]
        length=math.sqrt(sum(v*v for v in delta))
        if length<.05 or radius<=0:
            raise ValueError("Invalid tube")
        unit=tuple(v/length for v in delta)
        ref=(0.,0.,1.) if abs(unit[1])>.88 else (0.,1.,0.)
        u=(unit[1]*ref[2]-unit[2]*ref[1],
           unit[2]*ref[0]-unit[0]*ref[2],
           unit[0]*ref[1]-unit[1]*ref[0])
        norm=math.sqrt(sum(a*a for a in u))
        u=tuple(a/norm for a in u)
        v=(unit[1]*u[2]-unit[2]*u[1],
           unit[2]*u[0]-unit[0]*u[2],
           unit[0]*u[1]-unit[1]*u[0])
        verts=[]
        for pos in (start,end):
            for i in range(segments):
                angle=2*math.pi*i/segments
                verts.append(tuple(
                    pos[j]+radius*(u[j]*math.cos(angle)+v[j]*math.sin(angle))
                    for j in range(3)))
        faces=[]
        for i in range(1,segments-1):
            faces.extend(((0,i+1,i),(segments,segments+i,segments+i+1)))
        for i in range(segments):
            j=(i+1)%segments
            faces.extend(((i,j,segments+j),(i,segments+j,segments+i)))
        self.add(name,material,verts,faces)

    def nacelle(self,side):
        """Tapered 16-sided engine, physically segmented rotor collar and grille."""
        x=side*12.1
        y=-2.7
        rings=[(5.0,2.2),(6.3,3.2),(11.8,3.6),
               (18.0,3.15),(21.3,2.55)]
        n=16
        verts=[]
        for z,r in rings:
            for i in range(n):
                a=2*math.pi*i/n
                verts.append((x+r*math.cos(a),y+r*math.sin(a),z))
        faces=[]
        for layer in range(len(rings)-1):
            for i in range(n):
                j=(i+1)%n
                a=layer*n+i
                b=layer*n+j
                c=(layer+1)*n+j
                d=(layer+1)*n+i
                faces.extend(((a,b,c),(a,c,d)))
        for i in range(1,n-1):
            faces.extend(((0,i+1,i),((len(rings)-1)*n,
                     (len(rings)-1)*n+i,(len(rings)-1)*n+i+1)))
        self.add("TaperedDriveNacelle"+str(side),"BRUSHED",verts,faces)

        # Toroidal cooling collars have actual ring topology, not cylinders.
        for at in (8.2,16.6):
            major,minor,minorSegments=3.25,.34,8
            verts=[]
            for i in range(n):
                theta=2*math.pi*i/n
                for j in range(minorSegments):
                    phi=2*math.pi*j/minorSegments
                    radial=major+minor*math.cos(phi)
                    verts.append((x+radial*math.cos(theta),
                                  y+radial*math.sin(theta),
                                  at+minor*math.sin(phi)))
            faces=[]
            for i in range(n):
                for j in range(minorSegments):
                    a=i*minorSegments+j
                    b=((i+1)%n)*minorSegments+j
                    c=((i+1)%n)*minorSegments+(j+1)%minorSegments
                    d=i*minorSegments+(j+1)%minorSegments
                    faces.extend(((a,b,c),(a,c,d)))
            self.add("RingCoil"+str(side)+"_"+str(at),"ALLOY",verts,faces)

        self.beveled_block("AfterburnerRecess"+str(side),"CARBON",
                           x,y,21.48,3.9,3.9,.14,.6)
        self.beveled_block("AfterburnerLens"+str(side),"SIGNAL",
                           x,y,21.64,2.4,2.4,.08,.45)
        for k in range(6):
            a=2*math.pi*k/6
            sx=x+math.cos(a)*2.45
            sy=y+math.sin(a)*2.45
            self.rod("EngineTorqueVane"+str(side)+"_"+str(k),"ARMOR",
                     (sx,sy,18.0),(sx*.96+x*.04,sy*.96+y*.04,21.5),.15,8)
        self.rod("EngineMainCoolantRail"+str(side),"GRIP",
                 (x+side*3.8,y+.8,8.0),(x+side*3.3,y+.8,19.6),.18,8)

    def write(self,path):
        if not 1400<=self.triangles<=11000:
            raise ValueError("Skyfleet triangle envelope out of bounds")
        if not 20<=self.groups<=512 or set(MATERIALS)!=self.materials:
            raise ValueError("Missing material or invalid group count")
        dimensions=[self.maximum[i]-self.minimum[i] for i in range(3)]
        if dimensions[0] < 45 or dimensions[1] < 12 or dimensions[2] < 45:
            raise ValueError("Not a true colossal aerial silhouette")
        path.parent.mkdir(parents=True,exist_ok=True)
        content="\n".join(self.lines)+"\n"
        path.write_text(content,encoding="utf-8")
        return {
            "asset":"skyfleet_carrier",
            "vertices":self.vertices,
            "triangles":self.triangles,
            "groups":self.groups,
            "materials":sorted(self.materials),
            "bounds_min":self.minimum,
            "bounds_max":self.maximum,
            "dimensions":dimensions,
            "bytes":len(content.encode("utf-8")),
            "sha256":hashlib.sha256(content.encode("utf-8")).hexdigest(),
        }


def build():
    m=Sculpture()
    m.loft("ElevenFacetedMonocoque","ARMOR",[
        (-25.1,.75,1.1,-.4),(-22.5,3.5,2.4,-.4),(-17.5,6.1,4.0,-.1),
        (-10.2,8.4,4.9,0),(-1,9.3,5.3,.1),(8,9.5,4.6,-.1),
        (16,7.6,3.5,-.5),(24.5,1.9,1.4,-.6)])
    m.loft("UpperSensorBridge","CERAMIC",[
        (-15.5,.8,.32,5.6),(-12.4,2.8,1.3,5.5),
        (-8.0,3.6,2.1,6.3),(-2.5,3.0,2.0,6.1),
        (2.2,1.2,1.1,5.5)])
    m.beveled_block("PressureCockpitGlass","CARBON",
                    0,7.4,-8.9,5.6,.82,5.1,.6)
    m.beveled_block("HullTangentDatum","GRIP",0,5.4,5.8,3.5,.28,17,.35)
    m.beveled_block("LowerKeelSpline","CARBON",0,-6.2,1.5,2.8,1.0,28,.5)
    for side in (-1,1):
        m.wing(side)
        m.nacelle(side)
        m.beveled_block("ThrustHingeShell"+str(side),"BRUSHED",
                        side*7.4,0.45,12.7,3.9,1.9,6.0,.45)
        m.rod("SideArmorTie"+str(side),"ALLOY",
              (side*7.3,-.4,-8.0),(side*16.9,.6,-2.3),.36,10)
        m.rod("WingBraceStrut"+str(side),"BRUSHED",
              (side*6.5,-3.1,1.9),(side*19.0,-.9,3.4),.33,10)
        m.beveled_block("WingTipElevator"+str(side),"CARBON",
                        side*23.2,.2,2.1,2.1,2.15,2.7,.28)
        for i in range(6):
            m.beveled_block("SideMaintenancePanel"+str(side)+"_"+str(i),
                            "GRIP",side*7.7,3.8,-10.5+i*3.0,
                            1.0,.18,1.85,.18)
    for i in range(11):
        z=-17+i*3.4
        m.beveled_block("ArticulatedDorsalPlate"+str(i),"ALLOY",
                        0,5.16,z,4.1,.23,1.65,.32)
        if i%2 == 0:
            m.beveled_block("DorsalSensorNotch"+str(i),"SIGNAL",
                            0,5.32,z,1.5,.10,.32,.05)
    for side in (-1,1):
        m.rod("RearVentralStabilizer"+str(side),"ARMOR",
              (side*4.2,-4.0,11.6),(side*6.4,-7.5,20.5),.40,10)
        m.rod("RoofSignalMast"+str(side),"BRUSHED",
              (side*3.2,6.4,10.5),(side*4.3,11.7,12.2),.21,8)
    return m


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",default="assets/source/chaos_skyfleet_carrier.obj")
    args=parser.parse_args()
    summary=build().write(Path(args.output))
    print(json.dumps(summary,sort_keys=True,indent=2))


if __name__=="__main__":
    main()
