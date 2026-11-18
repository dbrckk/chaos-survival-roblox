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

    it("shrinks four Tower Run skybridge decks, rails and supports as one assembly", function()
        local storage = game:GetService("ReplicatedStorage")
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
        beam.Size = Vector3.new(40.64, 3.1108, 5.96)
        beam.Anchored = true
        beam.CanCollide = false
        beam.CanTouch = false
        beam.CanQuery = false
        beam.Parent = source
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
        SkybridgePressure.setPhase(pressure, "Warning", workspace:GetServerTimeNow())
        expect(math.abs(guardedRib.Transparency - 0.65) < 0.001).toBe(true)
        expect(math.abs(guardedFrame.Transparency - 0.65) < 0.001).toBe(true)
        expect(math.abs(guardedBevel.Transparency - 0.65) < 0.001).toBe(true)
        SkybridgePressure.setPhase(pressure, "Gone")
        expect(guardedRib.Transparency).toBe(1)
        expect(guardedFrame.Transparency).toBe(1)
        expect(guardedBevel.Transparency).toBe(1)
        SkybridgePressure.setPhase(pressure, nil)
        expect(guardedRib.Transparency).toBe(0)
        expect(math.abs(guardedFrame.Transparency - 0.04) < 0.001).toBe(true)
        expect(math.abs(guardedBevel.Transparency - 0.08) < 0.001).toBe(true)
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
            for side = 1, 2 do
                local post = decor:FindFirstChild("PlatformSupport" .. index .. "_" .. side)
                expect(LargeStructure.matchesSkybridgeSupport(post,bridge)).toBe(true)
            end
            local prefix = {
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
                if name:match("^PlatformUnderFrame") then
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

    local function checkUnderdeckSignal(arena,deck)
        local index=assert(deck.Name:match("^Platform(%d+)$"))
        local glow=arena.Decor:FindFirstChild("PlatformCoreGlow"..index)
        assert(glow and glow:IsA("MeshPart") and glow.Material==Enum.Material.Neon)
        assert(glow.Anchored and not glow.CanCollide and not glow.CanTouch and not glow.CanQuery)
        assert(#glow:GetChildren()==0 and glow.Transparency<1)
        local offset=deck.CFrame:ToObjectSpace(glow.CFrame)
        local acrossX=math.abs(offset.LookVector.X)>.99
        local extentX=acrossX and glow.Size.Z or glow.Size.X
        local extentZ=acrossX and glow.Size.X or glow.Size.Z
        local alongX=deck.Size.X>deck.Size.Z
        assert(math.abs(extentX-deck.Size.X*(alongX and .62 or .22))<.025)
        assert(math.abs(extentZ-deck.Size.Z*(alongX and .22 or .62))<.025)
        assert(math.abs(offset.Y+deck.Size.Y*.5+.52)<.015)
        assert(math.abs(glow.Size.Y-.30)<.01)
        return glow
    end

    it("fits the short approved chassis beneath every Promenade deck",function()
        local storage=game:GetService("ReplicatedStorage")
        local oldMap=workspace:FindFirstChild("GeneratedMap")
        local oldSource=storage:FindFirstChild("ApprovedRemainingStructureTemplates")
        if oldMap then oldMap.Parent=nil end
        if oldSource then oldSource.Parent=nil end
        local holder=shortChassisFixture(storage)

        local generated,context
        local active,callbacks=false,{}
        local okay,why=pcall(function()
            local total=0
            for _,variant in ipairs(ArenaVariants.Order) do
                local arena=MapBuilder.buildArena(Config,variant,ArenaVariants)
                generated=arena.Parent
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
                    Remaining.sync(nil,Vector3.zero,"Low",false)
                    Remaining.sync(arena,finalDeck.Position,"Low",true,nil,0,true)
                    local art=workspace.ApprovedRemainingStructureMeshesLocal.ApprovedP4_JunctionUnderframe
                    local mesh=art:FindFirstChildWhichIsA("MeshPart")
                    local width=mesh.Size.X
                    local glow=checkUnderdeckSignal(arena,finalDeck)
                    local originalGlowSize=glow.Size
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
                    assert(finalTruss.LocalTransparencyModifier==1 and finalFrame.LocalTransparencyModifier==1)
                    Remaining.sync(arena,finalDeck.Position,"Low",true,nil,1,true)
                    assert(math.abs(finalFrame.LocalTransparencyModifier-.19)<.01)
                    assert(math.abs(finalTruss.LocalTransparencyModifier-.22)<.01)
                    cleanup(callbacks,{})
                    assert((glow.Size-originalGlowSize).Magnitude<.01)
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
        local generated,context
        local active,callbacks=false,{}
        local okay,why=pcall(function()
            local total=0
            for _,variant in ipairs(ArenaVariants.Order) do
                local arena=MapBuilder.buildArena(Config,variant,ArenaVariants)
                generated=arena.Parent
                local count,owner=0,nil
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
                        assert(arena.Decor["SkySpine"..id.."_LightedEdge1"].LocalTransparencyModifier==0)
                        checkUnderdeckSignal(arena,deck)
                        count+=1
                        owner=deck
                    end
                end
                assert(count==10,variant)
                total+=count
                if variant=="Harbor" and owner then
                    context="Sky Spine streaming, shared claims and contraction"
                    local native=assert(LargeStructure.spineNativeParts(arena.Decor,owner))
                    local art=workspace.ApprovedRemainingStructureMeshesLocal.ApprovedP4_SpineUnderframe
                    local mesh=art:FindFirstChildWhichIsA("MeshPart")
                    local size=mesh.Size
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
                    Remaining.sync(arena,owner.Position,"Low",true,nil,1,true)
                    for _,part in ipairs(native) do
                        assert(math.abs(part.LocalTransparencyModifier-.21)<.01)
                    end
                    cleanup(callbacks,{})
                    table.clear(callbacks)
                end
                Remaining.sync(nil,Vector3.zero,"Low",false)
                generated:Destroy()
                generated=nil
            end
            expect(total).toBe(50)
        end)
        active=false
        Remaining.sync(nil,Vector3.zero,"Low",false)
        cleanup(callbacks,{})
        if generated then generated:Destroy() end
        holder:Destroy()
        if oldSource then oldSource.Parent=storage end
        if oldMap then oldMap.Parent=workspace end
        if not okay then error(tostring(context)..": "..tostring(why)) end
    end)

end)

return nil
