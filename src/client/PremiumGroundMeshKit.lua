-- Original, creator-owned, approved UV/tangent 3D floor plating.
-- The 320-stud arena's true server Base, six-by-six material floor, warning
-- glyphs and collision remain authoritative; these are camera-near cosmetics.
-- Reuse the existing scenery LOD sampler: no new RenderStepped/polling loop.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PremiumGroundMeshKit = {}

-- Approved original Roblox MODEL package, not an invented MeshPart.MeshId.
-- Roblox import/moderation proof: GitHub Actions #41622860616.
local APPROVED_GROUND_ID = 72507987666671
local TEMPLATE_NAME = "PremiumGroundTile"
-- The 6x6 arena has 36 manufactured floor bays, but a six-model High
-- cap left most of the camera-facing deck as generic native slab art.
-- Spend genuine 3D on the nearest visible bays, not the whole world:
-- mobile Low remains ONE imported tile; Medium is five; High twelve.
-- No new source assets, stream loops or physical surfaces are created.
local BUDGET = {
    Low = {count = 1, distance = 112, retention = 18},
    Medium = {count = 5, distance = 200, retention = 24},
    High = {count = 12, distance = 260, retention = 28},
}

local folder = Instance.new("Folder")
folder.Name = "OriginalPremiumGroundMeshesLocal"
folder.Parent = workspace

local mounted = {}
local activeArena = nil
local watchedBase = nil
local baseChanged = nil

local function restore(entry)
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    entry.model:Destroy()
end

local function clearMounted()
    for ground, entry in pairs(mounted) do
        restore(entry)
        mounted[ground] = nil
    end
end

local function clear()
    clearMounted()
    if baseChanged then baseChanged:Disconnect() end
    baseChanged = nil
    watchedBase = nil
    activeArena = nil
    folder:ClearAllChildren()
end

local function originalSurface(ground, decor, base)
    -- Only source-authored 49-stud modular floors may take imported art.
    -- Do not decorate the real Base, platform collider, hazard or arbitrary
    -- player-supplied instance with a falsely safe-looking floor surface.
    if not ground or not decor or not base or not base.Parent
        or ground.Parent ~= decor or not ground:IsA("Part")
        or not ground.Name:match("^PremiumGroundModule%d+$")
        or ground:GetAttribute("OriginalGroundFinish") ~= true
        or ground:GetAttribute("PremiumArchitecturalSurface") ~= true
        or ground.CanCollide or ground.CanTouch or ground.CanQuery
        or ground.Transparency >= 0.5
        or ground.Size.X < 35 or ground.Size.Z < 35
        or base.Size.X < 318 or base.Size.Z < 318 then
        return false
    end
    return true
end

local function validTemplate()
    local holder = ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates")
    if not holder or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local template = holder:FindFirstChild(TEMPLATE_NAME)
    if not template or not template:IsA("Model")
        or template:GetAttribute("Original3DAssetId") ~= APPROVED_GROUND_ID
        or template:GetAttribute("OwnerVerified") ~= true
        or template:GetAttribute("CosmeticOnly") ~= true then
        return nil
    end
    local meshCount = 0
    for _, descendant in ipairs(template:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if not descendant:IsA("MeshPart") then return nil end
            meshCount += 1
        elseif descendant:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if meshCount < 1 or meshCount > 24 then return nil end
    return template
end

local function hide(entry)
    for _, piece in ipairs(entry.pieces) do
        if piece.Parent and piece.LocalTransparencyModifier ~= 1 then
            piece.LocalTransparencyModifier = 1
        end
    end
end

local function safeAfterMount(entry, base)
    local ground = entry.ground
    if not originalSurface(ground, entry.decor, base)
        or (ground.Size - entry.initialSize).Magnitude >= 0.07
        or (ground.CFrame.Position - entry.initialCFrame.Position).Magnitude >= 0.07
        -- A rotation or streamed reanchor must not leave ghost 3D paint.
        or ground.CFrame.LookVector:Dot(entry.initialCFrame.LookVector) < 0.999
        or ground.CFrame.RightVector:Dot(entry.initialCFrame.RightVector) < 0.999
    then
        return false
    end
    return true
end

local function mount(ground, decor, base, template)
    local _, templateSize = template:GetBoundingBox()
    if templateSize.X < 30 or templateSize.Z < 30
        or templateSize.X > 65 or templateSize.Z > 65
        or templateSize.Y > 1.5 or templateSize.Y <= 0 then
        return nil
    end
    local scale = math.min(
        ground.Size.X * 0.97 / templateSize.X,
        ground.Size.Z * 0.97 / templateSize.Z, 1.05)
    if scale < 0.60 then return nil end
    local clone = template:Clone()
    local scaled = pcall(function() clone:ScaleTo(scale) end)
    if not scaled then
        clone:Destroy()
        return nil
    end
    local sourceFrame, dimensions = clone:GetBoundingBox()
    if dimensions.X > ground.Size.X * 0.98
        or dimensions.Z > ground.Size.Z * 0.98
        or dimensions.Y > 1.5 then
        clone:Destroy()
        return nil
    end

    -- The original warning/safe-route paint is at ~0.19-0.20 studs above
    -- the Base. This 3D art's top is capped at +0.033 over the existing
    -- PremiumGroundModule center (+0.153), i.e. below danger text/glyphs.
    -- Keep real PBR underlay visible through the manufactured 3D seams.
    local number = tonumber(ground.Name:match("(%d+)$")) or 1
    local yaw = number % 2 == 0 and math.pi * 0.5 or 0
    local frame = ground.CFrame
        * CFrame.new(0, 0.032 - dimensions.Y * 0.5, 0)
        * CFrame.Angles(0, yaw, 0)
    local pieces = {}
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            part.CFrame = frame * sourceFrame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            pieces[#pieces + 1] = part
        end
    end
    if #pieces == 0 or #pieces > 24 then
        clone:Destroy()
        return nil
    end
    clone.Name = "OriginalPremiumArenaGround3D"
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("OriginalGroundMeshId", APPROVED_GROUND_ID)
    clone:SetAttribute("Original3DSourceGround", ground.Name)
    clone.Parent = folder

    local entry = {
        model = clone, ground = ground, decor = decor,
        initialSize = ground.Size, initialCFrame = ground.CFrame,
        pieces = pieces, connections = {},
    }
    local function onGroundChanged()
        -- Immediate on first shrink step, not 0.65s later in the LOD loop.
        -- The original noncolliding 2K PBR tiles remain visible as fallback.
        if not safeAfterMount(entry, base) then hide(entry) end
    end
    for _, prop in ipairs({"Size", "CFrame", "Transparency"}) do
        entry.connections[#entry.connections + 1] =
            ground:GetPropertyChangedSignal(prop):Connect(onGroundChanged)
    end
    entry.connections[#entry.connections + 1] =
        ground.AncestryChanged:Connect(onGroundChanged)
    onGroundChanged()
    return entry
end

-- Exclusively called by the EXISTING arena/scenery LOD sampling owner.
function PremiumGroundMeshKit.sync(arena, cameraPoint, tier, cameraReady, cameraLook)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[tier] or BUDGET.Low
    if not arena or not cameraReady or typeof(cameraPoint) ~= "Vector3" then
        clearMounted()
        return
    end
    local base = arena:FindFirstChild("Base")
    local decor = arena:FindFirstChild("Decor")
    if not base or not base:IsA("BasePart")
        or not decor or not decor:IsA("Folder") then
        clearMounted()
        return
    end
    if base ~= watchedBase then
        if baseChanged then baseChanged:Disconnect() end
        watchedBase = base
        baseChanged = base:GetPropertyChangedSignal("Size"):Connect(function()
            if base.Size.X < 318 or base.Size.Z < 318 then
                clearMounted()
            end
        end)
    end
    if base.Size.X < 318 or base.Size.Z < 318 then
        clearMounted()
        return
    end

    -- Rank the same small number of imported 3D tiles for visible ground.
    -- A third-person camera can sit closer to tiles BEHIND the player than
    -- tiles on screen; raw nearest-first spends Android meshes off screen.
    -- Keep underfoot panels even during camera rotation or steep pitch.
    local look = typeof(cameraLook) == "Vector3"
        and Vector3.new(cameraLook.X, 0, cameraLook.Z)
        or Vector3.zero
    local hasFacing = look.Magnitude > 0.2
    if hasFacing then look = look.Unit end

    local candidates = {}
    for _, part in ipairs(decor:GetChildren()) do
        if originalSurface(part, decor, base) then
            local toTile = part.Position - cameraPoint
            local distance = toTile.Magnitude
            local resident = mounted[part] ~= nil
            -- Only current, unmodified cosmetics receive an EXIT margin.
            -- New tiles still enter at exactly the previous tier distance.
            if distance <= budget.distance
                + (resident and budget.retention or 0) then
                local priority = distance
                    - (resident and budget.retention * 0.55 or 0)
                local horizontal = Vector3.new(toTile.X, 0, toTile.Z)
                if hasFacing and horizontal.Magnitude > 54
                    and horizontal.Unit:Dot(look) < -0.15 then
                    priority += 72
                end
                candidates[#candidates + 1] = {
                    part = part,
                    distance = distance,
                    priority = priority,
                }
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end
        if a.distance ~= b.distance then
            return a.distance < b.distance
        end
        return a.part.Name < b.part.Name
    end)
    local template = validTemplate()
    local wanted = {}
    if template then
        for i = 1, math.min(budget.count, #candidates) do
            wanted[candidates[i].part] = true
        end
    end

    for ground, entry in pairs(mounted) do
        if not wanted[ground] or not safeAfterMount(entry, base) then
            restore(entry)
            mounted[ground] = nil
        end
    end
    for ground in pairs(wanted) do
        if not mounted[ground] then
            mounted[ground] = mount(ground, decor, base, template)
        end
    end
end

function PremiumGroundMeshKit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        if entry.model.Parent then n += 1 end
    end
    return n
end

return PremiumGroundMeshKit
