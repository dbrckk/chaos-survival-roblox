-- Approved creator-original 18-stud full underside hull; art-only.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = {}
local APPROVED = 125929150866282

-- The full-size original hull is a better 18-stud focal silhouette
-- than enlarging the much smaller five-arena compact carapaces.
-- The single selected Low mount SHARES its slot with Low carapaces.
local function physicalFit(deck, index)
    local n = tonumber(index)
    if not n or n < 1 or n > 24 or not deck
        or not deck:IsA("BasePart") or not deck.Parent
        or not deck.Anchored or not deck.CanCollide
        or deck.Transparency >= .75
        or deck:GetAttribute("ChaosSkybridge") == true then return false end
    local phase = deck:GetAttribute("CollapsePhase")
    local shutter = deck:GetAttribute("BridgeShutterPhase")
    if (phase ~= nil and phase ~= "Normal" and phase ~= "Safe")
        or (shutter ~= nil and shutter ~= "Idle") then return false end
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
    if count<1 or count>12 then return nil end
    local _,size = source:GetBoundingBox()
    if size.X<16.5 or size.X>18.4 or size.Z<16.5 or size.Z>18.4
        or size.Y<2.3 or size.Y>4.2 then return nil end
    return source, count, size
end

-- Only the ONE camera-near, fully safe, already Low-decorated
-- 18x18-ish PlatformN can spend the existing seven-MeshPart Low shell
-- slot. Reuses the arena-rebuild camera snapshot, not a new sampler.
function Kit.selectLowDeck(platforms, base, cameraPoint, pressure)
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
        if id and id%8==1 and physicalFit(deck,id) then
            local scale = math.min(1.08,
                deck.Size.X*.94/size.X,deck.Size.Z*.94/size.Z)
            if scale >= .77 then
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

function Kit.install(parent, deck, tier, index, selectedLow)
    if tier == "Low" and (selectedLow ~= true
        or tonumber(index)%8 ~= 1) then return nil end
    if not parent or not physicalFit(deck, index) then return nil end
    local source,count,size = verifiedSource()
    if not source or (tier == "Low" and count ~= 7) then return nil end
    local sx,sy,sz=deck.Size.X,deck.Size.Y,deck.Size.Z
    local scale = math.min(1.08,sx*.94/size.X,sz*.94/size.Z)
    if scale<.77 then return nil end
    local copy = source:Clone()
    if not pcall(function() copy:ScaleTo(scale) end) then
        copy:Destroy()
        return nil
    end
    local frame,bounds = copy:GetBoundingBox()
    if bounds.X>sx*.96 or bounds.Z>sz*.96 or bounds.Y>4.6
        or bounds.Y<=0 then copy:Destroy();return nil end
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
