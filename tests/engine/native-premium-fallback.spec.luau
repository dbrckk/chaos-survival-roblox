--!strict
-- Real Roblox Instance / Weld ownership regression for original 3D art.
-- Fixture MeshParts are intentionally local stand-ins; source provenance is
-- checked in the existing creator-owned asset pipeline before installation.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Kit = require("../../src/client/PlatformNativeTrimReplacementKit")
local ApprovedDistrictSidewallMeshKit = require("../../src/client/ApprovedDistrictSidewallMeshKit")
local PremiumDistrictFacadeMeshKit = require("../../src/client/PremiumDistrictFacadeMeshKit")
local PremiumDistrictFacadeMeshKit = require("../../src/client/PremiumDistrictFacadeMeshKit")
local DistrictVisualCensusRules = require("../../src/shared/DistrictVisualCensusRules")
local PremiumPlatformSideMeshKit = require("../../src/client/PremiumPlatformSideMeshKit")
local PremiumLargeStructureMeshKit = require("../../src/client/PremiumLargeStructureMeshKit")
local RemainingStructureKit = require("../../src/client/ApprovedRemainingStructureMeshKit")
local RemainingStructureAssets = require("../../src/server/PremiumRemainingStructureAssets")
local HarborScenery = require("../../src/server/HarborScenery")
local VisualTheme = require("../../src/shared/VisualTheme")
local HarborFreighterMeshKit = require("../../src/client/HarborFreighterMeshKit")
local HarborHeroStationMeshKit = require("../../src/client/HarborHeroStationMeshKit")
local HarborMidgroundBargeMeshKit = require("../../src/client/HarborMidgroundBargeMeshKit")
local HarborSignatureGantryKit = require("../../src/client/ApprovedHarborSignatureGantryMeshKit")
local SouthHarborDrydockKit = require("../../src/client/ApprovedSouthHarborDrydockMeshKit")
local ExteriorRidgeKit = require("../../src/client/ApprovedExteriorRidgeMeshKit")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local Config = require("../../src/shared/Config")

describe("Original 3D native fallback isolation (engine)", function()
    it("drops genuine district facade and restores native roof under Android pressure", function()
        local ReplicatedStorage=game:GetService("ReplicatedStorage")
        local previousMap=workspace:FindFirstChild("GeneratedMap")
        local previousTemplates=ReplicatedStorage:FindFirstChild(
            "ApprovedDistrictFacadeTemplates")
        if previousMap then previousMap.Parent=nil end
        if previousTemplates then previousTemplates.Parent=nil end
        PremiumDistrictFacadeMeshKit.sync(
            nil,Vector3.zero,"Low",false)
        local generated,templates
        local ok,why=pcall(function()
            -- These are the SAME budgets as the six-source approved
            -- sidewall kit, with no new Android MeshParts or API calls.
            expect(PremiumDistrictFacadeMeshKit.residentBudget(
                "Low",true,0)).toBe(1)
            expect(PremiumDistrictFacadeMeshKit.residentBudget(
                "Low",true,1)).toBe(0)
            expect(PremiumDistrictFacadeMeshKit.residentBudget(
                "Medium",true,0)).toBe(3)
            expect(PremiumDistrictFacadeMeshKit.residentBudget(
                "Medium",true,1)).toBe(1)
            expect(PremiumDistrictFacadeMeshKit.residentBudget(
                "High",true,0)).toBe(8)
            expect(PremiumDistrictFacadeMeshKit.residentBudget(
                "High",true,1)).toBe(4)
            expect(PremiumDistrictFacadeMeshKit.residentBudget(
                "High",true,2)).toBe(0)
            expect(PremiumDistrictFacadeMeshKit.residentBudget(
                "Medium",false,0)).toBe(8)
            expect(PremiumDistrictFacadeMeshKit.residentBudget(
                "High",false,0)).toBe(16)
            expect(PremiumDistrictFacadeMeshKit.residentBudget(
                "High",false,1)).toBe(6)

            local arena=MapBuilder.buildArena(Config,"Classic",
                ArenaVariants,VisualTheme)
            generated=arena.Parent
            local base=arena:FindFirstChild("Base")
            local decor=arena:FindFirstChild("Decor")
            local district=decor:FindFirstChild(
                "ArenaDistrictArchitecture3D")
            local building=district:FindFirstChild("DistrictNorth1")
            local door=building:FindFirstChild("ServiceEntryDoor")
            local roof=building:FindFirstChild("AngledRoofL")
            expect(roof~=nil and roof:IsA("WedgePart")).toBe(true)
            expect(roof.CanCollide or roof.CanTouch or roof.CanQuery)
                .toBe(false)
            local originalAlpha=roof.Transparency
            templates=Instance.new("Folder")
            templates.Name="ApprovedDistrictFacadeTemplates"
            templates:SetAttribute("OwnerVerified",true)
            templates.Parent=ReplicatedStorage
            local source=Instance.new("Model")
            source.Name="Observatory"
            source:SetAttribute("OwnerVerified",true)
            source:SetAttribute("CosmeticOnly",true)
            source:SetAttribute("DistrictFacade3D",true)
            source:SetAttribute("Original3DAssetId",132020956214241)
            local mesh=Instance.new("MeshPart")
            mesh.Size=Vector3.new(12,20,8)
            mesh.Anchored=true
            mesh.CanCollide=false
            mesh.CanTouch=false
            mesh.CanQuery=false
            mesh.Parent=source
            source.Parent=templates
            local position=door.Position+Vector3.new(0,5,0)
            local look=door.CFrame.LookVector

            PremiumDistrictFacadeMeshKit.sync(
                arena,position,"Low",true,look,true,0)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(1)
            expect(building:GetAttribute(
                "LocalApprovedDistrictFacadeMounted")).toBe(true)
            expect(roof.Transparency).toBe(1)
            expect(base.CanCollide).toBe(true)

            -- Critical Low phone pressure: release approved 3D and
            -- restore its exact native WedgePart IMMEDIATELY.
            PremiumDistrictFacadeMeshKit.sync(
                arena,position,"Low",true,look,true,1)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(0)
            expect(building:GetAttribute(
                "LocalApprovedDistrictFacadeMounted")).toBe(nil)
            expect(roof.Transparency).toBe(originalAlpha)
            expect(base.CanCollide).toBe(true)

            PremiumDistrictFacadeMeshKit.sync(
                arena,position,"Low",true,look,true,0)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(1)
            expect(roof.Transparency).toBe(1)
            -- A source that loses its owner's approval must not retain
            -- an invisible native roof until the next camera sample.
            source:SetAttribute("OwnerVerified",false)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(0)
            expect(roof.Transparency).toBe(originalAlpha)
            expect(base.CanCollide).toBe(true)
            source:SetAttribute("OwnerVerified",true)
            PremiumDistrictFacadeMeshKit.sync(
                arena,position,"Low",true,look,true,0)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(1)
            expect(roof.Transparency).toBe(1)
            -- An unexpected source Part immediately revokes the original
            -- package; it must never be accepted as extra genuine 3D.
            local injected=Instance.new("Part")
            injected.Name="UnapprovedSourcePart"
            injected.Parent=source
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(0)
            expect(roof.Transparency).toBe(originalAlpha)
            injected:Destroy()
            PremiumDistrictFacadeMeshKit.sync(
                arena,position,"Low",true,look,true,0)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(1)
            expect(roof.Transparency).toBe(1)
            -- Severe pressure also evicts even the permitted Medium
            -- front; it cannot remain orphaned while sidewalls fall back.
            PremiumDistrictFacadeMeshKit.sync(
                arena,position,"Medium",true,look,true,2)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(0)
            expect(roof.Transparency).toBe(originalAlpha)
            expect(base.CanCollide).toBe(true)
        end)
        PremiumDistrictFacadeMeshKit.sync(
            nil,Vector3.zero,"Low",false)
        if templates then templates:Destroy() end
        if generated then generated:Destroy() end
        if previousTemplates then
            previousTemplates.Parent=ReplicatedStorage
        end
        if previousMap then previousMap.Parent=workspace end
        if not ok then error(why) end
    end)

    it("completes existing approved 3D district shells symmetrically with a true streamed 16-slot census", function()
        -- Low never receives a reciprocal boost: its one sidewall must
        -- FIRST have a true mounted facade. Medium/High can use a small
        -- verified sidewall boost to complete an otherwise split building.
        expect(PremiumDistrictFacadeMeshKit.pairedPriority(
            100, true, "Low")).toBe(100)
        expect(PremiumDistrictFacadeMeshKit.pairedPriority(
            100, false, "Medium")).toBe(100)
        expect(PremiumDistrictFacadeMeshKit.pairedPriority(
            100, true, "Medium")).toBe(88)
        expect(PremiumDistrictFacadeMeshKit.pairedPriority(
            100, true, "High")).toBe(88)
        expect(PremiumDistrictFacadeMeshKit.pairedPriority(
            112, true, "High") < PremiumDistrictFacadeMeshKit
                .pairedPriority(101, false, "High")).toBe(true)
        expect(PremiumDistrictFacadeMeshKit.pairedPriority(
            130, true, "High") > PremiumDistrictFacadeMeshKit
                .pairedPriority(100, false, "High")).toBe(true)

        local b1=bit32.lshift(1,0)
        local b2=bit32.lshift(1,1)
        local b3=bit32.lshift(1,2)
        local b4=bit32.lshift(1,3)
        local b16=bit32.lshift(1,15)
        local b8=bit32.lshift(1,7)
        local loaded=bit32.bor(b1,b2,b3,b4,b16)
        -- Source models outside streamed buildings do not count. No
        -- native-only building may be counted as a genuine replacement.
        local census=DistrictVisualCensusRules.summarize(
            loaded,bit32.bor(b1,b2,b8),bit32.bor(b2,b3,b8))
        expect(census.states:sub(1,4)).toBe("FBSN")
        expect(census.states:sub(5,15)).toBe(string.rep("-",11))
        expect(census.states:sub(16,16)).toBe("N")
        expect(census.loaded).toBe(5)
        expect(census.unstreamed).toBe(11)
        expect(census.complete).toBe(1)
        expect(census.facadeOnly).toBe(1)
        expect(census.sidewallOnly).toBe(1)
        expect(census.nativeOnly).toBe(2)
        local all=DistrictVisualCensusRules.summarize(65535,65535,65535)
        expect(all.complete).toBe(16)
        expect(all.nativeOnly).toBe(0)
        expect(all.unstreamed).toBe(0)
        expect(all.states).toBe(string.rep("B",16))
        local absent=DistrictVisualCensusRules.summarize(0,65535,65535)
        expect(absent.loaded).toBe(0)
        expect(absent.unstreamed).toBe(16)
        expect(absent.complete).toBe(0)
        expect(absent.states).toBe(string.rep("-",16))
    end)

    it("prioritizes genuinely paired Medium/High district shells without changing GPU caps", function()
        -- Both legitimate LOD rankers compare an owner-verified front and
        -- side/back shell on the SAME real server-authored building. At
        -- most 16 studs of priority, never overriding an offscreen 80.
        expect(ApprovedDistrictSidewallMeshKit.pairedPriority(
            100,true,"Medium")).toBe(84)
        expect(ApprovedDistrictSidewallMeshKit.pairedPriority(
            100,true,"High")).toBe(84)
        expect(ApprovedDistrictSidewallMeshKit.pairedPriority(
            100,true,"Low")).toBe(100)
        expect(ApprovedDistrictSidewallMeshKit.pairedPriority(
            100,false,"Medium")).toBe(100)
        expect(ApprovedDistrictSidewallMeshKit.pairedPriority(
            100,false,"High")).toBe(100)
        -- A building 12 studs further away but genuinely complete takes
        -- the sidewall slot from a partly primitive nearby facade.
        expect(ApprovedDistrictSidewallMeshKit.pairedPriority(
            112,true,"Medium") < ApprovedDistrictSidewallMeshKit
                .pairedPriority(100,false,"Medium")).toBe(true)
        -- An actual 25-stud gap still wins in favor of the nearer native.
        expect(ApprovedDistrictSidewallMeshKit.pairedPriority(
            126,true,"Medium") > ApprovedDistrictSidewallMeshKit
                .pairedPriority(100,false,"Medium")).toBe(true)
        -- Hidden or distant behind-camera buildings still lose decisively.
        expect(ApprovedDistrictSidewallMeshKit.pairedPriority(
            180,true,"High") > ApprovedDistrictSidewallMeshKit
                .pairedPriority(100,false,"High")).toBe(true)
    end)

    it("selects only genuinely fitting 22-stud cradles and unmasks real underframes", function()
        Kit.reset()
        local previous=workspace:FindFirstChild("GeneratedMap")
        if previous then previous.Parent=nil end
        local generated,templates,meshes
        local ok,reason=pcall(function()
            local arena=MapBuilder.buildArena(Config,"Crossroads",
                ArenaVariants,VisualTheme)
            generated=arena.Parent
            local platforms=arena:FindFirstChild("Platforms")
            local decor=arena:FindFirstChild("Decor")
            local base=arena:FindFirstChild("Base")
            -- These bounds match the existing approved LongCradle model
            -- (128914328933863), but the fixture has no external assets.
            local sourceBounds=Vector3.new(22.6,3.0,9.8)
            expect(PremiumLargeStructureMeshKit.cradleFit(
                Vector3.new(34,2,12),sourceBounds)).toBe(nil)
            expect(PremiumLargeStructureMeshKit.cradleFit(
                Vector3.new(24,2,12),sourceBounds)~=nil).toBe(true)
            expect(PremiumLargeStructureMeshKit.cradleFit(
                Vector3.new(12,2,12),sourceBounds)).toBe(nil)

            templates=Instance.new("Folder")
            templates.Name="ApprovedLargeStructureTemplates"
            templates:SetAttribute("OwnerVerified",true)
            templates.Parent=game:GetService("ReplicatedStorage")
            local source=Instance.new("Model")
            source.Name="LongCradle"
            source:SetAttribute("Original3DAssetId",128914328933863)
            source:SetAttribute("OwnerVerified",true)
            source:SetAttribute("CosmeticOnly",true)
            source:SetAttribute("OriginalLargeStructure3D",true)
            for i=1,7 do
                local material=Instance.new("MeshPart")
                material.Name="CradleMaterial"..i
                material.Size=if i==1 then sourceBounds
                    else Vector3.new(.3,.3,.3)
                material.Anchored=true
                material.CanCollide=false
                material.CanTouch=false
                material.CanQuery=false
                material.Parent=source
            end
            source.Parent=templates

            local ordered={}
            for _,part in ipairs(platforms:GetChildren()) do
                if part:IsA("BasePart")
                    and part.Name:match("^Platform%d+$") then
                    ordered[#ordered+1]=part
                end
            end
            local camera=platforms:FindFirstChild("Platform2").Position
            local selected=PremiumLargeStructureMeshKit
                .selectNearRouteStructures(ordered,decor,"Crossroads",
                    "Medium",base,camera,Vector3.new(0,0,1),0)
            local count,owner=0,nil
            for part in pairs(selected) do
                count+=1
                local id=part.Name:match("^Platform(%d+)$")
                expect(id~=nil).toBe(true)
                expect(part.CanCollide and part.Anchored).toBe(true)
                expect(part:GetAttribute("PromenadeStep")~=nil
                    or part:GetAttribute("SkySpineStep")~=nil).toBe(true)
                expect(PremiumLargeStructureMeshKit.cradleFit(
                    part.Size,sourceBounds)~=nil).toBe(true)
                local native=decor:FindFirstChild("PlatformUnderFrame"..id)
                expect(native~=nil).toBe(true)
                expect(native.CanCollide or native.CanTouch or native.CanQuery)
                    .toBe(false)
                owner=part
            end
            expect(count).toBe(2)
            -- On the same REAL MapBuilder route inventory, High Android
            -- retains four fully source-fitted 22-stud cradles; High
            -- desktop reuses four existing column slots to mount EIGHT.
            -- Both keep 20 seven-MeshPart structure modules in total.
            local mobileCradles=PremiumLargeStructureMeshKit
                .selectNearRouteStructures(ordered,decor,"Crossroads",
                    "High",base,camera,Vector3.new(0,0,1),0,false)
            local desktopCradles=PremiumLargeStructureMeshKit
                .selectNearRouteStructures(ordered,decor,"Crossroads",
                    "High",base,camera,Vector3.new(0,0,1),0,true)
            local mobileCount,desktopCount=0,0
            for part in pairs(mobileCradles) do
                mobileCount+=1
                expect(PremiumLargeStructureMeshKit.cradleFit(
                    part.Size,sourceBounds)~=nil).toBe(true)
            end
            for part in pairs(desktopCradles) do
                desktopCount+=1
                expect(part:IsA("BasePart") and part.CanCollide).toBe(true)
                expect(PremiumLargeStructureMeshKit.cradleFit(
                    part.Size,sourceBounds)~=nil).toBe(true)
                expect(decor:FindFirstChild("PlatformUnderFrame"
                    ..part.Name:match("^Platform(%d+)$"))~=nil).toBe(true)
            end
            expect(mobileCount).toBe(4)
            expect(desktopCount).toBe(8)
            local moved=PremiumLargeStructureMeshKit.desktopCradleTransfer(
                "High",true,desktopCradles)
            expect(moved).toBe(4)
            expect(4+moved+16-moved).toBe(20)
            expect(PremiumLargeStructureMeshKit.desktopCradleTransfer(
                "High",false,desktopCradles)).toBe(0)
            expect(PremiumLargeStructureMeshKit.desktopCradleTransfer(
                "Medium",true,desktopCradles)).toBe(0)
            expect(PremiumLargeStructureMeshKit.desktopCradleTransfer(
                "High",true,mobileCradles)).toBe(0)
            expect(owner~=nil).toBe(true)
            local id=tonumber(owner.Name:match("^Platform(%d+)$"))
            local underframe=decor:FindFirstChild("PlatformUnderFrame"..id)
            expect(underframe:GetAttribute("PremiumArchitecturalSurface"))
                .toBe(true)
            meshes=Instance.new("Folder")
            meshes.Name="OriginalLongCradleUnderframeFixture"
            meshes.Parent=workspace
            local sculpt=PremiumLargeStructureMeshKit.longCradle(
                meshes,owner,"Medium",id,true)
            expect(sculpt~=nil and #sculpt==7).toBe(true)
            for _,mesh in ipairs(sculpt) do
                expect(mesh:IsA("MeshPart")).toBe(true)
                expect(mesh.CanCollide or mesh.CanTouch or mesh.CanQuery)
                    .toBe(false)
                expect(mesh:GetAttribute("OriginalLongCradle3D")).toBe(true)
            end
            Kit.bind(arena,{[tostring(id)]="cradle"},nil,nil,meshes)
            expect(underframe.LocalTransparencyModifier).toBe(1)
            expect(owner.CanCollide).toBe(true)
            owner:SetAttribute("CollapsePhase","Warning")
            expect(underframe.LocalTransparencyModifier).toBe(0)
            owner:SetAttribute("CollapsePhase","Normal")
            expect(underframe.LocalTransparencyModifier).toBe(1)
            for _,mesh in ipairs(sculpt) do mesh:Destroy() end
            expect(underframe.LocalTransparencyModifier).toBe(0)
            expect(owner.CanCollide).toBe(true)

            -- Go beyond an abstract selection: actually mount EIGHT
            -- individually authored, seven-MeshPart High source fixtures
            -- on EIGHT real Crossroads promenade collider owners.
            -- Reuse the same physical MapBuilder Parts, no mock platforms.
            Kit.reset()
            local highParts={}
            local highReplacements={}
            local installed=0
            local firstOwner=nil
            for deck in pairs(desktopCradles) do
                local n=tonumber(deck.Name:match("^Platform(%d+)$"))
                local genuine=PremiumLargeStructureMeshKit.longCradle(
                    meshes,deck,"High",n,true)
                expect(genuine~=nil and #genuine==7).toBe(true)
                installed+=1
                highParts[deck]=genuine
                highReplacements[tostring(n)]="cradle"
                if firstOwner==nil then firstOwner=deck end
                expect(deck.CanCollide).toBe(true)
            end
            expect(installed).toBe(8)
            expect(#meshes:GetChildren()).toBe(56)
            Kit.bind(arena,highReplacements,nil,nil,meshes)
            local masked=0
            for deck in pairs(desktopCradles) do
                local n=tonumber(deck.Name:match("^Platform(%d+)$"))
                local native=decor:FindFirstChild("PlatformUnderFrame"..n)
                expect(native.LocalTransparencyModifier).toBe(1)
                masked+=1
            end
            expect(masked).toBe(8)
            -- Warning on ONE real deck restores only its own fallback.
            local firstId=tonumber(firstOwner.Name:match("^Platform(%d+)$"))
            local firstFrame=decor:FindFirstChild(
                "PlatformUnderFrame"..firstId)
            firstOwner:SetAttribute("CollapsePhase","Warning")
            expect(firstFrame.LocalTransparencyModifier).toBe(0)
            for deck in pairs(desktopCradles) do
                if deck~=firstOwner then
                    local n=tonumber(deck.Name:match("^Platform(%d+)$"))
                    expect(decor:FindFirstChild(
                        "PlatformUnderFrame"..n).LocalTransparencyModifier)
                        .toBe(1)
                end
            end
            firstOwner:SetAttribute("CollapsePhase","Normal")
            expect(firstFrame.LocalTransparencyModifier).toBe(1)
            for _,piece in ipairs(highParts[firstOwner]) do
                piece:Destroy()
            end
            expect(firstFrame.LocalTransparencyModifier).toBe(0)
            for deck in pairs(desktopCradles) do
                if deck~=firstOwner then
                    local n=tonumber(deck.Name:match("^Platform(%d+)$"))
                    expect(decor:FindFirstChild(
                        "PlatformUnderFrame"..n).LocalTransparencyModifier)
                        .toBe(1)
                end
                expect(deck.CanCollide).toBe(true)
            end
            Kit.reset()
            for deck in pairs(desktopCradles) do
                local n=tonumber(deck.Name:match("^Platform(%d+)$"))
                expect(decor:FindFirstChild(
                    "PlatformUnderFrame"..n).LocalTransparencyModifier)
                    .toBe(0)
            end
        end)
        Kit.reset()
        if meshes then meshes:Destroy() end
        if templates then templates:Destroy() end
        if generated then generated:Destroy() end
        if previous then previous.Parent=workspace end
        if not ok then error(reason) end
    end)

    it("prefits approved support columns before spending limited Android and PC 3D slots", function()
        -- This exact source envelope belongs to the approved Crossroads
        -- seven-material original. Selection and final mounting must agree
        -- on both fit and how many modules each real pillar consumes.
        local bounds = Vector3.new(2.12, 14.1, 2.12)
        local fitLow, scaleLow = PremiumLargeStructureMeshKit.supportFit(
            Vector3.new(1.3, 4.85, 1.3), bounds)
        expect(fitLow).toBe(1)
        expect(scaleLow >= .34 and scaleLow <= 1.25).toBe(true)
        local fitMedium = PremiumLargeStructureMeshKit.supportFit(
            Vector3.new(1.3, 28, 1.3), bounds)
        expect(fitMedium).toBe(2)
        local fitHigh = PremiumLargeStructureMeshKit.supportFit(
            Vector3.new(1.3, 46, 1.3), bounds)
        expect(fitHigh).toBe(3)
        -- An ultra-thin but correctly named native, or a source that
        -- would require over-expansion, cannot reserve any mesh slot.
        expect(PremiumLargeStructureMeshKit.supportFit(
            Vector3.new(.25, 30, .25), bounds)).toBe(nil)
        expect(PremiumLargeStructureMeshKit.supportFit(
            Vector3.new(1.3, 4.0, 1.3), bounds)).toBe(nil)
        expect(PremiumLargeStructureMeshKit.supportFit(
            Vector3.new(1.3, 47.1, 1.3), bounds)).toBe(nil)
        expect(PremiumLargeStructureMeshKit.supportFit(
            Vector3.new(1.3, 28, 1.3), Vector3.new(2, 0, 2)))
            .toBe(nil)
        expect(PremiumLargeStructureMeshKit.supportFit(
            nil, bounds)).toBe(nil)
    end)

    it("replaces a real 4.85-stud Crossroads near support on Low with native recovery", function()
        Kit.reset()
        local previous=workspace:FindFirstChild("GeneratedMap")
        if previous then previous.Parent=nil end
        local generated,templates,meshes
        local result,err=pcall(function()
            -- The real MapBuilder produces a 4.85-stud source support under
            -- Platform2 (7-stud deck centre - 1-stud half-height - 1.15).
            -- No fabricated Roblox native pillars are used for this test.
            local arena=MapBuilder.buildArena(Config,"Crossroads",
                ArenaVariants,VisualTheme)
            generated=arena.Parent
            local base=arena:FindFirstChild("Base")
            local decor=arena:FindFirstChild("Decor")
            local platforms=arena:FindFirstChild("Platforms")
            local platform=platforms:FindFirstChild("Platform2")
            local native=decor:FindFirstChild("PlatformSupport2_1")
            expect(platform~=nil and native~=nil).toBe(true)
            expect(platform.Anchored and platform.CanCollide).toBe(true)
            expect(native.Anchored and not native.CanCollide
                and not native.CanTouch and not native.CanQuery).toBe(true)
            expect(math.abs(native.Size.Y-4.85)<.001).toBe(true)
            -- Exhaustive count for this exact Crossroads family: each
            -- of four first elevated decks owns four real 4.85-stud
            -- supports. Source eligibility is not sixteen simultaneous
            -- client MeshParts, nor permission to erase their native art.
            local eligibleNativeCount=0
            for _,route in ipairs({2,4,6,8}) do
                local owner=platforms:FindFirstChild("Platform"..route)
                expect(owner~=nil and owner.CanCollide).toBe(true)
                for corner=1,4 do
                    local post=decor:FindFirstChild(
                        "PlatformSupport"..route.."_"..corner)
                    expect(post~=nil and post.Anchored
                        and not post.CanCollide and not post.CanQuery
                        and not post.CanTouch).toBe(true)
                    expect(math.abs(post.Size.Y-4.85)<.001).toBe(true)
                    eligibleNativeCount+=1
                end
            end
            expect(eligibleNativeCount).toBe(16)

            templates=Instance.new("Folder")
            templates.Name="ApprovedLargeStructureTemplates"
            templates:SetAttribute("OwnerVerified",true)
            templates.Parent=game:GetService("ReplicatedStorage")
            local source=Instance.new("Model")
            source.Name="Crossroads"
            source:SetAttribute("Original3DAssetId",93993697329658)
            source:SetAttribute("OwnerVerified",true)
            source:SetAttribute("CosmeticOnly",true)
            source:SetAttribute("OriginalLargeStructure3D",true)
            for i=1,7 do
                local mesh=Instance.new("MeshPart")
                mesh.Name="OriginalColumnMaterial"..i
                mesh.Size=if i==1 then Vector3.new(2.12,14.1,2.12)
                    else Vector3.new(.3,.3,.3)
                mesh.Anchored=true
                mesh.CanCollide=false
                mesh.CanTouch=false
                mesh.CanQuery=false
                mesh.Parent=source
            end
            source.Parent=templates
            -- An authentic long lattice ALSO exists: the old Low selector
            -- always chose it, including when it was ~100 studs away from
            -- this immediately visible native pillar. Both fixture models
            -- have the exact approved IDs and permitted bounding boxes.
            local lattice=Instance.new("Model")
            lattice.Name="LongCradle"
            lattice:SetAttribute("Original3DAssetId",128914328933863)
            lattice:SetAttribute("OwnerVerified",true)
            lattice:SetAttribute("CosmeticOnly",true)
            lattice:SetAttribute("OriginalLargeStructure3D",true)
            for i=1,7 do
                local mesh=Instance.new("MeshPart")
                mesh.Name="OriginalLatticeMaterial"..i
                mesh.Size=if i==1 then Vector3.new(22.6,3.0,9.8)
                    else Vector3.new(.25,.25,.25)
                mesh.Anchored=true
                mesh.CanCollide=false
                mesh.CanTouch=false
                mesh.CanQuery=false
                mesh.Parent=lattice
            end
            lattice.Parent=templates
            -- Medium already reserves EIGHT seven-piece support modules,
            -- but the old selector returned at most FOUR platform owners.
            -- Use the actual complete Crossroads MapBuilder geometry and
            -- genuine named server posts: no synthetic platforms/posts.
            local actualDecks={}
            for _,deck in ipairs(platforms:GetChildren()) do
                if deck:IsA("BasePart") and
                    deck.Name:match("^Platform%d+$") then
                    actualDecks[#actualDecks+1]=deck
                end
            end
            local _,mediumSupports=
                PremiumLargeStructureMeshKit.selectNearRouteStructures(
                    actualDecks,decor,"Crossroads","Medium",base,
                    platform.Position,Vector3.new(0,0,1),0)
            local selectedMedium=0
            for owner in pairs(mediumSupports) do
                selectedMedium+=1
                expect(owner.Anchored and owner.CanCollide).toBe(true)
                local id=owner.Name:match("^Platform(%d+)$")
                expect(id~=nil).toBe(true)
                local actualNative=false
                for _,post in ipairs(decor:GetChildren()) do
                    if post.Name:match("^PlatformSupport"..id.."_%d+$")
                        and post:IsA("BasePart") and post.Anchored
                        and not post.CanCollide then
                        actualNative=true
                        break
                    end
                end
                expect(actualNative).toBe(true)
            end
            expect(selectedMedium).toBe(8)
            local farCradle=nil
            local farDistance=math.huge
            for _,candidate in ipairs(platforms:GetChildren()) do
                if candidate:IsA("BasePart")
                    and (candidate:GetAttribute("PromenadeStep")~=nil
                        or candidate:GetAttribute("SkySpineStep")~=nil) then
                    local long=math.max(candidate.Size.X,candidate.Size.Z)
                    local short=math.min(candidate.Size.X,candidate.Size.Z)
                    local scale=math.min(1.21,long*.95/22.6,
                        short*.91/9.8)
                    local distance=(candidate.Position-platform.Position).Magnitude
                    if long>=19.5 and long<=34 and short>=9 and short<=18
                        and scale>=.76 and 22.6*scale>=long*.87
                        and 9.8*scale>=short*.76
                        and distance<=125 and distance<farDistance then
                        farCradle=candidate
                        farDistance=distance
                    end
                end
            end
            expect(farCradle~=nil).toBe(true)

            local camera=platform.Position
            local cradles,supports=
                PremiumLargeStructureMeshKit.selectNearRouteStructures(
                    {platform,farCradle},decor,"Crossroads","Low",base,
                    camera,Vector3.new(0,0,1),0)
            expect(supports[platform]).toBe(true)
            expect(cradles[farCradle]).toBe(nil)
            local nearestCradle,demotedSupport=
                PremiumLargeStructureMeshKit.selectNearRouteStructures(
                    {platform,farCradle},decor,"Crossroads","Low",base,
                    farCradle.Position,Vector3.new(0,0,1),0)
            expect(nearestCradle[farCradle]).toBe(true)
            expect(demotedSupport[platform]).toBe(nil)
            local _,pressured=
                PremiumLargeStructureMeshKit.selectNearRouteStructures(
                    {platform},decor,"Crossroads","Low",base,
                    camera,Vector3.new(0,0,1),1)
            expect(pressured[platform]).toBe(nil)
            local criticalCradles,criticalSupports=
                PremiumLargeStructureMeshKit.selectNearRouteStructures(
                    {platform,farCradle},decor,"Crossroads","Low",base,
                    camera,Vector3.new(0,0,1),2)
            expect(next(criticalCradles)).toBe(nil)
            expect(next(criticalSupports)).toBe(nil)
            meshes=Instance.new("Folder")
            meshes.Name="P0OriginalColumnLowFixture"
            meshes.Parent=workspace
            local mounted=PremiumLargeStructureMeshKit.supports(
                meshes,decor,platform,"Crossroads","Low",2,1,true)
            expect(mounted~=nil).toBe(true)
            expect(mounted.modules).toBe(1)
            expect(#mounted.parts).toBe(7)
            expect(#mounted.covered).toBe(1)
            expect(mounted.covered[1]).toBe(native)
            for _,part in ipairs(mounted.parts) do
                expect(part:IsA("MeshPart")).toBe(true)
                expect(part.CanCollide or part.CanTouch or part.CanQuery)
                    .toBe(false)
                expect(part:GetAttribute("OriginalSupportColumn3D"))
                    .toBe(true)
            end

            Kit.bind(arena,{},nil,mounted.covered,meshes)
            expect(Kit.count()).toBe(1)
            expect(native.LocalTransparencyModifier).toBe(1)
            -- A single 7-MeshPart Low mount hides ONE native post, not
            -- the other fifteen same-height posts or another deck.
            local maskedNativeCount=0
            for _,route in ipairs({2,4,6,8}) do
                for corner=1,4 do
                    local part=decor:FindFirstChild(
                        "PlatformSupport"..route.."_"..corner)
                    if part.LocalTransparencyModifier==1 then
                        maskedNativeCount+=1
                        expect(part).toBe(native)
                    else
                        expect(part.LocalTransparencyModifier).toBe(0)
                    end
                end
            end
            expect(maskedNativeCount).toBe(1)
            -- Collapse overrides any imported cosmetic; the real
            -- server-owned collidable deck never becomes intangible.
            platform:SetAttribute("CollapsePhase","Warning")
            expect(Kit.count()).toBe(0)
            expect(native.LocalTransparencyModifier).toBe(0)
            platform:SetAttribute("CollapsePhase","Normal")
            expect(Kit.count()).toBe(1)
            -- Streaming/destruction of the final source segment always
            -- unmasks the original anchored, nonphysical server support.
            for _,part in ipairs(mounted.parts) do part:Destroy() end
            expect(Kit.count()).toBe(0)
            expect(native.LocalTransparencyModifier).toBe(0)
            expect(platform.CanCollide).toBe(true)
            for _,conn in ipairs(mounted.disconnects) do
                conn:Disconnect()
            end
        end)
        Kit.reset()
        if meshes then meshes:Destroy() end
        if templates then templates:Destroy() end
        if generated then generated:Destroy() end
        if previous then previous.Parent=workspace end
        if not result then error(err) end
    end)

    it("spends the same one Low seven-mesh carapace on the real even-index Crossroads near deck", function()
        Kit.reset()
        local previous=workspace:FindFirstChild("GeneratedMap")
        if previous then previous.Parent=nil end
        local generated,templates,meshes
        local ok,failure=pcall(function()
            local arena=MapBuilder.buildArena(Config,"Crossroads",ArenaVariants,VisualTheme)
            generated=arena.Parent
            local base=arena:FindFirstChild("Base")
            local platforms=arena:FindFirstChild("Platforms")
            local decor=arena:FindFirstChild("Decor")
            local nearby=platforms:FindFirstChild("Platform2")
            local distant=platforms:FindFirstChild("Platform1")
            expect(nearby~=nil and distant~=nil).toBe(true)
            expect(nearby.CanCollide and nearby.Anchored).toBe(true)
            expect(nearby.Size).toBe(Vector3.new(14,2,12))
            -- The true MapBuilder has FOUR safe fallback bevels and
            -- one underframe for this already-existing even-index deck.
            local bevels={}
            for i=1,4 do
                local bevel=decor:FindFirstChild("PlatformBevel2_"..i)
                expect(bevel~=nil and bevel:IsA("WedgePart")).toBe(true)
                expect(bevel:GetAttribute("OriginalStructuralBevel")).toBe(true)
                expect(bevel.CanCollide or bevel.CanTouch or bevel.CanQuery)
                    .toBe(false)
                bevels[#bevels+1]=bevel
            end
            local underside=decor:FindFirstChild("PlatformUnderFrame2")
            expect(underside~=nil).toBe(true)
            expect(underside:GetAttribute("PremiumArchitecturalSurface"))
                .toBe(true)

            templates=Instance.new("Folder")
            templates.Name="ApprovedPlatformSideTemplates"
            templates:SetAttribute("OwnerVerified",true)
            templates.Parent=game:GetService("ReplicatedStorage")
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
            expect(PremiumPlatformSideMeshKit.hasNativeCarapaceFallback(
                decor,nearby)).toBe(true)
            local chosen=PremiumPlatformSideMeshKit.selectCarapaceDecks(
                {distant,nearby},"Crossroads","Low",base,nearby.Position,
                Vector3.new(0,0,1),0,decor)
            expect(chosen[nearby]).toBe(true)
            expect(chosen[distant]).toBe(nil)
            expect(PremiumPlatformSideMeshKit.selectCarapaceDecks(
                {distant,nearby},"Crossroads","Low",base,nearby.Position,
                Vector3.new(0,0,1),1,decor)[nearby]).toBe(nil)

            -- Roblox StreamingEnabled may replicate the physical deck
            -- before its four original bevels or authentic underside.
            -- Never spend scarce 3D source slots on missing native masks.
            local missingBevel=bevels[1]
            missingBevel.Parent=nil
            expect(PremiumPlatformSideMeshKit.hasNativeCarapaceFallback(
                decor,nearby)).toBe(false)
            expect(PremiumPlatformSideMeshKit.selectCarapaceDecks(
                {distant,nearby},"Crossroads","Low",base,nearby.Position,
                Vector3.new(0,0,1),0,decor)[nearby]).toBe(nil)
            missingBevel.Parent=decor
            expect(PremiumPlatformSideMeshKit.hasNativeCarapaceFallback(
                decor,nearby)).toBe(true)
            -- A present but unauthenticated WedgePart is not legitimate
            -- native geometry. Reject before consuming a scarce MeshKit
            -- slot, and resume when the server's original tag returns.
            missingBevel:SetAttribute("OriginalStructuralBevel",false)
            expect(PremiumPlatformSideMeshKit.hasNativeCarapaceFallback(
                decor,nearby)).toBe(false)
            missingBevel:SetAttribute("OriginalStructuralBevel",true)
            expect(PremiumPlatformSideMeshKit.hasNativeCarapaceFallback(
                decor,nearby)).toBe(true)
            underside.Parent=nil
            expect(PremiumPlatformSideMeshKit.hasNativeCarapaceFallback(
                decor,nearby)).toBe(false)
            underside.Parent=decor
            expect(PremiumPlatformSideMeshKit.selectCarapaceDecks(
                {distant,nearby},"Crossroads","Low",base,nearby.Position,
                Vector3.new(0,0,1),0,decor)[nearby]).toBe(true)

            meshes=Instance.new("Folder")
            meshes.Name="OriginalCarapaceEvenDeckFixture"
            meshes.Parent=workspace
            local parts=PremiumPlatformSideMeshKit.carapace(
                meshes,nearby,"Crossroads","Low",2,true)
            expect(parts~=nil and #parts==7).toBe(true)
            for _,piece in ipairs(parts) do
                expect(piece:IsA("MeshPart")).toBe(true)
                expect(piece.CanCollide or piece.CanTouch or piece.CanQuery)
                    .toBe(false)
                expect(piece:GetAttribute("Original3DStructuralSide"))
                    .toBe(true)
            end
            Kit.bind(arena,{["2"]="carapace"},nil,nil,meshes)
            expect(Kit.count()).toBe(5)
            for _,bevel in ipairs(bevels) do
                expect(bevel.LocalTransparencyModifier).toBe(1)
            end
            expect(underside.LocalTransparencyModifier).toBe(1)
            expect(nearby.CanCollide).toBe(true)
            local masks=Kit.breakdown()
            expect(masks.bevel).toBe(4)
            expect(masks.underframe).toBe(1)
            expect(masks.support).toBe(0)
            expect(masks.other).toBe(0)
            -- The approved source is a genuine seven-piece bundle.
            -- Losing just its FIRST mesh must immediately restore ALL
            -- four authentic WedgePart bevels and the full underframe.
            parts[1].Parent = nil
            expect(Kit.count()).toBe(0)
            for _,bevel in ipairs(bevels) do
                expect(bevel.LocalTransparencyModifier).toBe(0)
            end
            expect(underside.LocalTransparencyModifier).toBe(0)
            expect(nearby.CanCollide).toBe(true)
            parts[1].Parent = meshes
            expect(Kit.count()).toBe(5)
            for _,bevel in ipairs(bevels) do
                expect(bevel.LocalTransparencyModifier).toBe(1)
            end
            expect(underside.LocalTransparencyModifier).toBe(1)

            -- The MeshPart may remain in the render folder but lose its
            -- actual WeldConstraint on the playable Platform2 owner.
            -- A naked 3D skirt is not an authorized native replacement.
            local joint = parts[2]:FindFirstChild("ChaosPlatformTrimWeld")
            expect(joint~=nil and joint.Part1==nearby).toBe(true)
            joint.Parent = nil
            expect(Kit.count()).toBe(0)
            expect(Kit.breakdown().bevel).toBe(0)
            for _,bevel in ipairs(bevels) do
                expect(bevel.LocalTransparencyModifier).toBe(0)
            end
            expect(underside.LocalTransparencyModifier).toBe(0)
            joint.Parent = parts[2]
            expect(Kit.count()).toBe(5)
            expect(Kit.breakdown().bevel).toBe(4)
            for _,bevel in ipairs(bevels) do
                expect(bevel.LocalTransparencyModifier).toBe(1)
            end
            expect(underside.LocalTransparencyModifier).toBe(1)

            nearby:SetAttribute("CollapsePhase","Warning")
            expect(Kit.count()).toBe(0)
            for _,bevel in ipairs(bevels) do
                expect(bevel.LocalTransparencyModifier).toBe(0)
            end
            expect(underside.LocalTransparencyModifier).toBe(0)
            nearby:SetAttribute("CollapsePhase","Normal")
            expect(Kit.count()).toBe(5)
            -- A lost imported original must restore the server natives,
            -- never leave a hole around the physical landing surface.
            for _,piece in ipairs(parts) do piece:Destroy() end
            expect(Kit.count()).toBe(0)
            expect(underside.LocalTransparencyModifier).toBe(0)
            for _,bevel in ipairs(bevels) do
                expect(bevel.LocalTransparencyModifier).toBe(0)
            end
        end)
        Kit.reset()
        if meshes then meshes:Destroy() end
        if templates then templates:Destroy() end
        if generated then generated:Destroy() end
        if previous then previous.Parent=workspace end
        if not ok then error(failure) end
    end)

    it("retains genuine exterior ridge sculpture across shrink on Android Low", function()
        local previous=workspace:FindFirstChild("GeneratedMap")
        if previous then previous.Parent=nil end
        local generated,templates
        local ok,failure=pcall(function()
            local arena=MapBuilder.buildArena(Config,"Classic",
                ArenaVariants,VisualTheme)
            generated=arena.Parent
            local base=arena:FindFirstChild("Base")
            local decor=arena:FindFirstChild("Decor")
            local ridgeOwner=decor:FindFirstChild("ExteriorRidgeNW")
            expect(ridgeOwner~=nil).toBe(true)
            local ridge=ridgeOwner:FindFirstChild("Ridge1")
            expect(ridge:IsA("WedgePart")).toBe(true)
            local alpha=ridge.Transparency
            templates=Instance.new("Folder")
            templates.Name="ApprovedExteriorRidgeTemplates"
            templates:SetAttribute("OwnerVerified",true)
            templates.Parent=game:GetService("ReplicatedStorage")
            local source=Instance.new("Model")
            source.Name="RidgesNW"
            source:SetAttribute("OwnerVerified",true)
            source:SetAttribute("CosmeticOnly",true)
            source:SetAttribute("OriginalExteriorRidges3D",true)
            source:SetAttribute("Original3DAssetId",123836720232695)
            source:SetAttribute("ExteriorCornerId","NW")
            for i=1,7 do
                local mesh=Instance.new("MeshPart")
                mesh.Name="RidgeMaterial"..i
                mesh.Size=if i==1 then Vector3.new(
                    37.45768,15.9,33.90254) else Vector3.new(1,1,1)
                mesh.Anchored=true
                mesh.CanCollide=false
                mesh.CanTouch=false
                mesh.CanQuery=false
                mesh.Parent=source
            end
            source.Parent=templates
            local camera=ridge.Position
            local function sync(pressure)
                ExteriorRidgeKit.sync(arena,camera,"Low",true,true,pressure)
            end
            sync(0)
            expect(ExteriorRidgeKit.count()).toBe(1)
            expect(ExteriorRidgeKit.replacedNativeCount()).toBe(3)
            expect(ridge.Transparency).toBe(1)
            local initialPosition=ridge.Position
            -- Real shrink changes X/Z but not the authored floor thickness.
            base.Size=Vector3.new(170,base.Size.Y,174)
            sync(0)
            expect(ExteriorRidgeKit.count()).toBe(1)
            expect(ExteriorRidgeKit.replacedNativeCount()).toBe(3)
            expect((ridge.Position-initialPosition).Magnitude<.01).toBe(true)
            sync(1)
            expect(ExteriorRidgeKit.count()).toBe(0)
            expect(math.abs(ridge.Transparency-alpha)<.001).toBe(true)
            sync(0)
            expect(ExteriorRidgeKit.count()).toBe(1)
            base.Size=Vector3.new(330,base.Size.Y,320)
            sync(0)
            expect(ExteriorRidgeKit.count()).toBe(0)
            expect(math.abs(ridge.Transparency-alpha)<.001).toBe(true)
        end)
        ExteriorRidgeKit.sync(nil,Vector3.zero,"Low",false,true,2)
        if generated then generated:Destroy() end
        if templates then templates:Destroy() end
        if previous then previous.Parent=workspace end
        if not ok then error(failure) end
    end)

    -- Repeatable real-engine structural census across all five fully
    -- generated maps + lobby. The exact per-family snapshot is frozen in
    -- docs/audit/structure-family-census-2026-11-13.csv. These safety
    -- assertions reject empty/incomplete maps without tying development
    -- to exact source Part counts or artificially failing CI.
    for _,variantId in ipairs(ArenaVariants.Order) do
        it("P4 five-world physical structure census "..variantId, function()
            local previous=workspace:FindFirstChild("GeneratedMap")
            local replicated=game:GetService("ReplicatedStorage")
            local previousP4=replicated:FindFirstChild(
                "ApprovedRemainingStructureTemplates")
            if previous then previous.Parent=nil end
            if previousP4 then previousP4.Parent=nil end
            local generated,templates=nil,nil
            local p4Phase="map"
            RemainingStructureKit.sync(nil,Vector3.zero,"Low",false)
            local ok,result=pcall(function()
                generated=MapBuilder.build(Config,variantId,ArenaVariants,VisualTheme)
                local arena=generated:FindFirstChild("Arena")
                local lobby=generated:FindFirstChild("Lobby")
                assert(arena and lobby,"Full map and lobby must exist")
                local HttpService=game:GetService("HttpService")
                local stats={
                    total=0,visible=0,primitives=0,meshes=0,
                    visiblePrimitives=0,physicalVisible=0,
                    nonphysicalVisiblePrimitives=0,
                    largeNonphysical=0,hugeNonphysical=0,
                    neonNonphysical=0,opaqueNonphysical=0,
                    invisible=0,lights=0,effects=0,
                    models=0,lobbyPrimitives=0,
                    lobbyVisible=0,arenaVisible=0,
                    arenaNonphysical=0,arenaCollidable=0,
                }
                local groups={}
                local function category(part)
                    local chain={}
                    local parent=part
                    while parent and parent~=generated do
                        table.insert(chain,1,parent)
                        parent=parent.Parent
                    end
                    local top=chain[1] and chain[1].Name or "External"
                    if top=="Arena" then
                        local section=chain[2] and chain[2].Name or "Direct"
                        if section=="Decor" then
                            local subgroup=chain[3]
                            if not subgroup then return "Arena/Decor/Empty" end
                            if subgroup==part then
                                return "Arena/Decor/Direct/"
                                    ..part.Name:gsub("%d+","#")
                            end
                            return "Arena/Decor/"..subgroup.Name:gsub("%d+","#")
                        end
                        return "Arena/"..section
                    end
                    return top
                end
                for _,inst in ipairs(generated:GetDescendants()) do
                    if inst:IsA("Model") then stats.models+=1 end
                    if inst:IsA("Light") then stats.lights+=1 end
                    if inst:IsA("ParticleEmitter")
                        or inst:IsA("Trail") or inst:IsA("Beam") then
                        stats.effects+=1
                    end
                    if inst:IsA("BasePart") then
                        stats.total+=1
                        local name=category(inst)
                        local item=groups[name]
                        if not item then
                            item={0,0,0,0,0,0,0}
                            groups[name]=item
                        end
                        item[1]+=1
                        local primitive=inst:IsA("Part")
                            or inst:IsA("WedgePart")
                            or inst:IsA("CornerWedgePart")
                            or inst:IsA("TrussPart")
                        local visible=inst.Transparency<.99
                        local physical=inst.CanCollide or inst.CanTouch
                            or inst.CanQuery
                        local maxDim=math.max(inst.Size.X,inst.Size.Y,inst.Size.Z)
                        local cue=inst.Material==Enum.Material.Neon
                            or string.find(string.lower(inst.Name),
                                "signal")~=nil
                            or string.find(string.lower(inst.Name),
                                "beacon")~=nil
                            or string.find(string.lower(inst.Name),
                                "glow")~=nil
                            or string.find(string.lower(inst.Name),
                                "guide")~=nil
                            or string.find(string.lower(inst.Name),
                                "lens")~=nil
                        if primitive then stats.primitives+=1 end
                        if inst:IsA("MeshPart") then stats.meshes+=1;item[7]+=1 end
                        if visible then
                            stats.visible+=1;item[2]+=1
                            if name=="Lobby" then stats.lobbyVisible+=1
                            else stats.arenaVisible+=1 end
                            if physical then
                                stats.physicalVisible+=1;item[6]+=1
                                if name~="Lobby" then stats.arenaCollidable+=1 end
                            else
                                if name~="Lobby" then stats.arenaNonphysical+=1 end
                                if primitive then
                                    stats.nonphysicalVisiblePrimitives+=1
                                    item[3]+=1
                                    if maxDim>=12 then
                                        stats.largeNonphysical+=1;item[4]+=1
                                    end
                                    if maxDim>=30 then stats.hugeNonphysical+=1 end
                                    if cue then
                                        stats.neonNonphysical+=1;item[5]+=1
                                    else
                                        stats.opaqueNonphysical+=1
                                    end
                                end
                            end
                            if primitive then stats.visiblePrimitives+=1 end
                            if name=="Lobby" and primitive then
                                stats.lobbyPrimitives+=1
                            end
                        else
                            stats.invisible+=1
                        end
                    end
                end
                local ordered={}
                for name,counts in pairs(groups) do
                    ordered[#ordered+1]={name,unpack(counts)}
                end
                table.sort(ordered,function(a,b)
                    if a[5]~=b[5] then return a[5]>b[5] end
                    if a[4]~=b[4] then return a[4]>b[4] end
                    return a[1]<b[1]
                end)
                -- Extend this EXISTING five-world real-engine census with
                -- the actual approved-3D owner lifecycle, not a new unit
                -- suite or a guessed count of assets visible at runtime.
                p4Phase="registered source IDs"
                local expectedIds={
                    Access=110243423264048,
                    Transfer=107273631120961,
                    Summit=127049813505254,
                    Casing=130196548599769,
                    Helix=106863534763803,
                }
                for name,id in pairs(expectedIds) do
                    expect(RemainingStructureAssets.approvedId(name)).toBe(id)
                end
                p4Phase="mobile and desktop model budgets"
                expect(RemainingStructureKit.budget("Low",true,0,"arch")).toBe(1)
                expect(RemainingStructureKit.budget("Low",true,1,"arch")).toBe(0)
                expect(RemainingStructureKit.budget("Low",true,0,"helix")).toBe(0)
                expect(RemainingStructureKit.budget("Medium",true,0,"arch")).toBe(2)
                expect(RemainingStructureKit.budget("Medium",true,0,"helix")).toBe(1)
                expect(RemainingStructureKit.budget("High",true,0,"arch")).toBe(3)
                expect(RemainingStructureKit.budget("High",true,0,"casing")).toBe(2)
                -- Higher desktop-only visible coverage consumes existing approved
                -- seven-MeshPart source bundles, never Android extras.
                expect(RemainingStructureKit.budget("Medium",false,0,"arch")).toBe(6)
                expect(RemainingStructureKit.budget("Medium",false,0,"casing")).toBe(4)
                expect(RemainingStructureKit.budget("Medium",false,0,"helix")).toBe(4)
                expect(RemainingStructureKit.budget("High",false,0,"arch")).toBe(10)
                expect(RemainingStructureKit.budget("High",false,0,"helix")).toBe(8)
                -- Even on desktop, GPU pressure 1 retains ALL original
                -- emergency caps. Pressure 2 immediately restores natives.
                expect(RemainingStructureKit.budget("Medium",false,1,"arch")).toBe(1)
                expect(RemainingStructureKit.budget("Medium",false,1,"casing")).toBe(1)
                expect(RemainingStructureKit.budget("Medium",false,1,"helix")).toBe(1)
                expect(RemainingStructureKit.budget("High",false,1,"arch")).toBe(3)
                expect(RemainingStructureKit.budget("High",false,1,"casing")).toBe(2)
                expect(RemainingStructureKit.budget("High",false,1,"helix")).toBe(3)
                expect(RemainingStructureKit.budget("High",false,2,"arch")).toBe(0)

                p4Phase="seven-MeshPart owner-approved template fixtures"
                templates=Instance.new("Folder")
                templates.Name="ApprovedRemainingStructureTemplates"
                templates:SetAttribute("OwnerVerified",true)
                templates.Parent=replicated
                -- Engine-only stand-ins with EXACT pre-verified source
                -- metadata. Asset ID / glTF provenance is independently
                -- certified by creator upload run 43467373476 (Approved).
                local function specimen(name,size)
                    local model=Instance.new("Model")
                    model.Name=name
                    model:SetAttribute("OwnerVerified",true)
                    model:SetAttribute("CosmeticOnly",true)
                    model:SetAttribute("Original3DAssetId",expectedIds[name])
                    model:SetAttribute("P4OriginalRemainingStructure3D",true)
                    for index=1,7 do
                        local part=Instance.new("MeshPart")
                        part.Name="OriginalMaterialRegion"..index
                        part.Size=size
                        part.CFrame=CFrame.new(0,0,0)
                        part.Anchored=true
                        part.Massless=true
                        part.CanCollide=false
                        part.CanTouch=false
                        part.CanQuery=false
                        part.Parent=model
                    end
                    model.Parent=templates
                end
                specimen("Access",Vector3.new(3.9,17.53,17.6))
                specimen("Transfer",Vector3.new(4.1,18.33,17.6))
                specimen("Summit",Vector3.new(5.2,19.73,17.6))
                specimen("Casing",Vector3.new(8.58,10.378,5.3))
                if variantId=="Orbital" then
                    specimen("Helix",Vector3.new(5.08,1.453,23.6))
                end
                p4Phase="authentic server-made casing and ascension gateway"
                local base=arena:FindFirstChild("Base")
                local platforms=arena:FindFirstChild("Platforms")
                local decor=arena:FindFirstChild("Decor")
                local casingGroup=decor:FindFirstChild(
                    "OriginalPremiumColumnCladding")
                expect(casingGroup~=nil).toBe(true)
                expect(#casingGroup:GetChildren()).toBe(4)
                local entryDeck=nil
                for _,platform in ipairs(platforms:GetChildren()) do
                    if platform:GetAttribute("PerimeterStep")==1 then
                        entryDeck=platform;break
                    end
                end
                expect(entryDeck~=nil).toBe(true)
                local deckId=tonumber(entryDeck.Name:match("%d+"))
                local overpass=decor:FindFirstChild(
                    "SkyRouteMonument"..deckId.."_MonumentalOverpass")
                local wayfinding=decor:FindFirstChild(
                    "SkyRouteMonument"..deckId.."_RouteStageBeacon")
                expect(overpass~=nil).toBe(true)
                expect(wayfinding~=nil).toBe(true)
                expect(base.CanCollide).toBe(true)
                p4Phase="first geometry owner mounting"
                RemainingStructureKit.sync(arena,base.Position,"High",true,
                    Vector3.new(0,0,-1),0,false)
                p4Phase="approved arch residency"
                expect(RemainingStructureKit.count("arch")).toBe(10)
                expect(RemainingStructureKit.nativeCount("arch")).toBe(50)
                RemainingStructureKit.sync(arena,base.Position,"Medium",true,
                    Vector3.new(0,0,-1),0,false)
                expect(RemainingStructureKit.count("arch")).toBe(6)
                RemainingStructureKit.sync(arena,base.Position,"High",true,
                    Vector3.new(0,0,-1),0,false)
                -- Verify REAL source-masked upper porticos on all FOUR
                -- physical perimeter escape routes, using the existing six
                -- High PC slots. This catches camera-only concentration of
                -- the approved originals without inventing a fake platform.
                p4Phase="four genuine escape routes visibly sculpted"
                local sculptedRoutes={}
                local sculptedStages={}
                for _,realDeck in ipairs(platforms:GetChildren()) do
                    local stage=realDeck:GetAttribute("PerimeterStep")
                    if stage==1 or stage==4 or stage==8 then
                        local realId=tonumber(realDeck.Name:match("%d+"))
                        local native=realId and decor:FindFirstChild(
                            "SkyRouteMonument"..realId.."_MonumentalOverpass")
                        if native and native.LocalTransparencyModifier==1 then
                            sculptedRoutes[realDeck:GetAttribute("PerimeterRoute")]=true
                            sculptedStages[stage]=true
                        end
                    end
                end
                local distinctRoutes=0
                for _ in pairs(sculptedRoutes) do distinctRoutes+=1 end
                expect(distinctRoutes).toBe(4)
                expect(sculptedStages[1]).toBe(true)
                expect(sculptedStages[4]).toBe(true)
                expect(sculptedStages[8]).toBe(true)
                p4Phase="approved casing residency"
                expect(RemainingStructureKit.count("casing")>=1).toBe(true)
                p4Phase="native arch mask and untouched signal"
                expect(overpass.LocalTransparencyModifier).toBe(1)
                expect(wayfinding.LocalTransparencyModifier).toBe(0)
                expect(entryDeck.CanCollide).toBe(true)
                -- Hazard warning immediately unmasks the true gateway.
                p4Phase="immediate warning fallback"
                entryDeck:SetAttribute("CollapsePhase","Warning")
                expect(overpass.LocalTransparencyModifier).toBe(0)
                p4Phase="warning recovery"
                entryDeck:SetAttribute("CollapsePhase","Normal")
                expect(overpass.LocalTransparencyModifier).toBe(1)
                -- If a single cosmetic MeshPart streams out, restore the
                -- native immediately. On the next existing LOD sample,
                -- discard only its damaged clone and remount the complete
                -- seven-part source. The actual walkable deck never changes.
                p4Phase="partial 3D clone eviction and remount"
                local residentFolder=workspace:FindFirstChild(
                    "ApprovedRemainingStructureMeshesLocal")
                expect(residentFolder~=nil).toBe(true)
                -- Six high-PC arches can include several identical
                -- Access imports. Corrupt the clone for THIS actual
                -- owned deck, not the first same-named sibling.
                local function ownedAccessClone()
                    for _,model in ipairs(residentFolder:GetChildren()) do
                        if model.Name=="ApprovedP4_Access"
                            and model:GetAttribute("OriginalP4OwnerPlatform")
                                ==entryDeck.Name then
                            return model
                        end
                    end
                    return nil
                end
                local originalClone=ownedAccessClone()
                expect(originalClone~=nil).toBe(true)
                local missingPiece=originalClone:FindFirstChildWhichIsA(
                    "MeshPart",true)
                expect(missingPiece~=nil).toBe(true)
                local before=RemainingStructureKit.count("arch")
                missingPiece:Destroy()
                task.wait()
                expect(RemainingStructureKit.count("arch")).toBe(before-1)
                RemainingStructureKit.sync(arena,base.Position,"High",true,
                    Vector3.new(0,0,-1),0,false)
                expect(RemainingStructureKit.count("arch")).toBe(before)
                expect(overpass.LocalTransparencyModifier).toBe(1)
                expect(entryDeck.CanCollide).toBe(true)

                -- An extra unexpected primitive in an imported clone
                -- cannot be trusted as part of the seven-piece original.
                -- Restore the native instantly and reject local collision.
                p4Phase="foreign geometry corruption and native recovery"
                local restoredClone=ownedAccessClone()
                expect(restoredClone~=nil).toBe(true)
                local foreignPart=Instance.new("Part")
                foreignPart.Name="UnapprovedEighthPart"
                foreignPart.CanCollide=true
                foreignPart.CanTouch=true
                foreignPart.CanQuery=true
                foreignPart.Parent=restoredClone
                -- Roblox may deliver descendant signals in deferred mode.
                task.wait()
                expect(foreignPart.CanCollide).toBe(false)
                expect(foreignPart.CanTouch).toBe(false)
                expect(foreignPart.CanQuery).toBe(false)
                expect(foreignPart.LocalTransparencyModifier).toBe(1)
                expect(overpass.LocalTransparencyModifier).toBe(0)
                expect(RemainingStructureKit.count("arch")).toBe(before-1)
                RemainingStructureKit.sync(arena,base.Position,"High",true,
                    Vector3.new(0,0,-1),0,false)
                expect(RemainingStructureKit.count("arch")).toBe(before)
                expect(overpass.LocalTransparencyModifier).toBe(1)

                -- The approved TEMPLATE must remain seven real pieces,
                -- not just its already-mounted copy. Missing original
                -- geometry immediately restores all affected native roofs.
                p4Phase="mutated approved source and recovery"
                local template=templates:FindFirstChild("Access")
                local sourcePiece=template:FindFirstChildWhichIsA(
                    "MeshPart",true)
                expect(sourcePiece~=nil).toBe(true)
                local originalSourceParent=sourcePiece.Parent
                sourcePiece.Parent=nil
                task.wait()
                expect(overpass.LocalTransparencyModifier).toBe(0)
                RemainingStructureKit.sync(arena,base.Position,"High",true,
                    Vector3.new(0,0,-1),0,false)
                -- Invalid Access source can release its previous slots
                -- to already-Approved Transfer/Summit meshes. Total arch
                -- count may stay at its capped budget: the exact Access
                -- owner and its native warning geometry must be restored.
                expect(ownedAccessClone()==nil).toBe(true)
                expect(RemainingStructureKit.count("arch")<=before).toBe(true)
                sourcePiece.Parent=originalSourceParent
                task.wait()
                RemainingStructureKit.sync(arena,base.Position,"High",true,
                    Vector3.new(0,0,-1),0,false)
                expect(RemainingStructureKit.count("arch")).toBe(before)
                expect(ownedAccessClone()~=nil).toBe(true)
                expect(overpass.LocalTransparencyModifier).toBe(1)

                -- Same approved geometry, different client budget: mobile
                -- High displays at most three distinct real deck owners.
                -- It must never obtain the six-slot PC allocation.
                p4Phase="three-slot Android High verified native owners"
                RemainingStructureKit.sync(arena,base.Position,"High",true,
                    Vector3.new(0,0,-1),0,true)
                expect(RemainingStructureKit.count("arch")).toBe(3)
                local visibleMobileOwners=0
                for _,realDeck in ipairs(platforms:GetChildren()) do
                    local stage=realDeck:GetAttribute("PerimeterStep")
                    if stage==1 or stage==4 or stage==8 then
                        local realId=tonumber(realDeck.Name:match("%d+"))
                        local native=realId and decor:FindFirstChild(
                            "SkyRouteMonument"..realId.."_MonumentalOverpass")
                        if native and native.LocalTransparencyModifier==1 then
                            visibleMobileOwners+=1
                            expect(realDeck.CanCollide).toBe(true)
                        end
                    end
                end
                expect(visibleMobileOwners).toBe(3)
                -- Restore PC context for the Orbital-specific helix check.
                RemainingStructureKit.sync(arena,base.Position,"High",true,
                    Vector3.new(0,0,-1),0,false)
                if variantId=="Orbital" then
                    p4Phase="genuine Orbital helix residency"
                    expect(RemainingStructureKit.count("helix")>=1).toBe(true)
                    local circuit=arena:FindFirstChild("HelixCircuit")
                    local ramp=circuit and circuit:FindFirstChild("HelixRamp1")
                    expect(ramp~=nil and ramp.CanCollide).toBe(true)
                    local underframe=circuit:FindFirstChild("HelixUnderframe1_-1")
                    expect(underframe~=nil).toBe(true)
                    expect(underframe.LocalTransparencyModifier).toBe(1)
                    RemainingStructureKit.sync(arena,base.Position,"Low",true,
                        Vector3.new(0,0,-1),0,true)
                    expect(RemainingStructureKit.count("helix")).toBe(0)
                    expect(underframe.LocalTransparencyModifier).toBe(0)
                    expect(ramp.CanCollide).toBe(true)
                end
                p4Phase="final native restoration"
                RemainingStructureKit.sync(nil,Vector3.zero,"Low",false)
                expect(overpass.LocalTransparencyModifier).toBe(0)
                expect(base.CanCollide).toBe(true)

                -- Every owner group, including small visual details, is
                -- emitted in this diagnostic: the finished CSV must not
                -- silently discard low-frequency groups or the lobby.
                return HttpService:JSONEncode({
                    variant=variantId,stats=stats,
                    groups=#ordered,
                    inventory=ordered,
                })
            end)
            RemainingStructureKit.sync(nil,Vector3.zero,"Low",false)
            if templates then templates:Destroy() end
            if generated then generated:Destroy() end
            if previousP4 then previousP4.Parent=replicated end
            if previous then previous.Parent=workspace end
            if not ok then
                local detail=tostring(result)
                if type(result)=="table" then
                    for key,value in pairs(result) do
                        detail ..=" "..tostring(key).."="..tostring(value)
                    end
                end
                error("P4_CENSUS_ERROR "..variantId.." ["..p4Phase.."] "..detail)
            end
            local snapshot=game:GetService("HttpService"):JSONDecode(result)
            expect(snapshot.variant).toBe(variantId)
            expect(snapshot.groups>=140).toBe(true)
            expect(snapshot.stats.total>2600).toBe(true)
            expect(snapshot.stats.nonphysicalVisiblePrimitives>2400).toBe(true)
            expect(snapshot.stats.physicalVisible>=100).toBe(true)
            expect(snapshot.stats.meshes).toBe(0)
            expect(#snapshot.inventory).toBe(snapshot.groups)
        end)
    end

    it("keeps both authentic outer Harbor 3D landmarks through shrink with native restoration", function()
        -- Use the real MapBuilder Harbor geometry, not stand-in native
        -- signature parts. Only the approved imported meshes are local
        -- test fixtures; production imports remain gated by AssetService.
        local previous=workspace:FindFirstChild("GeneratedMap")
        if previous then previous.Parent=nil end
        local generated,northSource,southSource
        local ok,failure=pcall(function()
        local arena=MapBuilder.buildArena(Config,"Harbor",ArenaVariants)
        generated=arena.Parent
        local base=arena:FindFirstChild("Base")
        local decor=arena:FindFirstChild("Decor")
        local north=decor:FindFirstChild("ArenaSignatureMegastructure")
        local south=decor:FindFirstChild("SouthHorizonMonument")
        expect(base~=nil and north~=nil and south~=nil).toBe(true)
        local storage=game:GetService("ReplicatedStorage")
        local function originalSource(folderName,modelName,tag,id,dimensions)
            local holder=Instance.new("Folder")
            holder.Name=folderName
            holder:SetAttribute("OwnerVerified",true)
            holder.Parent=storage
            local source=Instance.new("Model")
            source.Name=modelName
            source:SetAttribute("OwnerVerified",true)
            source:SetAttribute("CosmeticOnly",true)
            source:SetAttribute(tag,true)
            source:SetAttribute("Original3DAssetId",id)
            for i=1,7 do
                local mesh=Instance.new("MeshPart")
                mesh.Name="ApprovedSourceMesh"..i
                mesh.Size=if i==1 then dimensions
                    else Vector3.new(1,1,1)
                mesh.Anchored=true
                mesh.CanCollide=false
                mesh.CanTouch=false
                mesh.CanQuery=false
                mesh.Parent=source
            end
            source.Parent=holder
            return holder
        end
        northSource=originalSource(
            "ApprovedHarborSignatureGantryTemplates","SculptedGantry",
            "OriginalHarborSignatureGantry3D",124368710235343,
            Vector3.new(40.8,14.0425,9.141))
        southSource=originalSource(
            "ApprovedSouthHarborDrydockTemplates","SculptedDrydock",
            "OriginalSouthHarborSculptedDrydock3D",125428569657840,
            Vector3.new(16.58,18.42,4.63))
        local beam=north:FindFirstChild("QuayCraneSpanningBeam")
        local drydock=south:FindFirstChild("HarborLightshipBridge")
        expect(beam~=nil and drydock~=nil).toBe(true)
        local beamAlpha=beam.Transparency
        local dockAlpha=drydock.Transparency
        local northCamera=beam.Position
        local southCamera=drydock.Position
        local function update(pressure)
            HarborSignatureGantryKit.sync(arena,northCamera,
                "Low",true,pressure)
            SouthHarborDrydockKit.sync(arena,southCamera,
                "Low",true,pressure)
        end
        update(0)
        local function requireMounted(stage)
            local n=HarborSignatureGantryKit.count()
            local d=SouthHarborDrydockKit.count()
            local hiddenN=HarborSignatureGantryKit.replacedNativeCount()
            local hiddenD=SouthHarborDrydockKit.replacedNativeCount()
            if n~=1 or d~=1 or hiddenN~=3 or hiddenD~=14
                or beam.Transparency~=1 or drydock.Transparency~=1 then
                error("Harbor authentic outer 3D failed at "..stage
                    .." north="..tostring(n).." south="..tostring(d)
                    .." northMasked="..tostring(hiddenN)
                    .." southMasked="..tostring(hiddenD)
                    .." northAlpha="..tostring(beam.Transparency)
                    .." southAlpha="..tostring(drydock.Transparency)
                    .." base="..tostring(base.Size)
                    .." originalX="..tostring(base:GetAttribute("OriginalSizeX"))
                    .." originalZ="..tostring(base:GetAttribute("OriginalSizeZ"))
                    .." baseParent="..tostring(base.Parent==arena)
                    .." baseAnchored="..tostring(base.Anchored)
                    .." baseCollide="..tostring(base.CanCollide)
                    .." northVariant="..tostring(north:GetAttribute("SignatureVariant"))
                    .." southVariant="..tostring(south:GetAttribute("SignatureVariant"))
                    .." generatedOk="..tostring(
                        workspace:FindFirstChild("GeneratedMap")==generated)
                    .." northTargetError="..tostring(
                        (beam.Position-(base.Position+Vector3.new(
                            base:GetAttribute("OriginalSizeX")*.24,
                            base.Size.Y*.5+43.5,
                            -(base:GetAttribute("OriginalSizeZ")*.5+66)))).Magnitude)
                    .." southTargetError="..tostring(
                        (south.Foundation.Position-(base.Position+Vector3.new(
                            -base:GetAttribute("OriginalSizeX")*.20,
                            base.Size.Y*.5-1,
                            base:GetAttribute("OriginalSizeZ")*.5+54))).Magnitude))
            end
        end
        requireMounted("initial")
        expect(HarborSignatureGantryKit.count()).toBe(1)
        expect(HarborSignatureGantryKit.replacedNativeCount()).toBe(3)
        expect(SouthHarborDrydockKit.count()).toBe(1)
        expect(SouthHarborDrydockKit.replacedNativeCount()).toBe(14)
        expect(beam.Transparency).toBe(1)
        expect(drydock.Transparency).toBe(1)
        local originalBeamPos=beam.Position
        local originalDockPos=drydock.Position
        base.Size=Vector3.new(170,base.Size.Y,174)
        local eventNorth=HarborSignatureGantryKit.count()
        local eventSouth=SouthHarborDrydockKit.count()
        local expectedNorth=base.Position+Vector3.new(
            base:GetAttribute("OriginalSizeX")*.24,
            base.Size.Y*.5+43.5,
            -(base:GetAttribute("OriginalSizeZ")*.5+66))
        local expectedDock=base.Position+Vector3.new(
            -base:GetAttribute("OriginalSizeX")*.20,
            base.Size.Y*.5,base:GetAttribute("OriginalSizeZ")*.5+54)
        if eventNorth~=1 or eventSouth~=1 then
            error("Harbor outer 3D invalidated by Base.Size event: north="
                ..tostring(eventNorth).." south="..tostring(eventSouth)
                .." baseCollide="..tostring(base.CanCollide)
                .." baseAnchored="..tostring(base.Anchored)
                .." baseParentOk="..tostring(base.Parent==arena)
                .." beamPositionErr="..tostring(
                    (beam.Position-expectedNorth).Magnitude)
                .." drydockOriginErr="..tostring(
                    (south.Foundation.Position-
                        (expectedDock+Vector3.new(0,-1,0))).Magnitude))
        end
        update(0)
        requireMounted("after-shrink")
        expect(HarborSignatureGantryKit.count()).toBe(1)
        expect(SouthHarborDrydockKit.count()).toBe(1)
        expect((beam.Position-originalBeamPos).Magnitude<.01).toBe(true)
        expect((drydock.Position-originalDockPos).Magnitude<.01).toBe(true)
        update(1)
        expect(HarborSignatureGantryKit.count()).toBe(0)
        expect(SouthHarborDrydockKit.count()).toBe(0)
        expect(beam.Transparency).toBe(beamAlpha)
        expect(drydock.Transparency).toBe(dockAlpha)
        update(0)
        requireMounted("after-pressure-recovery")
        expect(HarborSignatureGantryKit.count()).toBe(1)
        expect(SouthHarborDrydockKit.count()).toBe(1)
        -- An invalid floor expansion must immediately reveal both
        -- original silhouettes instead of retaining counterfeit art.
        base.Size=Vector3.new(330,base.Size.Y,320)
        update(0)
        expect(HarborSignatureGantryKit.count()).toBe(0)
        expect(SouthHarborDrydockKit.count()).toBe(0)
        expect(beam.Transparency).toBe(beamAlpha)
        expect(drydock.Transparency).toBe(dockAlpha)
        end)
        -- Even a failed assertion must never leak a GeneratedMap into
        -- subsequent map, bot or visual tests in this engine shard.
        HarborSignatureGantryKit.sync(nil,Vector3.zero,"Low",false,2)
        SouthHarborDrydockKit.sync(nil,Vector3.zero,"Low",false,2)
        if generated then generated:Destroy() end
        if northSource then northSource:Destroy() end
        if southSource then southSource:Destroy() end
        if previous then previous.Parent=workspace end
        if not ok then error(failure) end
    end)

    it("mounts the approved Harbor hero 3D on genuine Low scenery without nonexistent hoist sensors", function()
        local storage=game:GetService("ReplicatedStorage")
        local templates=Instance.new("Folder")
        templates.Name="ApprovedHarborHeroStationTemplates"
        templates:SetAttribute("OwnerVerified",true)
        templates.Parent=storage
        local source=Instance.new("Model")
        source.Name="SignalStation"
        source:SetAttribute("OwnerVerified",true)
        source:SetAttribute("CosmeticOnly",true)
        source:SetAttribute("OriginalHarborHeroStation3D",true)
        source:SetAttribute("Original3DAssetId",73237902371094)
        local roles={"Static","Static","Static","Static",
            "Radar","Cable","Weight"}
        for i,role in ipairs(roles) do
            local part=Instance.new("MeshPart")
            part.Name=role.."Mesh"..i
            part.Size=if i==1 then Vector3.new(28.4,28.2,7.2)
                else Vector3.new(1,1,1)
            part.Anchored=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part:SetAttribute("OriginalHarborHeroMotionRole",role)
            part.Parent=source
        end
        source.Parent=templates
        local generated=Instance.new("Folder")
        generated.Name="GeneratedMap"
        generated.Parent=workspace
        local arena=Instance.new("Folder")
        arena.Name="Arena"
        arena:SetAttribute("VariantId","Harbor")
        arena.Parent=generated
        local base=Instance.new("Part")
        base.Name="Base"
        base.Anchored=true
        base.CanCollide=true
        base.Size=Vector3.new(320,4,320)
        base:SetAttribute("OriginalSizeX",320)
        base:SetAttribute("OriginalSizeZ",320)
        base.Parent=arena
        local hero=Instance.new("Folder")
        hero.Name="ArenaHeroSceneryLocal"
        hero.Parent=workspace
        local frame=base.CFrame*CFrame.new(0,0,178)
            *CFrame.Angles(0,math.pi,0)
        local original={}
        local function native(name,size,offset)
            local p=Instance.new("Part")
            p.Name=name
            p.Size=size
            p.CFrame=frame*CFrame.new(offset)
            p.Anchored=true
            p.CanCollide=false
            p.CanTouch=false
            p.CanQuery=false
            p.Transparency=.15
            p.Parent=hero
            original[p]=p.Transparency
            return p
        end
        native("HarborHeroPierFoundation",
            Vector3.new(23,2,8.8),Vector3.new(0,1.4,0))
        native("HarborHeroPortLeg",
            Vector3.new(2.2,19,2.4),Vector3.new(-7.8,11.5,0))
        native("HarborHeroStarboardLeg",
            Vector3.new(2.2,19,2.4),Vector3.new(7.8,11.5,0))
        local girder=native("HarborHeroGantryCrosshead",
            Vector3.new(19.5,1.8,3),Vector3.new(0,21.5,0))
        native("HarborHeroSignalCabin",
            Vector3.new(9.5,5.7,6.5),Vector3.new(0,25.2,0))
        native("HarborHeroRadarMast",
            Vector3.new(.9,9.5,.9),Vector3.new(0,32.9,0))
        local radar=native("HarborHeroRadarArm",
            Vector3.new(11.5,.48,.6),Vector3.new(0,37.7,0))
        local lens=native("HarborHeroStormLens",
            Vector3.new(2.6,2.6,2.6),Vector3.new(0,39.8,0))
        original[lens]=nil
        local camera=girder.Position
        local function sync(tier,pressure)
            HarborHeroStationMeshKit.sync(arena,camera,tier,true,pressure)
        end
        -- Low's native scene has no HarborHeroHoistCable/Weight at all.
        expect(hero:FindFirstChild("HarborHeroHoistCable")).toBe(nil)
        expect(hero:FindFirstChild("HarborHeroHoistWeight")).toBe(nil)
        sync("Low",0)
        expect(HarborHeroStationMeshKit.count()).toBe(1)
        local mounted=workspace.OriginalHarborHeroStationLocal:
            FindFirstChild("ApprovedOriginalHarborHeroStation3D")
        expect(mounted~=nil).toBe(true)
        local meshCount=0
        local radarMesh=nil
        for _,part in ipairs(mounted:GetDescendants()) do
            if part:IsA("BasePart") then
                meshCount+=1
                expect(part:IsA("MeshPart")).toBe(true)
                expect(part.CanCollide or part.CanTouch or part.CanQuery).toBe(false)
                if part:GetAttribute("OriginalHarborHeroMotionRole")=="Radar" then
                    radarMesh=part
                end
            end
        end
        expect(meshCount).toBe(7)
        expect(radarMesh~=nil).toBe(true)
        for part in pairs(original) do
            expect(part.Transparency).toBe(1)
        end
        expect(math.abs(lens.Transparency-.15)<.001).toBe(true)
        local beforeMove=radarMesh.Position
        radar.CFrame=radar.CFrame*CFrame.new(0,0,3)
        expect((radarMesh.Position-beforeMove).Magnitude>2).toBe(true)
        -- The station's already-mounted original 3D does not move or
        -- disappear when the physical survival floor shrinks.
        local beforeShrink=girder.Position
        base.Size=Vector3.new(170,4,174)
        sync("Low",0)
        expect(HarborHeroStationMeshKit.count()).toBe(1)
        expect((girder.Position-beforeShrink).Magnitude<.01).toBe(true)
        sync("Low",1)
        expect(HarborHeroStationMeshKit.count()).toBe(0)
        for part,alpha in pairs(original) do
            expect(part.Transparency).toBe(alpha)
        end
        sync("Low",0)
        expect(HarborHeroStationMeshKit.count()).toBe(1)
        local live=workspace.OriginalHarborHeroStationLocal:
            FindFirstChild("ApprovedOriginalHarborHeroStation3D")
        live:Destroy()
        expect(HarborHeroStationMeshKit.count()).toBe(0)
        for part,alpha in pairs(original) do
            expect(part.Transparency).toBe(alpha)
        end
        -- No spoofed, larger physical floor can authorize an offshore 3D.
        base.Size=Vector3.new(330,4,320)
        sync("Low",0)
        expect(HarborHeroStationMeshKit.count()).toBe(0)
        HarborHeroStationMeshKit.sync(nil,camera,"Low",false,2)
        hero:Destroy()
        generated:Destroy()
        templates:Destroy()
    end)

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
        local function sync(pressure,quality,position)
            HarborFreighterMeshKit.sync(arena,position or camera,
                quality or "High",true,Vector3.zero,pressure)
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
        -- The same seven approved meshes must replace the fourteen-part
        -- native Low outline, but only near the camera and pressure-free.
        sync(0,"Low")
        expect(HarborFreighterMeshKit.count()).toBe(1)
        expect(hull.Transparency).toBe(1)
        sync(0,"Low",camera+Vector3.new(0,0,350))
        expect(HarborFreighterMeshKit.count()).toBe(0)
        expect(hull.Transparency).toBe(initialAlpha)
        sync(0,"Low")
        expect(HarborFreighterMeshKit.count()).toBe(1)
        sync(1,"Low")
        expect(HarborFreighterMeshKit.count()).toBe(0)
        expect(hull.Transparency).toBe(initialAlpha)
        sync(0,"Low")
        expect(HarborFreighterMeshKit.count()).toBe(1)
        -- Genuine stationary exterior art must not disappear when only
        -- the survival floor contracts during Shrinking Arena.
        base.Size=Vector3.new(170,4,174)
        sync(0,"Low")
        expect(HarborFreighterMeshKit.count()).toBe(1)
        expect(hull.Transparency).toBe(1)
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
            local first
            for i=1,7 do
                local piece = Instance.new("MeshPart")
                piece.Name = name .. "_" .. i
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
                if i == 1 then first = piece end
            end
            return first
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
        local initialMasks=Kit.breakdown()
        expect(initialMasks.bevel).toBe(0)
        expect(initialMasks.underframe).toBe(2)
        expect(initialMasks.support).toBe(1)
        expect(initialMasks.other).toBe(1)
        expect(frame1.LocalTransparencyModifier).toBe(1)
        expect(frame2.LocalTransparencyModifier).toBe(1)
        expect(rib3.LocalTransparencyModifier).toBe(1)
        expect(support4.LocalTransparencyModifier).toBe(1)

        -- Removing just ONE of the seven genuine source MeshParts
        -- must restore ONLY that platform's whole native underside.
        -- As soon as the exact original part streams back in, all seven
        -- are again verified and its five-piece fallback can be masked.
        shell1.Parent = nil
        expect(frame1.LocalTransparencyModifier).toBe(0)
        expect(frame2.LocalTransparencyModifier).toBe(1)
        expect(Kit.count()).toBe(3)
        shell1.Parent = meshes
        expect(frame1.LocalTransparencyModifier).toBe(1)
        expect(Kit.count()).toBe(4)

        -- Permanent loss of the same ONE material leaves the other
        -- owner-verified 3D platforms resident. Never wait for loss of
        -- the sixth or final sibling before recovering the native.
        shell1:Destroy()
        expect(frame1.LocalTransparencyModifier).toBe(0)
        expect(frame2.LocalTransparencyModifier).toBe(1)
        expect(rib3.LocalTransparencyModifier).toBe(1)
        expect(support4.LocalTransparencyModifier).toBe(1)
        expect(Kit.count()).toBe(3)

        -- A tall seven-part support must also reveal its native Part
        -- when ONE material fails, rather than leaving a hollow column.
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
