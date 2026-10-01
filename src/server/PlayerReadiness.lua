local Players = game:GetService("Players")

local PlayerReadiness = {}

function PlayerReadiness.waitForDataLoaded(player)
    while player.Parent == Players and player:GetAttribute("DataLoaded") ~= true do
        task.wait(0.05)
    end

    return player.Parent == Players and player:GetAttribute("DataLoaded") == true
end

return PlayerReadiness
