#!/usr/bin/env python3
"""Stamp the exact Git source into the runtime Roblox place before Rojo build.

This touches only the local checked-out workspace. It never publishes or
changes repository settings. SHA and channel come from the trusted workflow,
not from client-supplied Roblox data.
"""
import argparse
from pathlib import Path
import re

CHANNELS = {"CANDIDATE", "PUBLIC_PLAYTEST", "PRODUCTION", "STAGING"}
TARGET = Path("src/shared/BuildIdentity.lua")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sha", required=True)
    parser.add_argument("--channel", choices=sorted(CHANNELS), required=True)
    args = parser.parse_args()

    if not re.fullmatch(r"[a-f0-9]{40}", args.sha):
        parser.error("source SHA must be a complete lowercase 40-digit Git commit")
    if not TARGET.is_file():
        parser.error("BuildIdentity.lua is missing")

    TARGET.write_text(
        "-- Generated from a verified checkout just before Rojo build.\n"
        "-- Not a signature, certification or Roblox deployment receipt.\n"
        "return {\n"
        f'    SourceSha = "{args.sha}",\n'
        f'    Channel = "{args.channel}",\n'
        "}\n",
        encoding="utf-8",
    )
    print(f"Stamped build identity: {args.channel} {args.sha[:12]} (not published)")


if __name__ == "__main__":
    main()
