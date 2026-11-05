-- Genuine creator-approved MeshPart replacement of ALL 11 possible
-- cinematic horizon structures per one of five actual arena variants.
-- Each native block/crown/slit is a nonphysical, reversible fallback.
-- NO client AssetService, unapproved MeshId, new collision or render loop.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Rules=require(ReplicatedStorage.Shared.CinematicHorizonMeshRules)
local Ring=require(ReplicatedStorage.Shared.CinematicDepthLayoutRules)
local Spatial=require(ReplicatedStorage.Shared.SpatialMidgroundSelectionRules)

local Kit={}
local DISTRICT={
    Observatory=132020956214241,
    Freight=88725004643299,
    Turbine=84217436280282,
    Aerial=135791763112202,
}
local SPECIAL={
    CoolingSpire={
        holder="ApprovedTowerCoolingSpireTemplates",
        model="RealCoolingSpire",id=95543769387033,
        flag="OriginalTowerCoolingSpire3D",
    },
    HollowStack={
        holder="ApprovedTowersHollowStackTemplates",
        model="HollowCoolingStack",id=97498534364335,
        flag="OriginalTowersHollowStack3D",
    },
    Satellite={
        holder="ApprovedAmbientMotionTemplates",
        model="Orbital",id=127850230318627,
        flag="ApprovedAmbientMotion3D",
    },
    Containment={
        holder="ApprovedServiceEquipmentTemplates",
        model="Orbital",id=127295681925871,
        flag="OriginalService3D",
    },
}
local folder=Instance.new("Folder")
folder.Name="OriginalCinematicHorizonMeshesLocal"
folder:SetAttribute("CosmeticOnly",true)
folder.Parent=workspace
local currentArena=nil
local mounted={}

local function template(key,cache)
    if cache[key]~=nil then
        return cache[key] or nil
    end
    local spec=SPECIAL[key]
    local id=DISTRICT[key] or (spec and spec.id)
    if not id then cache[key]=false;return nil end
    local holder=ReplicatedStorage:FindFirstChild(
        spec and spec.holder or "ApprovedDistrictFacadeTemplates")
    local name=spec and spec.model or key
    local source=holder and holder:FindFirstChild(name)
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true
        or not source or not source:IsA("Model")
        or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("Original3DAssetId")~=id
        or source:GetAttribute(spec and spec.flag or "DistrictFacade3D")~=true
    then cache[key]=false;return nil end
    local n=0
    for _,desc in ipairs(source:GetDescendants()) do
        if desc:IsA("BasePart") then
            if not desc:IsA("MeshPart") or desc.CanCollide
                or desc.CanTouch or desc.CanQuery then
                cache[key]=false;return nil
            end
            n+=1
        elseif desc:IsA("LuaSourceContainer") then
            cache[key]=false;return nil
        end
    end
    if n<1 or n>24 or (spec and n~=7) then
        cache[key]=false;return nil
    end
    local _,bounds=source:GetBoundingBox()
    if bounds.X<.5 or bounds.Y<.5 or bounds.Z<.5
        or math.max(bounds.X,bounds.Y,bounds.Z)>65 then
        cache[key]=false;return nil end
    if not spec and (bounds.X<8 or bounds.X>31
        or bounds.Y<12 or bounds.Y>48
        or bounds.Z<3 or bounds.Z>28) then
        cache[key]=false;return nil
    end
    local entry={source=source,holder=holder,id=id,bounds=bounds,key=key}
    cache[key]=entry
    return entry
end

local function arenaContext(arena)
    local generated=workspace:FindFirstChild("GeneratedMap")
    if not arena or not arena:IsA("Folder")
        or not generated or arena.Parent~=generated then return nil end
    local base=arena:FindFirstChild("Base")
    local cinematic=workspace:FindFirstChild("ArenaCinematicDepthLocal")
    local variant=arena:GetAttribute("VariantId")
    if not base or not base:IsA("BasePart") or not base.Anchored
        or base.Size.X<318 or base.Size.Z<318
        or not cinematic or not cinematic:IsA("Folder")
        or cinematic.Parent~=workspace
        or not Rules.bodySize(variant,1) then return nil end
    return base,cinematic,variant
end

local function genuineBody(body,base,cinematic,variant,index)
    if not body or not body:IsA("Part")
        or body.Parent~=cinematic
        or body.Name~="CinemaHorizonStructure"..index
        or body:GetAttribute("OriginalCinematicHorizonIndex")~=index
        or body:GetAttribute("OriginalCinematicHorizonVariant")~=variant
        or body:GetAttribute("CosmeticOnly")~=true
        or not body.Anchored or body.CanCollide
        or body.CanTouch or body.CanQuery then return false end
    local required=Rules.bodySize(variant,index)
    local offset=Rules.offset(base.Size,variant,index)
    if not required or not offset
        or (body.Size-required).Magnitude>.15
        or (base.CFrame:PointToObjectSpace(body.Position)-offset).Magnitude>.3
    then return false end
    return body.Shape==(variant=="Orbital"
        and Enum.PartType.Cylinder or Enum.PartType.Block)
end

local function nativeGroup(cinema,body,variant,index)
    local parts={}
    local crown=nil
    for _,part in ipairs(cinema:GetChildren()) do
        if part:IsA("BasePart") and part.Parent==cinema
            and part:GetAttribute("OriginalCinematicHorizonIndex")==index
            and part:GetAttribute("OriginalCinematicHorizonVariant")==variant
        then
            if not part.Anchored or part.CanCollide or part.CanTouch
                or part.CanQuery or part:GetAttribute("CosmeticOnly")~=true then
                return nil
            end
            if part.Name=="CinemaHorizonCrown"..index then crown=part end
            parts[part]=part.Transparency
        end
    end
    if not crown or parts[body]==nil then return nil end
    return parts
end

local function fitting(sourceBounds,nativeSize)
    local function scaleFor(x,z)
        return math.min(3.1,
            nativeSize.X*.96/x,
            nativeSize.Z*.96/z,
            nativeSize.Y*1.04/sourceBounds.Y)
    end
    local regular=scaleFor(sourceBounds.X,sourceBounds.Z)
    local rotated=scaleFor(sourceBounds.Z,sourceBounds.X)
    local turn=rotated>regular and math.pi*.5 or 0
    local scale=math.max(regular,rotated)
    if scale<.24 or scale>3.1
        or sourceBounds.Y*scale<math.min(9,nativeSize.Y*.34) then
        return nil
    end
    return scale,turn
end

local function valid(entry)
    if entry.arena~=currentArena or not entry.model
        or entry.model.Parent~=folder
        or entry.arena.Parent~=workspace:FindFirstChild("GeneratedMap")
        or entry.base.Parent~=entry.arena
        or entry.cinematic.Parent~=workspace
        or entry.source.Parent~=entry.sourceHolder
        or entry.sourceHolder.Parent~=ReplicatedStorage
        or not genuineBody(entry.body,entry.base,entry.cinematic,
            entry.variant,entry.index)
        or (entry.body.CFrame.Position-entry.position).Magnitude>.3
    then return false end
    for part in pairs(entry.native) do
        if not part or part.Parent~=entry.cinematic
            or part:GetAttribute("OriginalCinematicHorizonIndex")
                ~=entry.index
            or part:GetAttribute("OriginalCinematicHorizonVariant")
                ~=entry.variant then return false end
    end
    for _,piece in ipairs(entry.pieces) do
        if not piece or not piece:IsDescendantOf(entry.model) then
            return false end
    end
    return #entry.pieces>=1 and #entry.pieces<=24
end

local function reconcile(entry)
    local show=valid(entry)
    for _,piece in ipairs(entry.pieces) do
        if piece.Parent then
            piece.LocalTransparencyModifier=show and 0 or 1
        end
    end
    for native,original in pairs(entry.native) do
        if native.Parent==entry.cinematic
            and native:GetAttribute("OriginalCinematicHorizonIndex")
                ==entry.index
            and native:GetAttribute("OriginalCinematicHorizonVariant")
                ==entry.variant then
            if show then
                native.Transparency=1
            elseif native.Transparency==1 then
                native.Transparency=original
            end
        end
    end
    return show
end

local function unmount(entry)
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    -- Restore the intact original art BEFORE destroying authentic geometry.
    for native,original in pairs(entry.native) do
        if native.Parent==entry.cinematic
            and native.Transparency==1
            and native:GetAttribute("OriginalCinematicHorizonIndex")
                ==entry.index
            and native:GetAttribute("OriginalCinematicHorizonVariant")
                ==entry.variant then
            native.Transparency=original
        end
    end
    entry.model:Destroy()
end

local function clear()
    for body,entry in pairs(mounted) do
        unmount(entry)
        mounted[body]=nil
    end
end

local function mount(arena,base,cinematic,variant,body,index,source)
    if not genuineBody(body,base,cinematic,variant,index) then return nil end
    local native=nativeGroup(cinematic,body,variant,index)
    if not native then return nil end
    local scale,turn=fitting(source.bounds,body.Size)
    if not scale then return nil end
    local clone=source.source:Clone()
    if not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy();return nil
    end
    local sourceFrame,bounds=clone:GetBoundingBox()
    if bounds.Y>body.Size.Y*1.06
        or math.max(bounds.X,bounds.Z)>math.max(body.Size.X,body.Size.Z)*1.08
        or math.min(bounds.X,bounds.Z)<.15 then
        clone:Destroy();return nil
    end
    local angle=Ring.angle("Horizon",index)
    local tangent=angle+math.pi*.5
    local target=CFrame.new(
        body.Position+Vector3.new(0,(bounds.Y-body.Size.Y)*.5,0))
        * base.CFrame.Rotation
        * CFrame.Angles(0,-tangent+turn,0)
    local pieces={}
    for _,part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then clone:Destroy();return nil end
            part.CFrame=target*sourceFrame:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.Massless=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.CastShadow=false
            part:SetAttribute("CosmeticOnly",true)
            part:SetAttribute("Original3DAssetId",source.id)
            pieces[#pieces+1]=part
        end
    end
    if #pieces<1 or #pieces>24 then clone:Destroy();return nil end
    clone.Name="ApprovedCinemaHorizon_"..variant.."_"..index
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("OwnerVerified",true)
    clone:SetAttribute("Original3DAssetId",source.id)
    clone:SetAttribute("CinematicHorizonIndex",index)
    clone.Parent=folder
    local entry={
        arena=arena,base=base,cinematic=cinematic,body=body,
        position=body.Position,index=index,variant=variant,
        source=source.source,sourceHolder=source.holder,
        model=clone,pieces=pieces,native=native,connections={},
    }
    local function changed()
        if not valid(entry) then reconcile(entry) end
    end
    for _,signal in ipairs({
        body.AncestryChanged,
        body:GetPropertyChangedSignal("Size"),
        body:GetPropertyChangedSignal("CFrame"),
        base:GetPropertyChangedSignal("Size"),
        base:GetPropertyChangedSignal("CFrame"),
        source.source.AncestryChanged,
    }) do
        entry.connections[#entry.connections+1]=signal:Connect(changed)
    end
    if not reconcile(entry) then unmount(entry);return nil end
    return entry
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,cameraLook,pressure,isTouch)
    if arena~=currentArena then
        clear()
        currentArena=arena
    end
    local cap=Rules.capacity(tier,pressure,isTouch)
    local base,cinematic,variant=arenaContext(arena)
    if not base or not cameraReady or cap==0
        or typeof(cameraPoint)~="Vector3" then
        clear()
        return
    end
    local perTier=Ring.indices("Horizon",tier)
    local sourceCache={}
    local candidates={}
    local maxDistance=tier=="Low" and 215
        or (tier=="Medium" and 305 or 400)
    for _,index in ipairs(perTier) do
        local body=cinematic:FindFirstChild("CinemaHorizonStructure"..index)
        if genuineBody(body,base,cinematic,variant,index) then
            local distance=(body.Position-cameraPoint).Magnitude
            local resident=mounted[body]~=nil
            local retention=resident and 28 or 0
            if distance<=maxDistance+retention then
                local chosen=nil
                for _,key in ipairs(Rules.sources(variant,index)) do
                    local possible=template(key,sourceCache)
                    if possible and fitting(possible.bounds,body.Size) then
                        chosen=possible
                        break
                    end
                end
                if chosen then
                    local score=distance-(resident and 16 or 0)
                    if typeof(cameraLook)=="Vector3"
                        and cameraLook.Magnitude>.5 and distance>35 then
                        local look=(body.Position-cameraPoint).Unit
                        score-=math.min(42,distance*.16)
                            *look:Dot(cameraLook.Unit)
                    end
                    candidates[#candidates+1]={
                        body=body,index=index,score=score,source=chosen,
                    }
                end
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.score==b.score then return a.index<b.index end
        return a.score<b.score
    end)
    local wanted=Spatial.choose(candidates,cap)
    for body,entry in pairs(mounted) do
        local want=wanted[body]
        if not want or want.source.source~=entry.source
            or not valid(entry) then
            unmount(entry)
            mounted[body]=nil
        else
            reconcile(entry)
        end
    end
    for body,want in pairs(wanted) do
        if not mounted[body] then
            mounted[body]=mount(arena,base,cinematic,variant,body,
                want.index,want.source)
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
        if valid(entry) then
            for part in pairs(entry.native) do
                if part.Parent==entry.cinematic
                    and part.Transparency==1 then
                    n+=1
                end
            end
        end
    end
    return n
end

return Kit
