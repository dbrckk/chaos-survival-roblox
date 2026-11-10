#!/usr/bin/env python3
"""Static provenance, geometry-contract and fallback audit for South Orbital.

Roblox Studio rendering and gameplay performance are separate release gates.
"""
import json
import re
from pathlib import Path

root=Path(__file__).resolve().parents[1]
client=(root/"src/client/ApprovedSouthOrbitalFinishingMeshKit.lua").read_text()
ring=(root/"src/client/ApprovedSouthOrbitalObservationRingMeshKit.lua").read_text()
server=(root/"src/server/PremiumSouthOrbitalFinishingAssets.lua").read_text()
registry=json.loads((root/"assets/source/roblox-asset-registry.json").read_text())
models={m["name"]:m for m in registry["models"]}
m=models["south_orbital_forged_finishing"]
assert m["asset_id"]=="96266711661930"
assert m["moderation"]=="Approved" and m["workflow_run_id"]==42844551858
assert "local MODEL_ID=96266711661930" in client
assert "local APPROVED_ID=96266711661930" in server
assert 'OriginalSouthOrbitalForgedFinishing3D' in client
assert 'OriginalSouthOrbitalForgedFinishing3D' in server
assert 'OriginalMeshScenery.sanitize(raw)' in server
assert 'if count~=7 then return false end' in server
print("PASS owner-moderated seven-material source and sanitized 7-mesh server")

names=[
    "Foundation","FloorInset","LeftRingSupport",
    "RightRingSupport","SuspendedOrb","OrbClamp",
]
context=client.split("local function context(arena)",1)[1].split("local function fit(",1)[0]
specs=context.split("local specs={",1)[1].split("\n    }",1)[0]
targets=re.findall(r'\{"([^"]+)",Vector3.new\(',specs)
assert targets==names,(targets,names)
assert 'local desiredShape=index==5 and Enum.PartType.Ball' in context
assert 'part.Shape~=desiredShape' in context
assert 'arena:GetAttribute("VariantId")~="Orbital"' in context
assert 'owner:GetAttribute("SignatureVariant")~="Orbital"' in context
assert '"ObservationArc"..i' in context
assert "for i=1,14 do" in context
assert 'part.CFrame.LookVector:Dot(expected.LookVector)' in context
assert 'part.CFrame.UpVector:Dot(expected.UpVector)' in context
assert 'part.CanCollide or part.CanTouch or part.CanQuery' in context
assert '"LeftRingSupport"' in ring and '"RightRingSupport"' in ring
assert 'RADIUS=17' in ring and 'SEGMENTS=14' in ring
ring_targets={"ObservationArc"+str(k) for k in range(1,15)}
assert set(names).isdisjoint(ring_targets)
assert len(set(names)|ring_targets)==20
print("PASS correct separate six original native targets, real sphere and 14 approved ring arcs")

restore=client.split("local function restore()",1)[1].split("local function clear()",1)[0]
assert 'part.Transparency=alpha' in restore
assert 'part.Transparency==1' in restore
assert "model.Parent=bucket" in client
assert "native.Transparency=1" in client
assert client.index("model.Parent=bucket")<client.index("native.Transparency=1")
assert "#currentNatives~=6" in client
assert 'if cap==0 or not cameraReady' in client
assert 'source.DescendantRemoving:Connect' in client
assert "RenderStepped" not in client and "Heartbeat" not in client
assert 'part.CanCollide=false' in client
assert 'part.CanTouch=false' in client and 'part.CanQuery=false' in client
print("PASS mount-before-hide, native rollback, no extra sampler, physical safety")

for path in ("src/server/init.server.lua","src/client/scenery-lod.client.lua",
             "src/shared/VisualBudgetRules.lua"):
    assert "SouthOrbitalFinishing" in (root/path).read_text(),path
print("PASS shared LOD sampler, server boot, visual budget and approved registry")
