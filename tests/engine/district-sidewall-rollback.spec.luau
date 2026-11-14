--!strict
-- Dedicated Roblox Engine regression for owner-approved 3D district
-- sidewall fallback. Kept separate to respect Open Cloud's 105KB/spec cap.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local ApprovedDistrictSidewallMeshKit = require(
    "../../src/client/ApprovedDistrictSidewallMeshKit")
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
            local clone=cloneFolder:FindFirstChild(
                "ApprovedOriginalDistrictSidewall3D")
            expect(clone~=nil).toBe(true)
            local clonePiece=clone:FindFirstChild("ApprovedMaterial1")
            expect(clonePiece~=nil).toBe(true)
            clonePiece.CanQuery=true
            expect(ApprovedDistrictSidewallMeshKit.count()).toBe(0)
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
end)

return nil
