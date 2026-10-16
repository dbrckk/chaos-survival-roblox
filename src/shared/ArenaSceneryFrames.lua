-- Compute environmental scenery in the rotated arena's own coordinate system.
local ArenaSceneryFrames = {}
function ArenaSceneryFrames.point(base, offset)
    return base.CFrame:PointToWorldSpace(offset)
end
function ArenaSceneryFrames.frame(base, offset, yaw)
    return base.CFrame * CFrame.new(offset)
        * CFrame.Angles(0, yaw or 0, 0)
end
return ArenaSceneryFrames
