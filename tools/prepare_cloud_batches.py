#!/usr/bin/env python3
"""Build fewer real-Roblox execution tasks without skipping engine assertions.

Lest Cloud launches one remote execution task PER .spec.luau file. The project
has >70 engine files; concurrent PR workflows exceeded owner-wide Open Cloud
limits with HTTP 429. Generate scoped, inline composite specs from the
existing explicit shard manifest. Each test remains an actual engine test.
Source files stay unchanged, and this generator runs after the original
1-to-1 shard-coverage verification in CI.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import tomllib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHARDS = ("gameplay", "matrix", "core_a", "core_b1", "core_b2")
MAX_FILES_PER_BATCH = 4
MAX_SOURCE_BYTES = 105_000
TERMINATOR = re.compile(r"\nreturn\s+nil\s*\Z")


def inline_source(path: pathlib.Path) -> str:
    raw = path.read_text(encoding="utf-8").replace("\r\n", "\n")
    if not TERMINATOR.search(raw):
        raise ValueError(f"{path}: engine specs must end with a plain 'return nil'")
    body = TERMINATOR.sub("", raw).strip()
    # Every file gets an independent lexical scope, so local names and
    # test-specific helpers do not leak into the next imported spec.
    return "do\n" + body + "\nend\n"


def batch_specs(entries: list[tuple[str, str]]) -> list[list[tuple[str, str]]]:
    batches: list[list[tuple[str, str]]] = []
    batch: list[tuple[str, str]] = []
    size = 0
    for name, script in entries:
        encoded_size = len(script.encode("utf-8"))
        if encoded_size > MAX_SOURCE_BYTES:
            raise ValueError(f"Single spec exceeds Open Cloud source cap: {name}")
        if batch and (len(batch) >= MAX_FILES_PER_BATCH
                      or size + encoded_size > MAX_SOURCE_BYTES):
            batches.append(batch)
            batch, size = [], 0
        batch.append((name, script))
        size += encoded_size
    if batch:
        batches.append(batch)
    return batches


def generate(source_config: pathlib.Path, output_config: pathlib.Path) -> None:
    data = tomllib.loads(source_config.read_text(encoding="utf-8"))
    batches_by_shard: dict[str, list[str]] = {}
    seen: set[str] = set()

    # Generate root-level spec filenames next to originals to preserve all
    # ../ and ../../ require paths used by existing engine specs.
    for shard in SHARDS:
        files = data["suites"][shard]["include"]
        entries = []
        for relative in files:
            if relative in seen:
                raise ValueError(f"Spec appears in multiple shards: {relative}")
            seen.add(relative)
            spec = ROOT / relative
            if not spec.is_file() or spec.parent != ROOT / "tests" / "engine":
                raise ValueError(f"Not a repository engine spec: {relative}")
            entries.append((relative, inline_source(spec)))

        batched = []
        for index, members in enumerate(batch_specs(entries), start=1):
            filename = f"tests/engine/__ci_{shard}_{index:02d}.spec.luau"
            output_path = ROOT / filename
            if output_path.exists():
                raise ValueError(f"Refusing to overwrite existing spec: {output_path}")
            parts = [
                "--!strict",
                "-- Generated for CI. Do not commit; the original specs own the tests.",
                f"-- Shard {shard} / batch {index}",
            ]
            for original, script in members:
                parts.append(f"-- BEGIN {original}")
                parts.append(script.rstrip())
                parts.append(f"-- END {original}")
            parts.append("return nil")
            output_path.write_text("\n".join(parts) + "\n", encoding="utf-8")
            batched.append(filename)
            print(f"{filename}: {len(members)} original specs")
        batches_by_shard[shard] = batched

    actual = {p.relative_to(ROOT).as_posix()
              for p in (ROOT / "tests" / "engine").glob("*.spec.luau")
              if not p.name.startswith("__ci_")}
    if seen != actual:
        raise ValueError(
            f"Coverage mismatch: missing={sorted(actual - seen)}, "
            f"extra={sorted(seen - actual)}"
        )

    # Keep the exact same five named suites and target Roblox universe/place,
    # only replacing 73 original spec entries with fewer generated specs.
    output_lines = []
    for shard in SHARDS:
        output_lines.append(f"[suites.{shard}]")
        output_lines.append("include = [")
        for name in batches_by_shard[shard]:
            output_lines.append(f'  "{name}",')
        output_lines.extend(['  ]', 'backend = "cloud"', 'default = false', ''])

    place = data["place"]
    output_lines.extend([
        "[place]",
        f'universe_id = {place["universe_id"]}',
        f'place_id = {place["place_id"]}',
        "",
        "[settings]",
        'backend = "native"',
        f'timeout_ms = {data["settings"]["timeout_ms"]}',
        "",
    ])
    output_config.write_text("\n".join(output_lines), encoding="utf-8")
    print(f"Real-engine task count: {sum(len(x) for x in batches_by_shard.values())} "
          f"(was {len(seen)}); no spec omitted.")


def self_test() -> None:
    source = "--!strict\nlocal X = 1\nreturn nil\n"
    import tempfile
    with tempfile.TemporaryDirectory() as directory:
        p = pathlib.Path(directory) / "test.spec.luau"
        p.write_text(source, encoding="utf-8")
        script = inline_source(p)
        assert "do\n" in script and "local X = 1" in script
        assert "return nil" not in script
        entries = [(str(i), script) for i in range(9)]
        batches = batch_specs(entries)
        assert [len(x) for x in batches] == [4, 4, 1]
        p.write_text("local x = true\nreturn false\n", encoding="utf-8")
        try:
            inline_source(p)
        except ValueError:
            pass
        else:
            raise AssertionError("Unsafe source terminator not rejected")
    print("Cloud spec composer self-test passed.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--source", default="lest.ci.toml")
    parser.add_argument("--output", default="lest.ci-batched.toml")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    else:
        generate(ROOT / args.source, ROOT / args.output)
