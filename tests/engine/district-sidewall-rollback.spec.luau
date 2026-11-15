--!strict
-- Dedicated Roblox Engine regression for owner-approved 3D district
-- sidewall fallback. Kept separate to respect Open Cloud's 105KB/spec cap.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local ApprovedDistrictSidewallMeshKit = require(
    "../../src/client/ApprovedDistrictSidewallMeshKit")
local PremiumDistrictFacadeMeshKit = require(
    "../../src/client/PremiumDistrictFacadeMeshKit")
local ApprovedDistrictFoundationMeshKit = require(
    "../../src/client/ApprovedDistrictFoundationMeshKit")
local ApprovedDistrictRoofMeshKit = require(
    "../../src/client/ApprovedDistrictRoofMeshKit")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local VisualTheme = require("../../src/shared/VisualTheme")
local Config = require("../../src/shared/Config")
local Hero = require("../../src/client/ApprovedHeroStructureMeshKit")
local NorthSignature = require("../../src/client/ApprovedNorthSignatureFinishingMeshKit")

describe("Authenticated district sidewall restoration (engine)", function()
    it("maintains each hero identity and independently restores its forged foundation and skyline fittings", function()
        local storage = game:GetService("ReplicatedStorage")
        local holders = {}
        local function make(folder,name,id,tag,rows)
            local holder = holders[folder]
            if not holder then
                holder = Instance.new("Folder")
                holder.Name = folder
                holder:SetAttribute("OwnerVerified",true)
                holder.Parent = storage
                holders[folder] = holder
            end
            local model = Instance.new("Model")
            model.Name = name
            model:SetAttribute("OwnerVerified",true)
            model:SetAttribute("CosmeticOnly",true)
            model:SetAttribute("Original3DAssetId",id)
            model:SetAttribute(tag,true)
            for i=1,7 do
                local row = rows[i] or {.1,.1,.1,0,0,0}
                local part = Instance.new("MeshPart")
                part.Name = "Mesh"..i
                part.Anchored = true
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.Size = Vector3.new(row[1],row[2],row[3])
                part.Position = Vector3.new(row[4] or 0,row[5] or 0,row[6] or 0)
                part.Parent = model
            end
            model.Parent = holder
            return model
        end
        local body = {}
        body.Classic = make("ApprovedClassicSignatureObservatoryTemplates","DualDishObservatory",
            112493873850364,"OriginalClassicDualDishObservatory3D",{
                {1.03,15.0875,1.71},{.6975,12.085,9.105,0,-.2312},
                {.7338,5.1625,9.07,.1344,4.0025},{.4594,13.8531,6.6175,.2259,.6141},
                {.7155,14.1883,8.9772,.1227,.3503},
            })
        body.Harbor = make("ApprovedSouthHarborDrydockTemplates","SculptedDrydock",
            125428569657840,"OriginalSouthHarborSculptedDrydock3D",{
                {16.5357,18.3643,4.4107},{15.215,17.9729,4.6007,0,-.04566},
                {14.6429,17.1089,3.2214,0,.13484},
            })
        body.Towers = make("ApprovedHeroStructureTemplates","sky_transit_exchange",
            95878714550124,"ApprovedHero3D",{{32,27.8,15},{12,2,1,0,4,-6}})
        body.Crossroads = make("ApprovedHeroStructureTemplates","plasma_foundry",
            95926792159328,"ApprovedHero3D",{{30,27.615,14}})
        body.Orbital = make("ApprovedHeroStructureTemplates","orbital_halo_array",
            135985134195364,"ApprovedHero3D",{{22.748,30.213,12},{25*.5,2,1,0,4,-4}})
        local mast = make("ApprovedVariantIdentitySpineTemplates","Towers",
            86423178125318,"OriginalVariantIdentitySpine3D",{
                {2.52,19.92,2.52,0,-.02781},{2.29954,19.52,2.23955,0,-.02781},
                {.1,.1,.1,0,9.93781},
            })
        make("ApprovedOrbitalReactorLandmarkTemplates","Strut",138666009076890,
            "OriginalOrbitalReactorLandmark3D",{{1.10,1.24,8.46},{.872,.8638,7.96}})
        local lens = make("ApprovedOrbitalReactorLandmarkTemplates","Node",104654294187035,
            "OriginalOrbitalReactorLandmark3D",{{4.36,4.36,4.36},{2.96,2.9503,2.96},{4.11,4.11,.39}})
        local bridge = make("ApprovedCrossroadsSignatureInterchangeTemplates","ForgedInterchange",
            96622579843060,"OriginalCrossroadsSignatureInterchange3D",{
                {45.04,11.12,5.9,0,-.43},{47.68,2.3458,5.3,0,2.9871},
                {46.409,9.4952,5.244,0,.9964},{47.42,6.8,6.76,0,-.71},
                {44.93,2.3475,5.26,0,4.57029},
            })
        local foot = make("ApprovedHarborDockCaissonTemplates","DockCaisson",101457508594609,
            "OriginalHarborDockCaisson3D",{
                {12.82,2.69,12.82,0,.29378},{13.54,2.95755,13.54,0,-.175},
                {14.07,1.865,14.07,0,-.6937},{13.54,.35,13.54,0,1.47878},
            })
        local signature = {
            Classic={"ObservatoryFoundation","StormDishArc1",nil,nil},
            Towers={"TransitFoundation","SuspendedTransitCabin-1","SkyTransitSignalCrown",mast},
            Crossroads={"SwitchyardFoundation","ExchangeCore","NorthConduit",bridge},
            Orbital={"MagneticPlatform","OrbitalOuterArc1","HaloLens",lens},
            Harbor={"HarborDrydockFoundation","CargoHull",nil,nil},
        }
        local bucket = assert(workspace:FindFirstChild("ApprovedOriginalHeroStructuresLocal"))
        local hidden = 0
        for _,variant in ipairs(ArenaVariants.Order) do
            local arena = MapBuilder.buildArena(Config,variant,ArenaVariants,VisualTheme)
            local base,decor = arena.Base,arena.Decor
            local native = decor.ArenaHeroArchitecture3D
            local names = signature[variant]
            local foundation,landmark = native[names[1]],native[names[2]]
            local origin = native:GetAttribute("HeroOrigin")
            local partCount = native:GetAttribute("HeroArchitectureParts")
            local nativeAlpha = landmark.Transparency
            local point = base.Position
            local function sync(pressure)
                Hero.sync(arena,point,"Low",true,pressure)
            end
            sync(0)
            local sculpture = assert(bucket:FindFirstChild("ApprovedOriginalHero3D_"..variant),variant.." missing hero")
            assert(Hero.replacedNativeCount() == partCount and foundation.Transparency == 1,variant.." native coverage")
            hidden += partCount
            assert(sculpture:GetAttribute("Original3DAssetId") == body[variant]:GetAttribute("Original3DAssetId"))
            for _,part in ipairs(sculpture:GetDescendants()) do
                if part:IsA("BasePart") then
                    assert(part:IsA("MeshPart") and part.Anchored and part.Massless
                        and not part.CanCollide and not part.CanTouch and not part.CanQuery)
                end
            end
            if variant == "Classic" then
                assert(sculpture.Mesh4.Position.X < origin.Position.X, "dish glazing points away from arena")
                assert(sculpture:FindFirstChild("Mesh5"), "dish bracing is missing")
            elseif variant == "Crossroads" then
                local pieces = sculpture.ForgedHeroFittings:GetChildren()
                local mastBottom = math.huge
                for _,piece in ipairs(pieces) do
                    if piece:GetAttribute("Original3DAssetId") == 86423178125318 then
                        mastBottom = math.min(mastBottom,piece.Position.Y-piece.Size.Y*.5)
                    end
                end
                assert(math.abs(mastBottom-origin.Position.Y-22.34) < .12)
            elseif variant == "Orbital" or variant == "Harbor" then
                -- GetBoundingBox can express bounds in the model's pivot
                -- axes. Project the long side of the body onto world axes.
                local mass = sculpture.Mesh1
                local long = mass.Size.X > mass.Size.Z and mass.CFrame.RightVector
                    or mass.CFrame.LookVector
                assert(math.abs(long:Dot(Vector3.zAxis)) > .999,variant.." monument faces edge-on")
            end
            local size = base.Size
            base.Size = Vector3.new(size.X*.7,size.Y,size.Z*.7)
            sync(0)
            assert(sculpture.Parent == bucket and Hero.replacedNativeCount() == partCount)
            foot.Parent:SetAttribute("OwnerVerified",false)
            task.wait()
            assert(foundation.Transparency < 1 and landmark.Transparency == 1)
            foot.Parent:SetAttribute("OwnerVerified",true)
            if names[3] then
                local fitting = native[names[3]]
                local source = names[4]
                local piece = source.Mesh1
                piece.Parent = nil
                task.wait()
                assert(fitting.Transparency < 1 and landmark.Transparency == 1)
                piece.Parent = source
            end
            sync(0)
            assert(foundation.Transparency == 1 and Hero.replacedNativeCount() == partCount)
            sync(1)
            assert(foundation.Transparency < 1 and landmark.Transparency == 1)
            sync(0)
            local mesh = sculpture:FindFirstChildWhichIsA("MeshPart")
            mesh:Destroy()
            task.wait()
            assert(Hero.count() == 0 and math.abs(landmark.Transparency-nativeAlpha) < .001)
            sync(0)
            assert(Hero.count() == 1)
            sync(2)
            assert(Hero.count() == 0 and math.abs(landmark.Transparency-nativeAlpha) < .001)
            Hero.sync(nil,Vector3.zero,"Low",false)
            arena.Parent:Destroy()
        end
        expect(hidden).toBe(124)
        for _,holder in pairs(holders) do holder:Destroy() end
    end)
    it("finishes the five north signatures and restores only the affected native assemblies", function()
        local storage = game:GetService("ReplicatedStorage")
        local holders = {}
        local function make(folder,name,id,tag,rows)
            local holder = holders[folder]
            if not holder then
                holder = Instance.new("Folder")
                holder.Name = folder
                holder:SetAttribute("OwnerVerified",true)
                holder.Parent = storage
                holders[folder] = holder
            end
            local model = Instance.new("Model")
            model.Name = name
            model:SetAttribute("OwnerVerified",true)
            model:SetAttribute("CosmeticOnly",true)
            model:SetAttribute("Original3DAssetId",id)
            model:SetAttribute(tag,true)
            for i=1,7 do
                local row = rows[i] or {.1,.1,.1}
                local part = Instance.new("MeshPart")
                part.Name = "Mesh"..i
                part.Size = Vector3.new(row[1],row[2],row[3])
                part.Position = Vector3.new(row[4] or 0,row[5] or 0,row[6] or 0)
                part.Anchored = true
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.Parent = model
            end
            model.Parent = holder
            return model
        end
        local foot = make("ApprovedHarborDockCaissonTemplates","DockCaisson",101457508594609,
            "OriginalHarborDockCaisson3D",{
                {12.82,2.69,12.82,0,.29378},{13.54,2.95755,13.54,0,-.175},
                {14.07,.1,14.07},
            })
        local tower = make("ApprovedExteriorTowerTemplates","Tower21",137744886537150,
            "OriginalExteriorTower3D",{
                {8.96,21,7.8,0,-.6},{11.84,19.47912,9.84,0,1.36044},
                {10.86,1.2275,7.85,0,10.47875},{2.2,.009,.12,0,11.095,-4.43},
            })
        make("ApprovedPerimeterArmorTemplates","Cap",88962643359267,
            "OriginalPerimeterArmor3D",{{2.7699,2.14,2.34},{2.4566,.4494,1.7784,0,-.5564}})
        make("ApprovedVariantIdentitySpineTemplates","Towers",86423178125318,
            "OriginalVariantIdentitySpine3D",{
                {2.52,19.92,2.52,0,-.02781},{2.29954,19.52,2.23955,0,-.02781},
                {.1,.1,.1,0,9.93781},
            })
        make("ApprovedOrbitalReactorLandmarkTemplates","Node",104654294187035,
            "OriginalOrbitalReactorLandmark3D",{{4.36,4.36,4.36},{2.96,2.9503,2.96},{4.11,4.11,.39}})
        local strut = make("ApprovedOrbitalReactorLandmarkTemplates","Strut",138666009076890,
            "OriginalOrbitalReactorLandmark3D",{{1.1,1.24,8.46},{.872,.8638,7.96}})
        local bucket = assert(workspace:FindFirstChild("ApprovedNorthSignatureFinishingLocal"))
        local counts = {Classic=2,Towers=11,Crossroads=9,Orbital=8,Harbor=13}
        local existing = {
            Classic="ReceiverDishWest",Towers="OverheadServiceBridge",
            Crossroads="UpperExchange",Orbital="ReactorArc1",Harbor="QuayCraneSpanningBeam",
        }
        local total = 0
        for _,variant in ipairs(ArenaVariants.Order) do
            local arena = MapBuilder.buildArena(Config,variant,ArenaVariants,VisualTheme)
            local base = arena.Base
            local owner = arena.Decor.ArenaSignatureMegastructure
            local originals = {}
            for _,part in ipairs(owner:GetChildren()) do originals[part] = part.Transparency end
            local function sync(tier,pressure)
                NorthSignature.sync(arena,base.Position,tier,true,pressure)
            end
            sync("High",0)
            assert(NorthSignature.replacedNativeCount() == counts[variant],
                variant.." masked "..NorthSignature.replacedNativeCount().." north native parts")
            assert(NorthSignature.count() <= 24 and NorthSignature.count() >= counts[variant])
            assert(owner[existing[variant]].Transparency == originals[owner[existing[variant]]])
            assert(owner.Foundation.Transparency == 1 and owner.InsetBase.Transparency == 1)
            total += NorthSignature.replacedNativeCount()
            for _,group in ipairs(bucket:GetChildren()) do
                assert(group:IsA("Model"))
                for _,part in ipairs(group:GetChildren()) do
                    assert(part:IsA("MeshPart") and part.Anchored and part.Massless
                        and not part.CanCollide and not part.CanTouch and not part.CanQuery)
                end
            end

            local foundation = bucket.ForgedFoundation
            local originalSize = base.Size
            base.Size = Vector3.new(originalSize.X*.62,originalSize.Y,originalSize.Z*.62)
            task.wait()
            sync("High",0)
            assert(foundation.Parent == bucket and NorthSignature.replacedNativeCount() == counts[variant])
            if variant == "Harbor" then
                local hoist = bucket.QuayHoistPort:FindFirstChildWhichIsA("MeshPart")
                local axis = hoist.Size.X > hoist.Size.Z and hoist.CFrame.RightVector or hoist.CFrame.LookVector
                assert(math.abs(axis:Dot(Vector3.yAxis)) > .999 and math.max(hoist.Size.X,hoist.Size.Z) >= 16.9)
                assert((hoist.Position-owner.QuayHoistPort.Position).Magnitude < .12)
                tower:SetAttribute("Original3DAssetId",1)
                task.wait()
                assert(owner.QuayPortLeg.Transparency < 1 and owner.QuayStarboardLeg.Transparency < 1)
                assert(owner.Foundation.Transparency == 1 and owner.QuayHoistPort.Transparency == 1)
                tower:SetAttribute("Original3DAssetId",137744886537150)
                local strutMesh = strut.Mesh1
                strutMesh.Parent = nil
                task.wait()
                assert(owner.QuayHoistPort.Transparency < 1 and owner.QuayRakerPort.Transparency < 1
                    and owner.QuaySpreader.Transparency < 1 and owner.QuayWinchPort.Transparency == 1)
                strutMesh.Parent = strut
                sync("High",0)
                assert(NorthSignature.replacedNativeCount() == 13)
                sync("Medium",0)
                assert(NorthSignature.count() <= 16 and owner.QuayStormMast.Transparency < 1)
                sync("Low",0)
                assert(NorthSignature.count() == 8 and owner.QuayPortLeg.Transparency == 1)
                sync("High",0)
                local leg = owner.QuayPortLeg
                leg.CanQuery = true
                task.wait()
                assert(leg.Transparency < 1 and owner.QuayStarboardLeg.Transparency == 1)
                leg.CanQuery = false
            end

            local forgedMesh = foundation:FindFirstChildWhichIsA("MeshPart")
            forgedMesh:Destroy()
            task.wait()
            assert(owner.Foundation.Transparency == originals[owner.Foundation]
                and owner.InsetBase.Transparency == originals[owner.InsetBase])
            foot.Parent:SetAttribute("OwnerVerified",false)
            sync("High",0)
            assert(not bucket:FindFirstChild("ForgedFoundation"))
            foot.Parent:SetAttribute("OwnerVerified",true)
            sync("High",0)
            NorthSignature.sync(arena,base.Position+Vector3.new(900,0,0),"High",true,0)
            assert(NorthSignature.count() == 0 and owner.Foundation.Transparency < 1)
            sync("High",0)
            sync("High",1)
            assert(NorthSignature.count() == 0 and #bucket:GetChildren() == 0)
            for part,alpha in pairs(originals) do
                assert(part.Transparency == alpha,variant.." incomplete fallback for "..part.Name)
            end
            sync("High",0)
            owner.Parent = nil
            task.wait()
            assert(NorthSignature.replacedNativeCount() == 0 and owner.Foundation.Transparency < 1)
            owner:Destroy()
            arena.Parent:Destroy()
        end
        expect(total).toBe(43)
        for _,holder in pairs(holders) do holder:Destroy() end
    end)
    it("restores five native district sidewalls immediately on revoked source or native mutation", function()
        local ReplicatedStorage=game:GetService("ReplicatedStorage")
        local previousMap=workspace:FindFirstChild("GeneratedMap")
        local previous=ReplicatedStorage:FindFirstChild(
            "ApprovedDistrictSidewallShellTemplates")
        if previousMap then previousMap.Parent=nil end
        if previous then previous.Parent=nil end
        ApprovedDistrictSidewallMeshKit.sync(
            nil,Vector3.zero,"Low",false,false,0)
        local generated,templates
        local ok,why=pcall(function()
            local arena=MapBuilder.buildArena(Config,"Classic",
                ArenaVariants,VisualTheme)
            generated=arena.Parent
            local district=arena:FindFirstChild("Decor")
                :FindFirstChild("ArenaDistrictArchitecture3D")
            local building=district:FindFirstChild("DistrictNorth1")
            local door=building:FindFirstChild("ServiceEntryDoor")
            local core=building:FindFirstChild("ServiceCore")
            expect(door~=nil and core~=nil).toBe(true)
            local original=core.Transparency
            local source=Instance.new("Model")
            source.Name="Sidewall"
            source:SetAttribute("OwnerVerified",true)
            source:SetAttribute("CosmeticOnly",true)
            source:SetAttribute("OriginalDistrictSidewallShell3D",true)
            source:SetAttribute("Original3DAssetId",77387019170428)
            for i=1,6 do
                local piece=Instance.new("MeshPart")
                piece.Name="ApprovedMaterial"..i
                piece.Size=if i==1 then Vector3.new(10.5,13.2,7.4)
                    else Vector3.new(.35,.35,.35)
                piece.Anchored=true
                piece.CanCollide=false
                piece.CanTouch=false
                piece.CanQuery=false
                piece.Parent=source
            end
            templates=Instance.new("Folder")
            templates.Name="ApprovedDistrictSidewallShellTemplates"
            templates:SetAttribute("OwnerVerified",true)
            templates.Parent=ReplicatedStorage
            source.Parent=templates
            local camera=door.Position+Vector3.new(0,5,0)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"Medium",true,true,0,door.CFrame.LookVector)
            expect(building:GetAttribute(
                "LocalApprovedDistrictSidewallMounted")).toBe(true)
            expect(core.Transparency).toBe(1)
            expect(ApprovedDistrictSidewallMeshKit.count()>0).toBe(true)
            -- Actual Classic MapBuilder has 16 physical district owners.
            -- Healthy desktop Medium completes EIGHT side/back 3D shells
            -- inside the central camera range; mobile stays capped at 3.
            -- Pressure 1 halves the desktop limit; pressure 2 revokes
            -- all shells with immediate five-native restoration.
            local centralCamera=arena:FindFirstChild("Base").Position
                + Vector3.new(0,7,0)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,centralCamera,"Medium",true,false,0,Vector3.new(0,0,1))
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(8)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,centralCamera,"Medium",true,true,0,Vector3.new(0,0,1))
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(3)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,centralCamera,"Medium",true,false,1,Vector3.new(0,0,1))
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(4)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,centralCamera,"Medium",true,true,2,Vector3.new(0,0,1))
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(0)
            expect(core.Transparency).toBe(original)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"Medium",true,true,0,door.CFrame.LookVector)
            expect(core.Transparency).toBe(1)
            source:SetAttribute("OwnerVerified",false)
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(0)
            expect(core.Transparency).toBe(original)
            source:SetAttribute("OwnerVerified",true)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"Medium",true,true,0,door.CFrame.LookVector)
            expect(building:GetAttribute(
                "LocalApprovedDistrictSidewallMounted")).toBe(true)
            local originalSize=core.Size
            core.Size=originalSize+Vector3.new(1,0,0)
            expect(building:GetAttribute(
                "LocalApprovedDistrictSidewallMounted")).toBe(nil)
            expect(core.Transparency).toBe(original)
            core.Size=originalSize
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"Medium",true,true,0,door.CFrame.LookVector)
            expect(building:GetAttribute(
                "LocalApprovedDistrictSidewallMounted")).toBe(true)
            -- In-place mutations do not emit DescendantAdded/Removing.
            -- Both the source and the mounted six-piece clone must
            -- reveal all five real native masses synchronously.
            local sourcePiece=source:FindFirstChild("ApprovedMaterial1")
            local approvedSize=sourcePiece.Size
            sourcePiece.Size=approvedSize+Vector3.new(.2,0,0)
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(0)
            expect(core.Transparency).toBe(original)
            sourcePiece.Size=approvedSize
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"Medium",true,true,0,door.CFrame.LookVector)
            expect(building:GetAttribute(
                "LocalApprovedDistrictSidewallMounted")).toBe(true)
            local cloneFolder=workspace:FindFirstChild(
                "ApprovedDistrictSidewallsLocal")
            local clone=nil
            for _, resident in ipairs(cloneFolder:GetChildren()) do
                if resident:GetAttribute("DistrictIndex") ==
                    building:GetAttribute("DistrictIndex") then
                    clone=resident
                    break
                end
            end
            expect(clone~=nil).toBe(true)
            local clonePiece=clone:FindFirstChild("ApprovedMaterial1")
            expect(clonePiece~=nil).toBe(true)
            local beforeCloneMutation=ApprovedDistrictSidewallMeshKit.count()
            clonePiece.CanQuery=true
            -- A clone belongs to exactly ONE building: revoke only that
            -- owner's shell, not other intact approved district models.
            expect(ApprovedDistrictSidewallMeshKit.count())
                .toBe(beforeCloneMutation-1)
            expect(building:GetAttribute(
                "LocalApprovedDistrictSidewallMounted")).toBe(nil)
            expect(core.Transparency).toBe(original)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"Medium",true,true,0,door.CFrame.LookVector)
            expect(building:GetAttribute(
                "LocalApprovedDistrictSidewallMounted")).toBe(true)
            local injected=Instance.new("Part")
            injected.Parent=source
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(0)
            expect(core.Transparency).toBe(original)
            injected:Destroy()
            expect(door.CanCollide or door.CanTouch or door.CanQuery)
                .toBe(false)
        end)
        ApprovedDistrictSidewallMeshKit.sync(
            nil,Vector3.zero,"Low",false,false,0)
        if templates then templates:Destroy() end
        if generated then generated:Destroy() end
        if previous then previous.Parent=ReplicatedStorage end
        if previousMap then previousMap.Parent=workspace end
        if not ok then error(why) end
    end)
    it("completes desktop Medium 3D envelopes across real 16 district owners without raising Android budgets",function()
        local RS=game:GetService("ReplicatedStorage")
        local oldMap=workspace:FindFirstChild("GeneratedMap")
        local oldFacade=RS:FindFirstChild("ApprovedDistrictFacadeTemplates")
        local oldSidewall=RS:FindFirstChild(
            "ApprovedDistrictSidewallShellTemplates")
        local oldCaisson=RS:FindFirstChild("ApprovedHarborDockCaissonTemplates")
        if oldMap then oldMap.Parent=nil end
        if oldFacade then oldFacade.Parent=nil end
        if oldSidewall then oldSidewall.Parent=nil end
        if oldCaisson then oldCaisson.Parent=nil end
        PremiumDistrictFacadeMeshKit.sync(
            nil,Vector3.zero,"Low",false)
        ApprovedDistrictSidewallMeshKit.sync(
            nil,Vector3.zero,"Low",false,false,0)
        local generated,facades,shells,caissons
        local roofFixtures, previousRoofSources = {}, {}
        local ok,why=pcall(function()
            local arena=MapBuilder.buildArena(Config,"Classic",
                ArenaVariants,VisualTheme)
            generated=arena.Parent
            facades=Instance.new("Folder")
            facades.Name="ApprovedDistrictFacadeTemplates"
            facades:SetAttribute("OwnerVerified",true)
            facades.Parent=RS
            local ids={132020956214241,88725004643299,
                84217436280282,135791763112202}
            local names={"Observatory","Freight","Turbine","Aerial"}
            for i,name in ipairs(names) do
                local model=Instance.new("Model")
                model.Name=name
                model:SetAttribute("OwnerVerified",true)
                model:SetAttribute("CosmeticOnly",true)
                model:SetAttribute("DistrictFacade3D",true)
                model:SetAttribute("Original3DAssetId",ids[i])
                local piece=Instance.new("MeshPart")
                piece.Name="VerifiedFacadeMaterial"
                piece.Size=Vector3.new(12,20,8)
                piece.Anchored=true
                piece.CanCollide=false
                piece.CanTouch=false
                piece.CanQuery=false
                piece.Parent=model
                model.Parent=facades
            end
            shells=Instance.new("Folder")
            shells.Name="ApprovedDistrictSidewallShellTemplates"
            shells:SetAttribute("OwnerVerified",true)
            shells.Parent=RS
            local shell=Instance.new("Model")
            shell.Name="Sidewall"
            shell:SetAttribute("OwnerVerified",true)
            shell:SetAttribute("CosmeticOnly",true)
            shell:SetAttribute("OriginalDistrictSidewallShell3D",true)
            shell:SetAttribute("Original3DAssetId",77387019170428)
            for i=1,6 do
                local piece=Instance.new("MeshPart")
                piece.Name="ApprovedMaterial"..i
                piece.Size=if i==1 then Vector3.new(10.5,13.2,7.4)
                    else Vector3.new(.35,.35,.35)
                piece.Anchored=true
                piece.CanCollide=false
                piece.CanTouch=false
                piece.CanQuery=false
                piece.Parent=shell
            end
            shell.Parent=shells
            caissons=Instance.new("Folder")
            caissons.Name="ApprovedHarborDockCaissonTemplates"
            caissons:SetAttribute("OwnerVerified",true)
            caissons.Parent=RS
            local caisson=Instance.new("Model")
            caisson.Name="DockCaisson"
            caisson:SetAttribute("OwnerVerified",true)
            caisson:SetAttribute("CosmeticOnly",true)
            caisson:SetAttribute("OriginalHarborDockCaisson3D",true)
            caisson:SetAttribute("Original3DAssetId",101457508594609)
            for i=1,7 do
                local piece=Instance.new("MeshPart")
                piece.Size=if i==1 then Vector3.new(14.07,3.30755,14.07)
                    else Vector3.new(.4,.4,.4)
                piece.Anchored=true
                piece.Massless=true
                piece.CanCollide=false
                piece.CanQuery=false
                piece.CanTouch=false
                piece.Parent=caisson
            end
            caisson.Parent=caissons
            local base=arena:FindFirstChild("Base")
            local district=arena:FindFirstChild("Decor")
                :FindFirstChild("ArenaDistrictArchitecture3D")
            local near = district.DistrictNorth2
            local complete = district.DistrictNorth3
            local nearDoor = near.ServiceEntryDoor
            local completeDoor = complete.ServiceEntryDoor
            local pairCamera = nearDoor.Position:Lerp(completeDoor.Position, .42)
                + Vector3.new(0, 7, 0)
            local pairLook = -nearDoor.CFrame.LookVector
            local nearCore = near.ServiceCore
            local originalSize = nearCore.Size
            local completeCore = complete.ServiceCore
            local originalAlpha = completeCore.Transparency
            -- An incompatible streamed native prevents a complete shell
            -- on the nearer building. The other building still fits Low.
            nearCore.Size = originalSize + Vector3.new(1, 0, 0)
            local function syncLow(pressure)
                PremiumDistrictFacadeMeshKit.sync(
                    arena, pairCamera, "Low", true, pairLook, true, pressure,
                    if pressure == 0
                        then ApprovedDistrictSidewallMeshKit.lowPairingCheck() else nil)
                ApprovedDistrictSidewallMeshKit.sync(
                    arena, pairCamera, "Low", true, true, pressure, pairLook)
                ApprovedDistrictFoundationMeshKit.sync(
                    arena, pairCamera, "Low", true, true, pressure, pairLook)
            end
            syncLow(0)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(1)
            expect(near:GetAttribute("LocalApprovedDistrictFacadeMounted")).toBe(nil)
            expect(complete:GetAttribute("LocalApprovedDistrictFacadeMounted")).toBe(true)
            expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(1)
            expect(ApprovedDistrictSidewallMeshKit.replacedNativeCount()).toBe(5)
            expect(completeCore.Transparency).toBe(1)
            expect(ApprovedDistrictFoundationMeshKit.replacedNativeCount()).toBe(2)
            local foot, rim = complete.BasaltFoundation, complete.FoundationRim
            expect(foot.Transparency).toBe(1)
            expect(rim.Transparency).toBe(1)
            expect(near.BasaltFoundation.Transparency).toBe(0)
            expect(completeDoor.Transparency).toBe(0)
            local bases = workspace:FindFirstChild("ApprovedDistrictFoundationsLocal")
            local forged = bases:FindFirstChild("ApprovedOriginalDistrictFoundation3D")
            local frame, bounds = forged:GetBoundingBox()
            local floorY = base.Position.Y + base.Size.Y * .5
            expect(#forged:GetChildren()).toBe(7)
            assert(math.abs(frame.Position.Y - bounds.Y*.5 - floorY) < .03)
            assert(math.abs(frame.Position.Y + bounds.Y*.5 - floorY - .88) < .03)
            assert(math.max(bounds.X, bounds.Z) <= 15.5)
            for _, mesh in ipairs(forged:GetChildren()) do
                assert(mesh:IsA("MeshPart") and not mesh.CanCollide
                    and not mesh.CanTouch and not mesh.CanQuery)
            end
            forged:FindFirstChildWhichIsA("MeshPart"):Destroy()
            task.wait()
            expect(ApprovedDistrictFoundationMeshKit.replacedNativeCount()).toBe(0)
            expect(foot.Transparency).toBe(0)
            syncLow(0)
            caissons:SetAttribute("OwnerVerified", false)
            task.wait()
            expect(rim.Transparency).toBe(0)
            expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(1)
            caissons:SetAttribute("OwnerVerified", true)
            syncLow(0)
            base.Size = Vector3.new(base.Size.X*.7,base.Size.Y,base.Size.Z*.7)
            syncLow(0)
            expect(ApprovedDistrictFoundationMeshKit.replacedNativeCount()).toBe(2)
            base.Size = Vector3.new(base:GetAttribute("OriginalSizeX"),base.Size.Y,
                base:GetAttribute("OriginalSizeZ"))

            -- A revoked shell source leaves the nearest facade eligible.
            shells:SetAttribute("OwnerVerified", false)
            syncLow(0)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(1)
            expect(near:GetAttribute("LocalApprovedDistrictFacadeMounted")).toBe(true)
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(0)
            expect(completeCore.Transparency).toBe(originalAlpha)
            expect(ApprovedDistrictFoundationMeshKit.replacedNativeCount()).toBe(0)
            expect(rim.Transparency).toBe(0)
            shells:SetAttribute("OwnerVerified", true)
            syncLow(0)
            expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(1)
            syncLow(1)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(0)
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(0)
            expect(completeCore.Transparency).toBe(originalAlpha)
            nearCore.Size = originalSize

            -- At this elevation, even the closest authentic door is
            -- beyond the old Low range but within the new shared range.
            local highCamera = Vector3.new(base.Position.X,
                nearDoor.Position.Y + 70, base.Position.Z)
            local closest = math.huge
            for _, owner in ipairs(district:GetChildren()) do
                closest = math.min(closest,
                    (owner.ServiceEntryDoor.Position - highCamera).Magnitude)
            end
            assert(closest > 130 and closest <= 145, "Low range fixture drifted")
            PremiumDistrictFacadeMeshKit.sync(
                arena, highCamera, "Low", true, Vector3.zero, true, 0,
                ApprovedDistrictSidewallMeshKit.lowPairingCheck())
            ApprovedDistrictSidewallMeshKit.sync(
                arena, highCamera, "Low", true, true, 0)
            expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(1)
            expect(ApprovedDistrictSidewallMeshKit.replacedNativeCount()).toBe(5)
            syncLow(1)

            local camera=base.Position+Vector3.new(0,7,0)
            local look=Vector3.new(0,0,1)
            PremiumDistrictFacadeMeshKit.sync(
                arena,camera,"Medium",true,look,false,0)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"Medium",true,false,0,look)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(8)
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(8)
            expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(8)
            expect(ApprovedDistrictSidewallMeshKit.replacedNativeCount())
                .toBe(40)
            expect(PremiumDistrictFacadeMeshKit.residentMask16())
                .toBe(ApprovedDistrictSidewallMeshKit.residentMask16())
            local sides={}
            local full=0
            for _,building in ipairs(district:GetChildren()) do
                if building:GetAttribute(
                    "LocalApprovedDistrictFacadeMounted")==true then
                    full+=1
                    expect(building:GetAttribute(
                        "LocalApprovedDistrictSidewallMounted")).toBe(true)
                    sides[building:GetAttribute("DistrictSide")]=true
                end
            end
            expect(full).toBe(8)
            local sectors=0
            for _ in pairs(sides) do sectors+=1 end
            expect(sectors>=3).toBe(true)
            -- A lower GPU tier preserves the old phone limits, even
            -- after the desktop distributed 8 authentic models.
            PremiumDistrictFacadeMeshKit.sync(
                arena,camera,"Medium",true,look,true,0)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"Medium",true,true,0,look)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(3)
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(3)
            expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(3)
            expect(PremiumDistrictFacadeMeshKit.residentMask16())
                .toBe(ApprovedDistrictSidewallMeshKit.residentMask16())
            -- Every reduced budget should finish verified real envelopes,
            -- rather than showing separate front-only and back-only art.
            PremiumDistrictFacadeMeshKit.sync(
                arena,camera,"Medium",true,look,false,1)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"Medium",true,false,1,look)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(4)
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(4)
            expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(4)
            expect(PremiumDistrictFacadeMeshKit.residentMask16())
                .toBe(ApprovedDistrictSidewallMeshKit.residentMask16())
            PremiumDistrictFacadeMeshKit.sync(
                arena,camera,"Medium",true,look,true,1)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"Medium",true,true,1,look)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(1)
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(1)
            expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(1)
            expect(PremiumDistrictFacadeMeshKit.residentMask16())
                .toBe(ApprovedDistrictSidewallMeshKit.residentMask16())
            PremiumDistrictFacadeMeshKit.sync(
                arena,camera,"High",true,look,true,0)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"High",true,true,0,look)
            -- Emit real source/camera ownership counts with the failure.
            -- The message distinguishes an import/selection miss from
            -- an actual front-and-shell pairing regression in Cloud.
            local highFront=PremiumDistrictFacadeMeshKit.count()
            local highShell=ApprovedDistrictSidewallMeshKit.count()
            local highPaired=ApprovedDistrictSidewallMeshKit.completeCount()
            if highFront~=8 or highShell~=8 or highPaired~=8 then
                local doorReady,coreReady,frontReady,fullyOpaque=0,0,0,0
                local bands={}
                for _,owner in ipairs(district:GetChildren()) do
                    local door=owner:FindFirstChild("ServiceEntryDoor")
                    local core=owner:FindFirstChild("ServiceCore")
                    local supportL=owner:FindFirstChild("ArmoredSupportL")
                    local supportR=owner:FindFirstChild("ArmoredSupportR")
                    local cassetteL=owner:FindFirstChild("SideCassette-1")
                    local cassetteR=owner:FindFirstChild("SideCassette1")
                    if door and door.Transparency<.7 and
                        door.LocalTransparencyModifier<.95 then doorReady+=1 end
                    if core and core.Transparency<1 then coreReady+=1 end
                    if owner:GetAttribute("LocalApprovedDistrictFacadeMounted")==true then
                        frontReady+=1
                    end
                    if core and supportL and supportR and cassetteL and cassetteR
                        and core.Transparency<1 and supportL.Transparency<1
                        and supportR.Transparency<1 and cassetteL.Transparency<1
                        and cassetteR.Transparency<1 then fullyOpaque+=1 end
                    local ix=owner:GetAttribute("DistrictIndex")
                    if type(ix)=="number" then
                        bands[#bands+1]=("%d:%s:%s"):format(ix,
                            owner:GetAttribute("LocalApprovedDistrictFacadeMounted")
                                and "F" or "_",
                            owner:GetAttribute("LocalApprovedDistrictSidewallMounted")
                                and "S" or "_")
                    end
                end
                error(("High touch expected 8/8/8, got %d/%d/%d masks %d/%d; doors=%d cores=%d frontFlags=%d opaque5=%d | %s")
                    :format(highFront,highShell,highPaired,
                        PremiumDistrictFacadeMeshKit.residentMask16(),
                        ApprovedDistrictSidewallMeshKit.residentMask16(),
                        doorReady,coreReady,frontReady,fullyOpaque,
                        table.concat(bands,",")))
            end
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(8)
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(8)
            expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(8)
            expect(PremiumDistrictFacadeMeshKit.residentMask16())
                .toBe(ApprovedDistrictSidewallMeshKit.residentMask16())
            PremiumDistrictFacadeMeshKit.sync(
                arena,camera,"High",true,look,true,1)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"High",true,true,1,look)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(4)
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(4)
            expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(4)
            expect(PremiumDistrictFacadeMeshKit.residentMask16())
                .toBe(ApprovedDistrictSidewallMeshKit.residentMask16())
            -- Desktop High pressure retains one extra facade; every
            -- retained shell must still be paired with a real front.
            PremiumDistrictFacadeMeshKit.sync(
                arena,camera,"High",true,look,false,1)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"High",true,false,1,look)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(6)
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(5)
            expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(5)
            local fronts=PremiumDistrictFacadeMeshKit.residentMask16()
            local sides=ApprovedDistrictSidewallMeshKit.residentMask16()
            expect(bit32.band(fronts,sides)).toBe(sides)
            PremiumDistrictFacadeMeshKit.sync(
                arena,camera,"Medium",true,look,true,2)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"Medium",true,true,2,look)
            expect(PremiumDistrictFacadeMeshKit.count()).toBe(0)
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(0)
            expect(base.CanCollide).toBe(true)
            PremiumDistrictFacadeMeshKit.sync(
                arena,camera,"Medium",true,look,false,0)
            ApprovedDistrictSidewallMeshKit.sync(
                arena,camera,"Medium",true,false,0,look)
            expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(8)

            -- Exercise the actual five MapBuilder districts and their
            -- approved-roof ownership independently of renderer assets.
            local roofProfiles = {
                Classic = {"ApprovedClassicSignatureObservatoryTemplates", "DualDishObservatory",
                    "OriginalClassicDualDishObservatory3D", 112493873850364,
                    Vector3.new(9.105,15.0875,1.03), "StormSensor", 5},
                Towers = {"ApprovedSouthTowersSkytransferTemplates", "ForgedSkytransfer",
                    "OriginalSouthTowersForgedSkytransfer3D", 120959181274080,
                    Vector3.new(19.65,4.42948,2.94874), "TransitCab", 6},
                Crossroads = {"ApprovedCrossroadsSignatureInterchangeTemplates", "ForgedInterchange",
                    "OriginalCrossroadsSignatureInterchange3D", 96622579843060,
                    Vector3.new(47.68,11.73404,6.76), "SwitchboardPanel", 6},
                Orbital = {"ApprovedOrbitalReactorLandmarkTemplates", "Node",
                    "OriginalOrbitalReactorLandmark3D", 104654294187035,
                    Vector3.new(4.36,4.36,4.36), "ReactorSphere", 6},
                Harbor = {"ApprovedHarborKineticGantryTemplates", "ContainerGantry",
                    "OriginalHarborKineticGantry3D", 75684193304551,
                    Vector3.new(21.86,36.08949,44), "HarborCargoHousing", 5},
            }
            local roofBucket = workspace:FindFirstChild("ApprovedDistrictRoofsLocal")
            for variant, profile in pairs(roofProfiles) do
                local previous = RS:FindFirstChild(profile[1])
                if previous then
                    table.insert(previousRoofSources, previous)
                    previous.Parent = nil
                end
                local holder = Instance.new("Folder")
                holder.Name = profile[1]
                holder:SetAttribute("OwnerVerified", true)
                holder.Parent = RS
                table.insert(roofFixtures, holder)
                local source = Instance.new("Model")
                source.Name = profile[2]
                source:SetAttribute("CosmeticOnly", true)
                source:SetAttribute("OwnerVerified", true)
                source:SetAttribute(profile[3], true)
                source:SetAttribute("Original3DAssetId", profile[4])
                for i = 1, 7 do
                    local piece = Instance.new("MeshPart")
                    piece.Size = if i == 1 then profile[5] else Vector3.one * .3
                    piece.Anchored = true
                    piece.Massless = true
                    piece.CanCollide = false
                    piece.CanTouch = false
                    piece.CanQuery = false
                    piece.Parent = source
                end
                source.Parent = holder
                local world = MapBuilder.buildArena(Config, variant, ArenaVariants, VisualTheme)
                local building = world.Decor.ArenaDistrictArchitecture3D.DistrictNorth1
                local door = building.ServiceEntryDoor
                local native = building:FindFirstChild(profile[6])
                local nativeAlpha = native.Transparency
                local eye = door.Position + door.CFrame.LookVector * 14 + Vector3.new(0, 17, 0)
                local function update(pressure)
                    ApprovedDistrictRoofMeshKit.sync(world, eye, "Low", true, true, pressure,
                        -door.CFrame.LookVector)
                end
                PremiumDistrictFacadeMeshKit.sync(world, eye, "Low", true,
                    -door.CFrame.LookVector, true, 0)
                expect(building:GetAttribute("LocalApprovedDistrictFacadeMounted")).toBe(true)
                update(0)
                expect(ApprovedDistrictRoofMeshKit.replacedNativeCount()).toBe(profile[7])
                expect(native.Transparency).toBe(1)
                assert(math.abs(building.RecessedSignal.Transparency - .32) < .001)
                local model = roofBucket:FindFirstChild("ApprovedOriginalDistrictRoof3D")
                local pose, bounds = model:GetBoundingBox()
                local floorY = world.Base.Position.Y + world.Base.Size.Y * .5
                assert(pose.Y - bounds.Y * .5 > floorY + 14.45, variant .. " roof overlaps ground")
                assert(pose.Y + bounds.Y * .5 < floorY + 31, variant .. " roof exceeds clearance")
                expect(model:GetAttribute("Original3DAssetId")).toBe(profile[4])
                expect(#model:GetChildren()).toBe(7)
                for _, part in ipairs(model:GetChildren()) do
                    assert(part:IsA("MeshPart") and not part.CanCollide
                        and not part.CanTouch and not part.CanQuery)
                end
                world.Base.Size *= Vector3.new(.65, 1, .65)
                update(0)
                expect(ApprovedDistrictRoofMeshKit.replacedNativeCount()).toBe(profile[7])
                model:FindFirstChildWhichIsA("MeshPart"):Destroy()
                task.wait()
                assert(math.abs(native.Transparency-nativeAlpha) < .001, variant)
                update(0)
                update(1)
                expect(ApprovedDistrictRoofMeshKit.replacedNativeCount()).toBe(0)
                update(0)
                building:SetAttribute("LocalApprovedDistrictFacadeMounted", nil)
                task.wait()
                assert(math.abs(native.Transparency-nativeAlpha) < .001, variant)
                building:SetAttribute("LocalApprovedDistrictFacadeMounted", true)
                update(0)
                holder:SetAttribute("OwnerVerified", false)
                task.wait()
                assert(math.abs(native.Transparency-nativeAlpha) < .001, variant)
            end
        end)
        ApprovedDistrictRoofMeshKit.sync(nil,Vector3.zero,"Low",false,true,0)
        ApprovedDistrictFoundationMeshKit.sync(nil,Vector3.zero,"Low",false,true,0)
        ApprovedDistrictSidewallMeshKit.sync(
            nil,Vector3.zero,"Low",false,false,0)
        PremiumDistrictFacadeMeshKit.sync(
            nil,Vector3.zero,"Low",false)
        if shells then shells:Destroy() end
        if caissons then caissons:Destroy() end
        if facades then facades:Destroy() end
        for _, holder in ipairs(roofFixtures) do holder:Destroy() end
        for _, holder in ipairs(previousRoofSources) do holder.Parent = RS end
        if generated then generated:Destroy() end
        if oldSidewall then oldSidewall.Parent=RS end
        if oldCaisson then oldCaisson.Parent=RS end
        if oldFacade then oldFacade.Parent=RS end
        if oldMap then oldMap.Parent=workspace end
        if not ok then error(why) end
    end)
end)

return nil
