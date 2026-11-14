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
import csv
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

# A mounted district facade must never hide its original primitives if
# an unexpected clone descendant arrives between existing LOD samples.
district_facade = (ROOT / "src/client/PremiumDistrictFacadeMeshKit.lua").read_text(
    encoding="utf8")
for clause in (
    'clone.DescendantAdded:Connect(function(part)',
    'if part:IsA("BasePart") or part:IsA("LuaSourceContainer") then',
    'revokeIfMounted()',
    'if actual ~= #entry.pieces then return false end',
    'restoreNative(entry)',
):
    assert clause in district_facade, ("district facade integrity", clause)
print("PASS district approved 3D clone rejects foreign geometry/scripts")

# Genuine approved sidewall meshes can now cover all 16 buildings on
# healthy desktop High, without lifting mobile or GPU pressure ceilings.
sidewall = (ROOT / "src/client/ApprovedDistrictSidewallMeshKit.lua").read_text(
    encoding="utf8")
for clause in (
    "Medium = {count = 8, distance = 205, retention = 20}",
    "High = {count = 16, distance = 275, retention = 28}",
    "local TOUCH_CAP = {Low = 1, Medium = 3, High = 8}",
    "if tier == \"High\" then cap = math.min(cap, 5) end",
    'clone.DescendantAdded:Connect(function(part)',
    'if actual ~= 6 then return false end',
    'release(building)',
):
    assert clause in sidewall, ("district sidewall coverage/safety", clause)
print("PASS 16 desktop district sidewalls, unchanged touch and pressure caps")

# Both 3D district owners must revoke cloned art immediately if the
# creator's source loses approval, gains unexpected geometry or if one
# of five original native sidewalls mutates while hidden. A future
# camera/LOD tick is too late for trusted native fallback.
for clause in (
    'entry.sourceFolder:GetAttribute("OwnerVerified") ~= true',
    'entry.source:GetAttribute("OwnerVerified") ~= true',
    'entry.source:GetAttribute("CosmeticOnly") ~= true',
    'entry.source:GetAttribute("DistrictFacade3D") ~= true',
    'source.DescendantAdded:Connect(function(part)',
    'source:GetAttributeChangedSignal(attribute):Connect(function()',
    'entry.sourceFolder:GetAttributeChangedSignal(',
):
    assert clause in district_facade, ("district facade source revocation", clause)
for clause in (
    'entry.folder:GetAttribute("OwnerVerified") ~= true',
    'entry.source:GetAttribute("OwnerVerified") ~= true',
    'entry.source:GetAttribute("OriginalDistrictSidewallShell3D") ~= true',
    'source.DescendantAdded:Connect(function(part)',
    'folder:GetAttributeChangedSignal("OwnerVerified"):Connect(function()',
    'source:GetAttributeChangedSignal(attribute):Connect(function()',
    'local function releaseSource(source)',
    'for _, building in ipairs(owners) do release(building) end',
    'building.ChildRemoved:Connect(function(part)',
    'native:GetPropertyChangedSignal(property):Connect(reconcile)',
    'if not valid(entry, arena, district, base) then',
):
    assert clause in sidewall, ("district sidewall native/source revocation", clause)
for clause in (
    'local function revokeSource(source)',
    'for _, entry in ipairs(cohort) do dispose(entry) end',
    'source.DescendantRemoving:Connect(function(part)',
    'if part:IsA("MeshPart") then revokeSource(source) end',
    'clearMounted()',
):
    assert clause in district_facade, ("district shared facade cohort", clause)
print("PASS atomic source-cohort district 3D rollback and native restoration")

# Four additional desktop High route skins may hide real native panels
# only when the imported model covers the actual authoritative platform.
# Touch and stressed clients retain their previous bounded residency.
route_mesh = (ROOT / "src/client/PremiumRouteMeshKit.lua").read_text(
    encoding="utf8")
for clause in (
    "High = {decks = 16, bridges = 5, segments = 4, underdecks = 4,",
    'if touch == true and quality == "High" then',
    "deckCap = math.min(deckCap, 12)",
    'if quality == "High" then deckCap = math.min(deckCap, 9) end',
    'if quality == "High" then deckCap = math.min(deckCap, 5) end',
    "entry.panelCovered",
    "authenticDeck(entry,platform)",
):
    assert clause in route_mesh, ("desktop route mesh native fallback", clause)
print("PASS desktop 16-deck approved art with unchanged mobile/pressure caps")

# Approved underfloor geometry is fixed to the creator's initial
# footprint, not the contracting playable Base. Verify both owners.
for module in ("UnderstructureBeamMeshKit", "ArenaKeelMeshKit"):
    code = (ROOT / "src/client" / (module + ".lua")).read_text(
        encoding="utf8")
    for clause in (
        'base:GetAttribute("OriginalSizeX")',
        'base:GetAttribute("OriginalSizeZ")',
        'base.Size.X <= base:GetAttribute("OriginalSizeX") + .2',
        'base.Size.Z <= base:GetAttribute("OriginalSizeZ") + .2',
    ):
        assert clause in code, ("underfloor shrink mesh coverage", module, clause)
    assert "base.Size.X >= 318 and base.Size.X <= 322" not in code, module
print("PASS approved underfloor 3D remains eligible through valid shrink")

# Approved 7-MeshPart chassis now replace up to 16 original
# understructure beams on desktop High. Android stays at 12 and
# GPU-pressure caps reduce cosmetic models without affecting physics.
beam_mesh = (ROOT / "src/client/UnderstructureBeamMeshKit.lua").read_text(
    encoding="utf8")
scenery_lod = (ROOT / "src/client/scenery-lod.client.lua").read_text(
    encoding="utf8")
for clause in (
    "High = {count = 16, distance = 290, retention = 25}",
    'if touch == true and tier == "High" then cap = math.min(cap, 12) end',
    'if stress == 1 and tier == "High" then cap = math.min(cap, 8) end',
    'if stress >= 2 and tier == "High" then cap = math.min(cap, 4) end',
    'if count ~= 7 then return nil end',
    'if count ~= 7 then clone:Destroy(); return nil end',
):
    assert clause in beam_mesh, ("approved beam replacement coverage", clause)
assert '            isTouch)' in scenery_lod, "beam device budget not wired"
print("PASS approved 16-beam desktop cap and mobile pressure guard")

# Desktop Medium gets two more authenticated 3D chassis while mobile
# Medium stays at four. A tampered clone must restore its native fallback.
for clause in (
    "Medium = {count = 6, distance = 225, retention = 22}",
    'if touch == true and tier == "Medium" then cap = math.min(cap, 4) end',
    "clone.DescendantAdded:Connect(function(child)",
    "meshParts=meshParts",
    "local intact = #entry.meshParts == 7",
):
    assert clause in beam_mesh, ("medium understructure safety", clause)
print("PASS desktop Medium six-beam mesh residency and clone integrity")

# Two perimeter stations on desktop Medium can now replace four
# native primitive buttresses, while touch Medium retains one station.
buttress = (ROOT / "src/client/ApprovedPerimeterButtressMeshKit.lua").read_text(
    encoding="utf8")
for clause in (
    "local LIMITS = {Low = 1, Medium = 2, High = 4}",
    'if tier == "Medium" and touch then cap = 1 end',
    'model.DescendantAdded:Connect(function(item)',
    'item:IsA("LuaSourceContainer")',
):
    assert clause in buttress, ("approved perimeter buttress safety", clause)
print("PASS desktop Medium two-station 3D buttress residency")

# The two station buttress meshes must never become collidable or
# non-MeshPart while their native fallback remains hidden.
for clause in (
    'if not piece:IsA("MeshPart")',
    'or not piece.Anchored or not piece.Massless',
    'or piece.CanCollide or piece.CanTouch',
    'or piece.CanQuery then',
):
    assert clause in buttress, ("buttress runtime integrity guard", clause)
print("PASS authenticated nonphysical buttress clone integrity")

# Source-template injection and resized native station geometry must
# revoke an existing authenticated buttress replacement.
for clause in (
    'source.DescendantAdded:Connect(function(item)',
    'or math.abs(native.Size.X - 1.5) > .1',
    'or math.abs(native.Size.Y - 9) > .1',
    'or math.abs(native.Size.Z - 2) > .1',
):
    assert clause in buttress, ("buttress source/native revocation", clause)
print("PASS station geometry and source-template mutation revocation")

# Creator-owned rectangular/long 7-MeshPart rim art added 13 November.
# Unlike a full underside carapace, rim replacement may mask ONLY four
# WedgePart edges and must keep the native underframe and all hazard cues.
rim_server = (ROOT / "src/server/PremiumPlatformRimAssets.lua").read_text(
    encoding="utf8")
rim_client = (ROOT / "src/client/ApprovedPlatformRimMeshKit.lua").read_text(
    encoding="utf8")
rim_native = (ROOT / "src/client/PlatformNativeTrimReplacementKit.lua").read_text(
    encoding="utf8")
rim_finish = (ROOT / "src/client/PlatformFinishKit.lua").read_text(
    encoding="utf8")
rim_owner = (ROOT / "src/client/arena-platform-identity.client.lua").read_text(
    encoding="utf8")
rim_init = (ROOT / "src/server/init.server.lua").read_text(encoding="utf8")
for name, id_, tris in (
    ("platform_rim_rect", "131482590870627", 1760),
    ("platform_rim_long", "127617571835277", 2040),
):
    models = [m for m in REGISTRY["models"] if m["name"] == name]
    assert len(models) == 1 and str(models[0]["asset_id"]) == id_
    assert models[0]["moderation"] == "Approved"
    assert models[0]["triangles"] == tris
    assert len(models[0]["source_sha256"]) == 64
    assert models[0]["source"] == "tools/generate_original_platform_rims.py"
    assert id_ in rim_server and id_ in rim_client
for clause in (
    'require("./PremiumApprovedAssetImportGate")', "ImportGate.load",
    "OriginalMeshScenery.sanitize(raw)",
    "if count ~= 7 then return false end",
    "OriginalPlatformRim3D", "OwnerVerified", "CosmeticOnly",
):
    assert clause in rim_server, ("approved rim safe importer", clause)
for clause in (
    "if pieces~=7 then return nil end",
    "if #parts~=7 then copy:Destroy();return nil end",
    'edge:GetAttribute("OriginalStructuralBevel")~=true',
    'underside:GetAttribute("PremiumArchitecturalSurface")~=true',
    "if scale<.60 or coverLong<.90 or coverShort<.87",
    'piece:SetAttribute("OriginalPlatformRim3D",true)',
    'joint.Name="ChaosPlatformTrimWeld"',
    'piece.CanCollide=false', 'piece.CanTouch=false',
    'piece.CanQuery=false',
    "if stress>=2 or cap<=0",
):
    assert clause in rim_client, ("rim physical/LOD fallback", clause)
assert 'or kind == "rim"' in rim_native
assert 'active[id] == "carapace" or active[id] == "rim"' in rim_native
assert 'if id and (active[id] == "carapace" or active[id] == "cradle")' in rim_native
for clause in (
    "OriginalPlatformRimAxisSwap",
    "rimSwapped and ratioZ or ratioX",
    "rimSwapped and ratioX or ratioZ",
):
    assert clause in rim_finish
for clause in (
    "ApprovedPlatformRimMeshKit.selectVisibleDecks(",
    "ApprovedPlatformRimMeshKit.install(",
    'replacements[tostring(visualIndex)] = "rim"',
    "for _, piece in ipairs(rimPieces or {}) do",
    "LocalOriginalPlatformRimDeckCount",
    "watchRimTemplates(",
    "Rect = true, Long = true",
    'child.Name == "ApprovedPlatformRimTemplates"',
    "or nearRims[platform] ~= nil",
):
    assert clause in rim_owner, ("rim source-mounted visual ownership", clause)
assert "require(script.PremiumPlatformRimAssets)" in rim_init
assert "task.defer(PremiumPlatformRimAssets.start)" in rim_init
# Healthy desktop uses the SAME 4/8 existing approved slots over
# separated physical routes; Android and pressured clients remain nearest
# only. Source provenance is sampled once each rebuild, but rechecked at
# mounting so an invalidated source never masks native WedgeParts.
for clause in (
    'local cap=tier=="High" and (touch and 2 or 8)',
    'or tier=="Medium" and (touch and 1 or 4) or 1',
    'if touch~=true and stress==0 and tier~="Low" and count>2 then',
    'local foreground=math.min(count,tier=="High" and 3 or 2)',
    'local spacingCap=math.max(base.Size.X,base.Size.Z)*.65',
    'result[winner.deck]=winner.kind',
    'local boundsByKind={}',
    'local source,bounds=verified(kind)',
    'local kind=pickSource(deck,boundsByKind)',
    'if not source then return nil end',
):
    assert clause in rim_client, ("genuine rim spatial/source gate", clause)
assert "RenderStepped" not in rim_client and "Heartbeat:Connect" not in rim_client
print("PASS two genuine approved perimeter rim assets: PC four-sector spread, unchanged Android caps, cached epoch auth, shrink/native fallback")

# P4 large-deck bevel coverage must not regress to a hard-coded first-24
# physical platform gate. Only approved 18-stud, seven-mesh hulls may
# mask all four fully replicated, noncolliding server WedgeParts.
hull = (ROOT / "src/client/PremiumLargeDeckHullMeshKit.lua").read_text(
    encoding="utf8")
identity = (ROOT / "src/client/arena-platform-identity.client.lua").read_text(
    encoding="utf8")
for clause in (
    "function Kit.selectVisibleDecks(platforms, tier, base, cameraPoint,",
    'deck.Name ~= "Platform" .. tostring(n)',
    "n > 512",
    "local function nativeFallback(decor, deck)",
    'bevel:GetAttribute("OriginalStructuralBevel") ~= true',
    'frame:GetAttribute("PremiumArchitecturalSurface") ~= true',
    'local cap = tier == "High" and (touch and 3 or 6)',
    "if stress >= 2 or type(platforms)",
    "if not source or count ~= 7 then return chosen end",
    "and size.X*scale >= deck.Size.X*.80",
    "and size.Z*scale >= deck.Size.Z*.80",
    "if tier ~= \"Low\" and selected == false then return nil end",
    "function Kit.install(parent, deck, tier, index, selected, decor)",
    "or (decor ~= nil and not nativeFallback(decor, deck)) then",
    "or bounds.X < sx*.80 or bounds.Z < sz*.80",
    "or size.X*scale < sx*.80 or size.Z*scale < sz*.80",
):
    assert clause in hull, ("P4 approved large hull native replacement", clause)
assert "id%8==1" not in hull, "Low original hull cannot remain index-limited"
for clause in (
    "PremiumLargeDeckHullMeshKit.selectVisibleDecks(",
    "UserInputService.TouchEnabled, decor)",
    "folder, target, tier.Name, id, true, decor)",
    "or nearLargeDeckHulls[platform] == true, decor)",
    "or platform == lowHubDeck",
    "or nearLargeDeckHulls[platform] == true, decor)",
    'LocalOriginalLargeDeckHullMountedCount',
    'player:GetAttributeChangedSignal("OptionalVfxPressure")',
    ':Connect(scheduleRebuild)',
    'PremiumPlatformSideMeshKit.hasNativeCarapaceFallback(',
    'part.Name:match("^PlatformBevel(%d+)_[1-4]$")',
):
    assert clause in identity, ("large-hull 3D owner integration", clause)
print("PASS approved large-deck 3D hulls cover any indexed deck within capped camera LOD")

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

# All northern/southern signature monuments and the 14-slot Orbital
# cinematic ring are FIXED original-perimeter sculptures, not platforms.
additional_fixed_owners = (
    "ApprovedClassicBroadcastFinMeshKit",
    "ApprovedClassicForgedSupportsMeshKit",
    "ApprovedClassicSignatureObservatoryMeshKit",
    "ApprovedCrossroadsOpenGantryMeshKit",
    "ApprovedCrossroadsSignatureInterchangeMeshKit",
    "ApprovedTowersSignatureBridgeMeshKit",
    "ApprovedSouthClassicObservatoryMeshKit",
    "ApprovedSouthCrossroadsExchangeMeshKit",
    "ApprovedSouthOrbitalFinishingMeshKit",
    "ApprovedSouthOrbitalObservationRingMeshKit",
    "ApprovedSouthTowersFinishingMeshKit",
    "ApprovedSouthTowersLiftTwinsMeshKit",
    "ApprovedSouthTowersSkytransferMeshKit",
)
for module in additional_fixed_owners:
    code = (ROOT / "src/client" / (module + ".lua")).read_text(
        encoding="utf8")
    for clause in (
        "local function originalFootprint(base, arena)",
        "local originalX, originalZ = originalFootprint(base, arena)",
        'base:GetAttribute("OriginalSizeX")',
        'base:GetAttribute("OriginalSizeZ")',
        'base:GetAttributeChangedSignal("OriginalSizeX")',
        'base:GetAttributeChangedSignal("OriginalSizeZ")',
    ):
        assert clause in code, (module, clause)
    assert "originalX" in code and "originalZ" in code, module
    assert not re.search(
        r'base\.Size\.[XZ]\s*<\s*318', code), module

halo_kit = (ROOT / "src/client/ApprovedOrbitalHaloTrussMeshKit.lua").read_text(
    encoding="utf8")
halo_rules = (ROOT / "src/shared/CinematicOrbitalHaloMeshRules.lua").read_text(
    encoding="utf8")
for clause in (
    "local function authenticBase(base, arena)",
    "not authenticBase(base,arena)",
    'base:GetAttributeChangedSignal("OriginalSizeX")',
    'base:GetAttributeChangedSignal("OriginalSizeZ")',
):
    assert clause in halo_kit, clause
for clause in (
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    "local radius=math.max(sx,sz)*.5+78",
    "base.Size.X>sx+.2 or base.Size.Z>sz+.2",
):
    assert clause in halo_rules, clause
assert not re.search(r'base\.Size\.[XZ]\s*<\s*318',halo_kit)
assert not re.search(r'base\.Size\.[XZ]\s*<\s*318',halo_rules)
print("PASS 14 more fixed northern/southern/orbital visual owners survive shrink")

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
# Harbor cargo caissons are now refitted to *real* shrinking
# RouteTier landings; the game-owned deck always supplies collision.
# Refit uses adjustable local Weld.C0, bounded geometry update cadence,
# genuine source registry/provenance and the pre-existing Size listener.
caisson = (ROOT / "src/client/HarborDockCaissonMeshKit.lua").read_text(
    encoding="utf8")
for clause in (
    "local function realFloorScale(base, arena)",
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    'deck:GetAttribute("RouteTier")',
    "deck.Size.X / floorScale",
    "deck.Size.Z / floorScale",
    'local joint = Instance.new("Weld")',
    "joint.Part0 = deck",
    "joint.Part1 = piece",
    "entry.joints[piece].C0 = shift",
    "piece.Size = entry.sizes[piece] * factor",
    "if not valid(entry) then return false end",
    "local show = refit(entry)",
    "folder.ChildRemoved:Connect(function(child)",
    "if not entry.disposing and entry.model == child then",
    'or part.CanCollide or part.CanTouch or part.CanQuery',
    "or weld.Part0 ~= entry.deck or weld.Part1 ~= part",
    "local function changed()",
    "visibility(entry)",

    'deck:GetPropertyChangedSignal(property):Connect(changed)',
    '"CollapsePhase", "BridgeShutterPhase", "HarborRoute"',
    "base:GetPropertyChangedSignal(\"Size\"):Connect(function()",
    "for _, entry in pairs(mounted) do visibility(entry) end",
):
    assert clause in caisson, clause
assert not re.search(r'base\.Size\.[XZ]\s*<\s*318', caisson)
for forbidden in ("RenderStepped", "Heartbeat", "RemoteEvent",
                  "AssetService.LoadAssetAsync", "CanCollide = true"):
    assert forbidden not in caisson, forbidden
print("PASS Harbor caisson mesh follows real shrinking decks with safe 3D fallback")

# Harbor promenade arches now follow genuine colliding skywalks through
# ShrinkingArena; only the imported nonphysical MeshParts are reformed.
portal = (ROOT / "src/client/HarborPromenadePortalMeshKit.lua").read_text(
    encoding="utf8")
for clause in (
    "local function realFloorScale(base, arena)",
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    "deck.Size.X / scale",
    "deck.Size.Z / scale",
    'type(deck:GetAttribute("RouteTier")) ~= "number"',
    'local joint=Instance.new("Weld")',
    "entry.joints[piece].C0 = CFrame.new(",
    "piece.Size = Vector3.new(original.X * scale,",
    "entry.frames[piece]=deck.CFrame:ToObjectSpace(piece.CFrame)",
    "local visible = refit(entry)",
    "or part.CanCollide or part.CanTouch or part.CanQuery",
    "or joint.Part0 ~= entry.deck or joint.Part1 ~= part",
    "or not entry.frames[part] or not entry.sizes[part]",
    "for _, entry in pairs(entries) do refresh(entry) end",

    "visible and 1 or native.original",
    "PremiumRoutePbrKit.detach(entry)",
):
    assert clause in portal, clause
assert not re.search(r'base\.Size\.[XZ]\s*<\s*318', portal)
print("PASS Harbor promenade 3D follows contracted collidable decks")

# The four genuine Sky Spine gateway crowns now follow shrinking,
# server-owned decks and retain original-height nonphysical silhouettes.
crown = (ROOT / "src/client/SkySpineCrownMeshKit.lua").read_text(
    encoding="utf8")
for clause in (
    "local function realFloorScale(base, arena)",
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    "math.abs(deck.Size.X / scale - 12)",
    "deck.Size.Z / scale < 14.3",
    'type(deck:GetAttribute("RouteTier")) ~= "number"',
    'local joint = Instance.new("Weld")',
    "entry.joints[piece].C0=CFrame.new(",
    "piece.Size=Vector3.new(original.X*scale,",
    "local visible = refit(entry)",
    "visible and 1 or saved.original",
    "if not visible then PremiumRoutePbrKit.detach(entry) end",
    "darknessGuard",
    "or not piece:IsDescendantOf(entry.model)",
    "or piece.CanCollide or piece.CanTouch or piece.CanQuery",
    "joint.Part0 ~= entry.deck or joint.Part1 ~= piece",
    "clone.DescendantRemoving:Connect(function(child)",
    "task.defer(function()",
    "if not entry.restoring then updateVisibility(entry) end",
    "if safeAfterMount(entry) then count += 1 end",
    "if not realFloorScale(base, arena) then",
    "updateVisibility(entry)",
    "visible and 1 or saved.original",
):
    assert clause in crown, clause
assert not re.search(r'base\.Size\.[XZ]\s*<\s*318', crown)
assert ".RenderStepped:Connect(" not in crown
assert ".Heartbeat:Connect(" not in crown
print("PASS Sky Spine crown shrink + partial-stream native fallback + truthful residency")

# Original 6x6 creator-authored ground plating now follows the ACTUAL
# server-owned 36 tiles. Full source coordinates, live footprint and
# Part order must match the 320-stud builder with no false solid floor.
ground = (ROOT / "src/client/PremiumGroundMeshKit.lua").read_text(
    encoding="utf8")
for clause in (
    "local function signedFloorScale(base)",
    "local function originalSurface(ground, decor, base)",
    'ground:GetAttribute("OriginalGroundFinish") ~= true',
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    "(cellX - 1.2) * scale",
    "(cellZ - 1.2) * scale",
    "(ground.Position - expected).Magnitude < .36",
    "local function refit()",
    "folder.ChildRemoved:Connect(function(child)",
    "if not entry.restoring and entry.model == child then",
    "if entry.restoring or not entry.model",
    "or entry.model.Parent ~= folder",
    "or piece.CanCollide or piece.CanTouch or piece.CanQuery",
    'local joint = Instance.new("Weld")',
    "joint.Part0 = ground",
    "joint.Part1 = piece",
    "piece.Size = Vector3.new(size.X * ratioX, size.Y,",
    "entry.joints[piece].C0 = CFrame.new(",
    "if not refit() then",
    "PremiumGroundPbrKit.detach(entry)",
    "restoreOverlays(entry)",
    'ground:GetPropertyChangedSignal(prop):Connect(onGroundChanged)',
):
    assert clause in ground, clause
assert not re.search(r'base\.Size\.[XZ]\s*<\s*318', ground)
assert ".RenderStepped:Connect(" not in ground
assert ".Heartbeat:Connect(" not in ground
print("PASS 36 real nonphysical 3D floor bays follow server shrink")

# Mixed RouteMesh now validates the physical *per-deck* shrink contract:
# RouteTier x/z, gated Towers Skybridge long axis, or fixed-size translation.
# A fitted, approved MeshPart shell is adjusted through its own deck's Weld
# and Size event, never by adding a fake client route/collider.
routes = (ROOT / "src/client/PremiumRouteMeshKit.lua").read_text(
    encoding="utf8")
for clause in (
    "local function realFloorScale(base,arena)",
    "local function authenticDeck(entry,platform)",
    'base:GetAttribute("OriginalSizeX")',
    'base:GetAttribute("OriginalSizeZ")',
    'entry.resizeKind=="compact"',
    'entry.resizeKind=="skybridge"',
    "sx,sz=sx*ratio,sz*ratio",
    "sx=math.max(4,(sx+7)*ratio-7)",
    "sz=math.max(4,(sz+7)*ratio-7)",
    "local function refit(entry,platform)",
    'local weld=Instance.new("Weld")',
    "weld.Part0=platform",
    "weld.Part1=piece",
    "entry.joints[piece].C0=CFrame.new(",
    "piece.Size=Vector3.new(original.X*fx,original.Y,",
    "local safe = refit(entry,platform)",
    'platform:GetPropertyChangedSignal(prop):Connect(refresh)',
    "if not realFloorScale(base,arena) then",
    "syncVisibility(entry,platform)",
    "PremiumRoutePbrKit.detach(entry)",
    'platform:GetAttribute("LocalOriginalLongCradleMounted") == true',
    'platform:GetAttribute("BridgeShutterPhase")',
    'platform:GetAttribute("CollapsePhase")',
):
    assert clause in routes, clause
assert not re.search(r'base\.Size\.[XZ]\s*<\s*318',routes)
assert ".RenderStepped:Connect(" not in routes
assert ".Heartbeat:Connect(" not in routes
assert not outer_scene_checks, ("stale 320-live-floor guard", outer_scene_checks)
print("PASS all 19 original remaining floor guards classified and corrected safely")
# Existing approved P4 sculptures were already imported. Assert the
# five actual moderated IDs, the single LOD owner and the sampled client
# fallback census so source audits cannot mislabel them as unimplemented.
remaining = (ROOT / "src/client/ApprovedRemainingStructureMeshKit.lua").read_text(
    encoding="utf8")
for asset_id in (
    "110243423264048", "107273631120961", "127049813505254",
    "130196548599769", "106863534763803",
):
    assert asset_id in remaining, "P4 source not connected: " + asset_id
    assert ids[asset_id] == 1, "P4 source not uniquely approved: " + asset_id
# A corrupted local seven-MeshPart clone must not own its slot forever:
# native reveal happens immediately, the subsequent LOD pass remounts
# the intact approved model without changing the physical perimeter deck.
assert 'or not sourceIntact(entry) then' in remaining
assert 'mounted[owner]=nil\n            dispose(entry)' in remaining
# High PC coverage must span all four genuine physical escape routes within
# the SAME six-approved-model cap. Never expand Android or add another timer.
for marker in (
    'local route=deck:GetAttribute("PerimeterRoute")',
    'or route<1 or route>4 then return nil end',
    'stage=step,route=route,index=index',
    'kind=="arch" and (tier=="High" or tier=="Medium") and touch~=true',
    'if not routes[data.route] then',
    'routes[data.route]=true',
    'for _,stage in ipairs({4,8}) do',
    'if data.stage==stage and not desired[data.owner] then',
    'for _,data in ipairs(candidates[kind]) do',
):
    assert marker in remaining, "Four-route approved P4 owner lost: "+marker
# On cap-limited clients, approved stage diversity only reallocates
# already eligible source models near the camera. A damaged local clone
# must restore the five native upper arch volumes without collisions.
for marker in (
    'elseif kind=="arch" and cap>=2',
    'local boundary=candidates.arch[math.min(cap,#candidates.arch)]',
    'local ceiling=boundary.priority+60',
    'for _,stage in ipairs({8,4,1}) do',
    'if not routes[data.route] and data.priority<=ceiling then',
    'local actual=0',
    'entry.model:GetDescendants()',
    'if actual~=7 then return false end',
    'entry.source:GetDescendants()',
    'if sourceCount~=7 then return false end',
    'source.DescendantRemoving:Connect(function(child)',
    'source.DescendantAdded:Connect(function(child)',
    'or entry.corrupt or not entry.model',
    'entry.corrupt=true',
    'child.CanCollide=false',
    'child.CanTouch=false',
    'child.CanQuery=false',
    'reveal(entry)',
):
    assert marker in remaining, "P4 safe sculptor diversity lost: " + marker
assert 'Medium={arch=6,casing=4,helix=4}' in remaining
assert 'High={arch=10,casing=4,helix=8}' in remaining
assert 'local PRESSURE_CAP={' in remaining
assert 'High={arch=3,casing=2,helix=3}' in remaining
assert 'return math.min(math.floor(cap*.5),prior)' in remaining
assert 'High={arch=3,casing=2,helix=3}' in remaining
assert '.RenderStepped:Connect(' not in remaining
assert '.Heartbeat:Connect(' not in remaining
for marker in (
    'ApprovedRemainingStructureMeshKit.sync(arena,cameraPoint,',
    'RemainingVisualNativeCensus.sample(player, arena, profile.Name)',
    'LocalP4RemainingStructuralNativePiecesReplaced',
):
    assert marker in SCENERY, "P4 telemetry missing: " + marker
census = (ROOT / "src/client/RemainingVisualNativeCensus.lua").read_text(
    encoding="utf8")
for marker in (
    'part.LocalTransparencyModifier < .95',
    'part.Transparency < .95',
    'part:IsDescendantOf(circuit)',
    '"Ascension", "ColumnCasing", "Helix", "District"',
    'LocalP4VisibleNative',
    'LocalP4NativeCensusReady',
    # Match native primitive classes from the actual real-engine census.
    'part:IsA("Part") or part:IsA("WedgePart")',
    'part:IsA("CornerWedgePart") or part:IsA("TrussPart")',
    'local owners = {',
    'casing = decor:FindFirstChild("OriginalPremiumColumnCladding")',
    'owners.casing and part:IsDescendantOf(owners.casing)',
    'counts[key..suffix] += 1',
    'local signal = part.Material==Enum.Material.Neon',
    '"AscensionStructure", "AscensionSignal"',
    '"HelixStructure", "HelixSignal"',
    '"DistrictStructure", "DistrictSignal"',
    '"PlatformSupportStructure", "PlatformSupportSignal"',
    '"SkySpineStructure", "SkySpineSignal"',
    '"PromenadeStructure", "PromenadeSignal"',
    'or key=="District" or key=="PlatformSupport"',
    'or key=="SkySpine" or key=="Promenade"',
    '"HarborFleet", "PerimeterStations"',
    'set(player, "AllScanned", scanned)',
):
    assert marker in census, "P4 runtime census guard missing: " + marker
assert "RenderStepped" not in census and "Heartbeat:Connect" not in census
assert census.count('GetDescendants()') == 1, "unexpected extra native scan"
print("PASS five approved P4 sources and family-accurate native visibility census")

# Validate the actionable five-world 3D backlog as actual CSV, including
# independently verifiable row totals. A broken quotation or comma could
# silently corrupt the priority chosen for a whole family.
matrix_path = ROOT / "docs/audit/remaining-3d-priority-matrix-2026-11-13.csv"
numeric = (
    "classic_raw_natives", "towers_raw_natives", "crossroads_raw_natives",
    "orbital_raw_natives", "harbor_raw_natives",
)
with matrix_path.open(newline="", encoding="utf8") as handle:
    reader = csv.DictReader(handle, strict=True)
    assert reader.fieldnames == [
        "owner_family", "description", "priority", "coverage_status",
        *numeric, "five_world_raw_natives", "large_12_plus",
        "signal_neon_subset", "evidence_action",
    ], "3D matrix schema changed"
    priority_rows = list(reader)
assert len(priority_rows) >= 25, "Missing 3D backlog families"
assert len({r["owner_family"] for r in priority_rows}) == len(priority_rows)
for row in priority_rows:
    assert None not in row and all(
        isinstance(v, str) and v.strip() for v in row.values()
    ), "Malformed or truncated priority CSV: " + repr(row)
    assert row["priority"] in ("P0", "P1", "P2", "CONSERVER", "AUDITER")
    numbers = [int(row[key]) for key in numeric]
    total = int(row["five_world_raw_natives"])
    assert all(v >= 0 for v in numbers) and sum(numbers) == total, row
    assert 0 <= int(row["large_12_plus"]) <= total, row
    assert 0 <= int(row["signal_neon_subset"]) <= total, row
for key in ("skyroute", "columnclad", "helix"):
    group = next(r for r in priority_rows if r["owner_family"] == key)
    assert group["coverage_status"] == "SOURCE_3D_APPROUVEE_LOD_PARTIEL"
print("PASS five-world 3D priority matrix: valid CSV, owner totals and approved P4 coverage")

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
# P4 district shell safety: in-place mesh mutation is not a descendant
# event. Both authenticated source and resident clone must synchronously
# restore native volumes when geometry, anchoring or collision is changed.
for owner in ("ApprovedDistrictSidewallMeshKit.lua",
              "PremiumDistrictFacadeMeshKit.lua"):
    code = (ROOT / "src/client" / owner).read_text(encoding="utf8")
    for signal in (
        'sourcePiece:GetPropertyChangedSignal(property):Connect(',
        'piece:GetPropertyChangedSignal(property):Connect(',
        '"MeshId", "Size", "CFrame", "Anchored"',
        '"CanCollide", "CanTouch", "CanQuery"',
    ):
        assert signal in code, (owner, signal)
print("PASS district 3D native rollback on source and mounted mesh mutation")

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
