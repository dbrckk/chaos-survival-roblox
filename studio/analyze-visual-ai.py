#!/usr/bin/env python3
"""Audit real, externally captured Roblox Studio frames; never invent imagery.

Usage: python studio/analyze-visual-ai.py build/visual-ai-captures
The input must contain exactly 15 PNGs from the authenticated interactive
Windows Studio collector and an accompanying timing/hash manifest.
"""
from __future__ import annotations

import csv
import hashlib
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageStat


def inspect(directory: Path) -> dict:
    files = sorted(directory.glob("ai-frame-*.png"))
    if [x.name for x in files] != [f"ai-frame-{i:02d}.png" for i in range(1, 16)]:
        raise ValueError("Expected exactly fifteen consecutively numbered real PNGs")

    path = directory / "frames.tsv"
    with path.open(encoding="utf-8-sig", newline="") as handle:
        manifest = list(csv.DictReader(handle, delimiter="\t"))
    if len(manifest) != 15:
        raise ValueError("Missing or malformed 15-frame provenance manifest")

    records: list[dict] = []
    thumbnails: list[Image.Image] = []
    previous = None
    hashes = set()
    for number, filename in enumerate(files, 1):
        data = filename.read_bytes()
        if not data.startswith(b"\x89PNG\r\n\x1a\n"):
            raise ValueError(f"Not a genuine PNG: {filename.name}")
        sha256 = hashlib.sha256(data).hexdigest()
        source = manifest[number - 1]
        if int(source["index"]) != number or sha256.lower() != source["sha256"].lower():
            raise ValueError(f"Provenance/hash mismatch for {filename.name}")
        hashes.add(sha256)

        with Image.open(filename) as original:
            original.verify()
        with Image.open(filename) as original:
            frame = original.convert("RGB")
        w, h = frame.size
        if w < 640 or h < 360:
            raise ValueError(f"Viewport too small to inspect: {w}x{h}")
        short = frame.copy()
        short.thumbnail((480, 270), Image.Resampling.LANCZOS)
        thumbnails.append(short)

        # Quantified presentation indicators, not a claimed human/AI
        # assessment of legibility or screenshot authenticity.
        sample = frame.resize((320, 180), Image.Resampling.BILINEAR)
        gray = sample.convert("L")
        colors = ImageStat.Stat(gray)
        pixels = list(gray.getdata())
        black = sum(v < 17 for v in pixels) / len(pixels)
        white = sum(v > 244 for v in pixels) / len(pixels)
        contrast = gray.getextrema()[1] - gray.getextrema()[0]
        mid = sample.crop((80, 35, 240, 150))
        centerGray = mid.convert("L")
        centerMean = ImageStat.Stat(centerGray).mean[0]
        difference = None
        if previous is not None:
            delta = ImageChops.difference(previous, sample)
            difference = round(sum(ImageStat.Stat(delta).mean) / 3.0, 2)
        previous = sample
        warnings = []
        if black > 0.65:
            warnings.append("very_dark_frame")
        if white > 0.35:
            warnings.append("overbright_frame")
        if contrast < 58:
            warnings.append("very_low_contrast")
        if difference is not None and difference < 0.75:
            warnings.append("near_duplicate_frame")
        records.append({
            "index": number,
            "file": filename.name,
            "sha256": sha256,
            "window_title": source["window_title"],
            "utc": source["utc"],
            "width": w,
            "height": h,
            "mean_brightness": round(colors.mean[0], 2),
            "center_brightness": round(centerMean, 2),
            "grayscale_stddev": round(colors.stddev[0], 2),
            "near_black_fraction": round(black, 4),
            "highlight_fraction": round(white, 4),
            "difference_from_previous": difference,
            "warnings": warnings,
        })

    if len(hashes) < 8:
        raise ValueError("Static or duplicated capture: insufficient unique frames")
    moving_frames = sum(
        1 for r in records[1:]
        if r["difference_from_previous"] is not None
        and r["difference_from_previous"] >= 0.75
    )
    if moving_frames < 7:
        raise ValueError("Capture does not contain enough changing 3D content")

    warnings = [
        f"{record['index']:02d}: {warning}"
        for record in records
        for warning in record["warnings"]
    ]
    data = {
        "origin": "real-on-screen-roblox-studio-playtest",
        "production_live_server": False,
        "android_device_certified": False,
        "frame_count": 15,
        "unique_frame_hashes": len(hashes),
        "changing_frame_pairs": moving_frames,
        "visual_warnings": warnings,
        "frames": records,
        "caveat": (
            "Screenshots include the desktop Roblox Studio/play-client window. "
            "Pixel metrics do not establish gameplay balance, human UX, "
            "or Android FPS; inspect every full-resolution PNG."
        ),
    }
    (directory / "visual-ai-audit.json").write_text(
        json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    # A legible contact sheet for rapid review, retaining full-res source
    # PNGs separately. These are real crops/resizes, not generated scenes.
    columns, rows = 5, 3
    cell_w, cell_h = 486, 310
    sheet = Image.new("RGB", (columns * cell_w, rows * cell_h), "#18202d")
    draw = ImageDraw.Draw(sheet)
    for index, thumb in enumerate(thumbnails):
        x = (index % columns) * cell_w + 3
        y = (index // columns) * cell_h + 29
        draw.text((x + 8, y - 21), f"AI FRAME {index + 1:02d}/15", fill="#ffffff")
        sheet.paste(thumb, (x, y))
        diff = records[index]["difference_from_previous"]
        draw.text(
            (x + 8, y + 274),
            f"brightness {records[index]['mean_brightness']:.1f}"
            + (f" | motion delta {diff:.1f}" if diff is not None else ""),
            fill="#b5c7df",
        )
    sheet.save(directory / "visual-ai-contact-sheet.jpg", quality=90, subsampling=0)

    lines = [
        "# Chaos Survival — 15 real AI-camera screenshots",
        "",
        "Source: an authenticated Roblox Studio client/server session; "
        "not a public-server recording or an Android device.",
        "",
        f"- Frames: 15 / 15; unique hashes: {len(hashes)}",
        f"- Visually changing adjacent pairs: {moving_frames} / 14",
        "- Real PNGs are separate artifacts; montage is a resized contact sheet.",
        "- The warnings below are heuristic flags, not confirmed defects.",
        "",
        "## Automated indicators",
        "",
        "| Image | Brightness | Center | Motion delta | Flags |",
        "|---|---:|---:|---:|---|",
    ]
    for record in records:
        delta = record["difference_from_previous"]
        lines.append(
            f"| {record['index']:02d} | {record['mean_brightness']:.1f}"
            f" | {record['center_brightness']:.1f} | "
            f"{delta if delta is not None else '—'} | "
            f"{', '.join(record['warnings']) or '—'} |"
        )
    lines.extend([
        "",
        "## Manual QA still required",
        "",
        "Inspect occluding AI bodies, vote cards, overexposed decals/neon, "
        "hazard readability and traversable platforms in the full-res PNGs. "
        "Comparisons with true Android play remain distinct.",
    ])
    (directory / "visual-ai-audit.md").write_text(
        "\n".join(lines) + "\n", encoding="utf-8"
    )
    return data


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: analyze-visual-ai.py <capture-directory>")
    result = inspect(Path(sys.argv[1]))
    print(json.dumps({
        "status": "AUDIT_CREATED",
        "frames": result["frame_count"],
        "unique": result["unique_frame_hashes"],
        "motion_pairs": result["changing_frame_pairs"],
        "warnings": result["visual_warnings"],
    }, ensure_ascii=False))
