-- Original approved 3D container freighter replaces the 70+ native
-- Part/WedgePart cargo ship, with a seven-MeshPart near-camera Low
-- replacement when healthy. All native pieces remain reversible fallback.
-- The existing scenery-lod sampler is the ONLY scheduling owner.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local ID = 128820723471019
local SOURCE_SCALE = 3.5
local folder = Instance.new("Folder")
folder.Name = "OriginalHarborFreighterLocal"
folder:SetAttribute("CosmeticOnly",true)
folder.Parent = workspace
local entry = nil
local currentArena = nil

local function approved()
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedHarborFreighterTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local model=holder:FindFirstChild("OriginalContainerFreighter")
    if not model or not model:IsA("Model") or model.Parent~=holder
        or model:GetAttribute("OwnerVerified")~=true
        or model:GetAttribute("CosmeticOnly")~=true
        or model:GetAttribute("OriginalHarborFreighter3D")~=true
        or model:GetAttribute("Original3DAssetId")~=ID then return nil end
    local n=0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then return nil end
            n+=1
        elseif part:IsA("LuaSourceContainer") then return nil end
    end
    if n~=7 then return nil end
    local _,b=model:GetBoundingBox()
    if math.max(b.X,b.Z)<28.6 or math.max(b.X,b.Z)>29.6
        or math.min(b.X,b.Z)<6 or math.min(b.X,b.Z)>6.9
        or b.Y<9.1 or b.Y>10.6 then return nil end
    return model
end

-- Exterior ships remain fixed while the actual survival floor shrinks.
-- Verify the signed original map footprint rather than its live width.
local function authenticBase(base,arena)
    if not base or not base:IsA("BasePart") or base.Parent~=arena
        or not base.Anchored or not base.CanCollide then return false end
    local originalX=base:GetAttribute("OriginalSizeX")
    local originalZ=base:GetAttribute("OriginalSizeZ")
    return typeof(originalX)=="number" and typeof(originalZ)=="number"
        and originalX>=318 and originalZ>=318
        and base.Size.X>0 and base.Size.Z>0
        and base.Size.X<=originalX+.2 and base.Size.Z<=originalZ+.2
end

local function genuine(arena,base,ship)
    if not arena or not base or not ship
        or tostring(arena:GetAttribute("VariantId"))~="Harbor"
        or not authenticBase(base,arena) or not ship:IsA("Model")
        or ship.Name~="HarborCargoVessel"
        or ship:GetAttribute("HarborVesselScenery")~=true
        or ship:GetAttribute("CosmeticOnly")~=true then return false end
    local decor=arena:FindFirstChild("Decor")
    local fleet=decor and decor:FindFirstChild("StormHarborGantryFleet")
    if not fleet or ship.Parent~=fleet then return false end
    local deck=ship:FindFirstChild("MainCargoDeck")
    local hull=ship:FindFirstChild("MainHull")
    if not deck or not hull or not deck:IsA("BasePart")
        or not hull:IsA("BasePart") or not deck.Anchored
        or deck.CanCollide or hull.CanCollide
        or math.abs(deck.Size.X-88)>.5
        or math.abs(deck.Size.Z-19)>.5 then return false end
    return true
end

local function alive(e)
    if not e or not e.model or e.model.Parent~=folder
        or e.arena~=currentArena
        or not genuine(e.arena,e.base,e.ship)
        or e.ship:FindFirstChild("MainCargoDeck")~=e.deck
        or e.source~=approved() then return false end
    local n=0
    for _,p in ipairs(e.parts) do
        if not p or p.Parent~=e.model then return false end
        n+=1
    end
    return n==7
end

local function reveal(e)
    if not e then return end
    local visible=alive(e)
    for _,p in ipairs(e.parts) do
        if p.Parent then p.LocalTransparencyModifier=visible and 0 or 1 end
    end
    -- Client-only Transparency avoids fighting SceneryLod's
    -- LocalTransparencyModifier owner on this distant native vessel.
    for part,alpha in pairs(e.original) do
        if part.Parent then
            part.Transparency=visible and 1 or alpha
        end
    end
end

local function clear()
    if not entry then return end
    local old=entry
    entry=nil
    old.disposing=true
    for _,conn in ipairs(old.connections) do conn:Disconnect() end
    for part,alpha in pairs(old.original) do
        if part.Parent then part.Transparency=alpha end
    end
    old.model:Destroy()
end

local function mount(arena,base,ship,source)
    local deck=ship:FindFirstChild("MainCargoDeck")
    if not deck then return nil end
    local clone=source:Clone()
    if not pcall(function() clone:ScaleTo(SOURCE_SCALE) end) then
        clone:Destroy();return nil
    end
    local frame,b=clone:GetBoundingBox()
    if math.max(b.X,b.Z)<99 or math.max(b.X,b.Z)>104
        or math.min(b.X,b.Z)<20.8 or math.min(b.X,b.Z)>24.2
        or b.Y<31.8 or b.Y>37.2 then
        clone:Destroy();return nil
    end
    local yaw=b.X<b.Z and math.pi*.5 or 0
    -- Authored origin is 0,0,0; source deck at Y=-.38*3.5.
    -- Authored bbox center is Y~2.31*3.5. The actual native cargo
    -- deck is Y=+4.1 relative to ship origin. Match the native deck
    -- rather than the importer model pivot, which may be arbitrary.
    local centerY=(7.195-2.575)*.5*SOURCE_SCALE
    local target=deck.CFrame*CFrame.new(0,centerY+.38*SOURCE_SCALE,0)
        *CFrame.Angles(0,yaw,0)
    local pieces={}
    for _,part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy();return nil
            end
            part.CFrame=target*frame:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.CastShadow=false
            part.Massless=true
            part:SetAttribute("OriginalHarborFreighter3D",true)
            part:SetAttribute("Original3DAssetId",ID)
            pieces[#pieces+1]=part
        end
    end
    if #pieces~=7 then clone:Destroy();return nil end
    local originals={}
    for _,part in ipairs(ship:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.CanCollide or part.CanTouch or part.CanQuery then
                clone:Destroy();return nil
            end
            originals[part]=part.Transparency
        end
    end
    if #ship:GetDescendants()<40 then clone:Destroy();return nil end
    local e={arena=arena,base=base,ship=ship,deck=deck,
        model=clone,source=source,parts=pieces,original=originals,
        connections={},disposing=false}
    clone.Name="ApprovedHarborFreighter3D"
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",ID)
    clone.Parent=folder
    local function changed() reveal(e) end
    e.connections[#e.connections+1]=ship.DescendantAdded:Connect(function(p)
        if p:IsA("BasePart") and not p.CanCollide
            and not p.CanTouch and not p.CanQuery then
            originals[p]=p.Transparency
            if alive(e) then p.Transparency=1 end
        end
    end)
    e.connections[#e.connections+1]=ship.AncestryChanged:Connect(changed)
    e.connections[#e.connections+1]=base:GetPropertyChangedSignal(
        "Size"):Connect(changed)
    e.connections[#e.connections+1]=clone.DescendantRemoving:Connect(function(p)
        if not e.disposing and p:IsA("MeshPart") then
            task.defer(reveal,e)
        end
    end)
    reveal(e)
    return e
end

function Kit.sync(arena,cameraPoint,quality,cameraReady,_,pressure)
    if arena~=currentArena then
        clear()
        currentArena=arena
    end
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    -- On Low, substitute the original seven source-authenticated MeshParts
    -- for the 14-part coarse native silhouette only within 295 studs.
    -- First graphics pressure restores native immediately; Medium/High
    -- retain their established pressure-2 fallback.
    if not arena or not cameraReady
        or (quality=="Low" and stress>=1)
        or (quality~="Low" and stress>=2)
        or typeof(cameraPoint)~="Vector3" then
        clear();return
    end
    local decor=arena:FindFirstChild("Decor")
    local fleet=decor and decor:FindFirstChild("StormHarborGantryFleet")
    local ship=fleet and fleet:FindFirstChild("HarborCargoVessel")
    local base=arena:FindFirstChild("Base")
    if not decor or not fleet or not base
        or not genuine(arena,base,ship) then
        clear();return
    end
    local distance=(cameraPoint-ship:GetPivot().Position).Magnitude
    local maximum=quality=="Low" and 295
        or (quality=="High" and 610 or 440)
    if distance>maximum+(entry and 45 or 0) then
        clear();return
    end
    local source=approved()
    if not source then clear();return end
    if entry and (entry.source~=source or entry.ship~=ship
        or not alive(entry)) then clear() end
    if not entry then entry=mount(arena,base,ship,source) end
    if entry then reveal(entry) end
end

function Kit.count()
    return alive(entry) and 1 or 0
end

return Kit
