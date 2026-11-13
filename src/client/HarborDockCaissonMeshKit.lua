-- Real seven-material creator-approved cargo caisson skins for the
-- EXISTING Harbor switchbacks and cardinal dock spurs. Only their 3D
-- sidewalls and undersides are enriched. The native platform's TOP,
-- full authoritative collision, and danger overlays are NEVER hidden.
-- Reuse scenery-lod's one existing camera/quality tick, not new polling.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local ASSET_ID = 101457508594609
local BUDGET = {
    -- One original below-deck armored caisson directly under the camera.
    -- Never add a false walkable surface or an extra collision platform.
    Low = {models = 1, distance = 108, retention = 14},
    Medium = {models = 5, distance = 150, retention = 24},
    High = {models = 12, distance = 215, retention = 34},
}
local folder = Instance.new("Folder")
folder.Name = "OriginalHarborDockCaissonsLocal"
folder:SetAttribute("CosmeticOnly", true)
folder.Parent = workspace

local activeArena = nil
local watchedBase = nil
local baseChanged = nil
local mounted = {}

local function original()
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedHarborDockCaissonTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = holder:FindFirstChild("DockCaisson")
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalHarborDockCaisson3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= ASSET_ID then
        return nil
    end
    local count = 0
    for _, item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return nil end
            count += 1
        elseif item:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, box = source:GetBoundingBox()
    if box.X < 13 or box.X > 14.4
        or box.Z < 13 or box.Z > 14.4
        or box.Y < 2.9 or box.Y > 3.55 then return nil end
    return source, count
end

local function route(deck)
    local harbor = deck:GetAttribute("HarborRoute")
    local harborStep = deck:GetAttribute("HarborStep")
    if type(harbor) == "number" and harbor >= 1 and harbor <= 4
        and harbor % 1 == 0
        and type(harborStep) == "number" and harborStep >= 1
        and harborStep <= 7 and harborStep % 1 == 0 then
        return true
    end
    local spoke = deck:GetAttribute("HarborSpokeRoute")
    local spokeStep = deck:GetAttribute("HarborSpokeStep")
    return type(spoke) == "number" and spoke >= 1 and spoke <= 4
        and spoke % 1 == 0
        and type(spokeStep) == "number" and spokeStep >= 1
        and spokeStep <= 4 and spokeStep % 1 == 0
end

-- ShrinkingArena scales and MOVES genuine Harbor RouteTier decks every
-- round tick. Require the server-authored ORIGINAL floor footprint and
-- compare deck width against the actual floor shrink fraction, instead of
-- hiding every approved caisson as soon as the playable floor contracts.
local function realFloorScale(base, arena)
    local generated = workspace:FindFirstChild("GeneratedMap")
    if not arena or not generated or arena.Parent ~= generated
        or arena.Name ~= "Arena" or arena:GetAttribute("VariantId") ~= "Harbor"
        or not base or not base:IsA("BasePart") or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide then return nil end
    local sx, sz = base:GetAttribute("OriginalSizeX"),
        base:GetAttribute("OriginalSizeZ")
    if typeof(sx) ~= "number" or typeof(sz) ~= "number"
        or sx ~= sx or sz ~= sz or sx < 318 or sz < 318
        or sx >= math.huge or sz >= math.huge then return nil end
    local scaleX, scaleZ = base.Size.X / sx, base.Size.Z / sz
    if scaleX < .445 or scaleX > 1.005 or scaleZ < .445
        or scaleZ > 1.005 or math.abs(scaleX - scaleZ) > .012 then
        return nil
    end
    return math.min(scaleX, scaleZ)
end

local function genuineLanding(deck, arena, base)
    local floorScale = realFloorScale(base, arena)
    if not floorScale or not deck or not deck:IsA("BasePart")
        or not deck.Name:match("^Platform%d+$")
        or deck.Parent ~= arena:FindFirstChild("Platforms")
        or not deck.Anchored or not deck.CanCollide
        or deck.Transparency >= .75
        or deck:GetAttribute("ChaosSkybridge") == true
        or type(deck:GetAttribute("RouteTier")) ~= "number"
        or not route(deck)
        -- The server's genuine Harbor switchback/spoke footprint starts
        -- between 9.5 and 12.2 studs and scales uniformly with the floor.
        -- An unrelated/lagging deck never qualifies as a forged landing.
        or deck.Size.X / floorScale < 9.35
        or deck.Size.X / floorScale > 12.35
        or deck.Size.Z / floorScale < 9.35
        or deck.Size.Z / floorScale > 12.35
        or math.abs(deck.Size.X - deck.Size.Z) > .18
        or math.abs(deck.Size.Y - 2) > .10 then
        return false
    end
    local collapse = deck:GetAttribute("CollapsePhase")
    if collapse ~= nil and collapse ~= "Normal" and collapse ~= "Safe" then
        return false
    end
    local shutter = deck:GetAttribute("BridgeShutterPhase")
    if shutter ~= nil and shutter ~= "Idle" then return false end
    return true
end

local function valid(entry)
    if entry.disposing or not entry.model or entry.model.Parent ~= folder
        or entry.arena ~= activeArena
        or not genuineLanding(entry.deck, entry.arena, entry.base)
        or not entry.pieces or #entry.pieces ~= entry.expected then
        return false
    end
    for _, part in ipairs(entry.pieces) do
        -- A partial imported model, lost weld or accidentally collidable
        -- cosmetic is not an authentic underdeck shell. Hide it rather
        -- than claiming that the caisson has survived the shrink event.
        if not part:IsA("MeshPart") or part.Parent ~= entry.model
            or part.Anchored or not part.Massless
            or part.CanCollide or part.CanTouch or part.CanQuery then
            return false
        end
        local weld = entry.joints[part]
        if not weld or weld.Parent ~= part
            or weld.Part0 ~= entry.deck or weld.Part1 ~= part
            or not entry.localFrames[part] or not entry.sizes[part] then
            return false
        end
    end
    return true
end

-- Refit the already-imported seven real MeshParts to the live, solid
-- server deck. Weld.C0 can be changed WITHOUT moving/resizing its anchored
-- owner. Avoid recurring Clone/Destroy and don't add a render-step loop.
-- The imported caisson always finishes .14 studs below the real deck top.
local function refit(entry)
    if not valid(entry) then return false end
    local width = math.min(entry.deck.Size.X, entry.deck.Size.Z)
    local factor = width / entry.initialWidth
    if factor < .44 or factor > 1.03 then return false end
    for _, piece in ipairs(entry.pieces) do
        local weld, frame, size =
            entry.joints[piece], entry.localFrames[piece], entry.sizes[piece]
        if not weld or weld.Parent ~= piece or weld.Part0 ~= entry.deck
            or weld.Part1 ~= piece or not frame or not size then
            return false
        end
    end
    if entry.lastWidth and math.abs(entry.lastWidth - width) < .016 then
        return true
    end
    local shift = CFrame.new(0,
        entry.deck.Size.Y * .5 - .14 - entry.boxHeight * factor * .5, 0)
    for _, piece in ipairs(entry.pieces) do
        local frame = entry.localFrames[piece]
        piece.Size = entry.sizes[piece] * factor
        entry.joints[piece].C0 = shift *
            CFrame.new(frame.Position * factor) *
            (frame - frame.Position)
    end
    entry.lastWidth = width
    return true
end

local function visibility(entry)
    local show = refit(entry)
    for _, part in ipairs(entry.pieces) do
        if part.Parent then
            part.LocalTransparencyModifier = show and 0 or 1
        end
    end
end

local function dispose(entry)
    if entry.disposing then return end
    entry.disposing = true
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    entry.model:Destroy()
end

-- No native art is hidden by this kit, but an externally removed model
-- must release its per-deck listeners immediately: do not retain ghost
-- residents or stale references until the next camera LOD sample.
folder.ChildRemoved:Connect(function(child)
    if not child:IsA("Model") then return end
    for deck, entry in pairs(mounted) do
        if not entry.disposing and entry.model == child then
            dispose(entry)
            mounted[deck] = nil
        end
    end
end)

local function clearModels()
    for deck, entry in pairs(mounted) do
        dispose(entry)
        mounted[deck] = nil
    end
end

local function clear()
    clearModels()
    if baseChanged then baseChanged:Disconnect() end
    baseChanged = nil
    watchedBase = nil
    activeArena = nil
    folder:ClearAllChildren()
end

local function mount(deck, arena, base, source, expected)
    local clone = source:Clone()
    local width = math.min(deck.Size.X, deck.Size.Z)
    -- Every approved original MODEL is a 12-stud base profile. Scale all
    -- three axes together: this preserves bevel tangents, UVs and truss
    -- proportions, while the actual walkable top remains authoritative.
    local scale = width / 12.0
    if scale < .34 or scale > 1.02 then
        clone:Destroy()
        return nil
    end
    if not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return nil
    end
    local origin, box = clone:GetBoundingBox()
    if box.X < width * 1.08 or box.Z < width * 1.08
        or box.Y < 2.2 or box.Y > 3.60 then
        clone:Destroy()
        return nil
    end
    -- Top of all caisson geometry stays 0.14 studs BELOW the
    -- native collidable top. It can NEVER advertise a false landing
    -- or block a real R15 jump, even if the Roblox importer changes pivot.
    local target = deck.CFrame * CFrame.new(
        0, deck.Size.Y * .5 - .14 - box.Y * .5, 0)
    local pieces = {}
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            part.CFrame = target * origin:ToObjectSpace(part.CFrame)
            part.Anchored = false
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part:SetAttribute("OriginalHarborDockCaisson3D", true)
            part:SetAttribute("Original3DAssetId", ASSET_ID)
            pieces[#pieces + 1] = part
        end
    end
    if #pieces ~= expected then clone:Destroy(); return nil end
    local entry = {
        model = clone, source = source, arena = arena, base = base,
        deck = deck, initialWidth = width, boxHeight = box.Y,
        pieces = pieces, expected = expected, connections = {},
        localFrames = {}, sizes = {}, joints = {}, lastWidth = nil,
        disposing = false,
    }
    clone.Name = "ApprovedOriginalHarborDockCaisson3D"
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("Original3DAssetId", ASSET_ID)
    clone.Parent = folder

    for _, piece in ipairs(pieces) do
        -- Weld with adjustable C0: the deck stays authoritative, while
        -- uniform cosmetic geometry follows the server-owned shrinking size.
        local joint = Instance.new("Weld")
        joint.Name = "HarborDockCosmeticWeld"
        joint.Part0 = deck
        joint.Part1 = piece
        joint.C0 = deck.CFrame:ToObjectSpace(piece.CFrame)
        joint.C1 = CFrame.identity
        joint.Parent = piece
        entry.joints[piece] = joint
        entry.localFrames[piece] = target:ToObjectSpace(piece.CFrame)
        entry.sizes[piece] = piece.Size
    end
    local function changed()
        -- This MUST run when Size changes even if the deck is healthy:
        -- a fully valid shrinking RouteTier needs its welded imported
        -- geometry resized, not merely checked for a hazard. Otherwise
        -- the original 12-stud shell survives until the next LOD tick.
        visibility(entry)
    end
    for _, property in ipairs({"Size", "CanCollide", "Transparency",
        "Anchored"}) do
        entry.connections[#entry.connections + 1] =
            deck:GetPropertyChangedSignal(property):Connect(changed)
    end
    for _, attr in ipairs({
        "CollapsePhase", "BridgeShutterPhase", "HarborRoute",
        "HarborStep", "HarborSpokeRoute", "HarborSpokeStep", "RouteTier",
    }) do
        entry.connections[#entry.connections + 1] =
            deck:GetAttributeChangedSignal(attr):Connect(changed)
    end
    entry.connections[#entry.connections + 1] =
        deck.AncestryChanged:Connect(changed)
    entry.connections[#entry.connections + 1] =
        clone.DescendantRemoving:Connect(function(part)
            if not entry.disposing and part:IsA("MeshPart") then
                task.defer(visibility, entry)
            end
        end)
    -- The attached deck may already have shrunk before this LOD sample.
    visibility(entry)
    return entry
end

-- Existing scenery-lod camera sampler calls this. No extra frame loop,
-- Roblox fetch on client, lighting, physics or server-side changes.
function Kit.sync(arena, cameraPoint, quality, cameraReady, cameraLook, pressure)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[quality] or BUDGET.Low
    local stress = math.clamp(math.floor(tonumber(pressure) or 0), 0, 2)
    local maximum = budget.models
    if quality == "High" then
        maximum = stress == 0 and 12 or (stress == 1 and 6 or 2)
    elseif quality == "Medium" then
        maximum = stress == 0 and 5 or (stress == 1 and 2 or 0)
    elseif quality == "Low" and stress > 0 then
        -- Restore the native physical deck as soon as GPU pressure rises.
        -- The cosmetic underside has no authority over any gameplay Part.
        maximum = 0
    end
    if not arena or not cameraReady or maximum <= 0
        or typeof(cameraPoint) ~= "Vector3"
        or tostring(arena:GetAttribute("VariantId")) ~= "Harbor" then
        clearModels()
        return
    end
    local base = arena:FindFirstChild("Base")
    local platforms = arena:FindFirstChild("Platforms")
    if not platforms or not platforms:IsA("Folder")
        or not realFloorScale(base, arena) then
        clearModels()
        return
    end
    if watchedBase ~= base then
        if baseChanged then baseChanged:Disconnect() end
        watchedBase = base
        -- A streaming mismatch, invalid provenance or floor reset must
        -- restore safe cosmetics immediately; actual RouteTier resizing
        -- is handled by each deck's existing Size event.
        baseChanged = base:GetPropertyChangedSignal("Size"):Connect(function()
            if not realFloorScale(base, arena) then
                clearModels()
            else
                -- Floor contracts before any owned RouteTier deck. A
                -- previously authentic caisson must hide if the server
                -- deck has not yet reached its corresponding new size.
                for _, entry in pairs(mounted) do visibility(entry) end
            end
        end)
    end
    local source, expected = original()
    -- The approved source has seven material families. Low only accepts
    -- exactly seven real MeshParts, never a larger importer split or
    -- a cheap generic Part pretending to be the forged sidewall.
    if not source or (quality == "Low" and expected ~= 7) then
        clearModels()
        return
    end
    local nearby = {}
    for _, deck in ipairs(platforms:GetChildren()) do
        if genuineLanding(deck, arena, base) then
            local dist = (cameraPoint - deck.Position).Magnitude
            local resident = mounted[deck] ~= nil
            if dist <= budget.distance +
                (resident and budget.retention or 0) then
                local score = dist - (resident
                    and budget.retention * .65 or 0)
                if typeof(cameraLook) == "Vector3"
                    and cameraLook.Magnitude > .5 and dist > 35 then
                    local unit = (deck.Position - cameraPoint).Unit
                    score -= math.min(33, dist * .20)
                        * unit:Dot(cameraLook.Unit)
                end
                nearby[#nearby + 1] = {deck = deck, score = score}
            end
        end
    end
    table.sort(nearby, function(a,b)
        if a.score == b.score then
            return a.deck.Name < b.deck.Name
        end
        return a.score < b.score
    end)
    local wanted = {}
    for i = 1, math.min(maximum, #nearby) do
        wanted[nearby[i].deck] = true
    end
    for deck, entry in pairs(mounted) do
        if not wanted[deck] or not valid(entry)
            or entry.source ~= source then
            dispose(entry)
            mounted[deck] = nil
        else
            visibility(entry)
        end
    end
    for deck in pairs(wanted) do
        if not mounted[deck] then
            mounted[deck] = mount(deck, arena, base, source, expected)
        end
    end
end

function Kit.count()
    local models, parts = 0, 0
    for _, entry in pairs(mounted) do
        if valid(entry) then
            models += 1
            parts += entry.expected
        end
    end
    return models, parts
end

return Kit
