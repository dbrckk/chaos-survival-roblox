--!strict
-- Real Roblox Instance / Weld ownership regression for original 3D art.
-- Fixture MeshParts are intentionally local stand-ins; source provenance is
-- checked in the existing creator-owned asset pipeline before installation.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Kit = require("../../src/client/PlatformNativeTrimReplacementKit")

describe("Original 3D native fallback isolation (engine)", function()
    it("restores only a lost deck/support and releases streamed native masks", function()
        Kit.reset()
        local arena = Instance.new("Folder")
        arena.Name = "NativeFallbackIsolationArena"
        arena.Parent = workspace
        local platforms = Instance.new("Folder")
        platforms.Name = "Platforms"
        platforms.Parent = arena
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        local meshes = Instance.new("Folder")
        meshes.Name = "ApprovedOriginal3DScene"
        meshes.Parent = workspace

        local function physical(name)
            local part = Instance.new("Part")
            part.Name = name
            part.Anchored = true
            part.CanCollide = true
            part.Size = Vector3.new(16, 2, 12)
            part.Parent = platforms
            return part
        end
        local function native(name, ownerSupport)
            local part = Instance.new("Part")
            part.Name = name
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            if not ownerSupport then
                part:SetAttribute("PremiumArchitecturalSurface", true)
            end
            part.Parent = decor
            return part
        end
        local function genuine(anchor, name, large)
            local piece = Instance.new("MeshPart")
            piece.Name = name
            piece.CanCollide = false
            piece.CanTouch = false
            piece.CanQuery = false
            piece:SetAttribute(
                large and "OriginalLargeStructure3D"
                    or "Original3DStructuralSide", true
            )
            local weld = Instance.new("WeldConstraint")
            weld.Name = "OriginalSupportVisualWeld"
            weld.Part0 = piece
            weld.Part1 = anchor
            weld.Parent = piece
            piece.Parent = meshes
            return piece
        end

        local platform1 = physical("Platform1")
        local platform2 = physical("Platform2")
        local platform4 = physical("Platform4")
        local bridge3 = physical("Skybridge3")
        local frame1 = native("PlatformUnderFrame1")
        local frame2 = native("PlatformUnderFrame2")
        local rib3 = native("SkybridgeRib3_1")
        local support4 = native("PlatformSupport4_1", true)
        support4.Size = Vector3.new(2, 18, 2)
        local shell1 = genuine(platform1, "OwnedCarapace1", false)
        local shell2 = genuine(platform2, "OwnedCarapace2", false)
        local girder3 = genuine(bridge3, "OwnedGirder3", false)
        local column4 = genuine(support4, "OwnedColumn4", true)

        Kit.bind(arena, {
            ["1"] = "carapace",
            ["2"] = "carapace",
            ["3"] = "bridge",
        }, nil, {support4}, meshes)
        expect(Kit.count()).toBe(4)
        expect(frame1.LocalTransparencyModifier).toBe(1)
        expect(frame2.LocalTransparencyModifier).toBe(1)
        expect(rib3.LocalTransparencyModifier).toBe(1)
        expect(support4.LocalTransparencyModifier).toBe(1)

        -- One failed original import no longer turns all five worlds back
        -- into their Roblox-native underneath. Other original meshes live.
        shell1:Destroy()
        expect(frame1.LocalTransparencyModifier).toBe(0)
        expect(frame2.LocalTransparencyModifier).toBe(1)
        expect(rib3.LocalTransparencyModifier).toBe(1)
        expect(support4.LocalTransparencyModifier).toBe(1)
        expect(Kit.count()).toBe(3)

        column4:Destroy()
        expect(support4.LocalTransparencyModifier).toBe(0)
        expect(frame2.LocalTransparencyModifier).toBe(1)
        expect(rib3.LocalTransparencyModifier).toBe(1)
        expect(Kit.count()).toBe(2)

        -- A disaster shutter wins immediately over any surviving 3D art.
        bridge3:SetAttribute("BridgeShutterPhase", "Warning")
        expect(rib3.LocalTransparencyModifier).toBe(0)
        expect(frame2.LocalTransparencyModifier).toBe(1)
        bridge3:SetAttribute("BridgeShutterPhase", "Idle")
        expect(rib3.LocalTransparencyModifier).toBe(1)
        expect(Kit.count()).toBe(2)

        -- A native server Part can stream out without its Decor folder.
        -- Do not count or retain a mask for a destroyed instance.
        frame2:Destroy()
        expect(Kit.count()).toBe(1)
        shell2:Destroy()
        expect(Kit.count()).toBe(1)

        Kit.reset()
        expect(rib3.LocalTransparencyModifier).toBe(0)
        expect(Kit.count()).toBe(0)
        expect(platform4.CanCollide).toBe(true)
        expect(bridge3.CanCollide).toBe(true)
        expect(girder3.CanCollide).toBe(false)
        arena:Destroy()
        meshes:Destroy()
    end)
end)

return nil
