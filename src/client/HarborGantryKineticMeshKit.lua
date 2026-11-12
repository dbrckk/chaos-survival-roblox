-- Real moving 3D Harbor cranes: 7 genuine source-moderated MeshParts per
-- Model, with separate structural/Trolley/Cable/Load groups. Uses EXISTING
-- native HarborGantryMotionRules parts as motion sensors: no second timer,
-- RenderStepped, additional physics, new RemoteEvents or fabricated route.
-- Original 4 native cranes are retained and restored on source/LOD failure.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local APPROVED = {
    North = {name="ContainerGantry", id=75684193304551},
    South = {name="CableGantry", id=98809955094422},
}
local BUDGET = {
    -- Low: one source-authenticated 7-MeshPart crane within camera-near
    -- range. The existing Low gantry-motion profile remains static and
    -- the native scenery is still hidden by its separate coarse LOD.
    Low = {models=1,distance=135,retention=18},
    Medium = {models=2,distance=170,retention=24},
    High = {models=4,distance=345,retention=36},
}
local CRANES = {
    "HarborGantryEastNorth", "HarborGantryEastSouth",
    "HarborGantryWestNorth", "HarborGantryWestSouth",
}
local EXPECTED_SECTOR = {
    HarborGantryEastNorth="North", HarborGantryEastSouth="South",
    HarborGantryWestNorth="North", HarborGantryWestSouth="South",
}
local folder = Instance.new("Folder")
folder.Name = "OriginalHarborKineticGantryLocal"
folder:SetAttribute("CosmeticOnly",true)
folder.Parent = workspace

local activeArena = nil
local mounted = {}
local watchedBase = nil
local baseChanged = nil

-- The visible arena Base is shrunk during active survival rounds; the
-- exterior gantries are not. Their authored perimeter is immutable and
-- must be checked via the original dimensions, not the shrinking floor.
local function authenticBase(base)
    if not base or not base:IsA("BasePart")
        or not base.Anchored or not base.CanCollide then return false end
    local sx=base:GetAttribute("OriginalSizeX")
    local sz=base:GetAttribute("OriginalSizeZ")
    return typeof(sx)=="number" and typeof(sz)=="number"
        and sx>=318 and sz>=318
end

local function sourceFor(sector)
    local spec = APPROVED[sector]
    if not spec then return nil end
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedHarborKineticGantryTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source = holder:FindFirstChild(spec.name)
    if not source or not source:IsA("Model") or source.Parent~=holder
        or source:GetAttribute("Original3DAssetId")~=spec.id
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("OriginalHarborKineticGantry3D")~=true
        or source:GetAttribute("CosmeticOnly")~=true then return nil end
    local roles={Static=0,Trolley=0,Cable=0,Load=0}
    for _,part in ipairs(source:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then return nil end
            local role=part:GetAttribute("OriginalHarborGantryKineticRole")
            if not roles[role] then
                -- 0 is truthy in Luau; absent role is nil.
                return nil
            end
            roles[role]+=1
        elseif part:IsA("LuaSourceContainer") then return nil end
    end
    if roles.Static~=4 or roles.Trolley~=1
        or roles.Cable~=1 or roles.Load~=1 then return nil end
    local _,b=source:GetBoundingBox()
    if math.min(b.X,b.Z)<21.1 or math.min(b.X,b.Z)>22.8
        or math.max(b.X,b.Z)<43.3 or math.max(b.X,b.Z)>45.0
        or b.Y<35.5 or b.Y>36.8 then return nil end
    return source
end

local function genuine(crane,arena,base)
    if not crane or not arena or not base
        or tostring(arena:GetAttribute("VariantId"))~="Harbor"
        or not authenticBase(base) or base.Parent~=arena
        or not crane:IsA("Model")
        or crane:GetAttribute("HarborGantryScenery")~=true
        or crane:GetAttribute("SourceIsOriginal")~=true
        or crane:GetAttribute("CosmeticOnly")~=true then return false end
    local decor=arena:FindFirstChild("Decor")
    local fleet=decor and decor:FindFirstChild("StormHarborGantryFleet")
    if not fleet or crane.Parent~=fleet then return false end
    local sector=crane:GetAttribute("GantrySector")
    if (sector~="North" and sector~="South")
        or EXPECTED_SECTOR[crane.Name]~=sector then
        return false
    end
    local girder=crane:FindFirstChild("MainCrossgirder")
    local trolley=crane:FindFirstChild("TrolleyCabin")
    local cable=crane:FindFirstChild("HoistCable")
    local load=crane:FindFirstChild("CargoSpreader")
    local native=crane:FindFirstChild(sector=="North"
        and "ContainerArmor" or "CableDrum")
    if not girder or not trolley or not cable or not load or not native
        or not girder:IsA("BasePart")
        or not trolley:IsA("BasePart")
        or not cable:IsA("BasePart")
        or not load:IsA("BasePart")
        or not native:IsA("BasePart")
        or not girder.Anchored or not trolley.Anchored
        or not cable.Anchored or not load.Anchored
        or girder.CanCollide or trolley.CanCollide
        or cable.CanCollide or load.CanCollide
        or math.abs(girder.Size.X-20)>.35
        or math.abs(girder.Size.Y-1.8)>.35
        or math.abs(cable.Size.X-.25)>.15
        or math.abs(girder.Size.Z-2.2)>.35 then return false end
    return true,girder,trolley,cable,load
end

local function valid(e)
    -- This runs on native CFrame animation events (up to 4 cranes).
    -- Never re-inspect seven template MeshParts, call GetBoundingBox or
    -- rescan the whole native gantry on every movement frame. The shared
    -- 0.90s scenery LOD sampler performs full source/genuine checks.
    if not e or not e.model or e.model.Parent~=folder
        or e.arena~=activeArena or e.crane.Parent~=e.fleet
        or not authenticBase(e.base) or e.base.Parent~=e.arena
        or not e.source.Parent
        or e.source:GetAttribute("OriginalHarborKineticGantry3D")~=true
        or e.source:GetAttribute("Original3DAssetId")~=(
            e.sector=="North" and APPROVED.North.id or APPROVED.South.id)
        or e.crane:GetAttribute("GantrySector")~=e.sector
        or e.girder.Parent~=e.crane or e.trolley.Parent~=e.crane
        or e.cable.Parent~=e.crane or e.load.Parent~=e.crane
        or not e.girder.Anchored or e.girder.CanCollide then
        return false
    end
    local n=0
    for _,piece in ipairs(e.pieces) do
        if not piece.part or piece.part.Parent~=e.model then return false end
        n+=1
    end
    return n==7
end

local function visibility(e)
    local show=valid(e)
    for _,piece in ipairs(e.pieces) do
        if piece.part.Parent then
            piece.part.LocalTransparencyModifier=show and 0 or 1
        end
    end
    -- SceneryLod already owns native LocalTransparencyModifier.
    -- Only this client-local Transparency change masks a completed original
    -- imported Model; NEVER touch the server Part or physical collider.
    for part,alpha in pairs(e.originalNative) do
        if part.Parent then part.Transparency=show and 1 or alpha end
    end
    return show
end

local function followNativeMotion(e)
    -- The pre-existing harbor-gantry-motion.client.lua owns *all* time
    -- and tween/hoist calculations. Follow its actual native CFrames so
    -- real 3D cargo is always synchronized, including ReduceMotion resets.
    if not valid(e) then visibility(e);return end
    local current={
        Trolley=e.trolley.CFrame*e.trolleyRest:Inverse(),
        Cable=e.cable.CFrame*e.cableRest:Inverse(),
        Load=e.load.CFrame*e.loadRest:Inverse(),
    }
    local cableScale=math.clamp(e.cable.Size.Y/13.0,.52,1.2)
    for _,piece in ipairs(e.pieces) do
        if piece.part.Parent then
            local transform=current[piece.role]
            if transform then
                piece.part.CFrame=transform*piece.rest
                if piece.role=="Cable" then
                    piece.part.Size=Vector3.new(
                        piece.size.X,piece.size.Y*cableScale,piece.size.Z)
                end
            end
        end
    end
end

local function dispose(e)
    e.disposing=true
    for _,conn in ipairs(e.connections) do conn:Disconnect() end
    for part,alpha in pairs(e.originalNative) do
        if part.Parent then part.Transparency=alpha end
    end
    e.model:Destroy()
end

local function unmount(crane)
    local e=mounted[crane]
    if not e then return end
    -- Remove ownership first: Destroy/ChildRemoved callbacks must not
    -- recursively tear down an already disposed original native crane.
    mounted[crane]=nil
    dispose(e)
end

local function clearModels()
    local keys={}
    for crane in pairs(mounted) do keys[#keys+1]=crane end
    for _,crane in ipairs(keys) do unmount(crane) end
end

-- The shared Android budget may evict a 7-part crane between scenery
-- ticks. Reveal the exact original crane immediately, not one tick later.
folder.ChildRemoved:Connect(function(child)
    if not child:IsA("Model") then return end
    for crane,e in pairs(mounted) do
        if e.model==child then unmount(crane);break end
    end
end)

local function clear()
    clearModels()
    if baseChanged then baseChanged:Disconnect() end
    baseChanged=nil
    watchedBase=nil
    activeArena=nil
    folder:ClearAllChildren()
end

local function mount(arena,base,fleet,crane,source,sector)
    local ok,girder,trolley,cable,load=genuine(crane,arena,base)
    if not ok then return nil end
    local clone=source:Clone()
    local frame,b=clone:GetBoundingBox()
    if math.min(b.X,b.Z)<21.1 or math.min(b.X,b.Z)>22.8
        or math.max(b.X,b.Z)<43.3 or math.max(b.X,b.Z)>45.0
        or b.Y<35.5 or b.Y>36.8 then
        clone:Destroy();return nil
    end
    -- The authored source Y was lowered by 18 studs and its verified
    -- bounding center is (0,-0.00526,0). The native crossgirder is
    -- physically at local (0,30,0), fixed even during hoist/trolley moves.
    -- Orientation can be swapped X/Z by the glTF Roblox importer.
    local yaw=b.X>b.Z and math.pi*.5 or 0
    local target=girder.CFrame*CFrame.new(0,-12.00526,0)
        *CFrame.Angles(0,yaw,0)
    local pieces,roles={}, {Static=0,Trolley=0,Cable=0,Load=0}
    for _,part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then clone:Destroy();return nil end
            local role=part:GetAttribute("OriginalHarborGantryKineticRole")
            if not roles[role] then clone:Destroy();return nil end
            part.CFrame=target*frame:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.Massless=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.CastShadow=false
            part:SetAttribute("OriginalHarborGantryKinetic3D",true)
            pieces[#pieces+1]={part=part,role=role,rest=part.CFrame,size=part.Size}
            roles[role]+=1
        end
    end
    if #pieces~=7 or roles.Static~=4 or roles.Trolley~=1
        or roles.Cable~=1 or roles.Load~=1 then
        clone:Destroy();return nil
    end

    -- The existing native crane's complete, always non-collidable fallback
    -- is retained. Motion source parts stay alive and continue to animate,
    -- even when hidden visually behind an imported MeshPart.
    local originals={}
    for _,part in ipairs(crane:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.CanCollide or part.CanTouch or part.CanQuery then
                clone:Destroy();return nil
            end
            originals[part]=part.Transparency
        end
    end
    local baseline=girder.CFrame*CFrame.new(0,-30,0)
    local e={
        arena=arena,base=base,crane=crane,fleet=fleet,
        girder=girder,trolley=trolley,cable=cable,load=load,
        sector=sector,source=source,model=clone,pieces=pieces,
        trolleyRest=baseline*CFrame.new(0,29.5,-11),
        cableRest=baseline*CFrame.new(0,22,-15),
        loadRest=baseline*CFrame.new(0,15.5,-15),
        originalNative=originals,connections={},disposing=false,
    }
    clone.Name="ApprovedOriginalAnimatedHarborCrane3D"
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",
        sector=="North" and APPROVED.North.id or APPROVED.South.id)
    clone.Parent=folder

    -- Only changes to EXISTING local animation Parts; no new animation
    -- owner or RenderStepped. Source and destination remain cosmetic.
    for _,part in ipairs({trolley,cable,load}) do
        e.connections[#e.connections+1]=
            part:GetPropertyChangedSignal("CFrame"):Connect(function()
                followNativeMotion(e)
            end)
    end
    e.connections[#e.connections+1]=
        cable:GetPropertyChangedSignal("Size"):Connect(function()
            followNativeMotion(e)
        end)
    local function changed()
        if mounted[crane]==e and not valid(e) then unmount(crane) end
    end
    e.connections[#e.connections+1]=crane.AncestryChanged:Connect(changed)
    e.connections[#e.connections+1]=source.AncestryChanged:Connect(changed)
    e.connections[#e.connections+1]=source.DescendantRemoving:Connect(function(part)
        if mounted[crane]==e and part:IsA("MeshPart") then
            unmount(crane)
        end
    end)
    e.connections[#e.connections+1]=base:GetPropertyChangedSignal(
        "Size"):Connect(changed)
    e.connections[#e.connections+1]=crane.ChildAdded:Connect(function(part)
        if part:IsA("BasePart") and not part.CanCollide and not part.CanTouch
            and not part.CanQuery and originals[part]==nil then
            originals[part]=part.Transparency
            if valid(e) then part.Transparency=1 end
        end
    end)
    e.connections[#e.connections+1]=crane.ChildRemoved:Connect(changed)
    e.connections[#e.connections+1]=clone.DescendantRemoving:Connect(function(p)
        if not e.disposing and mounted[crane]==e and p:IsA("MeshPart") then
            -- Missing any of seven source pieces must restore the native.
            unmount(crane)
        end
    end)
    if visibility(e) then followNativeMotion(e) end
    return e
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,cameraLook,pressure)
    if activeArena~=arena then
        clear()
        activeArena=arena
    end
    local budget=BUDGET[tier] or BUDGET.Low
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    local maxModels=budget.models
    if tier=="High" then
        maxModels=stress==0 and 4 or (stress==1 and 2 or 0)
    elseif tier=="Medium" then
        maxModels=stress==0 and 2 or (stress==1 and 1 or 0)
    elseif tier=="Low" and stress>0 then
        -- No costly original meshes under first optional-GPU pressure.
        maxModels=0
    end
    if not arena or not cameraReady or maxModels==0
        or typeof(cameraPoint)~="Vector3"
        or tostring(arena:GetAttribute("VariantId"))~="Harbor" then
        clearModels();return
    end
    local base=arena:FindFirstChild("Base")
    local decor=arena:FindFirstChild("Decor")
    local fleet=decor and decor:FindFirstChild("StormHarborGantryFleet")
    if not authenticBase(base) or base.Parent~=arena or not fleet
        or not fleet:IsA("Folder") then
        clearModels();return
    end
    if watchedBase~=base then
        if baseChanged then baseChanged:Disconnect() end
        watchedBase=base
        baseChanged=base:GetPropertyChangedSignal("Size"):Connect(function()
            -- A shrinking playable floor does not invalidate the
            -- original exterior art. Only a lost/invalid authored base
            -- should release the model.
            if not authenticBase(base) then clearModels() end
        end)
    end
    local ranked={}
    for _,name in ipairs(CRANES) do
        local crane=fleet:FindFirstChild(name)
        if crane and genuine(crane,arena,base) then
            local sector=crane:GetAttribute("GantrySector")
            local source=sourceFor(sector)
            if source then
                local girder=crane:FindFirstChild("MainCrossgirder")
                local distance=(cameraPoint-girder.Position).Magnitude
                local resident=mounted[crane]~=nil
                if distance<=budget.distance+(resident
                    and budget.retention or 0) then
                    local score=distance-(resident
                        and budget.retention*.60 or 0)
                    if typeof(cameraLook)=="Vector3"
                        and cameraLook.Magnitude>.5 and distance>40 then
                        local towardCrane=(girder.Position-cameraPoint).Unit
                        score-=math.min(42,distance*.16)
                            *towardCrane:Dot(cameraLook.Unit)
                    end
                    ranked[#ranked+1]={crane=crane,source=source,
                        score=score,sector=sector}
                end
            end
        end
    end
    table.sort(ranked,function(a,b)
        if a.score==b.score then return a.crane.Name<b.crane.Name end
        return a.score<b.score
    end)
    local selected={}
    for i=1,math.min(maxModels,#ranked) do
        selected[ranked[i].crane]=ranked[i]
    end
    local obsolete={}
    for crane,e in pairs(mounted) do
        local choose=selected[crane]
        if not choose or e.source~=choose.source or not valid(e) then
            obsolete[#obsolete+1]=crane
        else
            if visibility(e) then followNativeMotion(e) end
        end
    end
    -- Never mutate a Luau pairs iterator while cleanup callbacks remove
    -- the budget-owned clone. All mounts are bounded (Low1/Med2/High4).
    for _,crane in ipairs(obsolete) do unmount(crane) end
    for crane,selection in pairs(selected) do
        if not mounted[crane] then
            mounted[crane]=mount(arena,base,fleet,crane,
                selection.source,selection.sector)
        end
    end
end

function Kit.count()
    local models,parts=0,0
    for _,e in pairs(mounted) do
        if valid(e) then models+=1;parts+=#e.pieces end
    end
    return models,parts
end

return Kit
