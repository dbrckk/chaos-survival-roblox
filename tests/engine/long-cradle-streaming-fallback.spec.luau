--!strict
-- Genuine MapBuilder decks and native decorative truss stream ownership.
-- No asset uploads or counterfeit published MeshIds; fixtures exist only
-- inside the isolated Roblox Cloud Engine test runtime.
local Lest=require("@lest")
local describe,it,expect=Lest.describe,Lest.it,Lest.expect
local MapBuilder=require("../../src/server/MapBuilder")
local Config=require("../../src/shared/Config")
local ArenaVariants=require("../../src/server/ArenaVariants")
local VisualTheme=require("../../src/shared/VisualTheme")
local Kit=require("../../src/client/PremiumLargeStructureMeshKit")
local Finish=require("../../src/client/PlatformFinishKit")
local Crown=require("../../src/client/SkySpineCrownMeshKit")
local IdentityLod=require("../../src/shared/PlatformIdentityLodRules")
local Remaining=require("../../src/client/ApprovedRemainingStructureMeshKit")

describe("P4 approved long cradle streaming fallback (engine)",function()
    it("uses complete genuine Promenade and SkySpine native underframes only",function()
        local RS=game:GetService("ReplicatedStorage")
        local previous=workspace:FindFirstChild("GeneratedMap")
        local oldTemplates=RS:FindFirstChild("ApprovedLargeStructureTemplates")
        if previous then previous.Parent=nil end
        if oldTemplates then oldTemplates.Parent=nil end
        local generated,templates,models=nil,nil,nil
        local ok,err=pcall(function()
            local arena=MapBuilder.buildArena(
                Config,"Crossroads",ArenaVariants,VisualTheme)
            generated=arena.Parent
            local base=arena:FindFirstChild("Base")
            local platforms=arena:FindFirstChild("Platforms")
            local decor=arena:FindFirstChild("Decor")
            local bounds=Vector3.new(22.6,3.0,9.8)
            templates=Instance.new("Folder")
            templates.Name="ApprovedLargeStructureTemplates"
            templates:SetAttribute("OwnerVerified",true)
            templates.Parent=RS
            local source=Instance.new("Model")
            source.Name="LongCradle"
            source:SetAttribute("Original3DAssetId",128914328933863)
            source:SetAttribute("OwnerVerified",true)
            source:SetAttribute("CosmeticOnly",true)
            source:SetAttribute("OriginalLargeStructure3D",true)
            for i=1,7 do
                local part=Instance.new("MeshPart")
                part.Name="OriginalMaterial"..i
                part.Size=i==1 and bounds or Vector3.new(.25,.25,.25)
                part.Anchored=true
                part.CanCollide=false
                part.CanTouch=false
                part.CanQuery=false
                part.Parent=source
            end
            source.Parent=templates
            -- Seven-material test-only fixture matching the exact Roblox
            -- Approved original created in action 43643193625.
            local shortBounds=Vector3.new(10.13,2.34,16.52)
            local shortSource=Instance.new("Model")
            shortSource.Name="ShortCradle"
            shortSource:SetAttribute("Original3DAssetId",140716716476069)
            shortSource:SetAttribute("OwnerVerified",true)
            shortSource:SetAttribute("CosmeticOnly",true)
            shortSource:SetAttribute("OriginalLargeStructure3D",true)
            for i=1,7 do
                local item=Instance.new("MeshPart")
                item.Name="ShortMaterial"..i
                item.Size=i==1 and shortBounds
                    or Vector3.new(.22,.22,.22)
                item.Anchored=true
                item.CanCollide=false
                item.CanTouch=false
                item.CanQuery=false
                item.Parent=shortSource
            end
            shortSource.Parent=templates
            models=Instance.new("Folder")
            models.Name="CradleStreamOriginalGeometry"
            models.Parent=workspace
            local owners={}
            for _,deck in ipairs(platforms:GetChildren()) do
                if deck:IsA("BasePart")
                    and Kit.hasNativeCradleFallback(decor,deck) then
                    if deck:GetAttribute("SkySpineStep")~=nil then
                        owners.SkySpine=deck
                    elseif deck:GetAttribute("PromenadeStep")~=nil
                        and Kit.cradleFit(deck.Size,bounds) then
                        owners.Promenade=deck
                    end
                end
            end
            expect(owners.SkySpine~=nil).toBe(true)
            expect(owners.Promenade~=nil).toBe(true)
            expect(Kit.shortCradleFit(
                owners.SkySpine.Size,shortBounds)~=nil).toBe(true)
            expect(Kit.shortCradleFit(
                owners.Promenade.Size,shortBounds)).toBe(nil)
            expect(Kit.shortCradleFit(
                Vector3.new(12,2,25),shortBounds)).toBe(nil)
            for kind,deck in pairs(owners) do
                local id=tonumber(deck.Name:match("^Platform(%d+)$"))
                expect(id~=nil and deck.Anchored and deck.CanCollide)
                    .toBe(true)
                local function selected()
                    local cradles=Kit.selectNearRouteStructures(
                        {deck},decor,"Crossroads","Medium",base,
                        deck.Position,Vector3.new(0,0,1),0)
                    return cradles[deck] == true
                end
                -- SkySpine is genuinely too short for the older 22-stud
                -- source; the new Approved 16.52-stud model fits instead.
                local longFit=Kit.cradleFit(deck.Size,bounds)~=nil
                local shortFit=kind=="SkySpine" and
                    Kit.shortCradleFit(deck.Size,shortBounds)~=nil
                local fitted=longFit or shortFit
                expect(selected()).toBe(fitted)
                if shortFit and not longFit then
                    shortSource:SetAttribute("Original3DAssetId",0)
                    expect(selected()).toBe(false)
                    expect(Kit.longCradle(models,deck,
                        "Medium",id,true,decor)).toBe(nil)
                    shortSource:SetAttribute(
                        "Original3DAssetId",140716716476069)
                    expect(selected()).toBe(true)
                end
                local underframe=decor:FindFirstChild(
                    "PlatformUnderFrame"..id)
                expect(underframe~=nil).toBe(true)
                -- Exact server-authored nonphysical structural piece
                -- drives event-based late-stream recovery; not a random
                -- gameplay or luminous part.
                expect(Kit.cradleStreamNativeIndex(underframe)).toBe(id)
                underframe.Parent=nil
                expect(Kit.cradleStreamNativeIndex(underframe)).toBe(id)
                expect(Kit.hasNativeCradleFallback(decor,deck)).toBe(false)
                expect(selected()).toBe(false)
                expect(Kit.longCradle(models,deck,"Medium",id,true,decor))
                    .toBe(nil)
                underframe.Parent=decor
                expect(selected()).toBe(fitted)
                local nativeName=kind=="SkySpine"
                    and "SkySpine"..id.."_CrossStiffener"
                    or "Promenade"..id.."_UnderdeckTruss"
                local native=decor:FindFirstChild(nativeName)
                expect(native~=nil).toBe(true)
                expect(Kit.cradleStreamNativeIndex(native)).toBe(id)
                native.Parent=nil
                expect(Kit.cradleStreamNativeIndex(native)).toBe(id)
                expect(Kit.hasNativeCradleFallback(decor,deck)).toBe(false)
                expect(selected()).toBe(false)
                native.Parent=decor
                native:SetAttribute("PerimeterPlatformIndex",-1)
                expect(Kit.cradleStreamNativeIndex(native)).toBe(nil)
                expect(selected()).toBe(false)
                native:SetAttribute("PerimeterPlatformIndex",id)
                expect(Kit.cradleStreamNativeIndex(native)).toBe(id)
                expect(selected()).toBe(fitted)
                if kind=="SkySpine" then
                    for _,suffix in ipairs({"_Undercarriage-1",
                        "_Undercarriage1"}) do
                        local side=decor:FindFirstChild(
                            "SkySpine"..id..suffix)
                        expect(side~=nil).toBe(true)
                        expect(Kit.cradleStreamNativeIndex(side)).toBe(id)
                    end
                end
                local decoy=Instance.new("Part")
                decoy.Name="SkySpine"..id.."_Warning"
                decoy.Anchored=true
                decoy.CanCollide=false
                decoy.CanTouch=false
                decoy.CanQuery=false
                decoy:SetAttribute("SkySpineDecor",true)
                decoy:SetAttribute("PerimeterPlatformIndex",id)
                expect(Kit.cradleStreamNativeIndex(decoy)).toBe(nil)
                decoy:Destroy()
                local parts=Kit.longCradle(models,deck,
                    "Medium",id,true,decor)
                if fitted then
                    expect(parts~=nil and #parts==7).toBe(true)
                    -- Real source is now mounted. Confirm native underside
                    -- fallback details disappear, but upper route paint
                    -- and the physical collision deck stay authoritative.
                    local palette={
                        Detail=Color3.fromRGB(176,186,193),
                        Secondary=Color3.fromRGB(112,157,187),
                        Structure=Color3.fromRGB(55,76,94),
                        Accent=Color3.fromRGB(112,194,221),
                        Surface=Color3.fromRGB(117,132,144),
                    }
                    local fallback=Finish.build(models,deck,"Towers",
                        "High",palette,false)
                    expect(#fallback).toBe(3)
                    for _,piece in ipairs(fallback) do piece:Destroy() end
                    local sculpted=Finish.build(models,deck,"Towers",
                        "High",palette,true)
                    expect(#sculpted).toBe(0)
                    local harbor=Finish.build(models,deck,"Harbor",
                        "High",palette,true)
                    expect(#harbor).toBe(2)
                    for _,piece in ipairs(harbor) do
                        expect(piece.CanCollide or piece.CanQuery
                            or piece.CanTouch).toBe(false)
                        piece:Destroy()
                    end
                    for _,piece in ipairs(parts) do
                        expect(piece:IsA("MeshPart")).toBe(true)
                        expect(piece.CanCollide or piece.CanTouch or piece.CanQuery)
                            .toBe(false)
                        expect(piece:GetAttribute("OriginalLongCradle3D"))
                            .toBe(true)
                        expect(piece:GetAttribute(
                            "OriginalShortSkySpineCradle3D")==true)
                            .toBe(shortFit and not longFit)
                        expect(piece:GetAttribute("Original3DAssetId"))
                            .toBe(shortFit and not longFit
                                and 140716716476069 or 128914328933863)
                        piece:Destroy()
                    end
                else
                    expect(parts).toBe(nil)
                end
                expect(deck.CanCollide).toBe(true)
            end
        end)
        if models then models:Destroy() end
        if templates then templates:Destroy() end
        if generated then generated:Destroy() end
        if oldTemplates then oldTemplates.Parent=RS end
        if previous then previous.Parent=workspace end
        if not ok then error(err) end
    end)

    it("fits approved promenade structures and equipment through shrink and streaming",function()
        local rs=game:GetService("ReplicatedStorage")
        local previous=workspace:FindFirstChild("GeneratedMap")
        local old=rs:FindFirstChild("ApprovedPerimeterStructuresTemplates")
        if previous then previous.Parent=nil end
        if old then old.Parent=nil end
        local previousSide=rs:FindFirstChild("ApprovedPlatformSideTemplates")
        if previousSide then previousSide.Parent=nil end
        local sideHolder=Instance.new("Folder")
        sideHolder.Name="ApprovedPlatformSideTemplates"
        sideHolder:SetAttribute("OwnerVerified",true)
        sideHolder.Parent=rs
        local holder=Instance.new("Folder")
        holder.Name="ApprovedPerimeterStructuresTemplates"
        holder:SetAttribute("OwnerVerified",true)
        holder.Parent=rs
        local source=Instance.new("Model")
        source.Name="Brace"
        source:SetAttribute("OwnerVerified",true)
        source:SetAttribute("CosmeticOnly",true)
        source:SetAttribute("OriginalPerimeterStructure3D",true)
        source:SetAttribute("Original3DAssetId",108452611210970)
        local main,detachable=nil,nil
        for i=1,7 do
            local part=Instance.new("MeshPart")
            part.Name="BraceMesh"..i
            part.Size=i==1 and Vector3.new(8.94,.5675,1.12)
                or Vector3.new(.16,.16,.16)
            part.Anchored=true
            part.Massless=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.Parent=source
            if i==1 then main=part end
            if i==7 then detachable=part end
        end
        source.Parent=holder
        local girder=source:Clone()
        girder.Name="Bridge"
        girder:SetAttribute("Original3DAssetId",122766792774607)
        girder:SetAttribute("OriginalStructuralSide3D",true)
        for _,piece in ipairs(girder:GetChildren()) do
            if piece.Size.X>8 then piece.Size=Vector3.new(9.62,1.505,.6175) end
        end
        girder.Parent=sideHolder
        local profiles={
            Classic={"ApprovedServiceEquipmentTemplates","Classic",
                "OriginalService3D",108954400662606,Vector3.new(2,3.712,1.625),
                {"SurveyDish","SurveyMast","SurveyTip"}},
            Towers={"ApprovedServiceEquipmentTemplates","Towers",
                "OriginalService3D",106083832432833,Vector3.new(3.08,2.32,2.6351),
                {"HoistMachine"}},
            Crossroads={"ApprovedCrossroadsGantryTemplates","Gantry",
                "OriginalCrossroadsGantry3D",90844491148907,Vector3.new(27.92,3.6,2.74),
                {"SignalConcourse","SwitchFin-1","SwitchFin1"}},
            Orbital={"ApprovedOrbitalReactorLandmarkTemplates","Node",
                "OriginalOrbitalReactorLandmark3D",104654294187035,Vector3.new(4.36,4.36,4.36),
                {"GyroCore"}},
        }
        local fittings={
            Towers={
                {"ApprovedOrbitalReactorLandmarkTemplates","Strut",
                    "OriginalOrbitalReactorLandmark3D",138666009076890,Vector3.new(8.46,1.24,1.10),
                    "HoistRail","Rail",5},
                {"ApprovedPerimeterArmorTemplates","Cap",
                    "OriginalPerimeterArmor3D",88962643359267,Vector3.new(2.7699,2.14,2.34),
                    "HoistBeacon","Beacon",.55},
            },
            Orbital={
                {"ApprovedClassicBroadcastFinTemplates","BroadcastFin",
                    "OriginalClassicBroadcastFin3D",123049626693705,Vector3.new(5.46,15.92,1.76),
                    "ContainmentFin-1","Fin",5.5},
                {"ApprovedClassicBroadcastFinTemplates","BroadcastFin",
                    "OriginalClassicBroadcastFin3D",123049626693705,Vector3.new(5.46,15.92,1.76),
                    "ContainmentFin1","Fin",5.5},
            },
        }
        local equipmentHolders,previousEquipment={},{}
        local function provide(profile)
            local folderName,name,tag,id,size=table.unpack(profile)
            local equipmentFolder=equipmentHolders[folderName]
            if not equipmentFolder then
                local existing=rs:FindFirstChild(folderName)
                if existing then
                    previousEquipment[folderName]=existing
                    existing.Parent=nil
                end
                equipmentFolder=Instance.new("Folder")
                equipmentFolder.Name=folderName
                equipmentFolder:SetAttribute("OwnerVerified",true)
                equipmentFolder.Parent=rs
                equipmentHolders[folderName]=equipmentFolder
            end
            if equipmentFolder:FindFirstChild(name) then return end
            local gear=source:Clone()
            gear.Name=name
            gear:SetAttribute(tag,true)
            gear:SetAttribute("Original3DAssetId",id)
            gear:FindFirstChild("BraceMesh1").Size=size
            gear.Parent=equipmentFolder
        end
        for _,profile in pairs(profiles) do provide(profile) end
        for _,pair in pairs(fittings) do
            for _,profile in ipairs(pair) do provide(profile) end
        end
        local generated=nil
        local ok,err=pcall(function()
            for _,variant in ipairs({"Classic","Towers","Crossroads","Orbital","Harbor"}) do
                local arena=MapBuilder.buildArena(Config,variant,ArenaVariants,VisualTheme)
                generated=arena.Parent
                local platforms=arena:FindFirstChild("Platforms")
                local decor=arena:FindFirstChild("Decor")
                local base=arena:FindFirstChild("Base")
                local crossheads={}
                local profile=profiles[variant]
                local fittingPair=fittings[variant]
                for _,deck in ipairs(platforms:GetChildren()) do
                    local index=deck.Name:match("^Platform(%d+)$")
                    local native=index and decor:FindFirstChild(
                        "Promenade"..index.."_MonumentalCrosshead")
                    if native then crossheads[deck]=native end
                end
                local total=0
                for _ in pairs(crossheads) do total+=1 end
                expect(total).toBe(6)
                Remaining.sync(arena,base.Position,"High",true,nil,0,false)
                expect(Remaining.count("promenade")).toBe(variant=="Harbor" and 0 or 6)
                expect(Remaining.count("stay")).toBe(variant=="Harbor" and 0 or 12)
                expect(Remaining.count("equipment")).toBe(profile and 6 or 0)
                expect(Remaining.count("fitting")).toBe(fittingPair and 12 or 0)
                expect(Remaining.nativeCount("equipment")).toBe(profile and 6*#profile[6] or 0)
                for deck,native in pairs(crossheads) do
                    expect(native.LocalTransparencyModifier).toBe(variant=="Harbor" and 0 or 1)
                    local index=deck.Name:match("^Platform(%d+)$")
                    local pylon=decor:FindFirstChild("Promenade"..index.."_LoadPylon1")
                    local underdeck=decor:FindFirstChild("Promenade"..index.."_UnderdeckTruss")
                    expect(pylon.LocalTransparencyModifier).toBe(0)
                    expect(underdeck.LocalTransparencyModifier).toBe(0)
                    for _,name in ipairs(profile and profile[6] or {}) do
                        local primitive=decor:FindFirstChild("Promenade"..index.."_"..name)
                        expect(primitive.LocalTransparencyModifier).toBe(1)
                    end
                    for _,fitting in ipairs(fittingPair or {}) do
                        local detail=decor:FindFirstChild("Promenade"..index.."_"..fitting[6])
                        expect(detail.LocalTransparencyModifier).toBe(1)
                    end
                    if variant=="Harbor" then
                        local detail=decor:FindFirstChild("Promenade"..index.."_SuspendedCrate")
                        expect(detail.LocalTransparencyModifier).toBe(0)
                    end
                    for _,side in ipairs({-1,1}) do
                        local diagonal=decor:FindFirstChild("Promenade"..index.."_DiagonalStay"..side)
                        expect(diagonal.LocalTransparencyModifier).toBe(variant=="Harbor" and 0 or 1)
                    end
                    expect(deck.CanCollide).toBe(true)
                end
                if fittingPair then
                    local deck,crosshead=next(crossheads)
                    local prefix="Promenade"..deck.Name:match("%d+").."_"
                    local a=decor:FindFirstChild(prefix..fittingPair[1][6])
                    local b=decor:FindFirstChild(prefix..fittingPair[2][6])
                    local function checkPair(alpha)
                        expect(a.LocalTransparencyModifier).toBe(alpha)
                        expect(b.LocalTransparencyModifier).toBe(alpha)
                    end
                    local function syncFittings(pressure)
                        Remaining.sync(arena,crosshead.Position,"Low",true,nil,pressure,true)
                    end
                    -- Drop the High residency bias before picking the nearest pair.
                    syncFittings(1)
                    syncFittings(0)
                    expect(Remaining.count("fitting")).toBe(2)
                    checkPair(1)
                    local folder=workspace:FindFirstChild("ApprovedRemainingStructureMeshesLocal")
                    local fitting=folder:FindFirstChild("ApprovedP4_"..fittingPair[1][7])
                    local lattice=fitting:FindFirstChild("BraceMesh1")
                    expect(fitting:GetAttribute("Original3DAssetId")).toBe(fittingPair[1][4])
                    expect((lattice.Position-a.Position).Magnitude<.04).toBe(true)
                    local frame=a.CFrame:ToObjectSpace(lattice.CFrame)
                    local verticalExtent=math.abs(frame.RightVector.Y)*lattice.Size.X
                        +math.abs(frame.UpVector.Y)*lattice.Size.Y
                        +math.abs(frame.LookVector.Y)*lattice.Size.Z
                    expect(math.abs(verticalExtent-fittingPair[1][8])<.12).toBe(true)
                    expect(lattice.CanCollide or lattice.CanTouch or lattice.CanQuery).toBe(false)
                    deck:SetAttribute("CollapsePhase","Warning")
                    checkPair(0)
                    deck:SetAttribute("CollapsePhase","Normal")
                    checkPair(1)
                    lattice:Destroy()
                    task.wait()
                    expect(Remaining.count("fitting")).toBe(0)
                    checkPair(0)
                    syncFittings(0)
                    checkPair(1)
                    local missingSource=equipmentHolders[fittingPair[2][1]]:FindFirstChild(fittingPair[2][2])
                    missingSource.Parent=nil
                    task.wait()
                    checkPair(0)
                    syncFittings(0)
                    expect(Remaining.count("fitting")).toBe(0)
                    missingSource.Parent=equipmentHolders[fittingPair[2][1]]
                    syncFittings(0)
                    checkPair(1)
                    local scale=.75
                    base.Size=Vector3.new(base.Size.X*scale,base.Size.Y,base.Size.Z*scale)
                    checkPair(0)
                    for _,part in ipairs({deck,crosshead,a,b}) do
                        local frame=deck.CFrame:ToObjectSpace(part.CFrame)
                        local offset=frame.Position
                        part.CFrame=deck.CFrame*CFrame.new(offset.X*scale,offset.Y,offset.Z*scale)
                            *(frame-offset)
                        part.Size=Vector3.new(part.Size.X*scale,part.Size.Y,part.Size.Z*scale)
                        if part~=b then checkPair(0) end
                    end
                    checkPair(1)
                    syncFittings(1)
                    expect(Remaining.count("fitting")).toBe(0)
                    checkPair(0)
                end
                if variant~="Crossroads" then continue end
                local deck,native=nil,nil
                for owner,part in pairs(crossheads) do
                    if owner:GetAttribute("PromenadeStep")==2
                        and owner:GetAttribute("PromenadeLane")==1 then
                        deck,native=owner,part
                        break
                    end
                end
                local bucket=workspace:FindFirstChild("ApprovedRemainingStructureMeshesLocal")
                local prefix="Promenade"..deck.Name:match("%d+").."_DiagonalStay"
                local stays={decor:FindFirstChild(prefix.."-1"),decor:FindFirstChild(prefix.."1")}
                Remaining.sync(arena,deck.Position,"High",true,nil,0,true)
                expect(Remaining.count("promenade")).toBe(3)
                expect(Remaining.count("stay")).toBe(2)
                local lost=bucket:FindFirstChild("ApprovedP4_Stay")
                local mesh=lost:FindFirstChildWhichIsA("MeshPart")
                mesh:Destroy()
                task.wait()
                expect(Remaining.count("stay")).toBe(0)
                for _,stay in ipairs(stays) do expect(stay.LocalTransparencyModifier).toBe(0) end
                Remaining.sync(arena,deck.Position,"Medium",true,nil,0,true)
                expect(Remaining.count("stay")).toBe(2)
                local function verifyStays()
                    for _,stay in ipairs(stays) do
                        expect(stay.LocalTransparencyModifier).toBe(1)
                        local fitted=nil
                        for _,model in ipairs(bucket:GetChildren()) do
                            if model.Name=="ApprovedP4_Stay" then
                                for _,piece in ipairs(model:GetChildren()) do
                                    if piece.Size.Magnitude>5
                                        and (piece.Position-stay.Position).Magnitude<.05 then
                                        expect(model:GetAttribute("Original3DAssetId")).toBe(122766792774607)
                                        local size=piece.Size
                                        expect(math.abs(math.max(size.X,size.Y,size.Z)
                                            -stay.Size.Y*.985)<.07).toBe(true)
                                        expect(math.abs(piece.CFrame.RightVector:Dot(stay.CFrame.UpVector))>.999).toBe(true)
                                        fitted=model
                                    end
                                end
                            end
                        end
                        expect(fitted~=nil).toBe(true)
                    end
                end
                verifyStays()
                Remaining.sync(arena,deck.Position,"Medium",true,nil,1,true)
                expect(Remaining.count("stay")).toBe(0)
                Remaining.sync(arena,deck.Position,"Low",true,nil,0,true)
                expect(Remaining.count("stay")).toBe(0)
                expect(Remaining.count("equipment")).toBe(1)
                expect(Remaining.nativeCount("promenade")).toBe(1)
                local gear=bucket:FindFirstChild("ApprovedP4_PromenadeCrossroads")
                local gearPrefix="Promenade"..gear:GetAttribute("OriginalP4OwnerPlatform"):match("%d+").."_"
                local fin=decor:FindFirstChild(gearPrefix.."SwitchFin1")
                local concourse=decor:FindFirstChild(gearPrefix.."SignalConcourse")
                expect(gear:GetAttribute("Original3DAssetId")).toBe(90844491148907)
                expect(fin.LocalTransparencyModifier).toBe(1)
                fin.Parent=nil
                task.wait()
                expect(fin.LocalTransparencyModifier).toBe(0)
                expect(concourse.LocalTransparencyModifier).toBe(0)
                fin.Parent=decor
                expect(concourse.LocalTransparencyModifier).toBe(1)
                gear:FindFirstChildWhichIsA("MeshPart"):Destroy()
                task.wait()
                expect(concourse.LocalTransparencyModifier).toBe(0)
                Remaining.sync(arena,deck.Position,"Low",true,nil,0,true)
                expect(concourse.LocalTransparencyModifier).toBe(1)
                expect(native.LocalTransparencyModifier).toBe(1)
                local model=bucket:FindFirstChild("ApprovedP4_Crosshead")
                expect(model:GetAttribute("Original3DAssetId")).toBe(108452611210970)
                local function verifyFit()
                    local meshCount=0
                    for _,piece in ipairs(model:GetDescendants()) do
                        if piece:IsA("MeshPart") then
                            meshCount+=1
                            expect(piece.CanCollide or piece.CanQuery or piece.CanTouch).toBe(false)
                        end
                    end
                    expect(meshCount).toBe(7)
                    local frame,size=model:GetBoundingBox()
                    local major=math.max(size.X,size.Z)
                    expect((frame.Position-native.Position).Magnitude<.03).toBe(true)
                    expect(math.abs(major-native.Size.Z*.98)<.04).toBe(true)
                    expect(math.abs(size.Y-native.Size.Y*.975)<.02).toBe(true)
                end
                verifyFit()
                Remaining.sync(arena,deck.Position,"Medium",true,nil,0,true)
                verifyStays()
                local deckSize,nativeSize=deck.Size,native.Size
                base.Size=Vector3.new(base.Size.X*.75,base.Size.Y,base.Size.Z*.75)
                expect(native.LocalTransparencyModifier).toBe(0)
                expect(Remaining.count("equipment")).toBe(0)
                expect(Remaining.count("stay")).toBe(0)
                deck.Size=Vector3.new(deckSize.X*.75,deckSize.Y,deckSize.Z*.75)
                native.Size=Vector3.new(nativeSize.X*.75,nativeSize.Y,nativeSize.Z*.75)
                for _,stay in ipairs(stays) do
                    local frame=deck.CFrame:ToObjectSpace(stay.CFrame)
                    local offset=frame.Position
                    stay.CFrame=deck.CFrame*CFrame.new(offset.X*.75,offset.Y,offset.Z*.75)
                        *(frame-offset)
                    stay.Size=Vector3.new(stay.Size.X*.75,stay.Size.Y,stay.Size.Z*.75)
                end
                expect(native.LocalTransparencyModifier).toBe(1)
                verifyFit()
                verifyStays()
                for _,name in ipairs(profile[6]) do
                    local detail=decor:FindFirstChild(gearPrefix..name)
                    local frame=deck.CFrame:ToObjectSpace(detail.CFrame)
                    local offset=frame.Position
                    detail.CFrame=deck.CFrame*CFrame.new(offset.X*.75,offset.Y,offset.Z*.75)
                        *(frame-offset)
                    detail.Size=Vector3.new(detail.Size.X*.75,detail.Size.Y,detail.Size.Z*.75)
                end
                expect(concourse.LocalTransparencyModifier).toBe(1)
                local resizedEquipment=bucket:FindFirstChild("ApprovedP4_PromenadeCrossroads")
                local gearFrame,gearSize=resizedEquipment:GetBoundingBox()
                expect(math.abs(math.max(gearSize.X,gearSize.Z)-16.2*.75)<.06).toBe(true)
                expect(gearFrame.Position.Y-gearSize.Y*.5>deck.Position.Y+11).toBe(true)
                deck:SetAttribute("BridgeShutterPhase","Warning")
                expect(native.LocalTransparencyModifier).toBe(0)
                expect(concourse.LocalTransparencyModifier).toBe(0)
                expect(Remaining.count("stay")).toBe(0)
                deck:SetAttribute("BridgeShutterPhase","Idle")
                expect(native.LocalTransparencyModifier).toBe(1)
                expect(concourse.LocalTransparencyModifier).toBe(1)
                verifyStays()
                native.Parent=nil
                expect(native.LocalTransparencyModifier).toBe(0)
                local replacement=native:Clone()
                replacement.LocalTransparencyModifier=.25
                replacement.Parent=decor
                native:Destroy()
                Remaining.sync(arena,deck.Position,"Low",true,nil,0,true)
                expect(replacement.LocalTransparencyModifier).toBe(1)
                detachable.Parent=nil
                task.wait()
                expect(replacement.LocalTransparencyModifier).toBe(.25)
                -- A new template identity is required to refit an import
                -- with changed axes after a streaming replacement.
                source.Parent=nil
                detachable.Parent=source
                main.Size=Vector3.new(1.12,.5675,8.94)
                local reimport=source:Clone()
                source:Destroy()
                reimport.Parent=holder
                Remaining.sync(arena,deck.Position,"Low",true,nil,0,true)
                expect(replacement.LocalTransparencyModifier).toBe(1)
                local rotated=bucket:FindFirstChild("ApprovedP4_Crosshead")
                local _,rotatedSize=rotated:GetBoundingBox()
                expect(math.abs(math.max(rotatedSize.X,rotatedSize.Z)-replacement.Size.Z*.98)<.04).toBe(true)
                Remaining.sync(arena,deck.Position,"Low",true,nil,1,true)
                expect(Remaining.count("promenade")).toBe(0)
                expect(replacement.LocalTransparencyModifier).toBe(.25)
                local newScale=.45/.75
                base.Size=Vector3.new(base.Size.X*newScale,base.Size.Y,base.Size.Z*newScale)
                deck.Size=Vector3.new(deckSize.X*.45,deckSize.Y,deckSize.Z*.45)
                for _,stay in ipairs(stays) do
                    local frame=deck.CFrame:ToObjectSpace(stay.CFrame)
                    local offset=frame.Position
                    stay.CFrame=deck.CFrame*CFrame.new(offset.X*newScale,offset.Y,offset.Z*newScale)
                        *(frame-offset)
                    stay.Size=Vector3.new(stay.Size.X*newScale,stay.Size.Y,stay.Size.Z*newScale)
                end
                Remaining.sync(arena,deck.Position,"Medium",true,nil,0,true)
                local ownStays=0
                for _,model in ipairs(bucket:GetChildren()) do
                    if model.Name=="ApprovedP4_Stay"
                        and model:GetAttribute("OriginalP4OwnerPlatform")==deck.Name then
                        ownStays+=1
                        for _,piece in ipairs(model:GetChildren()) do
                            if piece:IsA("MeshPart") then
                                local relative=deck.CFrame:ToObjectSpace(piece.CFrame)
                                local zExtent=(
                                    math.abs(relative.RightVector.Z)*piece.Size.X
                                    +math.abs(relative.UpVector.Z)*piece.Size.Y
                                    +math.abs(relative.LookVector.Z)*piece.Size.Z)*.5
                                expect(math.abs(relative.Position.Z)-zExtent
                                    > deck.Size.Z*.5).toBe(true)
                            end
                        end
                    end
                end
                local hasClearance=deck:GetAttribute("PromenadeStep")~=7
                expect(ownStays).toBe(hasClearance and 2 or 0)
                for _,stay in ipairs(stays) do
                    expect(stay.LocalTransparencyModifier).toBe(hasClearance and 1 or 0)
                end
            end
        end)
        Remaining.sync(nil,Vector3.zero,"Low",false)
        if generated then generated:Destroy() end
        holder:Destroy()
        sideHolder:Destroy()
        for name,instance in pairs(equipmentHolders) do
            instance:Destroy()
            if previousEquipment[name] then previousEquipment[name].Parent=rs end
        end
        if previousSide then previousSide.Parent=rs end
        if old then old.Parent=rs end
        if previous then previous.Parent=workspace end
        if not ok then error(err) end
    end)

    it("sculpts both genuine promenade pylons per portico within the existing column budget",function()
        local rs=game:GetService("ReplicatedStorage")
        local trim=require("../../src/client/PlatformNativeTrimReplacementKit")
        local previous=workspace:FindFirstChild("GeneratedMap")
        local old=rs:FindFirstChild("ApprovedLargeStructureTemplates")
        if previous then previous.Parent=nil end
        if old then old.Parent=nil end
        local holder=Instance.new("Folder")
        holder.Name="ApprovedLargeStructureTemplates"
        holder:SetAttribute("OwnerVerified",true)
        holder.Parent=rs
        local art=Instance.new("Folder")
        art.Parent=workspace
        local generated=nil
        local connections={}
        local variants={
            Classic=91626128452597,Towers=107521411452905,
            Crossroads=93993697329658,Orbital=119010829781313,
            Harbor=76194593490199,
        }
        local ok,err=pcall(function()
            for variant,assetId in pairs(variants) do
                local source=Instance.new("Model")
                source.Name=variant
                source:SetAttribute("Original3DAssetId",assetId)
                source:SetAttribute("OriginalLargeStructure3D",true)
                source:SetAttribute("OwnerVerified",true)
                source:SetAttribute("CosmeticOnly",true)
                for i=1,7 do
                    local piece=Instance.new("MeshPart")
                    piece.Size=i==1 and Vector3.new(2.12,14.1,2.12)
                        or Vector3.new(.18,.18,.18)
                    piece.Anchored=true
                    piece.CanCollide=false
                    piece.CanTouch=false
                    piece.CanQuery=false
                    piece.Parent=source
                end
                source.Parent=holder
                local arena=MapBuilder.buildArena(Config,variant,ArenaVariants,VisualTheme)
                generated=arena.Parent
                local platforms=arena:FindFirstChild("Platforms")
                local decor=arena:FindFirstChild("Decor")
                local base=arena:FindFirstChild("Base")
                local genuine=0
                local deck=nil
                for _,owner in ipairs(platforms:GetChildren()) do
                    local index=owner.Name:match("^Platform(%d+)$")
                    if index then
                        for _,side in ipairs({-1,1}) do
                            local part=decor:FindFirstChild("Promenade"..index.."_LoadPylon"..side)
                            if IdentityLod.matchesPromenadePylon(part,owner) then
                                genuine+=1
                            end
                        end
                    end
                    if owner:GetAttribute("PromenadeStep")==7
                        and owner:GetAttribute("PromenadeLane")==1 then deck=owner end
                end
                expect(genuine).toBe(variant=="Harbor" and 0 or 12)
                expect(deck~=nil and deck.CanCollide).toBe(true)
                local index=tonumber(deck.Name:match("^Platform(%d+)$"))
                local left=decor:FindFirstChild("Promenade"..index.."_LoadPylon-1")
                local diagonal=decor:FindFirstChild("Promenade"..index.."_DiagonalStay-1")
                expect(IdentityLod.matchesPromenadePylon(diagonal,deck)).toBe(false)
                if variant=="Harbor" then
                    local harbor=Kit.supports(art,decor,deck,variant,"High",index,2,true)
                    for _,part in ipairs(harbor and harbor.parts or {}) do
                        expect(part:GetAttribute("OriginalPromenadePylon3D")).toBe(nil)
                    end
                    if harbor then
                        for _,conn in ipairs(harbor.disconnects) do conn:Disconnect() end
                    end
                    art:ClearAllChildren()
                    continue
                end
                local _,selected=Kit.selectNearRouteStructures(
                    {deck},decor,variant,"Low",base,deck.Position,nil,0,false)
                expect(selected[deck]).toBe(true)
                local _,pressured=Kit.selectNearRouteStructures(
                    {deck},decor,variant,"Low",base,deck.Position,nil,1,false)
                expect(next(pressured)).toBe(nil)
                local low=Kit.supports(art,decor,deck,variant,"Low",index,1,true)
                expect(low.modules).toBe(1)
                expect(low.covered[1]).toBe(left)
                expect(#low.parts).toBe(7)
                for _,conn in ipairs(low.disconnects) do conn:Disconnect() end
                art:ClearAllChildren()
                local high=Kit.supports(art,decor,deck,variant,"High",index,2,true)
                connections=high.disconnects
                expect(high.modules).toBe(2)
                expect(#high.parts).toBe(14)
                for _,part in ipairs(high.parts) do
                    expect(part:GetAttribute("OriginalPromenadePylon3D")).toBe(true)
                    expect(part:GetAttribute("Original3DAssetId")).toBe(assetId)
                    expect(part.CanCollide or part.CanTouch or part.CanQuery).toBe(false)
                end
                left.LocalTransparencyModifier=.25
                trim.bind(arena,{},nil,high.covered,art)
                expect(trim.breakdown().promenadePylon).toBe(2)
                expect(diagonal.LocalTransparencyModifier).toBe(0)
                if variant=="Crossroads" then
                    local mesh=high.parts[1]
                    local anchor=IdentityLod.owner(mesh,platforms,decor)
                    expect(anchor).toBe(left)
                    trim.setPylonLodVisible(anchor,false)
                    expect(left.LocalTransparencyModifier).toBe(.25)
                    trim.setPylonLodVisible(anchor,true)
                    expect(left.LocalTransparencyModifier).toBe(1)
                    local initial=mesh.Size
                    deck.Size=Vector3.new(deck.Size.X*.75,deck.Size.Y,deck.Size.Z*.75)
                    expect(trim.breakdown().promenadePylon).toBe(0)
                    for _,pylon in ipairs(high.covered) do
                        local frame=deck.CFrame:ToObjectSpace(pylon.CFrame)
                        local offset=frame.Position
                        pylon.CFrame=deck.CFrame*CFrame.new(offset.X*.75,offset.Y,offset.Z*.75)
                        pylon.Size=Vector3.new(pylon.Size.X*.75,pylon.Size.Y,pylon.Size.Z*.75)
                    end
                    expect(trim.breakdown().promenadePylon).toBe(2)
                    expect(math.abs(mesh.Size.X-initial.X*.75)<.02).toBe(true)
                    expect(math.abs(mesh.Size.Y-initial.Y)<.02).toBe(true)
                    deck:SetAttribute("CollapsePhase","Warning")
                    expect(left.LocalTransparencyModifier).toBe(.25)
                    deck:SetAttribute("CollapsePhase","Normal")
                    expect(left.LocalTransparencyModifier).toBe(1)
                    mesh:Destroy()
                    expect(left.LocalTransparencyModifier).toBe(.25)
                    expect(trim.breakdown().promenadePylon).toBe(1)
                    expect(high.parts[2].LocalTransparencyModifier).toBe(1)
                end
                trim.reset()
                expect(left.LocalTransparencyModifier).toBe(.25)
                for _,conn in ipairs(connections) do conn:Disconnect() end
                table.clear(connections)
                art:ClearAllChildren()
            end
        end)
        trim.reset()
        for _,conn in ipairs(connections) do conn:Disconnect() end
        art:Destroy()
        holder:Destroy()
        if generated then generated:Destroy() end
        if old then old.Parent=rs end
        if previous then previous.Parent=workspace end
        if not ok then error(err) end
    end)

    it("sculpts genuine nonphysical Sky Spine pylons using old column quota",function()
        local RS=game:GetService("ReplicatedStorage")
        local Trim=require("../../src/client/PlatformNativeTrimReplacementKit")
        local previous=workspace:FindFirstChild("GeneratedMap")
        local oldTemplates=RS:FindFirstChild("ApprovedLargeStructureTemplates")
        local oldCrowns=RS:FindFirstChild("PremiumRouteMeshTemplates")
        if previous then previous.Parent=nil end
        if oldTemplates then oldTemplates.Parent=nil end
        if oldCrowns then oldCrowns.Parent=nil end
        local generated,templates,art,crownTemplates=nil,nil,nil,nil
        local ok,err=pcall(function()
            local arena=MapBuilder.buildArena(
                Config,"Crossroads",ArenaVariants,VisualTheme)
            generated=arena.Parent
            local platforms=arena:FindFirstChild("Platforms")
            local decor=arena:FindFirstChild("Decor")
            local base=arena:FindFirstChild("Base")
            local owner,pylons=nil,{}
            for _,deck in ipairs(platforms:GetChildren()) do
                local step=tonumber(deck:GetAttribute("SkySpineStep"))
                if deck:IsA("BasePart") and (step==2 or step==5
                    or step==6 or step==9) then
                    local id=tonumber(deck.Name:match("^Platform(%d+)$"))
                    local left=decor:FindFirstChild(
                        "SkySpine"..id.."_MonumentalPylon-1")
                    local right=decor:FindFirstChild(
                        "SkySpine"..id.."_MonumentalPylon1")
                    if left and right and Kit.validNativeSkyPylon(left,id)
                        and Kit.validNativeSkyPylon(right,id) then
                        owner=deck
                        pylons={left,right}
                        break
                    end
                end
            end
            expect(owner~=nil and owner.CanCollide
                and owner.Anchored).toBe(true)
            local id=tonumber(owner.Name:match("^Platform(%d+)$"))
            expect(#pylons).toBe(2)
            for _,native in ipairs(pylons) do
                expect(Kit.validNativeSkyPylon(native,id)).toBe(true)
                expect(native.CanCollide or native.CanTouch
                    or native.CanQuery).toBe(false)
                native:SetAttribute("PerimeterPlatformIndex",-1)
                expect(Kit.validNativeSkyPylon(native,id)).toBe(false)
                native:SetAttribute("PerimeterPlatformIndex",id)
                expect(Kit.validNativeSkyPylon(native,id)).toBe(true)
                local segments,scale=Kit.supportFit(native.Size,
                    Vector3.new(2.12,14.1,2.12))
                expect(segments).toBe(1)
                expect(scale~=nil and scale>.80 and scale<1).toBe(true)
            end
            local decoy=Instance.new("Part")
            decoy.Name="SkySpine"..id.."_SignalInlay-1"
            decoy.Size=Vector3.new(.30,7.5,.42)
            decoy.Anchored=true
            decoy.CanCollide=false
            decoy.CanTouch=false
            decoy.CanQuery=false
            decoy:SetAttribute("SkySpineDecor",true)
            decoy:SetAttribute("PerimeterPlatformIndex",id)
            expect(Kit.validNativeSkyPylon(decoy,id)).toBe(false)
            decoy:Destroy()
            templates=Instance.new("Folder")
            templates.Name="ApprovedLargeStructureTemplates"
            templates:SetAttribute("OwnerVerified",true)
            templates.Parent=RS
            local source=Instance.new("Model")
            source.Name="Crossroads"
            source:SetAttribute("OwnerVerified",true)
            source:SetAttribute("Original3DAssetId",93993697329658)
            source:SetAttribute("OriginalLargeStructure3D",true)
            source:SetAttribute("CosmeticOnly",true)
            for i=1,7 do
                local mesh=Instance.new("MeshPart")
                mesh.Name="OriginalPylonColumnMaterial"..i
                mesh.Size=i==1 and Vector3.new(2.12,14.1,2.12)
                    or Vector3.new(.2,.2,.2)
                mesh.Anchored=true
                mesh.CanCollide=false
                mesh.CanQuery=false
                mesh.CanTouch=false
                mesh.Parent=source
            end
            source.Parent=templates
            art=Instance.new("Folder")
            art.Name="ApprovedPylonVisualOwner"
            art.Parent=workspace
            local _,selected=Kit.selectNearRouteStructures(
                {owner},decor,"Crossroads","High",base,
                owner.Position,Vector3.new(0,0,1),0,false)
            expect(selected[owner]).toBe(true)
            -- If no complete 3D underframe source is available, Low
            -- can still sculpt ONE authentic nearby pylon, and never
            -- spends a source column in addition to a full cradle.
            local lowCradles,lowSupports=Kit.selectNearRouteStructures(
                {owner},decor,"Crossroads","Low",base,
                owner.Position,Vector3.new(0,0,1),0,false)
            expect(next(lowCradles)).toBe(nil)
            expect(lowSupports[owner]).toBe(true)
            local result=Kit.supports(art,decor,owner,"Crossroads",
                "High",id,2,true)
            expect(result~=nil and result.modules==2).toBe(true)
            expect(#result.covered).toBe(2)
            expect(#result.parts).toBe(14)
            expect(result.covered[1]).toBe(pylons[1])
            expect(result.covered[2]).toBe(pylons[2])
            for _,mesh in ipairs(result.parts) do
                expect(mesh:IsA("MeshPart")).toBe(true)
                expect(mesh:GetAttribute("OriginalSkySpinePylon3D"))
                    .toBe(true)
                expect(mesh.CanCollide or mesh.CanTouch
                    or mesh.CanQuery).toBe(false)
            end
            -- Keep the real baseline through both possible ownership orders.
            pylons[1].LocalTransparencyModifier=.25
            Trim.bind(arena,{},function() end,result.covered,art)
            expect(Trim.breakdown().pylon).toBe(2)
            expect(Trim.breakdown().support).toBe(0)
            for _,native in ipairs(pylons) do
                expect(native.LocalTransparencyModifier).toBe(1)
            end
            crownTemplates=Instance.new("Folder")
            crownTemplates.Name="PremiumRouteMeshTemplates"
            crownTemplates:SetAttribute("OwnerVerified",true)
            crownTemplates.Parent=RS
            local crownSource=Instance.new("Model")
            crownSource.Name="OriginalSkySpineCrown"
            crownSource:SetAttribute("OwnerVerified",true)
            crownSource:SetAttribute("CosmeticOnly",true)
            crownSource:SetAttribute("PremiumSkySpineCrown3D",true)
            crownSource:SetAttribute("Original3DAssetId",71492051540032)
            local crownMesh=Instance.new("MeshPart")
            crownMesh.Size=Vector3.new(18.8,20.52,3.86)
            crownMesh.Parent=crownSource
            crownSource.Parent=crownTemplates

            Crown.sync(arena,owner.Position,"Low",true)
            expect(Crown.count()).toBe(1)
            expect(Trim.count()).toBe(0)
            expect(Trim.breakdown().pylon).toBe(0)
            for _,mesh in ipairs(result.parts) do
                expect(mesh.LocalTransparencyModifier).toBe(1)
            end
            Trim.reset()
            expect(pylons[1].LocalTransparencyModifier).toBe(1)
            Trim.bind(arena,{},function() end,result.covered,art)
            expect(Trim.breakdown().pylon).toBe(0)
            -- Losing a weld only invalidates the complete crown. The
            -- two verified columns immediately resume their fallback.
            local crownFolder=workspace:FindFirstChild("OriginalSkySpineCrownLocal")
            local crownWeld=crownFolder:FindFirstChild("SkySpineCrownCosmeticWeld",true)
            expect(crownWeld~=nil).toBe(true)
            crownWeld:Destroy()
            task.wait()
            expect(Crown.count()).toBe(0)
            expect(Trim.count()).toBe(2)
            expect(Trim.breakdown().pylon).toBe(2)
            for _,mesh in ipairs(result.parts) do
                expect(mesh.LocalTransparencyModifier).toBe(0)
            end
            Crown.sync(arena,owner.Position,"Low",true)
            expect(Crown.count()).toBe(1)
            local streamed=pylons[1]:Clone()
            streamed.LocalTransparencyModifier=.5
            streamed.Parent=decor
            expect(streamed.LocalTransparencyModifier).toBe(1)
            streamed.Parent=nil
            expect(streamed.LocalTransparencyModifier).toBe(.5)
            streamed:Destroy()
            -- Low pressure eviction releases the crown while the
            -- next platform-owner pass can update its own quota.
            Crown.sync(arena,owner.Position,"Low",true,nil,2)
            expect(Crown.count()).toBe(0)
            expect(Trim.breakdown().pylon).toBe(2)
            -- Existing scenery LOD must restore the native silhouette and
            -- leave no cached opacity when the camera returns.
            local nativeOwner=IdentityLod.owner(result.parts[1],platforms,decor)
            expect(nativeOwner).toBe(pylons[1])
            Trim.setPylonLodVisible(nativeOwner,false)
            expect(Trim.breakdown().pylon).toBe(1)
            expect(pylons[1].LocalTransparencyModifier).toBe(.25)
            expect(result.parts[1].LocalTransparencyModifier).toBe(1)
            Trim.setPylonLodVisible(nativeOwner,true)
            expect(Trim.breakdown().pylon).toBe(2)
            expect(result.parts[1].LocalTransparencyModifier).toBe(0)
            -- A real gameplay collapse restores BOTH native originals
            -- while keeping their owner collidable authority unchanged.
            owner:SetAttribute("CollapsePhase","Warning")
            expect(Trim.breakdown().pylon).toBe(0)
            expect(pylons[1].LocalTransparencyModifier).toBe(.25)
            expect(pylons[2].LocalTransparencyModifier).toBe(0)
            owner:SetAttribute("CollapsePhase","Normal")
            expect(Trim.breakdown().pylon).toBe(2)
            -- One lost imported material revokes ONLY that pylon source.
            result.parts[1]:Destroy()
            expect(Trim.breakdown().pylon).toBe(1)
            expect(pylons[1].LocalTransparencyModifier).toBe(.25)
            expect(pylons[2].LocalTransparencyModifier).toBe(1)
            expect(result.parts[8].LocalTransparencyModifier).toBe(0)
            Trim.reset()
            expect(pylons[1].LocalTransparencyModifier).toBe(.25)
            expect(pylons[2].LocalTransparencyModifier).toBe(0)
            for _,conn in ipairs(result.disconnects) do
                conn:Disconnect()
            end
            expect(owner.CanCollide).toBe(true)
        end)
        Crown.sync(nil,Vector3.zero,"Low",false)
        Trim.reset()
        if crownTemplates then crownTemplates:Destroy() end
        if oldCrowns then oldCrowns.Parent=RS end
        if art then art:Destroy() end
        if templates then templates:Destroy() end
        if generated then generated:Destroy() end
        if oldTemplates then oldTemplates.Parent=RS end
        if previous then previous.Parent=workspace end
        if not ok then error(err) end
    end)
end)

return nil
