local Lighting = game:GetService("Lighting")
local D = {Name = "BLACKOUT", Hint = "FIND YOUR WAY!"}

function D.start(ctx)
    local oldBrightness = Lighting.Brightness
    local oldAmbient = Lighting.Ambient
    local oldOutdoor = Lighting.OutdoorAmbient

    Lighting.Brightness = 0.35
    Lighting.Ambient = Color3.fromRGB(10,10,18)
    Lighting.OutdoorAmbient = Color3.fromRGB(5,5,12)

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        Lighting.Brightness = oldBrightness
        Lighting.Ambient = oldAmbient
        Lighting.OutdoorAmbient = oldOutdoor
    end
end

return D
