#!/usr/bin/env python3
"""Verify real six-family P4 near-field 3D residency enters existing pulse.

Source-level cross-owner contract only, not an in-engine FPS claim.
"""
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
RULES=(ROOT/"src/shared/PerformancePulseRules.lua").read_text()
CLIENT=(ROOT/"src/client/juice.client.lua").read_text()
LOD=(ROOT/"src/client/scenery-lod.client.lua").read_text()
SERVER=(ROOT/"src/server/init.server.lua").read_text()
ENGINE=(ROOT/"tests/engine/game-analytics.spec.luau").read_text()
CLOUD=(ROOT/".github/workflows/roblox-cloud-test.yml").read_text()
FAMILIES={
    # (fields reported by client, actual owned locally, max values, ratio)
    "Towers":("premiumTowers","premiumTowersMasked",
               "LocalTowersLandmarkMeshCount",
               "LocalTowersLandmarkPrimitivesReplaced",4,8,2),
    "CrossroadsGantry":("premiumGantry","premiumGantryMasked",
               "LocalCrossroadsGantryMeshCount",
               "LocalCrossroadsGantryPrimitivesReplaced",4,4,1),
    "ClassicFin":("premiumClassicFin","premiumClassicFinMasked",
               "LocalClassicFinMeshCount",
               "LocalClassicFinPrimitivesReplaced",4,4,1),
    "OrbitalReactor":("premiumOrbitalPair","premiumOrbitalPairMasked",
               "LocalOrbitalReactorSculptPairCount",
               "LocalOrbitalReactorNativePartsReplaced",8,16,2),
    "CrossroadsEntrance":("premiumEntrance","premiumEntranceMasked",
               "LocalCrossroadsEntrance3DCount",
               "LocalCrossroadsEntranceNativePartsReplaced",4,12,3),
    "IdentitySpine":("premiumIdentity","premiumIdentityMasked",
               "LocalIdentitySpineMeshCount",
               "LocalIdentitySpineNativePartsReplaced",4,4,1),
}
assert len(FAMILIES)==6
for family,(count,masked,owner_count,owner_mask,limit,mask_limit,ratio) in FAMILIES.items():
    for fld,attr,bound in ((count,owner_count,limit),
                           (masked,owner_mask,mask_limit)):
        line=f'{fld} = player:GetAttribute("{attr}")'
        assert CLIENT.count(line)==1,(family,line)
        assert f'player:SetAttribute("{attr}"' in LOD,(family,attr)
        assert RULES.count(f'{fld} = {{{bound}, true}}')==1,(family,fld)
        assert f'{fld} = ' in RULES
    expected=f's.{masked} < s.{count}'
    if ratio!=1:
        expected+=f' * {ratio}'
    assert expected in RULES,(family,expected)
    print(f"PASS {family}: two real client owner counters and exact {ratio}:1 mask contract")
assert "local premiumGroups = " in RULES
assert "        + premiumGroups" in RULES
assert '        .. "S" .. presence(premiumGroups)' in RULES
assert "or premiumMismatch" in RULES
assert "ClientOriginal3DResidencyPulse" in SERVER
assert "PerformancePulseRules.original3DAnalytics(sample)" in SERVER
assert "performancePulseEvent:FireServer(sample)" in CLIENT
assert "return first == true and 12 or 45" in RULES
assert "RateLimiter.new(45)" in SERVER
assert '"tests/engine/game-analytics.spec.luau"' in CLOUD
assert 'reports six actually resident P4 landmark families' in ENGINE
assert 'premiumEntrance = 1, premiumEntranceMasked = 2' in ENGINE
assert 'expect(wrong).toBe("P0C0T0H0F1S1")' in ENGINE
assert 'expect(extra.premiumEntranceMasked).toBe(0)' in ENGINE

# Guard against adding any extra remote or render sampler in this change.
assert CLIENT.count("performancePulseEvent:FireServer(sample)")==1
assert CLIENT.count("RunService.RenderStepped:Connect(")==1
assert 'Instance.new("RemoteEvent")' not in RULES
assert 'Instance.new("RemoteEvent")' not in LOD
print("PASS six-family mounted 3D owner evidence uses existing 12s/45s pulse")
print("PASS P/C/T/H/F legacy presence flags preserved; S reflects premium groups")
print("LIMIT client-reported sample does not certify public Place or mobile FPS")
