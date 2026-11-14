--!strict
-- Focused Roblox Engine fixture: two authentic approved perimeter shapes.
-- Imported source provenance is verified separately in the pipeline;
-- the Roblox-only MeshParts here are purpose-built test fixtures.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Kit = require("../../src/client/PlatformNativeTrimReplacementKit")

describe("Approved perimeter rim fallback and physics (engine)", function()
    it("replaces four native platform bevel Wedges with seven approved rect/long MeshParts, never the collision deck", function()
        local Rim = require("../../src/client/ApprovedPlatformRimMeshKit")
        local RS = game:GetService("ReplicatedStorage")
        local previous = RS:FindFirstChild("ApprovedPlatformRimTemplates")
        if previous then previous.Parent = nil end
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
            checkSpread(mediumDesktop,4,2)
            checkSpread(highDesktop,8,3)
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
        end)
        Kit.reset()
        arena:Destroy()
        templates:Destroy()
        if previous then previous.Parent = RS end
        if not ok then error(why) end
    end)
end)

return nil
