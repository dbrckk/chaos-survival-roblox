-- Original seven-material 3D Storm Harbor hero station. Only authentic
-- owner-approved ID #73237902371094 is accepted, NEVER marketplace props.
-- Three mesh pieces independently follow existing arena-hero-motion's
-- RadarArm, HoistCable and HoistWeight via native CFrame change signals.
-- Nonphysical original Parts are hidden locally only once a COMPLETE
-- original Model is mounted. Native storm lens remains visible/animated.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
local ID=73237902371094
local SOURCE_SCALE=.74
local SOURCE_SHIFT_Y=20
local SOURCE_CENTER=Vector3.new(5.05801,-.60865,0)
local BUDGET={
    Low={count=0,distance=0,retain=0},
    Medium={count=1,distance=215,retain=26},
    High={count=1,distance=345,retain=42},
}
local localFolder=Instance.new("Folder")
localFolder.Name="OriginalHarborHeroStationLocal"
localFolder:SetAttribute("CosmeticOnly",true)
localFolder.Parent=workspace
local activeArena=nil
local entry=nil

local EXPECTED_NAMES={
    HarborHeroPierFoundation=true,
    HarborHeroPortLeg=true,
    HarborHeroStarboardLeg=true,
    HarborHeroGantryCrosshead=true,
    HarborHeroSignalCabin=true,
    HarborHeroRadarMast=true,
    HarborHeroRadarArm=true,
    HarborHeroCabinRoof=true,
    HarborHeroHoistPost=true,
    HarborHeroHoistBoom=true,
    HarborHeroHoistCable=true,
    HarborHeroHoistWeight=true,
    HarborHeroPortKnee=true,
    HarborHeroStarboardKnee=true,
    HarborHeroSignalRailPort=true,
    HarborHeroSignalRailStarboard=true,
    HarborHeroHoistTrussPort=true,
    HarborHeroHoistTrussStarboard=true,
    HarborHeroCabinPanorama=true,
}

local function allowedModel()
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedHarborHeroStationTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=holder:FindFirstChild("SignalStation")
    if not source or not source:IsA("Model") or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("OriginalHarborHeroStation3D")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("Original3DAssetId")~=ID then return nil end
    local roles={Static=0,Radar=0,Cable=0,Weight=0}
    for _,piece in ipairs(source:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then return nil end
            local role=piece:GetAttribute("OriginalHarborHeroMotionRole")
            if roles[role]==nil then return nil end
            roles[role]+=1
        elseif piece:IsA("LuaSourceContainer") then return nil end
    end
    if roles.Static~=4 or roles.Radar~=1
        or roles.Cable~=1 or roles.Weight~=1 then return nil end
    local _,b=source:GetBoundingBox()
    if math.min(b.X,b.Z)<6.8 or math.min(b.X,b.Z)>7.7
        or math.max(b.X,b.Z)<27.8 or math.max(b.X,b.Z)>29.1
        or b.Y<27.5 or b.Y>28.7 then return nil end
    return source
end

local function nativeScene(arena)
    if not arena or tostring(arena:GetAttribute("VariantId"))~="Harbor"
        then return nil end
    local generated=workspace:FindFirstChild("GeneratedMap")
    if not generated or arena.Parent~=generated then return nil end
    local base=arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") or base.Size.X<318
        or base.Size.Z<318 then return nil end
    local hero=workspace:FindFirstChild("ArenaHeroSceneryLocal")
    if not hero or not hero:IsA("Folder") then return nil end
    local refs={
        Radar=hero:FindFirstChild("HarborHeroRadarArm"),
        Cable=hero:FindFirstChild("HarborHeroHoistCable"),
        Weight=hero:FindFirstChild("HarborHeroHoistWeight"),
    }
    local girder=hero:FindFirstChild("HarborHeroGantryCrosshead")
    local lens=hero:FindFirstChild("HarborHeroStormLens")
    local foundation=hero:FindFirstChild("HarborHeroPierFoundation")
    if not girder or not lens or not foundation
        or not girder:IsA("BasePart")
        or not lens:IsA("BasePart")
        or not foundation:IsA("BasePart")
        or girder.CanCollide or lens.CanCollide
        or math.abs(girder.Size.X-19.5)>.3
        or math.abs(foundation.Size.X-23)>.3 then return nil end
    for _,part in pairs(refs) do
        if not part or not part:IsA("BasePart")
            or not part.Anchored or part.CanCollide or part.CanTouch
            or part.CanQuery then return nil end
    end
    return {base=base,hero=hero,refs=refs,girder=girder,lens=lens}
end

local function alive(e)
    if not e or e.model.Parent~=localFolder or e.arena~=activeArena
        or not e.source.Parent or e.source:GetAttribute(
            "OriginalHarborHeroStation3D")~=true
        or e.source:GetAttribute("Original3DAssetId")~=ID
        or e.base.Size.X<318 or e.base.Size.Z<318
        or e.girder.Parent~=e.hero or e.lens.Parent~=e.hero then
        return false
    end
    for role,part in pairs(e.refs) do
        if part.Parent~=e.hero or part~=e.motionRefs[role]
            then return false end
    end
    local n=0
    for _,p in ipairs(e.pieces) do
        if not p.part or p.part.Parent~=e.model then return false end
        n+=1
    end
    return n==7
end

local function visibility(e)
    local show=alive(e)
    for _,p in ipairs(e.pieces) do
        if p.part.Parent then
            p.part.LocalTransparencyModifier=show and 0 or 1
        end
    end
    -- HeroMotion owns the original radar/Cable/Weight CFrame and the
    -- dedicated lens transparency. Never modify the native storm lens.
    for part,original in pairs(e.original) do
        if part.Parent then
            part.Transparency=show and 1 or original
        end
    end
    return show
end

local function syncMotion(e)
    if not alive(e) then visibility(e);return end
    local relative={}
    for role,part in pairs(e.motionRefs) do
        relative[role]=part.CFrame*e.initial[role]:Inverse()
    end
    for _,p in ipairs(e.pieces) do
        local transform=relative[p.role]
        if transform and p.part.Parent then
            p.part.CFrame=transform*p.rest
        end
    end
end

local function dismount()
    if not entry then return end
    local old=entry
    entry=nil
    old.disposing=true
    for _,conn in ipairs(old.connections) do conn:Disconnect() end
    for part,original in pairs(old.original) do
        if part.Parent then part.Transparency=original end
    end
    old.model:Destroy()
end

local function mount(arena,scene,source)
    local clone=source:Clone()
    local before,b=clone:GetBoundingBox()
    if math.min(b.X,b.Z)<6.8 or math.max(b.X,b.Z)>29.1
        or b.Y<27.5 or b.Y>28.7 then clone:Destroy();return nil end
    if not pcall(function() clone:ScaleTo(1/SOURCE_SCALE) end) then
        clone:Destroy();return nil
    end
    local modelFrame,big=clone:GetBoundingBox()
    if math.min(big.X,big.Z)<9.0 or math.min(big.X,big.Z)>10.8
        or math.max(big.X,big.Z)<37.5 or math.max(big.X,big.Z)>39.6
        or big.Y<36.8 or big.Y>39.3 then clone:Destroy();return nil end
    local base=scene.base
    local nativeFrame=base.CFrame
        *CFrame.new(0,0,base.Size.Z*.5+18)
        *CFrame.Angles(0,math.pi,0)
    local rotation=big.X<big.Z and math.pi*.5 or 0
    -- The source model's TRUE geometric center, not its arbitrary
    -- Roblox import pivot, preserves alignment to the exact native
    -- hero station frame and the existing 3 individually moving Parts.
    local target=nativeFrame
        *CFrame.new(SOURCE_CENTER.X/SOURCE_SCALE,
            SOURCE_CENTER.Y/SOURCE_SCALE+SOURCE_SHIFT_Y,
            SOURCE_CENTER.Z/SOURCE_SCALE)
        *CFrame.Angles(0,rotation,0)
    local roles={Static=0,Radar=0,Cable=0,Weight=0}
    local pieces={}
    for _,p in ipairs(clone:GetDescendants()) do
        if p:IsA("BasePart") then
            if not p:IsA("MeshPart") then clone:Destroy();return nil end
            local role=p:GetAttribute("OriginalHarborHeroMotionRole")
            if roles[role]==nil then clone:Destroy();return nil end
            p.CFrame=target*modelFrame:ToObjectSpace(p.CFrame)
            p.Anchored=true
            p.Massless=true
            p.CanCollide=false
            p.CanTouch=false
            p.CanQuery=false
            p.CastShadow=false
            p:SetAttribute("OriginalHarborHeroStation3D",true)
            p:SetAttribute("Original3DAssetId",ID)
            pieces[#pieces+1]={part=p,role=role,rest=p.CFrame}
            roles[role]+=1
        end
    end
    if #pieces~=7 or roles.Static~=4 or roles.Radar~=1
        or roles.Cable~=1 or roles.Weight~=1 then
        clone:Destroy();return nil
    end
    local originals={}
    local observed=0
    for _,native in ipairs(scene.hero:GetChildren()) do
        if native:IsA("BasePart") and EXPECTED_NAMES[native.Name] then
            if native.CanCollide or native.CanQuery or native.CanTouch then
                clone:Destroy();return nil
            end
            originals[native]=native.Transparency
            observed+=1
        end
    end
    if observed<12 then clone:Destroy();return nil end
    local refs=scene.refs
    local e={
        arena=arena,base=base,hero=scene.hero,lens=scene.lens,
        girder=scene.girder,source=source,model=clone,
        pieces=pieces,refs=refs,motionRefs=refs,
        initial={
            Radar=nativeFrame*CFrame.new(0,37.7,0),
            Cable=nativeFrame*CFrame.new(22.5,16,0),
            Weight=nativeFrame*CFrame.new(22.5,9.7,0),
        },
        original=originals,connections={},disposing=false,
    }
    clone.Name="ApprovedOriginalHarborHeroStation3D"
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",ID)
    clone.Parent=localFolder
    -- Reuse the actual native hero animation CFrame writes; no new loop.
    for _,native in pairs(refs) do
        e.connections[#e.connections+1]=
            native:GetPropertyChangedSignal("CFrame"):Connect(function()
                syncMotion(e)
            end)
        -- The existing hero owner resets original alpha during
        -- ReduceMotion/phase rest-pose events. Keep the native animation
        -- provider alive but visually masked for the FULL duration of
        -- an authenticated 3D replacement, without a second frame loop.
        e.connections[#e.connections+1]=
            native:GetPropertyChangedSignal("Transparency"):Connect(function()
                if not e.disposing and alive(e)
                    and native.Transparency~=1 then
                    native.Transparency=1
                end
            end)
    end
    local function changed()
        if not alive(e) then visibility(e) end
    end
    e.connections[#e.connections+1]=
        scene.hero.ChildRemoved:Connect(changed)
    e.connections[#e.connections+1]=
        base:GetPropertyChangedSignal("Size"):Connect(changed)
    e.connections[#e.connections+1]=
        clone.DescendantRemoving:Connect(function(p)
            if not e.disposing and p:IsA("MeshPart") then
                task.defer(visibility,e)
            end
        end)
    if visibility(e) then syncMotion(e) end
    return e
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,pressure)
    if activeArena~=arena then
        dismount()
        activeArena=arena
    end
    local budget=BUDGET[tier] or BUDGET.Low
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if not arena or not cameraReady or budget.count==0
        or stress>=2 or (tier=="Medium" and stress>=1)
        or typeof(cameraPoint)~="Vector3" then
        dismount();return
    end
    local scene=nativeScene(arena)
    local source=allowedModel()
    if not scene or not source then dismount();return end
    local distance=(cameraPoint-scene.girder.Position).Magnitude
    if distance>budget.distance+(entry and budget.retain or 0) then
        dismount();return
    end
    if entry and (entry.source~=source or entry.hero~=scene.hero
        or entry.girder~=scene.girder or not alive(entry)) then
        dismount()
    end
    if not entry then entry=mount(arena,scene,source) end
    if entry then
        if visibility(entry) then syncMotion(entry) end
    end
end

function Kit.count()
    return alive(entry) and 1 or 0
end

return Kit
