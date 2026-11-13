-- The four static near-shore cargo barges of Storm Harbor finally use a
-- real sculpted original chined vessel Model rather than rectangular Parts.
-- No fake walkable surfaces. Server gameplay, 4 working port cranes and
-- large 88-stud freighter remain unchanged.
--
-- Exact owned ID is verified by the server's ApprovedHarborBargeTemplates
-- allowlist; only its seven source-authenticated MeshParts are replicated.
-- One existing scenery-lod 0.90s camera sampler owns all mounting.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpatialMidgroundSelectionRules = if script and script.Parent
    and script.Parent.Parent and script.Parent.Parent.Parent
    and ReplicatedStorage:FindFirstChild("Shared")
    and ReplicatedStorage.Shared:FindFirstChild("SpatialMidgroundSelectionRules")
    then require(ReplicatedStorage.Shared.SpatialMidgroundSelectionRules)
    else require("../shared/SpatialMidgroundSelectionRules")

local Kit={}
-- EXACT Model ID returned by Roblox import with Approved moderation.
-- Verify against the server template holder and the Model itself.
local APPROVED_ID=132891280963772
local folder=Instance.new("Folder")
folder.Name="OriginalHarborMidgroundBargesLocal"
folder:SetAttribute("CosmeticOnly",true)
folder.Parent=workspace
local currentArena=nil
local active={}
local BUDGET={
    -- One 3,718-triangle creator-approved barge replaces a near-camera
    -- native cargo block only on a healthy Low device (seven MeshParts).
    Low={models=1,distance=145,retention=18},
    Medium={models=2,distance=270,retention=27},
    High={models=4,distance=380,retention=45},
}
-- Imported generator's verified exact source bounds:
-- min=(-14.2,-2.03,-6.65), max=(14.15,9.15,6.65).
-- This is the real geometric center, not an assumed import Model pivot.
local ORIGINAL_CENTER=Vector3.new(-.025,3.56,0)

local function source()
    local holder=ReplicatedStorage:FindFirstChild("ApprovedHarborBargeTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    if holder:GetAttribute("Original3DAssetId")~=APPROVED_ID
        then return nil end
    local model=holder:FindFirstChild("CoastalFreightBarge")
    if not model or not model:IsA("Model") or model.Parent~=holder
        or model:GetAttribute("Original3DAssetId")~=APPROVED_ID
        or model:GetAttribute("OwnerVerified")~=true
        or model:GetAttribute("CosmeticOnly")~=true
        or model:GetAttribute("OriginalHarborBarge3D")~=true then return nil end
    local n=0
    for _,item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return nil end
            n+=1
        elseif item:IsA("LuaSourceContainer") then return nil end
    end
    if n~=7 then return nil end
    local _,b=model:GetBoundingBox()
    if math.max(b.X,b.Z)<28.05 or math.max(b.X,b.Z)>28.65
        or math.min(b.X,b.Z)<13.0 or math.min(b.X,b.Z)>13.65
        or b.Y<10.93 or b.Y>11.45 then return nil end
    return model,APPROVED_ID
end

-- The sea and berth positions do not shrink with the playable floor.
-- Compare the signed original 320-stud footprint, not live round dimensions.
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

local function authentic(hull,arena,midground,base)
    if not hull or not arena or not midground or not base
        or tostring(arena:GetAttribute("VariantId"))~="Harbor"
        or not hull:IsA("BasePart") or hull.Parent~=midground
        or not hull.Anchored or hull.CanCollide or hull.CanTouch
        or hull.CanQuery or not authenticBase(base,arena) then return false end
    local index=tonumber(hull.Name:match("^HarborFreightBargeHull([1-4])$"))
    if not index or hull:GetAttribute("OriginalHarborMidgroundBargeIndex")
        ~=index then return false end
    if (hull.Size-Vector3.new(28,3.5,13.2)).Magnitude>.2 then return false end
    return true,index
end

local function alive(e)
    if not e or not e.model or e.model.Parent~=folder
        or e.arena~=currentArena or e.hull.Parent~=e.midground
        or e.source.Parent~=e.sourceHolder
        or e.sourceHolder.Parent~=ReplicatedStorage
        or e.source:GetAttribute("Original3DAssetId")~=APPROVED_ID
        or not authentic(e.hull,e.arena,e.midground,e.base)
        or e.hull:GetAttribute("OriginalHarborMidgroundBargeIndex")~=e.index
        or not e.hull.Anchored or e.hull.CanCollide
        or (e.hull.Size-e.size).Magnitude>.15 then return false end
    local n=0
    for _,piece in ipairs(e.pieces) do
        if not piece or not piece:IsDescendantOf(e.model) then return false end
        n+=1
    end
    return n==7
end

local function visibility(e)
    local show=alive(e)
    for _,piece in ipairs(e.pieces) do
        if piece.Parent then
            piece.LocalTransparencyModifier=show and 0 or 1
        end
    end
    for part,original in pairs(e.native) do
        if part.Parent then part.Transparency=show and 1 or original end
    end
    return show
end

local function remove(e)
    e.disposing=true
    for _,conn in ipairs(e.connections) do conn:Disconnect() end
    for part,original in pairs(e.native) do
        if part.Parent then part.Transparency=original end
    end
    e.model:Destroy()
end

local function clear()
    for hull,e in pairs(active) do
        remove(e)
        active[hull]=nil
    end
end

local function mount(arena,base,midground,hull,index,approved,id)
    local clone=approved:Clone()
    local frame,b=clone:GetBoundingBox()
    local long,short=math.max(b.X,b.Z),math.min(b.X,b.Z)
    if long<28.05 or long>28.65 or short<13.0 or short>13.65
        or b.Y<10.93 or b.Y>11.45 then
        clone:Destroy();return nil
    end
    -- Roblox glTF orientation may swap authored X/Z; always match the
    -- actual native 28x13 barge's long axis, with its own berth yaw.
    local yaw=b.X<b.Z and math.pi*.5 or 0
    local target=hull.CFrame*CFrame.new(ORIGINAL_CENTER)
        *CFrame.Angles(0,yaw,0)
    local pieces={}
    for _,part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then clone:Destroy();return nil end
            part.CFrame=target*frame:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.Massless=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.CastShadow=false
            part:SetAttribute("OriginalHarborBarge3D",true)
            part:SetAttribute("Original3DAssetId",id)
            pieces[#pieces+1]=part
        end
    end
    if #pieces~=7 then clone:Destroy();return nil end

    -- All old barge pieces are source-index tagged during the original
    -- midground's tier-specific build, including ArenaDetailKit's ribs.
    -- Never mask an untagged route, neighboring barge or hazard.
    local native={}
    local nativeCount=0
    for _,descendant in ipairs(midground:GetDescendants()) do
        if descendant:IsA("BasePart")
            and descendant:GetAttribute("OriginalHarborMidgroundBargeIndex")
                ==index then
            if descendant.CanCollide or descendant.CanTouch
                or descendant.CanQuery then
                clone:Destroy();return nil
            end
            native[descendant]=descendant.Transparency
            nativeCount+=1
        end
    end
    if nativeCount<4 then clone:Destroy();return nil end
    local entry={arena=arena,base=base,midground=midground,hull=hull,
        index=index,size=hull.Size,source=approved,
        sourceHolder=approved.Parent,model=clone,
        native=native,pieces=pieces,connections={},disposing=false}
    clone.Name="ApprovedOriginal3DHarborBarge"..index
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",id)
    clone.Parent=folder
    local function changed()
        if not alive(entry) then visibility(entry) end
    end
    entry.connections[#entry.connections+1]=
        hull.AncestryChanged:Connect(changed)
    entry.connections[#entry.connections+1]=
        hull:GetPropertyChangedSignal("Size"):Connect(changed)
    entry.connections[#entry.connections+1]=
        base:GetPropertyChangedSignal("Size"):Connect(changed)
    entry.connections[#entry.connections+1]=
        clone.DescendantRemoving:Connect(function(part)
            if not entry.disposing and part:IsA("MeshPart") then
                task.defer(visibility,entry)
            end
        end)
    visibility(entry)
    return entry
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,cameraLook,pressure)
    if currentArena~=arena then
        clear()
        currentArena=arena
    end
    local budget=BUDGET[tier] or BUDGET.Low
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    local cap=budget.models
    if tier=="Low" then
        cap=stress==0 and 1 or 0
    elseif tier=="Medium" then
        cap=stress==0 and 2 or (stress==1 and 1 or 0)
    elseif tier=="High" then
        cap=stress==0 and 4 or (stress==1 and 2 or 0)
    end
    if not arena or not cameraReady or cap==0
        or typeof(cameraPoint)~="Vector3"
        or tostring(arena:GetAttribute("VariantId"))~="Harbor" then
        clear();return
    end
    local base=arena:FindFirstChild("Base")
    local midground=workspace:FindFirstChild("ArenaMidgroundMassLocal")
    if not base or not midground or not midground:IsA("Folder") then
        clear();return
    end
    local approved,id=source()
    if not approved then clear();return end
    local choices={}
    for index=1,4 do
        local hull=midground:FindFirstChild("HarborFreightBargeHull"..index)
        if hull and authentic(hull,arena,midground,base) then
            local distance=(cameraPoint-hull.Position).Magnitude
            local previous=active[hull]~=nil
            if distance<=budget.distance+(previous
                and budget.retention or 0) then
                local score=distance-(previous
                    and budget.retention*.65 or 0)
                if typeof(cameraLook)=="Vector3"
                    and cameraLook.Magnitude>.5 and distance>45 then
                    local direction=(hull.Position-cameraPoint).Unit
                    score-=math.min(38,distance*.17)
                        *direction:Dot(cameraLook.Unit)
                end
                choices[#choices+1]={hull=hull,index=index,score=score}
            end
        end
    end
    table.sort(choices,function(a,b)
        if a.score==b.score then return a.index<b.index end
        return a.score<b.score
    end)
    -- First verified 3D barge stays nearest to the player; when
    -- Medium/high pressure permits a second, distribute it along
    -- the coast instead of using a second nearby native block.
    -- At most 1/2/4 authentic barges for Low/Medium/High (pressure 0);
    -- Low falls back to native immediately at pressure 1 or 2.
    local wanted=SpatialMidgroundSelectionRules.choose(choices,cap)
    for hull,e in pairs(active) do
        if not wanted[hull] or not alive(e) or e.source~=approved then
            remove(e)
            active[hull]=nil
        else
            visibility(e)
        end
    end
    for hull,choice in pairs(wanted) do
        if not active[hull] then
            local added=mount(arena,base,midground,hull,
                choice.index,approved,id)
            if added then active[hull]=added end
        end
    end
end

function Kit.count()
    local total=0
    for _,e in pairs(active) do
        if alive(e) then total+=1 end
    end
    return total
end

return Kit
