#!/usr/bin/env python3
"""P4 Harbor atmosphere visual identity regression.

Static contract only: the final in-engine look still needs honest captures.
"""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
SRC = (ROOT / "src/server/ArenaAtmosphere.server.lua").read_text()
COLUMNS = (ROOT / "src/client/ApprovedAtmosphereColumnsMeshKit.lua").read_text()
STYLE = (ROOT / "src/server/ArenaAtmosphereStyle.lua").read_text()
THEME = (ROOT / "src/shared/VisualTheme.lua").read_text()
MAP = (ROOT / "src/server/MapBuilder.lua").read_text()
CLIENT = (ROOT / "src/client/arena-lighting.client.lua").read_text()
ENGINE = (ROOT / "tests/engine/arena-presentation.spec.luau").read_text()
CLOUD = (ROOT / ".github/workflows/roblox-cloud-test.yml").read_text()
REGISTRY = json.loads((ROOT / "assets/source/roblox-asset-registry.json").read_text())

# Existing source regression: only compatible real sculptures are ranked.
# A too-wide near pillar must not prevent a farther, valid spine from
# occupying the sole Android Low mount slot.
assert 'local function candidateFit(sourceSize, kind, variant, height)' in COLUMNS
assert 'sourceSize.X * scale > maxWidth + .08' in COLUMNS
assert 'sourceSize.Z * scale > maxWidth + .08' in COLUMNS
assert 'if native and candidateFit(size, kind, variant, height) then' in COLUMNS
assert 'local scale, maxWidth = candidateFit(' in COLUMNS
assert 'if not scale then return end' in COLUMNS
assert 'math.abs(bounds.Y - height) > .13' in COLUMNS
assert 'bounds.X > maxWidth or bounds.Z > maxWidth' in COLUMNS
assert 'Low = {cap = 1, distance = 175}' in COLUMNS
assert 'if tier == "Low" and stress >= 1 then cap = 0 end' in COLUMNS

assert 'local ArenaAtmosphereStyle = require("./ArenaAtmosphereStyle")' in SRC
assert 'ArenaAtmosphereStyle.profileFor(variantId)' in SRC
assert "local THEMES = {" not in SRC
assert 'if variantId == "Orbital" then' in SRC
assert 'elseif variantId == "Crossroads" then' in SRC
assert 'elseif variantId == "Towers" then' in SRC
assert 'elseif variantId == "Classic" then' in SRC
assert SRC.count('"ClassicHubGlow"') == 1
assert SRC.index('elseif variantId == "Classic" then') < SRC.index(
    '"ClassicHubGlow"')
assert 'arena:GetAttribute("VariantId")' in SRC
assert 'arena:FindFirstChild("Atmosphere")' in SRC
assert 'folder:SetAttribute("VariantId", variantId)' in SRC
assert 'addTowers(folder, center, theme, variantId)' in SRC
assert 'addDistantSilhouette(folder, center, theme, variantId, base)' in SRC

# Keep an exact four-light/20-native fallback for the fog/beacon system;
# the four 4-Part silhouettes and 12-ring segments are still nonphysical.
assert SRC.count('Instance.new("Part")') == 1
assert SRC.count('Instance.new("PointLight")') == 1
assert SRC.count('addLight(') == 3  # helper definition + tower + Orbital core
assert SRC.count('addRing(folder, center, theme)') == 2
assert SRC.count('addDistantSilhouette(') == 2
assert SRC.count('for index = 0, 11 do') == 1
assert SRC.count('for index, offset in ipairs(locations) do') == 1
assert SRC.count('for level = 1, 2 do') == 1
for field in ('object.Anchored = true', 'object.CanCollide = false',
              'object.CanTouch = false', 'object.CanQuery = false',
              'object.CastShadow = false'):
    assert field in SRC, field

# Harbor changes native fallback geometry, not object count or light count.
assert SRC.count('local harbor = variantId == "Harbor"') == 2
assert SRC.count('local verticalCylinder = CFrame.Angles(0, 0, math.pi * 0.5)') == 2
for pattern in ('pillar.Shape = Enum.PartType.Cylinder',
                'cap.Shape = Enum.PartType.Cylinder',
                'spine.Shape = Enum.PartType.Cylinder',
                'band.Shape = Enum.PartType.Cylinder'):
    assert pattern in SRC, pattern
assert SRC.count('Enum.Material.CorrodedMetal') >= 3
assert 'or (harbor and 15)' in SRC
assert 'harbor and theme.structure or Color3.fromRGB(42, 48, 62)' in SRC
assert 'harbor and theme.structure or Color3.fromRGB(29, 37, 53)' in SRC
assert 'theme.accent' in SRC and 'theme.secondary' in SRC

# Source the actual shared Harbor palette, not Classic's survey grid.
assert 'local harbor = VisualTheme.arena("Harbor")' in STYLE
for key in ("Accent", "Secondary", "Structure", "Detail"):
    assert f'harbor.{key}' in STYLE
assert "pillarHeight = 11" in STYLE
assert "ringRadius = 43" in STYLE
for name in ("Classic", "Towers", "Crossroads", "Orbital"):
    assert f"{name} = {{" in STYLE,name
assert 'return PREVIOUS[variantId] or PREVIOUS.Classic' in STYLE
assert 'Harbor = {' in THEME and 'Harbor = {' in CLIENT
assert 'HarborQuayInlay' in MAP

# No extra client sampler, new cosmetic imports, network or new asset IDs.
assert "AssetService" not in SRC and "LoadAssetAsync" not in SRC
assert "RenderStepped" not in SRC and "Heartbeat" not in SRC
assert "RemoteEvent" not in SRC and "RemoteFunction" not in SRC
# The approved source catalog is append-only; an exact 101 entries
# became stale after the next legitimate owner-approved model import.
# Keep a lower bound and reject duplicate Roblox asset IDs instead.
assert len(REGISTRY["models"]) >= 101
assert len({m["asset_id"] for m in REGISTRY["models"]}) == len(REGISTRY["models"])
assert all(m.get("moderation") == "Approved" for m in REGISTRY["models"])
assert 'local ArenaAtmosphereStyle = require("../../src/server/ArenaAtmosphereStyle")' in ENGINE
assert 'keeps Harbor atmosphere' in ENGINE
assert '"tests/engine/arena-presentation.spec.luau"' in CLOUD
print("PASS Harbor now uses own seafoam/dock palette, not Classic identity")
print("PASS maritime cylinders/industrial finishes without more native parts/lights")
print("PASS all four existing arena profiles, native collisions and Cloud suite retained")
print("LIMIT source CI does not certify gameplay pixel output or Android FPS")
