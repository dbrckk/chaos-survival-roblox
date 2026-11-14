--!strict
-- Dedicated Roblox Engine regression for owner-approved 3D district
-- sidewall fallback. Kept separate to respect Open Cloud's 105KB/spec cap.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local ApprovedDistrictSidewallMeshKit = require(
    "../../src/client/ApprovedDistrictSidewallMeshKit")
local PremiumDistrictFacadeMeshKit = require(
    "../../src/client/PremiumDistrictFacadeMeshKit")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local VisualTheme = require("../../src/shared/VisualTheme")
local Config = require("../../src/shared/Config")

describe("Authenticated district sidewall restoration (engine)", function()
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
        if oldMap then oldMap.Parent=nil end
        if oldFacade then oldFacade.Parent=nil end
        if oldSidewall then oldSidewall.Parent=nil end
        PremiumDistrictFacadeMeshKit.sync(
            nil,Vector3.zero,"Low",false)
        ApprovedDistrictSidewallMeshKit.sync(
            nil,Vector3.zero,"Low",false,false,0)
        local generated,facades,shells
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
            local base=arena:FindFirstChild("Base")
            local district=arena:FindFirstChild("Decor")
                :FindFirstChild("ArenaDistrictArchitecture3D")
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
            expect(ApprovedDistrictSidewallMeshKit.completeCount()<=3)
                .toBe(true)
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
        end)
        ApprovedDistrictSidewallMeshKit.sync(
            nil,Vector3.zero,"Low",false,false,0)
        PremiumDistrictFacadeMeshKit.sync(
            nil,Vector3.zero,"Low",false)
        if shells then shells:Destroy() end
        if facades then facades:Destroy() end
        if generated then generated:Destroy() end
        if oldSidewall then oldSidewall.Parent=RS end
        if oldFacade then oldFacade.Parent=RS end
        if oldMap then oldMap.Parent=workspace end
        if not ok then error(why) end
    end)
end)

return nil
