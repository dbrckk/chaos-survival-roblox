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

# Verify the final argument of each native slot call, not a fixed-width
# text window (which could accidentally include the next mesh-backed piece).
# All five declarations terminate with a literal opacity and no profile.
native_calls = {
    "LeftButtress": r'theme\\.Structure,\\s*0\\.06\\s*\\)',
    "CoreHousing": r'theme\\.Detail:Lerp\\(theme\\.Structure,\\s*0\\.35\\),\\s*0\\.06\\s*\\)',
    "CompressorPodL": r'theme\\.Structure:Lerp\\(theme\\.Detail,\\s*0\\.36\\),\\s*0\\.04\\s*\\)',
    "IntakeTurbineL": r'Enum\\.Material\\.Metal,\\s*theme\\.Detail,\\s*0\\.08\\s*\\)',
    "GeneratorRotor": r'Enum\\.Material\\.Metal,\\s*theme\\.Detail,\\s*0\\.08\\s*\\)',
}
for name, ending in native_calls.items():
    pos = station.index('"' + name + '"')
    assert re.search(ending, station[pos:pos + 450]), (
        name, "missing native Part ending; premium client LOD may be blocked"
    )

for kit in ("ApprovedPerimeterButtressMeshKit", "ApprovedPerimeterMachineryMeshKit", "ApprovedPerimeterRotorMeshKit"):
    client = (ROOT / "src/client" / (kit + ".lua")).read_text(encoding="utf-8")
    assert 'IsA("Part")' in client, kit
    assert "Transparency" in client, kit

assert "\\n        --" not in station, "Literal escaped newline in Luau comment"
print("Perimeter station native-to-premium LOD handoff: OK")
