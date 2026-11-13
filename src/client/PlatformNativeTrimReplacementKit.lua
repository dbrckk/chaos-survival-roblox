-- Client-only visual substitution for SERVER-authored primitive trim.
-- Never remove, move, resize, recolor, or collide with gameplay Parts.
-- The live server continues owning its original fallback and hazard cues.
-- Hide native structural trim ONLY while a provenance-checked genuine
-- MeshPart carapace/girder is already in the existing platform owner.
local Kit = {}

local saved = {}
local watchers = {}
local decorWatcher = nil
local decorRemovedWatcher = nil
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
    decorRemovedWatcher = nil
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
    if decorRemovedWatcher then
        decorRemovedWatcher:Disconnect()
        decorRemovedWatcher = nil
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
    -- Streaming can remove an already-masked native part without changing
    -- the Platforms or Decor FOLDER. Drop that exact stale baseline/count
    -- immediately; never retain a phantom replacement in diagnostics.
    decorRemovedWatcher = folder.ChildRemoved:Connect(function(part)
        local original = saved[part]
        if original == nil then return end
        if part.Parent then
            part.LocalTransparencyModifier = original
        end
        saved[part] = nil
        count -= 1
        report()
    end)
    watchers[#watchers + 1] = decorRemovedWatcher
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
    -- In production, masks require a COMPLETE, owner-verified source,
    -- not a boolean replacement tag or one surviving MeshPart. Start with
    -- ZERO authorized masks until the actual mounted source is counted.
    -- Caller-supplied source-less engine fixtures retain their old API.
    local approvedKinds = nil
    local approvedSupports = nil
    if meshFolder and meshFolder:IsA("Folder") then
        approvedKinds = table.clone(active)
        approvedSupports = table.clone(verifiedSupports)
        table.clear(active)
        table.clear(verifiedSupports)
    end
    -- Watch the REAL physical PlatformN/SkybridgeN owners before masking
    -- their native cosmetic underframes. Streaming in late also reconciles.
    attachPlatforms(arena:FindFirstChild("Platforms"))
    attachDecor(arena:FindFirstChild("Decor"))
    -- A previous all-or-nothing guard restored EVERY native platform when
    -- ONE original MeshPart vanished. This emptied the premium silhouettes
    -- of four perfectly healthy route districts until an unrelated rebuild.
    -- Resolve each mounted source piece to its EXACT existing physical
    -- PlatformN/SkybridgeN or verified noncolliding PlatformSupportN_K.
    -- Losing one piece revokes only THAT owner's native masking; all other
    -- genuine 3D shells stay visible. Never infer ownership from mesh name.
    -- Local clone assembly completes before bind(); one bounded snapshot,
    -- one ChildRemoved subscription and no per-part render/heartbeat loop.
    if meshFolder and meshFolder:IsA("Folder") then
        local sourceOwnerByPiece = {}
        local livePiecesByOwner = {}
        local requiredPiecesByOwner = {}
        local initializing = true
        local platformFolder = arena:FindFirstChild("Platforms")
        -- Source identity is checked against the actual welded server
        -- owner, never the mesh name or arbitrary client-supplied count.
        local function sourceOwner(piece)
            if not piece:IsA("MeshPart")
                or not (piece:GetAttribute("Original3DStructuralSide") == true
                    or piece:GetAttribute("OriginalLargeStructure3D") == true
                    or piece:GetAttribute("OriginalLargeDeckHull") == true)
                or piece.Parent ~= meshFolder then return nil end
            local joint = piece:FindFirstChild("ChaosPlatformTrimWeld")
                or piece:FindFirstChild("OriginalSupportVisualWeld")
            if not joint or (not joint:IsA("Weld")
                and not joint:IsA("WeldConstraint")) then return nil end
            local owner = joint.Part1
            if not owner or not owner:IsA("BasePart") then return nil end
            if approvedSupports[owner] == true then
                return owner, owner
            end
            if owner.Parent ~= platformFolder then return nil end
            local platformId = owner.Name:match("^Platform(%d+)$")
            local bridgeId = owner.Name:match("^Skybridge(%d+)$")
            local id = platformId or bridgeId
            if id and ((platformId
                    and (approvedKinds[id] == "carapace"
                        or approvedKinds[id] == "cradle"))
                or (bridgeId and approvedKinds[id] == "bridge")) then
                return id, owner
            end
            return nil
        end
        -- A single complete seven-material approved source contains 7
        -- MeshParts; stacked pillars and bridge sides contain multiples
        -- of 7. Capture the FULL initial welded source bundle once.
        -- Never infer a complete kit from a lone streamed sibling.
        for _, piece in ipairs(meshFolder:GetChildren()) do
            local key = sourceOwner(piece)
            if key then
                requiredPiecesByOwner[key] =
                    (requiredPiecesByOwner[key] or 0) + 1
            end
        end
        local function sourceComplete(key)
            local required = requiredPiecesByOwner[key]
            return required ~= nil and required >= 7
                and required % 7 == 0
                and (livePiecesByOwner[key] or 0) == required
        end
        local function refreshOwner(key, owner)
            if type(key) == "string" then
                active[key] = sourceComplete(key) and approvedKinds[key]
                    or nil
                if active[key] then watchOwner(owner) end
            else
                verifiedSupports[key] = sourceComplete(key) and true or nil
            end
            -- Initial source census can contain hundreds of approved
            -- MeshParts. Reconcile ONCE after the complete snapshot, not
            -- once per source material while scanning all native Decor.
            if not initializing then reconcile() end
        end
        local function registerSourcePiece(piece)
            if sourceOwnerByPiece[piece] ~= nil then return end
            local key, owner = sourceOwner(piece)
            if not key then return end
            sourceOwnerByPiece[piece] = key
            livePiecesByOwner[key] = (livePiecesByOwner[key] or 0) + 1
            refreshOwner(key, owner)
        end
        for _, piece in ipairs(meshFolder:GetChildren()) do
            registerSourcePiece(piece)
        end
        initializing = false
        reconcile()
        -- Streaming may add the remaining MeshParts after the folder is
        -- initially bound. Track only verified, welded source geometry.
        watchers[#watchers + 1] =
            meshFolder.ChildAdded:Connect(registerSourcePiece)
        -- StreamingEnabled can replicate a MeshPart before its Weld
        -- child. One folder-level listener retries only verified weld
        -- arrivals; no per-MeshPart listener or polling is needed.
        watchers[#watchers + 1] =
            meshFolder.DescendantAdded:Connect(function(descendant)
                if (descendant.Name ~= "ChaosPlatformTrimWeld"
                        and descendant.Name ~= "OriginalSupportVisualWeld")
                    or (not descendant:IsA("Weld")
                        and not descendant:IsA("WeldConstraint")) then
                    return
                end
                local piece = descendant.Parent
                if piece and piece.Parent == meshFolder then
                    registerSourcePiece(piece)
                end
            end)
        local function revokeSourcePiece(piece)
            local owner = sourceOwnerByPiece[piece]
            sourceOwnerByPiece[piece] = nil
            -- A decorative MeshPart without an approved welded server
            -- owner never affects a native platform silhouette.
            if owner == nil then return end
            local remaining = math.max(0,
                (livePiecesByOwner[owner] or 1) - 1)
            livePiecesByOwner[owner] =
                remaining > 0 and remaining or nil
            -- A single broken source material OR missing weld can leave
            -- a hole in a 3D skirt. Restore the ENTIRE native source
            -- silhouette only for this one physical owner immediately.
            if type(owner) == "string" then
                active[owner] = nil
            else
                verifiedSupports[owner] = nil
            end
            reconcile()
        end
        watchers[#watchers + 1] =
            meshFolder.ChildRemoved:Connect(revokeSourcePiece)
        -- DescendantRemoving fires BEFORE the original mesh's parent
        -- changes during Destroy(); revokeSourcePiece is idempotent, so
        -- ChildRemoved cannot subtract the same piece twice. A detached
        -- WeldConstraint with an otherwise surviving MeshPart must also
        -- reveal all four native WedgePart bevels without another tick.
        watchers[#watchers + 1] =
            meshFolder.DescendantRemoving:Connect(function(descendant)
                if (descendant.Name ~= "ChaosPlatformTrimWeld"
                        and descendant.Name ~= "OriginalSupportVisualWeld")
                    or (not descendant:IsA("Weld")
                        and not descendant:IsA("WeldConstraint")) then
                    return
                end
                local piece = descendant.Parent
                if piece and piece.Parent == meshFolder then
                    revokeSourcePiece(piece)
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

-- Accurate ACTUAL masked natives, not the 2,080/800/520
-- server-authored source inventory repeated across five different maps.
-- Event-driven: the existing onChange callback samples these counters
-- only on a native-mask change, not on RenderStepped or a new timer.
function Kit.breakdown()
    local result = {
        bevel = 0, underframe = 0, support = 0, other = 0,
    }
    for part in pairs(saved) do
        if part.Parent == activeDecor then
            local name = part.Name
            if name:match("^PlatformBevel%d+_%d+$") then
                result.bevel += 1
            elseif name:match("^PlatformUnderFrame%d+$") then
                result.underframe += 1
            elseif name:match("^PlatformSupport%d+_%d+$") then
                result.support += 1
            else
                result.other += 1
            end
        end
    end
    return result
end

function Kit.count()
    return count
end

return Kit
