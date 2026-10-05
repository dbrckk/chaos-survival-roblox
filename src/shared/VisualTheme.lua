local VisualTheme = {}

VisualTheme.World = {
    Void = Color3.fromRGB(7, 10, 18),
    Deep = Color3.fromRGB(13, 18, 29),
    Surface = Color3.fromRGB(27, 34, 48),
    SurfaceRaised = Color3.fromRGB(39, 48, 66),
    Metal = Color3.fromRGB(52, 62, 82),
    MetalLight = Color3.fromRGB(74, 86, 108),
    Text = Color3.fromRGB(242, 247, 255),
    MutedText = Color3.fromRGB(175, 190, 214),
}

VisualTheme.Accents = {
    Cyan = Color3.fromRGB(70, 215, 255),
    Blue = Color3.fromRGB(78, 142, 255),
    Violet = Color3.fromRGB(154, 92, 255),
    Magenta = Color3.fromRGB(245, 75, 210),
    Orange = Color3.fromRGB(255, 126, 54),
    Lime = Color3.fromRGB(115, 245, 172),
    Gold = Color3.fromRGB(255, 211, 92),
}

VisualTheme.Materials = {
    Floor = Enum.Material.Slate,
    Structure = Enum.Material.Metal,
    Panel = Enum.Material.DiamondPlate,
    Glow = Enum.Material.Neon,
}

VisualTheme.Glow = {
    SurfaceTransparency = 0.18,
    SecondaryTransparency = 0.42,
    LightBrightness = 1.15,
    LightRange = 24,
}

VisualTheme.Arenas = {
    Classic = {
        FloorMaterial = Enum.Material.DiamondPlate,
        StructureMaterial = Enum.Material.Metal,
        PanelMaterial = Enum.Material.DiamondPlate,
        Surface = Color3.fromRGB(31, 39, 55),
        Structure = Color3.fromRGB(62, 76, 102),
        Accent = Color3.fromRGB(72, 185, 255),
        Secondary = Color3.fromRGB(120, 100, 255),
        Detail = Color3.fromRGB(112, 135, 170),
    },
    Towers = {
        FloorMaterial = Enum.Material.Metal,
        StructureMaterial = Enum.Material.Metal,
        PanelMaterial = Enum.Material.DiamondPlate,
        Surface = Color3.fromRGB(28, 38, 52),
        Structure = Color3.fromRGB(55, 76, 92),
        Accent = Color3.fromRGB(62, 215, 225),
        Secondary = Color3.fromRGB(78, 135, 255),
        Detail = Color3.fromRGB(104, 160, 180),
    },
    Crossroads = {
        FloorMaterial = Enum.Material.Slate,
        StructureMaterial = Enum.Material.Metal,
        PanelMaterial = Enum.Material.DiamondPlate,
        Surface = Color3.fromRGB(37, 32, 50),
        Structure = Color3.fromRGB(73, 59, 92),
        Accent = Color3.fromRGB(213, 86, 255),
        Secondary = Color3.fromRGB(255, 105, 185),
        Detail = Color3.fromRGB(156, 115, 188),
    },
    Orbital = {
        FloorMaterial = Enum.Material.Metal,
        StructureMaterial = Enum.Material.Metal,
        PanelMaterial = Enum.Material.SmoothPlastic,
        Surface = Color3.fromRGB(23, 43, 48),
        Structure = Color3.fromRGB(50, 79, 82),
        Accent = Color3.fromRGB(76, 235, 190),
        Secondary = Color3.fromRGB(74, 188, 255),
        Detail = Color3.fromRGB(100, 170, 160),
    },
}

function VisualTheme.arena(id)
    return VisualTheme.Arenas[id] or VisualTheme.Arenas.Classic
end

return VisualTheme
