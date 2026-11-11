#!/usr/bin/env python3
"""Prevent invisible local original-3D owners from bypassing visual budgets.

One source-level regression covering ALL direct-workspace Folder owners
created by local MeshKit / 3DKit modules, not just the eight fixed today.
No physical Studio/Android frame-time or gameplay validation is claimed.
"""
from __future__ import annotations

from collections import Counter
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
RULES=(ROOT/"src/shared/VisualBudgetRules.lua").read_text(encoding="utf8")
CLIENT=ROOT/"src/client"
begin=RULES.index("VisualBudgetRules.LocalFolders = {")
end=RULES.index("\n}",begin)
ledger=RULES[begin:end]
registered=re.findall(r'^\s*"([^"]+Local)",\s*$',ledger,re.MULTILINE)
counts=Counter(registered)
assert len(registered)>=115,("Unexpected visual census coverage",len(registered))
assert all(n==1 for n in counts.values()),{
    name:count for name,count in counts.items() if count!=1
}

EXPECTED={
    "ApprovedClassicBroadcastFinMeshKit.lua":
        "ApprovedClassicBroadcastFinLocal",
    "ApprovedCrossroadsEntrancePortalMeshKit.lua":
        "ApprovedCrossroadsEntrancePortalsLocal",
    "ApprovedCrossroadsOpenGantryMeshKit.lua":
        "ApprovedCrossroadsOpenGantryLocal",
    "ApprovedOrbitalReactorLandmarkMeshKit.lua":
        "ApprovedOrbitalReactorLandmarksLocal",
    "ApprovedPrimarySkylineMeshKit.lua":
        "ApprovedPrimarySkylineLocal",
    "ApprovedSkylineDepthMeshKit.lua":
        "ApprovedSkylineDepthLocal",
    "ApprovedVariantIdentitySpineMeshKit.lua":
        "ApprovedOriginalIdentitySpinesLocal",
    "ApprovedVariantTowersLandmarkMeshKit.lua":
        "ApprovedTowersMachineryLocal",
}
DECLARATION=re.compile(
    r'\b(?:local\s+)?([a-zA-Z_][a-zA-Z_0-9]*)\s*=\s*'
    r'Instance\.new\(["\']Folder["\']\)')
observed={}
for source in sorted(CLIENT.glob("*.lua")):
    if not (source.name.endswith("MeshKit.lua")
            or source.name.endswith("3DKit.lua")):
        continue
    code=source.read_text(encoding="utf8")
    # Match only a literal named Folder with its actual Parent=workspace.
    # Do not confuse a nested child Folder or server-owned model with a
    # separate workspace root and accidentally double-count descendants.
    for declaration in DECLARATION.finditer(code):
        var=declaration.group(1)
        initialization=code[declaration.end():declaration.end()+1800]
        name=re.search(
            rf'\b{re.escape(var)}\.Name\s*=\s*["\']([^"\']+)["\']',
            initialization)
        parent=re.search(
            rf'\b{re.escape(var)}\.Parent\s*=\s*workspace\b',
            initialization)
        if name and parent and name.group(1).endswith("Local"):
            owner=name.group(1)
            observed.setdefault(owner,[]).append(source.name)
            assert owner in counts,(source.name,owner,
                "client MeshParts not counted in adaptive Android census")

# The existing authenticated structure owner can replace exactly TWO
# static perimeter cuboids on the ONE nearest Low-tier station.
# It must remain in the global Android Part census and return natives
# at first optional-VFX pressure tier, without AssetService client calls.
BUTTRESS=(CLIENT/"ApprovedPerimeterButtressMeshKit.lua").read_text()
assert 'local LIMITS = {Low = 1, Medium = 1, High = 4}' in BUTTRESS
assert 'local RANGE = {Low = 150, Medium = 185, High = 275}' in BUTTRESS
assert 'if stress == 1 then cap = math.floor(cap * .5) end' in BUTTRESS
assert 'if stress >= 2 then cap = 0 end' in BUTTRESS
assert 'local first, firstParts = fittedClone(source, left, APPROVED[variant])' in BUTTRESS
assert 'if not second then first:Destroy(); return end' in BUTTRESS
assert 'first.Parent = bucket' in BUTTRESS
assert 'second.Parent = bucket' in BUTTRESS
assert BUTTRESS.index('second.Parent = bucket') < BUTTRESS.index(
    'left.Transparency = 1')
assert 'right.Transparency = 1' in BUTTRESS
assert 'native.Transparency = alpha' in BUTTRESS
assert 'item.CastShadow = false' in BUTTRESS
assert 'item.CanCollide = false' in BUTTRESS
assert 'item.CanTouch = false' in BUTTRESS
assert 'item.CanQuery = false' in BUTTRESS
assert 'source:GetAttribute("Original3DAssetId") ~= approvedId' in BUTTRESS
assert 'source:GetAttribute("OwnerVerified") ~= true' in BUTTRESS
assert 'source:GetAttribute("OriginalLargeStructure3D") ~= true' in BUTTRESS
assert 'bucket.Name = "ApprovedPerimeterButtressesLocal"' in BUTTRESS
assert '"ApprovedPerimeterButtressesLocal"' in ledger
assert 'RenderStepped' not in BUTTRESS and 'Heartbeat' not in BUTTRESS
assert 'AssetService' not in BUTTRESS

for source,owner in EXPECTED.items():
    code=(CLIENT/source).read_text(encoding="utf8")
    assert owner in observed,(source,owner,
        "expected source-level direct workspace mesh owner not discovered")
    assert counts[owner]==1,(source,owner,
        "duplicate or missing LocalFolders entry")
    assert '"'+owner+'"' in code,source
    print("PASS counted real original 3D owner:",source,owner)

# The existing cooperative Android census owns every source, without
# adding another traversal or violating the single-pass owner ledger.
for snippet in (
    "function VisualBudgetRules.collect(root, cooperativeCheckpoint)",
    "for _, folderName in ipairs(VisualBudgetRules.LocalFolders) do",
    "local folder = root:FindFirstChild(folderName)",
    "for _, descendant in ipairs(folder:GetDescendants()) do",
    'descendant:IsA("BasePart")',
    'add(folderName, "Parts")',
    "checkpoint()",
):
    assert snippet in RULES,snippet
pressure=(CLIENT/"visual-budget-pressure.client.lua").read_text(
    encoding="utf8")
assert "VisualBudgetRules.collect(workspace" in pressure
assert "local CENSUS_SECONDS = 20" in pressure
assert "PressureRules.desired(" in pressure
assert "player:SetAttribute(\"OptionalVfxPressure\", nextValue)" in pressure

assert len(observed)>=8,observed
print("PASS",len(observed),"direct-workspace MeshKit/3DKit owners included")
print("PASS unique LocalFolders entries and shared cooperative Android census")
print("LIMIT: static coverage, not measured FPS or Studio screenshot validation")
