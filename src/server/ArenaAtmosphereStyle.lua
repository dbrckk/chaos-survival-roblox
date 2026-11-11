--!strict
-- Server atmosphere identity only. Existing four arenas retain their exact
-- prior colors and dimensions. Harbor reuses its actual ground/art palette
-- rather than silently inheriting Classic survey-grid blue and violet.
local VisualTheme = if script and script.Parent
    then require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("VisualTheme"))
    else require("../shared/VisualTheme")

local Style = {}

local PREVIOUS = {
    Classic = {
        accent = Color3.fromRGB(90, 180, 255),
        secondary = Color3.fromRGB(150, 95, 255),
        pillarHeight = 8,
        ringRadius = 43,
    },
    Towers = {
        accent = Color3.fromRGB(65, 220, 255),
        secondary = Color3.fromRGB(255, 185, 70),
        pillarHeight = 18,
        ringRadius = 40,
    },
    Crossroads = {
        accent = Color3.fromRGB(205, 105, 255),
        secondary = Color3.fromRGB(255, 95, 155),
        pillarHeight = 11,
        ringRadius = 44,
    },
    Orbital = {
        accent = Color3.fromRGB(65, 255, 205),
        secondary = Color3.fromRGB(95, 135, 255),
        pillarHeight = 13,
        ringRadius = 42,
    },
}

function Style.profileFor(variantId)
    if variantId == "Harbor" then
        -- Uses the same muted seafoam, salt-worn steel and blue
        -- identification signals as the Harbor map and daylight renderer.
        -- Orange/red remain reserved for hazard navigation.
        local harbor = VisualTheme.arena("Harbor")
        return {
            accent = harbor.Accent,
            secondary = harbor.Secondary,
            structure = harbor.Structure,
            detail = harbor.Detail,
            pillarHeight = 11,
            ringRadius = 43,
        }
    end
    return PREVIOUS[variantId] or PREVIOUS.Classic
end

return Style
