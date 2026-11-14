-- True creator-approved seven-MeshPart perimeter sculptures for real
-- rectangular / long playable platforms. Replaces the FOUR server
-- WedgePart bevels only AFTER a complete authentic model is welded.
-- NO new colliders, new update loop, fake MeshId or primitive fallback.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = {}

local APPROVED = {
    Rect = 131482590870627,
    Long = 127617571835277,
}
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
local function completeNative(decor,deck)
    if not decor or not decor:IsA("Folder")
        or not deck or not deck:IsA("BasePart") then return false end
    local id=deck.Name:match("^Platform(%d+)$")
    if not id then return false end
    local underside=decor:FindFirstChild("PlatformUnderFrame"..id)
    if not underside or not underside:IsA("BasePart")
        or underside.Parent~=decor or not underside.Anchored
        or underside.CanCollide or underside.CanTouch or underside.CanQuery
        or underside:GetAttribute("PremiumArchitecturalSurface")~=true then
        return false
    end
    for i=1,4 do
        local edge=decor:FindFirstChild("PlatformBevel"..id.."_"..i)
        if not edge or not edge:IsA("WedgePart")
            or edge.Parent~=decor or not edge.Anchored
            or edge.CanCollide or edge.CanTouch or edge.CanQuery
            or edge:GetAttribute("OriginalStructuralBevel")~=true then
            return false
        end
    end
    return true
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

-- Only rim shapes that convincingly COVER their matching native four
-- edges qualify. No anisotropic rescaling and no miniature 11-stud art
-- stretched to a 28-stud platform.
function Kit.fit(deck,bounds)
    if not deck or not bounds then return nil end
    local long=math.max(deck.Size.X,deck.Size.Z)
    local short=math.min(deck.Size.X,deck.Size.Z)
    local srcLong=math.max(bounds.X,bounds.Z)
    local srcShort=math.min(bounds.X,bounds.Z)
    local scale=math.min(1.12,long*.96/srcLong,short*.96/srcShort)
    local coverLong=srcLong*scale/long
    local coverShort=srcShort*scale/short
    if scale<.60 or coverLong<.90 or coverShort<.87
        or srcLong*scale>long*.97 or srcShort*scale>short*.97
        or bounds.Y*scale>3.05 then return nil end
    local alongZ=deck.Size.Z>deck.Size.X
    local sourceZ=bounds.Z>bounds.X
    local yaw=sourceZ==alongZ and 0 or math.pi*.5
    return scale,yaw,coverLong*coverShort
end

local function pickSource(deck)
    local bestKind,bestScore=nil,-math.huge
    for _,kind in ipairs({"Rect","Long"}) do
        local source,bounds=verified(kind)
        if source then
            local scale,yaw,score=Kit.fit(deck,bounds)
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
    touch,decor,reservedCarapaces,reservedHulls)
    local result={}
    local cap=tier=="High" and (touch and 2 or 8)
        or tier=="Medium" and (touch and 1 or 4) or 1
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if stress==1 then cap=math.floor(cap*.5) end
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
    local candidates={}
    local platforms=base.Parent and base.Parent:FindFirstChild("Platforms")
    for _,deck in ipairs(ordered) do
        if safeDeck(deck,platforms)
            and not (reservedCarapaces and reservedCarapaces[deck])
            and not (reservedHulls and reservedHulls[deck])
            and completeNative(decor,deck) then
            local distance=(deck.Position-cameraPoint).Magnitude
            if distance<=range then
                local kind=pickSource(deck)
                if kind then
                    candidates[#candidates+1]={
                        deck=deck,kind=kind,score=distance,
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
    -- WedgePart bevels stayed primitive. No extra models, renderer passes
    -- or unverified geometry; touch and GPU-stressed selection are exact
    -- nearest-first as before.
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
    if not pcall(function() copy:ScaleTo(scale) end) then
        copy:Destroy()
        return nil
    end
    local frame,size=copy:GetBoundingBox()
    if size.Y<=0 or size.Y>3.05
        or math.max(size.X,size.Z)>math.max(deck.Size.X,deck.Size.Z)*.97
        or math.min(size.X,size.Z)>math.min(deck.Size.X,deck.Size.Z)*.97 then
        copy:Destroy()
        return nil
    end
    local target=deck.CFrame*CFrame.new(0,
        deck.Size.Y*.5-.17-size.Y*.5,0)*CFrame.Angles(0,yaw,0)
    local parts={}
    local resizable=tonumber(deck:GetAttribute("RouteTier"))~=nil
    for _,piece in ipairs(copy:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then
                copy:Destroy()
                return nil
            end
            piece.CFrame=target*frame:ToObjectSpace(piece.CFrame)
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
            piece:SetAttribute("OriginalPlatformRimAxisSwap",yaw~=0)
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

return Kit
