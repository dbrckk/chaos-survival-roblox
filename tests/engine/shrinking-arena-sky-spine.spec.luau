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

describe("Sky Spine contraction", function()
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
                            local crown=arena.Decor[prefix.."_InterchangeCrown"]
                            local pulseZ=crown:GetAttribute("OriginalSkySpineCrosshead3D") and -1.27 or -.58
                            checkRouteSignal(deck,pulse,Vector3.new(13,.35,.7),
                                Vector3.new(0,deck.Size.Y*.5+12.7,pulseZ))
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
