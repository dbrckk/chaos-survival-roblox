-- A single per-client foreground notification lane. ModuleScripts are cached
-- independently in each Roblox client, so no RemoteEvents or server state.
-- HUD phase/timer and touch actions are NOT optional notifications.
local signal = Instance.new("BindableEvent")
local owner = nil
local priority = 0

local MobileHudNotices = {}
MobileHudNotices.Changed = signal.Event

function MobileHudNotices.claim(name, rank)
    assert(type(name) == "string" and name ~= "", "notification name is required")
    assert(type(rank) == "number" and rank >= 0, "notification priority is required")
    if owner ~= nil and owner ~= name and priority > rank then
        return false
    end
    if owner == name then
        priority = math.max(priority, rank)
        return true
    end
    owner = name
    priority = rank
    signal:Fire(owner)
    return true
end

function MobileHudNotices.release(name)
    if owner ~= name then
        return false
    end
    owner = nil
    priority = 0
    signal:Fire(nil)
    return true
end

function MobileHudNotices.current()
    return owner
end

return MobileHudNotices
