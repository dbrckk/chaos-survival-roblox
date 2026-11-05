-- Replace the five world's 2/4 native neon sky-traffic slivers with
-- their EXISTING source-approved industrial drone/lift/transit/satellite/
-- cargo 3D Model. All mesh pieces weld to the native TweenService driver.
-- The driver remains anchored; 3D children are massless, unanchored
-- and noncolliding. No independent animation loop or client asset fetch.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Rules=require(ReplicatedStorage.Shared.CinematicTrafficMeshRules)
local Ring=require(ReplicatedStorage.Shared.CinematicDepthLayoutRules)

local Kit={}
local folder=Instance.new("Folder")
folder.Name="OriginalCinematicSkyTraffic3DLocal"
folder:SetAttribute("CosmeticOnly",true)
folder.Parent=workspace

local currentArena=nil
local mounted={}

local function genuineTemplate(variant)
    local spec=Rules.source(variant)
    if not spec then return nil end
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedAmbientMotionTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=holder:FindFirstChild(variant)
    if not source or not source:IsA("Model")
        or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("ApprovedAmbientMotion3D")~=true
        or source:GetAttribute("Original3DAssetId")~=spec.id then
        return nil
    end
    local parts=0
    for _,child in ipairs(source:GetDescendants()) do
        if child:IsA("BasePart") then
            if not child:IsA("MeshPart") or child.CanCollide
                or child.CanTouch or child.CanQuery then return nil end
            parts+=1
        elseif child:IsA("LuaSourceContainer") then return nil end
    end
    if parts<1 or parts>12 then return nil end
    local _,bounds=source:GetBoundingBox()
    if math.min(bounds.X,bounds.Y,bounds.Z)<.5
        or math.max(bounds.X,bounds.Y,bounds.Z)>8 then return nil end
    return source,holder,spec
end

local function context(arena)
    local world=workspace:FindFirstChild("GeneratedMap")
    if not arena or not arena:IsA("Folder")
        or not world or arena.Parent~=world then return nil end
    local base=arena:FindFirstChild("Base")
    local cinematic=workspace:FindFirstChild("ArenaCinematicDepthLocal")
    local variant=arena:GetAttribute("VariantId")
    if not base or not base:IsA("BasePart")
        or base.Parent~=arena or not base.Anchored
        or base.Size.X<160 or base.Size.Z<160
        or not cinematic or not cinematic:IsA("Folder")
        or cinematic.Parent~=workspace
        or not Rules.source(variant) then return nil end
    return cinematic,variant
end

local function valid(entry)
    if entry.arena~=currentArena
        or entry.arena.Parent~=workspace:FindFirstChild("GeneratedMap")
        or entry.cinematic.Parent~=workspace
        or not Rules.isNative(entry.native,entry.cinematic,
            entry.variant,entry.index)
        or entry.model.Parent~=folder
        or entry.source.Parent~=entry.sourceHolder
        or entry.sourceHolder.Parent~=ReplicatedStorage
        or entry.source:GetAttribute("OwnerVerified")~=true
        or entry.source:GetAttribute("Original3DAssetId")~=entry.id
    then return false end
    if #entry.parts<1 or #entry.parts>12 then return false end
    for _,part in ipairs(entry.parts) do
        if not part or not part:IsA("MeshPart")
            or not part:IsDescendantOf(entry.model)
            or part.Anchored or part.CanCollide
            or part.CanTouch or part.CanQuery then return false end
        local joint=part:FindFirstChild("CinematicTrafficOriginal3DWeld")
        if not joint or not joint:IsA("WeldConstraint")
            or joint.Part0~=entry.native
            or joint.Part1~=part then return false end
    end
    return true
end

local function dispose(entry)
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    if entry.native.Parent==entry.cinematic
        and entry.native.Transparency==1
        and Rules.isNative(entry.native,entry.cinematic,
            entry.variant,entry.index) then
        -- Never clobber later animation/phase transparency choices.
        entry.native.Transparency=entry.nativeOriginal
    end
    if entry.model.Parent then entry.model:Destroy() end
end

local function clear()
    for native,entry in pairs(mounted) do
        dispose(entry)
        mounted[native]=nil
    end
end

local function mount(arena,cinematic,variant,native,index,
        source,sourceHolder,spec)
    if not Rules.isNative(native,cinematic,variant,index) then return nil end
    local copy=source:Clone()
    local sourceFrame,sourceBounds=copy:GetBoundingBox()
    local scale=math.min(1.12,
        8/math.max(sourceBounds.X,sourceBounds.Z),
        6/sourceBounds.Y)
    if scale<.50 or not pcall(function() copy:ScaleTo(scale) end) then
        copy:Destroy()
        return nil
    end
    local frame,bounds=copy:GetBoundingBox()
    if bounds.X>8.1 or bounds.Z>8.1 or bounds.Y>6.1
        or math.min(bounds.X,bounds.Y,bounds.Z)<.25 then
        copy:Destroy()
        return nil
    end
    local parts={}
    for _,piece in ipairs(copy:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then copy:Destroy();return nil end
            piece.Anchored=true
            piece.CanCollide=false
            piece.CanTouch=false
            piece.CanQuery=false
            piece.CastShadow=false
            piece.Massless=true
            piece:SetAttribute("CosmeticOnly",true)
            piece:SetAttribute("Original3DAssetId",spec.id)
            parts[#parts+1]=piece
        end
    end
    if #parts<1 or #parts>12 then copy:Destroy();return nil end

    -- Place the true MeshParts at the current moving driver's world CFrame,
    -- not the package pivot; the owner continues its ORIGINAL CFrame tween.
    copy:PivotTo(native.CFrame*frame:ToObjectSpace(copy:GetPivot()))
    copy.Name="ApprovedCinematicSkyTraffic_"..variant.."_"..index
    copy:SetAttribute("CosmeticOnly",true)
    copy:SetAttribute("OwnerVerified",true)
    copy:SetAttribute("Original3DAssetId",spec.id)
    copy:SetAttribute("CinematicTrafficIndex",index)
    copy.Parent=folder

    -- The original native remains the ONE anchored motion root. Only
    -- WeldConstraints make the imported pieces follow CFrame tweens.
    for _,piece in ipairs(parts) do
        local weld=Instance.new("WeldConstraint")
        weld.Name="CinematicTrafficOriginal3DWeld"
        weld.Part0=native
        weld.Part1=piece
        weld.Parent=piece
        piece.Anchored=false
    end

    local entry={
        arena=arena,cinematic=cinematic,variant=variant,index=index,
        native=native,nativeOriginal=native.Transparency,
        model=copy,source=source,sourceHolder=sourceHolder,
        id=spec.id,parts=parts,connections={},
    }
    local function invalidated()
        -- Streaming/tier/phase rebuild destroys native driver; do not
        -- leave an unpowered imported cargo vessel hanging in the sky.
        if not valid(entry) and mounted[native]==entry then
            mounted[native]=nil
            dispose(entry)
        end
    end
    entry.connections[#entry.connections+1]=
        native.AncestryChanged:Connect(invalidated)
    entry.connections[#entry.connections+1]=
        source.AncestryChanged:Connect(invalidated)
    native.Transparency=1
    if not valid(entry) then
        dispose(entry)
        return nil
    end
    return entry
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,cameraLook,
        pressure,isTouch)
    if currentArena~=arena then
        clear()
        currentArena=arena
    end
    local cinematic,variant=context(arena)
    local limit=Rules.capacity(tier,pressure,isTouch)
    if not cinematic or not cameraReady or limit==0
        or typeof(cameraPoint)~="Vector3" then
        clear()
        return
    end
    local source,holder,spec=genuineTemplate(variant)
    if not source then
        clear()
        return
    end
    local wanted={}
    local candidates={}
    local maxDistance=tier=="Medium" and 245 or 350
    for _,index in ipairs(Ring.indices("Traffic",tier)) do
        local native=cinematic:FindFirstChild("CinemaTraffic"..index)
        if Rules.isNative(native,cinematic,variant,index) then
            local distance=(cameraPoint-native.Position).Magnitude
            local existing=mounted[native]
            if distance<=maxDistance+(existing and 28 or 0) then
                local score=distance-(existing and 18 or 0)
                if typeof(cameraLook)=="Vector3"
                    and cameraLook.Magnitude>.5 and distance>20 then
                    score-=math.min(distance*.18,35)
                        *((native.Position-cameraPoint).Unit)
                            :Dot(cameraLook.Unit)
                end
                candidates[#candidates+1]={
                    native=native,index=index,score=score,
                }
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.score==b.score then return a.index<b.index end
        return a.score<b.score
    end)
    for i=1,math.min(limit,#candidates) do
        wanted[candidates[i].native]=candidates[i].index
    end
    for native,entry in pairs(mounted) do
        if not wanted[native] or not valid(entry)
            or entry.source~=source then
            mounted[native]=nil
            dispose(entry)
        else
            -- Native may be reset by a cosmetic phase or source rebuild.
            if native.Transparency~=1 then native.Transparency=1 end
        end
    end
    for native,index in pairs(wanted) do
        if not mounted[native] then
            mounted[native]=mount(arena,cinematic,variant,native,index,
                source,holder,spec)
        end
    end
end

function Kit.count()
    local count=0
    for _,entry in pairs(mounted) do
        if valid(entry) then count+=1 end
    end
    return count
end

return Kit
