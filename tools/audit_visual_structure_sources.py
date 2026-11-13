#!/usr/bin/env python3
"""Reproducible source census for Chaos Survival, NOT a rendered-object count.

This exhaustively indexes every server/client/shared Lua source, approved
original 3D model registry entry, imported asset module and cooperative
visual budget owner. Actual instance totals are measured in real Roblox
Engine separately: the Luau code contains loops, variant branches, runtime
streaming and graphics LOD which static regex cannot count truthfully.
"""
from __future__ import annotations

from collections import Counter, defaultdict
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "build" / "visual-structure-source-census.json"
LUA_ROOT = ROOT / "src"
REGISTRY = json.loads(
    (ROOT / "assets/source/roblox-asset-registry.json").read_text(encoding="utf8")
)
RULES = (ROOT / "src/shared/VisualBudgetRules.lua").read_text(encoding="utf8")
SCENERY = (ROOT / "src/client/scenery-lod.client.lua").read_text(encoding="utf8")
assert REGISTRY["models"], "Approved source registry is empty"

approved = [model for model in REGISTRY["models"]
            if model.get("moderation") == "Approved"]
unapproved = [model for model in REGISTRY["models"]
              if model.get("moderation") != "Approved"]
ids = Counter(str(m["asset_id"]) for m in REGISTRY["models"])
assert len(ids) == len(REGISTRY["models"]), "Duplicated creator model ID"
assert not unapproved, "Unapproved model present: " + repr(unapproved[:3])
assert all(v == 1 for v in ids.values())

# Exact source *call sites*. A 3-line factory invoked 300 times counts as
# ONE constructor site, never 300 game structures.
constructor = re.compile(
    r'\bInstance\s*\.\s*new\s*\(\s*["\x27]'
    r'(Part|WedgePart|CornerWedgePart|TrussPart|MeshPart|UnionOperation|'
    r'Folder|Model|PointLight|SpotLight|SurfaceLight|ParticleEmitter|Beam|Trail)'
    r'["\x27]\s*\)'
)
source_files = sorted(LUA_ROOT.rglob("*.lua"))
classes = Counter()
by_area = defaultdict(Counter)
top_constructor_sites = []
file_rows = []
for path in source_files:
    code = path.read_text(encoding="utf8")
    sites = Counter(constructor.findall(code))
    classes.update(sites)
    area = path.relative_to(LUA_ROOT).parts[0]
    by_area[area].update(sites)
    all_shapes = sum(sites[k] for k in (
        "Part", "WedgePart", "CornerWedgePart", "TrussPart", "MeshPart",
        "UnionOperation"))
    if all_shapes:
        top_constructor_sites.append(
            [str(path.relative_to(ROOT)), all_shapes, dict(sorted(sites.items()))]
        )
    file_rows.append({
        "path": str(path.relative_to(ROOT)),
        "constructor_sites": dict(sorted(sites.items())),
        "lua_bytes": path.stat().st_size,
    })
top_constructor_sites.sort(key=lambda x: (-x[1], x[0]))

# Enumerate all explicitly linked 3D client owner modules, source IDs,
# registered local folders, and missing accounting coverage.
ledger_begin = RULES.index("VisualBudgetRules.LocalFolders = {")
ledger_end = RULES.index("\n}", ledger_begin)
ledger = RULES[ledger_begin:ledger_end]
registered = re.findall(r'^\s*["\x27]([^"\x27]+Local)["\x27]\s*,',
                        ledger, re.MULTILINE)
assert len(set(registered)) == len(registered), "LocalFolders has duplicates"
owner_patterns = re.compile(
    r'\b([A-Za-z_][\w]*)\.Name\s*=\s*["\x27]([^"\x27]+Local)["\x27]'
)
owner_modules = defaultdict(list)
nonvisual_audio_owners = []
direct_workspace_transient_parts = []
client_3d = []
unbudgeted = []
approval_names = {str(m["asset_id"]): str(m.get("name", ""))
                  for m in approved}
for path in sorted((ROOT / "src/client").glob("*.lua")):
    code = path.read_text(encoding="utf8")
    name = path.name
    if name.endswith("MeshKit.lua") or name.endswith("3DKit.lua"):
        candidate_ids = sorted({id_ for id_ in re.findall(r'\b\d{12,16}\b',code)
                                if id_ in approval_names})
        linked = "require(script.Parent." + name.removesuffix(".lua") + ")" in SCENERY
        has_sync = bool(re.search(r'function\s+(?:Kit|Rules|[\w]+)\.sync\s*\(',code))
        client_3d.append({
            "module":name,
            "approved_source_ids":candidate_ids,
            "approved_source_names":[approval_names[x] for x in candidate_ids],
            "linked_in_scenery_lod":linked,
            "has_sync":has_sync,
        })
    for match in owner_patterns.finditer(code):
        var, owner = match.groups()
        nearby = code[match.end():match.end()+1500]
        if re.search(r'\b'+re.escape(var)+r'\.Parent\s*=\s*workspace\b',
                     nearby):
            before_name=code[max(0,match.start()-200):match.start()]
            folder_decl=re.search(
                r'\b'+re.escape(var)+r'\s*=\s*Instance\.new'
                r'\(\s*["\x27]Folder["\x27]\s*\)',before_name)
            if not folder_decl:
                # Live pickup ripple Parts are not persistent 3D owners.
                direct_workspace_transient_parts.append({
                    "owner":owner,"module":name
                })
            elif owner=="ArenaSpatialAudioLocal":
                # Sound-only owner has invisible spatial audio anchors.
                # Do not interpret its invisible Parts as missing meshes.
                nonvisual_audio_owners.append({
                    "owner":owner,"module":name
                })
            else:
                owner_modules[owner].append(name)
                if owner not in registered:
                    unbudgeted.append({"owner":owner,"module":name})

# An approved four-tower exterior mesh must remain eligible when the
# original playable floor contracts. Reject fabricated expansions and
# preserve the unchanged, signed exterior boundary; this is one of the
# 32 historically fragile outboard MeshKit checks.
exterior_towers = (ROOT / "src/client/ApprovedExteriorTowerMeshKit.lua").read_text(
    encoding="utf8")
assert "local function authenticBase(base,arena)" in exterior_towers
for clause in (
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    'base.Size.X<=sx+.2 and base.Size.Z<=sz+.2',
    'if not authenticBase(base,arena) then removeAll() end',
    'base:GetPropertyChangedSignal("Size"):Connect(checkBase)',
    'base:GetPropertyChangedSignal("CanCollide"):Connect(checkBase)',
    'base.AncestryChanged:Connect(checkBase)',
    'math.min(base:GetAttribute("OriginalSizeX"),',
    'local QUALITIES = {Low=1,Medium=2,High=4}',
    'if stress==1 then cap=math.floor(cap*.5) end',
):
    assert clause in exterior_towers,("exterior tower shrink safety",clause)
assert 'base.Size.X<318 or base.Size.Z<318' not in exterior_towers
assert 'base.Size.X<318' not in exterior_towers
assert 'base.Size.Z<318' not in exterior_towers
print("PASS signed original perimeter for four exterior 3D towers during shrink")

# Four perimeter stations also stay on their creator-authored OUTER
# footprint while the playable arena shrinks. Two original seven-mesh
# wings may replace their WedgeParts even on Low, without changing caps,
# proximity, colliders, or disappearing when the floor becomes <318.
perimeter_armor = (ROOT / "src/client/ApprovedPerimeterArmorMeshKit.lua").read_text(
    encoding="utf8")
for clause in (
    'local function authenticBase(base, arena)',
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    'base.Size.X <= sx + .2 and base.Size.Z <= sz + .2',
    'if not authenticBase(base, arena)',
    'if not authenticBase(base,arena)',
    'base:GetPropertyChangedSignal("Size"):Connect(invalidBase)',
    'base:GetPropertyChangedSignal("Anchored"):Connect(invalidBase)',
    'base:GetAttributeChangedSignal(attribute):Connect(invalidBase)',
    'local CAPS = {Low=1,Medium=1,High=3}',
    'if stress==1 then cap=math.floor(cap*.5) end',
    'if stress>=2 then cap=0 end',
    'if count ~= 7 then return nil end',
):
    assert clause in perimeter_armor,("perimeter armor shrink safety",clause)
assert 'base.Size.X<318' not in perimeter_armor
assert 'base.Size.Z<318' not in perimeter_armor
assert 'base.Size.X < 318' not in perimeter_armor
assert 'base.Size.Z < 318' not in perimeter_armor
print("PASS four authentic perimeter armor stations remain 3D-eligible after shrink")

# Every fixed outboard perimeter station kit must follow signed MapBuilder
# OriginalSizeX/Z through a legitimate Shrinking Arena contraction. Source
# eligibility is NOT the same as actual rendered coverage on a client.
perimeter_shrink_kits = (
    "ApprovedPerimeterStructuresMeshKit",
    "ApprovedPerimeterButtressMeshKit",
    "ApprovedPerimeterStationDeckInlayMeshKit",
    "ApprovedPerimeterMachineryMeshKit",
    "ApprovedPerimeterRotorMeshKit",
    "ApprovedPerimeterVariantApexMeshKit",
)
for module in perimeter_shrink_kits:
    code = (ROOT / "src/client" / (module + ".lua")).read_text(encoding="utf8")
    for clause in (
        "local function authenticBase(base, arena)",
        'base:GetAttribute("OriginalSizeX")',
        'base:GetAttribute("OriginalSizeZ")',
        "base.Size.X <= sx + .2 and base.Size.Z <= sz + .2",
        "not authenticBase(base, arena)",
    ):
        assert clause in code,(module,clause)
    assert not re.search(r'base\.Size\.[XZ]\s*<\s*318',code),module
print("PASS six additional original perimeter station 3D families survive shrink")

# Three additional fixed, outboard 3D families must not be invalidated by
# the live gameplay floor contracting. These assertions inspect the actual
# client scripts (no fake mesh source, runtime FPS or render claims).
fixed_scenery_guards = {
    "ApprovedFoundationChassisMeshKit": (
        "local function authenticBase(base, arena)",
        "not authenticBase(base, arena)",
        'base:GetAttributeChangedSignal("OriginalSizeX")',
        'base:GetAttributeChangedSignal("OriginalSizeZ")',
        'base:GetPropertyChangedSignal("Size"):Connect(revokeInvalidBase)',
    ),
    "ApprovedCinematicHorizonMeshKit": (
        "local function authenticBase(base, arena)",
        "local originalSize = authenticBase(base, base and base.Parent)",
        "Rules.offset(originalSize,variant,index)",
        'base:GetAttributeChangedSignal("OriginalSizeX")',
        'base:GetAttributeChangedSignal("OriginalSizeZ")',
    ),
    "ApprovedAtmosphereColumnsMeshKit": (
        "local function originalDimensions(base, arena)",
        "local originalX, originalZ = originalDimensions(base, arena)",
        "(originalX * 0.5 + 10)",
        "(originalZ * 0.5 + 10)",
        'base:GetAttributeChangedSignal("OriginalSizeX")',
        'base:GetAttributeChangedSignal("OriginalSizeZ")',
    ),
    "ApprovedAtmosphereCrownMeshKit": (
        "local function authenticBase(base, arena)",
        "if not authenticBase(base, arena)",
        'base:GetAttributeChangedSignal("OriginalSizeX")',
        'base:GetAttributeChangedSignal("OriginalSizeZ")',
    ),
    "ApprovedOrbitalSignatureRingMeshKit": (
        "local function originalDimensions(base, arena)",
        "local originalX,originalZ=originalDimensions(base,arena)",
        "local origin=base.Position+Vector3.new(originalX*.24,",
        "-(originalZ*.5+66)",
        'base:GetAttributeChangedSignal("OriginalSizeX")',
        'base:GetAttributeChangedSignal("OriginalSizeZ")',
    ),
    "ApprovedMidgroundSkylineMeshKit": (
        "local function originalFootprint(base, arena)",
        "local originalX, originalZ = originalFootprint(base, base and base.Parent)",
        "(originalX + body.Size.X)",
        "(originalZ + body.Size.Z)",
        'base:GetAttributeChangedSignal("OriginalSizeX")',
        'base:GetAttributeChangedSignal("OriginalSizeZ")',
    ),
}
for module, clauses in fixed_scenery_guards.items():
    code = (ROOT / "src/client" / (module + ".lua")).read_text(
        encoding="utf8")
    for clause in (
        'base:GetAttribute("OriginalSizeX")',
        'base:GetAttribute("OriginalSizeZ")',
        *clauses,
    ):
        assert clause in code, (module, clause)
    assert (
        "base.Size.X <= sx + .2 and base.Size.Z <= sz + .2" in code
        or "base.Size.X > sx + .2 or base.Size.Z > sz + .2" in code
    ), (module, "reject original-footprint expansion")
    assert not re.search(r'base\.Size\.[XZ]\s*<\s*(?:318|160)', code), module
print("PASS six fixed outboard 3D families remain eligible through arena shrink")

# This is a risk inventory, not a count of defective objects: checking a
# 320-stud playable floor is correct for physical platforms, but incorrect
# for outboard static scenery during Shrinking Arena.
live_floor_checks = []
for path in source_files:
    code = path.read_text(encoding="utf8")
    if re.search(r'base\.Size\.[XZ]\s*[<]=?\s*318', code):
        live_floor_checks.append(str(path.relative_to(ROOT)))
outer_scene_checks = [p for p in live_floor_checks
    if p.startswith("src/client/") and
    ("MeshKit" in p or "3DKit" in p)]
linked_kits = [x for x in client_3d if x["linked_in_scenery_lod"]]
unlinked_kits = [x for x in client_3d if not x["linked_in_scenery_lod"]]

assert not unbudgeted, f"Workspace owner outside VisualBudgetRules: {unbudgeted}"
assert len(registered) >= 115
assert len(source_files) >= 300
assert len(approved) >= 100

report = {
    "schema": "visual-structure-source-census/1",
    "scope": "all src/**/*.lua + approved creator registry; static call sites only",
    "methodological_warning":
        "Constructor call-site counts do NOT equal created instance counts, "
        "unreplaced geometry, or simultaneous on-screen objects. "
        "Source coverage is not Android runtime residency.",
    "lua_files": len(source_files),
    "approved_original_3d_models": len(approved),
    "unapproved_registry_models": len(unapproved),
    "constructor_sites_total": dict(sorted(classes.items())),
    "constructor_sites_by_code_area":
        {k:dict(sorted(v.items())) for k,v in sorted(by_area.items())},
    "largest_source_factory_site_files": top_constructor_sites[:35],
    "direct_workspace_local_folders_registered": len(registered),
    "direct_workspace_local_owners_detected": len(owner_modules),
    "local_owner_duplicates":
        {k:v for k,v in owner_modules.items() if len(v)>1},
    "local_owner_unbudgeted": unbudgeted,
    "nonvisual_audio_owners_excluded": nonvisual_audio_owners,
    "direct_workspace_transient_parts_not_meshkit_folders":
        direct_workspace_transient_parts,
    "meshkit_3dkit_files": len(client_3d),
    "meshkit_3dkit_lod_linked": len(linked_kits),
    "meshkit_3dkit_not_directly_linked": len(unlinked_kits),
    "meshkit_3dkit_with_approved_id": sum(
        1 for x in client_3d if x["approved_source_ids"]),
    "static_320_floor_guard_files": len(live_floor_checks),
    "static_320_floor_guard_outboard_meshkits":
        len(outer_scene_checks),
    "static_320_floor_guard_outboard_paths": outer_scene_checks,
    "meshkits": client_3d,
    "local_owner_modules": dict(sorted(owner_modules.items())),
}
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",
                  encoding="utf8")
summary = {
    k:report[k] for k in (
        "lua_files", "approved_original_3d_models",
        "direct_workspace_local_folders_registered",
        "direct_workspace_local_owners_detected",
        "meshkit_3dkit_files", "meshkit_3dkit_lod_linked",
        "meshkit_3dkit_with_approved_id",
        "static_320_floor_guard_outboard_meshkits"
    )
}
print("P4_STRUCTURE_SOURCE_CENSUS",json.dumps(summary,sort_keys=True))
print("P4_STRUCTURE_FACTORY_SITES",
      json.dumps(report["constructor_sites_total"],sort_keys=True))
print("P4_STRUCTURE_OUTBOARD_FLOOR_GUARD_FILES",
      json.dumps(outer_scene_checks,ensure_ascii=False))
print("P4_STRUCTURE_SOURCE_REPORT",OUTPUT.relative_to(ROOT))
