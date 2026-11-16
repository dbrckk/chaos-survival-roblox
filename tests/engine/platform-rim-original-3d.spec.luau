--!strict
-- Focused Roblox Engine fixture: two authentic approved perimeter shapes.
-- Imported source provenance is verified separately in the pipeline;
-- the Roblox-only MeshParts here are purpose-built test fixtures.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Kit = require("../../src/client/PlatformNativeTrimReplacementKit")


local PlatformIdentityLodRules = require("../../src/shared/PlatformIdentityLodRules")
local PremiumPlatformSideMeshKit = require("../../src/client/PremiumPlatformSideMeshKit")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local Config = require("../../src/shared/Config")
local VisualTheme = require("../../src/shared/VisualTheme")
local ShrinkingArena = require("../../src/server/Disasters/ShrinkingArena")

describe("Approved perimeter rim fallback and physics (engine)", function()
    it("moves the single Low carapace between real Crossroads decks and restores their trim", function()
        Kit.reset()
        local previous=workspace:FindFirstChild("GeneratedMap")
        if previous then previous.Parent=nil end
        local storage = game:GetService("ReplicatedStorage")
        local previousTemplates = storage:FindFirstChild("ApprovedPlatformSideTemplates")
        if previousTemplates then previousTemplates.Parent = nil end
        local generated,templates,meshes
        local ok,failure=pcall(function()
            local arena=MapBuilder.buildArena(Config,"Crossroads",ArenaVariants,VisualTheme)
            generated=arena.Parent
            local base=arena:FindFirstChild("Base")
            local platforms=arena:FindFirstChild("Platforms")
            local decor=arena:FindFirstChild("Decor")
            local nearby=platforms:FindFirstChild("Platform2")
            expect(nearby.Size).toBe(Vector3.new(14,2,12))
            local underside = decor.PlatformUnderFrame2
            templates=Instance.new("Folder")
            templates.Name="ApprovedPlatformSideTemplates"
            templates:SetAttribute("OwnerVerified",true)
            templates.Parent=storage
            local approved=Instance.new("Model")
            -- Exact dimension range of creator-approved Crossroads
            -- original. The 14x12 real physical deck can host it; square
            -- 10x10 decks in Classic do not pass the source-fit guard.
            approved.Name="Crossroads"
            approved:SetAttribute("Original3DAssetId",116452624086023)
            approved:SetAttribute("OwnerVerified",true)
            approved:SetAttribute("CosmeticOnly",true)
            approved:SetAttribute("OriginalStructuralSide3D",true)
            for i=1,7 do
                local source=Instance.new("MeshPart")
                source.Name="ApprovedDeckMaterial"..i
                source.Size=if i==1 then Vector3.new(11.04,3,8.36)
                    else Vector3.new(1,1,1)
                source.Anchored=true
                source.CanCollide=false
                source.CanTouch=false
                source.CanQuery=false
                source.Parent=approved
            end
            approved.Parent=templates
            local eastDeck = platforms:FindFirstChild("Platform4")
            local westCamera = nearby.Position - Vector3.new(18, 0, 0)
            local eastCamera = eastDeck.Position + Vector3.new(18, 0, 0)
            expect(PlatformIdentityLodRules.nearFieldRetarget(
                "Low", 0, westCamera, eastCamera, 11)).toBe(false)
            expect(PlatformIdentityLodRules.nearFieldRetarget(
                "Low", 1, westCamera, eastCamera, 12)).toBe(false)
            expect(PlatformIdentityLodRules.nearFieldRetarget(
                "Low", 0, westCamera, eastCamera, 12)).toBe(true)
            expect(PlatformIdentityLodRules.nearFieldRetarget(
                "Medium", 0, westCamera, eastCamera, 12)).toBe(false)
            local west = PremiumPlatformSideMeshKit.selectCarapaceDecks(
                {nearby, eastDeck}, "Crossroads", "Low", base, westCamera,
                Vector3.xAxis, 0, decor)
            local east = PremiumPlatformSideMeshKit.selectCarapaceDecks(
                {nearby, eastDeck}, "Crossroads", "Low", base, eastCamera,
                -Vector3.xAxis, 0, decor)
            expect(west[nearby] and east[eastDeck]).toBe(true)
            expect(west[eastDeck] or east[nearby]).toBe(nil)
            meshes=Instance.new("Folder")
            meshes.Name="OriginalCarapaceEvenDeckFixture"
            meshes.Parent=workspace
            local parts=PremiumPlatformSideMeshKit.carapace(
                meshes,nearby,"Crossroads","Low",2,west[nearby])
            expect(parts~=nil and #parts==7).toBe(true)
            Kit.bind(arena, {["2"] = "carapace"}, nil, nil, meshes)
            expect(Kit.count()).toBe(5)
            expect(underside.LocalTransparencyModifier).toBe(1)
            for _, piece in ipairs(parts) do piece:Destroy() end
            expect(Kit.count()).toBe(0)
            -- The budget can migrate to the other real route deck. The
            -- new welded bundle may mask only that deck's five natives.
            local eastParts = PremiumPlatformSideMeshKit.carapace(
                meshes, eastDeck, "Crossroads", "Low", 4, east[eastDeck])
            expect(eastParts and #eastParts).toBe(7)
            Kit.bind(arena, {["4"] = "carapace"}, nil, nil, meshes)
            expect(Kit.count()).toBe(5)
            expect(underside.LocalTransparencyModifier).toBe(0)
            local eastFrame = decor.PlatformUnderFrame4
            expect(eastFrame.LocalTransparencyModifier).toBe(1)
            Kit.setPlatformTrimLodVisible(eastDeck, false)
            expect(Kit.count()).toBe(0)
            expect(eastFrame.LocalTransparencyModifier).toBe(0)
            expect(decor.PlatformBevel4_1.LocalTransparencyModifier).toBe(0)
            -- A native arriving while the genuine shell is out of LOD
            -- must remain visible until that whole shell is drawn again.
            eastFrame.Parent = nil
            eastFrame.Parent = decor
            expect(Kit.count()).toBe(0)
            Kit.setPlatformTrimLodVisible(eastDeck, true)
            expect(Kit.count()).toBe(5)
            expect(eastFrame.LocalTransparencyModifier).toBe(1)
            expect(eastDeck.CanCollide and nearby.CanCollide).toBe(true)
        end)
        Kit.reset()
        if meshes then meshes:Destroy() end
        if templates then templates:Destroy() end
        if generated then generated:Destroy() end
        if previousTemplates then previousTemplates.Parent = storage end
        if previous then previous.Parent=workspace end
        if not ok then error(failure) end
    end)

    it("removes only redundant platform underside primitives beneath genuine seven-piece hulls", function()
        local Finish=require("../../src/client/PlatformFinishKit")
        local holder=Instance.new("Folder")
        holder.Name="ApprovedPlatformFinishFallbackTest"
        holder.Parent=workspace
        local deck=Instance.new("Part")
        deck.Name="Platform27"
        deck.Size=Vector3.new(14,2,12)
        deck.Anchored=true
        deck.CanCollide=true
        deck.Parent=holder
        local theme={
            Detail=Color3.fromRGB(172,183,196),
            Secondary=Color3.fromRGB(110,164,188),
            Structure=Color3.fromRGB(55,75,95),
            Accent=Color3.fromRGB(112,187,218),
            Surface=Color3.fromRGB(120,130,142),
        }
        for _,row in ipairs({
            {"Classic",3,2},{"Towers",3,0},{"Harbor",3,2},
            {"Crossroads",3,3},{"Orbital",3,3},
        }) do
            local variant,normalCount,sculptedCount=unpack(row)
            local regular=Finish.build(holder,deck,variant,"High",theme)
            expect(#regular).toBe(normalCount)
            for _,piece in ipairs(regular) do piece:Destroy() end
            local sculpted=Finish.build(holder,deck,variant,"High",
                theme,true)
            expect(#sculpted).toBe(sculptedCount)
            for _,piece in ipairs(sculpted) do
                expect(piece.CanCollide or piece.CanTouch or piece.CanQuery)
                    .toBe(false)
                expect(piece:FindFirstChild("ChaosPlatformTrimWeld")~=nil)
                    .toBe(true)
                piece:Destroy()
            end
            -- Failed/evicted approved source returns to the full native
            -- fallback without changing collision or safety markings.
            local fallback=Finish.build(holder,deck,variant,"High",
                theme,false)
            expect(#fallback).toBe(normalCount)
            for _,piece in ipairs(fallback) do piece:Destroy() end
            expect(deck.Anchored and deck.CanCollide).toBe(true)
        end
        -- Medium Harbor and Classic preserve their two upper markings.
        for _,variant in ipairs({"Classic","Harbor","Crossroads","Orbital"}) do
            local top=Finish.build(holder,deck,variant,"Medium",theme,true)
            expect(#top).toBe(2)
            for _,piece in ipairs(top) do piece:Destroy() end
        end
        local noHoist=Finish.build(holder,deck,"Towers","Medium",
            theme,true)
        expect(#noHoist).toBe(0)
        holder:Destroy()
    end)

    it("replaces four native platform bevel Wedges with seven approved rect/long MeshParts, never the collision deck", function()
        local Rim = require("../../src/client/ApprovedPlatformRimMeshKit")
        local RS = game:GetService("ReplicatedStorage")
        local previous = RS:FindFirstChild("ApprovedPlatformRimTemplates")
        local previousMap = workspace:FindFirstChild("GeneratedMap")
        if previous then previous.Parent = nil end
        if previousMap then previousMap.Parent = nil end
        Kit.reset()
        local templates = Instance.new("Folder")
        templates.Name = "ApprovedPlatformRimTemplates"
        templates:SetAttribute("OwnerVerified", true)
        templates.Parent = RS
        local arena = Instance.new("Folder")
        arena.Name = "PlatformRimEngineFixture"
        arena.Parent = workspace
        local platforms = Instance.new("Folder")
        platforms.Name = "Platforms"
        platforms.Parent = arena
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(320,2,320)
        base.CFrame = CFrame.new(0,2,0)
        base.Anchored = true
        base.CanCollide = true
        base.Parent = arena
        local function source(name, id, dimensions)
            local model = Instance.new("Model")
            model.Name = name
            model:SetAttribute("Original3DAssetId", id)
            model:SetAttribute("OwnerVerified", true)
            model:SetAttribute("CosmeticOnly", true)
            model:SetAttribute("OriginalPlatformRim3D", true)
            for i=1,7 do
                local piece = Instance.new("MeshPart")
                piece.Name = "OriginalMaterial_"..i
                piece.Size = dimensions
                piece.Anchored = true
                piece.CanCollide = false
                piece.CanTouch = false
                piece.CanQuery = false
                piece.Parent = model
            end
            model.Parent = templates
        end
        source("Rect",131482590870627,Vector3.new(16.64,2.115,9.64))
        source("Long",127617571835277,Vector3.new(25.64,2.115,7.64))
        local function platform(id, dimensions, location)
            local deck = Instance.new("Part")
            deck.Name = "Platform"..id
            deck.Size = dimensions
            deck.CFrame = CFrame.new(location)
            deck.Anchored = true
            deck.CanCollide = true
            deck.Parent = platforms
            for edge=1,4 do
                local native = Instance.new("WedgePart")
                native.Name = "PlatformBevel"..id.."_"..edge
                native.Size = Vector3.new(5,.3,.5)
                native.Anchored = true
                native.CanCollide = false
                native.CanTouch = false
                native.CanQuery = false
                native:SetAttribute("OriginalStructuralBevel",true)
                native.Parent = decor
            end
            local frame = Instance.new("Part")
            frame.Name = "PlatformUnderFrame"..id
            frame.Anchored = true
            frame.CanCollide = false
            frame.CanTouch = false
            frame.CanQuery = false
            frame:SetAttribute("PremiumArchitecturalSurface",true)
            frame.Parent = decor
            return deck,frame
        end
        local rectangular, rectFrame = platform(31,Vector3.new(17,2,10),
            Vector3.new(0,12,0))
        local elongated, longFrame = platform(32,Vector3.new(26,2,8),
            Vector3.new(24,12,0))
        -- All extra candidates are REAL collidable deck Parts with
        -- their own four fully replicated, nonphysical native Wedges.
        -- In High PC, nearby originals retain priority while the
        -- remaining authentic seven-MeshPart source slots must reach
        -- remote visible sectors of a 320-stud map.
        local allDecks={rectangular,elongated}
        local nearCoords={
            Vector3.new(6,12,28),Vector3.new(12,12,26),
            Vector3.new(18,12,25),Vector3.new(26,12,16),
            Vector3.new(20,12,-17),Vector3.new(-15,12,15),
        }
        for i,point in ipairs(nearCoords) do
            local deck=platform(32+i,Vector3.new(17,2,10),point)
            allDecks[#allDecks+1]=deck
        end
        local farDecks={}
        local remoteCoords={
            Vector3.new(95,12,70),Vector3.new(-92,12,65),
            Vector3.new(-96,12,-70),Vector3.new(92,12,-83),
        }
        for i,point in ipairs(remoteCoords) do
            local deck=platform(38+i,Vector3.new(26,2,8),point)
            allDecks[#allDecks+1]=deck
            farDecks[#farDecks+1]=deck
        end
        local meshes = Instance.new("Folder")
        meshes.Name = "TestVerifiedRimMeshes"
        meshes.Parent = arena
        local generated
        local cleanup = {}
        local active = false
        local footprint
        local ok,why=pcall(function()
            local point = Vector3.new(5,19,3)
            local selected = Rim.selectVisibleDecks(
                {rectangular, elongated}, "High", base, point,
                0,false,decor,{}, {})
            expect(selected[rectangular]).toBe("Rect")
            expect(selected[elongated]).toBe("Long")
            local low = Rim.selectVisibleDecks(
                {rectangular, elongated}, "Low", base, point,
                0,true,decor,{}, {})
            local count = 0
            for _ in pairs(low) do count += 1 end
            expect(count).toBe(1)
            local behind, ahead = farDecks[3], farDecks[1]
            local facing = Rim.selectVisibleDecks(
                {behind, ahead}, "Medium", base, Vector3.new(-7,12,0),
                0,true,decor,{}, {},Vector3.zAxis)
            expect(facing[behind]).toBe(nil)
            expect(facing[ahead]).toBe("Long")
            local stressed = Rim.selectVisibleDecks(
                {rectangular,elongated},"Medium",base,point,
                1,true,decor,{}, {})
            expect(next(stressed)).toBe(nil)
            local maxStress = Rim.selectVisibleDecks(
                {rectangular,elongated},"High",base,point,
                2,false,decor,{}, {})
            expect(next(maxStress)).toBe(nil)
            local mediumDesktop=Rim.selectVisibleDecks(
                allDecks,"Medium",base,point,0,false,decor,{}, {})
            local highDesktop=Rim.selectVisibleDecks(
                allDecks,"High",base,point,0,false,decor,{}, {})
            local highTouch=Rim.selectVisibleDecks(
                allDecks,"High",base,point,0,true,decor,{}, {})
            local stressedDesktop=Rim.selectVisibleDecks(
                allDecks,"High",base,point,1,false,decor,{}, {})
            local function checkSpread(owners,expectedCount,minFar)
                local count,far=0,0
                for deck,kind in pairs(owners) do
                    count+=1
                    expect(deck.Anchored and deck.CanCollide).toBe(true)
                    expect(kind=="Rect" or kind=="Long").toBe(true)
                    for _,remote in ipairs(farDecks) do
                        if remote==deck then far+=1 end
                    end
                end
                expect(count).toBe(expectedCount)
                expect(far>=minFar).toBe(true)
            end
            checkSpread(mediumDesktop,6,2)
            checkSpread(highDesktop,12,4)
            checkSpread(highTouch,2,0)
            checkSpread(stressedDesktop,4,0)
            -- Android and GPU pressure retain the old foreground
            -- nearest-first selection, rather than paying for skyline
            -- coverage under constrained render budgets.
            for _,remote in ipairs(farDecks) do
                expect(highTouch[remote]).toBe(nil)
                expect(stressedDesktop[remote]).toBe(nil)
            end
            expect(highDesktop[rectangular]).toBe("Rect")
            expect(highDesktop[elongated]).toBe("Long")
            -- Source snapshots are valid only for one selection call:
            -- a newly corrupted imported template must not let an old
            -- verified bounding box authorize a cosmetic replacement.
            local sourceRect=templates:FindFirstChild("Rect")
            local sourcePiece=sourceRect:FindFirstChild("OriginalMaterial_1")
            sourcePiece.CanQuery=true
            local withInvalidRect=Rim.selectVisibleDecks(
                allDecks,"High",base,point,0,false,decor,{}, {})
            expect(withInvalidRect[rectangular]).toBe(nil)
            expect(withInvalidRect[elongated]).toBe("Long")
            for _,kind in pairs(withInvalidRect) do
                expect(kind).toBe("Long")
            end
            sourcePiece.CanQuery=false
            local restored=Rim.selectVisibleDecks(
                allDecks,"High",base,point,0,false,decor,{}, {})
            expect(restored[rectangular]).toBe("Rect")
            -- Existing carapace arbitration still forbids duplicate
            -- approved rims on a previously selected physical deck.
            local reserved=Rim.selectVisibleDecks(
                allDecks,"High",base,point,0,false,decor,
                {[rectangular]=true},{})
            expect(reserved[rectangular]).toBe(nil)
            local rimRect = Rim.install(meshes,rectangular,31,"Rect",decor)
            local rimLong = Rim.install(meshes,elongated,32,"Long",decor)
            expect(rimRect~=nil and #rimRect==7).toBe(true)
            expect(rimLong~=nil and #rimLong==7).toBe(true)
            for _,piece in ipairs(rimRect) do
                expect(piece:IsA("MeshPart")).toBe(true)
                expect(piece.CanCollide or piece.CanTouch or piece.CanQuery)
                    .toBe(false)
                local joint=piece:FindFirstChild("ChaosPlatformTrimWeld")
                expect(joint~=nil and joint.Part1==rectangular).toBe(true)
            end
            Kit.bind(arena,{["31"]="rim",["32"]="rim"},
                nil,nil,meshes)
            local totals=Kit.breakdown()
            expect(totals.bevel).toBe(8)
            expect(totals.underframe).toBe(0)
            expect(rectFrame.LocalTransparencyModifier).toBe(0)
            expect(longFrame.LocalTransparencyModifier).toBe(0)
            for edge=1,4 do
                expect(decor:FindFirstChild(
                    "PlatformBevel31_"..edge).LocalTransparencyModifier)
                    .toBe(1)
                expect(decor:FindFirstChild(
                    "PlatformBevel32_"..edge).LocalTransparencyModifier)
                    .toBe(1)
            end
            expect(rectangular.CanCollide and elongated.CanCollide).toBe(true)
            rectangular:SetAttribute("CollapsePhase","Warning")
            for edge=1,4 do
                expect(decor:FindFirstChild(
                    "PlatformBevel31_"..edge).LocalTransparencyModifier)
                    .toBe(0)
            end
            expect(Kit.breakdown().bevel).toBe(4)
            rectangular:SetAttribute("CollapsePhase","Normal")
            expect(Kit.breakdown().bevel).toBe(8)
            -- Missing ONE of the source's seven materials restores
            -- only the exact original rectangular four-WedgePart fallback.
            rimRect[1]:Destroy()
            expect(Kit.breakdown().bevel).toBe(4)
            for edge=1,4 do
                expect(decor:FindFirstChild(
                    "PlatformBevel31_"..edge).LocalTransparencyModifier)
                    .toBe(0)
            end
            expect(longFrame.LocalTransparencyModifier).toBe(0)
            expect(elongated.CanCollide).toBe(true)

            local Finish = require("../../src/client/PlatformFinishKit")
            local total = 0
            for _, variant in ipairs(ArenaVariants.Order) do
                local live = MapBuilder.buildArena(Config,variant,ArenaVariants,VisualTheme)
                generated = live.Parent
                local deck, mark
                for _, landing in ipairs(live.Platforms:GetChildren()) do
                    if landing:GetAttribute("PerimeterStep")
                        or landing:GetAttribute("BranchStep")
                        or landing:GetAttribute("CrosslinkRoute") then
                        local picks = Rim.selectVisibleDecks({landing},"Low",live.Base,
                            landing.Position,0,true,live.Decor,{[landing]=true})
                        assert(picks[landing]=="Rect",variant.." "..landing.Name)
                        total += 1
                        if landing:GetAttribute("BranchStep")==2 then
                            deck = landing
                            local route = landing:GetAttribute("BranchRoute")
                            mark = live.Decor:FindFirstChild("BranchStepArrow"..route.."_2_1")
                        end
                    end
                end
                local owner = assert(deck)
                local arrow = assert(mark)
                local markerAlpha = arrow.LocalTransparencyModifier
                local id = assert(owner.Name:match("^Platform(%d+)$"))
                local edges = assert(Rim.routeNatives(live.Decor,owner))
                edges[1].LocalTransparencyModifier = .16
                local pieces = assert(Rim.install(meshes,owner,id,"Rect",live.Decor))
                local fascia = pieces[1]
                local width,height = fascia.Size.X,fascia.Size.Y
                local original = owner.Size
                assert(fascia:GetAttribute("OriginalAscensionPlatformRim"))
                assert(width > original.X and width < original.X+.96)
                assert(math.abs((owner.CFrame:PointToObjectSpace(fascia.Position).Y
                    + height*.5) - (original.Y*.5-.09)) < .03)
                footprint=Finish.bindRouteFootprint(owner,pieces,Kit.routeCradleRefitted)
                Kit.bind(live,{[id]="rim"},nil,nil,meshes)
                expect(Kit.breakdown().ascensionRim).toBe(4)
                expect(Kit.breakdown().elevatedRim).toBe(0)
                owner:SetAttribute("CollapsePhase","Warning")
                task.wait()
                expect(Kit.breakdown().ascensionRim).toBe(0)
                assert(math.abs(edges[1].LocalTransparencyModifier-.16)<.001)
                owner:SetAttribute("CollapsePhase","Safe")
                task.wait()
                active=true
                ShrinkingArena.start({Config=Config,RoundSeconds=.12,
                    Active=function() return active end,OnCleanup=cleanup})
                local deadline=os.clock()+1.5
                repeat task.wait() until live.Base.Size.X<=144.05 or os.clock()>deadline
                active=false
                task.wait()
                assert(live.Base.Size.X<=144.05 and owner.CanCollide)
                expect(Kit.breakdown().ascensionRim).toBe(4)
                assert(math.abs(fascia.Size.X-width*.45)<.02 and math.abs(fascia.Size.Y-height)<.02)
                local late = assert(Rim.install(meshes,owner,id,"Rect",live.Decor))
                assert(math.abs(late[1].Size.X-fascia.Size.X)<.02)
                for _, piece in ipairs(late) do piece:Destroy() end
                fascia:FindFirstChild("ChaosPlatformTrimWeld"):Destroy()
                task.wait()
                expect(Kit.breakdown().ascensionRim).toBe(0)
                assert(math.abs(edges[1].LocalTransparencyModifier-.16)<.001)
                assert(arrow.LocalTransparencyModifier==markerAlpha and owner.CanCollide)
                Kit.reset()
                footprint()
                footprint=nil
                for _, stop in ipairs(cleanup) do stop() end
                table.clear(cleanup)
                meshes:ClearAllChildren()
                generated:Destroy()
                generated=nil
            end
            expect(total).toBe(260)
        end)
        Kit.reset()
        active=false
        if footprint then footprint() end
        for _, stop in ipairs(cleanup) do stop() end
        if generated then generated:Destroy() end
        if previousMap then previousMap.Parent=workspace end
        arena:Destroy()
        templates:Destroy()
        if previous then previous.Parent = RS end
        if not ok then error(why) end
    end)
    it("spreads approved full underside hulls across desktop sectors without changing Android or native safety",function()
        local Hull=require("../../src/client/PremiumLargeDeckHullMeshKit")
        local RS=game:GetService("ReplicatedStorage")
        local prior=RS:FindFirstChild("ApprovedLargeDeckHullTemplates")
        if prior then prior.Parent=nil end
        local arena=Instance.new("Folder")
        arena.Name="ApprovedLargeHullDistributionFixture"
        arena.Parent=workspace
        local platforms=Instance.new("Folder")
        platforms.Name="Platforms"
        platforms.Parent=arena
        local decor=Instance.new("Folder")
        decor.Name="Decor"
        decor.Parent=arena
        local templates=Instance.new("Folder")
        templates.Name="ApprovedLargeDeckHullTemplates"
        templates:SetAttribute("OwnerVerified",true)
        templates.Parent=RS
        local model=Instance.new("Model")
        model.Name="LargeDeckHull"
        model:SetAttribute("Original3DAssetId",125929150866282)
        model:SetAttribute("OwnerVerified",true)
        model:SetAttribute("OriginalLargeDeckHull3D",true)
        model:SetAttribute("CosmeticOnly",true)
        for i=1,7 do
            local mesh=Instance.new("MeshPart")
            mesh.Name="ApprovedHullMaterial"..i
            mesh.Size=Vector3.new(17.6,3.1,17.6)
            mesh.Anchored=true
            mesh.CanCollide=false
            mesh.CanTouch=false
            mesh.CanQuery=false
            mesh.Parent=model
        end
        model.Parent=templates
        local base=Instance.new("Part")
        base.Name="Base"
        base.Size=Vector3.new(320,2,320)
        base.CFrame=CFrame.new(0,2,0)
        base.Anchored=true
        base.CanCollide=true
        base.Parent=arena
        local function deck(id,x,z)
            local platform=Instance.new("Part")
            platform.Name="Platform"..id
            platform.Size=Vector3.new(18.5,2,18.5)
            platform.CFrame=CFrame.new(x,12,z)
            platform.Anchored=true
            platform.CanCollide=true
            platform.Parent=platforms
            local frame=Instance.new("Part")
            frame.Name="PlatformUnderFrame"..id
            frame.Anchored=true
            frame.CanCollide=false
            frame.CanTouch=false
            frame.CanQuery=false
            frame:SetAttribute("PremiumArchitecturalSurface",true)
            frame.Parent=decor
            for side=1,4 do
                local edge=Instance.new("WedgePart")
                edge.Name="PlatformBevel"..id.."_"..side
                edge.Anchored=true
                edge.CanCollide=false
                edge.CanTouch=false
                edge.CanQuery=false
                edge:SetAttribute("OriginalStructuralBevel",true)
                edge.Parent=decor
            end
            return platform
        end
        local near={}
        for i,position in ipairs({
            Vector2.new(0,0),Vector2.new(12,15),Vector2.new(-16,9),
            Vector2.new(19,-12),Vector2.new(-14,-17),
            Vector2.new(23,13),Vector2.new(6,-23),Vector2.new(-22,21),
        }) do
            near[#near+1]=deck(100+i,position.X,position.Y)
        end
        local remote={}
        for i,position in ipairs({
            Vector2.new(96,82),Vector2.new(-99,85),
            Vector2.new(-92,-88),Vector2.new(96,-91),
        }) do
            remote[#remote+1]=deck(108+i,position.X,position.Y)
        end
        local ordered={}
        for _,p in ipairs(near) do ordered[#ordered+1]=p end
        for _,p in ipairs(remote) do ordered[#ordered+1]=p end
        local models=Instance.new("Folder")
        models.Name="MountedOriginalHullFixture"
        models.Parent=arena
        local ok,reason=pcall(function()
            local camera=Vector3.new(3,18,3)
            local function choose(tier,touch,pressure)
                return Hull.selectVisibleDecks(
                    ordered,tier,base,camera,pressure,touch,decor)
            end
            local function examine(set,expected,minimumRemote)
                local n,far=0,0
                for p in pairs(set) do
                    n+=1
                    expect(p.Anchored and p.CanCollide).toBe(true)
                    for _,other in ipairs(remote) do
                        if p==other then far+=1 end
                    end
                end
                expect(n).toBe(expected)
                expect(far>=minimumRemote).toBe(true)
            end
            examine(choose("Medium",false,0),3,1)
            local high=choose("High",false,0)
            examine(high,6,2)
            examine(choose("High",true,0),3,0)
            examine(choose("Medium",true,0),1,0)
            examine(choose("High",false,1),3,0)
            expect(next(choose("High",false,2))).toBe(nil)
            for _,p in ipairs(remote) do
                expect(choose("High",true,0)[p]).toBe(nil)
                expect(choose("High",false,1)[p]).toBe(nil)
            end
            expect(high[near[1]]).toBe(true)
            local mounted=Hull.install(models,near[1],"High",101,true,decor)
            expect(mounted~=nil and #mounted==7).toBe(true)
            for _,piece in ipairs(mounted) do
                expect(piece:IsA("MeshPart")).toBe(true)
                expect(piece.CanCollide or piece.CanTouch or piece.CanQuery)
                    .toBe(false)
                expect(piece:FindFirstChild("ChaosPlatformTrimWeld")~=nil)
                    .toBe(true)
            end
            expect(near[1].CanCollide).toBe(true)
            local edge=decor:FindFirstChild("PlatformBevel101_1")
            expect(edge~=nil and edge:IsA("WedgePart")).toBe(true)
            -- A partially streamed native edge must NEVER reserve an
            -- approved model or leave its real fallback hidden.
            edge:Destroy()
            expect(choose("High",false,0)[near[1]]).toBe(nil)
            expect(Hull.install(models,near[1],"High",101,true,decor))
                .toBe(nil)
            -- Source provenance revoked: no newly selected hulls.
            model:SetAttribute("OwnerVerified",false)
            expect(next(choose("High",false,0))).toBe(nil)
        end)
        models:Destroy()
        arena:Destroy()
        templates:Destroy()
        if prior then prior.Parent=RS end
        if not ok then error(reason) end
    end)

    it("mounts complete forged Harbor frames on real animated jetty endpoints",function()
        local Outpost=require("../../src/client/HarborOutpostKit")
        local Finish=require("../../src/client/PlatformFinishKit")
        local prior=workspace:FindFirstChild("GeneratedMap")
        if prior then prior.Parent=nil end
        local arena=MapBuilder.buildArena(Config,"Harbor",ArenaVariants,VisualTheme)
        local owner=Instance.new("Folder")
        owner.Parent=arena.Parent
        local column,truss=Instance.new("Model"),Instance.new("Model")
        column:SetAttribute("Original3DAssetId",76194593490199)
        truss:SetAttribute("Original3DAssetId",122766792774607)
        local columnSize,trussSize=Vector3.new(1.92,13.91,1.93),Vector3.new(1,2,10)
        for model,size in pairs({[column]=columnSize,[truss]=trussSize}) do
            for i=1,7 do
                local mesh=Instance.new("MeshPart")
                mesh.Size=i==1 and size or Vector3.one*.2
                mesh.Anchored=true
                mesh.CanCollide=false
                mesh.CanTouch=false
                mesh.CanQuery=false
                mesh.Parent=model
            end
        end
        local sources={column=column,columnSize=columnSize,truss=truss,trussSize=trussSize}
        local function factory(name,size,cf,color,material,alpha,anchor,mesh)
            local part=mesh or Instance.new("Part")
            part.Name=name
            part.Size=size
            part.CFrame=cf
            part.Color=color
            part.Material=material
            part.Transparency=alpha
            part:SetAttribute("ChaosBaseTransparency",alpha)
            part.Anchored=false
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.Massless=true
            local weld=Instance.new("Weld")
            weld.Name="PlatformIdentityWeld"
            weld.Part0=part
            weld.Part1=anchor
            weld.C1=anchor.CFrame:ToObjectSpace(cf)
            weld.Parent=part
            part.Parent=owner
            return part
        end
        local disconnect
        local running=false
        local cleanup={}
        local ok,why=pcall(function()
            local decks=arena.Platforms:GetChildren()
            local deck=arena.Platforms.Platform98
            assert(deck:GetAttribute("HarborSpokeStep")==4)
            local found,limit=Outpost.candidates(decks,"High",deck.Position,0,true)
            assert(found[1].deck==deck and limit==1)
            local _,desktopLimit=Outpost.candidates(decks,"High",deck.Position,0,false)
            assert(desktopLimit==2)
            assert(#(Outpost.candidates(decks,"Medium",deck.Position,1,false))==0)
            local theme=VisualTheme.arena("Harbor")
            local function install()
                local lost=0
                local count,instrument,stop=Outpost.build(factory,deck,98,theme,"High",sources,
                    function() lost+=1 end)
                disconnect=stop
                assert(count==9 and instrument and stop)
                assert(instrument.Name=="HarborStormRadarInstrument98")
                assert(Outpost.motionTarget(1,"normal")~=nil)
                local meshes=0
                local beam
                for _,part in ipairs(owner:GetChildren()) do
                    if part:IsA("MeshPart") then
                        meshes+=1
                        assert(part:GetAttribute("OriginalHarborOutpostFrame3D"))
                        assert(not part.CanCollide and not part.CanTouch and not part.CanQuery)
                        if part:GetAttribute("Original3DAssetId")==122766792774607
                            and math.max(part.Size.X,part.Size.Z)>2 then beam=part end
                    end
                end
                assert(meshes==21 and beam)
                local leg=owner.HarborStormRadarPortLeg98
                expect(leg.Transparency).toBe(1)
                return beam,leg,function() return lost end
            end
            local beam,leg=install()
            local snapshot=Finish.captureRouteFootprint(deck,owner:GetChildren())
            local original=beam.Size
            running=true
            ShrinkingArena.start({Config=Config,RoundSeconds=.12,
                Active=function() return running end,OnCleanup=cleanup})
            local deadline=os.clock()+1.5
            repeat task.wait() until arena.Base.Size.X<=144.05 or os.clock()>deadline
            running=false
            task.wait()
            assert(arena.Base.Size.X<=144.05)
            Finish.applyRouteFootprint(snapshot)
            assert(math.abs(math.max(beam.Size.X,beam.Size.Z)
                -math.max(original.X,original.Z)*.45)<.03)
            local finalSize=beam.Size
            local finalWeld=beam.PlatformIdentityWeld.C1.Position
            disconnect()
            owner:ClearAllChildren()
            local late,lateLeg,lost=install()
            assert((late.Size-finalSize).Magnitude<.04)
            assert((late.PlatformIdentityWeld.C1.Position-finalWeld).Magnitude<.04)
            late.PlatformIdentityWeld:Destroy()
            task.wait()
            assert(lost()==1 and math.abs(lateLeg.Transparency-.06)<.01)
            Finish.applyCollapseVisibility(owner:GetChildren(),"Gone")
            expect(lateLeg.Transparency).toBe(1)
            for _,part in ipairs(owner:GetChildren()) do
                if part:IsA("MeshPart") then expect(part.Transparency).toBe(1) end
            end
            disconnect()
            owner:ClearAllChildren()
            -- Already contracted real platform. Finish pieces share the
            -- late-join dimensions but keep independent welded ownership.
            local _, pivot, _, nativeFinish=Outpost.build(factory,deck,98,theme,"High")
            local keel, wings=nativeFinish.Keel[1],nativeFinish.Wing
            local wing=truss:Clone()
            wing:SetAttribute("Original3DAssetId",138096293972093)
            cleanup[#cleanup+1]=function() wing:Destroy() end
            local lostFinish=0
            local function lostGroup() lostFinish+=1 end
            local keelStop,keelCount=Outpost.mountFinishing(
                factory,deck,nativeFinish.Keel,"Keel",truss,trussSize,lostGroup)
            local wingStop,wingCount=Outpost.mountFinishing(
                factory,deck,wings,"Wing",wing,trussSize,lostGroup)
            assert(keelStop and keelCount==7 and wingStop and wingCount==14)
            assert(pivot.Transparency<1 and deck.CanCollide)
            assert(keel.Transparency==1 and wings[1].Transparency==1 and wings[2].Transparency==1)
            local bottom = math.huge
            local wingSculpt
            for _,part in ipairs(owner:GetChildren()) do
                local kind = part:GetAttribute("OriginalHarborOutpostFinishing3D")
                if kind == "Keel" then
                    local y = part.PlatformIdentityWeld.C1.Position.Y
                    assert(y+part.Size.Y*.5 <= -deck.Size.Y*.5)
                    bottom = math.min(bottom,y-part.Size.Y*.5)
                elseif kind == "Wing" then
                    assert(part.PlatformIdentityWeld.C1.Position.Y > 5.5)
                    wingSculpt = part
                end
            end
            assert(bottom < -2.69 and wingSculpt)
            wingSculpt.PlatformIdentityWeld:Destroy()
            task.wait()
            assert(lostFinish==1 and keel.Transparency==1)
            assert(math.abs(wings[1].Transparency-.16)<.01 and math.abs(wings[2].Transparency-.16)<.01)
            wing:FindFirstChildWhichIsA("MeshPart"):Destroy()
            assert(Outpost.mountFinishing(
                factory,deck,wings,"Wing",wing,trussSize,lostGroup)==nil)
            assert(math.abs(wings[1].Transparency-.16)<.01)
            keelStop()
            wingStop()
            owner:ClearAllChildren()
            truss:FindFirstChildWhichIsA("MeshPart"):Destroy()
            local _,fallback,failed=Outpost.build(factory,deck,98,theme,"Medium",sources)
            assert(fallback and failed==nil and #owner:GetChildren()==5)
            assert(deck.CanCollide and deck:FindFirstChild("HarborDryDockOutpost"))
            assert(leg.Parent==nil)

            local storage = game:GetService("ReplicatedStorage")
            local instruments = {
                {"ApprovedHarborHeroStationTemplates","SignalStation","OriginalHarborHeroStation3D",
                    73237902371094,Vector3.new(.9,1,9),"OriginalHarborHeroMotionRole","Radar",1},
                {"ApprovedHarborKineticGantryTemplates","CableGantry","OriginalHarborKineticGantry3D",
                    98809955094422,Vector3.new(8.8,7.2,5.3),"OriginalHarborGantryKineticRole","Load",1},
                {"ApprovedOrbitalReactorLandmarkTemplates","Node","OriginalOrbitalReactorLandmark3D",
                    104654294187035,Vector3.new(4.36,4.36,4.36),nil,nil,7},
                {"ApprovedPerimeterVariantApexTemplates","Relay","OriginalPerimeterVariantApex3D",
                    110237986522853,Vector3.new(2.26,6.0595,1.89),nil,nil,7},
            }
            for route,spec in ipairs(instruments) do
                local previous = storage:FindFirstChild(spec[1])
                if previous then previous.Parent=nil end
                local holder=Instance.new("Folder")
                holder.Name=spec[1]
                holder:SetAttribute("OwnerVerified",true)
                cleanup[#cleanup+1]=function()
                    holder:Destroy()
                    if previous then previous.Parent=storage end
                end
                holder.Parent=storage
                local model=Instance.new("Model")
                model.Name=spec[2]
                model:SetAttribute(spec[3],true)
                model:SetAttribute("Original3DAssetId",spec[4])
                model:SetAttribute("OwnerVerified",true)
                model:SetAttribute("CosmeticOnly",true)
                for i=1,7 do
                    local mesh=Instance.new("MeshPart")
                    mesh.Size=i==1 and spec[5] or Vector3.one*.2
                    mesh.Position=i==1 and Vector3.zero or Vector3.new(.4,.25,0)
                    mesh.Anchored=true
                    mesh.CanCollide=false
                    mesh.CanTouch=false
                    mesh.CanQuery=false
                    if i==1 and spec[6] then mesh:SetAttribute(spec[6],spec[7]) end
                    mesh.Parent=model
                end
                model.Parent=holder
                owner:ClearAllChildren()
                local index=98+(route-1)*4
                local endpoint=arena.Platforms["Platform"..index]
                local _,pivot=Outpost.build(factory,endpoint,index,theme,"Medium")
                assert(pivot)
                local lost=0
                local sculpture=assert(Outpost.mountInstrument(factory,endpoint,pivot,function()
                    lost+=1
                end))
                disconnect=sculpture.disconnect
                assert(#sculpture.parts==spec[8] and pivot.Transparency==1)
                local joint=pivot.PlatformIdentityWeld
                local pose=assert(Outpost.motionTarget(route,"normal"))
                joint.C0=pose
                Outpost.applyInstrumentPose(joint,sculpture.parts)
                for _,part in ipairs(sculpture.parts) do
                    local meshJoint=part.PlatformIdentityWeld
                    local offset=joint.C1:ToObjectSpace(meshJoint.C1)
                    local expected=joint.C1*pose:Inverse()*offset
                    local actual=meshJoint.C1*meshJoint.C0:Inverse()
                    assert((expected.Position-actual.Position).Magnitude<.001)
                    assert(expected.LookVector:Dot(actual.LookVector)>.9999)
                    assert(not part.CanCollide and part:GetAttribute("Original3DAssetId")==spec[4])
                end
                endpoint:SetAttribute("CollapsePhase","Warning")
                Finish.applyCollapseVisibility(owner:GetChildren(),"Warning")
                sculpture.parts[1].PlatformIdentityWeld:Destroy()
                task.wait()
                assert(lost==1 and math.abs(pivot.Transparency-.8)<.01)
                endpoint:SetAttribute("CollapsePhase","Safe")
                Finish.applyCollapseVisibility(owner:GetChildren(),"Safe")
                assert(math.abs(pivot.Transparency-.1)<.01)
                disconnect()
            end
        end)
        running=false
        if disconnect then disconnect() end
        for _,stop in ipairs(cleanup) do stop() end
        arena.Parent:Destroy()
        column:Destroy()
        truss:Destroy()
        if prior then prior.Parent=workspace end
        if not ok then error(why) end
    end)

    it("fits the forged Harbor pile to short piers and tall crossings through shrink", function()
        local Large=require("../../src/client/PremiumLargeStructureMeshKit")
        local Rules=require("../../src/shared/PlatformIdentityLodRules")
        local storage=game:GetService("ReplicatedStorage")
        local priorTemplates=storage:FindFirstChild("ApprovedLargeStructureTemplates")
        local priorMap=workspace:FindFirstChild("GeneratedMap")
        if priorTemplates then priorTemplates.Parent=nil end
        if priorMap then priorMap.Parent=nil end
        local arena=MapBuilder.buildArena(Config,"Harbor",ArenaVariants,VisualTheme)
        local visuals=Instance.new("Folder")
        visuals.Parent=arena.Parent
        local templates=Instance.new("Folder")
        templates.Name="ApprovedLargeStructureTemplates"
        templates:SetAttribute("OwnerVerified",true)
        templates.Parent=storage
        local source=Instance.new("Model")
        source.Name="Harbor"
        source:SetAttribute("Original3DAssetId",76194593490199)
        source:SetAttribute("OriginalLargeStructure3D",true)
        source:SetAttribute("OwnerVerified",true)
        source:SetAttribute("CosmeticOnly",true)
        for i=1,7 do
            local mesh=Instance.new("MeshPart")
            mesh.Size=i==1 and Vector3.new(2,14,1.8) or Vector3.one*.2
            mesh.Anchored=true
            mesh.CanCollide=false
            mesh.CanTouch=false
            mesh.CanQuery=false
            mesh.Parent=source
        end
        source.Parent=templates
        local running=false
        local cleanup,connections={},{}
        local ok,why=pcall(function()
            local base,decor,platforms=arena.Base,arena.Decor,arena.Platforms
            local count=0
            for _,part in ipairs(decor:GetChildren()) do
                local id=part.Name:match("^PlatformSupport(%d+)_%d+$")
                local deck=id and platforms:FindFirstChild("Platform"..id)
                if deck and Rules.isHarborLanding(deck) then
                    local scale=Large.routeSupportScale(part,deck)
                    assert(scale and math.abs(scale-1)<.002,part.Name)
                    count+=1
                end
            end
            expect(count).toBe(140)
            local short=platforms.Platform96
            assert(short:GetAttribute("HarborSpokeStep")==2)
            local tall=platforms.Platform84
            assert(tall:GetAttribute("HarborSkywayStep")~=nil)
            local shortPile,tallPile=decor.PlatformSupport96_1,decor.PlatformSupport84_2
            local function install(deck,pile)
                local index=tonumber(deck.Name:match("%d+"))
                local _,chosen=Large.selectNearRouteStructures(
                    {deck},decor,"Harbor","Low",base,pile.Position,nil,0,false)
                expect(chosen[deck]).toBe(true)
                local result=assert(Large.supports(
                    visuals,decor,deck,"Harbor","Low",index,1,true,pile.Position))
                for _,connection in ipairs(result.disconnects) do
                    connections[#connections+1]=connection
                end
                assert(result.modules==1 and #result.parts==7 and result.covered[1]==pile)
                return result.parts
            end
            local shortPieces=install(short,shortPile)
            local tallPieces=install(tall,tallPile)
            local function largest(pieces)
                local piece=pieces[1]
                for _,candidate in ipairs(pieces) do
                    if candidate.Size.Y>piece.Size.Y then piece=candidate end
                end
                return piece
            end
            local shaft=largest(tallPieces)
            local shortShaft=largest(shortPieces)
            assert(math.abs(shaft.Size.Y-tallPile.Size.Y)<.02)
            assert(math.abs(shortShaft.Size.Y-shortPile.Size.Y)<.02)
            local initial=shaft.Size
            Kit.bind(arena,{},nil,{shortPile,tallPile},visuals)
            expect(Kit.breakdown().harborPile).toBe(2)
            short:SetAttribute("CollapsePhase","Warning")
            task.wait()
            expect(shortPile.LocalTransparencyModifier).toBe(0)
            expect(shortShaft.LocalTransparencyModifier).toBe(1)
            expect(tallPile.LocalTransparencyModifier).toBe(1)
            local _,pressured=Large.selectNearRouteStructures(
                {short,tall},decor,"Harbor","Medium",base,tallPile.Position,nil,1,false)
            expect(next(pressured)).toBe(nil)

            running=true
            ShrinkingArena.start({Config=Config,RoundSeconds=.12,
                Active=function() return running end,OnCleanup=cleanup})
            local deadline=os.clock()+1.5
            repeat task.wait() until base.Size.X<=144.05 or os.clock()>deadline
            running=false
            task.wait()
            assert(base.Size.X<=144.05 and tall.CanCollide)
            assert(math.abs(Large.routeSupportScale(tallPile,tall)-.45)<.002)
            assert(tallPile.LocalTransparencyModifier==1)
            assert(math.abs(shaft.Size.X-initial.X*.45)<.02 and shaft.Size.Y==initial.Y)
            local final=shaft.Size
            Kit.reset()
            visuals:ClearAllChildren()
            local late=install(tall,tallPile)
            assert((largest(late).Size-final).Magnitude<.03)
            Kit.bind(arena,{},nil,{tallPile},visuals)
            expect(Kit.breakdown().harborPile).toBe(1)
            Kit.setPylonLodVisible(tallPile,false)
            expect(tallPile.LocalTransparencyModifier).toBe(0)
            Kit.setPylonLodVisible(tallPile,true)
            late[1]:FindFirstChild("ChaosPlatformTrimWeld"):Destroy()
            task.wait()
            expect(tallPile.LocalTransparencyModifier).toBe(0)
            expect(late[2].LocalTransparencyModifier).toBe(1)
        end)
        running=false
        Kit.reset()
        for _,stop in ipairs(cleanup) do stop() end
        for _,connection in ipairs(connections) do connection:Disconnect() end
        arena.Parent:Destroy()
        templates:Destroy()
        if priorTemplates then priorTemplates.Parent=storage end
        if priorMap then priorMap.Parent=workspace end
        if not ok then error(why) end
    end)

    it("replaces the Harbor panel with grooved timber and restores the exact fallback",function()
        local Route=require("../../src/client/PremiumRouteMeshKit")
        local storage=game:GetService("ReplicatedStorage")
        local previous=storage:FindFirstChild("PremiumRouteMeshTemplates")
        local previousMap=workspace:FindFirstChild("GeneratedMap")
        if previous then previous.Parent=nil end
        if previousMap then previousMap.Parent=nil end
        local arena=MapBuilder.buildArena(Config,"Harbor",ArenaVariants,VisualTheme)
        local holder=Instance.new("Folder")
        holder.Name="PremiumRouteMeshTemplates"
        holder:SetAttribute("OwnerVerified",true)
        holder.Parent=storage
        local source=Instance.new("Model")
        source.Name="PremiumJumpDeck"
        source:SetAttribute("Original3DAssetId",98478693994864)
        source:SetAttribute("OwnerVerified",true)
        source:SetAttribute("CosmeticOnly",true)
        source:SetAttribute("PremiumRoute3D",true)
        for i=1,7 do
            local mesh=Instance.new("MeshPart")
            mesh.Size=i==1 and Vector3.new(11.1,.106,11.1)
                or Vector3.new(11.94,1.6,11.94)
            mesh.Anchored=true
            mesh.CanCollide=false
            mesh.CanTouch=false
            mesh.CanQuery=false
            mesh.Parent=source
        end
        source.Parent=holder
        local running=false
        local cleanup={}
        local ok,why=pcall(function()
            local deck=arena.Platforms.Platform98
            local panel=arena.Decor.PlatformPanel98
            panel.LocalTransparencyModifier=.18
            local function find()
                for _,model in ipairs(workspace.PremiumRouteMeshLocal:GetChildren()) do
                    if model:GetAttribute("OriginalHarborTimberDeck3D") then
                        local part=model:FindFirstChildWhichIsA("MeshPart")
                        if part.OriginalRouteMeshCosmeticWeld.Part0==deck then return part end
                    end
                end
            end
            local function mount()
                Route.sync(arena,deck.Position,"Low",true,nil,0,true)
                return assert(find())
            end
            local timber=mount()
            assert(Route.coveredPanelCount()>=1)
            assert(Route.timberCount()>=1 and Route.timberCount()<=2)
            assert(timber.Material==Enum.Material.WoodPlanks and not timber.CanCollide)
            assert(timber.LocalTransparencyModifier==0 and panel.LocalTransparencyModifier==1)
            assert(math.abs(timber.Size.X-(deck.Size.X-.8)*.987)<.02)
            deck:SetAttribute("CollapsePhase","Warning")
            task.wait()
            assert(timber.LocalTransparencyModifier==1 and math.abs(panel.LocalTransparencyModifier-.18)<.01)
            deck:SetAttribute("CollapsePhase","Safe")
            panel.Parent=nil
            task.wait()
            assert(timber.LocalTransparencyModifier==1 and math.abs(panel.LocalTransparencyModifier-.18)<.01)
            panel.Parent=arena.Decor
            task.wait()
            assert(timber.LocalTransparencyModifier==0 and panel.LocalTransparencyModifier==1)
            local oldSize=timber.Size
            running=true
            ShrinkingArena.start({Config=Config,RoundSeconds=.12,
                Active=function() return running end,OnCleanup=cleanup})
            local deadline=os.clock()+1.5
            repeat task.wait() until arena.Base.Size.X<=144.05 or os.clock()>deadline
            running=false
            task.wait()
            assert(arena.Base.Size.X<=144.05 and timber.LocalTransparencyModifier==0)
            assert(math.abs(timber.Size.X-oldSize.X*.45)<.02 and timber.Size.Y==oldSize.Y)
            local contracted=timber.Size
            Route.sync(nil,Vector3.zero,"Low",false)
            assert(math.abs(panel.LocalTransparencyModifier-.18)<.01)
            local late=mount()
            assert((late.Size-contracted).Magnitude<.03 and panel.LocalTransparencyModifier==1)
            late.OriginalRouteMeshCosmeticWeld:Destroy()
            task.wait()
            assert(late.LocalTransparencyModifier==1 and deck.CanCollide)
            assert(math.abs(panel.LocalTransparencyModifier-.18)<.01)
        end)
        running=false
        Route.sync(nil,Vector3.zero,"Low",false)
        for _,stop in ipairs(cleanup) do stop() end
        arena.Parent:Destroy()
        holder:Destroy()
        if previous then previous.Parent=storage end
        if previousMap then previousMap.Parent=workspace end
        if not ok then error(why) end
    end)

    it("fits complete Harbor girders through real contraction and restores their separate native groups",function()
        local Finish=require("../../src/client/PlatformFinishKit")
        local Side=require("../../src/client/PremiumPlatformSideMeshKit")
        local Hardware=require("../../src/client/PremiumFloorHardwareMeshKit")
        local Outpost=require("../../src/client/HarborOutpostKit")
        local storage=game:GetService("ReplicatedStorage")
        local previous=storage:FindFirstChild("ApprovedPlatformSideTemplates")
        local previousHardware=storage:FindFirstChild("ApprovedFloorReliefTemplates")
        local previousMap=workspace:FindFirstChild("GeneratedMap")
        if previous then previous.Parent=nil end
        if previousHardware then previousHardware.Parent=nil end
        if previousMap then previousMap.Parent=nil end
        local arena=MapBuilder.buildArena(Config,"Harbor",ArenaVariants,VisualTheme)
        local holder=Instance.new("Folder")
        holder.Name="ApprovedPlatformSideTemplates"
        holder:SetAttribute("OwnerVerified",true)
        holder.Parent=storage
        local source=Instance.new("Model")
        source.Name="Bridge"
        source:SetAttribute("Original3DAssetId",122766792774607)
        source:SetAttribute("OwnerVerified",true)
        source:SetAttribute("CosmeticOnly",true)
        source:SetAttribute("OriginalStructuralSide3D",true)
        local sizes={Vector3.new(9.62,.39,.55),Vector3.new(9.18,.42,.34),
            Vector3.new(7.8371,.9701,.1465),Vector3.new(9,1.505,.45),
            Vector3.new(9.48,.56,.49),Vector3.new(8.82,.22,.34),Vector3.one*.2}
        local sourceParts={}
        for i,size in ipairs(sizes) do
            local mesh=Instance.new("MeshPart")
            mesh.Size=size
            if i==2 then mesh.CFrame=CFrame.new(.06,-.41,0) end
            if i==3 then mesh.CFrame=CFrame.new(-.14,-.10,0) end
            mesh.Anchored=true
            mesh.CanCollide=false
            mesh.CanTouch=false
            mesh.CanQuery=false
            mesh.Parent=source
            sourceParts[i]=mesh
        end
        source.Parent=holder
        local hardware=Instance.new("Folder")
        hardware.Name="ApprovedFloorReliefTemplates"
        hardware:SetAttribute("OwnerVerified",true)
        hardware.Parent=storage
        local cornerModel=Instance.new("Model")
        cornerModel.Name="CornerGuard"
        cornerModel:SetAttribute("Original3DAssetId",102215174919938)
        cornerModel:SetAttribute("OwnerVerified",true)
        cornerModel:SetAttribute("CosmeticOnly",true)
        cornerModel:SetAttribute("OriginalFloorRelief3D",true)
        local cornerSizes={Vector3.new(5.08,.33,5.08),Vector3.new(4.12,.1005,3.904),
            Vector3.new(3.884,.124,3.76),Vector3.new(4.65,.064,1.61),
            Vector3.new(2.78,.048,.7),Vector3.new(2.7,.024,.42),Vector3.new(1.35,.022,.105)}
        for index,size in ipairs(cornerSizes) do
            local part=sourceParts[1]:Clone()
            part.Size=size
            part.CFrame=CFrame.new(index==2 and .07 or 0,index==2 and .06 or 0,0)
            part.Parent=cornerModel
        end
        cornerModel.Parent=hardware
        local owner=Instance.new("Folder")
        owner.Parent=arena
        local disconnectRails,disconnectBraces,disconnectKeel,disconnectCorners
        local running=false
        local cleanup={}
        local ok,why=pcall(function()
            local theme=VisualTheme.arena("Harbor")
            local deck=arena.Platforms.Platform96
            local function buildRails(tier)
                return Finish.buildSideRails(owner,deck,tier,theme,"Harbor",96,false,Side.harborGirderSource())
            end
            local function buildBraces(tier)
                return Finish.buildLoadBraces(owner,deck,"Harbor",tier,theme,Side.harborGirderSource())
            end
            local function buildCorners(tier)
                local natives=Finish.buildArmor(owner,deck,"Harbor",tier,theme)
                local meshes,map=Finish.mountHarborCornerArmor(owner,deck,natives,Hardware.harborCornerSource())
                return natives,meshes,map
            end
            local function buildKeel()
                local keel=Finish.build(owner,deck,"Harbor","High",theme)[3]
                local mount=Instance.new("Part")
                mount.Name="HarborKeelMount96"
                mount.Size=Finish.harborKeelMountSize(deck)
                mount.Transparency=.13
                mount.CanCollide=false
                mount.CanTouch=false
                mount.CanQuery=false
                mount.Massless=true
                local joint=Instance.new("Weld")
                joint.Name="PlatformIdentityWeld"
                joint.Part0,joint.Part1=mount,deck
                joint.C1=CFrame.new(0,-deck.Size.Y*.5-.23,0)
                mount.CFrame=deck.CFrame*joint.C1
                joint.Parent=mount
                mount.Parent=owner
                local meshes,fallback=Finish.mountHarborLandingKeel(owner,deck,keel,mount,Side.harborGirderSource())
                return keel,mount,meshes,fallback
            end
            local medium,mediumMeshes=buildRails("Medium")
            assert(#medium==8 and #mediumMeshes==6)
            local mediumBraces,mediumOriginals=buildBraces("Medium")
            assert(#mediumBraces==8 and #mediumOriginals==6 and #buildBraces("Low")==0)
            local mediumCorners,mediumArmor=buildCorners("Medium")
            assert(#mediumCorners==2 and #mediumArmor==6)
            owner:ClearAllChildren()
            local pieces,meshes,fallback=buildRails("High")
            local braces,braceMeshes,braceFallback=buildBraces("High")
            local keel,keelMount,keelMeshes,keelFallback=buildKeel()
            local armor,armorMeshes,armorFallback=buildCorners("High")
            assert(#pieces==16 and #meshes==12)
            assert(#braces==16 and #braceMeshes==12)
            assert(#keelMeshes==3 and keel.Transparency==1 and keelMount.Transparency==1)
            assert(#armor==4 and #armorMeshes==12)
            for _,mesh in ipairs(armorMeshes) do
                assert(mesh:GetAttribute("OriginalHarborCornerArmor3D"))
                assert(not mesh.CanCollide and not mesh.CanTouch and not mesh.CanQuery)
                local localFrame=mesh.ChaosPlatformTrimWeld.C1
                assert(math.abs(localFrame.Position.X)+math.max(mesh.Size.X,mesh.Size.Z)*.5<deck.Size.X*.5)
                assert(localFrame.Position.Y-mesh.Size.Y*.5>=deck.Size.Y*.5+.104)
            end
            for _,mesh in ipairs(keelMeshes) do
                assert(mesh:GetAttribute("OriginalHarborLandingKeel3D"))
                assert(not mesh.CanCollide and not mesh.CanTouch and not mesh.CanQuery)
                local joint=mesh.ChaosPlatformTrimWeld
                assert(joint.Part0==mesh and joint.Part1==deck)
                assert(joint.C1.Position.Y+mesh.Size.Y*.5<deck.Size.Y*.5)
            end
            for native in pairs(fallback) do assert(native.Transparency==1) end
            for native in pairs(braceFallback) do assert(native.Transparency==1) end
            for _,mesh in ipairs(meshes) do
                assert(mesh:GetAttribute("OriginalHarborRecessedRail3D"))
                assert(not mesh.CanCollide and not mesh.CanTouch and not mesh.CanQuery)
                local weld=mesh.ChaosPlatformTrimWeld
                assert(weld.Part0==mesh and weld.Part1==deck)
                assert(weld.C1.Position.Y+mesh.Size.Y*.5<deck.Size.Y*.5)
            end
            for _,mesh in ipairs(braceMeshes) do
                assert(mesh:GetAttribute("OriginalHarborLoadBrace3D") and mesh:GetAttribute("ChaosLoadBrace"))
                assert(not mesh.CanCollide and not mesh.CanTouch and not mesh.CanQuery)
                local weld=mesh.ChaosPlatformTrimWeld
                assert(weld.Part0==mesh and weld.Part1==deck)
            end
            local snapshot=Finish.captureRouteFootprint(deck,owner:GetChildren())
            running=true
            ShrinkingArena.start({Config=Config,RoundSeconds=.12,
                Active=function() return running end,OnCleanup=cleanup})
            local deadline=os.clock()+1.5
            repeat task.wait() until arena.Base.Size.X<=144.05 or os.clock()>deadline
            running=false
            task.wait()
            assert(arena.Base.Size.X<=144.05 and Finish.applyRouteFootprint(snapshot)==55)
            local topSocket=braces[1].ChaosPlatformTrimWeld.C1:PointToWorldSpace(Vector3.zAxis*braces[1].Size.Z*.5)
            assert((topSocket-Vector3.new(-deck.Size.X*.36,-deck.Size.Y*.5-.10,-deck.Size.Z*.30)).Magnitude<.02)
            local contracted={}
            for _,piece in ipairs(owner:GetChildren()) do
                local joint=piece:FindFirstChild("ChaosPlatformTrimWeld") or piece.PlatformIdentityWeld
                contracted[piece.Name]={piece.Size,joint.C1}
            end
            owner:ClearAllChildren()
            pieces,meshes,fallback=buildRails("High")
            braces,braceMeshes,braceFallback=buildBraces("High")
            keel,keelMount,keelMeshes,keelFallback=buildKeel()
            armor,armorMeshes,armorFallback=buildCorners("High")
            assert(#pieces==16 and #meshes==12)
            assert(#braces==16 and #braceMeshes==12)
            for _,piece in ipairs(owner:GetChildren()) do
                local original=contracted[piece.Name]
                local joint=piece:FindFirstChild("ChaosPlatformTrimWeld") or piece.PlatformIdentityWeld
                local frame=joint.C1
                assert((piece.Size-original[1]).Magnitude<.03,
                    ("%s rebuilt size %s, live contracted size %s")
                        :format(piece.Name,tostring(piece.Size),tostring(original[1])))
                assert((frame.Position-original[2].Position).Magnitude<.03,
                    ("%s rebuilt offset %s, live contracted offset %s")
                        :format(piece.Name,tostring(frame.Position),tostring(original[2].Position)))
                assert(frame.LookVector:Dot(original[2].LookVector)>.999)
            end
            disconnectRails=Outpost.bindWeldedReplacement(deck,meshes,fallback)
            disconnectBraces=Outpost.bindWeldedReplacement(deck,braceMeshes,braceFallback)
            disconnectKeel=Outpost.bindWeldedReplacement(deck,keelMeshes,keelFallback)
            disconnectCorners=Outpost.bindWeldedReplacement(deck,armorMeshes,armorFallback)
            Finish.applyCollapseVisibility(braces,"Warning")
            assert(braceMeshes[1].Transparency>=.8 and braces[1].Transparency==1)
            Finish.applyCollapseVisibility(braces,"Safe")
            assert(braceMeshes[1].Transparency<.8 and braces[1].Transparency==1)
            meshes[7].ChaosPlatformTrimWeld:Destroy()
            task.wait()
            for native,alpha in pairs(fallback) do assert(math.abs(native.Transparency-alpha)<.01) end
            for _,mesh in ipairs(meshes) do assert(mesh.Transparency==1) end
            assert(braceMeshes[1].Transparency<1 and braces[1].Transparency==1)
            braceMeshes[7].ChaosPlatformTrimWeld:Destroy()
            task.wait()
            for native,alpha in pairs(braceFallback) do assert(math.abs(native.Transparency-alpha)<.01) end
            for _,mesh in ipairs(braceMeshes) do assert(mesh.Transparency==1) end
            assert(keel.Transparency==1 and keelMount.Transparency==1 and keelMeshes[1].Transparency<1)
            keelMeshes[1].ChaosPlatformTrimWeld:Destroy()
            task.wait()
            assert(math.abs(keel.Transparency-.10)<.01 and math.abs(keelMount.Transparency-.13)<.01)
            for _,mesh in ipairs(keelMeshes) do assert(mesh.Transparency==1) end
            assert(armor[1].Transparency==1 and armorMeshes[1].Transparency<1)
            armorMeshes[4].ChaosPlatformTrimWeld:Destroy()
            task.wait()
            for _,part in ipairs(armor) do assert(math.abs(part.Transparency-.04)<.01) end
            for _,mesh in ipairs(armorMeshes) do assert(mesh.Transparency==1) end
            deck:SetAttribute("LocalOriginalHarborDockCaissonMounted",true)
            local caissonNative,caissonBraces=buildBraces("High")
            assert(#caissonNative==4 and not caissonBraces)
            local caissonKeel,_,caissonMesh=buildKeel()
            assert(caissonKeel.Transparency<1 and not caissonMesh)
            local caissonArmor,caissonCorners=buildCorners("High")
            assert(caissonArmor[1].Transparency<1 and not caissonCorners)
            deck:SetAttribute("LocalOriginalHarborDockCaissonMounted",nil)
            sourceParts[1]:Destroy()
            local nativeOnly,missing=buildRails("High")
            assert(#nativeOnly==4 and not missing and nativeOnly[1].Transparency<1)
            local nativeBraces,missingBraces=buildBraces("High")
            assert(#nativeBraces==4 and not missingBraces and nativeBraces[1].Transparency<1)
            assert(deck.CanCollide and arena.Decor.PlatformPanel96.Transparency<1)
        end)
        running=false
        if disconnectRails then disconnectRails() end
        if disconnectBraces then disconnectBraces() end
        if disconnectKeel then disconnectKeel() end
        if disconnectCorners then disconnectCorners() end
        for _,stop in ipairs(cleanup) do stop() end
        arena.Parent:Destroy()
        holder:Destroy()
        hardware:Destroy()
        if previous then previous.Parent=storage end
        if previousHardware then previousHardware.Parent=storage end
        if previousMap then previousMap.Parent=workspace end
        if not ok then error(why) end
    end)

    it("fits the approved cargo tie-down to the 58 real Harbor landings",function()
        local Finish=require("../../src/client/PlatformFinishKit")
        local Outpost=require("../../src/client/HarborOutpostKit")
        local Rules=require("../../src/shared/PlatformIdentityLodRules")
        local storage=game:GetService("ReplicatedStorage")
        local previous=storage:FindFirstChild("ApprovedFloorReliefTemplates")
        local previousMap=workspace:FindFirstChild("GeneratedMap")
        if previous then previous.Parent=nil end
        if previousMap then previousMap.Parent=nil end
        local arena=MapBuilder.buildArena(Config,"Harbor",ArenaVariants,VisualTheme)
        local holder=Instance.new("Folder")
        holder.Name="ApprovedFloorReliefTemplates"
        holder:SetAttribute("OwnerVerified",true)
        holder.Parent=storage
        local source=Instance.new("Model")
        source.Name="Harbor"
        source:SetAttribute("Original3DAssetId",94830155055482)
        source:SetAttribute("OriginalFloorRelief3D",true)
        source:SetAttribute("OwnerVerified",true)
        source:SetAttribute("CosmeticOnly",true)
        for i=1,7 do
            local mesh=Instance.new("MeshPart")
            mesh.Size=i==1 and Vector3.new(2.74,.32,7.55) or Vector3.one*.2
            mesh.Anchored=true
            mesh.CanCollide=false
            mesh.CanTouch=false
            mesh.CanQuery=false
            mesh.Parent=source
        end
        source.Parent=holder
        local owner=Instance.new("Folder")
        owner.Parent=arena
        local disconnect
        local running=false
        local cleanup={}
        local ok,why=pcall(function()
            local theme=VisualTheme.arena("Harbor")
            local decks=arena.Platforms:GetChildren()
            local function build(deck,tier)
                return Finish.buildServiceHatch(owner,deck,"Harbor",tier,theme,
                    tonumber(deck.Name:match("%d+")),true)
            end
            local count=0
            for _,deck in ipairs(decks) do
                if deck:IsA("BasePart") and Rules.isHarborLanding(deck) then
                    local pieces=build(deck,"Low")
                    assert(#pieces==7 and pieces[1]:GetAttribute("OriginalHarborCargoTieDown3D")==true)
                    local highest=-math.huge
                    for _,part in ipairs(pieces) do
                        local p=part.ChaosPlatformTrimWeld.C1.Position
                        highest=math.max(highest,p.Y+part.Size.Y*.5)
                        assert(not part.CanCollide and not part.CanTouch and not part.CanQuery)
                        assert(math.abs(p.X)+math.max(part.Size.X,part.Size.Z)*.5 < deck.Size.X*.5)
                        assert(math.abs(p.Z)+math.min(part.Size.X,part.Size.Z)*.5 < deck.Size.Z*.5)
                    end
                    assert(math.abs(highest-(deck.Size.Y*.5+.174))<.01)
                    local band=Finish.build(owner,deck,"Harbor","Medium",theme)[2]
                    local bandOffset=band.ChaosPlatformTrimWeld.C1.Position.Z
                    local bakedOffset=pieces[1].ChaosPlatformTrimWeld.C1.Position.Z
                    assert(math.abs(bandOffset-bakedOffset)<.01)
                    count+=1
                    owner:ClearAllChildren()
                end
            end
            expect(count).toBe(58)
            local deck=arena.Platforms.Platform96
            assert(deck:GetAttribute("HarborSpokeStep")==2)
            local selected=Finish.selectOriginalServiceHatches(decks,"Harbor","Low",
                arena.Base,deck.Position,nil,0)
            assert(selected[deck] and #build(deck,"Low")==7)
            assert(next(Finish.selectOriginalServiceHatches(decks,"Harbor","Low",
                arena.Base,deck.Position,nil,1))==nil)
            assert(#Finish.buildServiceHatch(owner,deck,"Harbor","High",theme,1,false)==0)
            local original=owner:GetChildren()
            local function largest(pieces)
                local result=pieces[1]
                for _,part in ipairs(pieces) do
                    if part.Size.Magnitude>result.Size.Magnitude then result=part end
                end
                return result
            end
            local shape=largest(original)
            local snapshot=Finish.captureRouteFootprint(deck,original)
            local originalSize=shape.Size
            running=true
            ShrinkingArena.start({Config=Config,RoundSeconds=.12,
                Active=function() return running end,OnCleanup=cleanup})
            local deadline=os.clock()+1.5
            repeat task.wait() until arena.Base.Size.X<=144.05 or os.clock()>deadline
            running=false
            task.wait()
            assert(arena.Base.Size.X<=144.05)
            Finish.applyRouteFootprint(snapshot)
            assert(math.abs(shape.Size.X-originalSize.X*.45)<.02 and shape.Size.Y==originalSize.Y)
            local finalSize=shape.Size
            owner:ClearAllChildren()
            local late=build(deck,"Medium")
            assert(#late==7 and late[1]:GetAttribute("OriginalHarborCargoTieDown3D"))
            assert((largest(late).Size-finalSize).Magnitude<.03)
            assert(next(Finish.selectOriginalServiceHatches(decks,"Harbor","Medium",
                arena.Base,deck.Position,nil,0))~=nil)
            local fallback=Finish.build(owner,deck,"Harbor","Medium",theme)[2]
            local alpha=fallback.Transparency
            fallback.Transparency=1
            fallback:SetAttribute("ChaosBaseTransparency",1)
            disconnect=Outpost.bindWeldedReplacement(deck,late,{[fallback]=alpha})
            late[1].ChaosPlatformTrimWeld:Destroy()
            task.wait()
            assert(math.abs(fallback.Transparency-alpha)<.01 and late[2].Transparency==1)
            source:GetChildren()[1]:Destroy()
            assert(#build(deck,"Medium")==0 and fallback.Transparency<1)
            assert(deck.CanCollide and arena.Decor.PlatformPanel96.Transparency<1)
        end)
        running=false
        if disconnect then disconnect() end
        for _,stop in ipairs(cleanup) do stop() end
        arena.Parent:Destroy()
        holder:Destroy()
        if previous then previous.Parent=storage end
        if previousMap then previousMap.Parent=workspace end
        if not ok then error(why) end
    end)

    it("replaces the five native pieces under a real Storm Harbor freight landing",function()
        local Dock=require("../../src/client/HarborDockCaissonMeshKit")
        local storage=game:GetService("ReplicatedStorage")
        local previous=storage:FindFirstChild("ApprovedHarborDockCaissonTemplates")
        local previousMap=workspace:FindFirstChild("GeneratedMap")
        if previous then previous.Parent=nil end
        if previousMap then previousMap.Parent=nil end
        local arena=MapBuilder.buildArena(Config,"Harbor",ArenaVariants,VisualTheme)
        local folder=Instance.new("Folder")
        folder.Name="ApprovedHarborDockCaissonTemplates"
        folder:SetAttribute("OwnerVerified",true)
        folder.Parent=storage
        local source=Instance.new("Model")
        source.Name="DockCaisson"
        source:SetAttribute("OwnerVerified",true)
        source:SetAttribute("CosmeticOnly",true)
        source:SetAttribute("OriginalHarborDockCaisson3D",true)
        source:SetAttribute("Original3DAssetId",101457508594609)
        for i=1,7 do
            local piece=Instance.new("MeshPart")
            piece.Size=i==1 and Vector3.new(14.07,3.30755,14.07) or Vector3.one*.2
            piece.Anchored=true
            piece.CanCollide=false
            piece.CanTouch=false
            piece.CanQuery=false
            piece.Parent=source
        end
        source.Parent=folder
        local running=false
        local cleanup={}
        local ok,why=pcall(function()
            local n=0
            for _,deck in ipairs(arena.Platforms:GetChildren()) do
                if deck:GetAttribute("HarborRoute") or deck:GetAttribute("HarborSpokeRoute")
                    or deck:GetAttribute("HarborSkywayStep") then
                    Dock.sync(nil,Vector3.zero,"Low",false,nil,0)
                    Dock.sync(arena,deck.Position,"Low",true,nil,0)
                    assert(deck:GetAttribute("LocalOriginalHarborDockCaissonMounted")==true,deck.Name)
                    local models,parts,replaced=Dock.count()
                    assert(models==1 and parts==7 and replaced==5)
                    n+=1
                end
            end
            expect(n).toBe(58)
            local deck
            for _,part in ipairs(arena.Platforms:GetChildren()) do
                if part:GetAttribute("HarborSkywayStep")==4 then deck=part;break end
            end
            assert(deck)
            local id=assert(deck.Name:match("^Platform(%d+)$"))
            local edge=arena.Decor["PlatformBevel"..id.."_1"]
            local frame=arena.Decor["PlatformUnderFrame"..id]
            local panel=arena.Decor["PlatformPanel"..id]
            Dock.sync(nil,Vector3.zero,"Low",false,nil,0)
            edge.LocalTransparencyModifier=.2
            Dock.sync(arena,deck.Position,"Low",true,nil,0)
            assert(edge.LocalTransparencyModifier==1 and frame.LocalTransparencyModifier==1)
            assert(panel.LocalTransparencyModifier==0 and deck.CanCollide)
            local models=workspace.OriginalHarborDockCaissonsLocal
            local resident=models:FindFirstChildWhichIsA("Model")
            local _,initial=resident:GetBoundingBox()
            deck:SetAttribute("CollapsePhase","Warning")
            task.wait()
            assert(math.abs(edge.LocalTransparencyModifier-.2)<.001)
            assert(frame.LocalTransparencyModifier==0 and Dock.count()==0)
            deck:SetAttribute("CollapsePhase","Safe")
            task.wait()
            running=true
            ShrinkingArena.start({Config=Config,RoundSeconds=.12,
                Active=function() return running end,OnCleanup=cleanup})
            local deadline=os.clock()+1.5
            repeat task.wait() until arena.Base.Size.X<=144.05 or os.clock()>deadline
            running=false
            task.wait()
            assert(arena.Base.Size.X<=144.05 and edge.LocalTransparencyModifier==1)
            local _,final=resident:GetBoundingBox()
            assert(math.abs(initial.Y-final.Y)<.03 and math.abs(initial.X*.45-final.X)<.03)
            Dock.sync(nil,Vector3.zero,"Low",false,nil,0)
            Dock.sync(arena,deck.Position,"Low",true,nil,0)
            local late=models:FindFirstChildWhichIsA("Model")
            local _,lateSize=late:GetBoundingBox()
            assert((lateSize-final).Magnitude<.08)
            local mesh=late:FindFirstChildWhichIsA("MeshPart")
            mesh:FindFirstChild("HarborDockCosmeticWeld"):Destroy()
            task.wait()
            assert(Dock.count()==0 and math.abs(edge.LocalTransparencyModifier-.2)<.001)
            Dock.sync(arena,deck.Position,"Low",true,nil,0)
            assert(Dock.count()==1)
            Dock.sync(arena,deck.Position,"Low",true,nil,1)
            assert(Dock.count()==0 and frame.LocalTransparencyModifier==0 and deck.CanCollide)
        end)
        running=false
        Dock.sync(nil,Vector3.zero,"Low",false,nil,0)
        for _,stop in ipairs(cleanup) do stop() end
        arena.Parent:Destroy()
        folder:Destroy()
        if previous then previous.Parent=storage end
        if previousMap then previousMap.Parent=workspace end
        if not ok then error(why) end
    end)

end)

return nil
