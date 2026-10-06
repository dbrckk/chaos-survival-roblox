local CameraFeelBus = {}

local movementFovOffset = 0

function CameraFeelBus.setMovementFovOffset(value)
    movementFovOffset = math.clamp(tonumber(value) or 0, -8, 8)
end

function CameraFeelBus.getMovementFovOffset()
    return movementFovOffset
end

function CameraFeelBus.reset()
    movementFovOffset = 0
end

return CameraFeelBus
