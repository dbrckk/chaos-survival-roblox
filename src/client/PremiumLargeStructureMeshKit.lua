-- Authenticated creator-owned 3D replacement of visible primitive deck
-- support posts and overlong platform underframes. Cosmetic-only.
-- Six moderated Approved Model IDs, verified in upload #41808940118.
-- The server still owns every collision route, shrinking platform,
-- warning label, shutter and native fallback primitive.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local IDS = {
    Classic = 91626128452597,
    Towers = 107521411452905,
    Crossroads = 93993697329658,
    Orbital = 119010829781313,
    Harbor = 76194593490199,
    LongCradle = 128914328933863,
}

local function verified(kind)
    local holder = ReplicatedStorage:FindFirstChild("ApprovedLargeStructureTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild(kind)
    if not source or not source:IsA("Model")
        or source:GetAttribute("Original3DAssetId") ~= IDS[kind]
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("OriginalLargeStructure3D") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true then return nil end
    local count = 0
    for _, v in ipairs(source:GetDescendants()) do
        if v:IsA("BasePart") then
            if not v:IsA("MeshPart") then return nil end
            count += 1
        elseif v:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, size = source:GetBoundingBox()
    local xzLong = math.max(size.X,size.Z)
    local xzShort = math.min(size.X,size.Z)
    if kind == "LongCradle" then
        if not (size.Y > 1.9 and size.Y < 4.7
            and xzLong >= 21.2 and xzLong <= 24.2
            and xzShort >= 9.1 and xzShort <= 11.4) then return nil end
    elseif not (size.Y >= 13.4 and size.Y <= 15.1
        and xzLong >= 1.6 and xzLong <= 2.8
        and xzShort >= 1.5 and xzShort <= 2.7) then return nil end
    return source,size
end

local function prepare(source,scale,at,native,kind,adjustable)
    local clone = source:Clone()
    if not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return nil
    end
    local frame,box = clone:GetBoundingBox()
    local target = at(box)
    if typeof(target) ~= "CFrame" then clone:Destroy(); return nil end
    local parts = {}
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            part.CFrame = target * frame:ToObjectSpace(part.CFrame)
            part.Anchored = false
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part:SetAttribute("ChaosBaseTransparency",part.Transparency)
            part:SetAttribute("ChaosPlatformTrim",true)
            part:SetAttribute("OriginalLargeStructure3D",true)
            part:SetAttribute("Original3DAssetId",IDS[kind])
            local weld = Instance.new(adjustable and "Weld" or "WeldConstraint")
            weld.Name = adjustable and "ChaosPlatformTrimWeld"
                or "OriginalSupportVisualWeld"
            weld.Part0 = part
            weld.Part1 = native
            if adjustable then
                weld.C0 = CFrame.identity
                weld.C1 = native.CFrame:ToObjectSpace(part.CFrame)
            end
            weld.Parent = part
            parts[#parts+1] = part
        end
    end
    if #parts < 1 or #parts > 12 then
        clone:Destroy()
        return nil
    end
    -- Source Models are cleaned up only AFTER all their genuine MeshParts
    -- are reparented; this preserves the imported MeshId and materials.
    return {source = clone, parts = parts}
end

local function commit(parent,stage,kind,suffix)
    for i,part in ipairs(stage.parts) do
        part.Name = "ApprovedLarge3D_"..kind.."_"..suffix.."_"..tostring(i)
        part.Parent = parent
    end
    stage.source:Destroy()
    return stage.parts
end

local function validNativeSupport(part,index)
    return part and part:IsA("BasePart")
        and part.Anchored and not part.CanCollide and not part.CanTouch
        and not part.CanQuery and part.Name:match(
            "^PlatformSupport"..tostring(index).."_%d+$") ~= nil
        and part.Size.Y >= 5 and part.Size.Y <= 47
end

-- Returns {parts,covered,disconnects,modules} or nil. A support is masked
-- only after every segment of the source Model has been mounted correctly.
-- Each named native server support remains anchored and drives its Welds.
-- Shrink changes the ORIGINAL Part.Size; the only connection is event-based,
-- and scales the imported art X/Z while preserving its full vertical length.
function Kit.supports(parent,decor,platform,variant,tier,index,available)
    if tier == "Low" or available <= 0 or not parent
        or not decor or not decor:IsA("Folder") or not platform
        or platform:GetAttribute("ChaosSkybridge") == true then return nil end
    local source,box = verified(variant)
    if not source or not platform.Parent
        or not platform:IsA("BasePart") then return nil end
    if type(index) ~= "number" or index < 1 then return nil end
    -- Sample enough real supports to use the EXISTING hard module budget.
    -- The former 1/7 High, 1/13 Medium sampling could leave most of the
    -- 16/8-module allowance idle, with the old bare rectangular posts
    -- still dominating the scene. Never increase the module ceiling.
    local choice = tier == "High" and 4 or 8
    if index % choice ~= 0 then return nil end

    local natives = {}
    for _,child in ipairs(decor:GetChildren()) do
        if validNativeSupport(child,index) then
            natives[#natives+1]=child
        end
    end
    table.sort(natives,function(a,b) return a.Name<b.Name end)
    local maxSupports = tier=="High" and 2 or 1
    local output = {parts={},covered={},disconnects={},modules=0}
    for _,support in ipairs(natives) do
        if #output.covered >= maxSupports or output.modules >= available then break end
        local segments = math.clamp(math.ceil(support.Size.Y/16.0),1,3)
        local height = support.Size.Y/segments
        local scale = height/box.Y
        local width = math.max(box.X,box.Z)*scale
        if segments <= available-output.modules and scale >= .34
            and scale <= 1.25 and width <= 3.2
            and width <= math.max(support.Size.X,support.Size.Z)*2.5 then
            local stages = {}
            local ok = true
            for k=1,segments do
                local delta=(k-(segments+1)*.5)*height
                local stage=prepare(source,scale,function(scaled)
                    if scaled.Y <= 0 or scaled.Y>17.8 then return nil end
                    return support.CFrame*CFrame.new(0,delta,0)
                end,support,variant,true)
                if not stage then ok=false; break end
                stages[#stages+1]=stage
            end
            if ok then
                local entries = {}
                for k,stage in ipairs(stages) do
                    for _,part in ipairs(commit(parent,stage,variant,
                        tostring(index).."_"..tostring(k))) do
                        part:SetAttribute("OriginalSupportColumn3D",true)
                        -- This imported source follows its actual native
                        -- support, NOT the RouteTier deck shrink snapshot.
                        -- Avoid double resizing by deck and support owners.
                        part:SetAttribute("SkipRouteFootprint",true)
                        local localFrame=support.CFrame:ToObjectSpace(part.CFrame)
                        local joint=part:FindFirstChild("ChaosPlatformTrimWeld")
                        entries[#entries+1]={
                            part=part,size=part.Size,localFrame=localFrame,joint=joint,
                        }
                        output.parts[#output.parts+1]=part
                    end
                end
                local base=support.Size
                local function followSupportSize()
                    if not support.Parent then return end
                    local rx=math.clamp(support.Size.X/base.X,.05,2)
                    local rz=math.clamp(support.Size.Z/base.Z,.05,2)
                    for _,entry in ipairs(entries) do
                        if entry.part.Parent and entry.joint
                            and entry.joint.Parent then
                            entry.part.Size=Vector3.new(
                                math.max(.03,entry.size.X*rx),entry.size.Y,
                                math.max(.03,entry.size.Z*rz))
                            local p=entry.localFrame.Position
                            local rot=entry.localFrame-p
                            entry.joint.C1=CFrame.new(p.X*rx,p.Y,p.Z*rz)*rot
                        end
                    end
                end
                output.disconnects[#output.disconnects+1] =
                    support:GetPropertyChangedSignal("Size"):Connect(
                        followSupportSize)
                output.covered[#output.covered+1]=support
                output.modules += segments
                followSupportSize()
            else
                for _,stage in ipairs(stages) do
                    stage.source:Destroy()
                end
            end
        end
    end
    if output.modules < 1 then return nil end
    return output
end

-- A true 22-stud, open-lattice 3D underframe for long, elevated promenade
-- and Sky Spine routes, not an invented extra walkable bridge. The source
-- must cover at least 87% of length and 76% of width BEFORE replacing the
-- older low-slung rectangular underframe in the LOCAL renderer.
function Kit.longCradle(parent,platform,tier,index)
    if tier == "Low" or not parent or not platform
        or not platform:IsA("BasePart") or not platform.Parent
        or platform:GetAttribute("ChaosSkybridge") == true then return nil end
    if platform:GetAttribute("PromenadeStep")==nil
        and platform:GetAttribute("SkySpineStep")==nil then return nil end
    local source,box=verified("LongCradle")
    if not source then return nil end
    local sx,sy,sz=platform.Size.X,platform.Size.Y,platform.Size.Z
    local long=math.max(sx,sz)
    local short=math.min(sx,sz)
    if long<19.5 or long>34 or short<9 or short>18 then return nil end
    local srcLong=math.max(box.X,box.Z)
    local srcShort=math.min(box.X,box.Z)
    local scale=math.min(1.21,long*.95/srcLong,short*.91/srcShort)
    if scale<.76 or srcLong*scale<long*.87
        or srcShort*scale<short*.76 then return nil end
    local yaw=(sz>sx)~=(box.Z>box.X) and math.pi*.5 or 0
    local stage=prepare(source,scale,function(bounds)
        if bounds.Y>5 or math.max(bounds.X,bounds.Z)>long*.97 then
            return nil
        end
        return platform.CFrame*CFrame.new(
            0,-sy*.5-.09-bounds.Y*.5,0)*CFrame.Angles(0,yaw,0)
    end,platform,"LongCradle",tonumber(platform:GetAttribute("RouteTier"))~=nil)
    if not stage then return nil end
    local parts=commit(parent,stage,"LongCradle",tostring(index))
    for _,part in ipairs(parts) do
        part:SetAttribute("OriginalLongCradle3D",true)
    end
    return parts
end

return Kit
