#!/usr/bin/env python3
"""Fail closed if high-cost mobile visual owners regain High-before-FPS fallbacks.

The device-level initial profile is Medium on touch, High on desktop. Gameplay
hazards and server-authoritative state are not changed by this guard.
"""
from pathlib import Path
import re

OWNERS = (
    "arena-aerial-survey",
    "arena-hero-scenery",
    "arena-hero-motion",
    "arena-focal-lighting",
    "arena-lighting",
    "arena-ambient-props",
    "arena-cinematic-depth",
    "arena-surface-detail",
    "arena-surface-relief",
    "arena-understructure",
    "arena-service-props",
    "arena-silhouette-breakup",
    "arena-platform-identity",
    "arena-edge-profile",
    "arena-signatures",
    "arena-midground-mass",
    "arena-architectural-details",
    "arena-navigation-language",
    "arena-cinematic-disaster-atmosphere",
    "world-polish",
    "environment-depth",
    "tornado-visuals",
    "disaster-premium-vfx",
    "disaster-signature-vfx",
    "disaster-motion-vfx",
    "ambient-atmosphere",
    "character-polish",
    "character-motion-polish",
    "material-variation",
    "disaster-climax",
)

UNSAFE = re.compile(
    r"(?:VfxQuality|Quality)\.get\(\s*(?:localPlayer|player)"
    r":GetAttribute\([\"']VfxQualityTier[\"']\)\s*\)",
)

def main() -> None:
    for name in OWNERS:
        path = Path("src/client") / (name + ".client.lua")
        source = path.read_text(encoding="utf-8")
        assert "deviceTier(" in source, (
            f"{path}: no touch-aware initial quality for this visual owner"
        )
        assert "UserInputService.TouchEnabled" in source, (
            f"{path}: expected device classification, not desktop fallback"
        )
        assert not UNSAFE.search(source), (
            f"{path}: VfxQuality.get(player tier) defaults to High before "
            "Android adaptive quality has initialized"
        )
    print(f"Verified {len(OWNERS)} cosmetic controllers use safe initial quality.")


if __name__ == "__main__":
    main()
