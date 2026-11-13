-- Roblox creator-owned original modular ring 3D contract. The existing
-- premium skybridge package is an OPEN structural truss, not a solid
-- scaled tower or a new marketplace asset. No gameplay physics.
local Ring=if script and script.Parent
    then require(script.Parent.CinematicDepthLayoutRules)
    else require("./CinematicDepthLayoutRules")
local Rules={}
Rules.ASSET_ID=94023662427980
Rules.MODULES_PER_SITE=4
Rules.COUNT=14
Rules.SOURCE_NAME="PremiumSkybridgeModule"
Rules.SOURCE_FOLDER="PremiumRouteMeshTemplates"
Rules.LOCAL_FOLDER="OriginalOrbitalHaloTrussesLocal"

local CAP={
    Low={0,0,0},
    Medium={2,1,0},
    High={5,2,0},
}
local HIGH_TOUCH={3,1,0}
function Rules.capacity(tier,pressure,isTouch)
    local profile=CAP[tier]
    if not profile then return 0 end
    local n=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if tier=="High" and isTouch then profile=HIGH_TOUCH end
    return profile[n+1]
end
function Rules.position(base,index)
    local angle=Ring.angle("OrbitalHalo",index)
    if not angle or typeof(base)~="Instance"
        or not base:IsA("BasePart") then return nil end
    local sx=base:GetAttribute("OriginalSizeX")
    local sz=base:GetAttribute("OriginalSizeZ")
    -- An untagged Base can still be used by old source-level preview
    -- builders before MapBuilder attributes are replicated; a tagged
    -- Base must never revert to live dimensions when its tag is invalid.
    if sx==nil and sz==nil then
        sx,sz=base.Size.X,base.Size.Z
    end
    if typeof(sx)~="number" or typeof(sz)~="number"
        or sx~=sx or sz~=sz or sx<318 or sz<318
        or sx==math.huge or sz==math.huge
        or base.Size.X<=0 or base.Size.Z<=0
        or base.Size.X>sx+.2 or base.Size.Z>sz+.2 then
        return nil
    end
    local radius=math.max(sx,sz)*.5+78
    return base.CFrame:PointToWorldSpace(Vector3.new(
        math.cos(angle)*radius,
        34+math.sin(angle*2)*5,
        math.sin(angle)*radius))
end
function Rules.isNative(part,folder,base,index)
    if typeof(part)~="Instance" or not part:IsA("Part")
        or typeof(folder)~="Instance" or not folder:IsA("Folder")
        or part.Parent~=folder or not Ring.angle("OrbitalHalo",index)
        or part.Name~="CinemaOrbitalHalo"..index
        or not part.Anchored or part.CanCollide
        or part.CanTouch or part.CanQuery
        or part.Shape~=Enum.PartType.Block
        or part:GetAttribute("CosmeticOnly")~=true
        or part:GetAttribute("OriginalCinematicHaloIndex")~=index
        or (part.Size-Vector3.new(34,1.5,3.6)).Magnitude>.04
    then return false end
    local expected=Rules.position(base,index)
    return expected~=nil and (part.Position-expected).Magnitude<.25
end
function Rules.fit(sourceSize)
    if typeof(sourceSize)~="Vector3" then return nil end
    local long=math.max(sourceSize.X,sourceSize.Z)
    local short=math.min(sourceSize.X,sourceSize.Z)
    if long<9 or long>11.5 or short<4 or short>5.6
        or sourceSize.Y<1 or sourceSize.Y>2.3 then return nil end
    local scale=math.min(1.08,8.25/long,1.43/sourceSize.Y,
        3.35/short)
    if scale<.48 or long*scale<4.7 then return nil end
    local yaw=if sourceSize.Z>sourceSize.X then math.pi*.5 else 0
    return scale,yaw
end
function Rules.moduleOffset(moduleIndex)
    if type(moduleIndex)~="number" or moduleIndex~=math.floor(moduleIndex)
        or moduleIndex<1 or moduleIndex>Rules.MODULES_PER_SITE then
        return nil end
    return (moduleIndex-(Rules.MODULES_PER_SITE+1)*.5)*8.45
end
return Rules
