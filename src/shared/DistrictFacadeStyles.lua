--!strict
-- The same ORIGINAL front-door material language is used on both server
-- structural masses and client-only close-range hardware. Never duplicate
-- variant finish tables in separate rendering owners.
local Styles = {
    Classic = {recess = Enum.Material.CorrodedMetal, door = Enum.Material.DiamondPlate,
        lintel = Enum.Material.Metal, canopy = Enum.Material.Metal,
        hardware = Enum.Material.Metal, canopyDepth = 1.85},
    Towers = {recess = Enum.Material.Metal, door = Enum.Material.Foil,
        lintel = Enum.Material.DiamondPlate, canopy = Enum.Material.DiamondPlate,
        hardware = Enum.Material.Metal, canopyDepth = 2.45},
    Crossroads = {recess = Enum.Material.CorrodedMetal, door = Enum.Material.DiamondPlate,
        lintel = Enum.Material.CorrodedMetal, canopy = Enum.Material.Concrete,
        hardware = Enum.Material.CorrodedMetal, canopyDepth = 2.20},
    Orbital = {recess = Enum.Material.CeramicTiles, door = Enum.Material.CeramicTiles,
        lintel = Enum.Material.Metal, canopy = Enum.Material.CeramicTiles,
        hardware = Enum.Material.Metal, canopyDepth = 2.0},
    Harbor = {recess = Enum.Material.CorrodedMetal, door = Enum.Material.CorrodedMetal,
        lintel = Enum.Material.CorrodedMetal, canopy = Enum.Material.WoodPlanks,
        hardware = Enum.Material.CorrodedMetal, canopyDepth = 3.0},
}
return table.freeze(Styles)
