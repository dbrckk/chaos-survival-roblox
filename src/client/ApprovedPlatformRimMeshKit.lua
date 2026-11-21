-- True creator-approved seven-MeshPart perimeter sculptures for real
-- rectangular / long playable platforms. Replaces the FOUR server
-- Platform bevels only AFTER a complete authentic model is welded.
-- NO new colliders, new update loop, fake MeshId or primitive fallback.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:FindFirstChild("Shared")
local lodRulesModule = script and shared and shared:FindFirstChild("PlatformIdentityLodRules")
local PlatformIdentityLodRules = if lodRulesModule
    then require(lodRulesModule) else require("../shared/PlatformIdentityLodRules")
local LargeStructure = if script and script.Parent
    and script.Parent:FindFirstChild("PremiumLargeStructureMeshKit")
    then require(script.Parent.PremiumLargeStructureMeshKit)
    else require("./PremiumLargeStructureMeshKit")
local Kit = {}

local APPROVED = {
    Rect = 131482590870627,
    Long = 127617571835277,
}
-- Total horizontal allowance. The real wedges extend up to .50 studs
-- per side at the authored size of these decks.
local ELEVATED_RIM_OVERHANG = .94
local DIMENSIONS = {
    Rect = {longMin=15.9,longMax=17.4,shortMin=9,shortMax=10.5},
    Long = {longMin=25,longMax=26.4,shortMin=7,shortMax=8.6},
}

local function verified(kind)
    if not APPROVED[kind] then return nil end
    local folder=ReplicatedStorage:FindFirstChild("ApprovedPlatformRimTemplates")
    if not folder or not folder:IsA("Folder")
        or folder.Parent~=ReplicatedStorage
        or folder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=folder:FindFirstChild(kind)
    if not source or not source:IsA("Model") or source.Parent~=folder
        or source:GetAttribute("Original3DAssetId")~=APPROVED[kind]
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalPlatformRim3D")~=true then
        return nil
    end
    local pieces=0
    for _,piece in ipairs(source:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") or piece.CanCollide
                or piece.CanTouch or piece.CanQuery then return nil end
            pieces+=1
        elseif piece:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if pieces~=7 then return nil end
    local _,size=source:GetBoundingBox()
    local long,short=math.max(size.X,size.Z),math.min(size.X,size.Z)
    local spec=DIMENSIONS[kind]
    if long<spec.longMin or long>spec.longMax
        or short<spec.shortMin or short>spec.shortMax
        or size.Y<1.8 or size.Y>2.7 then return nil end
    return source,size
end

-- The original server-backed fallback is a single coherent four-edge
-- group. No partially streamed/unverified wedge may be hidden.
local function nativeParts(decor,deck,original,scale)
    if not decor or not decor:IsA("Folder")
        or not deck or not deck:IsA("BasePart") then return nil end
    local id=deck.Name:match("^Platform(%d+)$")
    if not id then return nil end
    local underside=decor:FindFirstChild("PlatformUnderFrame"..id)
    if not underside or not underside:IsA("BasePart")
        or underside.Parent~=decor or not underside.Anchored
        or underside.CanCollide or underside.CanTouch or underside.CanQuery
        or underside:GetAttribute("PremiumArchitecturalSurface")~=true then
        return nil
    end
    if original and not PlatformIdentityLodRules.matchesUnderdeckFallback(underside,
        deck.CFrame*CFrame.new(0,-deck.Size.Y*.5-.18,0),
        Vector3.new(deck.Size.X+.5*scale,.42,deck.Size.Z+.5*scale), .13, .14) then return nil end
    local edges = {}
    local harborLanding = PlatformIdentityLodRules.harborLandingWidth(deck) ~= nil
    for i=1,4 do
        local edge=decor:FindFirstChild("PlatformBevel"..id.."_"..i)
        if not PlatformIdentityLodRules.isAuthoredPlatformBevel(edge)
            or edge.Parent~=decor or not edge.Anchored
            or edge.CanCollide or edge.CanTouch or edge.CanQuery then
            return nil
        end
        if original then
            local alongX = i<=2
            local side = i%2==1 and -1 or 1
            local depth = math.clamp(math.min(original.X,original.Z)*.075,.28,.65)*scale
            local x = alongX and 0 or side*(deck.Size.X*.5+depth*.27)
            local z = alongX and side*(deck.Size.Z*.5+depth*.27) or 0
            local yaw = alongX and (i==1 and 0 or math.pi)
                or (i==3 and math.pi*.5 or -math.pi*.5)
            local span = (alongX and deck.Size.X or deck.Size.Z) + .12*scale
            local assetId = edge:GetAttribute("Original3DAssetId")
            local reserve = edge:GetAttribute("OriginalHarborLandingTrimReserve3D") == true
            if reserve and not (harborLanding
                and PlatformIdentityLodRules.isHarborLandingTrimReserve(edge)) then return nil end
            local quarterTurn = edge:IsA("MeshPart") and edge.MeshId ~= ""
                and ((assetId == 126298311664881
                        and edge:GetAttribute("OriginalElevatedForgedBevel3D") == true)
                    or (harborLanding and assetId == 94830155055482) or reserve)
            local frame = deck.CFrame*CFrame.new(x,deck.Size.Y*.5-.20,z)*CFrame.Angles(0,yaw,0)
            if not PlatformIdentityLodRules.matchesDeckTrimPose(
                edge,frame,Vector3.new(span,.30,depth),.13,.14,quarterTurn) then
                return nil
            end
        end
        edges[i] = edge
    end
    return edges,underside
end

Kit.nativeParts = nativeParts

local function isElevatedRoute(deck)
    return deck:GetAttribute("PromenadeStep") ~= nil
        or deck:GetAttribute("SkySpineStep") ~= nil
        or deck:GetAttribute("SkySpineInterchange") == true
end

local function routeIndex(value,maximum)
    return typeof(value) == "number" and value % 1 == 0 and value >= 1 and value <= maximum
end

local function isAscensionRoute(deck)
    return deck:GetAttribute("PerimeterStep") ~= nil
        or deck:GetAttribute("BranchStep") ~= nil or deck:GetAttribute("CrosslinkRoute") ~= nil
end

local function ascensionDeckSize(deck)
    local perimeter = deck:GetAttribute("PerimeterStep")
    local branch = deck:GetAttribute("BranchStep")
    local link = deck:GetAttribute("CrosslinkRoute")
    local valid = (routeIndex(perimeter,8) and routeIndex(deck:GetAttribute("PerimeterRoute"),4))
        or (routeIndex(branch,4) and routeIndex(deck:GetAttribute("BranchRoute"),4)
            and deck:GetAttribute("BranchParentStep") == 5)
        or (routeIndex(link,4) and deck:GetAttribute("CrosslinkFromPerimeterStep") == 6
            and deck:GetAttribute("CrosslinkToBranchStep") == 2)
    if not valid or not routeIndex(deck:GetAttribute("RouteTier"),4) then return nil end
    local scale = LargeStructure.liveRouteFloorScale(deck)
    if not scale then return nil end
    local size = deck.Size
    local width = size.X/scale
    if math.abs(size.X-size.Z) > .05 or width < 9.88 or width > 12.12
        or size.Y < 2.92 or size.Y > 37 then return nil end
    return Vector3.new(width,size.Y,width),scale
end

function Kit.routeNatives(decor,deck)
    if not deck or not deck:IsA("BasePart") then return nil end
    local original,scale
    if isElevatedRoute(deck) then
        original,scale = LargeStructure.routeDeckSize(deck)
    elseif isAscensionRoute(deck) then
        original,scale = ascensionDeckSize(deck)
    end
    if not original or not decor or decor ~= deck.Parent.Parent:FindFirstChild("Decor") then return nil end
    return nativeParts(decor,deck,original,scale)
end

local function completeNative(decor,deck)
    if isElevatedRoute(deck) or isAscensionRoute(deck) then
        return Kit.routeNatives(decor,deck) ~= nil
    end
    return nativeParts(decor,deck) ~= nil
end

local function safeDeck(deck,platforms)
    if not deck or not deck:IsA("BasePart")
        or not deck.Name:match("^Platform%d+$")
        or deck.Parent~=platforms or not deck.Anchored
        or not deck.CanCollide or deck.Transparency>=.75
        or deck:GetAttribute("ChaosSkybridge")==true then return false end
    local phase=deck:GetAttribute("CollapsePhase")
    local shutter=deck:GetAttribute("BridgeShutterPhase")
    return (phase==nil or phase=="Normal" or phase=="Safe")
        and (shutter==nil or shutter=="Idle")
end

local function uniformFit(size,bounds)
    local long=math.max(size.X,size.Z)
    local short=math.min(size.X,size.Z)
    local srcLong=math.max(bounds.X,bounds.Z)
    local srcShort=math.min(bounds.X,bounds.Z)
    local scale=math.min(1.12,long*.96/srcLong,short*.96/srcShort)
    local coverLong=srcLong*scale/long
    local coverShort=srcShort*scale/short
    if scale<.60 or coverLong<.90 or coverShort<.87
        or srcLong*scale>long*.97 or srcShort*scale>short*.97
        or bounds.Y*scale>3.05 then return nil end
    local alongZ=size.Z>size.X
    local sourceZ=bounds.Z>bounds.X
    local yaw=sourceZ==alongZ and 0 or math.pi*.5
    return scale,yaw,coverLong*coverShort
end

-- Exact-width fit for the authored Sky Spine and Promenade platforms.
-- Normalize the route before selecting the source so a joining client
-- sees the same fascia at 45% shrink. Vertical relief stays unchanged.
function Kit.fit(deck,bounds)
    if not deck or not deck:IsA("BasePart") or not bounds then return nil end
    if isAscensionRoute(deck) then
        local original,shrink = ascensionDeckSize(deck)
        if not original or math.max(bounds.X,bounds.Z) > 17.4 then return nil end
        -- Keep the lip outside the solid riser, inside the original bevel's
        -- clearance. A shallow fascia stays below the real landing top.
        local width = (original.X + .94)*shrink
        return Vector3.new(width/bounds.X,.82/bounds.Y,width/bounds.Z),0,1
    end
    if not isElevatedRoute(deck) then return uniformFit(deck.Size,bounds) end
    local original,shrink = LargeStructure.routeDeckSize(deck)
    if not original then return nil end
    local long,short = math.max(original.X,original.Z),math.min(original.X,original.Z)
    local srcLong,srcShort = math.max(bounds.X,bounds.Z),math.min(bounds.X,bounds.Z)
    local longScale,shortScale = long*.97/srcLong,short*.97/srcShort
    if longScale < .72 or longScale > 1.50 or shortScale < .95 or shortScale > 1.62
        or math.max(longScale/shortScale,shortScale/longScale) > 1.85 then return nil end
    local heightScale = math.clamp(math.sqrt(longScale*shortScale),.85,1.16)
    local sourceZ = bounds.Z>bounds.X
    local yaw = sourceZ == (original.Z>original.X) and 0 or math.pi*.5
    -- Size the visible outer face to the original bevel envelope. Use
    -- the original proportions above to select the source and its relief.
    local outerLong = (long+ELEVATED_RIM_OVERHANG)*shrink/srcLong
    local outerShort = (short+ELEVATED_RIM_OVERHANG)*shrink/srcShort
    local factors = Vector3.new(sourceZ and outerShort or outerLong,
        heightScale,sourceZ and outerLong or outerShort)
    return factors,yaw,1-math.abs(math.log(longScale/shortScale))
end

local function pickSource(deck,boundsByKind)
    local bestKind,bestScore=nil,-math.huge
    for _,kind in ipairs({"Rect","Long"}) do
        local bounds=boundsByKind[kind]
        if bounds then
            local scale,_,score=Kit.fit(deck,bounds)
            if scale and score>bestScore then
                bestKind,bestScore=kind,score
            end
        end
    end
    return bestKind
end

-- Same camera epoch as PlatformIdentity. Low shares exactly ONE exclusive
-- already-existing hero 3D slot; Medium/High add bounded authentic rims,
-- never one model per platform. Android caps remain far below desktop.
function Kit.selectVisibleDecks(ordered,tier,base,cameraPoint,pressure,
    touch,decor,reservedCarapaces,reservedHulls,cameraLook)
    local result={}
    -- Existing seven-material rims can now finish twelve actual eligible
    -- decks on healthy desktop High (six on Medium), without creating any
    -- extra model, uploader, renderer pass, or mobile residency. Stress
    -- 1 keeps the *old* 4/2 desktop ceilings, even after the healthy
    -- profile increases; touch 2/1 and critical pressure are unchanged.
    local cap=tier=="High" and (touch and 2 or 12)
        or tier=="Medium" and (touch and 1 or 6) or 1
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if stress==1 then
        cap=math.floor(cap*.5)
        if touch~=true then
            cap=math.min(cap,tier=="High" and 4
                or (tier=="Medium" and 2 or 0))
        end
    end
    if stress>=2 or cap<=0 or type(ordered)~="table"
        or not base or not base:IsA("BasePart")
        or not base.Anchored or not base.CanCollide
        or typeof(cameraPoint)~="Vector3"
        or not decor or not decor:IsA("Folder") then return result end
    local localPoint=base.CFrame:PointToObjectSpace(cameraPoint)
    if math.abs(localPoint.X)>base.Size.X*.5+16
        or math.abs(localPoint.Z)>base.Size.Z*.5+16
        or math.abs(localPoint.Y)>130 then return result end
    local range=tier=="Low" and 116
        or tier=="Medium" and (touch and 155 or 230)
        or (touch and 200 or 280)
    -- Authenticate each source ONCE per existing platform-rebuild
    -- epoch instead of repeating Model:GetBoundingBox and scanning all
    -- seven imported MeshParts for every candidate. Installation still
    -- re-authenticates live provenance to catch mid-epoch invalidation.
    local boundsByKind={}
    for _,kind in ipairs({"Rect","Long"}) do
        local source,bounds=verified(kind)
        if source then boundsByKind[kind]=bounds end
    end
    local candidates={}
    local look = if typeof(cameraLook)=="Vector3"
        then Vector3.new(cameraLook.X,0,cameraLook.Z) else Vector3.zero
    if look.Magnitude > .2 then look = look.Unit else look = Vector3.zero end
    local platforms=base.Parent and base.Parent:FindFirstChild("Platforms")
    for _,deck in ipairs(ordered) do
        if safeDeck(deck,platforms)
            and ((tier=="Low" and isAscensionRoute(deck))
                or not (reservedCarapaces and reservedCarapaces[deck]))
            and not (reservedHulls and reservedHulls[deck])
            and completeNative(decor,deck) then
            local delta=deck.Position-cameraPoint
            local distance=delta.Magnitude
            if distance<=range then
                local kind=pickSource(deck,boundsByKind)
                if kind then
                    local planar=Vector3.new(delta.X,0,delta.Z)
                    local behind=planar.Magnitude>28 and planar.Unit:Dot(look)<-.20
                    candidates[#candidates+1]={
                        deck=deck,kind=kind,score=distance+(behind and 65 or 0),
                    }
                end
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.score~=b.score then return a.score<b.score end
        return a.deck.Name<b.deck.Name
    end)
    local count=math.min(#candidates,cap)
    -- Keep the closest original two/three decks fully sculpted, then
    -- distribute the SAME remaining approved 3D slots across authentic
    -- platforms in other visible sectors. Previously all eight High PC
    -- rims could crowd the same walkway while distant foreground-sized
    -- bevels used the standalone server visuals. Touch and GPU-stressed profiles
    -- spend their slots on the best foreground candidates.
    if touch~=true and stress==0 and tier~="Low" and count>2 then
        local foreground=math.min(count,tier=="High" and 3 or 2)
        for i=1,foreground do
            local item=candidates[i]
            result[item.deck]=item.kind
        end
        local selected=foreground
        local spacingCap=math.max(base.Size.X,base.Size.Z)*.65
        while selected<count do
            local winner,winnerScore=nil,-math.huge
            for _,candidate in ipairs(candidates) do
                if result[candidate.deck]==nil then
                    local distance=spacingCap
                    for deck in pairs(result) do
                        local delta=candidate.deck.Position-deck.Position
                        local spread=Vector3.new(delta.X,delta.Y*.65,
                            delta.Z).Magnitude
                        distance=math.min(distance,spread)
                    end
                    -- Retain a strong near-camera bias while spreading
                    -- the finished facades into the same drawable zone.
                    local score=distance-candidate.score*.14
                    if score>winnerScore or (score==winnerScore
                        and winner and candidate.deck.Name
                            <winner.deck.Name) then
                        winner=candidate
                        winnerScore=score
                    end
                end
            end
            if not winner then break end
            result[winner.deck]=winner.kind
            selected+=1
        end
    else
        for i=1,count do
            local item=candidates[i]
            result[item.deck]=item.kind
        end
    end
    return result
end

function Kit.install(parent,deck,index,kind,decor)
    if not parent or not parent:IsA("Folder")
        or not APPROVED[kind] or not deck or not deck:IsA("BasePart")
        or deck.Name~="Platform"..tostring(tonumber(index))
        or not safeDeck(deck,deck.Parent)
        or not completeNative(decor,deck) then return nil end
    local source,bounds=verified(kind)
    if not source then return nil end
    local scale,yaw=Kit.fit(deck,bounds)
    if not scale then return nil end
    local copy=source:Clone()
    if not copy then return nil end
    if type(scale) == "number" and not pcall(function() copy:ScaleTo(scale) end) then
        copy:Destroy()
        return nil
    end
    local frame,size=copy:GetBoundingBox()
    local stretch = if typeof(scale)=="Vector3" then scale else Vector3.one
    size *= stretch
    local ascension = isAscensionRoute(deck)
    local elevated = isElevatedRoute(deck)
    local long,short = math.max(deck.Size.X,deck.Size.Z),math.min(deck.Size.X,deck.Size.Z)
    local longLimit,shortLimit = long*.971,short*.971
    if ascension then
        local _,shrink = ascensionDeckSize(deck)
        if not shrink then copy:Destroy();return nil end
        longLimit,shortLimit = long+.96*shrink,short+.96*shrink
    elseif elevated then
        local _,shrink = LargeStructure.routeDeckSize(deck)
        if not shrink then copy:Destroy();return nil end
        local allowance = (ELEVATED_RIM_OVERHANG+.02)*shrink
        longLimit,shortLimit = long+allowance,short+allowance
    end
    if size.Y<=0 or size.Y>3.05
        or math.max(size.X,size.Z)>longLimit
        or math.min(size.X,size.Z)>shortLimit then
        copy:Destroy()
        return nil
    end
    local target=deck.CFrame*CFrame.new(0,
        deck.Size.Y*.5-((ascension or elevated) and .09 or .17)-size.Y*.5,0)*CFrame.Angles(0,yaw,0)
    local parts={}
    local resizable=tonumber(deck:GetAttribute("RouteTier"))~=nil
    for _,piece in ipairs(copy:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then
                copy:Destroy()
                return nil
            end
            local pose = frame:ToObjectSpace(piece.CFrame)
            if typeof(scale)=="Vector3" then
                -- The seven material meshes share the source frame.
                -- A skewed submesh cannot be fitted by resizing its box.
                local function axis(vector)
                    if math.abs(vector.X)>.9999 then return stretch.X end
                    if math.abs(vector.Y)>.9999 then return stretch.Y end
                    if math.abs(vector.Z)>.9999 then return stretch.Z end
                end
                local x,y,z = axis(pose.RightVector),axis(pose.UpVector),axis(pose.LookVector)
                if not x or not y or not z then copy:Destroy();return nil end
                piece.Size *= Vector3.new(x,y,z)
            end
            piece.CFrame=target*CFrame.new(pose.Position*stretch)*pose.Rotation
            piece.Anchored=false
            piece.Massless=true
            piece.CanCollide=false
            piece.CanTouch=false
            piece.CanQuery=false
            piece.CastShadow=false
            piece:SetAttribute("Original3DStructuralSide",true)
            piece:SetAttribute("OriginalPlatformRim3D",true)
            piece:SetAttribute("Original3DAssetId",APPROVED[kind])
            piece:SetAttribute("ChaosBaseTransparency",piece.Transparency)
            piece:SetAttribute("ChaosPlatformTrim",true)
            piece:SetAttribute("OriginalPlatformRimAxisSwap",
                math.abs(deck.CFrame:VectorToObjectSpace(piece.CFrame.RightVector).Z)>.9999)
            piece:SetAttribute("OriginalElevatedPlatformRim",elevated or nil)
            piece:SetAttribute("OriginalAscensionPlatformRim",ascension or nil)
            local joint=Instance.new(resizable and "Weld" or "WeldConstraint")
            joint.Name="ChaosPlatformTrimWeld"
            joint.Part0=piece
            joint.Part1=deck
            if resizable then
                joint.C0=CFrame.identity
                joint.C1=deck.CFrame:ToObjectSpace(piece.CFrame)
            end
            joint.Parent=piece
            parts[#parts+1]=piece
        elseif piece:IsA("LuaSourceContainer") then
            copy:Destroy()
            return nil
        end
    end
    if #parts~=7 then copy:Destroy();return nil end
    -- The importer has proved the source, fit and all seven welded
    -- MeshParts BEFORE any native becomes invisible in the other owner.
    for i,piece in ipairs(parts) do
        piece.Name="ApprovedPlatformRim"..kind.."3D_"..tostring(i)
        piece.Parent=parent
    end
    copy:Destroy()
    return parts
end

function Kit.isRouteRim(piece)
    return piece:GetAttribute("OriginalElevatedPlatformRim") == true
        or piece:GetAttribute("OriginalAscensionPlatformRim") == true
end

function Kit.sourceOf(piece)
    local id=piece:GetAttribute("Original3DAssetId")
    for kind,asset in pairs(APPROVED) do
        if asset==id then return verified(kind) end
    end
    return nil
end

return Kit
