#!/usr/bin/env python3
"""Report historical primitive counts without confusing them with live replacements.

The audit matrix records five arena snapshots, not live resident meshes.
Run: python3 tools/report_remaining_3d_priorities.py
"""
from __future__ import annotations

import csv
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MATRIX = ROOT / "docs/audit/remaining-3d-priority-matrix-2026-11-13.csv"
ARENAS = ("classic", "towers", "crossroads", "orbital", "harbor")


def main() -> None:
    by_priority = defaultdict(int)
    by_arena = defaultdict(int)
    candidates = []
    with MATRIX.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    if not rows:
        raise SystemExit("Empty visual census")
    for row in rows:
        family = row["owner_family"]
        counts = [int(row[f"{arena}_raw_natives"]) for arena in ARENAS]
        total = int(row["five_world_raw_natives"])
        if sum(counts) != total:
            raise SystemExit(f"{family}: per-arena count does not match total")
        if total < 0:
            raise SystemExit(f"{family}: negative count")
        priority = row["priority"]
        by_priority[priority] += total
        if priority in ("P0", "P1", "P2"):
            for arena, count in zip(ARENAS, counts):
                by_arena[arena] += count
        if priority in ("P0", "P1", "P2"):
            candidates.append((priority, -total, family, row["coverage_status"]))
    print("Historical 3D visual census (raw natives, NOT live primitives remaining)")
    print(f"Families: {len(rows)}")
    for priority in ("P0", "P1", "P2", "CONSERVER", "AUDITER"):
        print(f"{priority}: {by_priority[priority]:,}")
    print("\nHistorical improvement candidates by arena (P0/P1/P2 only):")
    for arena in ARENAS:
        print(f"{arena:12} {by_arena[arena]:,}")
    print("\nPriority-ranked families (historical exposure, not unfinished count):")
    for priority, neg_total, family, coverage in sorted(candidates):
        print(f"{priority} {family:18} {-neg_total:5}  {coverage}")
    print("\nDo not derive a completion percentage from this ledger: approved")
    print("source availability, LOD, streaming and fallback affect live coverage.")


if __name__ == "__main__":
    main()
