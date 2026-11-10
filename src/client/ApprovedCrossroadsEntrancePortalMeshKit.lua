-- Genuine original Crossroads interior entrance portals: four source
-- groups of 3 cosmetic Parts (gate and two posts), each replaced by
-- seven verified creator-owned MeshParts before any native is hidden.
-- Retains collision-free passage, native restoration, Android LOD budget.
-- Does NOT add a RenderStepped, heartbeat, server request or light.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
local ID=127067628128103
local BOUNDS=Vector3.new(19.2,10.59,1.755)
local LIMIT={Low=0,Medium=2,High=4}
local DISTANCE={Low=0,Medium=340,High=470}
local RETAIN=28
local bucket=Instance.new("Folder")
bucket.Name="ApprovedCrossroadsEntrancePortalsLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent=workspace

local activeArena=nil
local mounted={}

local function release(index)
    local entry=mounted[index]
    if not entry then return end
    mounted[index]=nil
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    for native,alpha in pairs(entry.nativeAlpha) do
        if native.Parent==entry.decor and native.Transparency==1
            and native.Anchored and not native.CanCollide
            and not native.CanTouch and not native.CanQuery then
            native.Transparency=alpha
        end
    end
    -- This rail is actively animated by arena-identity-motion.
    -- Restore its previous local visibility/LOD owner, never its live
    -- Transparency or CFrame (the animation owns those properties).
    local rail=entry.rail
    if rail.Parent==entry.decor then
        rail.LocalTransparencyModifier=entry.railOriginalModifier
        rail:SetAttribute("SceneryLodHidden",entry.railOriginalHidden)
    end
    entry.model:Destroy()
end

local function clear()
    local ids={}
    for index in pairs(mounted) do ids[#ids+1]=index end
    for _,index in ipairs(ids) do release(index) end
end

local function sourceFor()
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedCrossroadsEntrancePortalTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then
        return nil
    end
    local source=holder:FindFirstChild("EntrancePortal")
    if not source or not source:IsA("Model")
        or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalCrossroadsEntrancePortal3D")~=true
        or source:GetAttribute("Original3DAssetId")~=ID then
        return nil
    end
    local n=0
    for _,part in ipairs(source:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then
                return nil
            end
            n+=1
        elseif part:IsA("LuaSourceContainer") then return nil end
    end
    if n~=7 then return nil end
    local _,size=source:GetBoundingBox()
    if math.abs(size.Y-BOUNDS.Y)>.32
        or math.abs(math.max(size.X,size.Z)-BOUNDS.X)>.38
        or math.abs(math.min(size.X,size.Z)-BOUNDS.Z)>.33 then
        return nil
    end
    return source,holder
end

local function exactPart(part,decor,name,size,frame,alpha,animated)
    return part and part:IsA("Part") and part.Parent==decor
        and part.Name==name and part.Shape==Enum.PartType.Block
        and part.Anchored and not part.CanCollide
        and not part.CanTouch and not part.CanQuery
        and (part.Size-size).Magnitude<=.10
        and (part.Position-frame.Position).Magnitude<=.17
        and part.CFrame.LookVector:Dot(frame.LookVector)>=.999
        and part.CFrame.UpVector:Dot(frame.UpVector)>=.999
        and ((animated and (
            (part.Transparency>=.04 and part.Transparency<=.66)
            or part.Transparency==1))
            or (not animated and (
                math.abs(part.Transparency-alpha)<=.035
                or part.Transparency==1)))
end

local function genuine(arena,index)
    local generated=workspace:FindFirstChild("GeneratedMap")
    local decor=arena and arena:FindFirstChild("Decor")
    local base=arena and arena:FindFirstChild("Base")
    if not arena or not arena:IsA("Folder") or arena.Name~="Arena"
        or not generated or not generated:IsA("Folder")
        or arena.Parent~=generated
        or arena:GetAttribute("VariantId")~="Crossroads"
        or not decor or not decor:IsA("Folder")
        or decor.Parent~=arena
        or not base or not base:IsA("BasePart")
        or base.Parent~=arena or not base.Anchored
        or not base.CanCollide or index<1 or index>4 then
        return nil
    end
    -- Use the immutable source dimensions: the playfield can shrink
    -- during a real disaster without moving its decorative entry rails.
    local originalX=base:GetAttribute("OriginalSizeX")
    local originalZ=base:GetAttribute("OriginalSizeZ")
    if typeof(originalX)~="number" or typeof(originalZ)~="number"
        or originalX<318 or originalZ<318 then return nil end
    local x,z=0,0
    if index==1 then z=-originalZ*.5+7
    elseif index==2 then z=originalZ*.5-7
    elseif index==3 then x=-originalX*.5+7
    else x=originalX*.5-7 end
    local alongX=index<=2
    local railSize=alongX and Vector3.new(18,1.2,1.4)
        or Vector3.new(1.4,1.2,18)
    local lateral=alongX and Vector3.new(8.5,-5,0)
        or Vector3.new(0,-5,8.5)
    local frame=CFrame.new(base.Position+Vector3.new(x,6,z))
    local rail=decor:FindFirstChild("CrossroadGate"..index)
    if not exactPart(rail,decor,"CrossroadGate"..index,
        railSize,frame,.18,true) then return nil end
    local posts={}
    for _,sign in ipairs({-1,1}) do
        local name="CrossroadPost"..index.."_"..tostring(sign)
        local part=decor:FindFirstChild(name)
        local post=CFrame.new(frame.Position+lateral*sign)
        if not exactPart(part,decor,name,
            Vector3.new(1.2,10,1.2),post,.05) then
            return nil
        end
        posts[#posts+1]=part
    end
    -- Each source gate/column is a noncolliding decor part; its MeshPart
    -- replacement may be more detailed but never blocks player passage.
    return rail,posts,base,decor
end

local function valid(entry)
    if entry.arena~=activeArena
        or entry.model.Parent~=bucket
        or entry.source.Parent~=entry.holder
        or entry.holder.Parent~=ReplicatedStorage
        or entry.decor.Parent~=entry.arena
        or entry.base.Parent~=entry.arena
        or #entry.parts~=7 then return false end
    local source=sourceFor()
    if source~=entry.source then return false end
    local rail,posts,base,decor=genuine(entry.arena,entry.index)
    if rail~=entry.rail or base~=entry.base or decor~=entry.decor
        or not posts then return false end
    for i,post in ipairs(posts) do
        if post~=entry.posts[i] then return false end
    end
    for _,part in ipairs(entry.parts) do
        if not part:IsDescendantOf(entry.model) then return false end
    end
    return true
end

local function mount(arena,index,source,holder)
    local rail,posts,base,decor=genuine(arena,index)
    if not rail then return end
    -- Do not steal a native already hidden by a different scenery LOD.
    if rail:GetAttribute("SceneryLodHidden")==true then return end
    local model=source:Clone()
    local frame,size=model:GetBoundingBox()
    local sourceAlongX=size.X>=size.Z
    local nativeAlongX=index<=2
    local yaw=sourceAlongX==nativeAlongX and 0 or math.pi*.5
    local long=math.max(size.X,size.Z)
    local slim=math.min(size.X,size.Z)
    if math.abs(long-BOUNDS.X)>.38
        or math.abs(slim-BOUNDS.Z)>.33
        or math.abs(size.Y-BOUNDS.Y)>.32 then
        model:Destroy()
        return
    end
    -- Original gate rail is at Y+6 relative to floor center. The
    -- combined rail+columns envelope is centered 4.7 studs lower.
    local target=rail.CFrame*CFrame.new(0,-4.7,0)
        *CFrame.Angles(0,yaw,0)
    local meshParts={}
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                model:Destroy()
                return
            end
            part.CFrame=target*frame:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.Massless=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.CastShadow=false
            part:SetAttribute("CosmeticOnly",true)
            part:SetAttribute("Original3DAssetId",ID)
            meshParts[#meshParts+1]=part
        end
    end
    if #meshParts~=7 then model:Destroy();return end
    -- Posts are static, so normal Transparency is safe. The rail is
    -- animated and must instead use client-only LocalTransparencyModifier.
    local natives={}
    for _,post in ipairs(posts) do natives[post]=post.Transparency end
    model.Name="OriginalCrossroadsSculptedPortal"..index
    model:SetAttribute("CosmeticOnly",true)
    model:SetAttribute("Original3DAssetId",ID)
    model.Parent=bucket
    local entry={
        arena=arena,index=index,rail=rail,posts=posts,base=base,
        decor=decor,source=source,holder=holder,model=model,
        parts=meshParts,nativeAlpha=natives,connections={},
        railOriginalModifier=rail.LocalTransparencyModifier,
        railOriginalHidden=rail:GetAttribute("SceneryLodHidden"),
    }
    mounted[index]=entry
    if not valid(entry) then release(index);return end
    for native in pairs(natives) do native.Transparency=1 end
    rail:SetAttribute("SceneryLodHidden",true)
    rail.LocalTransparencyModifier=1
    local function changed()
        if mounted[index]==entry and not valid(entry) then release(index) end
    end
    for _,object in ipairs({rail,posts[1],posts[2],base,decor,source}) do
        entry.connections[#entry.connections+1]=
            object.AncestryChanged:Connect(changed)
    end
    for native in pairs(natives) do
        for _,property in ipairs({"CFrame","Size","CanCollide"}) do
            entry.connections[#entry.connections+1]=
                native:GetPropertyChangedSignal(property):Connect(changed)
        end
    end
    for _,property in ipairs({"CFrame","Size"}) do
        entry.connections[#entry.connections+1]=
            base:GetPropertyChangedSignal(property):Connect(changed)
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
    if arena~=activeArena then clear();activeArena=arena end
    local cap=LIMIT[tier] or 0
    if touch then
        cap=tier=="High" and math.min(cap,2)
            or tier=="Medium" and math.min(cap,1) or 0
    end
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if stress==1 then cap=math.floor(cap*.5) end
    if stress>=2 then cap=0 end
    if cap==0 or not cameraReady
        or typeof(cameraPoint)~="Vector3" then clear();return end
    local source,holder=sourceFor()
    if not source then clear();return end
    local sorted={}
    for index=1,4 do
        local rail=genuine(arena,index)
        if rail then
            local retained=mounted[index]~=nil
            local distance=(cameraPoint-rail.Position).Magnitude
            if distance<=(DISTANCE[tier] or 0)
                +(retained and RETAIN or 0) then
                sorted[#sorted+1]={
                    index=index,score=distance-(retained and RETAIN*.5 or 0),
                }
            end
        end
    end
    table.sort(sorted,function(a,b)
        if a.score~=b.score then return a.score<b.score end
        return a.index<b.index
    end)
    local wanted={}
    for i=1,math.min(cap,#sorted) do
        wanted[sorted[i].index]=true
    end
    local old={}
    for index,entry in pairs(mounted) do
        if not wanted[index] or not valid(entry)
            or entry.source~=source then
            old[#old+1]=index
        else
            for native in pairs(entry.nativeAlpha) do
                native.Transparency=1
            end
            -- Animation updates BasePart.Transparency every 0.09 seconds
            -- while active. LTM and SceneryLodHidden safely own visibility.
            entry.rail:SetAttribute("SceneryLodHidden",true)
            entry.rail.LocalTransparencyModifier=1
        end
    end
    for _,index in ipairs(old) do release(index) end
    for index in pairs(wanted) do
        if not mounted[index] then mount(arena,index,source,holder) end
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
        if valid(entry) then
            for part in pairs(entry.nativeAlpha) do
                if part.Parent==entry.decor and part.Transparency==1 then
                    n+=1
                end
            end
            if entry.rail.Parent==entry.decor
                and entry.rail.LocalTransparencyModifier>=.99
                and entry.rail:GetAttribute("SceneryLodHidden")==true then
                n+=1
            end
        end
    end
    return n
end

return Kit
