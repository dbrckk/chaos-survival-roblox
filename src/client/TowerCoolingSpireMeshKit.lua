-- Five genuine Tower Run industrial cooling spires, imported as real
-- creator-authored 7-MeshPart 3D source. The legacy five square native
-- "TowerCoolingMass" Parts remain FULLY intact as a reversible fallback.
-- No server colliders, new lights, animation loop or RemoteEvents.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
local ID=95543769387033
local SOURCE_SCALE=.42
local ORIGINAL_BODY_HEIGHT=40
local BUDGET={
    Low={models=0,distance=0,retention=0},
    Medium={models=2,distance=285,retention=32},
    High={models=5,distance=405,retention=45},
}

local folder=Instance.new("Folder")
folder.Name="OriginalTowerCoolingSpireLocal"
folder:SetAttribute("CosmeticOnly",true)
folder.Parent=workspace

local activeArena=nil
local active={}

local function source()
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedTowerCoolingSpireTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified")~=true
        or holder:GetAttribute("Original3DAssetId")~=ID then return nil end
    local model=holder:FindFirstChild("RealCoolingSpire")
    if not model or not model:IsA("Model") or model.Parent~=holder
        or model:GetAttribute("OwnerVerified")~=true
        or model:GetAttribute("CosmeticOnly")~=true
        or model:GetAttribute("Original3DAssetId")~=ID
        or model:GetAttribute("OriginalTowerCoolingSpire3D")~=true
        or model:GetAttribute("Original3DTriangleCount")~=6380
        or model:GetAttribute("SourceArchitecturalBodyHeight")~=40
        then return nil end
    local n=0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide or part.CanTouch
                or part.CanQuery then return nil end
            n+=1
        elseif part:IsA("LuaSourceContainer") then return nil end
    end
    if n~=7 then return nil end
    local _,bounds=model:GetBoundingBox()
    local long=math.max(bounds.X,bounds.Z)
    local short=math.min(bounds.X,bounds.Z)
    if long<6.35 or long>6.98 or short<4.70 or short>5.20
        or bounds.Y<28.8 or bounds.Y>29.5 then return nil end
    return model
end

local function arenaForTowers(arena)
    if not arena or not arena:IsA("Folder")
        or tostring(arena:GetAttribute("VariantId"))~="Towers" then
        return nil
    end
    local generated=workspace:FindFirstChild("GeneratedMap")
    if not generated or arena.Parent~=generated then return nil end
    local base=arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") or not base.Anchored
        or base.Size.X<160 or base.Size.Z<160 then return nil end
    local mid=workspace:FindFirstChild("ArenaMidgroundMassLocal")
    if not mid or not mid:IsA("Folder") then return nil end
    return base,mid
end

local function nativeTower(part,mid,base,index)
    if not part or not part:IsA("BasePart") or part.Parent~=mid
        or part.Name~="TowerCoolingMass"..index
        or part:GetAttribute("OriginalTowerCoolingSpireIndex")~=index
        or not part.Anchored or part.CanCollide or part.CanTouch
        or part.CanQuery then return false end
    local heights={34,44,30,38,27}
    local widths={9,10,8,9,7}
    if math.abs(part.Size.Y-heights[index])>.15
        or math.abs(part.Size.X-widths[index])>.15
        or math.abs(part.Size.Z-widths[index])>.15
        or base.Size.X<160 or base.Size.Z<160 then
        return false
    end
    return true
end

local function alive(e)
    if not e or not e.model or e.model.Parent~=folder
        or e.arena~=activeArena or e.body.Parent~=e.mid
        or e.source.Parent==nil or e.base.Size.X<160
        or e.base.Size.Z<160 or not e.body.Anchored
        or e.body.CanCollide or e.body.CanTouch or e.body.CanQuery
        or e.body:GetAttribute("OriginalTowerCoolingSpireIndex")~=e.index
        or (e.body.Size-e.originalSize).Magnitude>.15 then return false end
    local n=0
    for _,part in ipairs(e.pieces) do
        if not part or part.Parent~=e.model then return false end
        n+=1
    end
    return n==7
end

local function visibility(e)
    local show=alive(e)
    for _,piece in ipairs(e.pieces) do
        if piece.Parent then piece.LocalTransparencyModifier=show and 0 or 1 end
    end
    for part,original in pairs(e.native) do
        if part.Parent then part.Transparency=show and 1 or original end
    end
    return show
end

local function dismount(e)
    e.disposing=true
    for _,conn in ipairs(e.connections) do conn:Disconnect() end
    for part,alpha in pairs(e.native) do
        if part.Parent then part.Transparency=alpha end
    end
    e.model:Destroy()
end

local function clear()
    for body,e in pairs(active) do
        dismount(e)
        active[body]=nil
    end
end

local function mount(arena,base,mid,body,index,approved)
    if not nativeTower(body,mid,base,index) then return nil end
    local clone=approved:Clone()
    local scale=body.Size.Y/(ORIGINAL_BODY_HEIGHT*SOURCE_SCALE)
    if not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy();return nil
    end
    local frame,bounds=clone:GetBoundingBox()
    -- The sculpted spire is ~69 source world studs high, adapted to
    -- the 27..44-stud legacy shaft without flattening details.
    if bounds.Y<body.Size.Y*1.59 or bounds.Y>body.Size.Y*1.88
        then clone:Destroy();return nil end
    local long,short=math.max(bounds.X,bounds.Z),
        math.min(bounds.X,bounds.Z)
    if long<body.Size.Y*.34 or long>body.Size.Y*.49
        or short<body.Size.Y*.26 or short>body.Size.Y*.36 then
        clone:Destroy();return nil
    end
    local yaw=bounds.X<bounds.Z and math.pi*.5 or 0
    -- Place the authenticated model's TRUE lowest sculpted vertex on
    -- the old native mass base; the old structure defines the same
    -- real skyline anchor. No invented platform, floor or collider.
    local target=body.CFrame*CFrame.new(
        0, (bounds.Y-body.Size.Y)*.5, 0)
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
            part.Massless=true
            part.CastShadow=false
            part:SetAttribute("OriginalTowerCoolingSpire3D",true)
            part:SetAttribute("Original3DAssetId",ID)
            pieces[#pieces+1]=part
        end
    end
    if #pieces~=7 then clone:Destroy();return nil end

    -- Own exactly the indexed nonphysical native silhouette, including
    -- its former rooftop motif/stripes, and never mask another tower.
    local native={}
    local originalCount=0
    for _,part in ipairs(mid:GetDescendants()) do
        if part:IsA("BasePart")
            and part:GetAttribute("OriginalTowerCoolingSpireIndex")==index then
            if not part.Anchored or part.CanCollide or part.CanTouch
                or part.CanQuery then
                clone:Destroy();return nil
            end
            native[part]=part.Transparency
            originalCount+=1
        end
    end
    if originalCount<3 then clone:Destroy();return nil end
    local e={
        arena=arena,base=base,mid=mid,body=body,index=index,
        source=approved,model=clone,pieces=pieces,native=native,
        originalSize=body.Size,connections={},disposing=false,
    }
    clone.Name="ApprovedOriginalTowerRunCoolingSpire"..index
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",ID)
    clone.Parent=folder
    local function changed()
        if not alive(e) then visibility(e) end
    end
    e.connections[#e.connections+1]=body.AncestryChanged:Connect(changed)
    e.connections[#e.connections+1]=
        body:GetPropertyChangedSignal("Size"):Connect(changed)
    e.connections[#e.connections+1]=
        base:GetPropertyChangedSignal("Size"):Connect(changed)
    e.connections[#e.connections+1]=
        clone.DescendantRemoving:Connect(function(part)
            if not e.disposing and part:IsA("MeshPart") then
                task.defer(visibility,e)
            end
        end)
    if not visibility(e) then
        dismount(e);return nil
    end
    return e
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,cameraLook,pressure)
    if activeArena~=arena then
        clear()
        activeArena=arena
    end
    local limits=BUDGET[tier] or BUDGET.Low
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    local cap=limits.models
    if tier=="Medium" then
        cap=stress==0 and 2 or (stress==1 and 1 or 0)
    elseif tier=="High" then
        cap=stress==0 and 5 or (stress==1 and 3 or 0)
    end
    if not arena or not cameraReady or cap<=0
        or typeof(cameraPoint)~="Vector3" then
        clear();return
    end
    local base,mid=arenaForTowers(arena)
    local approved=source()
    if not base or not mid or not approved then
        clear();return
    end
    local candidates={}
    for index=1,5 do
        local body=mid:FindFirstChild("TowerCoolingMass"..index)
        if body and nativeTower(body,mid,base,index) then
            local distance=(body.Position-cameraPoint).Magnitude
            local previous=active[body]~=nil
            if distance<=limits.distance+(previous
                and limits.retention or 0) then
                local score=distance-(previous
                    and limits.retention*.65 or 0)
                if typeof(cameraLook)=="Vector3"
                    and cameraLook.Magnitude>.5 and distance>40 then
                    local dir=(body.Position-cameraPoint).Unit
                    score-=math.min(45,distance*.16)
                        *dir:Dot(cameraLook.Unit)
                end
                candidates[#candidates+1]={
                    body=body,index=index,score=score}
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.score==b.score then return a.index<b.index end
        return a.score<b.score
    end)
    local wanted={}
    for i=1,math.min(cap,#candidates) do
        wanted[candidates[i].body]=candidates[i]
    end
    for body,e in pairs(active) do
        if not wanted[body] or e.source~=approved or not alive(e) then
            dismount(e)
            active[body]=nil
        else
            visibility(e)
        end
    end
    for body,choice in pairs(wanted) do
        if not active[body] then
            local e=mount(arena,base,mid,body,choice.index,approved)
            if e then active[body]=e end
        end
    end
end

function Kit.count()
    local n=0
    for _,e in pairs(active) do
        if alive(e) then n+=1 end
    end
    return n
end

return Kit
