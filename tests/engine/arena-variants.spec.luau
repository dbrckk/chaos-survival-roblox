--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaVariants = require("../../src/server/ArenaVariants")
local ArenaTargeting = require("../../src/server/ArenaTargeting")

describe("Arena variants", function()
    it("defines four distinct playable layouts", function()
        expect(#ArenaVariants.Order).toBe(4)

        local seen = {}
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            expect(variant ~= nil).toBe(true)
            expect(seen[id] == nil).toBe(true)
            seen[id] = true

            expect(#variant.SpawnOffsets >= 8).toBe(true)
            expect(#variant.Platforms >= 14).toBe(true)
            expect(variant.BaseSize.X >= 90).toBe(true)
            expect(variant.BaseSize.Z >= 90).toBe(true)
        end
    end)

    it("gives Classic four authored, spawn-safe, continuously reachable tiers", function()
        local classic = ArenaVariants.get("Classic")
        local tiers = {{}, {}, {}, {}}
        expect(#classic.Platforms).toBe(16)
        for _, deck in ipairs(classic.Platforms) do
            local tier = deck.RouteTier
            expect(type(tier)).toBe("number")
            expect(tier >= 1 and tier <= 4).toBe(true)
            table.insert(tiers[tier], deck)

            -- A mobile avatar arriving at any native spawn marker must not
            -- materialize inside a high deck, regardless of its height.
            -- Model R15 horizontal dimensions plus a one-stud margin.
            for _, spawn in ipairs(classic.SpawnOffsets) do
                local dx = math.abs(spawn.X - deck.offset.X)
                local dz = math.abs(spawn.Z - deck.offset.Z)
                local clearX = dx > deck.size.X * 0.5 + 3.8
                local clearZ = dz > deck.size.Z * 0.5 + 3.8
                expect(clearX or clearZ).toBe(true)
            end
        end
        for tier = 1, 4 do expect(#tiers[tier]).toBe(4) end

        local baseTop = classic.BaseSize.Y * 0.5
        for _, entry in ipairs(tiers[1]) do
            -- The floor -> starter leap is shorter than a standard jump.
            local top = entry.offset.Y + entry.size.Y * 0.5
            expect(top - baseTop <= 4.5).toBe(true)
        end

        local function canJump(from, target)
            local ascent = target.offset.Y + target.size.Y * 0.5
                - from.offset.Y - from.size.Y * 0.5
            local gapX = math.max(0, math.abs(from.offset.X - target.offset.X)
                - (from.size.X + target.size.X) * 0.5)
            local gapZ = math.max(0, math.abs(from.offset.Z - target.offset.Z)
                - (from.size.Z + target.size.Z) * 0.5)
            return ascent >= 0 and ascent <= 4.5
                and (gapX * gapX + gapZ * gapZ) <= 16
        end

        -- Every advanced deck has an explicit adjacent route from a lower
        -- tier; no decorative platform is an impossible floating island.
        for tier = 2, 4 do
            for _, target in ipairs(tiers[tier]) do
                local reachable = false
                for previousTier = 1, tier - 1 do
                    for _, source in ipairs(tiers[previousTier]) do
                        if canJump(source, target) then
                            reachable = true
                        end
                    end
                end
                expect(reachable).toBe(true)
            end
        end
    end)

    it("adds a connected high-route skybridge circuit to the Tower Run arena", function()
        local towers = ArenaVariants.get("Towers")
        local links = {}
        local mid = {}
        for _, entry in ipairs(towers.Platforms) do
            if entry.Skybridge == true then
                table.insert(links, entry)
            elseif entry.offset.Y == 12 then
                table.insert(mid, entry)
            end
        end
        expect(#links).toBe(4)
        expect(#mid).toBe(4)
        for _, bridge in ipairs(links) do
            local top = bridge.offset.Y + bridge.size.Y * 0.5
            expect(math.abs(top - 13) < 0.001).toBe(true)
            expect(math.max(bridge.size.X, bridge.size.Z) >= 49).toBe(true)
            expect(math.min(bridge.size.X, bridge.size.Z) >= 4).toBe(true)
            local aligned = 0
            for _, deck in ipairs(mid) do
                local delta = deck.offset - bridge.offset
                local reachX = deck.size.X * 0.5 + bridge.size.X * 0.5
                local reachZ = deck.size.Z * 0.5 + bridge.size.Z * 0.5
                if math.abs(delta.X) <= reachX and math.abs(delta.Z) <= reachZ then
                    aligned += 1
                end
            end
            expect(aligned).toBe(2)
        end
    end)

    it("derives hazard targeting bounds from arena footprints", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            local halfX, halfZ = ArenaTargeting.halfExtents(variant.BaseSize, 6, 42)

            expect(halfX > 0).toBe(true)
            expect(halfZ > 0).toBe(true)
            expect(halfX <= (variant.BaseSize.X * 0.5)).toBe(true)
            expect(halfZ <= (variant.BaseSize.Z * 0.5)).toBe(true)
        end

        local fallbackX, fallbackZ = ArenaTargeting.halfExtents(nil, 6, 42)
        expect(fallbackX).toBe(42)
        expect(fallbackZ).toBe(42)
    end)

    it("keeps overlapping bomb and meteor warnings apart when safe routes exist", function()
        local choose = ArenaTargeting.chooseSeparatedOffset
        local center = Vector3.new(12, 3, -8)
        local occupied = {Vector3.new(12, 50, -8)}
        local near = Vector3.new(3, 0, 0)
        local safe = Vector3.new(24, 0, 0)
        local far = Vector3.new(35, 0, 0)

        -- The vertical separation is intentionally ignored: the danger
        -- rings overlap on the player's X/Z map regardless of deck height.
        expect(choose({near, safe, far}, center, occupied, 22)).toBe(safe)
        expect(choose({near, safe, far}, center, occupied, 30)).toBe(far)
        expect(choose({near, safe}, center, occupied, 40)).toBe(safe)
        expect(choose({near}, center, {}, 22)).toBe(near)
        expect(choose({}, center, occupied, 22)).toBe(Vector3.zero)

        -- With two active hazards a new warning must consider BOTH zones,
        -- not just the most recently spawned marker.
        local paired = {
            Vector3.new(12, 0, -8),
            Vector3.new(52, 0, -8),
        }
        expect(choose({
            Vector3.new(3, 0, 0),
            Vector3.new(40, 0, 0),
            Vector3.new(21, 0, 25),
        }, center, paired, 22)).toBe(Vector3.new(21, 0, 25))

        -- The shared per-round marker set cannot retain destroyed instances;
        -- choosing a new random candidate automatically removes stale keys.
        local dead = Instance.new("Part")
        local pending = {[dead] = true}
        dead:Destroy()
        local offset = ArenaTargeting.randomSeparatedOffset(
            6, 42, center, pending, 22
        )
        expect(typeof(offset)).toBe("Vector3")
        expect(pending[dead] == nil).toBe(true)
    end)

    it("never publishes metadata for a removed or not-yet-ready arena", function()
        local map = Instance.new("Folder")
        map.Name = "GeneratedMap"
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = map

        expect(ArenaVariants.activeDefinition(arena, map)).toBe(nil)
        arena:SetAttribute("VariantId", "Towers")
        expect(ArenaVariants.activeDefinition(arena, map).Id).toBe("Towers")

        arena:SetAttribute("VariantId", "Unknown")
        expect(ArenaVariants.activeDefinition(arena, map)).toBe(nil)
        arena:SetAttribute("VariantId", "Orbital")
        expect(ArenaVariants.activeDefinition(arena, map).Id).toBe("Orbital")

        local replacement = Instance.new("Folder")
        replacement.Name = "GeneratedMap"
        expect(ArenaVariants.activeDefinition(arena, replacement)).toBe(nil)

        arena.Parent = nil
        expect(ArenaVariants.activeDefinition(arena, map)).toBe(nil)
        arena.Parent = replacement
        expect(ArenaVariants.activeDefinition(arena, replacement).Id).toBe("Orbital")

        arena.Name = "OldArena"
        expect(ArenaVariants.activeDefinition(arena, replacement)).toBe(nil)
        arena.Name = "Arena"
        replacement.Name = "RemovedMap"
        expect(ArenaVariants.activeDefinition(arena, replacement)).toBe(nil)

        map:Destroy()
        replacement:Destroy()
    end)

    it("gives every arena concise actionable strategy guidance", function()
        local seenHints = {}
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            expect(type(variant.StrategyHint)).toBe("string")
            expect(#variant.StrategyHint >= 24).toBe(true)
            expect(#variant.StrategyHint <= 96).toBe(true)
            expect(seenHints[variant.StrategyHint] == nil).toBe(true)
            seenHints[variant.StrategyHint] = true
        end
    end)

    it("never immediately repeats a map when alternatives exist", function()
        for _, previous in ipairs(ArenaVariants.Order) do
            for _ = 1, 20 do
                local nextId = ArenaVariants.choose(previous)
                expect(nextId ~= previous).toBe(true)
                expect(ArenaVariants.get(nextId) ~= nil).toBe(true)
            end
        end
    end)

    it("avoids both recently played maps", function()
        for _ = 1, 30 do
            local nextId = ArenaVariants.chooseRecent({"Classic", "Towers"})
            expect(nextId ~= "Classic").toBe(true)
            expect(nextId ~= "Towers").toBe(true)
            expect(ArenaVariants.get(nextId) ~= nil).toBe(true)
        end
    end)

    it("keeps recent history bounded and unique", function()
        local recent = ArenaVariants.pushRecent({"Classic", "Towers"}, "Orbital", 2)
        expect(#recent).toBe(2)
        expect(recent[1]).toBe("Orbital")
        expect(recent[2]).toBe("Classic")

        recent = ArenaVariants.pushRecent(recent, "Classic", 2)
        expect(#recent).toBe(2)
        expect(recent[1]).toBe("Classic")
        expect(recent[2]).toBe("Orbital")
    end)
end)

return nil
