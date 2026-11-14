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
                -- A real SkySpine may be too short for the certified
                -- 22-stud long sculpture. Still verify native streaming
                -- without stretching the genuine source into false art.
                local fitted=Kit.cradleFit(deck.Size,bounds)~=nil
                expect(selected()).toBe(fitted)
                local underframe=decor:FindFirstChild(
                    "PlatformUnderFrame"..id)
                expect(underframe~=nil).toBe(true)
                underframe.Parent=nil
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
                native.Parent=nil
                expect(Kit.hasNativeCradleFallback(decor,deck)).toBe(false)
                expect(selected()).toBe(false)
                native.Parent=decor
                native:SetAttribute("PerimeterPlatformIndex",-1)
                expect(selected()).toBe(false)
                native:SetAttribute("PerimeterPlatformIndex",id)
                expect(selected()).toBe(fitted)
                local parts=Kit.longCradle(models,deck,
                    "Medium",id,true,decor)
                if fitted then
                    expect(parts~=nil and #parts==7).toBe(true)
                    for _,piece in ipairs(parts) do
                        expect(piece:IsA("MeshPart")).toBe(true)
                        expect(piece.CanCollide or piece.CanTouch or piece.CanQuery)
                            .toBe(false)
                        expect(piece:GetAttribute("OriginalLongCradle3D"))
                            .toBe(true)
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
