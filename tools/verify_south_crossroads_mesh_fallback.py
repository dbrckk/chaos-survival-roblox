#!/usr/bin/env python3
"""Source-level gate for the 13 target South Crossroads primitives.

This checks authored fidelity, approvals and safe native fallback. Runtime
Roblox Studio/Android rendering tests remain a separate release gate.
"""
import json
import re
from pathlib import Path

root=Path(__file__).resolve().parents[1]
client=(root/"src/client/ApprovedSouthCrossroadsExchangeMeshKit.lua").read_text()
server=(root/"src/server/PremiumSouthCrossroadsExchangeAssets.lua").read_text()
builder=(root/"src/server/MapBuilder.lua").read_text()
registry=json.loads((root/"assets/source/roblox-asset-registry.json").read_text())
model=next(m for m in registry["models"] if m["name"]=="south_crossroads_forged_exchange")

ID="77870668100712"
assert model["asset_id"]==ID and model["moderation"]=="Approved"
assert model["workflow_run_id"]==42842143479
assert "local MODEL_ID="+ID in client and "local APPROVED_ID="+ID in server
assert "OriginalSouthCrossroadsForgedExchange3D" in server
assert "OriginalSouthCrossroadsForgedExchange3D" in client
assert "OriginalMeshScenery.sanitize(raw)" in server
assert "if count~=7 then return false end" in server

expect={
    "Foundation":"Part","FloorInset":"Part","ExchangeCore":"Part",
    "WestFork":"Part","EastFork":"Part",
    "WestFreightArm":"WedgePart","EastFreightArm":"WedgePart",
    "WestCounterweight":"Part","EastCounterweight":"Part",
    "WestSignal":"Part","EastSignal":"Part",
    "CentralSwitchCab":"Part","CabWindow":"Part",
}
context=client.split("local function context(arena)",1)[1].split("local function fit(",1)[0]
specs=context.split("local specs={",1)[1].split("\n    }",1)[0]
pairs=re.findall(r'\{"([^"]+)",\s*"(Part|WedgePart)"',specs)
assert len(pairs)==13,(len(pairs),pairs)
assert dict(pairs)==expect,pairs
assert len(set(k for k,v in pairs))==13
assert all('"'+key+'"' in builder for key in expect)
assert 'arena:GetAttribute("VariantId")~="Crossroads"' in context
assert 'owner:GetAttribute("SignatureVariant")~="Crossroads"' in context
assert 'part:IsA(spec[2])' in context
assert 'part.CFrame.LookVector:Dot(intended.LookVector)' in context
assert 'part.CFrame.UpVector:Dot(intended.UpVector)' in context
assert 'part.CanCollide' in context and 'part.CanTouch' in context
print("PASS exact Crossroads source landmark types and 13 nonphysical native targets")

restore=client.split("local function restore()",1)[1].split("local function clear()",1)[0]
assert 'part:IsA("BasePart")' in restore
assert 'part.Transparency=alpha' in restore
assert 'part.Transparency==1' in restore
assert "model.Parent=bucket" in client and "native.Transparency=1" in client
assert client.index("model.Parent=bucket")<client.index("native.Transparency=1")
assert "#currentNatives~=13" in client
assert 'if cap==0 or not cameraReady' in client
assert 'source.DescendantRemoving:Connect' in client
assert "RenderStepped" not in client and "Heartbeat" not in client
assert 'part.CanCollide=false' in client
assert 'part.CanTouch=false' in client and 'part.CanQuery=false' in client
print("PASS atomic 7-MeshPart mounting and Part/WedgePart restoration")

for path in ("src/server/init.server.lua","src/client/scenery-lod.client.lua",
             "src/shared/VisualBudgetRules.lua"):
    assert "SouthCrossroadsExchange" in (root/path).read_text(),path
print("PASS server startup, existing LOD sampler, visual budget and approved asset registry")
