local DisasterSetpiece = {}

DisasterSetpiece.Profiles = {
    RisingLava={Kind="rise",Color=Color3.fromRGB(255,92,28),Secondary=Color3.fromRGB(255,205,75)},
    Meteors={Kind="skyfall",Color=Color3.fromRGB(255,125,45),Secondary=Color3.fromRGB(255,220,120)},
    LowGravity={Kind="lift",Color=Color3.fromRGB(110,135,255),Secondary=Color3.fromRGB(205,220,255)},
    DisappearingPlatforms={Kind="fracture",Color=Color3.fromRGB(255,205,70),Secondary=Color3.fromRGB(255,240,155)},
    Tornado={Kind="spiral",Color=Color3.fromRGB(75,210,220),Secondary=Color3.fromRGB(190,245,245)},
    Freeze={Kind="freeze",Color=Color3.fromRGB(85,195,255),Secondary=Color3.fromRGB(205,245,255)},
    Bombs={Kind="blast",Color=Color3.fromRGB(255,65,65),Secondary=Color3.fromRGB(255,150,95)},
    SpeedSurge={Kind="speed",Color=Color3.fromRGB(245,80,205),Secondary=Color3.fromRGB(255,190,245)},
    Darkness={Kind="void",Color=Color3.fromRGB(100,90,205),Secondary=Color3.fromRGB(190,175,255)},
    ShrinkingArena={Kind="collapse",Color=Color3.fromRGB(185,80,245),Secondary=Color3.fromRGB(245,175,255)},
    JumpShock={Kind="shock",Color=Color3.fromRGB(80,155,255),Secondary=Color3.fromRGB(185,225,255)},
}

function DisasterSetpiece.get(id)
    return DisasterSetpiece.Profiles[id]
end

function DisasterSetpiece.forIds(ids)
    local out={}
    for _,id in ipairs(ids or {}) do
        local p=DisasterSetpiece.Profiles[id]
        if p then table.insert(out,p) end
    end
    return out
end

return DisasterSetpiece
