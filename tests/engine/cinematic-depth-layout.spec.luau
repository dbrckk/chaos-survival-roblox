--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Layout = require("../../src/shared/CinematicDepthLayoutRules")
local MeshRules = require("../../src/shared/CinematicHorizonMeshRules")
local TrafficRules = require("../../src/shared/CinematicTrafficMeshRules")
local HaloRules = require("../../src/shared/CinematicOrbitalHaloMeshRules")

describe("immutable cinematic skyline ring layouts", function()
    it("replaces 14 genuinely sourced orbital halo bars using four bounded PBR lattice modules without new geometry requests", function()
        expect(HaloRules.ASSET_ID).toBe(94023662427980)
        expect(HaloRules.SOURCE_FOLDER).toBe("PremiumRouteMeshTemplates")
        expect(HaloRules.SOURCE_NAME).toBe("PremiumSkybridgeModule")
        expect(HaloRules.MODULES_PER_SITE).toBe(4)
        expect(#Layout.indices("OrbitalHalo","Medium")).toBe(10)
        expect(#Layout.indices("OrbitalHalo","High")).toBe(14)
        expect(HaloRules.capacity("Low",0,true)).toBe(0)
        expect(HaloRules.capacity("Medium",0,true)).toBe(2)
        expect(HaloRules.capacity("Medium",1,true)).toBe(1)
        expect(HaloRules.capacity("Medium",2,true)).toBe(0)
        expect(HaloRules.capacity("High",0,true)).toBe(3)
        expect(HaloRules.capacity("High",1,true)).toBe(1)
        expect(HaloRules.capacity("High",2,true)).toBe(0)
        expect(HaloRules.capacity("High",0,false)).toBe(5)
        expect(HaloRules.capacity("High",1,false)).toBe(2)
        expect(HaloRules.capacity("High",2,false)).toBe(0)
        expect(HaloRules.capacity("Invalid",0,false)).toBe(0)

        -- The existing 10 x 1.542 x 4.94 stud approved source can fit
        -- four original MeshPart trusses in the native 34 x 1.5 x 3.6
        -- footprint, preserving a real open and deep UV-detailed shape.
        local scale,yaw=HaloRules.fit(Vector3.new(10,1.542,4.94))
        expect(scale~=nil and scale>.60 and scale<.85).toBe(true)
        expect(yaw).toBe(0)
        expect(HaloRules.fit(Vector3.new(2,3,2))).toBe(nil)
        local used={}
        for moduleIndex=1,4 do
            local offset=HaloRules.moduleOffset(moduleIndex)
            used[#used+1]=offset
            expect(math.abs(offset)+10*scale*.5 < 17).toBe(true)
        end
        expect(used[1]<used[2] and used[2]<used[3]
            and used[3]<used[4]).toBe(true)
        expect(HaloRules.moduleOffset(0)).toBe(nil)
        expect(HaloRules.moduleOffset(5)).toBe(nil)

        local base=Instance.new("Part")
        base.Size=Vector3.new(320,12,320)
        base.CFrame=CFrame.new(-12,6,29)
            *CFrame.Angles(0,math.rad(17),0)
        base.Anchored=true
        local folder=Instance.new("Folder")
        for _,index in ipairs(Layout.indices("OrbitalHalo","High")) do
            local angle=Layout.angle("OrbitalHalo",index)
            local radius=base.Size.X*.5+78
            local offset=Vector3.new(math.cos(angle)*radius,
                34+math.sin(angle*2)*5,math.sin(angle)*radius)
            local native=Instance.new("Part")
            native.Name="CinemaOrbitalHalo"..index
            native.Size=Vector3.new(34,1.5,3.6)
            native.CFrame=base.CFrame*CFrame.new(offset)
                *CFrame.Angles(0,-angle-math.pi*.5,0)
                *CFrame.Angles(0,0,math.rad(math.sin(angle)*7))
            native.Anchored=true
            native.CanCollide=false
            native.CanTouch=false
            native.CanQuery=false
            native:SetAttribute("CosmeticOnly",true)
            native:SetAttribute("OriginalCinematicHaloIndex",index)
            native.Parent=folder
            expect(HaloRules.isNative(native,folder,base,index)).toBe(true)
            native.CanCollide=true
            expect(HaloRules.isNative(native,folder,base,index)).toBe(false)
            native.CanCollide=false
            native:SetAttribute("OriginalCinematicHaloIndex",index+1)
            expect(HaloRules.isNative(native,folder,base,index)).toBe(false)
            native:Destroy()
        end
        base:Destroy()
        folder:Destroy()
    end)


    it("authenticates all five creator-owned moving original source IDs and strict mobile pressure caps", function()
        local ids={
            Classic=102850052145878,
            Towers=72210530094580,
            Crossroads=116186226477876,
            Orbital=127850230318627,
            Harbor=131294203899636,
        }
        for variant,id in pairs(ids) do
            expect(TrafficRules.source(variant).id).toBe(id)
        end
        expect(TrafficRules.source("Unknown")).toBe(nil)
        expect(TrafficRules.capacity("Low",0,true)).toBe(0)
        expect(TrafficRules.capacity("Medium",0,true)).toBe(2)
        expect(TrafficRules.capacity("Medium",1,true)).toBe(1)
        expect(TrafficRules.capacity("Medium",2,true)).toBe(0)
        expect(TrafficRules.capacity("High",0,false)).toBe(4)
        expect(TrafficRules.capacity("High",1,false)).toBe(2)
        expect(TrafficRules.capacity("High",2,false)).toBe(0)
        expect(TrafficRules.capacity("High",0,true)).toBe(3)
        expect(TrafficRules.capacity("High",1,true)).toBe(1)
        expect(TrafficRules.capacity("High",2,true)).toBe(0)
        expect(TrafficRules.capacity("Unknown",0,false)).toBe(0)

        local folder=Instance.new("Folder")
        local anchor=Instance.new("Part")
        anchor.Name="CinemaTraffic3"
        anchor.Size=Vector3.new(5.6,.26,.46)
        anchor.Anchored=true
        anchor.CanCollide=false
        anchor.CanTouch=false
        anchor.CanQuery=false
        anchor:SetAttribute("CosmeticOnly",true)
        anchor:SetAttribute("OriginalCinematicTrafficIndex",3)
        anchor:SetAttribute("OriginalCinematicTrafficVariant","Orbital")
        anchor.Parent=folder
        expect(TrafficRules.isNative(anchor,folder,"Orbital",3)).toBe(true)
        anchor.CanCollide=true
        expect(TrafficRules.isNative(anchor,folder,"Orbital",3)).toBe(false)
        anchor.CanCollide=false
        anchor:SetAttribute("OriginalCinematicTrafficVariant","Harbor")
        expect(TrafficRules.isNative(anchor,folder,"Orbital",3)).toBe(false)
        anchor:Destroy()
        folder:Destroy()
    end)

    it("tweens anchored welded original craft by CFrame instead of Position", function()
        local start=Vector3.new(14,28,-12)
        local destination=Vector3.new(42,30,8)
        local goal=TrafficRules.goal(start,destination)
        expect(goal~=nil).toBe(true)
        expect((goal.Position-destination).Magnitude<.001).toBe(true)
        expect(goal.LookVector:Dot((destination-start).Unit)>.999).toBe(true)
        expect(TrafficRules.goal(start,start)).toBe(nil)

        local root=Instance.new("Part")
        root.Anchored=true
        root.CanCollide=false
        root.CFrame=CFrame.new(14,28,-12)
        root.Parent=workspace
        local piece=Instance.new("Part")
        piece.Anchored=true
        piece.CanCollide=false
        piece.CanTouch=false
        piece.CanQuery=false
        piece.CFrame=root.CFrame*CFrame.new(0,2,-.5)
        piece.Parent=workspace
        local offset=root.CFrame:ToObjectSpace(piece.CFrame)
        local weld=Instance.new("WeldConstraint")
        weld.Name="CinematicTrafficOriginal3DWeld"
        weld.Part0=root
        weld.Part1=piece
        weld.Parent=piece
        piece.Anchored=false
        root.CFrame=goal
        task.wait(.06)
        local expected=(goal*offset).Position
        expect((piece.Position-expected).Magnitude<.25).toBe(true)
        piece:Destroy()
        root:Destroy()
    end)

    it("authenticates all five authored skyline volumes for the maximum 55 original-mesh slots", function()
        local baseSize=Vector3.new(320,12,320)
        local variants={"Classic","Towers","Crossroads","Orbital","Harbor"}
        local total=0
        for _,variant in ipairs(variants) do
            for _,index in ipairs(Layout.indices("Horizon","High")) do
                local size=MeshRules.bodySize(variant,index)
                local offset=MeshRules.offset(baseSize,variant,index)
                expect(size ~= nil and offset ~= nil).toBe(true)
                expect(size.X >= 7 and size.Z >= 7).toBe(true)
                expect(size.Y >= 12 and size.Y <= 90).toBe(true)
                expect(offset.Y).toBe(size.Y*.5-8)
                local radius=variant=="Orbital" and 148
                    or (variant=="Towers" and 142 or 136)
                expect(math.abs(Vector3.new(
                    offset.X,0,offset.Z).Magnitude-radius) < .01).toBe(true)
                local choices=MeshRules.sources(variant,index)
                expect(#choices >= 4).toBe(true)
                local validSources={
                    Observatory=true,Freight=true,Turbine=true,
                    Aerial=true,CoolingSpire=true,HollowStack=true,
                    Satellite=true,Containment=true,
                }
                for _,key in ipairs(choices) do
                    expect(validSources[key]==true).toBe(true)
                end
                total+=1
            end
        end
        expect(total).toBe(55)
        expect(MeshRules.bodySize("Unknown",1)).toBe(nil)
        expect(MeshRules.bodySize("Classic",12)).toBe(nil)
        expect(MeshRules.offset(Vector3.zero,"Harbor",1)).toBe(nil)
    end)

    it("limits genuine 3D horizon residency under Android pressure without adding source models", function()
        expect(MeshRules.capacity("Low",0,true)).toBe(2)
        expect(MeshRules.capacity("Low",1,true)).toBe(1)
        expect(MeshRules.capacity("Low",2,true)).toBe(0)
        expect(MeshRules.capacity("Medium",0,true)).toBe(5)
        expect(MeshRules.capacity("Medium",1,true)).toBe(2)
        expect(MeshRules.capacity("Medium",2,true)).toBe(0)
        expect(MeshRules.capacity("High",0,true)).toBe(7)
        expect(MeshRules.capacity("High",1,true)).toBe(3)
        expect(MeshRules.capacity("High",2,true)).toBe(0)
        expect(MeshRules.capacity("High",0,false)).toBe(11)
        expect(MeshRules.capacity("High",1,false)).toBe(6)
        expect(MeshRules.capacity("High",2,false)).toBe(0)
        expect(MeshRules.capacity("Invalid",0,false)).toBe(0)
    end)

    it("retains original 5/8/11, 0/10/14, 0/3/5 and 0/2/4 tier budgets", function()
        local counts = {
            Horizon = {5, 8, 11},
            OrbitalHalo = {0, 10, 14},
            Beacon = {0, 3, 5},
            Traffic = {0, 2, 4},
        }
        for group, budget in pairs(counts) do
            local low = Layout.indices(group, "Low")
            local medium = Layout.indices(group, "Medium")
            local high = Layout.indices(group, "High")
            expect(#low).toBe(budget[1])
            expect(#medium).toBe(budget[2])
            expect(#high).toBe(budget[3])
            local mediumSet, highAngles = {}, {}
            local previous = -1
            for _, index in ipairs(high) do
                expect(highAngles[index] == nil).toBe(true)
                local angle = Layout.angle(group, index)
                expect(angle ~= nil and angle > previous).toBe(true)
                highAngles[index] = angle
                previous = angle
            end
            for _, index in ipairs(medium) do
                expect(mediumSet[index] == nil).toBe(true)
                mediumSet[index] = true
                expect(Layout.angle(group, index)).toBe(highAngles[index])
            end
            for _, index in ipairs(low) do
                expect(mediumSet[index]).toBe(true)
                expect(Layout.angle(group, index)).toBe(highAngles[index])
            end
            expect(Layout.angle(group, budget[3] + 1)).toBe(nil)
        end
        expect(Layout.angle("Horizon", 1)).toBe(math.rad(11))
        expect(Layout.angle("Beacon", 1)).toBe(math.rad(22))
        expect(Layout.angle("Horizon", 0)).toBe(nil)
        expect(Layout.angle("Horizon", 0/0)).toBe(nil)
        expect(#Layout.indices("Unrelated", "High")).toBe(0)
        expect(Layout.angle("Unrelated", 1)).toBe(nil)
    end)
end)
return nil
