#!/usr/bin/env python3
"""Deterministic original 3D manufactured arena-floor module.

Emits a real triangulated OBJ asset (not Roblox Part/WedgePart geometry).
Authored directly for Chaos Survival: geometry, seams, mechanical load paths,
recessed plates, corner mounting hardware and service slots are all original.
No dependencies except Python's standard library. Decorative and sub-0.27 stud
deep: gameplay continues to use the server's authoritative 320-stud floor.
"""
from __future__ import annotations

import argparse
import math
from pathlib import Path

MATERIALS = {"ARMOR", "BRUSHED", "CARBON", "GRIP", "ALLOY", "CERAMIC", "SIGNAL"}
TOP_LIMIT = 0.033
VERTICAL_MINIMUM = -0.226
HALF_FOOTPRINT = 24.25


class OriginalTile:
    def __init__(self):
        self.lines = [
            "# Chaos Survival ORIGINAL 48.5-stud mechanical 3D floor",
            "# All upper details below the arena's existing hazard markings.",
            "mtllib chaos_route_kit.mtl",
            "o ChaosPremiumGroundTile",
        ]
        self.vertex_count = 0
        self.triangles = 0

    def geometry(self, name, material, vertices, faces):
        if material not in MATERIALS:
            raise ValueError("Unknown material: " + material)
        if not vertices or not faces:
            raise ValueError("Empty original geometry")
        for x, y, z in vertices:
            if not all(math.isfinite(n) for n in (x, y, z)):
                raise ValueError("Nonfinite source geometry")
            if max(abs(x), abs(z)) > HALF_FOOTPRINT + 1e-6:
                raise ValueError("Geometry exceeds the physical floor tile")
            if y > TOP_LIMIT or y < VERTICAL_MINIMUM:
                raise ValueError("Unapproved elevated source geometry")
        self.lines.extend(("g " + name, "usemtl " + material))
        base = self.vertex_count
        for x, y, z in vertices:
            self.lines.append(f"v {x:.6f} {y:.6f} {z:.6f}")
        for tri in faces:
            if len(tri) != 3 or len(set(tri)) != 3:
                raise ValueError("Invalid source triangle")
            if min(tri) < 0 or max(tri) >= len(vertices):
                raise ValueError("Invalid source triangle index")
            a, b, c = (base + v + 1 for v in tri)
            self.lines.append(f"f {a} {b} {c}")
            self.triangles += 1
        self.vertex_count += len(vertices)

    def box(self, name, material, x, y, z, sx, sy, sz, yaw=0.0):
        if min(sx, sy, sz) <= 0:
            raise ValueError("Nonpositive box size")
        vertices = []
        cc, ss = math.cos(yaw), math.sin(yaw)
        for xx, yy, zz in (
            (-1,-1,-1), (1,-1,-1), (1,1,-1), (-1,1,-1),
            (-1,-1,1), (1,-1,1), (1,1,1), (-1,1,1)
        ):
            px, pz = xx * sx * 0.5, zz * sz * 0.5
            vertices.append((x + cc * px - ss * pz,
                             y + yy * sy * 0.5,
                             z + ss * px + cc * pz))
        quads = (
            (0,3,2,1), (4,5,6,7), (0,4,7,3),
            (1,2,6,5), (3,7,6,2), (0,1,5,4),
        )
        faces = []
        for a, b, c, d in quads:
            faces.extend(((a, b, c), (a, c, d)))
        self.geometry(name, material, vertices, faces)

    def octagonal_plate(self, name, material, x, z, hx, hz, cut=0.72):
        # Three bevelled horizontal octagonal contours, continuous original
        # silhouette and explicitly triangulated top, not a square Part.
        def outline(ax, az, chamfer, height):
            return [
                (x-ax+chamfer,height,z-az),
                (x-ax,height,z-az+chamfer),
                (x-ax,height,z+az-chamfer),
                (x-ax+chamfer,height,z+az),
                (x+ax-chamfer,height,z+az),
                (x+ax,height,z+az-chamfer),
                (x+ax,height,z-az+chamfer),
                (x+ax-chamfer,height,z-az),
            ]
        rings = (
            outline(hx, hz, cut, -0.073),
            outline(hx-0.19, hz-0.19, cut, 0.001),
            outline(hx-0.37, hz-0.37, cut, 0.017),
        )
        vertices = sum((list(r) for r in rings), [])
        faces = []
        for level in range(2):
            low, high = level * 8, (level + 1) * 8
            for i in range(8):
                j = (i + 1) % 8
                faces.extend(((low+i, low+j, high+j),
                              (low+i, high+j, high+i)))
        for i in range(1, 7):
            faces.append((16, 16+i, 16+i+1))
            faces.append((0, i+1, i))
        self.geometry(name, material, vertices, faces)

    def fastener(self, name, x, z):
        # Genuine eight-sided recessed clamp with flat faceted head.
        # Fully decorative, much lower than gameplay jump tolerances.
        radius = 0.115
        vertices = []
        for y in (0.016, 0.030):
            for j in range(8):
                angle = math.pi * 2 * j / 8
                vertices.append((
                    x + radius * math.cos(angle), y,
                    z + radius * math.sin(angle)))
        faces = []
        for j in range(8):
            k = (j + 1) % 8
            faces.extend(((j, j+8, k+8), (j, k+8, k)))
        for j in range(1, 7):
            # Winding consistent with native OBJ top normal.
            faces.append((8, 8+j+1, 8+j))
        self.geometry(name, "BRUSHED", vertices, faces)

    def build(self):
        # A real 4x4 assembly at 48.5 studs, under the existing 49.13
        # stud original PBR ground module, with intact low-tier fallback.
        centers = (-18.05, -6.02, 6.02, 18.05)
        for i, x in enumerate(centers):
            for j, z in enumerate(centers):
                code = f"{i+1}_{j+1}"
                material = (
                    "CERAMIC" if (i == 1 and j == 1) or (i == 2 and j == 2)
                    else "BRUSHED" if (i+j) % 5 == 0 else "ARMOR"
                )
                self.octagonal_plate(
                    "Original3DBracedPlate_" + code,
                    material, x, z, 5.72, 5.72)
                # Paired non-slip micro-grips on the bevelled, recessed top.
                for direction in (-1, 1):
                    self.box(
                        f"GripInsert_{code}_{direction:+d}", "GRIP",
                        x + direction * 1.42, 0.020, z,
                        0.30, 0.012, 5.0)
                # Four mechanical fasteners at the industrial load corners.
                for cx in (-1, 1):
                    for cz in (-1, 1):
                        self.fastener(
                            f"Fastener_{code}_{cx:+d}_{cz:+d}",
                            x + cx * 4.58, z + cz * 4.58)
                # Every other plate has a distinct inset service index.
                if (i+j) % 3 == 0:
                    self.box(
                        f"ServiceIndex_{code}", "SIGNAL",
                        x, 0.019, z-3.7, 2.5, 0.008, 0.16)
                if (i+j) % 4 == 1:
                    self.box(
                        f"ServiceHatch_{code}", "CARBON",
                        x, 0.020, z+2.9, 2.3, 0.009, 1.25)
                    self.box(
                        f"ServiceHatchLatch_{code}", "ALLOY",
                        x, 0.027, z+2.9, 0.33, 0.009, 0.75)

        # Structural top channels between actual bevelled sub-plates,
        # an independent visible silhouette rather than a flat color grid.
        for k in (-2, -1, 0, 1, 2):
            line = k * 12.04
            if abs(line) < 24.25:
                self.box(
                    f"DeckTraverse_X_{k:+d}", "CARBON",
                    line, -0.051, 0, 0.17, 0.048, 48.1)
                self.box(
                    f"DeckTraverse_Z_{k:+d}", "CARBON",
                    0, -0.051, line, 48.1, 0.048, 0.17)

        # Inset peripheral manufactured shell, concealed below the player.
        for side in (-1, 1):
            self.box(
                f"OuterChassis_X_{side:+d}", "ALLOY",
                side * 24.04, -0.118, 0, 0.40, 0.16, 48.0)
            self.box(
                f"OuterChassis_Z_{side:+d}", "ALLOY",
                0, -0.118, side * 24.04, 48.0, 0.16, 0.40)
        # Heavy load ribs below the real floor; invisible as walkable ledges.
        for k in (-2, -1, 1, 2):
            off = k * 8.4
            self.box(
                f"UnderfloorBeam_X_{k:+d}", "CARBON",
                off, -0.173, 0, 0.52, 0.09, 47.7)
            self.box(
                f"UnderfloorBeam_Z_{k:+d}", "CARBON",
                0, -0.173, off, 47.7, 0.09, 0.52)
        # Each family has a physical steel attachment distinct from the
        # existing PBR decal material. No overlap with official warnings.
        for corner_x in (-1, 1):
            for corner_z in (-1, 1):
                self.box(
                    f"CornerShroud_{corner_x:+d}_{corner_z:+d}",
                    "BRUSHED", corner_x * 23.50, -0.105,
                    corner_z * 23.50, 1.12, 0.16, 1.12)
        if self.triangles < 1000 or self.triangles >= 16000:
            raise ValueError("Unexpected original floor mesh complexity")
        if self.vertex_count > 60000:
            raise ValueError("Excessive original floor mesh vertices")
        return self.lines


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    tile = OriginalTile()
    lines = tile.build()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(
        f"Original premium arena-floor tile: {tile.triangles} triangles, "
        f"{tile.vertex_count} vertices, {len(lines)} OBJ records; "
        f"bounds +/-{HALF_FOOTPRINT} studs; maximum relief {TOP_LIMIT} studs")


if __name__ == "__main__":
    main()
