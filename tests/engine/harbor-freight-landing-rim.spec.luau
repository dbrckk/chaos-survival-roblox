--!strict
-- Focused Roblox Engine fixture: two authentic approved perimeter shapes.
-- Imported source provenance is verified separately in the pipeline;
-- the Roblox-only MeshParts here are purpose-built test fixtures.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect


local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local Config = require("../../src/shared/Config")
local VisualTheme = require("../../src/shared/VisualTheme")
local ShrinkingArena = require("../../src/server/Disasters/ShrinkingArena")

describe("Harbor freight landing rim", function()
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
