local ArenaVariants = {}

ArenaVariants.Order = {"Classic", "Towers", "Crossroads", "Orbital"}

ArenaVariants.Definitions = {
    Classic = {
        Id = "Classic",
        Name = "CLASSIC GRID",
        BaseSize = Vector3.new(100, 2, 100),
        BaseColor = Color3.fromRGB(92, 103, 125),
        PlatformColor = Color3.fromRGB(120, 145, 190),
        SpawnOffsets = {
            Vector3.new(-30,3,-30), Vector3.new(30,3,-30),
            Vector3.new(-30,3,30), Vector3.new(30,3,30),
            Vector3.new(0,3,-35), Vector3.new(0,3,35),
            Vector3.new(-35,3,0), Vector3.new(35,3,0),
        },
        Platforms = (function()
            local result = {}
            local heights = {5, 10, 15, 20}
            for i = 1, 18 do
                table.insert(result, {
                    offset = Vector3.new(((i * 23) % 75) - 37, heights[(i % #heights) + 1], ((i * 41) % 75) - 37),
                    size = Vector3.new(12, 2, 12),
                })
            end
            return result
        end)(),
    },

    Towers = {
        Id = "Towers",
        Name = "TOWER RUN",
        BaseSize = Vector3.new(94, 2, 94),
        BaseColor = Color3.fromRGB(78, 88, 112),
        PlatformColor = Color3.fromRGB(105, 155, 185),
        SpawnOffsets = {
            Vector3.new(-32,3,-32), Vector3.new(32,3,-32),
            Vector3.new(-32,3,32), Vector3.new(32,3,32),
            Vector3.new(0,3,-38), Vector3.new(0,3,38),
            Vector3.new(-38,3,0), Vector3.new(38,3,0),
        },
        Platforms = {
            {offset=Vector3.new(-28,6,-28),size=Vector3.new(14,2,14)},
            {offset=Vector3.new(-28,12,-28),size=Vector3.new(10,2,10)},
            {offset=Vector3.new(-28,18,-28),size=Vector3.new(7,2,7)},
            {offset=Vector3.new(28,6,-28),size=Vector3.new(14,2,14)},
            {offset=Vector3.new(28,12,-28),size=Vector3.new(10,2,10)},
            {offset=Vector3.new(28,18,-28),size=Vector3.new(7,2,7)},
            {offset=Vector3.new(-28,6,28),size=Vector3.new(14,2,14)},
            {offset=Vector3.new(-28,12,28),size=Vector3.new(10,2,10)},
            {offset=Vector3.new(-28,18,28),size=Vector3.new(7,2,7)},
            {offset=Vector3.new(28,6,28),size=Vector3.new(14,2,14)},
            {offset=Vector3.new(28,12,28),size=Vector3.new(10,2,10)},
            {offset=Vector3.new(28,18,28),size=Vector3.new(7,2,7)},
            {offset=Vector3.new(0,8,0),size=Vector3.new(18,2,18)},
            {offset=Vector3.new(0,14,-24),size=Vector3.new(12,2,12)},
            {offset=Vector3.new(0,14,24),size=Vector3.new(12,2,12)},
            {offset=Vector3.new(-24,14,0),size=Vector3.new(12,2,12)},
            {offset=Vector3.new(24,14,0),size=Vector3.new(12,2,12)},
        },
    },


    Orbital = {
        Id = "Orbital",
        Name = "ORBITAL RING",
        BaseSize = Vector3.new(100, 2, 100),
        BaseColor = Color3.fromRGB(72, 82, 102),
        PlatformColor = Color3.fromRGB(90, 185, 175),
        SpawnOffsets = (function()
            local result = {}
            for i = 0, 7 do
                local angle = math.rad(i * 45)
                table.insert(result, Vector3.new(
                    math.cos(angle) * 35,
                    3,
                    math.sin(angle) * 35
                ))
            end
            return result
        end)(),
        Platforms = (function()
            local result = {}

            for i = 0, 7 do
                local angle = math.rad(i * 45)
                table.insert(result, {
                    offset = Vector3.new(
                        math.cos(angle) * 31,
                        6 + ((i % 2) * 2),
                        math.sin(angle) * 31
                    ),
                    size = Vector3.new(13, 2, 13),
                })
            end

            for i = 0, 7 do
                local angle = math.rad((i * 45) + 22.5)
                table.insert(result, {
                    offset = Vector3.new(
                        math.cos(angle) * 18,
                        11 + ((i % 2) * 2),
                        math.sin(angle) * 18
                    ),
                    size = Vector3.new(11, 2, 11),
                })
            end

            table.insert(result, {
                offset = Vector3.new(0, 7, 0),
                size = Vector3.new(18, 2, 18),
            })
            table.insert(result, {
                offset = Vector3.new(0, 15, 0),
                size = Vector3.new(11, 2, 11),
            })

            return result
        end)(),
    },

    Crossroads = {
        Id = "Crossroads",
        Name = "CROSSROADS",
        BaseSize = Vector3.new(104, 2, 104),
        BaseColor = Color3.fromRGB(86, 96, 110),
        PlatformColor = Color3.fromRGB(155, 125, 185),
        SpawnOffsets = {
            Vector3.new(-36,3,-18), Vector3.new(-36,3,18),
            Vector3.new(36,3,-18), Vector3.new(36,3,18),
            Vector3.new(-18,3,-36), Vector3.new(18,3,-36),
            Vector3.new(-18,3,36), Vector3.new(18,3,36),
        },
        Platforms = {
            {offset=Vector3.new(0,5,0),size=Vector3.new(18,2,18)},
            {offset=Vector3.new(-18,7,0),size=Vector3.new(14,2,12)},
            {offset=Vector3.new(-34,10,0),size=Vector3.new(12,2,12)},
            {offset=Vector3.new(18,7,0),size=Vector3.new(14,2,12)},
            {offset=Vector3.new(34,10,0),size=Vector3.new(12,2,12)},
            {offset=Vector3.new(0,7,-18),size=Vector3.new(12,2,14)},
            {offset=Vector3.new(0,10,-34),size=Vector3.new(12,2,12)},
            {offset=Vector3.new(0,7,18),size=Vector3.new(12,2,14)},
            {offset=Vector3.new(0,10,34),size=Vector3.new(12,2,12)},
            {offset=Vector3.new(-25,13,-25),size=Vector3.new(10,2,10)},
            {offset=Vector3.new(25,13,-25),size=Vector3.new(10,2,10)},
            {offset=Vector3.new(-25,13,25),size=Vector3.new(10,2,10)},
            {offset=Vector3.new(25,13,25),size=Vector3.new(10,2,10)},
            {offset=Vector3.new(-12,18,-12),size=Vector3.new(8,2,8)},
            {offset=Vector3.new(12,18,-12),size=Vector3.new(8,2,8)},
            {offset=Vector3.new(-12,18,12),size=Vector3.new(8,2,8)},
            {offset=Vector3.new(12,18,12),size=Vector3.new(8,2,8)},
        },
    },
}

function ArenaVariants.get(id)
    return ArenaVariants.Definitions[id]
end

function ArenaVariants.choose(previousId)
    local candidates = {}
    for _, id in ipairs(ArenaVariants.Order) do
        if id ~= previousId then
            table.insert(candidates, id)
        end
    end

    if #candidates == 0 then
        candidates = ArenaVariants.Order
    end

    return candidates[math.random(1, #candidates)]
end

return ArenaVariants
