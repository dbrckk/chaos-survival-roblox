--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local OrbitalRampRegistry = require("../../src/client/OrbitalRampRegistry")
local OrbitalRouteSignKit = require("../../src/client/OrbitalRouteSignKit")
local RemainingStructureKit = require("../../src/client/ApprovedRemainingStructureMeshKit")
local OrbitalHelix = require("../../src/server/OrbitalHelix")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local Config = require("../../src/shared/Config")

local function ramp(root, name, tag, lane)
    local part = Instance.new("Part")
    part.Name = name
    if tag then part:SetAttribute(tag, true) end
    if lane then part:SetAttribute("HelixLane", lane) end
    part.Parent = root
    return part
end

describe("Orbital event-driven ramp discovery", function()
    it("keeps smooth visual frames independent of geometry enumeration", function()
        local registry = OrbitalRampRegistry.new(OrbitalRouteSignKit)
        local first, access, changed = registry:snapshot(nil)
        expect(#first).toBe(0)
        expect(#access).toBe(0)
        expect(changed).toBe(true)
        local initialScans = registry.scanCount
        for _ = 1, 90 do
            local scored, links, rescanned = registry:snapshot(nil)
            expect(#scored).toBe(0)
            expect(#links).toBe(0)
            expect(rescanned).toBe(false)
        end
        expect(registry.scanCount).toBe(initialScans)

        local circuit = Instance.new("Folder")
        circuit.Name = "HelixCircuit"
        circuit.Parent = workspace
        local scored2 = ramp(circuit, "HelixRamp2", "OrbitalHelixRamp", 2)
        local scored10 = ramp(circuit, "HelixRamp10", "OrbitalHelixRamp", 10)
        local scored1 = ramp(circuit, "HelixRamp1", "OrbitalHelixRamp", 1)
        local entry = ramp(circuit, "EntryRamp1", "OrbitalAccessRamp", nil)
        local core = ramp(circuit, "HelixRamp9", "OrbitalCoreRamp", nil)
        -- Hundreds of static trim pieces may exist around a single ramp.
        for index = 1, 36 do
            local trim = Instance.new("Part")
            trim.Name = "HelixEdgeSignal" .. index
            trim.Parent = circuit
        end
        local scored, links, rescanned = registry:snapshot(circuit)
        expect(rescanned).toBe(true)
        expect(#scored).toBe(3)
        expect(scored[1]).toBe(scored1)
        expect(scored[2]).toBe(scored2)
        expect(scored[3]).toBe(scored10)
        expect(#links).toBe(2)
        expect(links[1]).toBe(entry)
        expect(links[2]).toBe(core)
        local scanCount = registry.scanCount

        for _ = 1, 120 do
            local _, _, wasDirty = registry:snapshot(circuit)
            expect(wasDirty).toBe(false)
        end
        expect(registry.scanCount).toBe(scanCount)

        -- Server VFX pulse updates must never trigger a route rescan.
        scored1:SetAttribute("HelixPulseActive", true)
        scored1.CFrame = CFrame.new(8, 5, 3)
        local _, _, afterPulse = registry:snapshot(circuit)
        expect(afterPulse).toBe(false)
        expect(registry.scanCount).toBe(scanCount)

        -- Streaming may add the Part before its gameplay attributes.
        local late = ramp(circuit, "CoreRamp8", nil, nil)
        task.wait(0.03)
        scored, links, rescanned = registry:snapshot(circuit)
        expect(rescanned).toBe(true)
        expect(#links).toBe(2)
        late:SetAttribute("OrbitalCoreRamp", true)
        task.wait(0.03)
        scored, links, rescanned = registry:snapshot(circuit)
        expect(rescanned).toBe(true)
        expect(#links).toBe(3)
        expect(links[1]).toBe(late)

        -- Changing Helix lane order is rare but still invalidates cache.
        scored10:SetAttribute("HelixLane", 0)
        task.wait(0.03)
        scored, links, rescanned = registry:snapshot(circuit)
        expect(rescanned).toBe(true)
        expect(scored[1]).toBe(scored10)

        -- Cosmetic child changes must not trigger an expensive rescan.
        local decoration = Instance.new("Part")
        decoration.Name = "CoreRampDecor999"
        decoration.Parent = circuit
        task.wait(0.03)
        local beforeTrim = registry.scanCount
        local _, _, afterTrim = registry:snapshot(circuit)
        expect(afterTrim).toBe(false)
        expect(registry.scanCount).toBe(beforeTrim)

        late:Destroy()
        task.wait(0.03)
        _, links, rescanned = registry:snapshot(circuit)
        expect(rescanned).toBe(true)
        expect(#links).toBe(2)
        registry:destroy()
        expect(registry.circuit).toBe(nil)
        expect(next(registry.partConnections) == nil).toBe(true)
        expect(#registry.connections).toBe(0)
        circuit:Destroy()
    end)

    it("disconnects every old arena observer when streaming replaces a circuit", function()
        local original = Instance.new("Folder")
        original.Parent = workspace
        local oldRamp = ramp(original, "EntryRamp1", "OrbitalAccessRamp", nil)
        local replacement = Instance.new("Folder")
        replacement.Parent = workspace
        local newRamp = ramp(replacement, "CoreRamp1", "OrbitalCoreRamp", nil)

        local registry = OrbitalRampRegistry.new(OrbitalRouteSignKit)
        local _, oldAccess = registry:snapshot(original)
        expect(#oldAccess).toBe(1)
        expect(oldAccess[1]).toBe(oldRamp)

        local scored, access, changed, replaced = registry:snapshot(replacement)
        expect(changed).toBe(true)
        expect(replaced).toBe(true)
        expect(#scored).toBe(0)
        expect(#access).toBe(1)
        expect(access[1]).toBe(newRamp)
        local scans = registry.scanCount

        oldRamp:SetAttribute("OrbitalAccessRamp", false)
        ramp(original, "EntryRamp7", "OrbitalAccessRamp", nil)
        task.wait(0.03)
        local _, _, dirty = registry:snapshot(replacement)
        expect(dirty).toBe(false)
        expect(registry.scanCount).toBe(scans)

        registry:destroy()
        original:Destroy()
        replacement:Destroy()
    end)

    it("fits approved underframes on all 24 Orbital ramps within the Low budget", function()
        local replicated=game:GetService("ReplicatedStorage")
        local previousMap=workspace:FindFirstChild("GeneratedMap")
        local previousSource=replicated:FindFirstChild("ApprovedRemainingStructureTemplates")
        if previousMap then previousMap.Parent=nil end
        if previousSource then previousSource.Parent=nil end

        local templates=Instance.new("Folder")
        templates.Name="ApprovedRemainingStructureTemplates"
        templates:SetAttribute("OwnerVerified",true)
        templates.Parent=replicated
        local function specimen(name,id,size)
            local model=Instance.new("Model")
            model.Name=name
            model:SetAttribute("OwnerVerified",true)
            model:SetAttribute("CosmeticOnly",true)
            model:SetAttribute("Original3DAssetId",id)
            model:SetAttribute("P4OriginalRemainingStructure3D",true)
            -- Stand-in material regions test the mounting lifecycle in the engine.
            for index=1,7 do
                local part=Instance.new("MeshPart")
                part.Name="OriginalMaterialRegion"..index
                part.Size=size
                part.Anchored=true
                part.Massless=true
                part.CanCollide=false
                part.CanTouch=false
                part.CanQuery=false
                part.Parent=model
            end
            model.Parent=templates
            return model
        end
        local model=specimen("AccessChassis",106401955318567,Vector3.new(5.17,.5065,12.8))

        local generated
        local phase="build Orbital"
        local ok,why=pcall(function()
            local arena=MapBuilder.buildArena(Config,"Orbital",ArenaVariants)
            generated=arena.Parent
            local base=arena:FindFirstChild("Base")
            local circuit=arena:FindFirstChild("HelixCircuit")
            local chassisCount=0
            for _,piece in ipairs(circuit:GetChildren()) do
                local kind,index=piece.Name:match("^(%a+)Chassis([1-8])$")
                if piece:IsA("BasePart") and (kind=="Entry" or kind=="Core") then
                    phase="Orbital access chassis Low "..piece.Name
                    local deck=circuit:FindFirstChild(kind.."Ramp"..index)
                    expect(deck~=nil and deck.CanCollide).toBe(true)
                    RemainingStructureKit.sync(nil,Vector3.zero,"Low",false)
                    RemainingStructureKit.sync(arena,deck.Position,"Low",true,nil,0,true)
                    expect(RemainingStructureKit.count("helix","AccessChassis")).toBe(1)
                    expect(RemainingStructureKit.count("casing")).toBe(0)
                    expect(RemainingStructureKit.nativeCount("helix")).toBe(1)
                    expect(piece.LocalTransparencyModifier).toBe(1)
                    chassisCount+=1
                end
            end
            expect(chassisCount).toBe(15)

            phase="Orbital access chassis hazards and streaming"
            RemainingStructureKit.sync(nil,Vector3.zero,"Low",false)
            local entry=circuit:FindFirstChild("EntryRamp1")
            local chassis=circuit:FindFirstChild("EntryChassis1")
            local signal=circuit:FindFirstChild("EntrySignal1_-1")
            chassis.LocalTransparencyModifier=.21
            local nativeAlpha=chassis.LocalTransparencyModifier
            RemainingStructureKit.sync(arena,entry.Position,"Low",true,nil,0,true)
            local art=workspace.ApprovedRemainingStructureMeshesLocal.ApprovedP4_AccessChassis
            expect(art:GetAttribute("OriginalP4OwnerPlatform")).toBe(entry.Name)
            for _,mesh in ipairs(art:GetChildren()) do
                local center=entry.CFrame:PointToObjectSpace(mesh.Position)
                expect(center.Y+mesh.Size.Y*.5 < -entry.Size.Y*.5).toBe(true)
                expect(not mesh.CanCollide and not mesh.CanTouch and not mesh.CanQuery).toBe(true)
            end
            expect(signal.LocalTransparencyModifier).toBe(0)
            entry:SetAttribute("CollapsePhase","Warning")
            task.wait()
            expect(chassis.LocalTransparencyModifier).toBe(nativeAlpha)
            expect(RemainingStructureKit.count("helix","AccessChassis")).toBe(0)
            entry:SetAttribute("CollapsePhase",nil)
            task.wait()
            expect(chassis.LocalTransparencyModifier).toBe(1)
            chassis.Parent=nil
            task.wait()
            expect(chassis.LocalTransparencyModifier).toBe(nativeAlpha)
            chassis.Parent=circuit
            task.wait()
            expect(chassis.LocalTransparencyModifier).toBe(1)

            phase="Orbital access chassis shrink and pressure"
            local snapshot=OrbitalHelix.capture(circuit)
            local originalWidth=art:FindFirstChildWhichIsA("MeshPart").Size.X
            OrbitalHelix.scale(snapshot,base.Position,.6)
            task.wait()
            expect(chassis.LocalTransparencyModifier).toBe(1)
            expect(art:FindFirstChildWhichIsA("MeshPart").Size.X<originalWidth).toBe(true)
            expect(entry.CanCollide and signal.LocalTransparencyModifier==0).toBe(true)
            OrbitalHelix.restore(snapshot)
            task.wait()
            expect(chassis.LocalTransparencyModifier).toBe(1)
            RemainingStructureKit.sync(arena,entry.Position,"Low",true,nil,1,true)
            expect(RemainingStructureKit.count("helix","AccessChassis")).toBe(0)
            expect(chassis.LocalTransparencyModifier).toBe(nativeAlpha)
            phase="source eviction"
            RemainingStructureKit.sync(arena,entry.Position,"Low",true,nil,0,true)
            expect(chassis.LocalTransparencyModifier).toBe(1)
            model:FindFirstChildWhichIsA("MeshPart"):Destroy()
            task.wait()
            expect(RemainingStructureKit.count("helix","AccessChassis")).toBe(0)
            expect(chassis.LocalTransparencyModifier).toBe(nativeAlpha)

            specimen("Helix",106863534763803,Vector3.new(5.08,1.453,23.6))
            local folder=workspace.ApprovedRemainingStructureMeshesLocal
            for index=1,9 do
                phase="Helix Low "..index
                local deck=circuit:FindFirstChild("HelixRamp"..index)
                local rail=circuit:FindFirstChild("HelixEdgeSignal"..index.."_-1")
                local nativeCount=index==9 and 5 or 4
                RemainingStructureKit.sync(nil,Vector3.zero,"Low",false)
                RemainingStructureKit.sync(arena,deck.Position,"Low",true,nil,0,true)
                expect(RemainingStructureKit.count("helix","Helix")).toBe(1)
                expect(RemainingStructureKit.nativeCount("helix")).toBe(nativeCount)
                expect(RemainingStructureKit.count("casing")).toBe(0)
                expect(folder.ApprovedP4_Helix:GetAttribute("OriginalP4OwnerPlatform")).toBe(deck.Name)
                expect(deck.CanCollide and rail.LocalTransparencyModifier==0).toBe(true)
            end

            phase="central crossing fit, warning and native rebinding"
            local core=circuit:FindFirstChild("HelixRamp9")
            local brace=circuit:FindFirstChild("HelixSpineBrace9_0")
            local coreArt=folder.ApprovedP4_Helix
            local mesh=coreArt:FindFirstChildWhichIsA("MeshPart")
            local initialWidth=mesh.Size.X
            local function insideNativeDepth()
                local center=core.CFrame:PointToObjectSpace(mesh.Position)
                return center.Y+mesh.Size.Y*.5 < -core.Size.Y*.5
                    and center.Y-mesh.Size.Y*.5 >= -.78
            end
            expect(insideNativeDepth()).toBe(true)
            expect(brace.LocalTransparencyModifier).toBe(1)
            core:SetAttribute("BridgeShutterPhase","Warning")
            task.wait()
            expect(brace.LocalTransparencyModifier).toBe(0)
            core:SetAttribute("BridgeShutterPhase",nil)
            task.wait()
            expect(brace.LocalTransparencyModifier).toBe(1)
            brace.Parent=nil
            task.wait()
            expect(brace.LocalTransparencyModifier).toBe(0)
            expect(RemainingStructureKit.count("helix","Helix")).toBe(0)
            local replacement=brace:Clone()
            replacement.Parent=circuit
            RemainingStructureKit.sync(arena,core.Position,"Low",true,nil,0,true)
            expect(RemainingStructureKit.nativeCount("helix")).toBe(5)
            expect(replacement.LocalTransparencyModifier).toBe(1)
            brace:Destroy()

            phase="central crossing shrink, shared slot and pressure"
            local coreSnapshot=OrbitalHelix.capture(circuit)
            OrbitalHelix.scale(coreSnapshot,base.Position,.45)
            task.wait()
            mesh=folder.ApprovedP4_Helix:FindFirstChildWhichIsA("MeshPart")
            expect(insideNativeDepth() and mesh.Size.X<initialWidth).toBe(true)
            expect(replacement.LocalTransparencyModifier).toBe(1)
            OrbitalHelix.restore(coreSnapshot)
            task.wait()
            expect(insideNativeDepth() and replacement.LocalTransparencyModifier==1).toBe(true)
            model:Destroy()
            specimen("AccessChassis",106401955318567,Vector3.new(5.17,.5065,12.8))
            RemainingStructureKit.sync(arena,core.Position,"Low",true,nil,0,true)
            expect(RemainingStructureKit.count("helix")).toBe(1)
            expect(RemainingStructureKit.count("helix","Helix")).toBe(1)
            RemainingStructureKit.sync(arena,core.Position,"Low",true,nil,1,true)
            expect(RemainingStructureKit.count("helix")).toBe(0)
            expect(replacement.LocalTransparencyModifier).toBe(0)
        end)
        RemainingStructureKit.sync(nil,Vector3.zero,"Low",false)
        if generated then generated:Destroy() end
        templates:Destroy()
        if previousMap then previousMap.Parent=workspace end
        if previousSource then previousSource.Parent=replicated end
        if not ok then error(phase..": "..tostring(why)) end
    end)

end)

return nil
