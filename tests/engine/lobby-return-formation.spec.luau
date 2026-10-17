--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local LobbyReturnFormation = require("../../src/server/LobbyReturnFormation")
local LobbySpawnSafety = require("../../src/server/LobbySpawnSafety")

describe("Lobby survivor return formation", function()
    it("recovers embedded or immobilized lobby rigs without nudging healthy arrivals", function()
        local check = LobbySpawnSafety.needsRecovery
        -- A normal rig can float within one stud of the landing surface
        -- while the engine settles without requiring a server teleport.
        expect(check(9.0, 9.0, false, false)).toBe(false)
        expect(check(8.05, 9.0, false, false)).toBe(false)
        expect(check(7.99, 9.0, false, false)).toBe(true)
        -- Raised centre-stage collisions are checked against its top.
        expect(check(5.0, 7.0, false, false)).toBe(true)
        -- An anchored or PlatformStand rig is still stranded at normal Y.
        expect(check(9.0, 9.0, true, false)).toBe(true)
        expect(check(9.0, 9.0, false, true)).toBe(true)
    end)

    it("returns zero positions for invalid inputs or zero contestants", function()
        expect(#LobbyReturnFormation.positions(nil, nil, nil, 3)).toBe(0)
        local root = MapBuilder.build(Config, "Classic", ArenaVariants)
        local lobby = root:FindFirstChild("Lobby")
        expect(#LobbyReturnFormation.positions(
            lobby:FindFirstChild("LobbySpawn"),
            lobby:FindFirstChild("Floor"),
            lobby:FindFirstChild("Decor"), 0
        )).toBe(0)
        root:Destroy()
    end)

    it("keeps eight survivors separated, supported and off solid decor", function()
        local root = MapBuilder.build(Config, "Classic", ArenaVariants)
        local lobby = root:FindFirstChild("Lobby")
        local spawn = lobby:FindFirstChild("LobbySpawn")
        local floor = lobby:FindFirstChild("Floor")
        local decor = lobby:FindFirstChild("Decor")
        local positions = LobbyReturnFormation.positions(spawn, floor, decor, 8)
        expect(#positions).toBe(8)

        local floorTop = floor.Position.Y + floor.Size.Y * 0.5
        for i, position in ipairs(positions) do
            local localPosition = floor.CFrame:PointToObjectSpace(position)
            expect(math.abs(localPosition.X) + 2.6 < floor.Size.X * 0.5).toBe(true)
            expect(math.abs(localPosition.Z) + 2.6 < floor.Size.Z * 0.5).toBe(true)
            for j = 1, i - 1 do
                expect((position - positions[j]).Magnitude >= 5.2).toBe(true)
            end
            for _, part in ipairs(decor:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    local top = part.Position.Y + part.Size.Y * 0.5
                    local bottom = part.Position.Y - part.Size.Y * 0.5
                    if top > floorTop + 0.8 and bottom < floorTop + 8 then
                        local localPart = part.CFrame:PointToObjectSpace(position)
                        local overlaps = math.abs(localPart.X) < part.Size.X * 0.5 + 2.6
                            and math.abs(localPart.Z) < part.Size.Z * 0.5 + 2.6
                        expect(overlaps).toBe(false)
                    end
                end
            end
        end
        root:Destroy()
    end)

    it("lands three R15 AI survivors away from the raised stage and players", function()
        local root = MapBuilder.build(Config, "Classic", ArenaVariants)
        local lobby = root:FindFirstChild("Lobby")
        local spawn = lobby:FindFirstChild("LobbySpawn")
        local floor = lobby:FindFirstChild("Floor")
        local decor = lobby:FindFirstChild("Decor")
        local stage = decor:FindFirstChild("CenterPlatform")
        local humanPositions = LobbyReturnFormation.positions(spawn, floor, decor, 8)
        local positions = {}
        local floorTop = floor.Position.Y + floor.Size.Y * 0.5

        for slot = 1, 3 do
            local landing = LobbyReturnFormation.botLanding(
                spawn, floor, decor, slot, 2.2, 1.0
            )
            expect(landing ~= nil).toBe(true)
            if landing then
                local position = landing.Position
                table.insert(positions, position)
                expect(math.abs(position.Y - (floorTop + 4.2)) < 0.01).toBe(true)
                local stagePosition = stage.CFrame:PointToObjectSpace(position)
                local outsideStage = math.abs(stagePosition.X) >= stage.Size.X * 0.5 + 2.6
                    or math.abs(stagePosition.Z) >= stage.Size.Z * 0.5 + 2.6
                expect(outsideStage).toBe(true)
                for _, human in ipairs(humanPositions) do
                    expect((Vector3.new(position.X, 0, position.Z)
                        - Vector3.new(human.X, 0, human.Z)).Magnitude >= 5.2).toBe(true)
                end
                for index = 1, #positions - 1 do
                    expect((position - positions[index]).Magnitude >= 5.2).toBe(true)
                end
                for _, part in ipairs(decor:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        local top = part.Position.Y + part.Size.Y * 0.5
                        local bottom = part.Position.Y - part.Size.Y * 0.5
                        if top > floorTop + 0.8 and bottom < floorTop + 8 then
                            local localPart = part.CFrame:PointToObjectSpace(position)
                            local overlaps = math.abs(localPart.X) < part.Size.X * 0.5 + 2.6
                                and math.abs(localPart.Z) < part.Size.Z * 0.5 + 2.6
                            expect(overlaps).toBe(false)
                        end
                    end
                end
            end
        end

        expect(LobbyReturnFormation.botLanding(spawn, floor, decor, 0, 2, 1)).toBe(nil)
        expect(LobbyReturnFormation.botLanding(spawn, floor, decor, 4, 2, 1)).toBe(nil)
        root:Destroy()
    end)

    it("returns distinct coordinates for repeated formation requests", function()
        local root = MapBuilder.build(Config, "Classic", ArenaVariants)
        local lobby = root:FindFirstChild("Lobby")
        local spawn = lobby:FindFirstChild("LobbySpawn")
        local floor = lobby:FindFirstChild("Floor")
        local decor = lobby:FindFirstChild("Decor")
        local first = LobbyReturnFormation.positions(spawn, floor, decor, 6)
        local second = LobbyReturnFormation.positions(spawn, floor, decor, 6)
        expect(#first).toBe(6)
        expect(#second).toBe(6)
        for i = 1, 6 do
            expect(first[i]).toBe(second[i])
        end
        root:Destroy()
    end)
end)

return nil
