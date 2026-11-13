-- Creator-approved original 3D South Crossroads freight interchange.
-- Exactly 13 visual-only native Parts/Wedges; seven approved MeshParts.
-- No gameplay physics or northern Crossroads signature replacement.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
-- These southern monuments were authored at the ORIGINAL outer perimeter.
-- The shrinking floor changes collision dimensions, not this fixed art.
local function originalFootprint(base, arena)
    if not base or not base:IsA("BasePart") or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide then return nil end
    local sx = base:GetAttribute("OriginalSizeX")
    local sz = base:GetAttribute("OriginalSizeZ")
    if typeof(sx) ~= "number" or typeof(sz) ~= "number"
        or sx ~= sx or sz ~= sz or sx < 318 or sz < 318
        or sx == math.huge or sz == math.huge
        or base.Size.X <= 0 or base.Size.Z <= 0
        or base.Size.X > sx + .2 or base.Size.Z > sz + .2 then
        return nil
    end
    return sx, sz
end

local MODEL_ID=77870668100712
-- One genuine creator-approved seven-MeshPart skyline source on Android
-- Low, ONLY at zero visual pressure. Each arena owns a disjoint south
-- landmark, so this does not mount four models in one active world.
local QUALITIES={Low=1,Medium=1,High=1}
local DISTANCE={Low=290,Medium=420,High=580}
local RETENTION=26
local bucket=Instance.new("Folder")
bucket.Name="ApprovedSouthCrossroadsExchangeLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent=workspace

local activeArena=nil
local entry=nil
local watchedBase=nil
local baseConnections={}

local function restore()
    local current=entry
    if not current then return end
    entry=nil
    for _,c in ipairs(current.connections) do c:Disconnect() end
    for part,alpha in pairs(current.natives) do
        if part.Parent==current.owner and part:IsA("BasePart")
            and part.Anchored and not part.CanCollide
            and not part.CanTouch and not part.CanQuery
            and part.Transparency==1 then
            part.Transparency=alpha
        end
    end
    current.model:Destroy()
end

local function clear()
    restore()
    for _,c in ipairs(baseConnections) do c:Disconnect() end
    table.clear(baseConnections)
    watchedBase=nil
    activeArena=nil
    bucket:ClearAllChildren()
end

local function sourceFor()
    local folder=ReplicatedStorage:FindFirstChild(
        "ApprovedSouthCrossroadsExchangeTemplates")
    if not folder or not folder:IsA("Folder")
        or folder.Parent~=ReplicatedStorage
        or folder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=folder:FindFirstChild("ForgedExchange")
    if not source or not source:IsA("Model") or source.Parent~=folder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalSouthCrossroadsForgedExchange3D")~=true
        or source:GetAttribute("Original3DAssetId")~=MODEL_ID then
        return nil
    end
    local n=0
    for _,p in ipairs(source:GetDescendants()) do
        if p:IsA("BasePart") then
            if not p:IsA("MeshPart") or p.CanCollide
                or p.CanTouch or p.CanQuery then return nil end
            n+=1
        elseif p:IsA("LuaSourceContainer") then return nil end
    end
    if n~=7 then return nil end
    local _,dims=source:GetBoundingBox()
    local lengths={dims.X,dims.Y,dims.Z}
    table.sort(lengths)
    if lengths[1]<4.35 or lengths[1]>4.85
        or lengths[2]<16.70 or lengths[2]>17.55
        or lengths[3]<17.95 or lengths[3]>18.65 then
        return nil
    end
    return source
end

local function context(arena)
    if not arena or not arena:IsA("Folder")
        or arena:GetAttribute("VariantId")~="Crossroads" then return nil end
    local generated=workspace:FindFirstChild("GeneratedMap")
    if not generated or not generated:IsA("Folder")
        or arena.Parent~=generated or arena.Name~="Arena" then return nil end
    local base=arena:FindFirstChild("Base")
    local decor=arena:FindFirstChild("Decor")
    local originalX, originalZ = originalFootprint(base, arena)
    if not base or not base:IsA("BasePart") or base.Parent~=arena
        or not base.Anchored or not base.CanCollide
        or not originalFootprint(base,arena)
        or not decor or not decor:IsA("Folder")
        or decor.Parent~=arena then return nil end
    local owner=decor:FindFirstChild("SouthHorizonMonument")
    if not owner or not owner:IsA("Model") or owner.Parent~=decor
        or owner:GetAttribute("ChaosDistantScenery")~=true
        or owner:GetAttribute("SignatureVariant")~="Crossroads" then return nil end

    local origin=CFrame.new(base.Position+Vector3.new(
        -originalX*.20, base.Size.Y*.5, originalZ*.5+54))
    local specs={
        {"Foundation","Part",Vector3.new(47,2,13),CFrame.new(0,-1,0)},
        {"FloorInset","Part",Vector3.new(39,.3,10),CFrame.new(0,.16,0)},
        {"ExchangeCore","Part",Vector3.new(8,39,8),CFrame.new(0,19.5,0)},
        {"WestFork","Part",Vector3.new(21,2.4,5.5),
            CFrame.new(-12,34,0)*CFrame.Angles(0,0,-math.rad(14))},
        {"EastFork","Part",Vector3.new(21,2.4,5.5),
            CFrame.new(12,34,0)*CFrame.Angles(0,0,math.rad(14))},
        {"WestFreightArm","WedgePart",Vector3.new(9,4.8,6.4),
            CFrame.new(-21,39,0)*CFrame.Angles(0,math.pi,0)},
        {"EastFreightArm","WedgePart",Vector3.new(9,4.8,6.4),
            CFrame.new(21,39,0)},
        {"WestCounterweight","Part",Vector3.new(5,8,5.5),
            CFrame.new(-18,23,0)},
        {"EastCounterweight","Part",Vector3.new(5,8,5.5),
            CFrame.new(18,23,0)},
        {"WestSignal","Part",Vector3.new(7,.32,.4),
            CFrame.new(-15,36,-2.9)},
        {"EastSignal","Part",Vector3.new(7,.32,.4),
            CFrame.new(15,36,-2.9)},
        {"CentralSwitchCab","Part",Vector3.new(10,5,7),
            CFrame.new(0,43,0)},
        {"CabWindow","Part",Vector3.new(7,2.2,.28),
            CFrame.new(0,43,-3.6)},
    }
    local natives={}
    for index,spec in ipairs(specs) do
        local part=owner:FindFirstChild(spec[1])
        local intended=origin*spec[4]
        if not part or not part:IsA(spec[2]) or part.Parent~=owner
            or not part.Anchored or part.CanCollide
            or part.CanTouch or part.CanQuery
            or (part.Size-spec[3]).Magnitude>.10
            or (part.Position-intended.Position).Magnitude>.16
            or part.CFrame.LookVector:Dot(intended.LookVector)<.999
            or part.CFrame.UpVector:Dot(intended.UpVector)<.999
            or (part:IsA("Part")
                and part.Shape~=Enum.PartType.Block) then
            return nil
        end
        natives[index]=part
    end
    return base,owner,natives,origin.Position+Vector3.new(0,22.15,0)
end

local function fit(source,center)
    local model=source:Clone()
    local _,dimensions=model:GetBoundingBox()
    -- Fail closed if the approved glTF import swaps X/Y/Z axes.
    if dimensions.X<17.95 or dimensions.X>18.65
        or dimensions.Y<16.70 or dimensions.Y>17.55
        or dimensions.Z<4.35 or dimensions.Z>4.85 then
        model:Destroy()
        return nil
    end
    local scale=50.82/dimensions.X
    if scale<2.68 or scale>2.92
        or not pcall(function() model:ScaleTo(scale) end) then
        model:Destroy()
        return nil
    end
    local frame,scaled=model:GetBoundingBox()
    if scaled.X<50.0 or scaled.X>51.9
        or scaled.Y<46.2 or scaled.Y>48.8
        or scaled.Z<12.15 or scaled.Z>13.8 then
        model:Destroy()
        return nil
    end
    local target=CFrame.new(center)
    local pieces={}
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                model:Destroy()
                return nil
            end
            part.CFrame=target*frame:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.Massless=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.CastShadow=false
            part:SetAttribute("CosmeticOnly",true)
            part:SetAttribute("Original3DAssetId",MODEL_ID)
            pieces[#pieces+1]=part
        end
    end
    if #pieces~=7 then
        model:Destroy()
        return nil
    end
    model.Name="OriginalSouthCrossroadsForgedExchange3D"
    model:SetAttribute("CosmeticOnly",true)
    model:SetAttribute("Original3DAssetId",MODEL_ID)
    return model,pieces
end

local function mount(arena,source)
    if entry then return end
    local base,owner,natives,center=context(arena)
    if not base then return end
    local model,pieces=fit(source,center)
    if not model then return end
    local currentBase,currentOwner,currentNatives=context(arena)
    if currentBase~=base or currentOwner~=owner
        or not source.Parent or not currentNatives or #currentNatives~=13 then
        model:Destroy()
        return
    end
    local item={
        model=model,pieces=pieces,natives={},frames={},
        owner=owner,arena=arena,source=source,
        base=base,connections={},
    }
    for _,native in ipairs(natives) do
        item.natives[native]=native.Transparency
        item.frames[native]=native.CFrame
    end
    model.Parent=bucket
    entry=item
    for _,native in ipairs(natives) do native.Transparency=1 end
    item.connections[#item.connections+1]=
        owner.AncestryChanged:Connect(function()
            if owner.Parent~=arena:FindFirstChild("Decor") then restore() end
        end)
    item.connections[#item.connections+1]=
        source.AncestryChanged:Connect(function()
            if not source.Parent then restore() end
        end)
    item.connections[#item.connections+1]=
        source.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore() end
        end)
    item.connections[#item.connections+1]=
        model.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore() end
        end)
    for _,native in ipairs(natives) do
        item.connections[#item.connections+1]=
            native.AncestryChanged:Connect(function()
                if native.Parent~=owner then restore() end
            end)
    end
end

bucket.ChildRemoved:Connect(function(child)
    if entry and entry.model==child then restore() end
end)

function Kit.sync(arena,cameraPoint,tier,cameraReady,pressure)
    if arena~=activeArena then clear();activeArena=arena end
    local cap=QUALITIES[tier] or 0
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if stress==1 and tier~="High" then cap=0 end
    if stress>=2 then cap=0 end
    if cap==0 or not cameraReady or typeof(cameraPoint)~="Vector3" then
        restore()
        return
    end
    local base,owner,natives,center=context(arena)
    if not base then restore();return end
    local distance=(center-cameraPoint).Magnitude
    local maxDistance=(DISTANCE[tier] or 0)+(entry and RETENTION or 0)
    if distance>maxDistance then restore();return end
    if watchedBase~=base then
        for _,c in ipairs(baseConnections) do c:Disconnect() end
        table.clear(baseConnections)
        watchedBase=base
        local function checkBase()
            if base.Parent~=arena or not base.Anchored or not base.CanCollide
                or not originalFootprint(base,arena) then restore() end
        end
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Size"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("CanCollide"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base.AncestryChanged:Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Anchored"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base:GetAttributeChangedSignal("OriginalSizeX"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base:GetAttributeChangedSignal("OriginalSizeZ"):Connect(checkBase)
    end
    local source=sourceFor()
    if not source then restore();return end
    if entry then
        local bad=entry.arena~=arena or entry.owner~=owner
            or entry.base~=base or entry.source~=source
            or entry.model.Parent~=bucket or #entry.pieces~=7
        if not bad then
            for native,frame in pairs(entry.frames) do
                if native.Parent~=owner
                    or (native.CFrame.Position-frame.Position).Magnitude>.08
                    or native.CFrame.LookVector:Dot(frame.LookVector)<.999
                    or native.CFrame.UpVector:Dot(frame.UpVector)<.999 then
                    bad=true
                    break
                end
            end
            for _,p in ipairs(entry.pieces) do
                if not p:IsDescendantOf(entry.model) then bad=true end
            end
        end
        if bad then restore() end
    end
    if not entry then mount(arena,source) end
    if entry then
        for native in pairs(entry.natives) do native.Transparency=1 end
    end
end

function Kit.count()
    return entry and entry.model.Parent==bucket
        and #entry.pieces==7 and 1 or 0
end

function Kit.replacedNativeCount()
    if Kit.count()==0 then return 0 end
    local hidden=0
    for native in pairs(entry.natives) do
        if native.Parent==entry.owner and native.Transparency==1 then
            hidden+=1
        end
    end
    return hidden
end

return Kit
