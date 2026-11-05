--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Layout = require("../../src/shared/CinematicDepthLayoutRules")
local MeshRules = require("../../src/shared/CinematicHorizonMeshRules")

describe("immutable cinematic skyline ring layouts", function()
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
