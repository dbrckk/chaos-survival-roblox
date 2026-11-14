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
end)

return nil
