local SweepLaneBounds = {}

-- Both pulses include a small margin around the painted floor.
function SweepLaneBounds.halfExtents(band)
    local size = band.Size
    return size.X * 0.5 + 0.3, size.Z * 0.5 + 0.3
end

return SweepLaneBounds
