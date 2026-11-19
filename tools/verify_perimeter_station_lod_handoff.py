#!/usr/bin/env python3
"""Guard the server/client handoff for premium perimeter-station LOD models."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
builder = (ROOT / "src/server/MapBuilder.lua").read_text(encoding="utf-8")
start = builder.index("local function addPerimeterStations(")
end = builder.index("\nlocal function exteriorPart(", start)
station = builder[start:end]

# The client kits authenticate native Part geometry, not a single server MeshPart.
# Count source declarations once: each named side is instantiated twice.
native_slots = {
    "LeftButtress": "RightButtress",
    "CompressorPodL": "CompressorPodR",
    "IntakeTurbineL": "IntakeTurbineR",
}
for left, right in native_slots.items():
    expression = re.escape('"' + left + '"') + r'\s+or\s+' + re.escape('"' + right + '"')
    assert re.search(expression, station), (left, right)

def declaration(name: str) -> str:
    marker = '"' + name + '"'
    pos = station.index(marker)
    return station[pos:station.index("\n        ", pos + len(marker))]

# Match the full piece invocation through the next statement to catch
# accidental profile arguments added to native handoff slots.
for name in ("LeftButtress", "CompressorPodL", "IntakeTurbineL", "GeneratorRotor", "CoreHousing"):
    pos = station.index('"' + name + '"')
    tail = station[pos:pos + 440]
    match = re.search(r'\bprofiles\.[A-Za-z]+', tail.split(')\n', 1)[0])
    assert match is None, f"{name}: server mesh blocks premium client LOD"

for kit in ("ApprovedPerimeterButtressMeshKit", "ApprovedPerimeterMachineryMeshKit", "ApprovedPerimeterRotorMeshKit"):
    client = (ROOT / "src/client" / (kit + ".lua")).read_text(encoding="utf-8")
    assert 'IsA("Part")' in client, kit
    assert "Transparency" in client, kit

assert "\\n        --" not in station, "Literal escaped newline in Luau comment"
print("Perimeter station native-to-premium LOD handoff: OK")
