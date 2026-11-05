-- Genuine 3D orbital halo lattice. Reuses the existing moderated-approved
-- PremiumSkybridgeModule as four OPEN UV/tangent MeshPart modules per
-- existing nonphysical CinemaOrbitalHalo segment; NEVER create new
-- gameplay bridges or make the distant orbital skyline walkable.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Rules=require(ReplicatedStorage.Shared.CinematicOrbitalHaloMeshRules)
local Ring=require(ReplicatedStorage.Shared.CinematicDepthLayoutRules)
local Spatial=require(ReplicatedStorage.Shared.SpatialMidgroundSelectionRules)

local Kit={}
local folder=Instance.new("Folder")
folder.Name=Rules.LOCAL_FOLDER
folder:SetAttribute("CosmeticOnly",true)
folder.Parent=workspace
local currentArena=nil
local mounted={}

local function originalSource()
    local holder=ReplicatedStorage:FindFirstChild(Rules.SOURCE_FOLDER)
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local model=holder:FindFirstChild(Rules.SOURCE_NAME)
    if not model or not model:IsA("Model") or model.Parent~=holder
        or model:GetAttribute("OwnerVerified")~=true
        or model:GetAttribute("CosmeticOnly")~=true
        or model:GetAttribute("PremiumRoute3D")~=true
        or model:GetAttribute("Original3DAssetId")~=Rules.ASSET_ID
    then return nil end
    local count=0
    for _,item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return nil end
            count+=1
        elseif item:IsA("LuaSourceContainer") then return nil end
    end
    if count<1 or count>12 then return nil end
    local _,size=model:GetBoundingBox()
    local scale,yaw=Rules.fit(size)
    if not scale then return nil end
    return model,holder,scale,yaw,count
end

local function context(arena)
    local map=workspace:FindFirstChild("GeneratedMap")
    if not arena or not arena:IsA("Folder")
        or not map or arena.Parent~=map
        or arena:GetAttribute("VariantId")~="Orbital" then return nil end
    local base=arena:FindFirstChild("Base")
    local cinematic=workspace:FindFirstChild("ArenaCinematicDepthLocal")
    if not base or not base:IsA("BasePart")
        or base.Parent~=arena or not base.Anchored
        or base.Size.X<318 or base.Size.Z<318
        or not cinematic or not cinematic:IsA("Folder")
        or cinematic.Parent~=workspace then return nil end
    return base,cinematic
end

local function valid(entry)
    if not entry or entry.disposing
        or entry.arena~=currentArena
        or entry.arena.Parent~=workspace:FindFirstChild("GeneratedMap")
        or entry.base.Parent~=entry.arena
        or entry.cinematic.Parent~=workspace
        or not Rules.isNative(entry.native,entry.cinematic,
            entry.base,entry.index)
        or entry.source.Parent~=entry.holder
        or entry.holder.Parent~=ReplicatedStorage
        or entry.holder:GetAttribute("OwnerVerified")~=true
        or entry.source:GetAttribute("OwnerVerified")~=true
        or entry.source:GetAttribute("Original3DAssetId")
            ~=Rules.ASSET_ID
        or #entry.models~=Rules.MODULES_PER_SITE then return false end
    local parts=0
    for _,model in ipairs(entry.models) do
        if model.Parent~=folder
            or model:GetAttribute("Original3DAssetId")~=Rules.ASSET_ID
            or model:GetAttribute("OriginalCinematicHaloIndex")
                ~=entry.index then return false end
        local meshes=entry.pieces[model]
        if not meshes or #meshes<1 or #meshes>12 then return false end
        for _,piece in ipairs(meshes) do
            if not piece or not piece:IsA("MeshPart")
                or not piece:IsDescendantOf(model)
                or not piece.Anchored or piece.CanCollide
                or piece.CanTouch or piece.CanQuery then return false end
            parts+=1
        end
    end
    return parts>0 and parts<=Rules.MODULES_PER_SITE*12
end

local function restore(entry)
    if entry.disposing then return end
    entry.disposing=true
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    -- The current valid native is always restored BEFORE removing the
    -- approved geometry; absent or rebuilt source parts are not touched.
    if entry.native.Parent==entry.cinematic
        and entry.native.Transparency==1
        and Rules.isNative(entry.native,entry.cinematic,
            entry.base,entry.index) then
        entry.native.Transparency=entry.originalTransparency
    end
    for _,model in ipairs(entry.models) do
        if model.Parent then model:Destroy() end
    end
end

local function clear()
    for native,entry in pairs(mounted) do
        mounted[native]=nil
        restore(entry)
    end
end

-- A source model is cloned into FOUR individually bounded lattice pieces
-- along the genuine 34-stud tangent. These are true, textured MeshParts,
-- not stretched single Parts and not replicated remote work.
local function mount(arena,base,cinematic,native,index,source,
        holder,scale,yaw,count)
    if not Rules.isNative(native,cinematic,base,index) then return nil end
    local models,pieces={},{}
    local function abandon()
        for _,model in ipairs(models) do model:Destroy() end
        return nil
    end
    for moduleIndex=1,Rules.MODULES_PER_SITE do
        local copy=source:Clone()
        models[#models+1]=copy
        if not pcall(function() copy:ScaleTo(scale) end) then
            return abandon()
        end
        local sourceFrame,bounds=copy:GetBoundingBox()
        local length=math.max(bounds.X,bounds.Z)
        local short=math.min(bounds.X,bounds.Z)
        if length<4.7 or length>8.38
            or short>3.48 or bounds.Y>1.48 then
            return abandon()
        end
        local shift=Rules.moduleOffset(moduleIndex)
        if not shift then return abandon() end
        local target=native.CFrame*CFrame.new(shift,0,0)
            *CFrame.Angles(0,yaw,0)
        local segment={}
        for _,piece in ipairs(copy:GetDescendants()) do
            if piece:IsA("BasePart") then
                if not piece:IsA("MeshPart") then return abandon() end
                piece.CFrame=target*sourceFrame:ToObjectSpace(piece.CFrame)
                piece.Anchored=true
                piece.Massless=true
                piece.CanCollide=false
                piece.CanTouch=false
                piece.CanQuery=false
                piece.CastShadow=false
                piece:SetAttribute("CosmeticOnly",true)
                piece:SetAttribute("Original3DAssetId",Rules.ASSET_ID)
                segment[#segment+1]=piece
            end
        end
        if #segment~=count then return abandon() end
        copy.Name="OriginalOrbitalHaloTruss_"..index
            .."_"..moduleIndex
        copy:SetAttribute("CosmeticOnly",true)
        copy:SetAttribute("OwnerVerified",true)
        copy:SetAttribute("Original3DAssetId",Rules.ASSET_ID)
        copy:SetAttribute("OriginalCinematicHaloIndex",index)
        copy:SetAttribute("OriginalCinematicHaloModule",moduleIndex)
        pieces[copy]=segment
    end
    -- One atomic visual swap: no missing native segment while source is
    -- still staged or partially streamed. Only one arena exists.
    for _,model in ipairs(models) do model.Parent=folder end
    local entry={
        arena=arena,base=base,cinematic=cinematic,native=native,
        index=index,source=source,holder=holder,models=models,
        pieces=pieces,originalTransparency=native.Transparency,
        connections={},
    }
    local function invalidated()
        if mounted[native]==entry and not valid(entry) then
            mounted[native]=nil
            restore(entry)
        end
    end
    entry.connections[#entry.connections+1]=
        native.AncestryChanged:Connect(invalidated)
    entry.connections[#entry.connections+1]=
        source.AncestryChanged:Connect(invalidated)
    native.Transparency=1
    if not valid(entry) then
        restore(entry)
        return nil
    end
    return entry
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,cameraLook,
        pressure,isTouch)
    if arena~=currentArena then
        clear()
        currentArena=arena
    end
    local base,cinematic=context(arena)
    local cap=Rules.capacity(tier,pressure,isTouch)
    if not base or not cameraReady or cap==0
        or typeof(cameraPoint)~="Vector3" then
        clear()
        return
    end
    local source,holder,scale,yaw,count=originalSource()
    if not source then
        clear()
        return
    end
    local candidates={}
    local range=tier=="Medium" and 325 or 440
    for _,index in ipairs(Ring.indices("OrbitalHalo",tier)) do
        local native=cinematic:FindFirstChild("CinemaOrbitalHalo"..index)
        if Rules.isNative(native,cinematic,base,index) then
            local distance=(native.Position-cameraPoint).Magnitude
            local existing=mounted[native]~=nil
            if distance<=range+(existing and 24 or 0) then
                local score=distance-(existing and 12 or 0)
                if typeof(cameraLook)=="Vector3"
                    and cameraLook.Magnitude>.5 and distance>30 then
                    score-=math.min(distance*.13,30)
                        *((native.Position-cameraPoint).Unit)
                        :Dot(cameraLook.Unit)
                end
                candidates[#candidates+1]={
                    body=native,index=index,score=score,
                }
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.score==b.score then return a.index<b.index end
        return a.score<b.score
    end)
    local wanted=Spatial.choose(candidates,cap)
    for native,entry in pairs(mounted) do
        if not wanted[native] or not valid(entry)
            or entry.source~=source then
            mounted[native]=nil
            restore(entry)
        elseif native.Transparency~=1 then
            native.Transparency=1
        end
    end
    for native,want in pairs(wanted) do
        if not mounted[native] then
            mounted[native]=mount(arena,base,cinematic,native,
                want.index,source,holder,scale,yaw,count)
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
