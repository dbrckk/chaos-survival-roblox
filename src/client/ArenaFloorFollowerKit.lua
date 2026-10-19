-- Client-only, allocation-free follow transform for anchored arena surface art.
-- Shrinking Arena changes the authoritative Base.Size; without this, the
-- local top-layer paint and mechanical relief become a phantom full-size
-- floor even though the real server collision deck is smaller.
local ArenaFloorFollowerKit = {}

local function ratio(current, original)
    if type(current) ~= "number" or type(original) ~= "number"
        or original <= 0 then
        return 1
    end
    local value = current / original
    if value ~= value or value == math.huge or value == -math.huge then
        return 1
    end
    -- A late-streamed client may first build midway through a shrink:
    -- restoring a 45%-size arena later legitimately needs >2x scaling.
    return math.clamp(value, 0.05, 4)
end

function ArenaFloorFollowerKit.capture(base, container, options)
    if typeof(base) ~= "Instance" or not base:IsA("BasePart")
        or typeof(container) ~= "Instance" then
        return nil
    end

    -- Some visual owners mix static floor guides with moving pad markers.
    -- Select only the floor-bound pieces to avoid fighting their own
    -- attribute-driven marker updates during Shrinking Arena.
    local prefix = type(options) == "table"
        and type(options.namePrefix) == "string"
        and options.namePrefix ~= ""
        and options.namePrefix or nil

    local snapshot = {
        base = base,
        baseSize = base.Size,
        -- Solid-looking service equipment moves with the shrinking arena,
        -- but should not turn into miniature crates or camera rigs.
        preserveSize = type(options) == "table" and options.preserveSize == true,
        parts = {},
    }
    for _, piece in ipairs(container:GetChildren()) do
        if piece:IsA("BasePart")
            and (not prefix or string.sub(piece.Name, 1, #prefix) == prefix) then
            snapshot.parts[#snapshot.parts+1] = {
                part = piece,
                size = piece.Size,
                localCFrame = base.CFrame:ToObjectSpace(piece.CFrame),
            }
        end
    end
    return snapshot
end

function ArenaFloorFollowerKit.apply(snapshot)
    if not snapshot or not snapshot.base
        or not snapshot.base.Parent then
        return 0
    end

    local base = snapshot.base
    local scaleX = ratio(base.Size.X, snapshot.baseSize.X)
    local scaleZ = ratio(base.Size.Z, snapshot.baseSize.Z)
    local moved = 0
    for _, data in ipairs(snapshot.parts) do
        local part = data.part
        if part and part.Parent then
            local position = data.localCFrame.Position
            local rotation = data.localCFrame - position
            if not snapshot.preserveSize then
                part.Size = Vector3.new(
                    math.max(0.02, data.size.X * scaleX),
                    data.size.Y,
                    math.max(0.02, data.size.Z * scaleZ)
                )
            end
            part.CFrame = base.CFrame
                * CFrame.new(position.X * scaleX, position.Y, position.Z * scaleZ)
                * rotation
            moved += 1
        end
    end
    return moved
end

-- Bind exactly one event per visual owner. No RenderStepped, no polling,
-- and disconnect before deleting/replacing art after a streamed map swap.
function ArenaFloorFollowerKit.bind(base, container, options)
    local snapshot = ArenaFloorFollowerKit.capture(base, container, options)
    if not snapshot then
        return function() end
    end

    local alive = true
    local scheduled = false
    local connection = base:GetPropertyChangedSignal("Size"):Connect(function()
        if not alive or scheduled then return end
        scheduled = true
        task.defer(function()
            scheduled = false
            if alive then
                ArenaFloorFollowerKit.apply(snapshot)
            end
        end)
    end)

    return function()
        alive = false
        connection:Disconnect()
    end
end

return ArenaFloorFollowerKit
