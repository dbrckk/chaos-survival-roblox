-- Two authentic creator-approved mast families. Replace ONLY the four
-- native solid GridMarker (Classic) or TowerSpine (Towers) bodies.
-- DO NOT hide/modify GridMarkerGlow or TowerBand, which are animated
-- by arena-identity-motion.client.lua independently every round.
-- Seven true original MeshParts per mounted mast; no new render loop.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
local SPECS={
    Classic={
        id=105555650820011,
        size=Vector3.new(2.16,11.92,2.16),
        native=Vector3.new(2.2,12,2.2),
        prefix="GridMarker",alpha=.06,
    },
    Towers={
        id=86423178125318,
        size=Vector3.new(2.52,19.97562,2.52),
        native=Vector3.new(2.6,20,2.6),
        prefix="TowerSpine",alpha=.04,
    },
}
-- Low can show one creator-authenticated seven-piece mast near the camera,
-- including on touch phones. Its native block remains the immediate
-- fallback under pressure 1/2; animated glow/bands are never masked.
local CAP={Low=1,Medium=2,High=4}
local RANGE={Low=165,Medium=295,High=425}
local RETAIN=25
local bucket=Instance.new("Folder")
bucket.Name="ApprovedOriginalIdentitySpinesLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent=workspace

local activeArena=nil
local activeVariant=nil
local mounted={}

local function release(index)
    local entry=mounted[index]
    if not entry then return end
    mounted[index]=nil
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    local native=entry.native
    if native.Parent==entry.decor and native.Transparency==1 then
        native.Transparency=entry.original
    end
    entry.model:Destroy()
end

-- If the global Android visual-budget owner evicts an optional model,
-- restore its native mast NOW rather than waiting for the next scenery tick.
bucket.ChildRemoved:Connect(function(child)
    if not child:IsA("Model") then return end
    for index,entry in pairs(mounted) do
        if entry.model==child then
            release(index)
            break
        end
    end
end)

local function clear()
    local indices={}
    for index in pairs(mounted) do indices[#indices+1]=index end
    for _,index in ipairs(indices) do release(index) end
end

local function sourceFor(variant)
    local spec=SPECS[variant]
    if not spec then return nil end
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedVariantIdentitySpineTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=holder:FindFirstChild(variant)
    if not source or not source:IsA("Model")
        or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalVariantIdentitySpine3D")~=true
        or source:GetAttribute("Original3DAssetId")~=spec.id then return nil end
    local n=0
    for _,part in ipairs(source:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return nil end
            n+=1
        elseif part:IsA("LuaSourceContainer") then return nil end
    end
    if n~=7 then return nil end
    local _,dims=source:GetBoundingBox()
    if (dims-spec.size).Magnitude>.48 then return nil end
    return source,holder,spec
end

local function signalParts(decor,variant,index)
    local signals={}
    if variant=="Classic" then
        local crown=decor:FindFirstChild("GridMarkerGlow"..index)
        if not crown or not crown:IsA("Part")
            or crown.Parent~=decor
            or (crown.Size-Vector3.new(3.8,.32,3.8)).Magnitude>.12
            or not crown.Anchored or crown.CanCollide
            or crown.CanTouch or crown.CanQuery then return nil end
        signals[1]=crown
    else
        for level=1,3 do
            local band=decor:FindFirstChild(
                "TowerBand"..index.."_"..level)
            if not band or not band:IsA("Part")
                or band.Parent~=decor
                or (band.Size-Vector3.new(4.4,.28,4.4)).Magnitude>.12
                or not band.Anchored or band.CanCollide
                or band.CanTouch or band.CanQuery then return nil end
            signals[#signals+1]=band
        end
    end
    return signals
end

local function genuine(arena,index)
    local variant=arena and arena:GetAttribute("VariantId")
    local spec=SPECS[variant]
    local generated=workspace:FindFirstChild("GeneratedMap")
    local decor=arena and arena:FindFirstChild("Decor")
    local base=arena and arena:FindFirstChild("Base")
    if not spec or not arena or not arena:IsA("Folder")
        or arena.Name~="Arena" or not generated
        or not generated:IsA("Folder") or arena.Parent~=generated
        or not decor or not decor:IsA("Folder") or decor.Parent~=arena
        or not base or not base:IsA("BasePart")
        or base.Parent~=arena or not base.Anchored
        or not base.CanCollide or index<1 or index>4 then return nil end
    -- Shrinking disaster floors retain the original map dimensions as
    -- attributes; decoration locations must not follow the shrinking Size.
    local sizeX=base:GetAttribute("OriginalSizeX")
    local sizeZ=base:GetAttribute("OriginalSizeZ")
    if typeof(sizeX)~="number" or typeof(sizeZ)~="number"
        or sizeX<318 or sizeZ<318 then return nil end
    local halfX=sizeX*.5
    local halfZ=sizeZ*.5
    local x,y,z=0,0,0
    if variant=="Classic" then
        y=6
        if index==1 then x=-halfX+8
        elseif index==2 then x=halfX-8
        elseif index==3 then z=-halfZ+8
        else z=halfZ-8 end
    else
        y=10
        x=(index==1 or index==3) and -halfX+7 or halfX-7
        z=index<=2 and -halfZ+7 or halfZ-7
    end
    local expected=CFrame.new(base.Position+Vector3.new(x,y,z))
    local native=decor:FindFirstChild(spec.prefix..index)
    if not native or not native:IsA("Part")
        or native.Parent~=decor or native.Shape~=Enum.PartType.Block
        or not native.Anchored or native.CanCollide
        or native.CanTouch or native.CanQuery
        or (native.Size-spec.native).Magnitude>.10
        or (native.Position-expected.Position).Magnitude>.17
        or native.CFrame.LookVector:Dot(expected.LookVector)<.999
        or native.CFrame.UpVector:Dot(expected.UpVector)<.999
        or (math.abs(native.Transparency-spec.alpha)>.04
            and native.Transparency~=1) then return nil end
    local signals=signalParts(decor,variant,index)
    if not signals then return nil end
    -- The visual lights are NOT static: their CFrame/Transparency/Color
    -- can legitimately change every identity-motion update.
    return native,signals,base,decor
end

local function valid(entry)
    if entry.arena~=activeArena or entry.model.Parent~=bucket
        or entry.decor.Parent~=entry.arena
        or entry.base.Parent~=entry.arena
        or entry.source.Parent~=entry.holder
        or entry.holder.Parent~=ReplicatedStorage
        or #entry.meshes~=7 then return false end
    local source=sourceFor(entry.variant)
    if source~=entry.source then return false end
    local native,signals,base,decor=genuine(entry.arena,entry.index)
    if native~=entry.native or base~=entry.base
        or decor~=entry.decor or not signals
        or #signals~=#entry.signals then return false end
    for index,part in ipairs(signals) do
        if part~=entry.signals[index] then return false end
    end
    for _,mesh in ipairs(entry.meshes) do
        if not mesh:IsDescendantOf(entry.model) then return false end
    end
    return true
end

local function mount(arena,variant,index,source,holder,spec)
    local native,signals,base,decor=genuine(arena,index)
    if not native then return end
    local model=source:Clone()
    local frame,dimensions=model:GetBoundingBox()
    if (dimensions-spec.size).Magnitude>.48 then
        model:Destroy()
        return
    end
    local meshes={}
    local target=native.CFrame
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then model:Destroy();return end
            part.CFrame=target*frame:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.Massless=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.CastShadow=false
            part:SetAttribute("CosmeticOnly",true)
            part:SetAttribute("Original3DAssetId",spec.id)
            meshes[#meshes+1]=part
        end
    end
    if #meshes~=7 then model:Destroy();return end
    model.Name="Original"..variant.."IdentitySpine"..index
    model:SetAttribute("CosmeticOnly",true)
    model:SetAttribute("Original3DAssetId",spec.id)
    model.Parent=bucket
    local entry={
        arena=arena,variant=variant,index=index,native=native,
        signals=signals,base=base,decor=decor,source=source,
        holder=holder,model=model,meshes=meshes,
        original=native.Transparency,connections={},
    }
    mounted[index]=entry
    if not valid(entry) then release(index);return end
    -- Do not hide before the actual seven imported sculpt MeshParts have
    -- been cloned, positioned, parented and provenance-checked.
    native.Transparency=1
    local function changed()
        if mounted[index]==entry and not valid(entry) then
            release(index)
        end
    end
    for _,object in ipairs({native,base,decor,source}) do
        entry.connections[#entry.connections+1]=
            object.AncestryChanged:Connect(changed)
    end
    for _,signal in ipairs(signals) do
        entry.connections[#entry.connections+1]=
            signal.AncestryChanged:Connect(changed)
    end
    for _,prop in ipairs({"CFrame","Size","CanCollide"}) do
        entry.connections[#entry.connections+1]=
            native:GetPropertyChangedSignal(prop):Connect(changed)
    end
    for _,prop in ipairs({"CFrame","Size"}) do
        entry.connections[#entry.connections+1]=
            base:GetPropertyChangedSignal(prop):Connect(changed)
    end
    entry.connections[#entry.connections+1]=
        source.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then release(index) end
        end)
    entry.connections[#entry.connections+1]=
        model.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then release(index) end
        end)
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,touch,pressure)
    local variant=arena and arena:GetAttribute("VariantId")
    if arena~=activeArena or variant~=activeVariant then
        clear()
        activeArena=arena
        activeVariant=variant
    end
    local budget=CAP[tier] or 0
    if touch then
        -- Previously any Low budget would STILL be set to zero here on
        -- Android: keep one near-camera source on healthy Low touch,
        -- preserving the existing tighter Medium/High touch caps.
        budget=tier=="High" and math.min(budget,2)
            or tier=="Medium" and math.min(budget,1)
            or tier=="Low" and math.min(budget,1) or 0
    end
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if stress==1 then budget=math.floor(budget*.5) end
    if stress>=2 then budget=0 end
    if budget==0 or not cameraReady
        or typeof(cameraPoint)~="Vector3" then clear();return end
    local source,holder,spec=sourceFor(variant)
    if not source then clear();return end
    local ranked={}
    for index=1,4 do
        local native=genuine(arena,index)
        if native then
            local retained=mounted[index]~=nil
            local distance=(native.Position-cameraPoint).Magnitude
            if distance<=(RANGE[tier] or 0)
                +(retained and RETAIN or 0) then
                ranked[#ranked+1]={
                    index=index,
                    score=distance-(retained and RETAIN*.55 or 0),
                }
            end
        end
    end
    table.sort(ranked,function(a,b)
        if a.score~=b.score then return a.score<b.score end
        return a.index<b.index
    end)
    local wanted={}
    for i=1,math.min(budget,#ranked) do
        wanted[ranked[i].index]=true
    end
    local obsolete={}
    for index,entry in pairs(mounted) do
        if not wanted[index] or not valid(entry)
            or entry.source~=source then
            obsolete[#obsolete+1]=index
        else
            -- Only the rigid native core is hidden. Preserve every
            -- live animated signal untouched, including CFrame/alpha.
            entry.native.Transparency=1
        end
    end
    for _,index in ipairs(obsolete) do release(index) end
    for index in pairs(wanted) do
        if not mounted[index] then
            mount(arena,variant,index,source,holder,spec)
        end
    end
end

function Kit.count()
    local n=0
    for _,entry in pairs(mounted) do
        if valid(entry) then n+=1 end
    end
    return n
end

function Kit.replacedNativeCount()
    local n=0
    for _,entry in pairs(mounted) do
        if valid(entry) and entry.native.Transparency==1 then n+=1 end
    end
    return n
end

return Kit
