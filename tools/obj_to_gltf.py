#!/usr/bin/env python3
"""Convert our original, triangulated OBJ+MTL sources to a self-contained glTF 2.0.
Standard library only. The resulting .gltf can be uploaded as an Open Cloud Model.
This does NOT upload assets, change game scripts, or insert models in any place.
"""
from __future__ import annotations

import argparse
import base64
from collections import defaultdict
import json
import math
from pathlib import Path
import struct


def read_materials(path: Path) -> dict:
    materials = {}
    current = None
    for raw in path.read_text(encoding="utf-8").splitlines():
        tokens = raw.split()
        if not tokens or tokens[0].startswith("#"):
            continue
        if tokens[0] == "newmtl" and len(tokens) == 2:
            current = tokens[1]
            materials[current] = {"color": [0.2, 0.3, 0.4], "emissive": [0, 0, 0]}
        elif tokens[0] in ("Kd", "Ke") and current and len(tokens) == 4:
            values = [float(v) for v in tokens[1:]]
            if not all(math.isfinite(v) for v in values):
                raise ValueError("Non-finite material values")
            materials[current]["color" if tokens[0] == "Kd" else "emissive"] = values
    if not materials:
        raise ValueError("No palette materials found")
    return materials


def read_obj(path: Path, materials: dict):
    vertices = [None]
    triangles = defaultdict(list)
    material = None
    groups = 0
    for raw in path.read_text(encoding="utf-8").splitlines():
        parts = raw.strip().split()
        if not parts or parts[0].startswith("#"):
            continue
        tag = parts[0]
        if tag == "v":
            if len(parts) < 4:
                raise ValueError("Invalid OBJ vertex")
            vertex = tuple(float(x) for x in parts[1:4])
            if not all(math.isfinite(x) for x in vertex):
                raise ValueError("Non-finite OBJ vertex")
            vertices.append(vertex)
        elif tag == "g":
            groups += 1
        elif tag == "usemtl":
            material = parts[1] if len(parts) == 2 else None
            if material not in materials:
                raise ValueError("Unknown material: %r" % material)
        elif tag == "f":
            if material is None or len(parts) < 4:
                raise ValueError("OBJ faces must specify a material and >=3 vertices")
            corners = []
            for item in parts[1:]:
                index = int(item.split("/")[0])
                if index <= 0 or index >= len(vertices):
                    raise ValueError("Only valid positive OBJ vertex indices accepted")
                corners.append(index)
            for j in range(1, len(corners) - 1):
                triangles[material].append((corners[0], corners[j], corners[j + 1]))
    count = sum(len(v) for v in triangles.values())
    if not count or count > 16000 or len(vertices) > 60000 or groups > 512:
        raise ValueError("Unexpected source mesh scale")
    return vertices, triangles, groups


def export_obj(source: Path, palette: Path, destination: Path) -> dict:
    materials = read_materials(palette)
    vertices, groups, group_count = read_obj(source, materials)
    blob = bytearray()
    buffer_views = []
    accessors = []
    primitives = []
    gltf_materials = []

    def stream(packed: bytes, target: int) -> int:
        while len(blob) % 4:
            blob.append(0)
        index = len(buffer_views)
        buffer_views.append({
            "buffer": 0, "byteOffset": len(blob),
            "byteLength": len(packed), "target": target,
        })
        blob.extend(packed)
        return index

    for name in sorted(groups):
        faces = groups[name]
        if not faces:
            continue
        position_data = bytearray()
        normal_data = bytearray()
        mins = [float("inf")] * 3
        maxs = [float("-inf")] * 3

        for ids in faces:
            points = [vertices[i] for i in ids]
            a, b, c = points
            ab = [b[i] - a[i] for i in range(3)]
            ac = [c[i] - a[i] for i in range(3)]
            nx = ab[1] * ac[2] - ab[2] * ac[1]
            ny = ab[2] * ac[0] - ab[0] * ac[2]
            nz = ab[0] * ac[1] - ab[1] * ac[0]
            mag = math.sqrt(nx * nx + ny * ny + nz * nz)
            if mag <= 1e-9 or not math.isfinite(mag):
                raise ValueError("Degenerate face in " + source.name)
            normal = (nx / mag, ny / mag, nz / mag)
            for xyz in points:
                position_data.extend(struct.pack("<3f", *xyz))
                normal_data.extend(struct.pack("<3f", *normal))
                for i in range(3):
                    mins[i] = min(mins[i], xyz[i])
                    maxs[i] = max(maxs[i], xyz[i])

        count = len(faces) * 3
        pos_view = stream(position_data, 34962)
        norm_view = stream(normal_data, 34962)
        pos_id = len(accessors)
        accessors.append({
            "bufferView": pos_view, "componentType": 5126,
            "count": count, "type": "VEC3", "min": mins, "max": maxs,
        })
        norm_id = len(accessors)
        accessors.append({
            "bufferView": norm_view, "componentType": 5126,
            "count": count, "type": "VEC3",
        })

        values = materials[name]
        kd = [max(0, min(1, x)) for x in values["color"]]
        ke = [max(0, min(1, x)) for x in values["emissive"]]
        mat_id = len(gltf_materials)
        gltf_materials.append({
            "name": name,
            "pbrMetallicRoughness": {
                "baseColorFactor": kd + [1],
                "metallicFactor": 0.15 if name in ("TEAL", "AMBER", "CYAN") else 0.62,
                "roughnessFactor": 0.48 if name != "CARBON" else 0.72,
            },
            "emissiveFactor": ke,
            "doubleSided": False,
            "alphaMode": "OPAQUE",
        })
        primitives.append({
            "attributes": {"POSITION": pos_id, "NORMAL": norm_id},
            "material": mat_id, "mode": 4,
        })

    if not primitives:
        raise ValueError("No triangles to export")
    result = {
        "asset": {"version": "2.0", "generator": "ChaosSurvival OBJ to glTF - stdlib"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": source.stem, "mesh": 0}],
        "meshes": [{"name": source.stem, "primitives": primitives}],
        "buffers": [{
            "byteLength": len(blob),
            "uri": "data:application/octet-stream;base64,"
                + base64.b64encode(blob).decode("ascii"),
        }],
        "bufferViews": buffer_views,
        "accessors": accessors,
        "materials": gltf_materials,
    }
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(result, separators=(",", ":")), encoding="utf-8")
    return {
        "source": source.name, "triangles": sum(len(f) for f in groups.values()),
        "groups": group_count, "materials": len(primitives),
        "gltf_bytes": destination.stat().st_size,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--materials", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(export_obj(args.source, args.materials, args.output)))


if __name__ == "__main__":
    main()
