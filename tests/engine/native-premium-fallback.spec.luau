--!strict
-- Real Roblox Instance / Weld ownership regression for original 3D art.
-- Fixture MeshParts are intentionally local stand-ins; source provenance is
-- checked in the existing creator-owned asset pipeline before installation.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Kit = require("../../src/client/PlatformNativeTrimReplacementKit")
local HarborScenery = require("../../src/server/HarborScenery")
local VisualTheme = require("../../src/shared/VisualTheme")
local HarborFreighterMeshKit = require("../../src/client/HarborFreighterMeshKit")
local HarborMidgroundBargeMeshKit = require("../../src/client/HarborMidgroundBargeMeshKit")

describe("Original 3D native fallback isolation (engine)", function()
    it("keeps the approved Harbor cargo freighter through shrink and restores native on GPU pressure", function()
        local storage=game:GetService("ReplicatedStorage")
        local holder=Instance.new("Folder")
        holder.Name="ApprovedHarborFreighterTemplates"
        holder:SetAttribute("OwnerVerified",true)
        holder.Parent=storage
        local source=Instance.new("Model")
        source.Name="OriginalContainerFreighter"
        source:SetAttribute("OwnerVerified",true)
        source:SetAttribute("CosmeticOnly",true)
        source:SetAttribute("OriginalHarborFreighter3D",true)
        source:SetAttribute("Original3DAssetId",128820723471019)
        for i=1,7 do
            local part=Instance.new("MeshPart")
            part.Name="FreighterMaterial"..i
            part.Size=if i==1 then Vector3.new(29.1,9.8,6.4)
                else Vector3.new(1,1,1)
            part.Anchored=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.Parent=source
        end
        source.Parent=holder
        local arena=Instance.new("Folder")
        arena.Name="Arena"
        arena:SetAttribute("VariantId","Harbor")
        arena.Parent=workspace
        local base=Instance.new("Part")
        base.Name="Base"
        base.Size=Vector3.new(320,4,320)
        base.Anchored=true
        base.CanCollide=true
        base:SetAttribute("OriginalSizeX",320)
        base:SetAttribute("OriginalSizeZ",320)
        base.Parent=arena
        local decor=Instance.new("Folder")
        decor.Name="Decor"
        decor.Parent=arena
        local fleet=HarborScenery.build(decor,base,VisualTheme.arena("Harbor"))
        local ship=fleet:FindFirstChild("HarborCargoVessel")
        expect(ship ~= nil).toBe(true)
        local hull=ship:FindFirstChild("MainHull")
        local initialAlpha=hull.Transparency
        local camera=ship:GetPivot().Position
        local function sync(pressure)
            HarborFreighterMeshKit.sync(arena,camera,"High",true,
                Vector3.zero,pressure)
        end
        sync(0)
        expect(HarborFreighterMeshKit.count()).toBe(1)
        expect(hull.Transparency).toBe(1)
        local model=workspace.OriginalHarborFreighterLocal:
            FindFirstChild("ApprovedHarborFreighter3D")
        expect(model ~= nil).toBe(true)
        local partCount=0
        for _,p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then
                partCount+=1
                expect(p.CanCollide or p.CanTouch or p.CanQuery).toBe(false)
            end
        end
        expect(partCount).toBe(7)
        base.Size=Vector3.new(170,4,174)
        sync(0)
        expect(HarborFreighterMeshKit.count()).toBe(1)
        expect(hull.Transparency).toBe(1)
        sync(2)
        expect(HarborFreighterMeshKit.count()).toBe(0)
        expect(hull.Transparency).toBe(initialAlpha)
        sync(0)
        expect(HarborFreighterMeshKit.count()).toBe(1)
        base.Size=Vector3.new(330,4,320)
        sync(0)
        expect(HarborFreighterMeshKit.count()).toBe(0)
        expect(hull.Transparency).toBe(initialAlpha)
        HarborFreighterMeshKit.sync(nil,camera,"Low",false,
            Vector3.zero,2)
        arena:Destroy()
        holder:Destroy()
    end)

    -- Engine integration of the real Harbor LOD owner with Roblox instances.
    it("keeps one authentic Harbor barge on Low through shrink and restores native art under GPU pressure", function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local templates = Instance.new("Folder")
        templates.Name = "ApprovedHarborBargeTemplates"
        templates:SetAttribute("OwnerVerified", true)
        templates:SetAttribute("Original3DAssetId", 132891280963772)
        templates.Parent = ReplicatedStorage
        local approved = Instance.new("Model")
        approved.Name = "CoastalFreightBarge"
        approved:SetAttribute("OwnerVerified", true)
        approved:SetAttribute("CosmeticOnly", true)
        approved:SetAttribute("OriginalHarborBarge3D", true)
        approved:SetAttribute("Original3DAssetId", 132891280963772)
        for i = 1, 7 do
            local mesh = Instance.new("MeshPart")
            mesh.Name = "OriginalPart" .. i
            mesh.Size = if i == 1
                then Vector3.new(28.35, 11.18, 13.30)
                else Vector3.new(1, 1, 1)
            mesh.Anchored = true
            mesh.CanCollide = false
            mesh.CanTouch = false
            mesh.CanQuery = false
            mesh.Parent = approved
        end
        approved.Parent = templates

        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena:SetAttribute("VariantId", "Harbor")
        arena.Parent = workspace
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(320, 4, 320)
        base.Anchored = true
        base.CanCollide = true
        base:SetAttribute("OriginalSizeX", 320)
        base:SetAttribute("OriginalSizeZ", 320)
        base.Parent = arena
        local midground = Instance.new("Folder")
        midground.Name = "ArenaMidgroundMassLocal"
        midground.Parent = workspace
        local native = {}
        for i = 1, 4 do
            local part = Instance.new("Part")
            part.Name = if i == 1
                then "HarborFreightBargeHull1"
                else "HarborFreightNativeDetail" .. i
            part.Size = if i == 1
                then Vector3.new(28, 3.5, 13.2)
                else Vector3.new(4, 2, 3)
            part.CFrame = CFrame.new(205, 0, -88)
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Transparency = .25
            part:SetAttribute("OriginalHarborMidgroundBargeIndex", 1)
            part.Parent = midground
            native[#native + 1] = part
        end
        local camera = Vector3.new(205, 3, -68)
        local function sync(pressure)
            HarborMidgroundBargeMeshKit.sync(arena, camera, "Low", true,
                Vector3.new(0, 0, -1), pressure)
        end
        sync(0)
        expect(HarborMidgroundBargeMeshKit.count()).toBe(1)
        for _, part in ipairs(native) do
            expect(part.Transparency).toBe(1)
        end
        local holder = workspace:FindFirstChild("OriginalHarborMidgroundBargesLocal")
        expect(holder ~= nil).toBe(true)
        local model = holder:FindFirstChild("ApprovedOriginal3DHarborBarge1")
        expect(model ~= nil).toBe(true)
        local meshCount = 0
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                meshCount += 1
                expect(part:IsA("MeshPart")).toBe(true)
                expect(part.CanCollide).toBe(false)
                expect(part.CanTouch).toBe(false)
                expect(part.CanQuery).toBe(false)
            end
        end
        expect(meshCount).toBe(7)
        -- Harbor boats remain at their fixed berth when the playable
        -- floor shrinks; only the real floor changes size.
        base.Size = Vector3.new(170, 4, 175)
        sync(0)
        expect(HarborMidgroundBargeMeshKit.count()).toBe(1)
        for _, part in ipairs(native) do
            expect(part.Transparency).toBe(1)
        end
        sync(1)
        expect(HarborMidgroundBargeMeshKit.count()).toBe(0)
        for _, part in ipairs(native) do
            expect(part.Transparency).toBe(.25)
        end
        sync(0)
        expect(HarborMidgroundBargeMeshKit.count()).toBe(1)
        base.Size = Vector3.new(325, 4, 320)
        sync(0)
        expect(HarborMidgroundBargeMeshKit.count()).toBe(0)
        for _, part in ipairs(native) do
            expect(part.Transparency).toBe(.25)
        end
        HarborMidgroundBargeMeshKit.sync(nil, camera, "Low", false,
            Vector3.zero, 2)
        midground:Destroy()
        arena:Destroy()
        templates:Destroy()
    end)

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
