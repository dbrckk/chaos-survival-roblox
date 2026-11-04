-- One true 960x960-stud maritime 3D annulus (6152 real source
-- triangles). Sculpted wind waves, shore foam, shallow tide shelf, deep
-- ocean and sun glints, seven distinct original UV/tangent PBR materials.
-- 320x320 gameplay arena and its ShrinkingArena disaster have ZERO sea
-- triangles, ZERO new colliders and ZERO fake water-landing platforms.
--
-- This is mounted by the EXISTING 0.65s scenery-lod camera sampler, not
-- by a second RenderStepped, physics body or water Terrain animation.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Kit={}

local ASSET_ID=111296950975600
local SOURCE_SCALE=.05
local FINAL_SCALE=1/SOURCE_SCALE
local SOURCE_CENTER=Vector3.new(0,.01085,0)
local folder=Instance.new("Folder")
folder.Name="OriginalHarborSculptedSeaLocal"
folder:SetAttribute("CosmeticOnly",true)
folder.Parent=workspace

local activeArena=nil
local entry=nil
local MAX_DISTANCE={
    Low=470,
    Medium=610,
    High=730,
}

local function authenticSource()
    local holder=ReplicatedStorage:FindFirstChild("ApprovedHarborSeaTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified")~=true
        or holder:GetAttribute("Original3DAssetId")~=ASSET_ID then
        return nil
    end
    local source=holder:FindFirstChild("SculptedSea")
    if not source or not source:IsA("Model") or source.Parent~=holder
        or source:GetAttribute("Original3DAssetId")~=ASSET_ID
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("OriginalHarborSea3D")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("Original3DTriangleCount")~=6152
        or source:GetAttribute("SourceDryInnerHalfWidth")~=164.8 then
        return nil
    end
    local n=0
    for _,p in ipairs(source:GetDescendants()) do
        if p:IsA("BasePart") then
            if not p:IsA("MeshPart") or p.CanCollide or p.CanTouch
                or p.CanQuery then return nil end
            n+=1
        elseif p:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if n~=7 then return nil end
    local _,b=source:GetBoundingBox()
    if b.X<47.5 or b.X>48.5
        or b.Z<47.5 or b.Z>48.5
        or b.Y<.03 or b.Y>.35 then return nil end
    return source
end

local function trueHarbor(arena)
    if not arena or not arena:IsA("Folder")
        or tostring(arena:GetAttribute("VariantId"))~="Harbor" then
        return nil
    end
    local generated=workspace:FindFirstChild("GeneratedMap")
    if not generated or arena.Parent~=generated then return nil end
    local base=arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart")
        or not base.Anchored
        or base.Size.X<=0 or base.Size.Z<=0 then
        return nil
    end
    -- This is the one original arena that already supports real survival
    -- physics, NOT a client-created or counterfeit decorative base.
    return base
end

local function alive(e)
    if not e or e.model.Parent~=folder
        or e.arena~=activeArena or e.base.Parent~=e.arena
        or e.source.Parent==nil
        or e.source:GetAttribute("Original3DAssetId")~=ASSET_ID
        or e.source:GetAttribute("OriginalHarborSea3D")~=true
        or e.base.Size.X<=0 or e.base.Size.Z<=0 then return false end
    local n=0
    for _,part in ipairs(e.pieces) do
        if not part or part.Parent~=e.model then return false end
        n+=1
    end
    return n==7
end

local function remove()
    if not entry then return end
    local old=entry
    entry=nil
    for _,connection in ipairs(old.connections) do
        connection:Disconnect()
    end
    old.model:Destroy()
end

local function position(e)
    -- Dry inner radius >=164.8 studs (arena half width is exactly 160);
    -- water therefore never covers a legitimate survivor landing point.
    -- Only 1.0 stud below the original base underside: sea visibly hugs
    -- the quays and floats the approved container freighter.
    local cf=e.base.CFrame
        *CFrame.new(0,-e.base.Size.Y*.5-1.0,0)
        *CFrame.new(SOURCE_CENTER*FINAL_SCALE)
    for _,piece in ipairs(e.pieces) do
        if piece.part.Parent then
            piece.part.CFrame=cf*piece.localFrame
        end
    end
end

local function mount(arena,base,source)
    local clone=source:Clone()
    local ok=pcall(function() clone:ScaleTo(FINAL_SCALE) end)
    if not ok then clone:Destroy();return nil end
    local frame,b=clone:GetBoundingBox()
    if b.X<945 or b.X>975
        or b.Z<945 or b.Z>975
        or b.Y<.5 or b.Y>8 then
        clone:Destroy();return nil
    end
    local pieces={}
    for _,p in ipairs(clone:GetDescendants()) do
        if p:IsA("BasePart") then
            if not p:IsA("MeshPart") then clone:Destroy();return nil end
            p.Anchored=true
            p.CanCollide=false
            p.CanTouch=false
            p.CanQuery=false
            p.Massless=true
            p.CastShadow=false
            p:SetAttribute("OriginalHarborSea3D",true)
            p:SetAttribute("Original3DAssetId",ASSET_ID)
            pieces[#pieces+1]={
                part=p,
                localFrame=frame:ToObjectSpace(p.CFrame),
            }
        end
    end
    if #pieces~=7 then clone:Destroy();return nil end
    local e={arena=arena,base=base,source=source,
        model=clone,pieces=pieces,connections={}}
    clone.Name="ApprovedOriginalStormHarborSea"
    clone:SetAttribute("OriginalHarborSea3D",true)
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",ASSET_ID)
    clone.Parent=folder
    position(e)
    e.connections[#e.connections+1]=
        base:GetPropertyChangedSignal("CFrame"):Connect(function()
            if alive(e) then position(e) end
        end)
    e.connections[#e.connections+1]=
        base:GetPropertyChangedSignal("Size"):Connect(function()
            if alive(e) then position(e) end
        end)
    return e
end

function Kit.sync(arena,cameraPoint,tier,cameraReady)
    if activeArena~=arena then
        remove()
        activeArena=arena
    end
    local maxDistance=MAX_DISTANCE[tier] or MAX_DISTANCE.Low
    local base=trueHarbor(arena)
    if not base or not cameraReady
        or typeof(cameraPoint)~="Vector3"
        or (cameraPoint-base.Position).Magnitude>maxDistance+
            (entry and 80 or 0) then
        remove();return
    end
    local source=authenticSource()
    if not source then remove();return end
    if entry and (entry.source~=source or entry.base~=base
        or not alive(entry)) then remove() end
    if not entry then entry=mount(arena,base,source) end
end

function Kit.count()
    return alive(entry) and 1 or 0
end

return Kit
