local Lighting = game:GetService("Lighting")
local D = {Name = "BLACKOUT", Hint = "VISIBILITY IS LOW — MOVE CAREFULLY!"}

function D.start(ctx)
    local oldBrightness = Lighting.Brightness
    local oldAmbient = Lighting.Ambient
    local oldOutdoor = Lighting.OutdoorAmbient

    Lighting.Brightness = 0.6
    Lighting.Ambient = Color3.fromRGB(24, 24, 36)
    Lighting.OutdoorAmbient = Color3.fromRGB(14, 14, 24)

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        Lighting.Brightness = oldBrightness
        Lighting.Ambient = oldAmbient
        Lighting.OutdoorAmbient = oldOutdoor
    end
end

return D
