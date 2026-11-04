-- Client-only visual substitution for SERVER-authored primitive trim.
-- Never remove, move, resize, recolor, or collide with gameplay Parts.
-- The live server continues owning its original fallback and hazard cues.
-- Hide native structural trim ONLY while a provenance-checked genuine
-- MeshPart carapace/girder is already in the existing platform owner.
local Kit = {}

local saved = {}
local watchers = {}
local decorWatcher = nil
local activeDecor = nil
local active = {}
local notify = nil
local count = 0

local function report()
    if notify then notify(count) end
end

local function restore()
    for part, original in pairs(saved) do
        if part and part.Parent then
            part.LocalTransparencyModifier = original
        end
        saved[part] = nil
    end
    count = 0
    report()
end

function Kit.reset()
    for _, connection in ipairs(watchers) do
        connection:Disconnect()
    end
    table.clear(watchers)
    decorWatcher = nil
    activeDecor = nil
    restore()
    table.clear(active)
    notify = nil
end

local function eligible(part)
    if not activeDecor or part.Parent ~= activeDecor
        or not part:IsA("BasePart") or not part.Anchored
        or part.CanCollide or part.CanTouch or part.CanQuery then
        return false
    end
    local name = part.Name
    local id = name:match("^PlatformBevel(%d+)_%d+$")
    if id and active[id] == "carapace" then
        -- Sloped WedgePart server edge, now replaced by a real sculpted
        -- SIDE face, not a gameplay warning or a walkable landing.
        return part:IsA("WedgePart")
            and part:GetAttribute("OriginalStructuralBevel") == true
    end
    id = name:match("^PlatformUnderFrame(%d+)$")
    if id and active[id] == "carapace" then
        return part:GetAttribute("PremiumArchitecturalSurface") == true
    end
    id = name:match("^SkybridgeRib(%d+)_")
    if id and active[id] == "bridge" then
        -- Keep SkybridgeRailN_±1 luminous wayfinding plus ALL shutter
        -- warnings. Only these three decorative under-deck block ribs
        -- have a genuine imported structural replacement.
        return part.Name:match("^SkybridgeRib%d+_%-?%d+$") ~= nil
    end
    return false
end

local function tryMask(part)
    if not eligible(part) or saved[part] ~= nil then return end
    saved[part] = part.LocalTransparencyModifier
    part.LocalTransparencyModifier = 1
    count += 1
end

local function attachDecor(folder)
    if folder == activeDecor then return end
    if decorWatcher then
        decorWatcher:Disconnect()
        decorWatcher = nil
    end
    -- A streamed Decor folder might disappear while the map is live.
    -- Restore masks on old Instances before reattaching a new folder.
    restore()
    activeDecor = nil
    if not folder or not folder:IsA("Folder") then return end
    activeDecor = folder
    for _, child in ipairs(folder:GetChildren()) do
        tryMask(child)
    end
    report()
    decorWatcher = folder.ChildAdded:Connect(function(part)
        if part:IsA("BasePart") then
            local before = count
            tryMask(part)
            if before ~= count then report() end
        end
    end)
    watchers[#watchers + 1] = decorWatcher
end

function Kit.bind(arena, replacements, onChange)
    Kit.reset()
    if not arena or not arena:IsA("Folder")
        or type(replacements) ~= "table" then return end
    notify = onChange
    for id, kind in pairs(replacements) do
        if type(id) == "string"
            and id:match("^%d+$") and (#id < 6)
            and (kind == "carapace" or kind == "bridge") then
            active[id] = kind
        end
    end
    attachDecor(arena:FindFirstChild("Decor"))
    watchers[#watchers + 1] = arena.ChildAdded:Connect(function(child)
        if child.Name == "Decor" and child:IsA("Folder") then
            attachDecor(child)
        end
    end)
    watchers[#watchers + 1] = arena.ChildRemoved:Connect(function(child)
        if child == activeDecor then
            attachDecor(nil)
        end
    end)
    report()
end

function Kit.count()
    return count
end

return Kit
