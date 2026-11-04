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
local verifiedSupports = {}
local notify = nil
local count = 0
-- Only physical PlatformN/SkybridgeN colliders can authorize masking
-- their own server-produced cosmetic underside. This is deliberately
-- tracked per current streamed map, never as a global visual preference.
local activePlatforms = nil
local ownerBaselines = {}
local watchedOwners = {}
local verifiedSupportIndices = {}

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
    table.clear(verifiedSupports)
    table.clear(verifiedSupportIndices)
    table.clear(ownerBaselines)
    table.clear(watchedOwners)
    activePlatforms = nil
    notify = nil
end

local function eligible(part)
    if not activeDecor or part.Parent ~= activeDecor
        or not part:IsA("BasePart") or not part.Anchored
        or part.CanCollide or part.CanTouch or part.CanQuery then
        return false
    end
    local name = part.Name
    if verifiedSupports[part] == true then
        -- The replacement mounted all real MeshPart segments on THIS
        -- exact server-authored nonphysical support. Never mask another
        -- deck's support, or a Part not explicitly verified/mounted.
        return name:match("^PlatformSupport%d+_%d+$") ~= nil
    end
    local id = name:match("^PlatformBevel(%d+)_%d+$")
    if id and active[id] == "carapace" then
        -- Sloped WedgePart server edge, now replaced by a real sculpted
        -- SIDE face, not a gameplay warning or a walkable landing.
        return part:IsA("WedgePart")
            and part:GetAttribute("OriginalStructuralBevel") == true
    end
    id = name:match("^PlatformUnderFrame(%d+)$")
    if id and (active[id] == "carapace" or active[id] == "cradle") then
        return part:GetAttribute("PremiumArchitecturalSurface") == true
    end
    -- The 22-stud provenance-checked LongCradle genuinely covers the
    -- structural underside of a physical Sky Spine / promenade deck.
    -- Retire ONLY the old nonphysical rectangular trusses. Lit edges,
    -- arrow chevrons, pylons, consoles and warning glyphs remain visible.
    id = name:match("^SkySpine(%d+)_Undercarriage%-?1$")
        or name:match("^SkySpine(%d+)_CrossStiffener$")
    if id and active[id] == "cradle" then
        return part:GetAttribute("SkySpineDecor") == true
            and part:GetAttribute("PerimeterPlatformIndex") == tonumber(id)
    end
    id = name:match("^Promenade(%d+)_UnderdeckTruss$")
    if id and active[id] == "cradle" then
        return part:GetAttribute("PromenadeVisualOnly") == true
            and part:GetAttribute("PerimeterPlatformIndex") == tonumber(id)
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

-- A cosmetic WedgePart / support is NOT permission to hide its
-- native fallback. Resolve the real server-authored playable owner by
-- exact index and name, independently of the visual model's name.
local function physicalOwner(native)
    if not activePlatforms or not native then return nil end
    local name = native.Name
    local bridge = name:match("^SkybridgeRib(%d+)_")
    if bridge then
        return activePlatforms:FindFirstChild("Skybridge"..bridge)
    end
    local id = name:match("^PlatformBevel(%d+)_")
        or name:match("^PlatformUnderFrame(%d+)$")
        or name:match("^PlatformSupport(%d+)_")
        or name:match("^SkySpine(%d+)_")
        or name:match("^Promenade(%d+)_")
    if not id then return nil end
    return activePlatforms:FindFirstChild("Platform"..id)
end

-- A pure condition on REAL Roblox Parts, also checked in the
-- important engine milestone. This does not alter collision itself.
function Kit.authorizesMask(owner, original, platforms)
    if not platforms or not platforms:IsA("Folder")
        or not owner or not owner:IsA("BasePart")
        or owner.Parent ~= platforms
        or not owner.Anchored or not owner.CanCollide
        or owner.Transparency >= 0.75
        or typeof(original) ~= "Vector3" then
        return false
    end
    local phase = owner:GetAttribute("CollapsePhase")
    if phase ~= nil and phase ~= "Normal" and phase ~= "Safe" then
        return false
    end
    local shutter = owner:GetAttribute("BridgeShutterPhase")
    if shutter ~= nil and shutter ~= "Idle" then
        return false
    end
    -- Only mask while the source-authored imported 3D still matches
    -- the native Part's initial physical footprint.
    return math.abs(owner.Size.X-original.X) < 0.09
        and math.abs(owner.Size.Z-original.Z) < 0.09
end

local function physicalSafe(native)
    local owner = physicalOwner(native)
    return Kit.authorizesMask(owner, owner and ownerBaselines[owner],
        activePlatforms)
end

local function tryMask(part)
    if not eligible(part) or saved[part] ~= nil
        or not physicalSafe(part) then return end
    saved[part] = part.LocalTransparencyModifier
    part.LocalTransparencyModifier = 1
    count += 1
end

-- Event-based reconciliation; does not poll a frame or create Parts.
-- A server collapse warning or shutter must restore the native fallback
-- even if the approved 3D clone itself is merely faded, not destroyed.
local function reconcile()
    local before = count
    for part, original in pairs(saved) do
        if part.Parent ~= activeDecor or not eligible(part)
            or not physicalSafe(part) then
            if part.Parent then part.LocalTransparencyModifier = original end
            saved[part] = nil
            count -= 1
        end
    end
    if activeDecor then
        for _, part in ipairs(activeDecor:GetChildren()) do
            if part:IsA("BasePart") then tryMask(part) end
        end
    end
    if count ~= before then report() end
end

local function watchOwner(part)
    if not part or not part:IsA("BasePart")
        or watchedOwners[part] then return end
    local platformId = part.Name:match("^Platform(%d+)$")
    local bridgeId = part.Name:match("^Skybridge(%d+)$")
    local id = platformId or bridgeId
    if not id then return end
    local kind = active[id]
    if platformId and not (kind == "carapace" or kind == "cradle"
        or verifiedSupportIndices[id] == true) then return end
    if bridgeId and kind ~= "bridge" then return end
    watchedOwners[part] = true
    ownerBaselines[part] = part.Size
    for _, property in ipairs({"CanCollide","Transparency","Size"}) do
        watchers[#watchers+1] =
            part:GetPropertyChangedSignal(property):Connect(reconcile)
    end
    for _, attribute in ipairs({"CollapsePhase","BridgeShutterPhase"}) do
        watchers[#watchers+1] =
            part:GetAttributeChangedSignal(attribute):Connect(reconcile)
    end
end

local function attachPlatforms(folder)
    if folder == activePlatforms then return end
    activePlatforms = nil
    -- Each old platform's event handlers are still in the map's bounded
    -- watchers list, but cannot reauthorize masks after its folder swaps.
    if not folder or not folder:IsA("Folder") then
        reconcile()
        return
    end
    activePlatforms = folder
    for _, part in ipairs(folder:GetChildren()) do watchOwner(part) end
    watchers[#watchers+1] = folder.ChildAdded:Connect(function(part)
        watchOwner(part)
        reconcile()
    end)
    watchers[#watchers+1] = folder.ChildRemoved:Connect(reconcile)
    reconcile()
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

function Kit.bind(arena, replacements, onChange, supports, meshFolder)
    Kit.reset()
    if not arena or not arena:IsA("Folder")
        or type(replacements) ~= "table" then return end
    notify = onChange
    for id, kind in pairs(replacements) do
        if type(id) == "string"
            and id:match("^%d+$") and (#id < 6)
            and (kind == "carapace" or kind == "bridge"
                or kind == "cradle") then
            active[id] = kind
        end
    end
    if type(supports) == "table" then
        for _, part in ipairs(supports) do
            if part and part:IsA("BasePart")
                and part.Parent == arena:FindFirstChild("Decor")
                and part.Anchored and not part.CanCollide
                and not part.CanTouch and not part.CanQuery
                and part.Name:match("^PlatformSupport%d+_%d+$") then
                verifiedSupports[part] = true
                local id = part.Name:match("^PlatformSupport(%d+)_")
                if id then verifiedSupportIndices[id] = true end
            end
        end
    end
    -- Watch the REAL physical PlatformN/SkybridgeN owners before masking
    -- their native cosmetic underframes. Streaming in late also reconciles.
    attachPlatforms(arena:FindFirstChild("Platforms"))
    attachDecor(arena:FindFirstChild("Decor"))
    -- Fail CLOSED if any genuine replacement mesh disappears unexpectedly
    -- (streaming, asset deletion or local teardown). Restore the complete
    -- server-authored native fallback immediately instead of leaving a
    -- visually hollow deck. The next normal owner rebuild can re-mask.
    -- One ChildRemoved signal per active map, not one per MeshPart.
    if meshFolder and meshFolder:IsA("Folder") then
        watchers[#watchers + 1] = meshFolder.ChildRemoved:Connect(
            function(child)
                if child:IsA("MeshPart")
                    and (child:GetAttribute("Original3DStructuralSide") == true
                        or child:GetAttribute("OriginalLargeStructure3D") == true
                        or child:GetAttribute("OriginalLargeDeckHull") == true) then
                    table.clear(active)
                    table.clear(verifiedSupports)
                    restore()
                end
            end)
    end
    watchers[#watchers + 1] = arena.ChildAdded:Connect(function(child)
        if child.Name == "Decor" and child:IsA("Folder") then
            attachDecor(child)
        elseif child.Name == "Platforms" and child:IsA("Folder") then
            attachPlatforms(child)
        end
    end)
    watchers[#watchers + 1] = arena.ChildRemoved:Connect(function(child)
        if child == activeDecor then
            attachDecor(nil)
        elseif child == activePlatforms then
            attachPlatforms(nil)
        end
    end)
    report()
end

function Kit.count()
    return count
end

return Kit
