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
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild(kind)
    if not source or not source:IsA("Model")
        or source.Parent ~= holder
        or source:GetAttribute("Original3DAssetId") ~= IDS[kind]
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("OriginalLargeStructure3D") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true then return nil end
    local count = 0
    for _, v in ipairs(source:GetDescendants()) do
        if v:IsA("BasePart") then
            if not v:IsA("MeshPart") or v.CanCollide
                or v.CanTouch or v.CanQuery then return nil end
            count += 1
        elseif v:IsA("LuaSourceContainer") then
            return nil
        end
    end
    -- Imported originals have seven material groups each. Accepting a
    -- partial/extra source left complete-source masking with a non-7
    -- bundle impossible, and wasted scarce Android 3D modules.
    if count ~= 7 then return nil end
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
    return source,size,count
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

-- The server authors true 4.85-stud posts under the first elevated
-- 14x12 Crossroads route decks (bottom 6, support deckTop 1.15). The
-- previous hardcoded five-stud cutoff rejected them even though the
-- creator-approved 14-stud original fits the already-enforced >=.34
-- source-scale requirement. Never admit shorter posts: they remain
-- bare native until a proven approved source fits.
local MIN_NATIVE_SUPPORT_HEIGHT = 4.75

local function validNativeSupport(part,index)
    return part and part:IsA("BasePart")
        and part.Anchored and not part.CanCollide and not part.CanTouch
        and not part.CanQuery and part.Name:match(
            "^PlatformSupport"..tostring(index).."_%d+$") ~= nil
        and part.Size.Y >= MIN_NATIVE_SUPPORT_HEIGHT
        and part.Size.Y <= 47
end

-- Source-fit and module cost for ONE genuine native support. This is
-- intentionally shared by candidate selection and mounting: a 42-stud
-- column consumes three seven-MeshPart modules and a too-narrow native
-- must not occupy a camera-ranked slot that would fail on installation.
-- Pure computation: no Roblox Instances or new frame listeners.
function Kit.supportFit(nativeSize, sourceBounds)
    if typeof(nativeSize) ~= "Vector3"
        or typeof(sourceBounds) ~= "Vector3"
        or nativeSize.X <= 0 or nativeSize.Z <= 0
        or nativeSize.Y < MIN_NATIVE_SUPPORT_HEIGHT
        or nativeSize.Y > 47
        or sourceBounds.X <= 0 or sourceBounds.Y <= 0
        or sourceBounds.Z <= 0 then return nil end
    local segments = math.clamp(math.ceil(nativeSize.Y / 16.0), 1, 3)
    local segmentHeight = nativeSize.Y / segments
    local scale = segmentHeight / sourceBounds.Y
    local width = math.max(sourceBounds.X, sourceBounds.Z) * scale
    if scale < .34 or scale > 1.25
        or width > 3.2
        or width > math.max(nativeSize.X, nativeSize.Z) * 2.5
        or segmentHeight > 17.8 then return nil end
    return segments, scale
end

-- The same genuine-model envelope must govern candidate selection and
-- final montage. Previously Medium/High could reserve a scarce authentic
-- LongCradle slot for a deck whose source was too narrow/short when
-- actually staged, leaving its huge rectangular native underframe visible.
-- This pure check creates no parts and uses ONLY real model bounding boxes.
function Kit.cradleFit(size,sourceBounds)
    if typeof(size)~="Vector3" or typeof(sourceBounds)~="Vector3"
        or sourceBounds.X<=0 or sourceBounds.Y<=0
        or sourceBounds.Z<=0 then return nil end
    local long=math.max(size.X,size.Z)
    local short=math.min(size.X,size.Z)
    if long<19.5 or long>34 or short<9 or short>18 then return nil end
    local sourceLong=math.max(sourceBounds.X,sourceBounds.Z)
    local sourceShort=math.min(sourceBounds.X,sourceBounds.Z)
    local scale=math.min(1.21,long*.95/sourceLong,
        short*.91/sourceShort)
    if scale<.76 or sourceLong*scale<long*.87
        or sourceShort*scale<short*.76
        or sourceLong*scale>long*.97
        or sourceBounds.Y*scale>5 then return nil end
    return scale
end

-- Exchange source modules, never create a new GPU allowance. At most
-- four of High desktop's 16 seven-MeshPart column slots may become four
-- additional seven-MeshPart original underframes, and ONLY when real
-- source-authenticated compatible deck candidates exist. In all cases
-- 16+4 == (16-traded)+(4+traded) == 20 total structure modules.
function Kit.desktopCradleTransfer(tier,desktopHigh,candidates)
    if tier~="High" or desktopHigh~=true
        or type(candidates)~="table" then return 0 end
    local count=0
    for _ in pairs(candidates) do count+=1 end
    return math.min(4,math.max(0,count-4))
end

-- Prioritize verified genuine supports + full-length undercarriages on
-- physically safe, nearby bridge decks instead of arbitrary PlatformN %
-- sampling or the first two PlatformN in a large streamed arena.
-- One snapshot per EXISTING map/tier/asset arrival rebuild. No camera loop,
-- network calls or server-authoritative gameplay changes.
function Kit.selectNearRouteStructures(platforms,decor,variant,tier,base,cameraPoint,cameraLook,pressure,desktopHigh)
    local cradleSet,supportSet={},{}
    -- Low spends exactly ONE approved seven-MeshPart source module:
    -- a near-camera LongCradle OR one rectangular support replacement,
    -- never both. Pressure restores all native geometry automatically.
    if type(platforms) ~= "table" or not base
        or not base:IsA("BasePart")
        or (tier == "Low" and (tonumber(pressure) or 0) > 0) then
        return cradleSet,supportSet
    end
    local cradleSource,cradleBounds,cradleParts=verified("LongCradle")
    if tier == "Low" and cradleParts ~= 7 then
        cradleSource=nil
    end
    local supportSource,supportBounds,supportParts=nil,nil,nil
    if decor and decor:IsA("Folder") then
        supportSource,supportBounds,supportParts=verified(variant)
    end
    if tier == "Low" and supportParts ~= 7 then
        supportSource=nil
    end
    if not cradleSource and not supportSource then
        return cradleSet,supportSet
    end
    -- Bind by actual named server support ownership; an unstreamed
    -- or absent support must never consume an authentic mesh slot.
    local supportsAvailable={}
    if supportSource then
        for _,part in ipairs(decor:GetChildren()) do
            local suffix=part.Name:match("^PlatformSupport(%d+)_%d+$")
            local id=tonumber(suffix)
            if id and validNativeSupport(part,id) then
                local segments = Kit.supportFit(part.Size, supportBounds)
                -- Low has only one available source module. Other tiers
                -- must also reject an impossible fit before reserving a
                -- finite camera-near owner; taller valid posts cost 2-3.
                if segments and (tier ~= "Low" or segments == 1) then
                    local previous = supportsAvailable[id]
                    if previous == nil or segments < previous then
                        supportsAvailable[id] = segments
                    end
                end
            end
        end
    end
    local focus=base.Position
    local cameraReady=false
    if typeof(cameraPoint) == "Vector3" then
        local point=base.CFrame:PointToObjectSpace(cameraPoint)
        if math.abs(point.X)<=base.Size.X*.5+16
            and math.abs(point.Z)<=base.Size.Z*.5+16
            and math.abs(point.Y)<=130 then
            focus=cameraPoint
            cameraReady=true
        end
    end
    -- Never mount extra Low geometry while the camera is still in lobby
    -- or a streamed-in arena is not yet a valid viewer frame.
    if tier == "Low" and not cameraReady then
        return cradleSet,supportSet
    end
    -- Favor genuine creator-owned columns / long cradles in the live
    -- third-person view without changing High/Medium source quotas or
    -- requiring a costly rebuild on every camera move.
    local function cameraFacingBias(delta)
        if focus ~= cameraPoint or typeof(cameraLook) ~= "Vector3" then
            return 0
        end
        local route=Vector3.new(delta.X,0,delta.Z)
        local look=Vector3.new(cameraLook.X,0,cameraLook.Z)
        if route.Magnitude<30 or look.Magnitude<0.5 then return 0 end
        return -route.Unit:Dot(look.Unit)
            *math.min(36,route.Magnitude*.18)
    end
    local cradles,supports={},{}

    for _,platform in ipairs(platforms) do
        local id=platform.Name:match("^Platform(%d+)$")
        id=id and tonumber(id) or nil
        if id and platform:IsA("BasePart") and platform.Parent
            and platform.Anchored and platform.CanCollide
            and platform.Transparency < .75
            and platform:GetAttribute("ChaosSkybridge")~=true
            and (platform:GetAttribute("CollapsePhase")==nil
                or platform:GetAttribute("CollapsePhase")=="Normal"
                or platform:GetAttribute("CollapsePhase")=="Safe") then
            local size=platform.Size
            local long,short=math.max(size.X,size.Z),math.min(size.X,size.Z)
            local delta=platform.Position-focus
            local score=Vector3.new(delta.X,delta.Y*.65,delta.Z).Magnitude
                +cameraFacingBias(delta)
            if platform:GetAttribute("ChaosPermanentRoute")==true then
                score-=8
            end
            local spine=tonumber(platform:GetAttribute("SkySpineStep"))
            local promenade=tonumber(platform:GetAttribute("PromenadeStep"))
            if spine==5 or spine==6 then score-=14 end
            -- All tiers now check the same geometry as longCradle().
            -- Reject a 30+ stud native deck that the actual 22-stud
            -- original cannot cover, BEFORE spending an approved 3D slot.
            if cradleSource and (spine or promenade)
                and Kit.cradleFit(size,cradleBounds)
                and (tier ~= "Low"
                    or (platform.Position-cameraPoint).Magnitude<=125) then
                cradles[#cradles+1]={platform=platform,score=score}
            end
            if supportSource and supportsAvailable[id]
                and long>=7 and long<=36 and short>=7
                and (tier ~= "Low" or (platform.Position-cameraPoint).Magnitude
                    <= 125) then
                supports[#supports+1]={platform=platform,score=score}
            end
        end
    end
    local function byFocus(a,b)
        if a.score~=b.score then return a.score<b.score end
        return a.platform.Name<b.platform.Name
    end
    table.sort(cradles,byFocus)
    table.sort(supports,byFocus)
    -- A map-owner snapshot is rebuilt on real streaming and tier events,
    -- NOT on every camera frame. Putting all approved source modules in the
    -- first screenful left distant Sky Spine/promenade intersections and
    -- their real supports as bare rectangular Roblox native Parts.
    -- Keep nearby hero silhouettes, then spread unused SAME-budget slots
    -- over real, separated, collidable platform owners on this 320x320 map.
    -- No new 3D assets, Parts, Lua loops per frame, routes or GPU budgets.
    local function distribute(candidates,limit,foreground)
        local selected={}
        local count=math.min(#candidates,limit)
        local front=math.min(count,foreground)
        for i=1,front do
            local deck=candidates[i].platform
            selected[deck]=true
        end
        local taken=front
        local spacingCap=math.max(base.Size.X,base.Size.Z)*.68
        while taken<count do
            local winner,winnerScore=nil,-math.huge
            for _,candidate in ipairs(candidates) do
                if not selected[candidate.platform] then
                    local nearest=spacingCap
                    for deck in pairs(selected) do
                        local offset=candidate.platform.Position-deck.Position
                        nearest=math.min(nearest,Vector3.new(
                            offset.X,offset.Y*.65,offset.Z).Magnitude)
                    end
                    -- Retain some preference for genuinely near, busy
                    -- permanent route segments; spacing itself dominates.
                    local score=nearest-candidate.score*.12
                    if score>winnerScore or (score==winnerScore
                        and winner and candidate.platform.Name<winner.Name) then
                        winner=candidate.platform
                        winnerScore=score
                    end
                end
            end
            if not winner then break end
            selected[winner]=true
            taken+=1
        end
        return selected
    end
    -- Desktop High may TRADE four existing 7-piece column modules for
    -- four extra open-lattice underframes. Android High/Medium/Low retain
    -- all old caps. This selector only exposes the eligible candidate set;
    -- arena-platform-identity reallocates the exact SAME total modules
    -- when the creator-approved LongCradle is actually available.
    local cradleLimit=tier=="High" and
        (desktopHigh==true and 8 or 4) or (tier=="Medium" and 2 or 1)
    -- Medium's renderer already budgets eight seven-MeshPart support
    -- modules. Each Medium platform mounts at most ONE support, so
    -- selecting only four deck owners left half the approved budget idle.
    -- Rank up to eight *distinct* real support-bearing platforms without
    -- increasing the existing eight-module ceiling. High still chooses
    -- eight owners (at most two supports each); Low still chooses one.
    local supportLimit=tier=="High" and 8 or (tier=="Medium" and 8 or 1)
    -- An authenticated long Sky Spine cradle 110 studs away used to
    -- consume Low's only structural 3D slot even with a sculptable
    -- native support immediately in the player's view. Use the EXISTING
    -- ranked camera/route scores: prefer the nearby genuine post only
    -- when it is clearly closer (eight-stud hysteresis), otherwise keep
    -- the more prominent long lattice. Still ONE seven-MeshPart source.
    local preferSupport=tier=="Low" and supports[1]
        and (not cradles[1]
            or supports[1].score+8<cradles[1].score)
    if not preferSupport then
        cradleSet=distribute(cradles,cradleLimit,
            tier=="High" and 2 or 1)
    end
    -- Never stack a seven-piece tall column behind a seven-piece
    -- underframe on Low. Medium/High keep their independent budgets.
    if tier~="Low" or next(cradleSet)==nil then
        supportSet=distribute(supports,supportLimit,
            tier=="High" and 5 or (tier=="Medium" and 2 or 1))
    end
    return cradleSet,supportSet
end

-- Returns {parts,covered,disconnects,modules} or nil. A support is masked
-- only after every segment of the source Model has been mounted correctly.
-- Each named native server support remains anchored and drives its Welds.
-- Shrink changes the ORIGINAL Part.Size; the only connection is event-based,
-- and scales the imported art X/Z while preserving its full vertical length.
function Kit.supports(parent,decor,platform,variant,tier,index,available,selected)
    if available <= 0 or not parent
        or not decor or not decor:IsA("Folder") or not platform
        or platform:GetAttribute("ChaosSkybridge") == true
        or (tier == "Low" and selected ~= true) then return nil end
    local source,box,sourceParts = verified(variant)
    if not source or (tier == "Low" and sourceParts ~= 7)
        or not platform.Parent
        or not platform:IsA("BasePart") then return nil end
    if type(index) ~= "number" or index < 1 then return nil end
    -- Sample enough real supports to use the EXISTING hard module budget.
    -- The former 1/7 High, 1/13 Medium sampling could leave most of the
    -- 16/8-module allowance idle, with the old bare rectangular posts
    -- still dominating the scene. Never increase the module ceiling.
    local choice = tier == "High" and 4 or 8
    if selected == false or (selected ~= true
        and index % choice ~= 0) then return nil end

    local natives = {}
    for _,child in ipairs(decor:GetChildren()) do
        if validNativeSupport(child,index) then
            natives[#natives+1]=child
        end
    end
    table.sort(natives,function(a,b) return a.Name<b.Name end)
    local maxSupports = tier=="High" and 2 or 1
    -- Low has exactly ONE seven-piece source module (not per-platform).
    local output = {parts={},covered={},disconnects={},modules=0}
    for _,support in ipairs(natives) do
        if #output.covered >= maxSupports or output.modules >= available then break end
        local segments, scale = Kit.supportFit(support.Size, box)
        if segments and segments <= available - output.modules then
            local height = support.Size.Y / segments
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
function Kit.longCradle(parent,platform,tier,index,selected)
    if selected == false or (tier == "Low" and selected ~= true) then
        return nil
    end
    if not parent or not platform or not platform:IsA("BasePart")
        or not platform.Parent
        or platform:GetAttribute("ChaosSkybridge") == true then return nil end
    if tier == "Low" then
        -- Low's single source-backed chariot can only decorate a safe
        -- actual collidable route. Medium/High retain legacy behavior.
        local phase=platform:GetAttribute("CollapsePhase")
        if not platform.Anchored or not platform.CanCollide
            or platform.Transparency>=.75
            or (phase ~= nil and phase ~= "Normal" and phase ~= "Safe")
            or (platform:GetAttribute("BridgeShutterPhase") ~= nil
                and platform:GetAttribute("BridgeShutterPhase") ~= "Idle")
            then return nil end
    end
    if platform:GetAttribute("PromenadeStep")==nil
        and platform:GetAttribute("SkySpineStep")==nil then return nil end
    local source,box,count=verified("LongCradle")
    if not source or (tier == "Low" and count ~= 7) then return nil end
    local sx,sy,sz=platform.Size.X,platform.Size.Y,platform.Size.Z
    local long=math.max(sx,sz)
    local scale=Kit.cradleFit(platform.Size,box)
    if not scale then return nil end
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
