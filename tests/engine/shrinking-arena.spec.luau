--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local LargeStructure = require("../../src/client/PremiumLargeStructureMeshKit")
local Remaining = require("../../src/client/ApprovedRemainingStructureMeshKit")
local NativeTrim = require("../../src/client/PlatformNativeTrimReplacementKit")
local ShrinkingArena = require("../../src/server/Disasters/ShrinkingArena")
local DisappearingPlatforms = require("../../src/server/Disasters/DisappearingPlatforms")
local Rim = require("../../src/client/ApprovedPlatformRimMeshKit")
local SkybridgePressure = require("../../src/server/SkybridgePressure")
local OrbitalHelix = require("../../src/server/OrbitalHelix")
local ArenaMechanics = require("../../src/server/ArenaMechanics")

local function cleanup(callbacks, objects)
    for _, fn in ipairs(callbacks) do
        pcall(fn)
    end
    for _, object in ipairs(objects) do
        if object and object.Parent then
            object:Destroy()
        end
    end
end

describe("Shrinking Arena mobility integration", function()
    it("keeps every ordinary platform trim on its moving deck and restores it", function()
        local root = MapBuilder.build(Config, "Classic", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local platforms = arena and arena:FindFirstChild("Platforms")
        local decor = arena and arena:FindFirstChild("Decor")
        local deck = platforms and platforms:FindFirstChild("Platform1")
        expect(deck ~= nil).toBe(true)
        expect(decor ~= nil).toBe(true)
        local originalDeck = deck.CFrame
        local originalDeckSize = deck.Size
        local base = arena:FindFirstChild("Base")
        local originalFloorX = base.Size.X
        local originalBaseFrame = base.CFrame
        local frame = decor:FindFirstChild("ArenaUndercarriage")
        expect(frame ~= nil and frame:IsA("Model")).toBe(true)
        local originalRails = {}
        for _, rail in ipairs(frame:GetChildren()) do
            expect(rail:IsA("BasePart")).toBe(true)
            expect(rail.CanCollide).toBe(false)
            originalRails[rail] = {
                cframe = rail.CFrame,
                size = rail.Size,
                relative = originalBaseFrame:ToObjectSpace(rail.CFrame),
            }
        end
        expect(#frame:GetChildren()).toBe(4)

        -- The cosmetic pieces must remain attached to their associated
        -- physical deck, not to the arena center or their old world pose.
        local names = {
            "PlatformGlow1",
            "PlatformPanel1",
            "PlatformUnderFrame1",
            "PlatformCoreGlow1",
            "PlatformSupport1_1",
            "PlatformBevel1_1",
            "PlatformBevel1_4",
        }
        local snapshot = {}
        for _, name in ipairs(names) do
            local piece = decor:FindFirstChild(name)
            expect(piece ~= nil).toBe(true)
            expect(piece.CanCollide).toBe(false)
            snapshot[piece] = {
                cframe = piece.CFrame,
                size = piece.Size,
                relative = deck.CFrame:ToObjectSpace(piece.CFrame),
            }
        end

        local columns = decor:FindFirstChild("OriginalPremiumColumnCladding")
        local columnParts = {}
        for i = 1, 4 do
            local casing = columns:FindFirstChild("ClassicArchitecturalCasing" .. i)
            local foot = casing:FindFirstChild("FoundationFoot")
            local core = decor:FindFirstChild("FrameColumn" .. i)
            local light = decor:FindFirstChild("FrameColumnGlow" .. i)
            local front = casing:FindFirstChild("ArmoredFrontShell")
            expect(casing.PrimaryPart).toBe(foot)
            local toward = base.Position-foot.Position
            toward = Vector3.new(toward.X,0,toward.Z)
            assert(front.CFrame.LookVector:Dot(toward.Unit)>.999,
                "column front faces away from the arena: "..casing.Name)
            assert(foot.Position.Y-foot.Size.Y*.5>=base.Position.Y+base.Size.Y*.5,
                "native casing foot is below the floor: "..casing.Name)
            columnParts[i] = {foot,core,light,casing:FindFirstChild("LandmarkNavigationHead")}
        end
        local columnFrames = {}
        for _, group in ipairs(columnParts) do
            for _,part in ipairs(group) do columnFrames[part]=part.CFrame end
        end

        local storage = game:GetService("ReplicatedStorage")
        local prior = storage:FindFirstChild("ApprovedRemainingStructureTemplates")
        if prior then prior.Parent = nil end
        local templates = Instance.new("Folder")
        templates.Name = "ApprovedRemainingStructureTemplates"
        templates:SetAttribute("OwnerVerified", true)
        templates.Parent = storage
        local source = Instance.new("Model")
        source.Name = "Casing"
        source:SetAttribute("OwnerVerified", true)
        source:SetAttribute("CosmeticOnly", true)
        source:SetAttribute("Original3DAssetId", 130196548599769)
        source:SetAttribute("P4OriginalRemainingStructure3D", true)
        for i = 1, 7 do
            local part = Instance.new("MeshPart")
            part.Name = "CasingMaterial" .. i
            -- Simulate the same approved source imported long in Z.
            part.Size = Vector3.new(5.3, 10.378, 8.58)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Parent = source
        end
        source.Parent = templates
        Remaining.sync(arena, base.Position, "Low", true, nil, 0, true)
        expect(Remaining.count("casing")).toBe(1)
        expect(Remaining.nativeCount("casing")).toBe(11)
        local localArt = workspace:FindFirstChild("ApprovedRemainingStructureMeshesLocal")
        local sculpt = assert(localArt:FindFirstChild("ApprovedP4_Casing"))
        local casingName = sculpt:GetAttribute("OriginalP4OwnerPlatform")
        local owned = columns:FindFirstChild(casingName)
        local foot = owned:FindFirstChild("FoundationFoot")
        local mesh = sculpt:FindFirstChildWhichIsA("MeshPart")
        local head = owned:FindFirstChild("LandmarkNavigationHead")
        local function verifyFit()
            expect(foot.LocalTransparencyModifier).toBe(1)
            expect(head.LocalTransparencyModifier).toBe(0)
            expect(mesh.LocalTransparencyModifier).toBe(0)
            local widthAxis = owned.ArmoredFrontShell.CFrame.RightVector
            assert(math.abs(mesh.CFrame.LookVector:Dot(widthAxis))>.999,
                "long-Z casing was not rotated onto the native fascia")
            local limits = {}
            for _,name in ipairs({"AerialCantilever-1","AerialCantilever1"}) do
                local spar = owned:FindFirstChild(name)
                local offset = (spar.Position-foot.Position):Dot(widthAxis)
                local half = (math.abs(spar.CFrame.RightVector:Dot(widthAxis))*spar.Size.X
                    + math.abs(spar.CFrame.UpVector:Dot(widthAxis))*spar.Size.Y
                    + math.abs(spar.CFrame.LookVector:Dot(widthAxis))*spar.Size.Z)*.5
                table.insert(limits, math.abs(offset)+half)
            end
            local expected = math.max(8.58,2*limits[1],2*limits[2])
            assert(math.abs(mesh.Size.Z-expected)<.03, string.format(
                "casing width is %.3f, expected %.3f",mesh.Size.Z,expected))
            assert(math.abs(mesh.Position.Y-mesh.Size.Y*.5
                -(foot.Position.Y-foot.Size.Y*.5))<.03, "casing foot does not meet the slab")
            assert((Vector3.new(mesh.Position.X,foot.Position.Y,mesh.Position.Z)
                -foot.Position).Magnitude<.03, "casing and native foot are misaligned")
        end
        verifyFit()

        local active = true
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config,
            RoundSeconds = 0.32,
            Cleanup = {},
            OnCleanup = callbacks,
            Active = function() return active end,
        })
        task.wait(0.19)

        expect((deck.Position - originalDeck.Position).Magnitude > 0.2)
            .toBe(true)
        local scale = base.Size.X / originalFloorX
        expect(scale < 0.98).toBe(true)
        expect(math.abs(deck.Size.X - originalDeckSize.X * scale) < 0.02)
            .toBe(true)
        expect(math.abs(deck.Size.Z - originalDeckSize.Z * scale) < 0.02)
            .toBe(true)
        for rail, original in pairs(originalRails) do
            local p = original.relative.Position
            local expected = originalBaseFrame
                * CFrame.new(p.X * scale, p.Y, p.Z * scale)
                * (original.relative - p)
            expect((rail.Position - expected.Position).Magnitude < 0.02)
                .toBe(true)
            local size = Vector3.new(
                original.size.X * scale,
                original.size.Y,
                original.size.Z * scale
            )
            expect((rail.Size - size).Magnitude < 0.02).toBe(true)
            expect(rail.CanCollide).toBe(false)
        end
        for piece, original in pairs(snapshot) do
            local p = original.relative.Position
            local expected = deck.CFrame
                * CFrame.new(p.X * scale, p.Y, p.Z * scale)
                * (original.relative - p)
            expect((piece.Position - expected.Position).Magnitude < 0.02)
                .toBe(true)
            local size = Vector3.new(
                original.size.X * scale,
                original.size.Y,
                original.size.Z * scale
            )
            expect((piece.Size - size).Magnitude < 0.02)
                .toBe(true)
            expect(piece.CanCollide).toBe(false)
        end

        for _, group in ipairs(columnParts) do
            local start = columnFrames[group[1]].Position
            local expected = Vector3.new(start.X*(scale-1),0,start.Z*(scale-1))
            for _,part in ipairs(group) do
                expect((part.Position-columnFrames[part].Position-expected).Magnitude<.03).toBe(true)
            end
        end
        verifyFit()
        source:SetAttribute("OwnerVerified",false)
        expect(foot.LocalTransparencyModifier).toBe(0)
        expect(mesh.LocalTransparencyModifier).toBe(1)
        source:SetAttribute("OwnerVerified",true)
        verifyFit()
        local shell = owned:FindFirstChild("ArmoredFrontShell")
        shell.Parent=nil
        expect(shell.LocalTransparencyModifier).toBe(0)
        expect(foot.LocalTransparencyModifier).toBe(0)
        shell.Parent=owned
        verifyFit()

        active = false
        cleanup(callbacks, {})
        expect((deck.Position - originalDeck.Position).Magnitude < 0.001)
            .toBe(true)
        expect((deck.Size - originalDeckSize).Magnitude < 0.001)
            .toBe(true)
        for rail, original in pairs(originalRails) do
            expect((rail.Position - original.cframe.Position).Magnitude < 0.001)
                .toBe(true)
            expect((rail.Size - original.size).Magnitude < 0.001).toBe(true)
        end
        for piece, original in pairs(snapshot) do
            expect((piece.Position - original.cframe.Position).Magnitude < 0.001)
                .toBe(true)
            expect((piece.Size - original.size).Magnitude < 0.001)
                .toBe(true)
        end
        for part,original in pairs(columnFrames) do
            expect((part.Position-original.Position).Magnitude<.02).toBe(true)
        end
        verifyFit()
        Remaining.sync(arena,base.Position,"Low",true,nil,1,true)
        expect(Remaining.count("casing")).toBe(0)
        expect(foot.LocalTransparencyModifier).toBe(0)
        expect(base.CanCollide).toBe(true)
        Remaining.sync(nil,Vector3.zero,"Low",false)
        templates:Destroy()
        if prior then prior.Parent=storage end
        root:Destroy()
    end)

    it("retracts wayfinding floor cues and moves lookout signals with their real deck", function()
        local root = MapBuilder.build(Config, "Classic", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local decor = arena:FindFirstChild("Decor")
        local base = arena:FindFirstChild("Base")
        local platforms = arena:FindFirstChild("Platforms")
        local terminal = platforms:FindFirstChild(
            "Platform" .. tostring(#ArenaVariants.get("Classic").Platforms + 8)
        )
        local floorArrow = decor:FindFirstChild("OuterRouteChevron1_1_-1")
        local arrow = decor:FindFirstChild("OuterStepChevron1_8_-1")
        local signal = decor:FindFirstChild("OuterRouteSignal1")
        expect(floorArrow ~= nil).toBe(true)
        expect(arrow ~= nil).toBe(true)
        expect(signal ~= nil).toBe(true)
        local before = {
            floor = floorArrow.CFrame,
            arrow = arrow.CFrame,
            signal = signal.CFrame,
            deck = terminal.CFrame,
            arrowSize = arrow.Size,
            signalSize = signal.Size,
        }
        local localFloor = base.CFrame:PointToObjectSpace(floorArrow.Position)
        local localArrow = terminal.CFrame:ToObjectSpace(arrow.CFrame)
        local localSignal = terminal.CFrame:ToObjectSpace(signal.CFrame)
        local width = base.Size.X
        local active = true
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config,
            RoundSeconds = 0.35,
            OnCleanup = callbacks,
            Active = function() return active end,
        })
        task.wait(0.21)
        local scale = base.Size.X / width
        expect(scale < 0.98).toBe(true)
        local expectedFloor = base.CFrame:PointToWorldSpace(Vector3.new(
            localFloor.X * scale, localFloor.Y, localFloor.Z * scale
        ))
        expect((floorArrow.Position - expectedFloor).Magnitude < 0.03)
            .toBe(true)
        for _, record in ipairs({
            {piece = arrow, relative = localArrow, size = before.arrowSize},
            {piece = signal, relative = localSignal, size = before.signalSize},
        }) do
            local p = record.relative.Position
            local expected = terminal.CFrame
                * CFrame.new(p.X * scale, p.Y, p.Z * scale)
                * (record.relative - p)
            expect((record.piece.Position - expected.Position).Magnitude < 0.03)
                .toBe(true)
            expect(math.abs(record.piece.Size.X - record.size.X * scale) < 0.03)
                .toBe(true)
        end
        active = false
        cleanup(callbacks, {})
        expect((floorArrow.Position - before.floor.Position).Magnitude < 0.001)
            .toBe(true)
        expect((arrow.Position - before.arrow.Position).Magnitude < 0.001)
            .toBe(true)
        expect((signal.Position - before.signal.Position).Magnitude < 0.001)
            .toBe(true)
        expect((terminal.Position - before.deck.Position).Magnitude < 0.001)
            .toBe(true)
        root:Destroy()
    end)

    it("moves outer exit sculptures together with shrinking physical routes", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local decor = arena:FindFirstChild("Decor")
            local platforms = arena:FindFirstChild("Platforms")
            local base = arena:FindFirstChild("Base")
            -- Exit facade follows the LAST physical terrace (step 8),
            -- not the old fourth platform in the enlarged route.
            local number = #ArenaVariants.get(id).Platforms
                + ArenaVariants.PerimeterSteps
            local deck = platforms:FindFirstChild("Platform" .. number)
            expect(deck ~= nil).toBe(true)
            local startDeck = deck.CFrame
            local floorWidth = base.Size.X
            local pieces = {}
            for _, name in ipairs({
                "PerimeterExitRib1_-1", "PerimeterExitRib1_1",
                "PerimeterExitCrown1", "PerimeterExitLens1",
            }) do
                local piece = decor:FindFirstChild(name)
                expect(piece ~= nil).toBe(true)
                expect(piece:GetAttribute("PerimeterPlatformIndex")).toBe(number)
                pieces[piece] = {
                    size = piece.Size,
                    cframe = piece.CFrame,
                    relative = deck.CFrame:ToObjectSpace(piece.CFrame),
                }
            end

            local active = true
            local callbacks = {}
            ShrinkingArena.start({
                Config = Config, RoundSeconds = 0.32,
                Cleanup = {}, OnCleanup = callbacks,
                Active = function() return active end,
            })
            task.wait(0.19)
            local scale = base.Size.X / floorWidth
            expect(scale < 0.98).toBe(true)
            expect((deck.Position - startDeck.Position).Magnitude > 0.1).toBe(true)
            for piece, state in pairs(pieces) do
                local offset = state.relative.Position
                local expected = deck.CFrame
                    * CFrame.new(offset.X * scale, offset.Y, offset.Z * scale)
                    * (state.relative - offset)
                expect((piece.Position - expected.Position).Magnitude < 0.03).toBe(true)
                expect(math.abs(piece.Size.X - state.size.X * scale) < 0.03
                    and math.abs(piece.Size.Z - state.size.Z * scale) < 0.03)
                    .toBe(true)
                expect(piece.CanCollide).toBe(false)
            end
            active = false
            cleanup(callbacks, {})
            expect((deck.Position - startDeck.Position).Magnitude < 0.001).toBe(true)
            for piece, state in pairs(pieces) do
                expect((piece.Position - state.cframe.Position).Magnitude < 0.001)
                    .toBe(true)
                expect((piece.Size - state.size).Magnitude < 0.001).toBe(true)
            end
            root:Destroy()
        end
    end)

    it("shrinks arena inlays with the solid floor in every variant", function()
        local cases = {
            {
                id = "Classic",
                names = {"ArenaDeckInset", "DeckLineNorth", "ClassicGridX-2",
                    "ClassicEntryChevron1_-1"},
            },
            {
                id = "Towers",
                names = {"ArenaDeckInset", "DeckLineEast",
                    "TowerGroundPlate1", "TowerGroundCore1",
                    "TowerAscentChevron1_-1"},
            },
            {
                id = "Crossroads",
                names = {"ArenaDeckInset", "DeckLineSouth",
                    "CrossroadLaneFill1", "FluxRouteChevron1_1_-1"},
            },
            {
                id = "Orbital",
                names = {"ArenaDeckInset", "DeckLineWest"},
            },
        }

        for _, case in ipairs(cases) do
            local root = MapBuilder.build(Config, case.id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local base = arena:FindFirstChild("Base")
            local decor = arena:FindFirstChild("Decor")
            local origin = base.CFrame
            local originalBase = base.Size
            local floorSnapshot = {}
            for _, name in ipairs(case.names) do
                local part = decor:FindFirstChild(name)
                expect(part ~= nil).toBe(true)
                expect(part.CanCollide).toBe(false)
                floorSnapshot[part] = {
                    cframe = part.CFrame,
                    size = part.Size,
                    localPosition = origin:PointToObjectSpace(part.Position),
                }
            end

            local active = true
            local callbacks = {}
            ShrinkingArena.start({
                Config = Config,
                RoundSeconds = 0.33,
                Cleanup = {},
                OnCleanup = callbacks,
                Active = function() return active end,
            })
            task.wait(0.20)
            local scale = base.Size.X / originalBase.X
            expect(scale < 0.90).toBe(true)

            for piece, before in pairs(floorSnapshot) do
                local expectedSize, expectedPosition =
                    ShrinkingArena.scaledFloorTransform(
                        before.size, before.localPosition, scale
                    )
                local expectedWorld = origin:PointToWorldSpace(expectedPosition)
                expect((piece.Size - expectedSize).Magnitude < 0.02)
                    .toBe(true)
                expect((piece.Position - expectedWorld).Magnitude < 0.02)
                    .toBe(true)
                expect(piece.CanCollide).toBe(false)
            end
            local inset = decor:FindFirstChild("ArenaDeckInset")
            expect(inset.Size.X < base.Size.X).toBe(true)
            expect(inset.Size.Z < base.Size.Z).toBe(true)

            active = false
            cleanup(callbacks, {})
            for piece, before in pairs(floorSnapshot) do
                expect((piece.CFrame.Position - before.cframe.Position).Magnitude < 0.001)
                    .toBe(true)
                expect((piece.Size - before.size).Magnitude < 0.001)
                    .toBe(true)
            end
            root:Destroy()
        end
    end)

    it("moves mobility pads inward and restores them on cleanup", function()
        MapBuilder.build(Config, "Towers", ArenaVariants)

        local generated = workspace:FindFirstChild("GeneratedMap")
        local arena = generated and generated:FindFirstChild("Arena")
        local base = arena and arena:FindFirstChild("Base")
        expect(base ~= nil).toBe(true)

        local mechanics = Instance.new("Folder")
        mechanics.Name = "Mechanics"
        mechanics.Parent = arena

        local pad = Instance.new("Part")
        pad.Name = "MobilityPadRegression"
        pad.Anchored = true
        pad.Size = Vector3.new(6.5, 0.35, 6.5)
        pad.Position = (base :: BasePart).Position + Vector3.new(28, 1.7, 28)
        pad:SetAttribute("ArenaMobilityPad", true)
        pad:SetAttribute("ImpulseX", 40)
        pad:SetAttribute("ImpulseY", 10)
        pad:SetAttribute("ImpulseZ", -20)
        pad.Parent = mechanics

        local original = pad.CFrame
        local originalImpulse = Vector3.new(40, 10, -20)
        local originalDistance = (
            Vector3.new(pad.Position.X, 0, pad.Position.Z)
            - Vector3.new((base :: BasePart).Position.X, 0, (base :: BasePart).Position.Z)
        ).Magnitude

        local active = true
        local objects = {}
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config,
            RoundSeconds = 0.30,
            Cleanup = objects,
            OnCleanup = callbacks,
            Active = function()
                return active
            end,
        })

        task.wait(0.18)

        local movedDistance = (
            Vector3.new(pad.Position.X, 0, pad.Position.Z)
            - Vector3.new((base :: BasePart).Position.X, 0, (base :: BasePart).Position.Z)
        ).Magnitude
        expect(movedDistance < originalDistance).toBe(true)

        local shrunkImpulse = Vector3.new(
            tonumber(pad:GetAttribute("ImpulseX")) or 0,
            tonumber(pad:GetAttribute("ImpulseY")) or 0,
            tonumber(pad:GetAttribute("ImpulseZ")) or 0
        )
        expect(math.abs(shrunkImpulse.X) < math.abs(originalImpulse.X)).toBe(true)
        expect(math.abs(shrunkImpulse.Z) < math.abs(originalImpulse.Z)).toBe(true)
        expect(shrunkImpulse.Y).toBe(originalImpulse.Y)

        active = false
        cleanup(callbacks, objects)
        expect(pad.CFrame).toBe(original)
        expect(pad:GetAttribute("ImpulseX")).toBe(originalImpulse.X)
        expect(pad:GetAttribute("ImpulseY")).toBe(originalImpulse.Y)
        expect(pad:GetAttribute("ImpulseZ")).toBe(originalImpulse.Z)

        if generated then
            generated:Destroy()
        end
    end)
    local function shortChassisFixture(storage)
        local holder=Instance.new("Folder")
        holder.Name="ApprovedRemainingStructureTemplates"
        holder:SetAttribute("OwnerVerified",true)
        holder.Parent=storage
        local source=Instance.new("Model")
        source.Name="AccessChassis"
        source:SetAttribute("Original3DAssetId",106401955318567)
        for _,attribute in ipairs({"OwnerVerified","CosmeticOnly","P4OriginalRemainingStructure3D"}) do
            source:SetAttribute(attribute,true)
        end
        for index=1,7 do
            local piece=Instance.new("MeshPart")
            if index==7 then
                piece.Name="UnderdeckSignal"
                piece.Size=Vector3.new(1.09,.05,12.15)
            elseif index==6 then
                piece.Name="UnderdeckLattice"
                piece.Size=Vector3.new(4.492,.215,11.5957)
            else
                piece.Name="Region"..index
                piece.Size=Vector3.new(5.17,.5065,12.8)
            end
            piece.Anchored=true
            piece.Massless=true
            piece.CanCollide=false
            piece.CanTouch=false
            piece.CanQuery=false
            piece.Parent=source
        end
        source.Parent=holder
        return holder
    end

    local function checkUnderdeckSignal(arena,deck)
        local bridgeIndex=deck.Name:match("^Skybridge(%d+)$")
        local index=assert(bridgeIndex or deck.Name:match("^Platform(%d+)$"))
        local glow=arena.Decor:FindFirstChild("PlatformCoreGlow"..index)
        assert(glow and glow:IsA("MeshPart") and glow.Material==Enum.Material.Neon)
        assert(glow.Anchored and not glow.CanCollide and not glow.CanTouch and not glow.CanQuery)
        assert(#glow:GetChildren()==0 and glow.Transparency<1)
        local offset=deck.CFrame:ToObjectSpace(glow.CFrame)
        local acrossX=math.abs(offset.LookVector.X)>.99
        local extentX=acrossX and glow.Size.Z or glow.Size.X
        local extentZ=acrossX and glow.Size.X or glow.Size.Z
        local alongX=deck.Size.X>deck.Size.Z
        local relativeWidth=bridgeIndex and .34 or .22
        assert(math.abs(extentX-deck.Size.X*(alongX and .62 or relativeWidth))<.025)
        assert(math.abs(extentZ-deck.Size.Z*(alongX and relativeWidth or .62))<.025)
        assert(math.abs(offset.Y+deck.Size.Y*.5+.52)<.015)
        assert(math.abs(glow.Size.Y-.30)<.01)
        return glow
    end

    local function forgedSignalFixture(alongZ)
        local holder = Instance.new("Folder")
        holder.Name = "ApprovedTowersSignatureBridgeTemplates"
        holder:SetAttribute("OwnerVerified", true)
        local source = Instance.new("Model")
        source.Name = "ForgedBridge"
        source:SetAttribute("OwnerVerified", true)
        source:SetAttribute("CosmeticOnly", true)
        source:SetAttribute("OriginalTowersSignatureBridge3D", true)
        source:SetAttribute("Original3DAssetId", 126298311664881)
        source.Parent = holder
        local beam = Instance.new("MeshPart")
        beam.Name = "SweptCrossbeam"
        beam.Size = alongZ and Vector3.new(5.96, 3.1108, 40.64)
            or Vector3.new(40.64, 3.1108, 5.96)
        beam.Anchored = true
        beam.CanCollide = false
        beam.CanTouch = false
        beam.CanQuery = false
        beam.Parent = source
        local edgeBand = beam:Clone()
        edgeBand.Name = "SculptedEdgeBand"
        edgeBand.Size = alongZ and Vector3.new(5.43, .1625, 39.38)
            or Vector3.new(39.38, .1625, 5.43)
        edgeBand.Parent = source
        return holder
    end

    local function checkRouteSignal(deck, piece, targetSize, targetOffset)
        assert(piece:IsA("MeshPart") and piece.Material==Enum.Material.Neon)
        assert(piece.Anchored and not piece.CanCollide and not piece.CanTouch and not piece.CanQuery)
        local frame = deck.CFrame:ToObjectSpace(piece.CFrame)
        local x, y, z = frame.RightVector, frame.UpVector, frame.LookVector
        local size = piece.Size
        local extent = Vector3.new(
            math.abs(x.X)*size.X+math.abs(y.X)*size.Y+math.abs(z.X)*size.Z,
            math.abs(x.Y)*size.X+math.abs(y.Y)*size.Y+math.abs(z.Y)*size.Z,
            math.abs(x.Z)*size.X+math.abs(y.Z)*size.Y+math.abs(z.Z)*size.Z
        )
        assert((extent-targetSize).Magnitude<.025)
        assert((frame.Position-targetOffset).Magnitude<.025)
    end

    local function checkAerialBand(arena,deck,scale)
        local index=assert(deck.Name:match("^Platform(%d+)$"))
        local piece=arena.Decor["PlatformGlow"..index]
        local alongX=deck.Size.X>deck.Size.Z
        checkRouteSignal(deck,piece,deck.Size*Vector3.new(1,0,1)+Vector3.new(
            (alongX and .28 or .96)*scale,.14,(alongX and .96 or .28)*scale),
            Vector3.new(0,-deck.Size.Y*.5-.47,0))
        return piece
    end

    it("shrinks four Tower Run skybridge decks, rails and supports as one assembly", function()
        local storage = game:GetService("ReplicatedStorage")
        local holder = forgedSignalFixture(false)
        local previous = storage:FindFirstChild(holder.Name)
        if previous then previous.Parent = nil end
        holder.Parent = storage
        local previousChassis = storage:FindFirstChild("ApprovedRemainingStructureTemplates")
        if previousChassis then previousChassis.Parent = nil end
        local chassisHolder = shortChassisFixture(storage)
        local built, root = pcall(MapBuilder.build, Config, "Towers", ArenaVariants)
        holder:Destroy()
        chassisHolder:Destroy()
        if previous then previous.Parent = storage end
        if previousChassis then previousChassis.Parent = storage end
        if not built then error(root) end
        local arena = root:FindFirstChild("Arena")
        local platforms = arena:FindFirstChild("Platforms")
        local decor = arena:FindFirstChild("Decor")
        local originals = {}
        local details = {}

        -- The new tower traversal must shrink as a complete connected
        -- physical system, not leave its decks full-sized under small
        -- moving skybridges.
        local tiers = {}
        for _, index in ipairs({1, 2, 3, 13, 14}) do
            local deck = platforms:FindFirstChild("Platform" .. index)
            local panel = decor:FindFirstChild("PlatformPanel" .. index)
            expect(deck ~= nil).toBe(true)
            expect(panel ~= nil).toBe(true)
            expect(deck:GetAttribute("RouteTier") ~= nil).toBe(true)
            tiers[#tiers + 1] = {
                deck = deck,
                panel = panel,
                deckCFrame = deck.CFrame,
                deckSize = deck.Size,
                panelCFrame = panel.CFrame,
                panelSize = panel.Size,
            }
        end
        local base = arena:FindFirstChild("Base")
        local baseOriginalX = base.Size.X

        expect(ShrinkingArena.skybridgeSpan(49, 1)).toBe(49)
        expect(math.abs(ShrinkingArena.skybridgeSpan(49, 0.45) - 18.2) < 0.01).toBe(true)
        local templates = Instance.new("Folder")
        templates.Name = "ApprovedLargeStructureTemplates"
        templates:SetAttribute("OwnerVerified", true)
        templates.Parent = game:GetService("ReplicatedStorage")
        local towers = Instance.new("Model")
        towers.Name = "Towers"
        towers:SetAttribute("OwnerVerified", true)
        towers:SetAttribute("CosmeticOnly", true)
        towers:SetAttribute("Original3DAssetId", 107521411452905)
        towers:SetAttribute("OriginalLargeStructure3D", true)
        for i = 1, 7 do
            local mesh = Instance.new("MeshPart")
            mesh.Name = "Material" .. i
            mesh.Size = Vector3.new(1.93, 13.91, 1.93)
            mesh.Anchored = true
            mesh.CanCollide = false
            mesh.CanTouch = false
            mesh.CanQuery = false
            mesh.Parent = towers
        end
        towers.Parent = templates
        local bridge18 = platforms:FindFirstChild("Skybridge18")
        local pressure = SkybridgePressure.snapshot(bridge18, decor)
        local guardedRib = decor:FindFirstChild("SkybridgeRib18_0")
        local guardedFrame = decor:FindFirstChild("PlatformUnderFrame18")
        local guardedBevel = decor:FindFirstChild("PlatformBevel18_1")
        local guardedGlow = checkUnderdeckSignal(arena, bridge18)
        local guardedBand = decor:FindFirstChild("PlatformGlow18")
        local surfaceRail = decor:FindFirstChild("SkybridgeRail18_1")
        local railTransparency = surfaceRail.Transparency
        SkybridgePressure.setPhase(pressure, "Warning", workspace:GetServerTimeNow())
        expect(math.abs(guardedRib.Transparency - 0.65) < 0.001).toBe(true)
        expect(math.abs(guardedFrame.Transparency - 0.65) < 0.001).toBe(true)
        expect(math.abs(guardedBevel.Transparency - 0.65) < 0.001).toBe(true)
        expect(math.abs(guardedGlow.Transparency - 0.65) < 0.001).toBe(true)
        expect(math.abs(guardedBand.Transparency - 0.65) < 0.001).toBe(true)
        SkybridgePressure.setPhase(pressure, "Gone")
        expect(guardedRib.Transparency).toBe(1)
        expect(guardedFrame.Transparency).toBe(1)
        expect(guardedBevel.Transparency).toBe(1)
        expect(guardedGlow.Transparency).toBe(1)
        expect(guardedBand.Transparency).toBe(1)
        SkybridgePressure.setPhase(pressure, nil)
        expect(guardedRib.Transparency).toBe(0)
        expect(math.abs(guardedFrame.Transparency - 0.04) < 0.001).toBe(true)
        expect(math.abs(guardedBevel.Transparency - 0.08) < 0.001).toBe(true)
        expect(math.abs(guardedGlow.Transparency - 0.56) < 0.001).toBe(true)
        expect(math.abs(guardedBand.Transparency - 0.64) < 0.001).toBe(true)
        expect(surfaceRail.Transparency).toBe(railTransparency)
        local pier2 = decor:FindFirstChild("PlatformSupport18_2")
        local visual = Instance.new("Folder")
        visual.Parent = root
        local _, selected, preferred = LargeStructure.selectNearRouteStructures(
            {bridge18}, decor, "Towers", "Low", base, pier2.Position, nil, 0, false)
        expect(selected[bridge18]).toBe(true)
        expect(preferred).toBe(bridge18)
        local _, _, midspanPreference = LargeStructure.selectNearRouteStructures(
            {bridge18}, decor, "Towers", "Low", base, bridge18.Position, nil, 0, false)
        expect(midspanPreference).toBe(nil)
        local _, pressured = LargeStructure.selectNearRouteStructures(
            {bridge18}, decor, "Towers", "Medium", base, pier2.Position, nil, 1, false)
        expect(pressured[bridge18]).toBe(nil)

        local columns = assert(LargeStructure.supports(
            visual, decor, bridge18, "Towers", "Low", 18, 1, true, pier2.Position))
        expect(#columns.parts).toBe(7)
        expect(columns.covered[1]).toBe(pier2)
        NativeTrim.bind(arena, {}, nil, columns.covered, visual)
        expect(pier2.LocalTransparencyModifier).toBe(1)
        bridge18:SetAttribute("BridgeShutterPhase", "Warning")
        expect(pier2.LocalTransparencyModifier).toBe(0)
        expect(columns.parts[1].LocalTransparencyModifier).toBe(1)
        bridge18:SetAttribute("BridgeShutterPhase", "Idle")
        expect(pier2.LocalTransparencyModifier).toBe(1)

        for index = 18, 21 do
            local bridge = platforms:FindFirstChild("Skybridge" .. index)
            expect(bridge ~= nil).toBe(true)
            expect(bridge.CanCollide).toBe(true)
            expect(bridge:GetAttribute("ChaosSkybridge")).toBe(true)
            checkUnderdeckSignal(arena, bridge)
            for side = 1, 2 do
                local post = decor:FindFirstChild("PlatformSupport" .. index .. "_" .. side)
                expect(LargeStructure.matchesSkybridgeSupport(post,bridge)).toBe(true)
            end
            local prefix = {
                "SkybridgeRail" .. index .. "_-1",
                "SkybridgeRail" .. index .. "_1",
                "SkybridgeRib" .. index .. "_-1",
                "SkybridgeRib" .. index .. "_0",
                "SkybridgeRib" .. index .. "_1",
                "PlatformGlow" .. index,
                "PlatformPanel" .. index,
                "PlatformUnderFrame" .. index,
                "PlatformCoreGlow" .. index,
                "PlatformSupport" .. index .. "_1",
                "PlatformBevel" .. index .. "_1",
                "PlatformBevel" .. index .. "_2",
                "PlatformBevel" .. index .. "_3",
                "PlatformBevel" .. index .. "_4",
            }
            originals[bridge] = {cf = bridge.CFrame, size = bridge.Size}
            details[bridge] = {}
            for _, name in ipairs(prefix) do
                local part = decor:FindFirstChild(name)
                expect(part ~= nil).toBe(true)
                local alongX = bridge.Size.X > bridge.Size.Z
                local lateral = alongX and Vector3.zAxis or Vector3.xAxis
                if name:match("^SkybridgeRail") then
                    local longitudinal = alongX and Vector3.xAxis or Vector3.zAxis
                    local offset = bridge.CFrame:PointToObjectSpace(part.Position)
                    expect(part:IsA("MeshPart") and part.Material == Enum.Material.Neon).toBe(true)
                    expect(part:GetAttribute("ChaosWayfinding")).toBe(true)
                    expect(math.abs(part.CFrame.RightVector:Dot(longitudinal)) > 0.999).toBe(true)
                    expect(math.abs(part.Size.X - 48.2) < 0.01).toBe(true)
                    expect(math.abs(part.Size.Z - 0.18) < 0.01).toBe(true)
                    expect(math.abs(offset:Dot(lateral)) > 1.95).toBe(true)
                    expect(part.CanTouch or part.CanQuery).toBe(false)
                elseif name:match("^PlatformUnderFrame") then
                    local longitudinal = alongX and Vector3.xAxis or Vector3.zAxis
                    local below = bridge.CFrame:PointToObjectSpace(part.Position).Y
                    expect(part:IsA("MeshPart")).toBe(true)
                    expect(math.abs(part.CFrame.LookVector:Dot(longitudinal)) > 0.999).toBe(true)
                    expect(math.abs(part.Size.X - 4.5 * 0.93) < 0.01).toBe(true)
                    expect(math.abs(part.Size.Z - 49 * 0.98) < 0.01).toBe(true)
                    expect(below + part.Size.Y * 0.5 < 0).toBe(true)
                    expect(part.CanTouch or part.CanQuery).toBe(false)
                elseif name:match("^SkybridgeRib") then
                    expect(part:IsA("MeshPart")).toBe(true)
                    expect(math.abs(part.CFrame.RightVector:Dot(lateral)) > 0.999).toBe(true)
                    expect(math.abs(part.Size.X - math.min(bridge.Size.X, bridge.Size.Z) - 0.22) < 0.01).toBe(true)
                    expect(part.CanTouch or part.CanQuery).toBe(false)
                elseif name:match("^PlatformGlow") then
                    local longitudinal = alongX and Vector3.xAxis or Vector3.zAxis
                    local offset = bridge.CFrame:PointToObjectSpace(part.Position)
                    expect(part:IsA("MeshPart") and part.Material == Enum.Material.Neon).toBe(true)
                    expect(math.abs(part.CFrame.RightVector:Dot(longitudinal)) > 0.999).toBe(true)
                    expect(math.abs(part.Size.X - 49.28) < 0.01).toBe(true)
                    expect(math.abs(part.Size.Z - 4.92) < 0.01).toBe(true)
                    expect(math.abs(offset.Y + bridge.Size.Y * 0.5 + 0.47) < 0.01).toBe(true)
                    expect(part.CanTouch or part.CanQuery).toBe(false)
                elseif name:match("^PlatformBevel") then
                    local edge = tonumber(name:match("_(%d)$"))
                    local edgeLength = edge <= 2 and bridge.Size.X or bridge.Size.Z
                    local tangent = edge <= 2 and Vector3.xAxis or Vector3.zAxis
                    local top = bridge.Position.Y + bridge.Size.Y * 0.5
                    expect(part:IsA("MeshPart")).toBe(true)
                    expect(math.abs(part.CFrame.RightVector:Dot(tangent)) > 0.999).toBe(true)
                    expect(math.abs(part.Size.X - edgeLength - 0.12) < 0.01).toBe(true)
                    expect(part.Position.Y + part.Size.Y * 0.5 < top).toBe(true)
                    expect(part.CanTouch or part.CanQuery).toBe(false)
                end
                originals[part] = {cf = part.CFrame, size = part.Size}
                table.insert(details[bridge], part)
            end
        end

        local running = true
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config, RoundSeconds = 0.36,
            Cleanup = {}, OnCleanup = callbacks,
            Active = function() return running end,
        })
        task.wait(0.22)
        expect(LargeStructure.matchesSkybridgeSupport(pier2,bridge18)).toBe(true)
        expect(pier2.LocalTransparencyModifier).toBe(1)
        expect(columns.parts[1].LocalTransparencyModifier).toBe(0)
        columns.parts[1]:Destroy()
        expect(pier2.LocalTransparencyModifier).toBe(0)
        expect(columns.parts[2].LocalTransparencyModifier).toBe(1)

        local shrinkScale = base.Size.X / baseOriginalX
        expect(shrinkScale < 1).toBe(true)
        for _, tier in ipairs(tiers) do
            expect(math.abs(tier.deck.Size.X
                - tier.deckSize.X * shrinkScale) < 0.03).toBe(true)
            expect(math.abs(tier.deck.Size.Z
                - tier.deckSize.Z * shrinkScale) < 0.03).toBe(true)
            expect(math.abs(tier.panel.Size.X
                - tier.panelSize.X * shrinkScale) < 0.03).toBe(true)
            expect(math.abs(tier.panel.Size.Z
                - tier.panelSize.Z * shrinkScale) < 0.03).toBe(true)
        end

        for bridge, old in pairs(originals) do
            if bridge:GetAttribute("ChaosSkybridge") == true then
                local alongX = old.size.X > old.size.Z
                local originalSpan = math.max(old.size.X, old.size.Z)
                local shrunkSpan = math.max(bridge.Size.X, bridge.Size.Z)
                expect(shrunkSpan < originalSpan).toBe(true)
                expect(shrunkSpan > 4).toBe(true)
                expect(bridge.CanCollide).toBe(true)
                -- North/south/east/west spans follow their tower rows inward.
                expect((bridge.Position - Config.ArenaCenter).Magnitude
                    < (old.cf.Position - Config.ArenaCenter).Magnitude).toBe(true)

                for _, detail in ipairs(details[bridge]) do
                    local prior = originals[detail]
                    local d0 = alongX and prior.size.X or prior.size.Z
                    local d1 = alongX and detail.Size.X or detail.Size.Z
                    if detail.Name:match("^SkybridgeRib") then
                        local before = old.cf:PointToObjectSpace(prior.cf.Position)
                        local after = bridge.CFrame:PointToObjectSpace(detail.Position)
                        local ratio = shrunkSpan / originalSpan
                        local target = alongX and Vector3.new(before.X * ratio, before.Y, before.Z)
                            or Vector3.new(before.X, before.Y, before.Z * ratio)
                        expect((after - target).Magnitude < 0.01).toBe(true)
                        expect((detail.Size - prior.size).Magnitude < 0.01).toBe(true)
                    elseif detail.Name:match("^PlatformUnderFrame") then
                        expect(math.abs(detail.Size.Z - shrunkSpan * 0.98) < 0.01).toBe(true)
                        expect(math.abs(detail.Size.X - prior.size.X) < 0.01).toBe(true)
                        expect(math.abs(detail.Size.Y - prior.size.Y) < 0.01).toBe(true)
                    elseif detail.Name:match("^PlatformBevel") then
                        local axis = alongX and Vector3.xAxis or Vector3.zAxis
                        local followsSpan = math.abs(prior.cf.RightVector:Dot(axis)) > 0.999
                        local expected = followsSpan and prior.size.X * shrunkSpan / originalSpan
                            or prior.size.X
                        expect(math.abs(detail.Size.X - expected) < 0.01).toBe(true)
                        expect(math.abs(detail.Size.Z - prior.size.Z) < 0.01).toBe(true)
                    elseif detail.Name:match("^PlatformCoreGlow") then
                        checkUnderdeckSignal(arena, bridge)
                    elseif detail.Name:match("^PlatformGlow")
                        or detail.Name:match("^SkybridgeRail") then
                        expect(math.abs(detail.Size.X - prior.size.X * shrunkSpan / originalSpan) < 0.01).toBe(true)
                        expect(math.abs(detail.Size.Z - prior.size.Z) < 0.01).toBe(true)
                        expect(math.abs(detail.Size.Y - prior.size.Y) < 0.01).toBe(true)
                    elseif d0 > 2.2 then
                        expect(d1 < d0).toBe(true)
                    end
                    expect(detail.CanCollide).toBe(false)
                    expect(detail.Parent).toBe(decor)
                end
            end
        end

        running = false
        cleanup(callbacks, {})
        for _, tier in ipairs(tiers) do
            expect((tier.deck.Position - tier.deckCFrame.Position).Magnitude < 0.001)
                .toBe(true)
            expect((tier.panel.Position - tier.panelCFrame.Position).Magnitude < 0.001)
                .toBe(true)
            expect((tier.deck.Size - tier.deckSize).Magnitude < 0.001)
                .toBe(true)
            expect((tier.panel.Size - tier.panelSize).Magnitude < 0.001)
                .toBe(true)
        end
        for part, old in pairs(originals) do
            expect((part.Position - old.cf.Position).Magnitude < 0.001).toBe(true)
            expect((part.Size - old.size).Magnitude < 0.001).toBe(true)
        end
        NativeTrim.reset()
        for _, connection in ipairs(columns.disconnects) do connection:Disconnect() end
        templates:Destroy()
        root:Destroy()
    end)

    it("keeps Crossroads Flux Relays on the shrinking base and restores gate locations", function()
        local root = MapBuilder.build(Config, "Crossroads", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local mechanicsCtx = {
            Active = function() return true end,
            IsContestantActive = function() return false end,
            Cleanup = {},
            Contestants = {},
        }
        ArenaMechanics.start(mechanicsCtx, "Crossroads")
        local mechanics = arena:FindFirstChild("Mechanics")
        local relays = mechanics and mechanics:FindFirstChild("FluxRelays")
        expect(relays ~= nil).toBe(true)
        expect(#relays:GetChildren()).toBe(4)

        local base = arena:FindFirstChild("Base")
        local platforms = arena:FindFirstChild("Platforms")
        local decor = arena:FindFirstChild("Decor")
        local initialFloorWidth = base.Size.X
        local routePieces = {}
        for _, index in ipairs({1, 3, 10, 14}) do
            local deck = platforms:FindFirstChild("Platform" .. index)
            local panel = decor:FindFirstChild("PlatformPanel" .. index)
            expect(deck ~= nil).toBe(true)
            expect(panel ~= nil).toBe(true)
            expect(deck:GetAttribute("RouteTier") ~= nil).toBe(true)
            routePieces[#routePieces + 1] = {
                deck = deck, panel = panel,
                deckCFrame = deck.CFrame, panelCFrame = panel.CFrame,
                deckSize = deck.Size, panelSize = panel.Size,
            }
        end
        local original = {}
        for _, gate in ipairs(relays:GetChildren()) do
            original[gate] = gate.CFrame
        end
        local active = true
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config,
            RoundSeconds = 0.36,
            Cleanup = {}, OnCleanup = callbacks,
            Active = function() return active end,
        })
        task.wait(0.22)
        local scale = base.Size.X / initialFloorWidth
        expect(scale < 0.98).toBe(true)
        for _, route in ipairs(routePieces) do
            expect(math.abs(route.deck.Size.X - route.deckSize.X * scale) < 0.03)
                .toBe(true)
            expect(math.abs(route.deck.Size.Z - route.deckSize.Z * scale) < 0.03)
                .toBe(true)
            expect(math.abs(route.panel.Size.X - route.panelSize.X * scale) < 0.03)
                .toBe(true)
            expect(math.abs(route.panel.Size.Z - route.panelSize.Z * scale) < 0.03)
                .toBe(true)
        end
        for gate, old in pairs(original) do
            local current = gate.Position - Config.ArenaCenter
            local before = old.Position - Config.ArenaCenter
            local planarCurrent = Vector3.new(current.X, 0, current.Z).Magnitude
            local planarBefore = Vector3.new(before.X, 0, before.Z).Magnitude
            expect(planarCurrent < planarBefore - 0.2).toBe(true)
            expect(gate.CanCollide).toBe(false)
            expect(gate.CanTouch).toBe(true)
            expect(gate:GetAttribute("FluxCycleEpoch") ~= nil).toBe(true)
        end
        active = false
        cleanup(callbacks, {})
        for _, route in ipairs(routePieces) do
            expect((route.deck.Size - route.deckSize).Magnitude < 0.001).toBe(true)
            expect((route.panel.Size - route.panelSize).Magnitude < 0.001).toBe(true)
            expect((route.deck.Position - route.deckCFrame.Position).Magnitude < 0.001)
                .toBe(true)
            expect((route.panel.Position - route.panelCFrame.Position).Magnitude < 0.001)
                .toBe(true)
        end
        for gate, old in pairs(original) do
            expect((gate.CFrame.Position - old.Position).Magnitude < 0.001).toBe(true)
        end
        root:Destroy()
    end)

    it("shrinks every Orbital ramp with the decks, then restores its beams", function()
        local root = MapBuilder.build(Config, "Orbital", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local platforms = arena and arena:FindFirstChild("Platforms")
        local helix = arena and arena:FindFirstChild("HelixCircuit")
        expect(platforms ~= nil).toBe(true)
        expect(helix ~= nil).toBe(true)

        local originals = {}
        local source = OrbitalHelix.capture(helix)
        expect(#source).toBe(24)
        local states = {}
        for _, state in ipairs(source) do
            states[state.ramp] = state
            originals[state.ramp] = {
                cf = state.ramp.CFrame,
                size = state.ramp.Size,
            }
            expect(#state.decorations).toBe(
                (state.ramp:GetAttribute("OrbitalHelixRamp") == true
                    or state.ramp.Name == "HelixRamp9") and 8 or 4
            )
            for _, d in ipairs(state.decorations) do
                originals[d.part] = {cf = d.part.CFrame, size = d.part.Size}
            end
        end

        local active = true
        local objects = {}
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config,
            RoundSeconds = 0.36,
            Cleanup = objects,
            OnCleanup = callbacks,
            Active = function() return active end,
        })
        task.wait(0.22)

        local factor = arena:FindFirstChild("Base").Size.X
            / ArenaVariants.get("Orbital").BaseSize.X
        local advanced = 0
        for index = 1, 8 do
            local outer = platforms:FindFirstChild("Platform" .. index)
            local inner = platforms:FindFirstChild("Platform" .. (index + 8))
            local ramp = helix:FindFirstChild("HelixRamp" .. index)
            expect(outer ~= nil).toBe(true)
            expect(inner ~= nil).toBe(true)
            expect(ramp ~= nil).toBe(true)

            local from = outer.Position + Vector3.new(0, outer.Size.Y * 0.5 - 0.15, 0)
            local to = inner.Position + Vector3.new(0, inner.Size.Y * 0.5 - 0.15, 0)
            expect((ramp.Position - (from + to) * 0.5).Magnitude < 0.1).toBe(true)
            expect((ramp.CFrame.LookVector - (to - from).Unit).Magnitude < 0.02).toBe(true)
            expect(math.abs(ramp.Size.Z - ((to - from).Magnitude + 4.4)) < 0.1).toBe(true)

            local old = originals[ramp]
            if (ramp.Position - old.cf.Position).Magnitude > 1 then
                advanced += 1
            end
            expect(ramp.CanCollide).toBe(true)
            local rail = helix:FindFirstChild("HelixEdgeSignal" .. index .. "_1")
            expect(rail ~= nil).toBe(true)
            expect(rail.CanCollide).toBe(false)
            expect((rail.CFrame.Position - originals[rail].cf.Position).Magnitude > 0.3).toBe(true)

            for _, kind in ipairs({"Entry", "Core"}) do
                local name = kind == "Core" and index == 2
                    and "HelixRamp9" or (kind .. "Ramp" .. index)
                local access = helix:FindFirstChild(name)
                expect(access ~= nil).toBe(true)
                local route = states[access]
                expect(route ~= nil).toBe(true)
                local function moved(point)
                    local relative = point - Config.ArenaCenter
                    return Config.ArenaCenter + Vector3.new(
                        relative.X * factor, relative.Y, relative.Z * factor
                    )
                end
                local expectedFrom, expectedTo =
                    moved(route.from), moved(route.to)
                expect((access.Position
                    - (expectedFrom + expectedTo) * 0.5).Magnitude < 0.1)
                    .toBe(true)
                expect(math.abs(access.Size.Z
                    - ((expectedTo - expectedFrom).Magnitude + route.padding))
                    < 0.1).toBe(true)
                expect(access.Size.X < originals[access].size.X).toBe(true)
                expect(access.CanCollide).toBe(true)
                local trimName = kind == "Core" and index == 2
                    and "HelixEdgeSignal9_1"
                    or (kind .. "Signal" .. index .. "_1")
                local trim = helix:FindFirstChild(trimName)
                expect(trim ~= nil).toBe(true)
                expect(trim.CanCollide).toBe(false)
                expect((trim.Position - originals[trim].cf.Position).Magnitude > 0.3)
                    .toBe(true)
            end
        end
        expect(advanced).toBe(8)
        local preservedCore = helix:FindFirstChild("HelixRamp9")
        expect(preservedCore:GetAttribute("OrbitalCoreRamp")).toBe(true)
        expect(preservedCore:GetAttribute("OrbitalHelixRamp") == nil).toBe(true)
        expect(states[preservedCore] ~= nil).toBe(true)

        active = false
        cleanup(callbacks, objects)
        for part, state in pairs(originals) do
            expect((part.CFrame.Position - state.cf.Position).Magnitude < 0.001).toBe(true)
            expect((part.Size - state.size).Magnitude < 0.001).toBe(true)
        end
        root:Destroy()
    end)

    it("fits the existing Harbor landing trims to all three real route families",function()
        local storage=game:GetService("ReplicatedStorage")
        local oldMap=workspace:FindFirstChild("GeneratedMap")
        local oldChassis=storage:FindFirstChild("ApprovedRemainingStructureTemplates")
        local signals=forgedSignalFixture(true)
        local oldSignals=storage:FindFirstChild(signals.Name)
        if oldMap then oldMap.Parent=nil end
        if oldChassis then oldChassis.Parent=nil end
        if oldSignals then oldSignals.Parent=nil end
        local chassis=shortChassisFixture(storage)
        signals.Parent=storage
        local generated
        local active,callbacks=false,{}
        local ok,why=pcall(function()
            local arena=MapBuilder.buildArena(Config,"Harbor",ArenaVariants)
            generated=arena.Parent
            local landings={}
            local lookup={}
            local counts={cargo=0,spoke=0,crossing=0}
            for _,deck in ipairs(arena.Platforms:GetChildren()) do
                local cargo=deck:GetAttribute("HarborRoute")
                local spoke=deck:GetAttribute("HarborSpokeRoute")
                local crossing=deck:GetAttribute("HarborSkywayLane")
                if cargo or spoke or crossing then
                    local group=cargo and "cargo" or spoke and "spoke" or "crossing"
                    counts[group]+=1
                    local step=deck:GetAttribute("HarborStep") or deck:GetAttribute("HarborSpokeStep")
                        or deck:GetAttribute("HarborSkywayStep")
                    local key=group..tostring(cargo or spoke or crossing).."_"
                    lookup[key..step]=deck
                    landings[deck]={key=key, step=step, forward=step < (spoke and 4 or 7)}
                end
            end
            assert(counts.cargo==28 and counts.spoke==16 and counts.crossing==14)
            local function checkLanding(deck,data,scale)
                local id=assert(deck.Name:match("^Platform(%d+)$"))
                local band=arena.Decor["PlatformGlow"..id]
                local lens=arena.Decor["PlatformCoreGlow"..id]
                local frame=arena.Decor["PlatformUnderFrame"..id]
                local alongX=data.alongX
                local sx,sz,halfY=deck.Size.X,deck.Size.Z,deck.Size.Y*.5
                checkRouteSignal(deck,band,Vector3.new(
                    sx+(alongX and .28 or .96)*scale,.14,sz+(alongX and .96 or .28)*scale),
                    Vector3.new(0,-halfY-.47,0))
                checkRouteSignal(deck,lens,
                    Vector3.new(sx*(alongX and .62 or .22),.30,sz*(alongX and .22 or .62)),
                    Vector3.new(0,-halfY-.52,0))
                for _,piece in ipairs({band,lens}) do
                    local direction=deck.CFrame:VectorToObjectSpace(piece.CFrame.LookVector)
                    assert(math.abs(alongX and direction.X or direction.Z)>.999)
                end
                local _,acceptedFrame=Rim.nativeParts(arena.Decor,deck,data.size,scale)
                assert(acceptedFrame==frame and frame:IsA("MeshPart") and deck.CanCollide)
                return band,lens,frame
            end
            for deck,data in pairs(landings) do
                local nextStep=data.forward and data.step+1 or data.step-1
                local neighbor=lookup[data.key..nextStep]
                local delta=neighbor.Position-deck.Position
                -- The four cargo summits turn onto their adjoining skyway.
                data.alongX=(deck:GetAttribute("HarborStep")==7)
                    or math.abs(delta.X)>math.abs(delta.Z)
                data.size=deck.Size
                checkLanding(deck,data,1)
            end

            local sample=lookup.crossing1_1
            local band,lens,frame=checkLanding(sample,landings[sample],1)
            local cosmetics=DisappearingPlatforms.cosmeticsForPlatform(arena.Decor,sample)
            DisappearingPlatforms.setCosmeticsPhase(cosmetics,"Warning")
            assert(band.Transparency>.59 and lens.Transparency>.59 and frame.Transparency>.59)
            DisappearingPlatforms.setCosmeticsPhase(cosmetics,"Gone")
            assert(band.Transparency==1 and lens.Transparency==1 and frame.Transparency==1)
            DisappearingPlatforms.setCosmeticsPhase(cosmetics,"Safe")
            assert(band.Transparency<.60 and lens.Transparency<.60 and frame.Transparency<.06)
            active=true
            ShrinkingArena.start({Config=Config,RoundSeconds=.12,OnCleanup=callbacks,
                Active=function() return active end})
            local deadline=os.clock()+1.5
            repeat task.wait() until arena.Base.Size.X<=144.05 or os.clock()>deadline
            active=false
            task.wait()
            assert(arena.Base.Size.X<=144.05)
            for deck,data in pairs(landings) do checkLanding(deck,data,.45) end
            cleanup(callbacks,{})
            table.clear(callbacks)
            for deck,data in pairs(landings) do checkLanding(deck,data,1) end

            chassis.Parent=nil
            signals.Parent=nil
            local fallback=MapBuilder.buildArena(Config,"Harbor",ArenaVariants)
            local fallbackDeck=fallback.Platforms[sample.Name]
            local id=assert(fallbackDeck.Name:match("^Platform(%d+)$"))
            for _,prefix in ipairs({"PlatformGlow","PlatformCoreGlow","PlatformUnderFrame"}) do
                assert(fallback.Decor[prefix..id]:IsA("Part"))
            end
        end)
        active=false
        cleanup(callbacks,{})
        if generated then generated:Destroy() end
        chassis:Destroy()
        signals:Destroy()
        if oldMap then oldMap.Parent=workspace end
        if oldChassis then oldChassis.Parent=storage end
        if oldSignals then oldSignals.Parent=storage end
        if not ok then error(why) end
    end)

    local function checkLookoutLinks(arena, scale)
        local decks=arena.Platforms:GetChildren()
        local lookoutEntries={}
        for _,deck in ipairs(decks) do
            local step=deck:GetAttribute("PromenadeStep")
            if step==1 or step==8 then
                local west=(deck:GetAttribute("PromenadeLane")-1)*2+1
                lookoutEntries[step==1 and west or west+1]=deck
            end
        end
        local branches,crosslinks=0,0
        for _,deck in ipairs(decks) do
            local step=deck:GetAttribute("BranchStep")
            if deck:GetAttribute("PerimeterStep")==5 then
                local id=assert(deck.Name:match("^Platform(%d+)$"))
                local panel=arena.Decor["PlatformPanel"..id]
                local route=deck:GetAttribute("PerimeterRoute")
                for _,side in ipairs({-1,1}) do
                    local arm=arena.Decor["BranchForkArrow"..route.."_"..side]
                    assert(arm:IsA("MeshPart") and arm:GetAttribute("ChaosWayfinding")==true)
                    assert(arm:GetAttribute("PerimeterPlatformIndex")==tonumber(id))
                    assert(arm.Position.Y-arm.Size.Y*.5>panel.Position.Y+panel.Size.Y*.5)
                end
            end
            if step or deck:GetAttribute("CrosslinkRoute") then
                local id=assert(deck.Name:match("^Platform(%d+)$"))
                local band=arena.Decor["PlatformGlow"..id]
                local across=step==4
                local size=deck.Size
                checkRouteSignal(deck,band,Vector3.new(
                    size.X+(across and .28 or .96)*scale,.14,
                    size.Z+(across and .96 or .28)*scale
                ),Vector3.new(0,size.Y*.5-1.02,0))
                local axis=deck.CFrame:VectorToObjectSpace(band.CFrame.LookVector)
                assert(math.abs(across and axis.X or axis.Z)>.999 and deck.CanCollide)
                if not step then
                    crosslinks+=1
                    continue
                end
                branches+=1
                local route=deck:GetAttribute("BranchRoute")
                local forward=Vector3.new(0,0,deck.Position.Z>=arena.Base.Position.Z and 1 or -1)
                if across then
                    local delta=lookoutEntries[route].Position-deck.Position
                    forward=Vector3.new(delta.X,0,delta.Z).Unit
                    assert(deck:FindFirstChild("SideLookoutLabel"))
                end
                local point=deck.Position+Vector3.new(0,deck.Size.Y*.5+.155,0)
                local heading=CFrame.lookAt(point,point+forward)
                local panel=arena.Decor["PlatformPanel"..id]
                for _,side in ipairs({-1,1}) do
                    local arm=arena.Decor["BranchStepArrow"..route.."_"..step.."_"..side]
                    local pose=heading*CFrame.new(side*.48*scale,0,0)*CFrame.Angles(0,math.rad(side*34),0)
                    assert(arm:IsA("MeshPart") and arm:GetAttribute("ChaosWayfinding")==true)
                    assert(arm:GetAttribute("PerimeterPlatformIndex")==tonumber(id))
                    assert(not arm.CanCollide and not arm.CanTouch and not arm.CanQuery)
                    assert(arm.CFrame.LookVector:Dot(pose.LookVector)>.999)
                    assert((arm.Position-pose.Position).Magnitude<.025)
                    assert((arm.Size-Vector3.new(.25*scale,.065,2*scale)).Magnitude<.025)
                    assert(arm.Position.Y-arm.Size.Y*.5>panel.Position.Y+panel.Size.Y*.5)
                end
            end
        end
        assert(branches==16 and crosslinks==4)
    end

    local function checkPromenadeChevrons(arena, scale)
        local decks = arena.Platforms:GetChildren()
        local endpoints = {}
        for _, deck in ipairs(decks) do
            local step = deck:GetAttribute("SkySpineStep")
            if step == 1 or step == 10 then endpoints[step == 1 and 1 or 2] = deck end
        end
        local junctions = 0
        for _, deck in ipairs(decks) do
            local lane = deck:GetAttribute("PromenadeLane")
            if not lane then continue end
            local id = assert(deck.Name:match("^Platform(%d+)$"))
            local prefix = "PromenadeJumpChevron" .. id .. "_"
            local panel = arena.Decor["PlatformPanel" .. id]
            local function checkChevron(name, forward, offset, width, alpha)
                local point = deck.Position + Vector3.new(0, deck.Size.Y * .5 + .155, 0)
                    + forward * offset
                local look = CFrame.lookAt(point, point + forward)
                for side = -1, 1, 2 do
                    local part = arena.Decor[prefix .. name .. "_" .. side]
                    local pose = look * CFrame.new(side * .62 * scale, 0, 0)
                        * CFrame.Angles(0, math.rad(side * 35), 0)
                    assert(part:IsA("MeshPart") and part.Material == Enum.Material.Neon)
                    assert(part:GetAttribute("PerimeterPlatformIndex") == tonumber(id)
                        and part:GetAttribute("ChaosWayfinding") == true)
                    assert(not part.CanCollide and not part.CanTouch and not part.CanQuery)
                    assert((part.Position - pose.Position).Magnitude < .025
                        and part.CFrame.LookVector:Dot(pose.LookVector) > .999)
                    assert((part.Size - Vector3.new(width * scale, .08, 2.55 * scale)).Magnitude < .025)
                    assert(part.Position.Y - part.Size.Y * .5 > panel.Position.Y + panel.Size.Y * .5)
                    assert(math.abs(part.Transparency - alpha) < .001)
                end
            end
            local inset = math.min(5 * scale, deck.Size.X * .24)
            checkChevron("-1", -Vector3.xAxis, inset, .30, .34)
            checkChevron("1", Vector3.xAxis, inset, .30, .34)
            if deck:GetAttribute("PromenadeStep") == 4 then
                local toward = endpoints[lane].Position.Z > deck.Position.Z and 1 or -1
                checkChevron("Spine", Vector3.zAxis * toward, deck.Size.Z * .25, .35, .24)
                local spine = endpoints[lane]
                local spineId = assert(spine.Name:match("^Platform(%d+)$"))
                local spinePanel = arena.Decor["PlatformPanel" .. spineId]
                for direction = -1, 1, 2 do
                    for side = -1, 1, 2 do
                        local arm = arena.Decor["SkySpine" .. spineId .. "_PromenadeChevron" .. direction .. "_" .. side]
                        assert(arm:IsA("MeshPart") and arm.Material == Enum.Material.Neon)
                        assert(arm:GetAttribute("ChaosWayfinding") == true
                            and arm:GetAttribute("PerimeterPlatformIndex") == tonumber(spineId))
                        assert(not arm.CanCollide and not arm.CanTouch and not arm.CanQuery)
                        assert(arm.CFrame.LookVector.X * direction > .81)
                        assert(arm.Position.Y - arm.Size.Y * .5
                            > math.max(panel.Position.Y + panel.Size.Y * .5,
                                spinePanel.Position.Y + spinePanel.Size.Y * .5))
                        for x = -1, 1, 2 do
                            for z = -1, 1, 2 do
                                local corner = arm.CFrame:PointToWorldSpace(
                                    Vector3.new(x * arm.Size.X * .5, 0, z * arm.Size.Z * .5))
                                for _, owner in ipairs({spine, deck}) do
                                    local point = owner.CFrame:PointToObjectSpace(corner)
                                    assert(math.abs(point.X) < owner.Size.X * .5
                                        and math.abs(point.Z) < owner.Size.Z * .5)
                                end
                            end
                        end
                    end
                end
                junctions += 1
            else
                assert(not arena.Decor:FindFirstChild(prefix .. "Spine_1"))
            end
        end
        assert(junctions == 2)
    end

    local function checkSpawnGuides(arena, variant)
        local base = arena.Base
        local surface = base.Position.Y + base.Size.Y * .5
        for index, offset in ipairs(ArenaVariants.get(variant).SpawnOffsets) do
            local spawn = arena.Spawns["Spawn" .. index]
            local expected = base.Position + Vector3.new(offset.X, base.Size.Y * .5 + .14, offset.Z)
            assert((spawn.Position - expected).Magnitude < .02)
            local glow = arena["SpawnGlow" .. index]
            checkRouteSignal(spawn, glow, Vector3.new(5.2, .12, 5.2), Vector3.new(0, .107, 0))
            assert(glow.Position.Y - glow.Size.Y * .5 > surface + .18)
            for side = -1, 1, 2 do
                local guide = arena.EntryGuides["EntryChevron" .. index .. "_" .. side]
                assert(guide:IsA("MeshPart") and guide:GetAttribute("ChaosWayfinding") == true)
                assert(guide.Anchored and not guide.CanCollide and not guide.CanTouch and not guide.CanQuery)
                assert(guide.Position.Y - guide.Size.Y * .5 > surface + .18)
                local pose = spawn.CFrame:ToObjectSpace(guide.CFrame)
                assert((pose.Position - Vector3.new(side * .78, .107, -3)).Magnitude < .02)
                local axis = guide.Size.X > guide.Size.Z and pose.RightVector or pose.LookVector
                assert(side * axis.X * axis.Z > .45)
            end
        end
    end

    local function checkPerimeterDecor(arena, scale)
        local base = arena.Base
        local edgeX, edgeZ = base.Size.X * .5 - .4 * scale, base.Size.Z * .5 - .4 * scale
        local edgeY = base.Size.Y * .5 + .25
        local sizeX = Vector3.new(base.Size.X, .45, .35)
        local sizeZ = Vector3.new(.35, .45, base.Size.Z)
        for _, side in ipairs({
            {"EdgeNorth", sizeX, Vector3.new(0, edgeY, -edgeZ)},
            {"EdgeSouth", sizeX, Vector3.new(0, edgeY, edgeZ)},
            {"EdgeWest", sizeZ, Vector3.new(-edgeX, edgeY, 0)},
            {"EdgeEast", sizeZ, Vector3.new(edgeX, edgeY, 0)},
        }) do
            local border = arena.Decor[side[1]]
            checkRouteSignal(base, border, side[2], side[3])
            assert(not border.CastShadow and border.Transparency == 0)
        end
        local center = arena.Decor.CenterBeacon
        assert(center:IsA("MeshPart") and center.Material == Enum.Material.Neon)
        assert(center.Anchored and not center.CastShadow)
        assert(not center.CanCollide and not center.CanTouch and not center.CanQuery)
        assert((center.Size - Vector3.new(1.4, 14, 1.4)).Magnitude < .02)
        assert((base.CFrame:PointToObjectSpace(center.Position) - Vector3.new(0, 7, 0)).Magnitude < .02)
        local centerLight = center:FindFirstChild("ArenaGlow")
        assert(centerLight and centerLight:IsA("PointLight") and centerLight.Color == center.Color)
        assert(centerLight.Range == 28 and math.abs(centerLight.Brightness - 1.2) < .01 and not centerLight.Shadows)
        for route = 1, 4 do
            local corner = arena.Decor["EdgeBeacon" .. route]
            local glow = arena.Decor["EdgeBeaconGlow" .. route]
            for _, piece in ipairs({corner, glow}) do
                assert(piece:IsA("MeshPart") and piece.Anchored and not piece.CastShadow)
                assert(not piece.CanCollide and not piece.CanTouch and not piece.CanQuery)
            end
            assert((corner.Size - Vector3.new(.8 * scale, 7, .8 * scale)).Magnitude < .02)
            assert((glow.Size - Vector3.new(1.35 * scale, .36, 1.35 * scale)).Magnitude < .02)
            local point = base.CFrame:PointToObjectSpace(corner.Position)
            assert(math.abs(base.Size.X * .5 - math.abs(point.X) - 3 * scale) < .02)
            assert(math.abs(base.Size.Z * .5 - math.abs(point.Z) - 3 * scale) < .02)
            assert(math.abs(point.Y - (base.Size.Y + corner.Size.Y) * .5) < .02)
            assert((glow.Position - corner.Position - Vector3.new(0, 3.55, 0)).Magnitude < .02)
            local light = glow:FindFirstChild("EdgeBeaconLight")
            assert(light and light:IsA("PointLight") and light.Color == glow.Color)
            assert(light.Range == 11 and math.abs(light.Brightness - .55) < .01 and not light.Shadows)
            local mast = arena.Decor["OuterRouteSignal" .. route]
            local crown = arena.Decor["OuterRouteSignalCrown" .. route]
            local lens = arena.Decor["OuterRouteSignalLens" .. route]
            assert(mast:IsA("MeshPart") and crown:IsA("MeshPart"))
            assert(lens:IsA("Part") and lens.Shape == Enum.PartType.Ball and lens.Material == Enum.Material.Glass)
            assert((mast.Size - Vector3.new(1.55 * scale, 34, 1.55 * scale)).Magnitude < .03)
            assert((crown.Size - Vector3.new(5 * scale, .85, 5 * scale)).Magnitude < .03)
            assert((lens.Position - mast.Position - Vector3.new(0, 18.5, 0)).Magnitude < .03)
            assert((crown.Position - mast.Position - Vector3.new(0, 15.9, 0)).Magnitude < .03)
            local offset = base.CFrame:PointToObjectSpace(mast.Position)
            assert(math.abs(offset.Y - mast.Size.Y * .5 - base.Size.Y * .5) < .02)
            assert(math.abs(offset.X) + crown.Size.X * .5 <= base.Size.X * .5
                and math.abs(offset.Z) + crown.Size.Z * .5 <= base.Size.Z * .5)
            local owner = arena.Platforms["Platform" .. mast:GetAttribute("PerimeterPlatformIndex")]
            assert(owner:GetAttribute("PerimeterStep") == ArenaVariants.PerimeterSteps)
            assert(owner:GetAttribute("PerimeterRoute") == route)
            local exitLens = arena.Decor["PerimeterExitLens" .. route]
            assert(exitLens:IsA("Part") and exitLens.Material == Enum.Material.Glass)
            assert(exitLens:GetAttribute("PerimeterPlatformIndex") == mast:GetAttribute("PerimeterPlatformIndex"))
            for _, fit in ipairs({
                {"PerimeterExitRib" .. route .. "_-1", .88, .34},
                {"PerimeterExitRib" .. route .. "_1", .88, .34},
                {"PerimeterExitCrown" .. route, 8, 1},
            }) do
                local piece = arena.Decor[fit[1]]
                assert(piece:IsA("MeshPart") and piece.Anchored and not piece.CastShadow)
                assert(not piece.CanCollide and not piece.CanTouch and not piece.CanQuery)
                assert(piece:GetAttribute("PerimeterPlatformIndex") == exitLens:GetAttribute("PerimeterPlatformIndex"))
                assert(math.abs(math.max(piece.Size.X, piece.Size.Z) - fit[2] * scale) < .02)
                assert(math.abs(math.min(piece.Size.X, piece.Size.Z) - fit[3] * scale) < .02)
                local pose = owner.CFrame:PointToObjectSpace(piece.Position)
                local depth = math.abs(piece.CFrame.RightVector.Z) * piece.Size.X
                    + math.abs(piece.CFrame.LookVector.Z) * piece.Size.Z
                assert(math.abs(pose.Z) - depth * .5 >= owner.Size.Z * .5 - .001)
            end
            for _, piece in ipairs({mast,crown,lens}) do
                assert(piece:GetAttribute("PerimeterPlatformIndex") == mast:GetAttribute("PerimeterPlatformIndex"))
                assert(piece:GetAttribute("ChaosWayfinding") == true)
                assert(not piece.CanCollide and not piece.CanTouch and not piece.CanQuery)
            end
            for _, point in ipairs({"Entry","Lookout"}) do
                local base = arena.Decor["DistrictWayfinder" .. route .. point]
                local owner = arena.Platforms["Platform" .. base:GetAttribute("PerimeterPlatformIndex")]
                local label = base.ObjectiveLabel
                assert(owner:GetAttribute("PerimeterRoute") == route)
                assert(owner:GetAttribute("PerimeterStep") == (point == "Entry" and 1 or 8))
                assert(base:IsA("MeshPart") and base.Anchored
                    and not base.CanCollide and not base.CanTouch and not base.CanQuery)
                assert((base.Size - Vector3.new(1.6 * scale, .46, 1.8 * scale)).Magnitude < .02)
                local pose = owner.CFrame:PointToObjectSpace(base.Position)
                assert(math.abs(pose.X) < .01 and math.abs(pose.Z) < .01)
                assert(math.abs(pose.Y - base.Size.Y * .5 - owner.Size.Y * .5 - .09) < .01)
                assert(label.Adornee == base and label.Enabled and label.MaxDistance == 85)
                assert(math.abs(pose.Y + label.StudsOffsetWorldSpace.Y - owner.Size.Y * .5 - 4.9) < .02)
            end
            for marker = 1, 5 do
                for side = -1, 1, 2 do
                    local arrow = arena.Decor["OuterRouteChevron" .. route .. "_" .. marker .. "_" .. side]
                    assert(arrow:IsA("MeshPart") and arrow:GetAttribute("ChaosWayfinding") == true)
                    assert((arrow.Size - Vector3.new(.28 * scale, .055, 2.5 * scale)).Magnitude < .02)
                end
            end
            for step = 1, ArenaVariants.PerimeterSteps do
                for side = -1, 1, 2 do
                    local arrow = arena.Decor["OuterStepChevron" .. route .. "_" .. step .. "_" .. side]
                    local id = arrow:GetAttribute("PerimeterPlatformIndex")
                    local deck = arena.Platforms["Platform" .. id]
                    local panel = arena.Decor["PlatformPanel" .. id]
                    assert(arrow:IsA("MeshPart") and deck:GetAttribute("PerimeterStep") == step)
                    assert((arrow.Size - Vector3.new(.26 * scale, .07, 1.8 * scale)).Magnitude < .02)
                    assert(arrow.Position.Y - arrow.Size.Y * .5 > panel.Position.Y + panel.Size.Y * .5)
                end
            end
            for marker = 1, 3 do
                for side = -1, 1, 2 do
                    local arrow = arena.Decor["DistrictArrow" .. route .. "_" .. marker .. "_" .. side]
                    assert(arrow:IsA("MeshPart") and arrow:GetAttribute("ChaosWayfinding") == true)
                    assert((arrow.Size - Vector3.new(.17 * scale, .055, 1.5 * scale)).Magnitude < .02)
                end
            end
        end
    end

    it("fits the short approved chassis beneath every Promenade deck",function()
        local storage=game:GetService("ReplicatedStorage")
        local oldMap=workspace:FindFirstChild("GeneratedMap")
        local oldSource=storage:FindFirstChild("ApprovedRemainingStructureTemplates")
        if oldMap then oldMap.Parent=nil end
        if oldSource then oldSource.Parent=nil end
        local holder=shortChassisFixture(storage)
        local signalHolder=forgedSignalFixture(true)
        local oldSignalSource=storage:FindFirstChild(signalHolder.Name)
        if oldSignalSource then oldSignalSource.Parent=nil end
        signalHolder.Parent=storage
        local oldArmor = storage:FindFirstChild("ApprovedPerimeterArmorTemplates")
        if oldArmor then oldArmor.Parent = nil end
        local armor = Instance.new("Folder")
        armor.Name = "ApprovedPerimeterArmorTemplates"
        armor:SetAttribute("OwnerVerified", true)
        local cap = Instance.new("Model")
        cap.Name = "Cap"
        cap:SetAttribute("OwnerVerified", true)
        cap:SetAttribute("CosmeticOnly", true)
        cap:SetAttribute("OriginalPerimeterArmor3D", true)
        cap:SetAttribute("Original3DAssetId", 88962643359267)
        cap.Parent = armor
        local baseMesh = Instance.new("MeshPart")
        baseMesh.Name = "WayfinderBase"
        baseMesh.Size = Vector3.new(2.34, 2.14, 2.76985)
        baseMesh.Parent = cap
        armor.Parent = storage

        local oldColumns = storage:FindFirstChild("ApprovedLargeStructureTemplates")
        if oldColumns then oldColumns.Parent = nil end
        local columns = Instance.new("Folder")
        columns.Name = "ApprovedLargeStructureTemplates"
        columns:SetAttribute("OwnerVerified", true)
        for name, id in pairs({Classic=91626128452597,Towers=107521411452905,
            Crossroads=93993697329658,Orbital=119010829781313,Harbor=76194593490199}) do
            local model = Instance.new("Model")
            model.Name = name
            model:SetAttribute("OwnerVerified", true)
            model:SetAttribute("CosmeticOnly", true)
            model:SetAttribute("OriginalLargeStructure3D", true)
            model:SetAttribute("Original3DAssetId", id)
            local shaft = Instance.new("MeshPart")
            shaft.Name = "BeaconShaft"
            shaft.Size = Vector3.new(1.48, 13.56, 1.43)
            shaft.Parent = model
            model.Parent = columns
        end
        columns.Parent = storage

        local generated,context
        local active,callbacks=false,{}
        local okay,why=pcall(function()
            local total=0
            for _,variant in ipairs(ArenaVariants.Order) do
                local arena=MapBuilder.buildArena(Config,variant,ArenaVariants)
                generated=arena.Parent
                checkLookoutLinks(arena,1)
                checkPromenadeChevrons(arena,1)
                checkPerimeterDecor(arena,1)
                checkSpawnGuides(arena,variant)
                local count,porticos,junctions=0,0,0
                local finalDeck,finalFrame,finalTruss
                local endpoints={}
                local decks=arena.Platforms:GetChildren()
                for _,deck in ipairs(decks) do
                    local step=deck:GetAttribute("SkySpineStep")
                    if step==1 or step==10 then endpoints[step==1 and 1 or 2]=deck end
                end
                for _,deck in ipairs(decks) do
                    local step=deck:GetAttribute("PromenadeStep")
                    if step then
                        context=variant.." "..deck.Name
                        local index=deck.Name:match("^Platform(%d+)$")
                        local frame=arena.Decor["PlatformUnderFrame"..index]
                        local truss=(step==2 or step==4 or step==7)
                            and arena.Decor["Promenade"..index.."_UnderdeckTruss"]
                        local name=step==4 and "JunctionUnderframe"
                            or (truss and "PromenadeTruss" or "PromenadeUnderframe")
                        frame.LocalTransparencyModifier=.19
                        if truss then truss.LocalTransparencyModifier=.22 end
                        Remaining.sync(nil,Vector3.zero,"Low",false)
                        Remaining.sync(arena,deck.Position,"Low",true,nil,0,true)
                        local bucket=workspace.ApprovedRemainingStructureMeshesLocal
                        local model=bucket:FindFirstChild("ApprovedP4_"..name)
                        assert(model and model:GetAttribute("OriginalP4OwnerPlatform")==deck.Name)
                        assert(Remaining.count("junction",name)==1)
                        assert(Remaining.nativeCount("junction")==(truss and 2 or 1))
                        assert(frame.LocalTransparencyModifier==1 and deck.CanCollide)
                        checkUnderdeckSignal(arena,deck)
                        checkAerialBand(arena,deck,1)
                        for _,piece in ipairs(model:GetChildren()) do
                            local center=deck.CFrame:PointToObjectSpace(piece.Position)
                            local bounds=deck.CFrame:ToObjectSpace(piece.CFrame)
                            local halfX=(math.abs(bounds.RightVector.X)*piece.Size.X
                                +math.abs(bounds.LookVector.X)*piece.Size.Z)*.5
                            local halfZ=(math.abs(bounds.RightVector.Z)*piece.Size.X
                                +math.abs(bounds.LookVector.Z)*piece.Size.Z)*.5
                            assert(center.Y+piece.Size.Y*.5 < -deck.Size.Y*.5)
                            assert(math.abs(center.X)+halfX < deck.Size.X*.5
                                and math.abs(center.Z)+halfZ < deck.Size.Z*.5)
                            assert(not piece.CanCollide and not piece.CanQuery)
                        end
                        if truss then
                            assert(truss.LocalTransparencyModifier==1)
                            if step==4 then
                                local endpoint=endpoints[deck:GetAttribute("PromenadeLane")]
                                local joined=endpoint.CFrame
                                endpoint.CFrame=joined*CFrame.new(50,0,0)
                                task.wait()
                                assert(Remaining.count("junction",name)==0)
                                assert(math.abs(frame.LocalTransparencyModifier-.19)<.01
                                    and math.abs(truss.LocalTransparencyModifier-.22)<.01)
                                endpoint.CFrame=joined
                                task.wait()
                                assert(Remaining.count("junction",name)==1)
                                assert(frame.LocalTransparencyModifier==1 and truss.LocalTransparencyModifier==1)
                                junctions+=1
                                finalDeck,finalFrame,finalTruss=deck,frame,truss
                            else
                                porticos+=1
                            end
                        end
                        count+=1
                    end
                end
                assert(count==16 and porticos==4 and junctions==2,variant)
                total+=count
                if variant=="Harbor" then
                    context="Harbor truss ownership and shrink"
                    local wayfinder = arena.Decor.DistrictWayfinder1Lookout
                    local lookout = arena.Platforms["Platform" .. wayfinder:GetAttribute("PerimeterPlatformIndex")]
                    lookout:SetAttribute("CollapsePhase", "Warning")
                    task.wait()
                    assert(not wayfinder.ObjectiveLabel.Enabled)
                    lookout:SetAttribute("CollapsePhase", nil)
                    lookout.CanCollide = false
                    task.wait()
                    assert(not wayfinder.ObjectiveLabel.Enabled)
                    lookout.CanCollide = true
                    task.wait()
                    assert(wayfinder.ObjectiveLabel.Enabled)
                    Remaining.sync(nil,Vector3.zero,"Low",false)
                    Remaining.sync(arena,finalDeck.Position,"Low",true,nil,0,true)
                    local art=workspace.ApprovedRemainingStructureMeshesLocal.ApprovedP4_JunctionUnderframe
                    local mesh=art:FindFirstChildWhichIsA("MeshPart")
                    local width=mesh.Size.X
                    local glow=checkUnderdeckSignal(arena,finalDeck)
                    local originalGlowSize=glow.Size
                    local band=checkAerialBand(arena,finalDeck,1)
                    local originalBandSize=band.Size
                    NativeTrim.setPromenadeStructureMask(finalTruss,true,true)
                    assert(mesh.LocalTransparencyModifier==1 and finalTruss.LocalTransparencyModifier==1)
                    assert(math.abs(finalFrame.LocalTransparencyModifier-.19)<.01)
                    NativeTrim.setPromenadeStructureMask(finalTruss,true,false)
                    assert(mesh.LocalTransparencyModifier==0 and finalFrame.LocalTransparencyModifier==1)
                    active=true
                    ShrinkingArena.start({Config=Config,RoundSeconds=.12,OnCleanup=callbacks,
                        Active=function() return active end})
                    local deadline=os.clock()+1.5
                    repeat task.wait() until arena.Base.Size.X<=144.05 or os.clock()>deadline
                    active=false
                    task.wait()
                    assert(arena.Base.Size.X<=144.05 and math.abs(mesh.Size.X-width*.45)<.025)
                    assert(checkUnderdeckSignal(arena,finalDeck)==glow)
                    assert(checkAerialBand(arena,finalDeck,.45)==band)
                    checkLookoutLinks(arena,.45)
                    checkPromenadeChevrons(arena,.45)
                    checkPerimeterDecor(arena,.45)
                    checkSpawnGuides(arena,variant)
                    assert(finalTruss.LocalTransparencyModifier==1 and finalFrame.LocalTransparencyModifier==1)
                    Remaining.sync(arena,finalDeck.Position,"Low",true,nil,1,true)
                    assert(math.abs(finalFrame.LocalTransparencyModifier-.19)<.01)
                    assert(math.abs(finalTruss.LocalTransparencyModifier-.22)<.01)
                    cleanup(callbacks,{})
                    assert((glow.Size-originalGlowSize).Magnitude<.01)
                    assert((band.Size-originalBandSize).Magnitude<.01)
                    checkLookoutLinks(arena,1)
                    checkPromenadeChevrons(arena,1)
                    checkPerimeterDecor(arena,1)
                    table.clear(callbacks)
                end
                Remaining.sync(nil,Vector3.zero,"Low",false)
                generated:Destroy()
                generated=nil
            end
            expect(total).toBe(80)
        end)
        active=false
        Remaining.sync(nil,Vector3.zero,"Low",false)
        cleanup(callbacks,{})
        if generated then generated:Destroy() end
        holder:Destroy()
        signalHolder:Destroy()
        armor:Destroy()
        columns:Destroy()
        if oldColumns then oldColumns.Parent = storage end
        if oldArmor then oldArmor.Parent = storage end
        if oldSignalSource then oldSignalSource.Parent=storage end
        if oldSource then oldSource.Parent=storage end
        if oldMap then oldMap.Parent=workspace end
        if not okay then error(tostring(context)..": "..tostring(why)) end
    end)


    it("fits one approved chassis over each complete Sky Spine set and yields to the full cradle",function()
        local storage=game:GetService("ReplicatedStorage")
        local oldMap=workspace:FindFirstChild("GeneratedMap")
        local oldSource=storage:FindFirstChild("ApprovedRemainingStructureTemplates")
        if oldMap then oldMap.Parent=nil end
        if oldSource then oldSource.Parent=nil end
        local holder=shortChassisFixture(storage)
        local signalHolder=forgedSignalFixture(true)
        local oldSignalSource=storage:FindFirstChild(signalHolder.Name)
        if oldSignalSource then oldSignalSource.Parent=nil end
        signalHolder.Parent=storage
        local generated,context
        local active,callbacks=false,{}
        local okay,why=pcall(function()
            local total=0
            local beam=signalHolder.ForgedBridge.SweptCrossbeam
            for _,variant in ipairs(ArenaVariants.Order) do
                local heightAxis=variant=="Harbor" and "Z" or "X"
                beam.Size=heightAxis=="Z" and Vector3.new(5.96,3.1108,40.64)
                    or Vector3.new(40.64,3.1108,5.96)
                local arena=MapBuilder.buildArena(Config,variant,ArenaVariants)
                generated=arena.Parent
                local count,owner,overheads=0,nil,0
                local inlays={}
                local function checkInlay(deck,signal,side,scale)
                    local deckHeight=deck.Size.Y*.5
                    checkRouteSignal(deck,signal,Vector3.new(.30*scale,7.5,.42*scale),
                        Vector3.new(side*7.22*scale,deckHeight+6.4,0))
                    local frame=deck.CFrame:ToObjectSpace(signal.CFrame)
                    assert(frame.UpVector.X*side<-.999)
                    assert(signal:GetAttribute("RouteSignalHeightAxis")==heightAxis)
                    assert(math.abs(signal.Transparency-.24)<.001)
                end
                for _,deck in ipairs(arena.Platforms:GetChildren()) do
                    if deck:GetAttribute("SkySpineStep") then
                        context=variant.." "..deck.Name
                        local native=assert(LargeStructure.spineNativeParts(arena.Decor,deck))
                        for _,part in ipairs(native) do part.LocalTransparencyModifier=.21 end
                        Remaining.sync(nil,Vector3.zero,"Low",false)
                        Remaining.sync(arena,deck.Position,"Low",true,nil,0,true)
                        local art=workspace.ApprovedRemainingStructureMeshesLocal
                            :FindFirstChild("ApprovedP4_SpineUnderframe")
                        assert(art and art:GetAttribute("OriginalP4OwnerPlatform")==deck.Name)
                        assert(Remaining.count("junction","SpineUnderframe")==1)
                        assert(Remaining.nativeCount("junction")==4 and deck.CanCollide)
                        for _,part in ipairs(native) do assert(part.LocalTransparencyModifier==1) end
                        for _,mesh in ipairs(art:GetChildren()) do
                            local p=deck.CFrame:PointToObjectSpace(mesh.Position)
                            assert(p.Y+mesh.Size.Y*.5< -deck.Size.Y*.5)
                            assert(math.abs(p.X)+mesh.Size.X*.5<=deck.Size.X*.5)
                            assert(math.abs(p.Z)+mesh.Size.Z*.5<=deck.Size.Z*.5)
                            assert(not mesh.CanCollide and not mesh.CanQuery)
                        end
                        local id=deck.Name:match("^Platform(%d+)$")
                        local prefix="SkySpine"..id
                        for _,side in ipairs({-1,1}) do
                            local rail=arena.Decor[prefix.."_LightedEdge"..side]
                            checkRouteSignal(deck,rail,Vector3.new(.26,.17,deck.Size.Z-1.1),
                                Vector3.new(side*(deck.Size.X*.5-.32),deck.Size.Y*.5+.12,0))
                            assert(rail.LocalTransparencyModifier==0 and math.abs(rail.Transparency-.36)<.001)
                        end
                        local pulse=arena.Decor:FindFirstChild(prefix.."_OverheadPulse")
                        if pulse then
                            checkRouteSignal(deck,pulse,Vector3.new(13,.35,.7),
                                Vector3.new(0,deck.Size.Y*.5+12.7,-.58))
                            overheads+=1
                            for _,side in ipairs({-1,1}) do
                                local pylon=arena.Decor[prefix.."_MonumentalPylon"..side]
                                local inlay=arena.Decor[prefix.."_SignalInlay"..side]
                                checkInlay(deck,inlay,side,1)
                                local face=math.abs(deck.CFrame:PointToObjectSpace(pylon.Position).X)
                                    -pylon.Size.X*.5
                                local center=math.abs(deck.CFrame:PointToObjectSpace(inlay.Position).X)
                                assert(center-.15<face and center+.15>face and center-.15>deck.Size.X*.5)
                                inlays[#inlays+1]={deck=deck,part=inlay,side=side,size=inlay.Size}
                            end
                        end
                        checkUnderdeckSignal(arena,deck)
                        checkAerialBand(arena,deck,1)
                        count+=1
                        owner=deck
                    end
                end
                assert(count==10 and overheads==4 and #inlays==8,variant)
                total+=count
                if (variant=="Harbor" or variant=="Towers") and owner then
                    context="Sky Spine streaming, shared claims and contraction"
                    local native=assert(LargeStructure.spineNativeParts(arena.Decor,owner))
                    local art=workspace.ApprovedRemainingStructureMeshesLocal.ApprovedP4_SpineUnderframe
                    local mesh=art:FindFirstChildWhichIsA("MeshPart")
                    local size=mesh.Size
                    local id=assert(owner.Name:match("^Platform(%d+)$"))
                    local rail=arena.Decor["SkySpine"..id.."_LightedEdge1"]
                    local originalRailSize=rail.Size
                    for _,index in ipairs({1,3}) do
                        NativeTrim.setRouteUnderdeckMask(native[index],true)
                        assert(mesh.LocalTransparencyModifier==1 and native[index].LocalTransparencyModifier==1)
                        NativeTrim.setRouteUnderdeckMask(native[index],false)
                        assert(mesh.LocalTransparencyModifier==0)
                    end
                    local frame=native[1]
                    frame:SetAttribute("PremiumArchitecturalSurface",false)
                    task.wait()
                    assert(mesh.LocalTransparencyModifier==1)
                    for _,part in ipairs(native) do
                        assert(math.abs(part.LocalTransparencyModifier-.21)<.01)
                    end
                    frame:SetAttribute("PremiumArchitecturalSurface",true)
                    task.wait()
                    assert(mesh.LocalTransparencyModifier==0)
                    local cross=native[4]
                    cross.Parent=nil
                    task.wait()
                    assert(mesh.LocalTransparencyModifier==1)
                    for _,part in ipairs(native) do
                        assert(math.abs(part.LocalTransparencyModifier-.21)<.01)
                    end
                    cross.Parent=arena.Decor
                    task.wait()
                    assert(mesh.LocalTransparencyModifier==0)
                    active=true
                    ShrinkingArena.start({Config=Config,RoundSeconds=.12,OnCleanup=callbacks,
                        Active=function() return active end})
                    local deadline=os.clock()+1.5
                    repeat task.wait() until arena.Base.Size.X<=144.05 or os.clock()>deadline
                    active=false
                    task.wait()
                    assert(arena.Base.Size.X<=144.05 and mesh.LocalTransparencyModifier==0)
                    assert(math.abs(mesh.Size.X-size.X*.45)<.03 and math.abs(mesh.Size.Z-size.Z*.45)<.03)
                    checkUnderdeckSignal(arena,owner)
                    checkAerialBand(arena,owner,.45)
                    for _,inlay in ipairs(inlays) do
                        checkInlay(inlay.deck,inlay.part,inlay.side,.45)
                    end
                    checkRouteSignal(owner,rail,Vector3.new(.26*.45,.17,owner.Size.Z-1.1*.45),
                        Vector3.new(owner.Size.X*.5-.32*.45,owner.Size.Y*.5+.12,0))
                    Remaining.sync(arena,owner.Position,"Low",true,nil,1,true)
                    for _,part in ipairs(native) do
                        assert(math.abs(part.LocalTransparencyModifier-.21)<.01)
                    end
                    cleanup(callbacks,{})
                    assert((rail.Size-originalRailSize).Magnitude<.01)
                    for _,inlay in ipairs(inlays) do
                        checkInlay(inlay.deck,inlay.part,inlay.side,1)
                        assert((inlay.part.Size-inlay.size).Magnitude<.01)
                    end
                    table.clear(callbacks)
                end
                Remaining.sync(nil,Vector3.zero,"Low",false)
                generated:Destroy()
                generated=nil
            end
            expect(total).toBe(50)

            -- Build a real arena while the forged detail is unavailable.
            signalHolder.Parent=nil
            local fallback=MapBuilder.buildArena(Config,"Harbor",ArenaVariants)
            generated=fallback.Parent
            local restored=0
            for _,piece in ipairs(fallback.Decor:GetChildren()) do
                if piece.Name:match("^SkySpine%d+_SignalInlay%-?1$") then
                    assert(piece:IsA("Part") and piece.Size.Y==7.5
                        and piece.Material==Enum.Material.Neon
                        and math.abs(piece.Transparency-.24)<.001)
                    assert(piece:GetAttribute("RouteSignalHeightAxis")==nil and not piece.CanCollide)
                    restored+=1
                end
            end
            assert(restored==8)
        end)
        active=false
        Remaining.sync(nil,Vector3.zero,"Low",false)
        cleanup(callbacks,{})
        if generated then generated:Destroy() end
        holder:Destroy()
        signalHolder:Destroy()
        if oldSignalSource then oldSignalSource.Parent=storage end
        if oldSource then oldSource.Parent=storage end
        if oldMap then oldMap.Parent=workspace end
        if not okay then error(tostring(context)..": "..tostring(why)) end
    end)

end)

return nil
