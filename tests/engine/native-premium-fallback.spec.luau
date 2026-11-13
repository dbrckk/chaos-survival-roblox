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
local HarborHeroStationMeshKit = require("../../src/client/HarborHeroStationMeshKit")
local HarborMidgroundBargeMeshKit = require("../../src/client/HarborMidgroundBargeMeshKit")
local HarborSignatureGantryKit = require("../../src/client/ApprovedHarborSignatureGantryMeshKit")
local SouthHarborDrydockKit = require("../../src/client/ApprovedSouthHarborDrydockMeshKit")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local Config = require("../../src/shared/Config")

describe("Original 3D native fallback isolation (engine)", function()
    -- One-off evidence gathering for the full five-map premium visual audit.
    -- This temporary diagnostic emits authoritative server MapBuilder object
    -- counts as Lest failures so GitHub records actual cloud-engine evidence.
    -- Replace the diagnostic errors with permanent numeric assertions after
    -- harvesting the results, then verify all seven suites green.
    for _,variantId in ipairs(ArenaVariants.Order) do
        it("P4 five-world physical structure census "..variantId, function()
            local previous=workspace:FindFirstChild("GeneratedMap")
            if previous then previous.Parent=nil end
            local generated=nil
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
                local trimmed={}
                for i=1,math.min(#ordered,75) do
                    trimmed[i]=ordered[i]
                end
                return HttpService:JSONEncode({
                    variant=variantId,stats=stats,
                    groups=#ordered,
                    top75=trimmed,
                })
            end)
            if generated then generated:Destroy() end
            if previous then previous.Parent=workspace end
            if not ok then error("P4_CENSUS_ERROR "..variantId.." "..tostring(result)) end
            error("P4_CENSUS_ENGINE_REAL "..result)
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
