#!/usr/bin/env python3
"""Remove comment text from the disposable Lest checkout before bundling.

Use Luau's parser spans so quoted strings, interpolation and long literals
keep their original bytes. Preserve each newline for engine stack traces.
"""
import argparse
import json
import re
import subprocess
from pathlib import Path

LOCATION = re.compile(r"(\d+),(\d+) - (\d+),(\d+)")


def compact(path: Path, luau_ast: Path) -> tuple[int, int]:
    source = path.read_bytes()
    ast = json.loads(subprocess.check_output([luau_ast, path]))
    if ast.get("errors"):
        raise ValueError(f"Cannot compact invalid Luau source: {path}")

    line_starts = [0, *(match.end() for match in re.finditer(b"\n", source))]
    spans = []
    for comment in ast["commentLocations"]:
        start_line, start_col, end_line, end_col = map(
            int, LOCATION.fullmatch(comment["location"]).groups()
        )
        start = line_starts[start_line] + start_col
        end = line_starts[end_line] + end_col
        if source[start:start + 2] != b"--":
            raise ValueError(f"Invalid Luau comment span in {path}")
        if start_col == 0 and source[start:start + 3] == b"--!":
            continue  # Keep Luau compiler directives.
        spans.append((start, end))

    result = bytearray(source)
    for start, end in sorted(spans, reverse=True):
        original = source[start:end]
        newline_count = original.count(b"\n")
        # A same-line block comment may separate two lexical tokens.
        result[start:end] = b"\n" * newline_count if newline_count else b" "
    if len(result) != len(source):
        path.write_bytes(result)
    return len(source), len(result)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("luau_ast", type=Path)
    parser.add_argument("directories", nargs="+", type=Path)
    args = parser.parse_args()
    before = after = 0
    for directory in args.directories:
        for path in sorted(directory.rglob("*")):
            if path.suffix not in {".lua", ".luau"} or not path.is_file():
                continue
            original, compacted = compact(path, args.luau_ast)
            before += original
            after += compacted
    print(f"Compacted Luau inputs for Cloud tasks: {before} -> {after} bytes")


if __name__ == "__main__":
    main()
