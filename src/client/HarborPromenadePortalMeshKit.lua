-- Six real, UV/tangent creator-approved industrial cargo gantries on
-- Storm Harbor's existing physical sky promenades. No extra player route:
-- preserve all server collision, warning state, bots, jumps and shrink.
-- Uses scenery-lod's existing low-frequency camera/quality tick.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PremiumRoutePbrKit = if script and script.Parent
    and script.Parent:FindFirstChild("PremiumRoutePbrKit")
    then require(script.Parent.PremiumRoutePbrKit)
    else require("./PremiumRoutePbrKit")

local Kit = {}
local ID = 134157110756659
local BUDGET = {
    -- One seven-MeshPart original replaces NINE server-authored block
    -- ornaments at the nearest actual cargo arch, only at pressure 0.
    Low = {count = 1, distance = 118, retention = 14},
    Medium = {count = 2, distance = 205, retention = 25},
    High = {count = 6, distance = 280, retention = 34},
}
-- Exactly nine NONPHYSICAL server-authored Parts are replaced. Their
-- matching real dock/cargo/suspension geometry exists inside the Model.
local NATIVE = {
    ["LoadPylon-1"] = true, LoadPylon1 = true,
    ["DiagonalStay-1"] = true, DiagonalStay1 = true,
    MonumentalCrosshead = true, UnderdeckTruss = true,
    FreightHoistArm = true, SuspendedCrate = true, CargoChain = true,
}

local folder = Instance.new("Folder")
folder.Name = "OriginalHarborPromenadePortalsLocal"
folder:SetAttribute("CosmeticOnly", true)
folder.Parent = workspace

local activeArena = nil
local watchedBase = nil
local baseConnection = nil
local entries = {}
local suppressOwnRemoval = false

local function modelSource()
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedHarborPromenadePortalTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild("CargoGantry")
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalHarborPromenadePortal3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= ID then return nil end
    local n = 0
    for _, piece in ipairs(source:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then return nil end
            n += 1
        elseif piece:IsA("LuaSourceContainer") then return nil end
    end
    if n < 1 or n > 12 then return nil end
    local _, b = source:GetBoundingBox()
    if math.min(b.X,b.Z) < 10.8 or math.min(b.X,b.Z) > 15.5
        or math.max(b.X,b.Z) < 18.2 or math.max(b.X,b.Z) > 21.6
        or b.Y < 18.4 or b.Y > 21.8 then return nil end
    return source,n
end

-- The server contracts real Harbor RouteTier decks horizontally;
-- their original industrial arches remain decorative and cannot collide.
-- Authenticate the signed original floor and the ACTUAL scaled deck, not
-- the ephemeral live 320-stud floor size.
local function realFloorScale(base, arena)
    local map = workspace:FindFirstChild("GeneratedMap")
    if not base or not base:IsA("BasePart") or base.Parent ~= arena
        or not arena or arena.Name ~= "Arena"
        or arena:GetAttribute("VariantId") ~= "Harbor"
        or not map or arena.Parent ~= map
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

local function authentic(deck, arena, base)
    local scale = realFloorScale(base, arena)
    if not scale or not deck or not deck:IsA("BasePart")
        or deck.Parent ~= arena:FindFirstChild("Platforms")
        or not deck.Name:match("^Platform%d+$")
        or deck:GetAttribute("ChaosPermanentRoute") ~= true
        or type(deck:GetAttribute("RouteTier")) ~= "number"
        or not deck.Anchored or not deck.CanCollide
        or deck.Transparency >= .75
        or deck.Size.X / scale < 17.8 or deck.Size.X / scale > 32.2
        or math.abs(deck.Size.Y - 2) > .12
        or math.abs(deck.Size.Z / scale - 12) > .22 then
        return false
    end
    local lane = deck:GetAttribute("PromenadeLane")
    local step = deck:GetAttribute("PromenadeStep")
    if (lane ~= 1 and lane ~= 2)
        or (step ~= 2 and step ~= 4 and step ~= 7) then
        return false
    end
    local collapse = deck:GetAttribute("CollapsePhase")
    if collapse and collapse ~= "Normal" and collapse ~= "Safe" then
        return false
    end
    return true
end

local function isNative(part, deck, decor)
    if not part or not part:IsA("BasePart") or part.Parent ~= decor
        or not part.Anchored or part.CanCollide or part.CanTouch
        or part.CanQuery or part:GetAttribute("PromenadeVisualOnly") ~= true
        then return false end
    local index = deck.Name:match("^Platform(%d+)$")
    if not index or part:GetAttribute("PerimeterPlatformIndex")
        ~= tonumber(index) then return false end
    local suffix = part.Name:match("^Promenade"..index.."_(.+)$")
    return suffix ~= nil and NATIVE[suffix] == true
end

local function isAlive(entry)
    -- The same complete-source test owns masking, PBR residency, late
    -- StreamingEnabled native pieces and the camera sampler. A surviving
    -- imported MeshPart with a missing weld cannot replace the nine native
    -- cargo gantry structures: reveal the server-authored original instead.
    if entry.disposing or not entry.model or entry.model.Parent ~= folder
        or entry.arena ~= activeArena
        or not authentic(entry.deck,entry.arena,entry.base)
        or not entry.pieces or #entry.pieces ~= entry.expected then
        return false
    end
    for _, part in ipairs(entry.pieces) do
        if not part:IsA("MeshPart") or part.Parent ~= entry.model
            or part.Anchored or not part.Massless
            or part.CanCollide or part.CanTouch or part.CanQuery then
            return false
        end
        local joint=entry.joints[part]
        if not joint or joint.Parent ~= part
            or joint.Part0 ~= entry.deck or joint.Part1 ~= part
            or not entry.frames[part] or not entry.sizes[part] then
            return false
        end
    end
    return true
end

-- Resize only the imported ornament, never the real collidable
-- deck. Server-authored native trims contract in horizontal X/Z but retain
-- their elevation; do the same here by updating cosmetic Weld.C0/Size.
-- Existing Size events drive this, without a Heartbeat/render poll.
local function refit(entry)
    if not isAlive(entry) then return false end
    local scale = realFloorScale(entry.base, entry.arena)
    if not scale then return false end
    for _, piece in ipairs(entry.pieces) do
        local joint = entry.joints[piece]
        if not joint or joint.Parent ~= piece or joint.Part0 ~= entry.deck
            or joint.Part1 ~= piece or not entry.frames[piece]
            or not entry.sizes[piece] then return false end
    end
    if entry.lastScale and math.abs(entry.lastScale - scale) < .008 then
        return true
    end
    for _, piece in ipairs(entry.pieces) do
        local frame = entry.frames[piece]
        local original = entry.sizes[piece]
        piece.Size = Vector3.new(original.X * scale,
            original.Y, original.Z * scale)
        entry.joints[piece].C0 = CFrame.new(
            frame.Position.X * scale, frame.Position.Y,
            frame.Position.Z * scale) * (frame - frame.Position)
    end
    entry.lastScale = scale
    return true
end

local function refresh(entry)
    local visible = refit(entry)
    -- Server hazard/shrink priority: restore original UV and safety cues
    -- during the same physical attribute event, not the next LOD pass.
    if not visible then PremiumRoutePbrKit.detach(entry) end
    for _, part in ipairs(entry.pieces) do
        if part.Parent then
            part.LocalTransparencyModifier = visible and 0 or 1
        end
    end
    for _, native in ipairs(entry.native) do
        if native.part.Parent then
            native.part.LocalTransparencyModifier =
                visible and 1 or native.original
        end
    end
end

local function dismantle(entry)
    if entry.disposing then return end
    entry.disposing = true
    PremiumRoutePbrKit.detach(entry)
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    for _, saved in ipairs(entry.native) do
        if saved.part.Parent then
            saved.part.LocalTransparencyModifier = saved.original
        end
    end
    suppressOwnRemoval = true
    entry.model:Destroy()
    suppressOwnRemoval = false
end

-- A missing authentic imported gantry must reveal the exact nine server
-- native structures immediately. Voluntary teardown is non-reentrant.
folder.ChildRemoved:Connect(function(child)
    if suppressOwnRemoval or not child:IsA("Model") then return end
    for deck, entry in pairs(entries) do
        if not entry.disposing and entry.model == child then
            dismantle(entry)
            entries[deck] = nil
        end
    end
end)

local function clearModels()
    for deck, entry in pairs(entries) do
        dismantle(entry)
        entries[deck] = nil
    end
end

local function clear()
    clearModels()
    if baseConnection then baseConnection:Disconnect() end
    baseConnection = nil
    watchedBase = nil
    activeArena = nil
    suppressOwnRemoval = true
    folder:ClearAllChildren()
    suppressOwnRemoval = false
end

local function mount(arena,base,decor,deck,template,expected)
    local copy = template:Clone()
    local frame, dims = copy:GetBoundingBox()
    if math.min(dims.X,dims.Z) < 10.8
        or math.max(dims.X,dims.Z) > 21.6
        or dims.Y < 18.4 or dims.Y > 21.8 then
        copy:Destroy()
        return nil
    end
    local yaw = dims.X > dims.Z and math.pi*.5 or 0
    -- Origin of the SOURCE sculpture is the platform's TOP plane.
    -- The verified authored source extends -2.06 studs below and
    -- ~17.3 above that plane. All positions are relative to GetBoundingBox,
    -- so Roblox asset import pivot/translation cannot displace the model.
    local target = deck.CFrame
        * CFrame.new(0, deck.Size.Y*.5 + dims.Y*.5 - 2.06, 0)
        * CFrame.Angles(0, yaw, 0)
    local pieces = {}
    for _, piece in ipairs(copy:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then
                copy:Destroy()
                return nil
            end
            piece.CFrame = target * frame:ToObjectSpace(piece.CFrame)
            piece.Anchored = false
            piece.Massless = true
            piece.CanCollide = false
            piece.CanTouch = false
            piece.CanQuery = false
            piece.CastShadow = false
            piece:SetAttribute("OriginalHarborPromenadePortal3D",true)
            piece:SetAttribute("Original3DAssetId",ID)
            pieces[#pieces+1] = piece
        end
    end
    if #pieces ~= expected then copy:Destroy(); return nil end
    local entry = {
        model=copy, pieces=pieces, expected=expected, arena=arena,
        base=base, deck=deck, connections={},
        native={}, joints={}, frames={}, sizes={}, lastScale=nil,
        disposing=false,
    }
    local seen = {}
    local function watchNative(part)
        -- A late StreamingEnabled packet must not draw a generic native
        -- Part through the already-approved sculptural cargo gantry.
        if seen[part] or not isNative(part,deck,decor) then return end
        seen[part]=true
        entry.native[#entry.native+1]={
            part=part, original=part.LocalTransparencyModifier,
        }
        if entry.model.Parent == folder and isAlive(entry) then
            part.LocalTransparencyModifier=1
        end
    end
    for _, part in ipairs(decor:GetChildren()) do watchNative(part) end

    copy.Name="ApprovedHarborSuspendedCargoGantry3D"
    copy:SetAttribute("Original3DAssetId",ID)
    copy:SetAttribute("CosmeticOnly",true)
    copy:SetAttribute("OriginalHarborPromenadePortal3D",true)
    copy:SetAttribute("OriginalHarborPromenadeStep",
        deck:GetAttribute("PromenadeStep"))
    copy.Parent=folder
    for _, piece in ipairs(pieces) do
        local joint=Instance.new("Weld")
        joint.Name="HarborCargoGantryCosmeticWeld"
        joint.Part0=deck
        joint.Part1=piece
        joint.C0=deck.CFrame:ToObjectSpace(piece.CFrame)
        joint.C1=CFrame.identity
        joint.Parent=piece
        entry.joints[piece]=joint
        entry.frames[piece]=deck.CFrame:ToObjectSpace(piece.CFrame)
        entry.sizes[piece]=piece.Size
    end
    local function changed()
        refresh(entry)
    end
    for _, property in ipairs({"Size","CanCollide","Transparency",
        "Anchored"}) do
        entry.connections[#entry.connections+1] =
            deck:GetPropertyChangedSignal(property):Connect(changed)
    end
    for _, attribute in ipairs({"CollapsePhase","ChaosPermanentRoute",
        "PromenadeLane","PromenadeStep","RouteTier"}) do
        entry.connections[#entry.connections+1] =
            deck:GetAttributeChangedSignal(attribute):Connect(changed)
    end
    entry.connections[#entry.connections+1] =
        deck.AncestryChanged:Connect(changed)
    entry.connections[#entry.connections+1] =
        decor.ChildAdded:Connect(watchNative)
    entry.connections[#entry.connections+1] =
        copy.DescendantRemoving:Connect(function(child)
            if not entry.disposing and child:IsA("MeshPart") then
                -- Before the next shared camera sampler iteration, restore
                -- native silhouette if the imported model gets incomplete.
                task.defer(refresh,entry)
            end
        end)
    refresh(entry)
    return entry
end

-- The existing scenery-lod.client.lua sampler calls this one function.
-- No extra RenderStepped, Heartbeat, independent polling or remote fetch.
function Kit.sync(arena,cameraPoint,tier,cameraReady,cameraLook,
    pressure,touch,pbrDisabled)
    if arena ~= activeArena then
        clear()
        activeArena=arena
    end
    local rules=BUDGET[tier] or BUDGET.Low
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    local maximum=rules.count
    if tier=="High" then
        maximum=stress==0 and 6 or (stress==1 and 3 or 1)
    elseif tier=="Medium" then
        maximum=stress==0 and 2 or (stress==1 and 1 or 0)
    elseif tier=="Low" and stress>0 then
        -- The first optional GPU pressure restores ALL native arches.
        -- Neither the actual walkway nor hazard warnings are masked.
        maximum=0
    end
    if not arena or not cameraReady or maximum==0
        or typeof(cameraPoint)~="Vector3" then
        clearModels()
        return
    end
    if tostring(arena:GetAttribute("VariantId"))~="Harbor" then
        clearModels()
        return
    end
    local base=arena:FindFirstChild("Base")
    local platforms=arena:FindFirstChild("Platforms")
    local decor=arena:FindFirstChild("Decor")
    if not platforms or not platforms:IsA("Folder")
        or not decor or not decor:IsA("Folder")
        or not realFloorScale(base, arena) then
        clearModels()
        return
    end
    if watchedBase~=base then
        if baseConnection then baseConnection:Disconnect() end
        watchedBase=base
        baseConnection=base:GetPropertyChangedSignal("Size"):Connect(function()
            if not realFloorScale(base, arena) then clearModels() end
        end)
    end
    local source,partCount=modelSource()
    if not source or (tier=="Low" and partCount~=7) then
        clearModels()
        return
    end
    local ranked={}
    for _,deck in ipairs(platforms:GetChildren()) do
        if authentic(deck,arena,base) then
            local distance=(cameraPoint-deck.Position).Magnitude
            local existing=entries[deck]~=nil
            if distance<=rules.distance+(existing and rules.retention or 0) then
                local score=distance-(existing and rules.retention*.6 or 0)
                if typeof(cameraLook)=="Vector3"
                    and cameraLook.Magnitude>.5 and distance>40 then
                    local direction=(deck.Position-cameraPoint).Unit
                    score-=math.min(28,distance*.17)
                        *direction:Dot(cameraLook.Unit)
                end
                ranked[#ranked+1]={deck=deck,score=score}
            end
        end
    end
    table.sort(ranked,function(a,b)
        if a.score==b.score then return a.deck.Name<b.deck.Name end
        return a.score<b.score
    end)
    local wanted={}
    for index=1,math.min(#ranked,maximum) do
        wanted[ranked[index].deck]=true
    end
    for deck,entry in pairs(entries) do
        if not wanted[deck] or not isAlive(entry)
            or entry.source~=source then
            dismantle(entry)
            entries[deck]=nil
        else
            refresh(entry)
        end
    end
    for deck in pairs(wanted) do
        if entries[deck]==nil then
            local mounted=mount(arena,base,decor,deck,source,partCount)
            if mounted then
                mounted.source=source
                entries[deck]=mounted
            end
        end
    end
    -- One complete near-camera source UV model only; no new textures.
    -- Android Low, disabled PBR or any frame pressure: zero allocations.
    local slots = math.min(1, PremiumRoutePbrKit.entryBudget(
        tier, pressure, touch, pbrDisabled))
    if stress > 0 then slots = 0 end
    local selected = {}
    for _, choice in ipairs(ranked) do
        if slots <= 0 then break end
        local entry = entries[choice.deck]
        if entry and isAlive(entry) then
            selected[choice.deck] = true
            slots -= 1
        end
    end
    for deck, entry in pairs(entries) do
        PremiumRoutePbrKit.apply(entry, "gantry", "Harbor",
            selected[deck] == true and isAlive(entry))
    end
end

function Kit.pbrCount()
    local models, appearances = 0, 0
    for _, entry in pairs(entries) do
        if isAlive(entry) then
            local n, m = PremiumRoutePbrKit.count(entry)
            models += n
            appearances += m
        end
    end
    return models, appearances
end

function Kit.count()
    local total=0
    for _,entry in pairs(entries) do
        if isAlive(entry) then total+=1 end
    end
    return total
end

return Kit
