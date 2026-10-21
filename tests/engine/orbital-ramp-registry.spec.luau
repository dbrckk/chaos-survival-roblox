--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local OrbitalRampRegistry = require("../../src/client/OrbitalRampRegistry")
local OrbitalRouteSignKit = require("../../src/client/OrbitalRouteSignKit")

local function ramp(root, name, tag, lane)
    local part = Instance.new("Part")
    part.Name = name
    if tag then part:SetAttribute(tag, true) end
    if lane then part:SetAttribute("HelixLane", lane) end
    part.Parent = root
    return part
end

describe("Orbital event-driven ramp discovery", function()
    it("keeps smooth visual frames independent of geometry enumeration", function()
        local registry = OrbitalRampRegistry.new(OrbitalRouteSignKit)
        local first, access, changed = registry:snapshot(nil)
        expect(#first).toBe(0)
        expect(#access).toBe(0)
        expect(changed).toBe(true)
        local initialScans = registry.scanCount
        for _ = 1, 90 do
            local scored, links, rescanned = registry:snapshot(nil)
            expect(#scored).toBe(0)
            expect(#links).toBe(0)
            expect(rescanned).toBe(false)
        end
        expect(registry.scanCount).toBe(initialScans)

        local circuit = Instance.new("Folder")
        circuit.Name = "HelixCircuit"
        circuit.Parent = workspace
        local scored2 = ramp(circuit, "HelixRamp2", "OrbitalHelixRamp", 2)
        local scored10 = ramp(circuit, "HelixRamp10", "OrbitalHelixRamp", 10)
        local scored1 = ramp(circuit, "HelixRamp1", "OrbitalHelixRamp", 1)
        local entry = ramp(circuit, "EntryRamp1", "OrbitalAccessRamp", nil)
        local core = ramp(circuit, "HelixRamp9", "OrbitalCoreRamp", nil)
        -- Hundreds of static trim pieces may exist around a single ramp.
        for index = 1, 36 do
            local trim = Instance.new("Part")
            trim.Name = "HelixEdgeSignal" .. index
            trim.Parent = circuit
        end
        local scored, links, rescanned = registry:snapshot(circuit)
        expect(rescanned).toBe(true)
        expect(#scored).toBe(3)
        expect(scored[1]).toBe(scored1)
        expect(scored[2]).toBe(scored2)
        expect(scored[3]).toBe(scored10)
        expect(#links).toBe(2)
        expect(links[1]).toBe(entry)
        expect(links[2]).toBe(core)
        local scanCount = registry.scanCount

        for _ = 1, 120 do
            local _, _, wasDirty = registry:snapshot(circuit)
            expect(wasDirty).toBe(false)
        end
        expect(registry.scanCount).toBe(scanCount)

        -- Server VFX pulse updates must never trigger a route rescan.
        scored1:SetAttribute("HelixPulseActive", true)
        scored1.CFrame = CFrame.new(8, 5, 3)
        local _, _, afterPulse = registry:snapshot(circuit)
        expect(afterPulse).toBe(false)
        expect(registry.scanCount).toBe(scanCount)

        -- Streaming may add the Part before its gameplay attributes.
        local late = ramp(circuit, "CoreRamp8", nil, nil)
        task.wait(0.03)
        scored, links, rescanned = registry:snapshot(circuit)
        expect(rescanned).toBe(true)
        expect(#links).toBe(2)
        late:SetAttribute("OrbitalCoreRamp", true)
        task.wait(0.03)
        scored, links, rescanned = registry:snapshot(circuit)
        expect(rescanned).toBe(true)
        expect(#links).toBe(3)
        expect(links[1]).toBe(late)

        -- Changing Helix lane order is rare but still invalidates cache.
        scored10:SetAttribute("HelixLane", 0)
        task.wait(0.03)
        scored, links, rescanned = registry:snapshot(circuit)
        expect(rescanned).toBe(true)
        expect(scored[1]).toBe(scored10)

        -- Cosmetic child changes must not trigger an expensive rescan.
        local decoration = Instance.new("Part")
        decoration.Name = "CoreRampDecor999"
        decoration.Parent = circuit
        task.wait(0.03)
        local beforeTrim = registry.scanCount
        local _, _, afterTrim = registry:snapshot(circuit)
        expect(afterTrim).toBe(false)
        expect(registry.scanCount).toBe(beforeTrim)

        late:Destroy()
        task.wait(0.03)
        _, links, rescanned = registry:snapshot(circuit)
        expect(rescanned).toBe(true)
        expect(#links).toBe(2)
        registry:destroy()
        expect(registry.circuit).toBe(nil)
        expect(next(registry.partConnections) == nil).toBe(true)
        expect(#registry.connections).toBe(0)
        circuit:Destroy()
    end)

    it("disconnects every old arena observer when streaming replaces a circuit", function()
        local original = Instance.new("Folder")
        original.Parent = workspace
        local oldRamp = ramp(original, "EntryRamp1", "OrbitalAccessRamp", nil)
        local replacement = Instance.new("Folder")
        replacement.Parent = workspace
        local newRamp = ramp(replacement, "CoreRamp1", "OrbitalCoreRamp", nil)

        local registry = OrbitalRampRegistry.new(OrbitalRouteSignKit)
        local _, oldAccess = registry:snapshot(original)
        expect(#oldAccess).toBe(1)
        expect(oldAccess[1]).toBe(oldRamp)

        local scored, access, changed, replaced = registry:snapshot(replacement)
        expect(changed).toBe(true)
        expect(replaced).toBe(true)
        expect(#scored).toBe(0)
        expect(#access).toBe(1)
        expect(access[1]).toBe(newRamp)
        local scans = registry.scanCount

        oldRamp:SetAttribute("OrbitalAccessRamp", false)
        ramp(original, "EntryRamp7", "OrbitalAccessRamp", nil)
        task.wait(0.03)
        local _, _, dirty = registry:snapshot(replacement)
        expect(dirty).toBe(false)
        expect(registry.scanCount).toBe(scans)

        registry:destroy()
        original:Destroy()
        replacement:Destroy()
    end)
end)

return nil
