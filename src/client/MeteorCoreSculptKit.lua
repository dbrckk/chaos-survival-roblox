-- Client-only, weld-following facets turn the server's basalt sphere into a
-- recognizable fractured meteor. No hitboxes, network ownership or damage.
local MeteorCoreSculptKit = {}

function MeteorCoreSculptKit.build(meteor, tier, rules)
    if typeof(meteor) ~= "Instance" or not meteor:IsA("BasePart")
        or not meteor.Parent or type(rules) ~= "table" then
        return {}
    end
    local pieces = {}
    local count = rules.corePlateCount(tier)
    for index = 1, count do
        local recipe = rules.corePlate(index, count, meteor.Size.X)
        if recipe then
            local plate = Instance.new("WedgePart")
            plate.Name = "LocalMeteorFacet" .. index
            plate.Size = recipe.Size
            plate.CFrame = meteor.CFrame * recipe.Transform
            plate.Material = recipe.Material
            plate.Color = recipe.Color
            plate.Transparency = recipe.Transparency
            plate.Anchored = false
            plate.Massless = true
            plate.CanCollide = false
            plate.CanTouch = false
            plate.CanQuery = false
            plate.CastShadow = false
            plate.Parent = meteor

            local weld = Instance.new("WeldConstraint")
            weld.Name = "MeteorFacetWeld"
            weld.Part0 = meteor
            weld.Part1 = plate
            weld.Parent = plate

            pieces[#pieces + 1] = plate
        end
    end
    return pieces
end

function MeteorCoreSculptKit.clear(pieces)
    if type(pieces) ~= "table" then return end
    for _, piece in ipairs(pieces) do
        if piece then piece:Destroy() end
    end
end

return MeteorCoreSculptKit
