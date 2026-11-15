#!/usr/bin/env python3
"""Regression test for the five-arena historical 3D priority report."""
from __future__ import annotations

import contextlib
import csv
import io
import unittest
from pathlib import Path

from report_remaining_3d_priorities import ARENAS, MATRIX, main


class HistoricalPriorityReportTest(unittest.TestCase):
    def test_arena_totals_are_printed_and_match_the_matrix(self) -> None:
        with MATRIX.open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            main()
        lines = output.getvalue().splitlines()
        self.assertIn(
            "Historical improvement candidates by arena (P0/P1/P2 only):",
            lines,
        )
        for arena in ARENAS:
            expected = sum(
                int(row[f"{arena}_raw_natives"])
                for row in rows
                if row["priority"] in {"P0", "P1", "P2"}
            )
            self.assertIn(f"{arena:12} {expected:,}", lines)
        self.assertIn("NOT live primitives remaining", output.getvalue())


if __name__ == "__main__":
    unittest.main()
