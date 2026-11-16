-- Client-only visual substitution for SERVER-authored primitive trim.
-- Never remove, move, resize, recolor, or collide with gameplay Parts.
-- The live server continues owning its original fallback and hazard cues.
-- Hide native structural trim ONLY while a provenance-checked genuine
-- MeshPart carapace/girder is already in the existing platform owner.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlatformIdentityLodRules = if script and script.Parent
    and ReplicatedStorage:FindFirstChild("Shared")
    and ReplicatedStorage.Shared:FindFirstChild("PlatformIdentityLodRules")
    then require(ReplicatedStorage.Shared.PlatformIdentityLodRules)
    else require("../shared/PlatformIdentityLodRules")

local LargeStructure = if script and script.Parent
    and script.Parent:FindFirstChild("PremiumLargeStructureMeshKit")
    then require(script.Parent.PremiumLargeStructureMeshKit)
    else require("./PremiumLargeStructureMeshKit")
local Rim = if script and script.Parent and script.Parent:FindFirstChild("ApprovedPlatformRimMeshKit")
    then require(script.Parent.ApprovedPlatformRimMeshKit)
    else require("./ApprovedPlatformRimMeshKit")

local Kit = {}

local saved = {}
local routeCradles = {}
local routeRims = {}
local cradleClaims = {}
local rimClaims = {}
local harborDockClaims = {}
local nativeBaselines = {}
local crownPylons = {}
local routeUnderdecks = {}
local harborTrusses = {}
local junctionTrusses = {}
local junctionObservers = {}
local crownTrim = {}
local commandTrim = {}
local pylonPieces = {}
local bridgePieces = {}
local pylonsOutsideLod = setmetatable({}, {__mode = "k"})
local watchers = {}
local decorWatcher = nil
local decorRemovedWatcher = nil
local activeDecor = nil
local active = {}
local hiddenPlatformTrim = {}
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
local promenadePylonsByDeck = {}

function Kit.hasPrimaryJunctionTruss(part)
    return saved[part] == true or routeUnderdecks[part] == true
        or harborTrusses[part] == true or cradleClaims[part] == true
end

function Kit.observePrimaryJunctionTruss(part,callback)
    junctionObservers[part] = callback
    return function()
        if junctionObservers[part] == callback then junctionObservers[part] = nil end
    end
end

local function setNativeMask(part, claims, masked)
    local observer = claims ~= junctionTrusses and junctionObservers[part]
    local wasPrimary = observer and Kit.hasPrimaryJunctionTruss(part)
    claims[part] = masked and true or nil
    local original = nativeBaselines[part]
    if saved[part] or crownPylons[part] or routeUnderdecks[part]
        or crownTrim[part] or commandTrim[part] or cradleClaims[part]
        or harborTrusses[part] or junctionTrusses[part] or rimClaims[part]
        or harborDockClaims[part] then
        if original == nil then
            nativeBaselines[part] = part.LocalTransparencyModifier
        end
        part.LocalTransparencyModifier = 1
    elseif original ~= nil then
        part.LocalTransparencyModifier = original
        nativeBaselines[part] = nil
    end
    if observer and Kit.hasPrimaryJunctionTruss(part) ~= wasPrimary then observer() end
end

function Kit.setHarborDockMask(part, masked)
    if (harborDockClaims[part] == true) ~= masked then
        setNativeMask(part, harborDockClaims, masked)
    end
end

function Kit.setRouteUnderdeckMask(part, masked)
    if (routeUnderdecks[part] == true) == masked then return end
    setNativeMask(part, routeUnderdecks, masked)
end

function Kit.setJunctionTrussMask(part,isHarbor,masked)
    local claims = isHarbor and harborTrusses or junctionTrusses
    if (claims[part] == true) ~= masked then setNativeMask(part,claims,masked) end
end

-- The generic crown and the variant equipment can both obscure the same
-- authored roof detail. Release the original alpha only after both leave.
function Kit.setSkySpineRoofMask(part, isCommand, masked)
    local claims = isCommand and commandTrim or crownTrim
    if (claims[part] == true) == masked then return end
    setNativeMask(part, claims, masked)
end

local function refreshPylon(part)
    local pieces = pylonPieces[part]
    if not pieces then return end
    -- Never leave a welded sculpture visible when its authenticated
    -- seven-piece source, streamed native owner or active arena is gone.
    -- The original support is the safe visual fallback in every case.
    local visible = saved[part] == true
        and verifiedSupports[part] == true
        and part.Parent == activeDecor
        and not crownPylons[part]
    for piece in pairs(pieces) do
        piece.LocalTransparencyModifier = visible and 0 or 1
    end
end

function Kit.isSkySpinePylon(part)
    return part:IsA("BasePart") and part.Anchored
        and not part.CanCollide and not part.CanTouch and not part.CanQuery
        and part.Name:match("^SkySpine%d+_MonumentalPylon%-?1$") ~= nil
        and part:GetAttribute("SkySpineDecor") == true
        and part:GetAttribute("PerimeterPlatformIndex")
            == tonumber(part.Name:match("^SkySpine(%d+)_"))
end

local function report()
    if notify then notify(count) end
end

-- Both approved models claim the same native pylon. The crown has visual
-- priority; the column stays ready to take over if the crown disappears.
function Kit.setCrownPylonMask(part, masked)
    if (crownPylons[part] == true) == masked then return end
    setNativeMask(part, crownPylons, masked)
    refreshPylon(part)
    if saved[part] then
        count += masked and -1 or 1
        report()
    end
end

local function restore()
    for part in pairs(saved) do
        setNativeMask(part, saved, false)
        refreshPylon(part)
        if not crownPylons[part] then count -= 1 end
    end
    report()
end

local function refreshCradle(entry)
    if routeCradles[entry.deck] ~= entry then return end
    local deck,arena = entry.deck,entry.arena
    local natives = entry.visible and entry.sourceReady and not entry.evicted
        and arena:FindFirstChild("Decor") == entry.decor
        and #entry.pieces == 7 and LargeStructure.cradleNativeParts(entry.decor,deck)
    if natives and (deck.Size-entry.fittedSize).Magnitude > .006 then
        -- Roblox can replicate the collider and its native trim in
        -- separate batches. Resume only after the 3D footprint is fitted.
        natives = nil
    end
    if natives and #natives ~= #entry.natives then natives = nil end
    if natives then
        for i,native in ipairs(natives) do
            if native ~= entry.natives[i] then natives = nil; break end
        end
    end
    if natives then
        for _,piece in ipairs(entry.pieces) do
            local joint = entry.joints[piece]
            if piece.Parent ~= entry.folder or not joint or joint.Parent ~= piece
                or joint.Part0 ~= piece or joint.Part1 ~= deck or piece.Transparency >= 1
                or piece.Anchored or piece.CanCollide or piece.CanTouch or piece.CanQuery then
                natives = nil
                break
            end
        end
    end
    local showing = natives ~= nil and natives ~= false
    local changed = entry.showing ~= showing
    entry.showing = showing
    if not changed then return end
    -- Claim the exact native pieces before the older route chassis
    -- yields, preserving the promenade junction's takeover state.
    for _,native in ipairs(entry.natives) do
        setNativeMask(native,cradleClaims,showing)
    end
    deck:SetAttribute("LocalOriginalLongCradleMounted", showing or nil)
    for _,piece in ipairs(entry.pieces) do
        piece.LocalTransparencyModifier = showing and 0 or 1
    end
    count += showing and #entry.natives or -#entry.natives
    report()
end

function Kit.setRouteCradleLodVisible(deck,visible)
    local entry = routeCradles[deck]
    if not entry or entry.visible == visible then return end
    entry.visible = visible
    refreshCradle(entry)
end

local function bindCradle(arena,deck,folder,pieces)
    local decor = arena:FindFirstChild("Decor")
    local natives = LargeStructure.cradleNativeParts(decor,deck)
    local source = LargeStructure.cradleSource(pieces[1])
    local entry = {arena=arena,deck=deck,folder=folder,decor=decor,pieces=pieces,
        natives=natives or {},joints={},connections={},visible=true,showing=false,
        fittedSize=deck.Size,sourceReady=source ~= nil,evicted=not natives}
    routeCradles[deck] = entry
    local function refresh() refreshCradle(entry) end
    local function evict()
        entry.evicted = true
        refresh()
    end
    local function watch(signal,callback)
        table.insert(entry.connections,signal:Connect(callback or refresh))
    end
    local function properties(object,names)
        for _,name in ipairs(names) do watch(object:GetPropertyChangedSignal(name)) end
    end
    local function attributes(object,names)
        for _,name in ipairs(names) do watch(object:GetAttributeChangedSignal(name)) end
    end
    for _,piece in ipairs(pieces) do
        piece.LocalTransparencyModifier = 1
        local joint = piece:FindFirstChild("ChaosPlatformTrimWeld")
        if not joint or not joint:IsA("Weld") or piece:GetAttribute("Original3DAssetId")
            ~= pieces[1]:GetAttribute("Original3DAssetId") then
            entry.evicted = true
        else
            entry.joints[piece] = joint
            watch(joint.AncestryChanged,evict)
            properties(joint,{"Part0","Part1"})
        end
        watch(piece.AncestryChanged,evict)
        properties(piece,{"Transparency","Anchored","CanCollide","CanQuery","CanTouch"})
    end
    watch(deck.AncestryChanged,evict)
    properties(deck,{"Size","CFrame","Name","CanCollide","Transparency","Anchored"})
    attributes(deck,{"SkySpineStep","SkySpineInterchange","PromenadeStep","PromenadeLane",
        "ChaosPermanentRoute","RouteTier","CollapsePhase","BridgeShutterPhase"})
    local base = arena:FindFirstChild("Base")
    if base and base:IsA("BasePart") then
        watch(base.AncestryChanged,evict)
        properties(base,{"Size","Anchored","CanCollide"})
        attributes(base,{"OriginalSizeX","OriginalSizeZ"})
    end
    if decor then watch(decor.AncestryChanged,evict) end
    for _,native in ipairs(natives or {}) do
        watch(native.AncestryChanged,evict)
        properties(native,{"CFrame","Size","Anchored","CanCollide","CanTouch","CanQuery",
            "Shape","Name","Transparency"})
        attributes(native,{"SkySpineDecor","PromenadeVisualOnly","PerimeterPlatformIndex","PremiumArchitecturalSurface"})
    end
    if source then
        watch(source.AncestryChanged,evict)
        watch(source.ChildRemoved,evict)
        watch(source.ChildAdded,evict)
        watch(source:GetPropertyChangedSignal("Name"),evict)
        for _,tag in ipairs({"OwnerVerified","OriginalLargeStructure3D","CosmeticOnly","Original3DAssetId"}) do
            watch(source:GetAttributeChangedSignal(tag),evict)
        end
        watch(source.Parent:GetAttributeChangedSignal("OwnerVerified"),evict)
        for _,part in ipairs(source:GetChildren()) do
            if part:IsA("MeshPart") then
                for _,prop in ipairs({"CanCollide","CanTouch","CanQuery","Transparency","MeshId","Size","CFrame"}) do
                    watch(part:GetPropertyChangedSignal(prop),evict)
                end
            end
        end
    end
    refresh()
end

local function refreshRim(entry)
    local deck = entry.deck
    local edges,frame
    if entry.visible and not entry.evicted and entry.decor
        and entry.decor.Parent == entry.arena
        and deck.Parent == entry.arena:FindFirstChild("Platforms")
        and deck.Anchored and deck.CanCollide and deck.Transparency < .75
        and (deck.Size-entry.fittedSize).Magnitude < .006 then
        local phase = deck:GetAttribute("CollapsePhase")
        local shutter = deck:GetAttribute("BridgeShutterPhase")
        if (phase == nil or phase == "Normal" or phase == "Safe")
            and (shutter == nil or shutter == "Idle") then
            edges,frame = Rim.routeNatives(entry.decor,deck)
        end
    end
    local showing = edges ~= nil and frame == entry.frame
    if showing then
        for i,edge in ipairs(edges) do
            if edge ~= entry.edges[i] then showing = false; break end
        end
    end
    if showing then
        for _,piece in ipairs(entry.pieces) do
            local joint = entry.joints[piece]
            if not joint or joint.Parent ~= piece or joint.Part0 ~= piece or joint.Part1 ~= deck
                or piece.Parent ~= entry.folder or piece.Transparency >= 1 or piece.Anchored
                or piece.CanCollide or piece.CanTouch or piece.CanQuery then
                showing = false; break
            end
        end
    end
    if showing == entry.showing then return end
    entry.showing = showing
    for _,edge in ipairs(entry.edges) do setNativeMask(edge,rimClaims,showing) end
    for _,piece in ipairs(entry.pieces) do piece.LocalTransparencyModifier = showing and 0 or 1 end
    count += showing and #entry.edges or -#entry.edges
    report()
end

local function bindRouteRim(arena,deck,folder,pieces)
    local decor = arena:FindFirstChild("Decor")
    local edges,frame = Rim.routeNatives(decor,deck)
    local source = Rim.sourceOf(pieces[1])
    local entry = {arena=arena,deck=deck,folder=folder,decor=decor,
        pieces=pieces,edges=edges or {},frame=frame,joints={},connections={},
        visible=true,showing=false,fittedSize=deck.Size,
        evicted=not edges or not source or #pieces ~= 7}
    routeRims[deck] = entry
    local function refresh() refreshRim(entry) end
    local function evict()
        entry.evicted = true
        refresh()
    end
    local function watch(signal,handler)
        table.insert(entry.connections,signal:Connect(handler or refresh))
    end
    local function properties(object,names,handler)
        for _,name in ipairs(names) do watch(object:GetPropertyChangedSignal(name),handler) end
    end
    for _,piece in ipairs(pieces) do
        piece.LocalTransparencyModifier = 1
        local joint = piece:FindFirstChild("ChaosPlatformTrimWeld")
        if joint and joint:IsA("Weld") and piece:GetAttribute("Original3DAssetId")
            == pieces[1]:GetAttribute("Original3DAssetId") then
            entry.joints[piece] = joint
            watch(joint.AncestryChanged,evict)
            properties(joint,{"Part0","Part1"})
        else
            entry.evicted = true
        end
        watch(piece.AncestryChanged,evict)
        properties(piece,{"Anchored","CanCollide","CanTouch","CanQuery","Transparency"})
    end
    watch(deck.AncestryChanged,evict)
    properties(deck,{"CFrame","Size","Anchored","CanCollide","Transparency","Name"})
    for _,attribute in ipairs({"RouteTier","ChaosPermanentRoute","SkySpineStep",
        "SkySpineInterchange","PromenadeStep","PromenadeLane","CollapsePhase","BridgeShutterPhase",
        "PerimeterRoute","PerimeterStep","BranchRoute","BranchStep","BranchParentStep",
        "CrosslinkRoute","CrosslinkFromPerimeterStep","CrosslinkToBranchStep"}) do
        watch(deck:GetAttributeChangedSignal(attribute))
    end
    if edges then
        local natives = table.clone(edges)
        table.insert(natives,frame)
        for _,native in ipairs(natives) do
            watch(native.AncestryChanged,evict)
            properties(native,{"CFrame","Size","Anchored","CanCollide","CanTouch","CanQuery","Name"})
            watch(native:GetAttributeChangedSignal("OriginalStructuralBevel"))
            watch(native:GetAttributeChangedSignal("PremiumArchitecturalSurface"))
        end
    end
    local base = arena:FindFirstChild("Base")
    if base and base:IsA("BasePart") then
        properties(base,{"Size","Anchored","CanCollide"})
        watch(base.AncestryChanged,evict)
        watch(base:GetAttributeChangedSignal("OriginalSizeX"))
        watch(base:GetAttributeChangedSignal("OriginalSizeZ"))
    end
    if decor then watch(decor.AncestryChanged,evict) end
    if source then
        watch(source.AncestryChanged,evict)
        watch(source.DescendantRemoving,evict)
        watch(source.DescendantAdded,evict)
        properties(source,{"Name"},evict)
        properties(source.Parent,{"Name"},evict)
        watch(source.Parent:GetAttributeChangedSignal("OwnerVerified"),evict)
        for _,attribute in ipairs({"OwnerVerified","CosmeticOnly","OriginalPlatformRim3D","Original3DAssetId"}) do
            watch(source:GetAttributeChangedSignal(attribute),evict)
        end
        for _,piece in ipairs(source:GetChildren()) do
            if piece:IsA("MeshPart") then
                properties(piece,{"MeshId","Size","CFrame","CanCollide","CanTouch","CanQuery","Transparency"},evict)
            end
        end
    end
    refresh()
end

function Kit.setRouteRimLodVisible(deck,visible)
    local entry = routeRims[deck]
    if not entry or entry.visible == visible then return end
    entry.visible = visible
    refreshRim(entry)
end

function Kit.routeCradleRefitted(deck)
    local cradle = routeCradles[deck]
    if cradle then
        cradle.fittedSize = deck.Size
        refreshCradle(cradle)
    end
    local rim = routeRims[deck]
    if rim then
        rim.fittedSize = deck.Size
        refreshRim(rim)
    end
end

function Kit.reset()
    for deck,entry in pairs(routeRims) do
        for _,connection in ipairs(entry.connections) do connection:Disconnect() end
        entry.visible = false
        refreshRim(entry)
        routeRims[deck] = nil
    end
    for deck,entry in pairs(routeCradles) do
        for _,connection in ipairs(entry.connections) do connection:Disconnect() end
        entry.visible = false
        refreshCradle(entry)
        routeCradles[deck] = nil
    end
    for _, connection in ipairs(watchers) do
        connection:Disconnect()
    end
    table.clear(watchers)
    decorWatcher = nil
    decorRemovedWatcher = nil
    activeDecor = nil
    restore()
    for _, entry in pairs(bridgePieces) do
        for piece in pairs(entry.pieces) do
            piece.LocalTransparencyModifier = 1
        end
    end
    table.clear(bridgePieces)
    table.clear(pylonPieces)
    table.clear(active)
    table.clear(hiddenPlatformTrim)
    table.clear(verifiedSupports)
    table.clear(verifiedSupportIndices)
    table.clear(promenadePylonsByDeck)
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
            or Kit.isSkySpinePylon(part)
            or PlatformIdentityLodRules.promenadePylonIndex(part) ~= nil
    end
    local id = name:match("^PlatformBevel(%d+)_[1-4]$")
    if id and (active[id] == "carapace" or active[id] == "rim") then
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
        return part.Name:match("^SkybridgeRib%d+_[01]$") ~= nil
            or part.Name:match("^SkybridgeRib%d+_%-1$") ~= nil
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
    local deck = activePlatforms:FindFirstChild("Platform"..id)
    if not deck and name:match("^PlatformSupport%d+_") then
        return activePlatforms:FindFirstChild("Skybridge"..id)
    end
    return deck
end

-- A pure condition on REAL Roblox Parts, also checked in the
-- important engine milestone. This does not alter collision itself.
local function ownerSafe(owner, platforms)
    if not platforms or not platforms:IsA("Folder")
        or not owner or not owner:IsA("BasePart")
        or owner.Parent ~= platforms
        or not owner.Anchored or not owner.CanCollide
        or owner.Transparency >= 0.75 then
        return false
    end
    local phase = owner:GetAttribute("CollapsePhase")
    if phase ~= nil and phase ~= "Normal" and phase ~= "Safe" then
        return false
    end
    local shutter = owner:GetAttribute("BridgeShutterPhase")
    return shutter == nil or shutter == "Idle"
end

local function bridgeSafe(owner)
    local original = ownerBaselines[owner]
    if not original or not ownerSafe(owner, activePlatforms)
        or owner:GetAttribute("ChaosSkybridge") ~= true then return false end
    local size = owner.Size
    -- ShrinkingArena changes only the longitudinal axis. The existing
    -- welded follower refits the approved side trusses to that span.
    -- Other size changes invalidate the edge clearance of the mount.
    local alongX = original.X >= original.Z
    local width = alongX and size.Z or size.X
    local originalWidth = alongX and original.Z or original.X
    local span = alongX and size.X or size.Z
    return span >= width and math.abs(width - originalWidth) < .09
        and math.abs(size.Y - original.Y) < .09
end

function Kit.authorizesMask(owner, original, platforms)
    -- Most imports require their original footprint. Promenade pylons
    -- are refitted to the actual resized native part as a separate case.
    return ownerSafe(owner, platforms) and typeof(original) == "Vector3"
        and math.abs(owner.Size.X-original.X) < 0.09
        and math.abs(owner.Size.Z-original.Z) < 0.09
end

local function physicalSafe(native)
    local owner = physicalOwner(native)
    if hiddenPlatformTrim[owner]
        and (native.Name:match("^PlatformBevel%d+_[1-4]$")
            or native.Name:match("^PlatformUnderFrame%d+$")) then return false end
    if native.Name:match("^SkybridgeRib%d+_") then
        return bridgePieces[owner] ~= nil and bridgeSafe(owner)
    end
    if owner and owner.Name:match("^Skybridge%d+$") then
        return ownerSafe(owner, activePlatforms)
            and LargeStructure.matchesSkybridgeSupport(native,owner)
    end
    if PlatformIdentityLodRules.promenadePylonIndex(native) then
        return ownerSafe(owner, activePlatforms)
            and PlatformIdentityLodRules.matchesPromenadePylon(native, owner)
    end
    if owner and native.Name:match("^PlatformSupport%d+_%d+$")
        and (owner:GetAttribute("PromenadeStep") ~= nil
            or owner:GetAttribute("SkySpineInterchange") == true
            or PlatformIdentityLodRules.isHarborLanding(owner)) then
        return ownerSafe(owner, activePlatforms)
            and LargeStructure.routeSupportScale(native,owner) ~= nil
    end
    return Kit.authorizesMask(owner, owner and ownerBaselines[owner],
        activePlatforms)
end

local function tryMask(part)
    if pylonsOutsideLod[part] or not eligible(part)
        or saved[part] ~= nil or not physicalSafe(part) then return end
    setNativeMask(part, saved, true)
    refreshPylon(part)
    if not crownPylons[part] then count += 1 end
    return true
end

local function unmask(part)
    setNativeMask(part, saved, false)
    refreshPylon(part)
    if not crownPylons[part] then count -= 1 end
end

local function reconcilePylon(part)
    if saved[part] then
        if not eligible(part) or not physicalSafe(part) then
            unmask(part)
            report()
        end
    elseif tryMask(part) then
        report()
    end
end

-- The existing scenery pass reports one distance decision per real pylon.
-- Apply it to the complete bundle and its native fallback together.
function Kit.setPylonLodVisible(part, visible)
    if (pylonsOutsideLod[part] ~= true) == visible then return end
    pylonsOutsideLod[part] = not visible or nil
    if not visible and saved[part] then
        unmask(part)
        report()
    elseif visible then
        reconcilePylon(part)
    end
end

-- Event-based reconciliation; does not poll a frame or create Parts.
-- A server collapse warning or shutter must restore the native fallback
-- even if the approved 3D clone itself is merely faded, not destroyed.
local function reconcile()
    for deck, entry in pairs(bridgePieces) do
        local visible = activeDecor ~= nil
            and active[entry.id] == "bridge" and bridgeSafe(deck)
        local alpha = visible and 0 or 1
        if entry.alpha ~= alpha then
            entry.alpha = alpha
            for piece in pairs(entry.pieces) do
                piece.LocalTransparencyModifier = alpha
            end
        end
    end
    local changed = false
    for part in pairs(saved) do
        if part.Parent ~= activeDecor or not eligible(part)
            or not physicalSafe(part) then
            unmask(part)
            changed = true
        end
    end
    if activeDecor then
        for _, part in ipairs(activeDecor:GetChildren()) do
            if tryMask(part) then changed = true end
        end
    end
    if changed then report() end
end

-- Scenery LOD can hide a whole platform shell between rebuilds.
-- Reconcile only that deck's four bevels and underframe, using the
-- same source and physical owner checks as the existing mask binder.
function Kit.setPlatformTrimLodVisible(deck, visible)
    if not activePlatforms or deck.Parent ~= activePlatforms then return end
    local id = deck.Name:match("^Platform(%d+)$")
    if not id or (active[id] ~= "carapace" and active[id] ~= "rim") then return end
    local hidden = not visible or nil
    if hiddenPlatformTrim[deck] == hidden then return end
    hiddenPlatformTrim[deck] = hidden
    if not activeDecor then return end
    local changed = false
    local function refresh(name)
        local part = activeDecor:FindFirstChild(name)
        if not part then return end
        if hidden and saved[part] then
            unmask(part)
            changed = true
        elseif not hidden and tryMask(part) then
            changed = true
        end
    end
    for edge = 1, 4 do
        refresh("PlatformBevel" .. id .. "_" .. edge)
    end
    if active[id] == "carapace" then refresh("PlatformUnderFrame" .. id) end
    if changed then report() end
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
        or kind == "rim"
        or verifiedSupportIndices[id] == true) then return end
    if bridgeId and kind ~= "bridge" and verifiedSupportIndices[id] ~= true then return end
    watchedOwners[part] = true
    ownerBaselines[part] = part.Size
    local pylons = promenadePylonsByDeck[id]
    local function refreshPylons()
        for _, pylon in ipairs(pylons) do reconcilePylon(pylon) end
    end
    local function refresh()
        if pylons and active[id] == nil then
            refreshPylons()
        else
            reconcile()
        end
    end
    for _, property in ipairs({"CanCollide","Transparency","Size","Anchored"}) do
        watchers[#watchers+1] =
            part:GetPropertyChangedSignal(property):Connect(refresh)
    end
    for _, attribute in ipairs({"CollapsePhase","BridgeShutterPhase"}) do
        watchers[#watchers+1] =
            part:GetAttributeChangedSignal(attribute):Connect(refresh)
    end
    if bridgeId then
        watchers[#watchers+1] =
            part:GetAttributeChangedSignal("ChaosSkybridge"):Connect(refresh)
    end
    if pylons then
        watchers[#watchers+1] =
            part:GetPropertyChangedSignal("CFrame"):Connect(refreshPylons)
        for _, attribute in ipairs({"PromenadeLane","PromenadeStep",
            "SkySpineInterchange","SkySpineStep","ChaosPermanentRoute","RouteTier",
            "HarborRoute","HarborStep","HarborSpokeRoute","HarborSpokeStep",
            "HarborSkywayLane","HarborSkywayStep"}) do
            watchers[#watchers+1] =
                part:GetAttributeChangedSignal(attribute):Connect(refreshPylons)
        end
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
    watchers[#watchers+1] = folder.ChildRemoved:Connect(function(part)
        hiddenPlatformTrim[part] = nil
        reconcile()
    end)
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
    if folder and folder:IsA("Folder") then activeDecor = folder end
    reconcile()
    report()
    if not activeDecor then return end
    decorWatcher = folder.ChildAdded:Connect(function(part)
        if tryMask(part) then report() end
    end)
    watchers[#watchers + 1] = decorWatcher
    -- Streaming can remove an already-masked native part without changing
    -- the Platforms or Decor FOLDER. Drop that exact stale baseline/count
    -- immediately; never retain a phantom replacement in diagnostics.
    decorRemovedWatcher = folder.ChildRemoved:Connect(function(part)
        if not saved[part] then return end
        unmask(part)
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
                or kind == "cradle" or kind == "rim") then
            active[id] = kind
        end
    end
    if type(supports) == "table" then
        local platforms = arena:FindFirstChild("Platforms")
        local decor = arena:FindFirstChild("Decor")
        for _, part in ipairs(supports) do
            local pylonIndex = PlatformIdentityLodRules.promenadePylonIndex(part)
            local isPromenadePylon = pylonIndex and platforms
                and PlatformIdentityLodRules.matchesPromenadePylon(part,
                    platforms:FindFirstChild("Platform"..pylonIndex))
            if part and part:IsA("BasePart")
                and part.Parent == decor
                and part.Anchored and not part.CanCollide
                and not part.CanTouch and not part.CanQuery
                and (part.Name:match("^PlatformSupport%d+_%d+$")
                    or Kit.isSkySpinePylon(part)
                    or isPromenadePylon)
                then
                verifiedSupports[part] = true
                local id = part.Name:match("^PlatformSupport(%d+)_")
                    or part.Name:match("^SkySpine(%d+)_")
                    or part.Name:match("^Promenade(%d+)_")
                if id then verifiedSupportIndices[id] = true end
                local deck = id and platforms and platforms:FindFirstChild("Platform"..id)
                local bridge = id and platforms and not deck
                    and platforms:FindFirstChild("Skybridge"..id)
                local routeSupport = deck and part.Name:match("^PlatformSupport%d+_%d+$")
                    and (deck:GetAttribute("PromenadeStep") ~= nil
                        or deck:GetAttribute("SkySpineInterchange") == true
                        or PlatformIdentityLodRules.isHarborLanding(deck))
                if isPromenadePylon or routeSupport
                    or (bridge and LargeStructure.matchesSkybridgeSupport(part,bridge)) then
                    local pylons = promenadePylonsByDeck[id] or {}
                    promenadePylonsByDeck[id] = pylons
                    pylons[#pylons + 1] = part
                    local function changed() reconcilePylon(part) end
                    for _, property in ipairs({"Size","CFrame","Anchored",
                        "CanCollide","CanTouch","CanQuery","Shape","Name","Transparency"}) do
                        watchers[#watchers + 1] =
                            part:GetPropertyChangedSignal(property):Connect(changed)
                    end
                    for _, attribute in ipairs({"PromenadeVisualOnly","PerimeterPlatformIndex"}) do
                        watchers[#watchers + 1] =
                            part:GetAttributeChangedSignal(attribute):Connect(changed)
                    end
                end
            end
        end
    end
    -- In production, masks require a COMPLETE, owner-verified source,
    -- not a boolean replacement tag or one surviving MeshPart. Start with
    -- ZERO authorized masks until the actual mounted source is counted.
    -- Caller-supplied source-less engine fixtures retain their old API.
    local approvedKinds = nil
    local approvedSupports = nil
    local cradlePieces = {}
    local routeRimPieces = {}
    if meshFolder and meshFolder:IsA("Folder") then
        approvedKinds = table.clone(active)
        approvedSupports = table.clone(verifiedSupports)
        table.clear(active)
        table.clear(verifiedSupports)
    end
    if approvedKinds then
        local platforms = arena:FindFirstChild("Platforms")
        if platforms then
            for _,piece in ipairs(meshFolder:GetChildren()) do
                if piece:IsA("MeshPart") and Rim.isRouteRim(piece) then
                    local joint = piece:FindFirstChild("ChaosPlatformTrimWeld")
                    local deck = joint and joint:IsA("Weld") and joint.Part0 == piece and joint.Part1
                    local id = deck and deck.Name:match("^Platform(%d+)$")
                    if id and deck.Parent == platforms
                        and (approvedKinds[id] == "rim" or approvedKinds[id] == "cradle") then
                        routeRimPieces[deck] = routeRimPieces[deck] or {}
                        table.insert(routeRimPieces[deck],piece)
                    end
                    piece.LocalTransparencyModifier = 1
                end
                if piece:IsA("MeshPart") and piece:GetAttribute("OriginalLongCradle3D") == true then
                    local joint = piece:FindFirstChild("ChaosPlatformTrimWeld")
                    local deck = joint and joint:IsA("Weld") and joint.Part0 == piece and joint.Part1
                    local id = deck and deck.Name:match("^Platform(%d+)$")
                    if id and approvedKinds[id] == "cradle" and deck.Parent == platforms then
                        local group = cradlePieces[deck] or {}
                        table.insert(group,piece)
                        cradlePieces[deck] = group
                    end
                end
            end
            for id,kind in pairs(approvedKinds) do
                if kind == "cradle" then approvedKinds[id] = nil end
            end
            for deck,pieces in pairs(routeRimPieces) do
                approvedKinds[deck.Name:match("^Platform(%d+)$")] = nil
                bindRouteRim(arena,deck,meshFolder,pieces)
            end
        end
    end
    -- Watch the REAL physical PlatformN/SkybridgeN owners before masking
    -- their native cosmetic underframes. Streaming in late also reconciles.
    attachPlatforms(arena:FindFirstChild("Platforms"))
    attachDecor(arena:FindFirstChild("Decor"))
    for deck,pieces in pairs(cradlePieces) do
        bindCradle(arena,deck,meshFolder,pieces)
    end
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
            if not piece:IsA("MeshPart") or Rim.isRouteRim(piece)
                or not (piece:GetAttribute("Original3DStructuralSide") == true
                    or piece:GetAttribute("OriginalLargeStructure3D") == true
                    or piece:GetAttribute("OriginalLargeDeckHull") == true)
                or piece.Parent ~= meshFolder then return nil end
            local joint = piece:FindFirstChild("ChaosPlatformTrimWeld")
                or piece:FindFirstChild("OriginalSupportVisualWeld")
            if not joint or (not joint:IsA("Weld")
                and not joint:IsA("WeldConstraint")) or joint.Part0 ~= piece then
                return nil
            end
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
                        or approvedKinds[id] == "cradle"
                        or approvedKinds[id] == "rim"))
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
                and (approvedKinds[key] ~= "bridge" or required == 14 or required == 28)
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
        local bridgeOwnerByPiece = {}
        local function registerSourcePiece(piece)
            if sourceOwnerByPiece[piece] ~= nil then return end
            local key, owner = sourceOwner(piece)
            if not key then return end
            sourceOwnerByPiece[piece] = key
            if approvedKinds[key] == "bridge" then
                local entry = bridgePieces[owner]
                if not entry then
                    entry = {id = key, pieces = {}}
                    bridgePieces[owner] = entry
                end
                bridgeOwnerByPiece[piece] = owner
                entry.pieces[piece] = true
                piece.LocalTransparencyModifier = entry.alpha or 1
            end
            local skyPylon = piece:GetAttribute("OriginalSkySpinePylon3D") == true
                and Kit.isSkySpinePylon(owner)
            local promenadePylon = piece:GetAttribute("OriginalPromenadePylon3D") == true
                and PlatformIdentityLodRules.promenadePylonIndex(owner) ~= nil
            if approvedSupports[owner] == true and (skyPylon or promenadePylon
                or piece:GetAttribute("OriginalSupportColumn3D") == true) then
                local pieces = pylonPieces[owner] or {}
                pylonPieces[owner] = pieces
                pieces[piece] = true
                piece.LocalTransparencyModifier = 1
            end
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
            local bridge = bridgeOwnerByPiece[piece]
            if bridge then
                local entry = bridgePieces[bridge]
                entry.pieces[piece] = nil
                bridgeOwnerByPiece[piece] = nil
                piece.LocalTransparencyModifier = 1
                if next(entry.pieces) == nil then bridgePieces[bridge] = nil end
            end
            local pieces = pylonPieces[owner]
            if pieces and pieces[piece] then
                piece.LocalTransparencyModifier = 1
                pieces[piece] = nil
            end
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
        -- changes during teardown; revokeSourcePiece is idempotent, so
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
        bevel = 0, elevatedRim = 0, ascensionRim = 0, underframe = 0, support = 0, pylon = 0,
        promenadePylon = 0, other = 0, spineUnderdeck = 0, promenadeUnderdeck = 0,
        harborPile = 0,
    }
    for edge in pairs(rimClaims) do
        if edge.Parent == activeDecor then
            result.bevel += 1
            local deck = physicalOwner(edge)
            local entry = deck and routeRims[deck]
            if entry and entry.pieces[1]:GetAttribute("OriginalAscensionPlatformRim") == true then
                result.ascensionRim += 1
            else
                result.elevatedRim += 1
            end
        end
    end
    for part in pairs(cradleClaims) do
        local deck = physicalOwner(part)
        local family = deck and deck:GetAttribute("SkySpineInterchange") == true
            and "spineUnderdeck" or "promenadeUnderdeck"
        result[family] += 1
        if part.Name:match("^PlatformUnderFrame%d+$") then
            result.underframe += 1
        else
            result.other += 1
        end
    end
    for part in pairs(saved) do
        if part.Parent == activeDecor then
            local name = part.Name
            if name:match("^PlatformBevel%d+_%d+$") then
                result.bevel += 1
            elseif name:match("^PlatformUnderFrame%d+$") then
                result.underframe += 1
            elseif name:match("^PlatformSupport%d+_%d+$") then
                result.support += 1
                local owner = physicalOwner(part)
                if owner and PlatformIdentityLodRules.isHarborLanding(owner) then
                    result.harborPile += 1
                end
            elseif name:match("^SkySpine%d+_MonumentalPylon%-?1$") then
                if not crownPylons[part] then result.pylon += 1 end
            elseif name:match("^Promenade%d+_LoadPylon%-?1$") then
                result.promenadePylon += 1
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
