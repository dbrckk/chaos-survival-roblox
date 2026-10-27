#!/usr/bin/env python3
"""Original deterministic, tileable high-resolution PBR maps for Chaos Survival.

Outputs: color (sRGB), OpenGL +Y normal, roughness (linear grayscale),
and metallic (binary/grunge grayscale). No copyrighted source textures.
The images are OUTPUTS, not verified Roblox asset IDs. Upload separately.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

MATERIALS = (
    "brushed_titanium",
    "oxidized_steel",
    "armored_diamondplate",
    "reactor_ceramic",
)
CHANNELS = ("color", "normal", "roughness", "metallic")

def tile_noise(size: int, cells: int, seed: int) -> np.ndarray:
    """Periodic smooth value noise, exactly seamless across the UV repeat."""
    if size % cells:
        raise ValueError("Texture size must be divisible by noise lattice")
    rng = np.random.default_rng(seed)
    grid = rng.random((cells, cells), dtype=np.float32)
    sample = np.arange(size, dtype=np.float32) * (cells / size)
    idx = sample.astype(np.int32)
    nxt = (idx + 1) % cells
    frac = sample - idx
    frac = frac * frac * (3 - 2 * frac)
    a = grid[idx[:, None], idx[None, :]]
    b = grid[nxt[:, None], idx[None, :]]
    c = grid[idx[:, None], nxt[None, :]]
    d = grid[nxt[:, None], nxt[None, :]]
    v = (a * (1 - frac[:, None]) + b * frac[:, None])
    w = (c * (1 - frac[:, None]) + d * frac[:, None])
    return (v * (1 - frac[None, :]) + w * frac[None, :]).astype(np.float32)

def clamp(array, low=0.0, high=1.0):
    return np.clip(array, low, high)

def height_to_opengl_normal(height: np.ndarray, strength: float) -> np.ndarray:
    """Tangent-space +Y green OpenGL normals, with periodic derivatives."""
    dx = (np.roll(height, -1, axis=1) -
          np.roll(height, 1, axis=1)) * (strength / 2)
    dy = (np.roll(height, -1, axis=0) -
          np.roll(height, 1, axis=0)) * (strength / 2)
    inv = 1 / np.sqrt(dx * dx + dy * dy + 1)
    return np.stack((
        clamp(0.5 - 0.5 * dx * inv) * 255,
        clamp(0.5 + 0.5 * dy * inv) * 255,
        clamp(0.5 + 0.5 * inv) * 255,
    ), axis=2).astype(np.uint8)

def compose(size: int, name: str):
    coords = np.arange(size, dtype=np.float32)
    yy, xx = np.meshgrid(coords, coords, indexing="ij")
    coarse = tile_noise(size, 8, 1001)
    medium = tile_noise(size, 32, 2002)
    micro = tile_noise(size, 128, 3003)
    grain = tile_noise(size, 256, 4004)

    if name == "brushed_titanium":
        # Directional fine linear machining with occasional polished bands.
        brush = np.sin((xx / size) * (np.pi * 2 * 256))
        band = np.sin((yy / size) * (np.pi * 2 * 48))
        height = (0.46 + 0.15 * brush + 0.12 * (medium - 0.5)
                  + 0.18 * (grain - 0.5) + 0.06 * band)
        color = np.stack((
            0.39 + 0.12 * coarse + 0.10 * medium,
            0.47 + 0.10 * coarse + 0.08 * medium,
            0.54 + 0.08 * coarse + 0.07 * medium,
        ), axis=2)
        rough = 0.28 + 0.22 * (1 - medium) + 0.12 * (1 - grain)
        metallic = np.full((size, size), 1.0, dtype=np.float32)
        normal_strength = 10.0
    elif name == "oxidized_steel":
        # Rust is a dielectric, so its metalness must fall toward BLACK.
        oxidation = clamp((coarse * 0.57 + medium * 0.31
                           + micro * 0.12 - 0.45) * 7)
        scratches = np.maximum(0, np.sin((xx / size) *
                                         (np.pi * 2 * 192))) * 0.07
        height = 0.43 + 0.28 * (medium - 0.5) + 0.23 * (
            micro - 0.5) + oxidation * 0.17 - scratches
        metal_colors = np.stack((
            0.27 + 0.11 * coarse,
            0.34 + 0.12 * coarse,
            0.39 + 0.10 * coarse,
        ), axis=2)
        rust_colors = np.stack((
            0.40 + 0.18 * medium,
            0.16 + 0.12 * medium,
            0.075 + 0.08 * micro,
        ), axis=2)
        color = metal_colors * (1 - oxidation[..., None]) + (
            rust_colors * oxidation[..., None])
        rough = 0.38 + oxidation * 0.48 + 0.12 * (1 - grain)
        metallic = np.where(oxidation > 0.63, 0.0,
                     np.where(oxidation < 0.35, 1.0,
                              (0.63 - oxidation) / 0.28)).astype(np.float32)
        normal_strength = 16.0
    elif name == "armored_diamondplate":
        # Opposing bevelled diamond ribs, repeated without border seams.
        cell = size // 16
        if cell < 16:
            raise ValueError("Diamond plate requires at least 256 pixels")
        def diamond(x, y):
            u = np.abs(((x % cell) - cell * 0.5) / (cell * 0.5))
            v = np.abs(((y % cell) - cell * 0.5) / (cell * 0.5))
            return clamp((1.0 - (u + v) * 0.88) * 8.0) * 0.32
        rib = np.maximum(diamond(xx, yy),
                         diamond(xx + cell * 0.5, yy + cell * 0.5))
        height = 0.36 + rib + 0.16 * (micro - 0.5) + 0.09 * (
            grain - 0.5)
        color = np.stack((
            0.22 + 0.17 * coarse + rib * 0.40,
            0.30 + 0.18 * coarse + rib * 0.44,
            0.37 + 0.18 * coarse + rib * 0.46,
        ), axis=2)
        rough = 0.36 + 0.22 * (1 - medium) - 0.11 * rib
        metallic = np.full((size, size), 0.96, dtype=np.float32)
        normal_strength = 20.0
    elif name == "reactor_ceramic":
        # Dense ceramic panels with recessed seams and microporosity.
        tile = size // 16
        if tile < 16:
            raise ValueError("Ceramic requires at least 256 pixels")
        edges = np.minimum.reduce((
            xx % tile, (tile - 1) - (xx % tile),
            yy % tile, (tile - 1) - (yy % tile),
        ))
        grout = clamp((3.0 - edges) / 3.0)
        bevel = clamp((edges - 1.5) / 8.0)
        height = 0.38 + 0.19 * bevel - 0.24 * grout + (
            micro - 0.5) * 0.11 + (grain - 0.5) * 0.08
        color = np.stack((
            0.29 + 0.13 * coarse + 0.08 * medium,
            0.34 + 0.14 * coarse + 0.08 * medium,
            0.41 + 0.15 * coarse + 0.08 * medium,
        ), axis=2) * (1 - grout[..., None] * 0.42)
        rough = 0.56 + 0.19 * (1 - micro) + 0.12 * grout
        metallic = np.zeros((size, size), dtype=np.float32)
        normal_strength = 13.0
    else:
        raise ValueError(f"Unknown material {name}")

    return {
        "color": (clamp(color) * 255).astype(np.uint8),
        "normal": height_to_opengl_normal(height, normal_strength),
        "roughness": (clamp(rough) * 255).astype(np.uint8),
        "metallic": (clamp(metallic) * 255).astype(np.uint8),
    }

def write_pack(directory: Path, size: int, names: tuple[str, ...]):
    directory.mkdir(parents=True, exist_ok=True)
    report = {
        "format": "Chaos Survival PBR source pack v1",
        "authoring": "original deterministic procedural material design",
        "resolution": [size, size],
        "normal_convention": "OpenGL positive Y tangent-space",
        "texture_upload_status": "NOT_UPLOADED_TO_ROBLOX",
        "materials": [],
    }
    preview = Image.new("RGB", (4 * 288, len(names) * 288), (16, 23, 34))
    for row, name in enumerate(names):
        maps = compose(size, name)
        entries = {}
        for col, channel in enumerate(CHANNELS):
            array = maps[channel]
            image = Image.fromarray(array, mode="RGB" if array.ndim == 3 else "L")
            dest = directory / f"{name}_{channel}_2k.png"
            # Use size in file names only for true 2K; smaller QA images
            # are named with their actual pixel resolution.
            if size != 2048:
                dest = directory / f"{name}_{channel}_{size}px.png"
            # L3 compression keeps 2K noisy normals under the 20MB Roblox
            # limit without spending minutes in PNG optimal-deflate.
            image.save(dest, compress_level=3)
            encoded = dest.read_bytes()
            if len(encoded) >= 20 * 1024 * 1024:
                raise ValueError(f"Exceeded Roblox 20 MB image limit: {dest}")
            entries[channel] = {
                "path": dest.name, "size_bytes": len(encoded),
                "sha256": hashlib.sha256(encoded).hexdigest(),
                "roblox_asset_id": None,
            }
            tile = image.convert("RGB").resize((284, 254), Image.Resampling.LANCZOS)
            preview.paste(tile, (col * 288 + 2, row * 288 + 31))
            draw = ImageDraw.Draw(preview)
            draw.text((col * 288 + 7, row * 288 + 8),
                      f"{name} / {channel}", fill=(223, 237, 255))
        report["materials"].append({"name": name, "maps": entries})
        print(f"{name}: four {size}x{size} PBR maps generated")
    preview.save(directory / "contact_sheet.jpg", quality=91)
    (directory / "manifest.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--size", type=int, default=2048,
                        choices=(256, 512, 1024, 2048))
    parser.add_argument("--output", type=Path,
                        default=Path("build/pbr-2k"))
    parser.add_argument("--material", choices=MATERIALS,
                        action="append", dest="materials")
    args = parser.parse_args()
    names = tuple(args.materials) if args.materials else MATERIALS
    report = write_pack(args.output, args.size, names)
    print(json.dumps({"maps": len(names) * 4,
                      "resolution": report["resolution"],
                      "upload_status": report["texture_upload_status"]}))

if __name__ == "__main__":
    main()
