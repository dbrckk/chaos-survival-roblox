-- P4: authentic 3D housing for Crossroads' REAL active gold junctions.
-- Use the previously owner-approved CornerGuard sculpture, never a fake
-- MeshId, collision surface, client-controlled trigger or new render loop.
-- Caller owns the existing FluxRelayLocal visual budget folder / cadence.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local APPROVED = 102215174919938
local mounted = {}

local function verifiedSource()
    local holder = ReplicatedStorage:FindFirstChild("ApprovedFloorReliefTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild("CornerGuard")
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalFloorRelief3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= APPROVED
    then return nil end
    local count = 0
    for _, part in ipairs(source:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return nil end
            count += 1
        elseif part:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, bounds = source:GetBoundingBox()
    if bounds.X < 4.7 or bounds.X > 5.6
        or bounds.Z < 4.7 or bounds.Z > 5.6
        or bounds.Y < 0.24 or bounds.Y > 0.56
    then return nil end
    return source
end

local function validPad(pad, yard)
    if not pad or not yard or pad.Parent ~= yard
        or yard.Name ~= "JunctionSwitchyard"
        or not yard:IsA("Folder") or not pad:IsA("BasePart")
        or not pad.Anchored or pad.CanCollide or not pad.CanTouch
        or pad.CanQuery or pad:GetAttribute("JunctionActive") ~= true
    then return false end
    local index = pad:GetAttribute("JunctionIndex")
    if type(index) ~= "number" or index % 1 ~= 0
        or index < 1 or index > 4
        or pad.Name ~= "JunctionSwitch" .. tostring(index)
        or math.abs(pad.Size.X - 6.2) > 0.1
        or math.abs(pad.Size.Z - 6.2) > 0.1
        or math.abs(pad.Size.Y - 4.8) > 0.1
    then return false end
    local mechanics = yard.Parent
    local arena = mechanics and mechanics.Parent
    local generated = arena and arena.Parent
    return mechanics and mechanics.Name == "Mechanics"
        and arena and arena.Name == "Arena"
        and arena:GetAttribute("VariantId") == "Crossroads"
        and generated and generated.Name == "GeneratedMap"
        and generated.Parent == workspace
end

local function dispose(pad)
    local entry = mounted[pad]
    if not entry then return end
    mounted[pad] = nil
    if entry.model.Parent then entry.model:Destroy() end
end

local function mount(pad, yard, owner, source)
    if not validPad(pad, yard) or mounted[pad] then return end
    local clone = source:Clone()
    local frame, bounds = clone:GetBoundingBox()
    local scale = math.min(1.0,
        pad.Size.X * 0.84 / math.max(bounds.X, 0.01),
        pad.Size.Z * 0.84 / math.max(bounds.Z, 0.01),
        0.44 / math.max(bounds.Y, 0.01))
    if scale < 0.68 or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return
    end
    frame, bounds = clone:GetBoundingBox()
    if bounds.X > 5.35 or bounds.Z > 5.35
        or bounds.Y > 0.45 then
        clone:Destroy()
        return
    end
    -- The live golden chevrons are at local Y=-2.04; this genuine forged
    -- low-profile housing is tucked against the actual floor below them.
    -- It never extends or replaces the invisible server touch volume.
    local target = pad.CFrame
        * CFrame.new(0, -1.88 - bounds.Y * 0.5, 0)
    local count = 0
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return
            end
            part.CFrame = target * frame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part:SetAttribute("CosmeticOnly", true)
            part:SetAttribute("Original3DAssetId", APPROVED)
            count += 1
        end
    end
    if count < 1 or count > 12
        or not validPad(pad, yard) or source.Parent == nil then
        clone:Destroy()
        return
    end
    clone.Name = "ApprovedJunctionHousing3D_"
        .. tostring(pad:GetAttribute("JunctionIndex"))
    clone:SetAttribute("CosmeticOnly", true)
    clone.Parent = owner
    mounted[pad] = {
        model = clone, source = source, owner = owner,
        parts = count, yard = yard,
    }
end

function Kit.sync(yard, owner, quality, pressure, touch, activeRound)
    local stress = math.clamp(math.floor(tonumber(pressure) or 0), 0, 2)
    local cap = quality == "High" and (touch and 2 or 2)
        or (quality == "Medium" and 1 or 0)
    if stress == 1 then cap = math.min(cap, 1) end
    if stress == 2 then cap = 0 end
    -- Low or pressurized Android never runs expensive source/mesh census.
    -- A newly arrived verified template is still picked up on the
    -- existing Flux Relay cadence as soon as graphics are eligible.
    local source = cap > 0 and activeRound == true
        and verifiedSource() or nil
    if not source then cap = 0 end

    -- A never-lit or currently inactive junction is not shown as usable.
    -- Active pairs are server-owned; late streaming and a rotated pair
    -- are handled by the SAME existing Flux Relay rendering cadence.
    local candidates = {}
    local camera = workspace.CurrentCamera
    local cameraPoint = camera and camera.CFrame.Position or Vector3.zero
    if yard and yard.Parent and cap > 0 then
        for index = 1, 4 do
            local pad = yard:FindFirstChild("JunctionSwitch" .. index)
            if validPad(pad, yard) then
                candidates[#candidates + 1] = {
                    pad = pad,
                    distance = (pad.Position - cameraPoint).Magnitude,
                    index = index,
                }
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.distance == b.distance then return a.index < b.index end
        return a.distance < b.distance
    end)
    local desired = {}
    for i = 1, math.min(cap, #candidates) do
        desired[candidates[i].pad] = true
    end
    for pad, entry in pairs(mounted) do
        local invalid = not desired[pad] or entry.source ~= source
            or entry.owner ~= owner or entry.model.Parent ~= owner
            or not validPad(pad, entry.yard)
        if not invalid then
            local count = 0
            for _, part in ipairs(entry.model:GetDescendants()) do
                if part:IsA("BasePart") then
                    if not part:IsA("MeshPart") then invalid = true end
                    count += 1
                elseif part:IsA("LuaSourceContainer") then invalid = true end
            end
            invalid = invalid or count ~= entry.parts
        end
        if invalid then dispose(pad) end
    end
    if source then
        for i = 1, math.min(cap, #candidates) do
            local pad = candidates[i].pad
            if not mounted[pad] then mount(pad, yard, owner, source) end
        end
    end
    local total = 0
    for _ in pairs(mounted) do total += 1 end
    return total
end

function Kit.clear()
    local keys = {}
    for pad in pairs(mounted) do keys[#keys+1] = pad end
    for _, pad in ipairs(keys) do dispose(pad) end
end

return Kit
