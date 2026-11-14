-- Approved creator-original 18-stud full underside hull; art-only.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = {}
local APPROVED = 125929150866282

-- The full-size original hull is a better 18-stud focal silhouette
-- than enlarging the much smaller five-arena compact carapaces.
-- The single selected Low mount SHARES its slot with Low carapaces.
local function physicalFit(deck, index, strictSafe)
    local n = tonumber(index)
    if not n or n < 1 or n > 512 or not deck
        or not deck:IsA("BasePart") or not deck.Parent
        or deck.Name ~= "Platform" .. tostring(n)
        or not deck.CanCollide or deck.Transparency >= .75
        or deck:GetAttribute("ChaosSkybridge") == true then return false end
    -- Preserve Medium/High historical eligibility. Low's optional
    -- flagship must not mount onto a collapsing or unanchored deck.
    if strictSafe then
        if not deck.Anchored then return false end
        local phase = deck:GetAttribute("CollapsePhase")
        local shutter = deck:GetAttribute("BridgeShutterPhase")
        if (phase ~= nil and phase ~= "Normal" and phase ~= "Safe")
            or (shutter ~= nil and shutter ~= "Idle") then return false end
    end
    local sx,sz = deck.Size.X,deck.Size.Z
    return math.min(sx,sz)>=16.3 and math.max(sx,sz)<=20
        and math.max(sx,sz)/math.min(sx,sz)<=1.15
end

local function verifiedSource()
    local holder = ReplicatedStorage:FindFirstChild("ApprovedLargeDeckHullTemplates")
    local source = holder and holder:FindFirstChild("LargeDeckHull")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true
        or not source or not source:IsA("Model")
        or source:GetAttribute("Original3DAssetId") ~= APPROVED
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalLargeDeckHull3D") ~= true then return nil end
    local count = 0
    for _, item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return nil end
            count += 1
        elseif item:IsA("LuaSourceContainer") then return nil end
    end
    if count ~= 7 then return nil end
    local _,size = source:GetBoundingBox()
    if size.X<16.5 or size.X>18.4 or size.Z<16.5 or size.Z>18.4
        or size.Y<2.3 or size.Y>4.2 then return nil end
    return source, count, size
end

-- Only the actual five-piece server-authored cosmetic fallback may be
-- substituted. Streamed-in platforms without ALL FOUR WedgeParts cannot
-- reserve expensive seven-MeshPart shells and cannot lose their silhouette.
local function nativeFallback(decor, deck)
    if not decor or not decor:IsA("Folder")
        or not deck or not deck:IsA("BasePart") then return false end
    local id = deck.Name:match("^Platform(%d+)$")
    if not id then return false end
    local frame = decor:FindFirstChild("PlatformUnderFrame" .. id)
    if not frame or not frame:IsA("BasePart")
        or frame.Parent ~= decor or not frame.Anchored
        or frame.CanCollide or frame.CanTouch or frame.CanQuery
        or frame:GetAttribute("PremiumArchitecturalSurface") ~= true then
        return false
    end
    for edge = 1, 4 do
        local bevel = decor:FindFirstChild("PlatformBevel" .. id .. "_" .. edge)
        if not bevel or not bevel:IsA("WedgePart")
            or bevel.Parent ~= decor or not bevel.Anchored
            or bevel.CanCollide or bevel.CanTouch or bevel.CanQuery
            or bevel:GetAttribute("OriginalStructuralBevel") ~= true then
            return false
        end
    end
    return true
end

-- The formerly hard-coded Platform1..24 gate left compatible 18x18
-- decks farther into the arena entirely primitive. Select genuine hull
-- assets by visible physical owner instead of by an arbitrary index.
-- The source is a real existing approved seven-MeshPart 18-stud hull,
-- NOT a new fake WedgePart or a stretched 11-stud side carapace.
-- Medium/High budgets are bounded per rebuild, mobile and GPU pressure
-- cost less; no additional camera sampler, event or gameplay collider.
function Kit.selectVisibleDecks(platforms, tier, base, cameraPoint,
    pressure, touch, decor)
    local chosen = {}
    if tier ~= "Medium" and tier ~= "High" then return chosen end
    local cap = tier == "High" and (touch and 3 or 6)
        or (touch and 1 or 3)
    local stress = math.clamp(math.floor(tonumber(pressure) or 0), 0, 2)
    if stress == 1 then cap = math.floor(cap * .5) end
    if stress >= 2 or type(platforms) ~= "table"
        or not base or not base:IsA("BasePart")
        or not base.Anchored or not base.CanCollide
        or typeof(cameraPoint) ~= "Vector3"
        or not decor or not decor:IsA("Folder") then return chosen end
    local localCamera = base.CFrame:PointToObjectSpace(cameraPoint)
    if math.abs(localCamera.X) > base.Size.X*.5+16
        or math.abs(localCamera.Z) > base.Size.Z*.5+16
        or math.abs(localCamera.Y) > 130 then return chosen end
    local source, count, size = verifiedSource()
    if not source or count ~= 7 then return chosen end
    local range = tier == "High" and (touch and 205 or 290)
        or (touch and 155 or 230)
    local ranked = {}
    for _,deck in ipairs(platforms) do
        local id = deck:IsA("BasePart")
            and tonumber(deck.Name:match("^Platform(%d+)$")) or nil
        if id and physicalFit(deck, id, true)
            and nativeFallback(decor, deck) then
            local scale = math.min(1.08,
                deck.Size.X*.94/size.X, deck.Size.Z*.94/size.Z)
            if scale >= .77
                and size.X*scale <= deck.Size.X*.96
                and size.Z*scale <= deck.Size.Z*.96
                and size.X*scale >= deck.Size.X*.80
                and size.Z*scale >= deck.Size.Z*.80 then
                local distance = (deck.Position-cameraPoint).Magnitude
                if distance <= range then
                    ranked[#ranked+1] = {part=deck, distance=distance}
                end
            end
        end
    end
    table.sort(ranked, function(a,b)
        if a.distance ~= b.distance then
            return a.distance < b.distance
        end
        return a.part.Name < b.part.Name
    end)
    local count=math.min(cap,#ranked)
    -- Healthy desktop: keep the authentic near-camera full underside
    -- shells, then allocate EXISTING remaining slots to separated real
    -- decks on the same visible map. Otherwise six 18-stud approved
    -- hulls cluster into one block while remote compatible underframes
    -- remain primitive. Touch, Low and GPU pressure remain nearest-first.
    if touch~=true and stress==0 and count>=3 then
        local foreground=tier=="High" and math.min(3,count)
            or math.min(2,count)
        for i=1,foreground do chosen[ranked[i].part]=true end
        local taken=foreground
        local spacingCap=math.max(base.Size.X,base.Size.Z)*.65
        while taken<count do
            local winner,winnerScore=nil,-math.huge
            for _,candidate in ipairs(ranked) do
                if not chosen[candidate.part] then
                    local nearest=spacingCap
                    for deck in pairs(chosen) do
                        local delta=candidate.part.Position-deck.Position
                        nearest=math.min(nearest,Vector3.new(
                            delta.X,delta.Y*.65,delta.Z).Magnitude)
                    end
                    local score=nearest-candidate.distance*.14
                    if score>winnerScore or (score==winnerScore
                        and winner and candidate.part.Name
                            <winner.part.Name) then
                        winner=candidate
                        winnerScore=score
                    end
                end
            end
            if not winner then break end
            chosen[winner.part]=true
            taken+=1
        end
    else
        for i=1,count do chosen[ranked[i].part]=true end
    end
    return chosen
end

-- Only the ONE camera-near, fully safe, already Low-decorated
-- 18x18-ish PlatformN can spend the existing seven-MeshPart Low shell
-- slot. Reuses the arena-rebuild camera snapshot, not a new sampler.
function Kit.selectLowDeck(platforms, base, cameraPoint, pressure, decor)
    if (tonumber(pressure) or 0) > 0
        or type(platforms) ~= "table"
        or not base or not base:IsA("BasePart")
        or typeof(cameraPoint) ~= "Vector3" then return nil end
    local localCamera = base.CFrame:PointToObjectSpace(cameraPoint)
    if math.abs(localCamera.X) > base.Size.X*.5+16
        or math.abs(localCamera.Z) > base.Size.Z*.5+16
        or math.abs(localCamera.Y) > 130 then return nil end
    local source, count, size = verifiedSource()
    if not source or count ~= 7 then return nil end
    local best,bestDistance=nil,125
    for _,deck in ipairs(platforms) do
        local id = deck:IsA("BasePart")
            and tonumber(deck.Name:match("^Platform(%d+)$")) or nil
        if id and physicalFit(deck,id,true)
            and (decor == nil or nativeFallback(decor,deck)) then
            local scale = math.min(1.08,
                deck.Size.X*.94/size.X,deck.Size.Z*.94/size.Z)
            if scale >= .77
                and size.X*scale >= deck.Size.X*.80
                and size.Z*scale >= deck.Size.Z*.80
                and size.X*scale <= deck.Size.X*.96
                and size.Z*scale <= deck.Size.Z*.96 then
                local distance=(deck.Position-cameraPoint).Magnitude
                if distance < bestDistance
                    or (distance == bestDistance and best
                        and id < tonumber(best.Name:match("%d+$"))) then
                    best,bestDistance=deck,distance
                end
            end
        end
    end
    return best
end

function Kit.install(parent, deck, tier, index, selected, decor)
    local n = tonumber(index)
    if tier == "Low" and selected ~= true then return nil end
    -- Existing external callers retain legacy 1..24 access only.
    -- The live owner explicitly passes FALSE for every non-selected
    -- Medium/High deck, so lifting the index gate cannot stamp 100 hulls.
    if tier ~= "Low" and selected == false then return nil end
    if selected ~= true and (not n or n > 24) then return nil end
    if not parent or not physicalFit(deck, index, selected == true)
        or (decor ~= nil and not nativeFallback(decor, deck)) then
        return nil
    end
    local source,count,size = verifiedSource()
    if not source or count ~= 7 then return nil end
    local sx,sy,sz=deck.Size.X,deck.Size.Y,deck.Size.Z
    local scale = math.min(1.08,sx*.94/size.X,sz*.94/size.Z)
    -- Selection is only a snapshot: a deck can shrink or a source can
    -- change before installation. Revalidate both axes at mount time.
    if scale < .77
        or size.X*scale < sx*.80 or size.Z*scale < sz*.80
        or size.X*scale > sx*.96 or size.Z*scale > sz*.96 then
        return nil
    end
    local copy = source:Clone()
    if not pcall(function() copy:ScaleTo(scale) end) then
        copy:Destroy()
        return nil
    end
    local frame,bounds = copy:GetBoundingBox()
    if bounds.X > sx*.96 or bounds.Z > sz*.96
        or bounds.X < sx*.80 or bounds.Z < sz*.80
        or bounds.Y > 4.6 or bounds.Y <= 0 then
        copy:Destroy()
        return nil
    end
    local target=deck.CFrame*CFrame.new(0,sy*.5-.12-bounds.Y*.5,0)
    local pieces={}
    for _,obj in ipairs(copy:GetDescendants()) do
        if obj:IsA("MeshPart") then
            obj.CFrame=target*frame:ToObjectSpace(obj.CFrame)
            obj.Anchored=false
            obj.Massless=true
            obj.CanCollide=false
            obj.CanTouch=false
            obj.CanQuery=false
            obj.CastShadow=false
            obj:SetAttribute("ChaosBaseTransparency",obj.Transparency)
            obj:SetAttribute("ChaosPlatformTrim",true)
            obj:SetAttribute("Original3DStructuralSide",true)
            obj:SetAttribute("OriginalLargeDeckHull",true)
            obj:SetAttribute("Original3DAssetId",APPROVED)
            local resizable=tonumber(deck:GetAttribute("RouteTier"))~=nil
            local joint=Instance.new(resizable and "Weld" or "WeldConstraint")
            joint.Name="ChaosPlatformTrimWeld"
            joint.Part0=obj
            joint.Part1=deck
            if resizable then
                joint.C0=CFrame.identity
                joint.C1=deck.CFrame:ToObjectSpace(obj.CFrame)
            end
            joint.Parent=obj
            pieces[#pieces+1]=obj
        end
    end
    if #pieces~=count then copy:Destroy();return nil end
    for i,obj in ipairs(pieces) do
        obj.Name="OriginalApprovedLargeDeckHull3D_"..tostring(i)
        obj.Parent=parent
    end
    copy:Destroy()
    return pieces
end
return Kit
