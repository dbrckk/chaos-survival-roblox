-- Original approved cosmetic geometry for perimeter ascension arches,
-- casing ornaments, Orbital helix underframes and promenade equipment.
-- Real colliders/route lights/warnings remain server-owned, never masked.
-- Exactly ONE existing scenery-lod sampler owns source residency. Event
-- callbacks are only for genuine streaming / shrink / collapse changes.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Kit={}
local SOURCE={
    Access={id=110243423264048,major=17.6,minor=3.9,height=17.53,centerY=6.855},
    Transfer={id=107273631120961,major=17.6,minor=4.1,height=18.33,centerY=7.255},
    Summit={id=127049813505254,major=17.6,minor=5.2,height=19.73,centerY=7.955},
    Casing={id=130196548599769,major=8.58,minor=5.3,height=10.378,centerY=1.1492},
    Helix={id=106863534763803,major=23.6,minor=5.08,height=1.453,centerY=-.97125},
    Crosshead={id=108452611210970,major=8.94,minor=1.12,height=.5675,
        centerY=0,holder="ApprovedPerimeterStructuresTemplates",
        template="Brace",tag="OriginalPerimeterStructure3D"},
    Stay={id=122766792774607,major=9.62,minor=.6175,height=1.505,
        centerY=0,holder="ApprovedPlatformSideTemplates",
        template="Bridge",tag="OriginalStructuralSide3D"},
}
local EQUIPMENT={
    Classic={
        name="PromenadeClassic",
        source={id=108954400662606,major=2,minor=1.625,height=3.712,centerY=0,
            holder="ApprovedServiceEquipmentTemplates",template="Classic",tag="OriginalService3D"},
        natives={
            {name="SurveyDish",size=Vector3.new(5.5,.70,5.5),x=0,y=1.2,roll=18},
            {name="SurveyMast",size=Vector3.new(.52,5,.52),x=0,y=4},
            {name="SurveyTip",size=Vector3.new(1.8,1.8,1.8),x=0,y=6.3},
        },
        size=Vector3.new(4.1,6.72,5.15),y=3.86,
    },
    Towers={
        name="PromenadeTowers",
        source={id=106083832432833,major=3.08,minor=2.6351,height=2.32,centerY=0,
            holder="ApprovedServiceEquipmentTemplates",template="Towers",tag="OriginalService3D"},
        natives={{name="HoistMachine",size=Vector3.new(7.2,3.5,4.2),x=0,y=2}},
        size=Vector3.new(4.1,3.4,7.08),y=2,
    },
    Crossroads={
        name="PromenadeCrossroads",
        source={id=90844491148907,major=27.92,minor=2.74,height=3.6,centerY=0,
            holder="ApprovedCrossroadsGantryTemplates",template="Gantry",tag="OriginalCrossroadsGantry3D"},
        natives={
            {name="SignalConcourse",size=Vector3.new(10.8,2.1,3),x=0,y=1.45},
            {name="SwitchFin-1",size=Vector3.new(4.9,1.4,.8),x=-6.1,y=3,roll=-24,wedge=true},
            {name="SwitchFin1",size=Vector3.new(4.9,1.4,.8),x=6.1,y=3,roll=24,wedge=true},
        },
        size=Vector3.new(2.9,4.08,16.2),y=2.53,
    },
    Orbital={
        name="PromenadeOrbital",
        source={id=104654294187035,major=4.36,minor=4.36,height=4.36,centerY=0,
            holder="ApprovedOrbitalReactorLandmarkTemplates",template="Node",tag="OriginalOrbitalReactorLandmark3D"},
        natives={{name="GyroCore",size=Vector3.new(4.2,4.2,4.2),x=0,y=3.3}},
        size=Vector3.new(4.12,4.12,4.12),y=3.3,
    },
}
local PROMENADE_VARIANTS={Classic=true,Towers=true,Crossroads=true,Orbital=true}
local CROSSHEAD_SPAN={[2]=18.4,[4]=19.6,[7]=21.2}
local CROSSHEAD_RISE={[2]=13.25,[4]=14.5,[7]=16.2}
-- Source Z becomes the height along the tilted native stay. The open
-- web faces up the walkway, within the native support's cross-section.
local STAY_AXES=CFrame.fromMatrix(Vector3.zero, -Vector3.xAxis,
    Vector3.zAxis, Vector3.yAxis)
-- Stay budget counts complete pairs (14 parts), not individual sides.
local STAY_ANGLE=math.rad(16)
local STAY_DISTANCE={Medium=150,High=265}
local STAY_BUDGET={Medium=2,High=6}
local EQUIPMENT_DISTANCE={Low=110,Medium=155,High=235}
local EQUIPMENT_BUDGET={Low=1,Medium=3,High=6}
local EQUIPMENT_TOUCH_CAP={Low=1,Medium=1,High=2}
local SIDES={-1,1}
local STAGE={[1]="Access",[4]="Transfer",[8]="Summit"}
-- Desktop-only extra creator-approved sculptures. The authenticated real
-- platform/casing/ramp and source dimensions still decide actual mounts.
-- No new assets, physical Parts, import requests or sampling loops.
-- Four genuine perimeter routes each author ACCESS, TRANSFER and SUMMIT:
-- twelve eligible physical arch owners maximum per fully resident map.
-- Healthy desktop Medium can finish eight original arch silhouettes, High
-- can finish all twelve. No import, extra LOD tick or new native geometry.
-- Mobile/touch and GPU-pressure-1/2 caps remain explicitly unchanged.
local BUDGET={
    Low={arch=1,casing=1,helix=0,promenade=1},
    Medium={arch=8,casing=4,helix=4,promenade=3},
    High={arch=12,casing=4,helix=8,promenade=6},
}
-- Preserve EXACT former GPU-pressure-1 ceilings even when healthy desktop
-- rendering is promoted: active hazards must retain their old relief path.
local PRESSURE_CAP={
    Low={arch=0,casing=0,helix=0,promenade=0},
    Medium={arch=1,casing=1,helix=1,promenade=1},
    High={arch=3,casing=2,helix=3,promenade=2},
}
local TOUCH_CAP={
    Low={arch=1,casing=1,helix=0,promenade=1},
    Medium={arch=2,casing=1,helix=1,promenade=2},
    High={arch=3,casing=2,helix=3,promenade=3},
}
local DISTANCE={
    Low={arch=135,casing=115,helix=0,promenade=118},
    Medium={arch=215,casing=180,helix=170,promenade=195},
    High={arch=325,casing=275,helix=265,promenade=280},
}
local ARCH_NATIVE={
    -- Five upper volumes are genuinely occluded by the authored canopy.
    -- Keep BOTH deep abutments and lower keel/girder server-native: these
    -- decks have variable genuine thickness 3 / 13.8 / 28.2 studs; the
    -- approved seven-MeshPart roof sculpture does not span to the bottom
    -- of all three floors, and masking their lower support would leave
    -- the high SUMMIT platform looking dangerously unsupported.
    "VerticalBridgePylon-1","VerticalBridgePylon1",
    "TaperedFin-1","TaperedFin1","MonumentalOverpass",
}
local CASING_NATIVE={
    "FoundationFoot","ArmoredFrontShell","ArmoredRearShell",
    "AngledArmorFin-1","AngledArmorFin1",
    "DiagonalLoadSpar-1","DiagonalLoadSpar1",
    "MachinedUpperCollar","RecessedCrown",
    "AerialCantilever-1","AerialCantilever1",
}
local HELIX_NATIVE={
    "Underframe_-1","Underframe_1","SpineBrace_-1","SpineBrace_1",
}
local folder=Instance.new("Folder")
folder.Name="ApprovedRemainingStructureMeshesLocal"
folder:SetAttribute("CosmeticOnly",true)
folder.Parent=workspace
local activeArena=nil
local mounted={}
local baseWatch=nil
local baseSignal=nil

local function realFloorScale(arena)
    local map=workspace:FindFirstChild("GeneratedMap")
    if not arena or arena.Name~="Arena" or not map or arena.Parent~=map then
        return nil
    end
    local base=arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") or base.Parent~=arena
        or not base.Anchored or not base.CanCollide then return nil end
    local x,z=base:GetAttribute("OriginalSizeX"),base:GetAttribute("OriginalSizeZ")
    if typeof(x)~="number" or typeof(z)~="number"
        or x~=x or z~=z or x<318 or z<318
        or x>=math.huge or z>=math.huge then return nil end
    local sx,sz=base.Size.X/x,base.Size.Z/z
    if sx<.445 or sx>1.005 or sz<.445 or sz>1.005
        or math.abs(sx-sz)>.012 then return nil end
    return (sx+sz)*.5
end

local function sourceFor(name,spec)
    spec=spec or SOURCE[name]
    local templates=ReplicatedStorage:FindFirstChild(
        spec.holder or "ApprovedRemainingStructureTemplates")
    if not templates or not templates:IsA("Folder")
        or templates.Parent~=ReplicatedStorage
        or templates:GetAttribute("OwnerVerified")~=true then return nil end
    local model=templates:FindFirstChild(spec.template or name)
    if not model or not model:IsA("Model") or model.Parent~=templates
        or model:GetAttribute("Original3DAssetId")~=spec.id
        or model:GetAttribute(spec.tag or "P4OriginalRemainingStructure3D")~=true
        or model:GetAttribute("OwnerVerified")~=true
        or model:GetAttribute("CosmeticOnly")~=true then return nil end
    local count=0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or not part.Anchored
                or part.CanCollide or part.CanTouch or part.CanQuery
                or not part.Massless then return nil end
            count+=1
        elseif part:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count~=7 then return nil end
    local _,b=model:GetBoundingBox()
    local portico=spec.holder~=nil
    if math.abs(math.max(b.X,b.Z)-spec.major)>(portico and .30 or .75)
        or math.abs(math.min(b.X,b.Z)-spec.minor)>(portico and .22 or .75)
        or math.abs(b.Y-spec.height)>(portico and .16 or .8) then return nil end
    return model
end

local function visualNative(part,parent)
    return part and part:IsA("BasePart") and part.Parent==parent
        and part.Anchored and not part.CanCollide
        and not part.CanTouch and not part.CanQuery
        and part.Transparency<.95
end

local function collectArch(arena,deck,decor,scale)
    if not deck:IsA("BasePart") or not deck.Name:match("^Platform%d+$")
        or deck.Parent~=arena:FindFirstChild("Platforms")
        or deck:GetAttribute("PerimeterRoute")==nil
        -- SUMMIT (stage eight) is intentionally collapsible; require a
        -- genuine collidable staged PerimeterRoute, NOT PermanentRoute.
        or type(deck:GetAttribute("RouteTier"))~="number"
        or not deck.Anchored or not deck.CanCollide
        or deck.Transparency>=.75 then return nil end
    local step=deck:GetAttribute("PerimeterStep")
    local key=STAGE[step]
    local route=deck:GetAttribute("PerimeterRoute")
    -- The real builder has four signed physical routes. Decline a fake
    -- or half-replicated owner instead of spending approved art on it.
    if not key or type(route)~="number" or route%1~=0
        or route<1 or route>4 then return nil end
    local size=deck.Size
    -- A base-first shrink packet must NEVER make an old full-width imported
    -- arch appear over a now smaller real physical escape deck.
    local height=step==1 and 3 or 6.6+(step-2)*3.6
    local sourceWidth=step==1 and 12 or (step==4 and 11.6 or 10)
    -- Actual MapBuilder perimeter decks have real collider heights
    -- 3, 13.8 and 28.2 studs. Reject fake or half-streamed footprints,
    -- but never assume every playable deck is a 2-stud Roblox slab.
    if math.abs(size.Y-height)>.14
        or math.abs(size.Z/scale-sourceWidth)>.32
        or math.abs(size.X/scale-sourceWidth)>.32 then return nil end
    local phase=deck:GetAttribute("CollapsePhase")
    if phase~=nil and phase~="Normal" and phase~="Safe" then return nil end
    local shutter=deck:GetAttribute("BridgeShutterPhase")
    if shutter~=nil and shutter~="Idle" then return nil end
    local index=tonumber(deck.Name:match("%d+"))
    local originals={}
    for _,suffix in ipairs(ARCH_NATIVE) do
        local part=decor:FindFirstChild("SkyRouteMonument"..index.."_"..suffix)
        if not visualNative(part,decor)
            or part:GetAttribute("SkyRouteMonument")~=true
            or part:GetAttribute("SkyRouteStage")~=key:upper()
            or part:GetAttribute("PerimeterPlatformIndex")~=index then
            return nil
        end
        originals[#originals+1]=part
    end
    -- The SOURCE overpass must have reached the current genuine resized
    -- deck; otherwise we are in the server Base-before-Decor replication gap.
    local overpass=originals[5]
    local extra=step==8 and 9 or 6.6
    local expected=(size.Z/scale+extra)*scale
    if math.abs(overpass.Size.Z-expected)>.36 then return nil end
    local rise=step==8 and 14 or (step==4 and 12.9 or 12.1)
    local expectedPos=(deck.CFrame*CFrame.new(0,size.Y*.5+rise,0)).Position
    if (overpass.Position-expectedPos).Magnitude>.45 then return nil end
    return {category="arch",name=key,owner=deck,arena=arena,
        originals=originals,center=deck.Position,
        -- The approved arch stands ON the actual top of the thick
        -- collidable platform; its source upper crosshead is +1 above
        -- the native overpass offset. Deep lower steel stays native.
        orientation=deck.CFrame*CFrame.new(0,size.Y*.5-1,0),
        scaleZ=overpass.Size.Z/17.6,
        stage=step,route=route,index=index,expectedParent=decor}
end

local function porticoStep(arena,deck,scale)
    if not PROMENADE_VARIANTS[arena:GetAttribute("VariantId")]
        or not deck:IsA("BasePart") or deck.Parent~=arena:FindFirstChild("Platforms")
        or deck:GetAttribute("ChaosPermanentRoute")~=true
        or deck:GetAttribute("RouteTier")~=4
        or not deck.Anchored or not deck.CanCollide or deck.Transparency>=.75
        or math.abs(deck.Size.Z/scale-12)>.22 or math.abs(deck.Size.Y-2)>.12 then
        return nil
    end
    local fullLength=deck.Size.X/scale
    if fullLength<=14.6 or fullLength>=29.6 then return nil end
    local lane=deck:GetAttribute("PromenadeLane")
    local step=deck:GetAttribute("PromenadeStep")
    if not deck.Name:match("^Platform%d+$") or not CROSSHEAD_SPAN[step]
        or (lane~=1 and lane~=2) then return nil end
    local collapse=deck:GetAttribute("CollapsePhase")
    if collapse~=nil and collapse~="Normal" and collapse~="Safe" then return nil end
    local shutter=deck:GetAttribute("BridgeShutterPhase")
    if shutter~=nil and shutter~="Idle" then return nil end

    return step
end

local function promenadeNative(decor,index,suffix,wedge)
    local native=decor:FindFirstChild("Promenade"..index..suffix)
    if not visualNative(native,decor)
        or native:GetAttribute("PromenadeVisualOnly")~=true
        or native:GetAttribute("PerimeterPlatformIndex")~=tonumber(index) then
        return nil
    end
    if wedge then
        if not native:IsA("WedgePart") then return nil end
    elseif not native:IsA("Part") or native.Shape~=Enum.PartType.Block then
        return nil
    end
    return native
end

local function collectPorticoPart(arena,deck,decor,scale,side)
    local step=porticoStep(arena,deck,scale)
    if not step then return nil end
    local index=deck.Name:match("^Platform(%d+)$")
    local suffix=side and "_DiagonalStay"..side or "_MonumentalCrosshead"
    local native=promenadeNative(decor,index,suffix)
    if not native then return nil end
    local size=native.Size
    local rise=CROSSHEAD_RISE[step]
    local span=CROSSHEAD_SPAN[step]
    if side then
        local expected=deck.CFrame*CFrame.new(0,deck.Size.Y*.5+rise*.66,
            side*8.3*scale)*CFrame.Angles(side*STAY_ANGLE,0,0)
        if math.abs(size.X-.65*scale)>.045 or math.abs(size.Y-rise*.55)>.06
            or math.abs(size.Z-1.1*scale)>.055
            or (expected.Position-native.Position).Magnitude>.16
            or expected.LookVector:Dot(native.CFrame.LookVector)<.999
            or expected.UpVector:Dot(native.CFrame.UpVector)<.999 then return nil end
        local depth=size.Z*.94
        -- Shrink narrows the route but preserves native vertical length.
        -- Shorten the tilted girder just enough to keep its inside corner
        -- outboard of the walkable edge. Preserve native art if too short.
        local maxHalfSpan=((8.3-6)*scale-depth*.5*math.cos(STAY_ANGLE)-.025)
            /math.sin(STAY_ANGLE)
        local length=math.min(size.Y*.985,maxHalfSpan*2)
        if length<size.Y*.70 then return nil end
        return {category="stay",name="Stay",owner=deck,key=native,side=side,arena=arena,
            originals={native},center=deck.Position,orientation=native.CFrame*STAY_AXES,
            fitSize=Vector3.new(size.X*.94,depth,length),expectedParent=decor}
    end
    local expected=deck.CFrame*CFrame.new(0,deck.Size.Y*.5+rise,0)
    if math.abs(size.X-4*scale)>.10 or math.abs(size.Y-1.2)>.06
        or math.abs(size.Z-span*scale)>.18
        or (expected.Position-native.Position).Magnitude>.16
        or expected.LookVector:Dot(native.CFrame.LookVector)<.999
        or expected.UpVector:Dot(native.CFrame.UpVector)<.999 then return nil end
    return {category="promenade",name="Crosshead",owner=deck,arena=arena,
        originals={native},center=native.Position,orientation=native.CFrame,
        fitSize=Vector3.new(size.X*.85,size.Y*.975,size.Z*.98),expectedParent=decor}
end

local function collectStayPair(arena,deck,decor,scale)
    local pair={}
    for _,side in ipairs(SIDES) do
        local stay=collectPorticoPart(arena,deck,decor,scale,side)
        if not stay then return nil end
        pair[#pair+1]=stay
    end
    -- Require both exact native instances to stay resident before either
    -- mask remains authorized. This also handles asynchronous shrink.
    for _,stay in ipairs(pair) do
        stay.other=pair[stay.side<0 and 2 or 1].key
    end
    return pair
end

local function collectEquipment(arena,deck,decor,scale,equipment)
    -- Authenticate the actual crosshead and its complete, correctly
    -- streamed equipment before erecting any local art above the route.
    local crosshead=collectPorticoPart(arena,deck,decor,scale)
    if not crosshead then return nil end
    local index=deck.Name:match("^Platform(%d+)$")
    local natives={}
    for _,spec in ipairs(equipment.natives) do
        local native=promenadeNative(decor,index,"_"..spec.name,spec.wedge)
        local expected=crosshead.orientation*CFrame.new(spec.x*scale,spec.y,0)
            *CFrame.Angles(0,0,math.rad(spec.roll or 0))
        local size=spec.size
        if not native or (native.Size-Vector3.new(size.X*scale,size.Y,size.Z*scale)).Magnitude>.10
            or (native.Position-expected.Position).Magnitude>.15
            or native.CFrame.UpVector:Dot(expected.UpVector)<.999
            or native.CFrame.LookVector:Dot(expected.LookVector)<.999 then return nil end
        natives[#natives+1]=native
    end
    -- The long dimension of each roof source runs along the real deck X
    -- axis. The common importer correction handles source X/Z swaps.
    local size=equipment.size
    return {category="equipment",name=equipment.name,spec=equipment.source,
        owner=deck,key=natives[1],
        arena=arena,originals=natives,anchor=crosshead.originals[1],
        center=natives[1].Position,orientation=crosshead.orientation
            *CFrame.new(0,equipment.y,0)*CFrame.Angles(0,-math.pi*.5,0),
        fitSize=Vector3.new(size.X*scale,size.Y,size.Z*scale),expectedParent=decor}
end

local function collectCasing(arena,casing,group)
    if not casing:IsA("Model") or casing.Parent~=group
        or casing:GetAttribute("OriginalFrameCladding")~=true
        or casing:GetAttribute("SourceIsOriginal")~=true
        or casing:GetAttribute("CosmeticOnly")~=true then return nil end
    local index=casing:GetAttribute("FrameColumnIndex")
    local variant=arena:GetAttribute("VariantId")
    if type(index)~="number" or index%1~=0 or index<1 or index>4
        or casing.Name~=tostring(variant).."ArchitecturalCasing"..index then
        return nil
    end
    local natives={}
    for _,suffix in ipairs(CASING_NATIVE) do
        local part=casing:FindFirstChild(suffix)
        if not visualNative(part,casing) then return nil end
        natives[#natives+1]=part
    end
    local foot=natives[1]
    if foot.Size.X<5.3 or foot.Size.X>5.7 or
        foot.Size.Z<5.3 or foot.Size.Z>5.7 then return nil end
    local origin=foot.CFrame*CFrame.new(0,3.55,0)
    return {category="casing",name="Casing",owner=casing,arena=arena,
        originals=natives,center=foot.Position,orientation=origin,
        scaleZ=1,expectedParent=casing}
end

local function collectHelix(arena,ramp,circuit)
    if arena:GetAttribute("VariantId")~="Orbital"
        or not ramp:IsA("BasePart") or ramp.Parent~=circuit
        or ramp:GetAttribute("OrbitalHelixRamp")~=true
        or not ramp.Name:match("^HelixRamp%d+$")
        or not ramp.Anchored or not ramp.CanCollide
        or ramp.Transparency>=.75 then return nil end
    local index=ramp:GetAttribute("HelixLane")
    if type(index)~="number" or index%1~=0
        or index<1 or index>8
        or ramp.Name~="HelixRamp"..index
        or ramp:GetAttribute("OrbitRouteGroup")~="Helix"..index
        or ramp.Size.X<4.9 or ramp.Size.X>5.9
        or ramp.Size.Z<6.5 or ramp.Size.Z>65
        or ramp.Size.Y<.8 or ramp.Size.Y>1.1 then return nil end
    local names={
        "HelixUnderframe"..index.."_-1",
        "HelixUnderframe"..index.."_1",
        "HelixSpineBrace"..index.."_-1",
        "HelixSpineBrace"..index.."_1",
    }
    local originals={}
    for _,name in ipairs(names) do
        local part=circuit:FindFirstChild(name)
        if not visualNative(part,circuit)
            or part:GetAttribute("HelixLane")~=index
            or part:GetAttribute("OrbitRouteGroup")~="Helix"..index then
            return nil
        end
        originals[#originals+1]=part
    end
    -- Native linear underframes are length-tracked by OrbitalHelix.scale.
    -- Refuse a partial replication tick before masking either underframe.
    for j=1,2 do
        if math.abs(originals[j].Size.Z-(ramp.Size.Z-.7))>.40 then
            return nil
        end
    end
    return {category="helix",name="Helix",owner=ramp,arena=arena,
        originals=originals,center=ramp.Position,
        orientation=ramp.CFrame,
        scaleX=ramp.Size.X/5.4,scaleZ=ramp.Size.Z/24.0,
        expectedParent=circuit,index=index}
end

local function isPortico(category)
    return category=="promenade" or category=="stay" or category=="equipment"
end

local function reveal(entry)
    for _,n in ipairs(entry.native) do
        if (n.part.Parent==entry.expectedParent
            or (isPortico(entry.category) and entry.visible))
            and n.part.LocalTransparencyModifier==1 then
            n.part.LocalTransparencyModifier=n.alpha
        end
    end
    for _,piece in ipairs(entry.pieces) do
        if piece.part.Parent then
            piece.part.LocalTransparencyModifier=1
        end
    end
    entry.visible=false
end

local function sourceIntact(entry)
    local spec=entry.spec
    if entry.disposing or entry.corrupt or not entry.model
        or entry.model.Parent~=folder
        or not entry.source or entry.source.Parent~=entry.sourceFolder
        or entry.sourceFolder.Parent~=ReplicatedStorage
        or entry.sourceFolder:GetAttribute("OwnerVerified")~=true
        or entry.source:GetAttribute("OwnerVerified")~=true
        or entry.source:GetAttribute(spec.tag or "P4OriginalRemainingStructure3D")~=true
        or entry.source:GetAttribute("CosmeticOnly")~=true
        or entry.source:GetAttribute("Original3DAssetId")
            ~= spec.id
        or not entry.pieces or #entry.pieces~=7 then return false end
    -- A streamed-in eighth mesh, stray Part or injected script must NEVER
    -- survive hidden inside a supposedly approved seven-piece sculpture.
    local actual=0
    for _,child in ipairs(entry.model:GetDescendants()) do
        if child:IsA("BasePart") then
            if not child:IsA("MeshPart") then return false end
            actual+=1
        elseif child:IsA("LuaSourceContainer") then
            return false
        end
    end
    if actual~=7 then return false end
    -- Check the *source* as well as its resident clone. A streamed-out
    -- material region, new unapproved part or Lua code invalidates the
    -- imported original without waiting for the next camera sample.
    local sourceCount=0
    for _,child in ipairs(entry.source:GetDescendants()) do
        if child:IsA("BasePart") then
            if not child:IsA("MeshPart") or not child.Anchored
                or not child.Massless or child.CanCollide
                or child.CanTouch or child.CanQuery then return false end
            sourceCount+=1
        elseif child:IsA("LuaSourceContainer") then
            return false
        end
    end
    if sourceCount~=7 then return false end
    for _,p in ipairs(entry.pieces) do
        if not p.part:IsA("MeshPart")
            or not p.part:IsDescendantOf(entry.model)
            or not p.part.Anchored or not p.part.Massless
            or p.part.CanCollide or p.part.CanTouch or p.part.CanQuery
            or not p.frame or not p.size then return false end
    end
    return true
end

local function sameOriginals(entry,data)
    if data.anchor~=entry.anchor or data.expectedParent~=entry.expectedParent
        or #data.originals~=#entry.native then return false end
    for i,native in ipairs(data.originals) do
        if entry.native[i].part~=native then return false end
    end
    return true
end

local function refresh(entry)
    if entry.disposing then return end
    local scale=realFloorScale(entry.arena)
    local data=nil
    if scale and sourceIntact(entry) then
        if entry.category=="arch" or isPortico(entry.category) then
            local decor=entry.arena:FindFirstChild("Decor")
            if decor==entry.expectedParent then
                if entry.category=="arch" then
                    data=collectArch(entry.arena,entry.owner,decor,scale)
                elseif entry.category=="equipment" then
                    local equipment=EQUIPMENT[entry.arena:GetAttribute("VariantId")]
                    if equipment then
                        data=collectEquipment(entry.arena,entry.owner,decor,scale,equipment)
                    end
                elseif entry.side then
                    local pair=collectStayPair(entry.arena,entry.owner,decor,scale)
                    data=pair and pair[entry.side<0 and 1 or 2]
                    local other=mounted[entry.other]
                    if data and (data.other~=entry.other or not other
                        or other.other~=entry.native[1].part or not sourceIntact(other)) then
                        data=nil
                    end
                else
                    data=collectPorticoPart(entry.arena,entry.owner,decor,scale)
                end
            end
        elseif entry.category=="casing" then
            local group=entry.arena:FindFirstChild("Decor")
            group=group and group:FindFirstChild("OriginalPremiumColumnCladding")
            if group and entry.owner.Parent==group then
                data=collectCasing(entry.arena,entry.owner,group)
            end
        else
            local circuit=entry.arena:FindFirstChild("HelixCircuit")
            if circuit==entry.expectedParent then
                data=collectHelix(entry.arena,entry.owner,circuit)
            end
        end
    end
    if not data or data.name~=entry.name or not sameOriginals(entry,data) then
        reveal(entry)
        return false
    end
    local rule=entry.spec
    local sx,sy,sz=data.scaleX or 1,1,data.scaleZ or 1
    if data.fitSize then
        local size,bounds=data.fitSize,entry.bounds
        sx=size.X/math.min(bounds.X,bounds.Z)
        sy=size.Y/bounds.Y
        sz=size.Z/math.max(bounds.X,bounds.Z)
    elseif sx<.35 or sx>1.45 or sz<.35 or sz>2.4 then
        reveal(entry)
        return false
    end
    local ax,az=sx,sz
    if entry.longX then ax,az=sz,sx end
    local aim=data.orientation*CFrame.new(0,rule.centerY,0)
        * CFrame.Angles(0,entry.longX and math.pi*.5 or 0,0)
    local fitChanged=data.fitSize~=entry.lastFitSize or aim~=entry.lastFitFrame
    for _,piece in ipairs(entry.pieces) do
        if not data.fitSize or fitChanged then
            local p=piece.frame.Position
            local rotation=piece.frame-p
            piece.part.Size=Vector3.new(
                math.max(.025,piece.size.X*ax),math.max(.025,piece.size.Y*sy),
                math.max(.025,piece.size.Z*az))
            piece.part.CFrame=aim*CFrame.new(p.X*ax,p.Y*sy,p.Z*az)*rotation
        end
        piece.part.LocalTransparencyModifier=0
    end
    if data.fitSize then
        entry.lastFitSize=data.fitSize
        entry.lastFitFrame=aim
    end
    for _,n in ipairs(entry.native) do
        if n.part.Parent==entry.expectedParent then
            n.part.LocalTransparencyModifier=1
        end
    end
    entry.visible=true
    return true
end

local function dispose(entry)
    if entry.disposing then return end
    entry.disposing=true
    reveal(entry)
    for _,c in ipairs(entry.connections) do c:Disconnect() end
    if entry.model then entry.model:Destroy() end
end

local function clear()
    for owner,entry in pairs(mounted) do
        mounted[owner]=nil
        dispose(entry)
    end
    if baseSignal then baseSignal:Disconnect();baseSignal=nil end
    baseWatch=nil
end

folder.ChildRemoved:Connect(function(child)
    if not child:IsA("Model") then return end
    for owner,entry in pairs(mounted) do
        if entry.model==child and not entry.disposing then
            mounted[owner]=nil
            dispose(entry)
            local other=entry.other and mounted[entry.other]
            if other then refresh(other) end
        end
    end
end)

local function mount(data,source)
    local clone=source:Clone()
    local cf,b=clone:GetBoundingBox()
    local entry={category=data.category,name=data.name,spec=data.spec or SOURCE[data.name],
        owner=data.owner,side=data.side,other=data.other,arena=data.arena,
        source=source,sourceFolder=source.Parent,
        expectedParent=data.expectedParent,anchor=data.anchor,
        native={},model=clone,pieces={},connections={},bounds=b,
        -- Architectural casings have an intentional X-wide front: rotating
        -- that source to Z would put the machined service front on a SIDE.
        -- Route owners may need Roblox import's X/Z axis swap corrected.
        longX=data.category~="casing" and b.X>b.Z,
        visible=false,disposing=false}
    for _,native in ipairs(data.originals) do
        entry.native[#entry.native+1]={
            part=native,alpha=native.LocalTransparencyModifier}
    end
    for _,piece in ipairs(clone:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then clone:Destroy();return nil end
            entry.pieces[#entry.pieces+1]={
                part=piece,frame=cf:ToObjectSpace(piece.CFrame),size=piece.Size}
            piece.Anchored=true
            piece.Massless=true
            piece.CanCollide=false
            piece.CanTouch=false
            piece.CanQuery=false
            piece.CastShadow=false
            piece.LocalTransparencyModifier=1
        end
    end
    if #entry.pieces~=7 then clone:Destroy();return nil end
    clone.Name="ApprovedP4_"..data.name
    -- Observability only: identical approved Access models may serve four
    -- distinct routes. Bind diagnostics and stream-loss proof to the
    -- ACTUAL server-owned platform instead of the first same-named clone.
    clone:SetAttribute("OriginalP4OwnerPlatform",data.owner.Name)
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("P4OriginalRemainingStructure3D",true)
    clone:SetAttribute("Original3DAssetId",entry.spec.id)
    clone.Parent=folder
    local function changed()
        refresh(entry)
        local other=entry.other and mounted[entry.other]
        if other then refresh(other) end
    end
    local function watch(o,properties)
        entry.connections[#entry.connections+1]=o.AncestryChanged:Connect(changed)
        for _,name in ipairs(properties) do
            entry.connections[#entry.connections+1]=
                o:GetPropertyChangedSignal(name):Connect(changed)
        end
    end
    if data.owner:IsA("BasePart") then
        watch(data.owner,{"CFrame","Size","Transparency","CanCollide","Anchored"})
    else
        -- Real authored ArchitecturalCasing owners are MODELS, which do
        -- not implement CFrame/Size/Transparency property-changed signals.
        -- Their eleven actual BasePart descendants below own all geometry
        -- events; watch only Model ancestry here.
        entry.connections[#entry.connections+1]=
            data.owner.AncestryChanged:Connect(changed)
    end
    if data.category=="arch" or isPortico(data.category) then
        -- A collapsing/shutter warning takes precedence over decorative
        -- art IMMEDIATELY, not after the next 0.65-second scenery sample.
        entry.connections[#entry.connections+1]=
            data.owner:GetAttributeChangedSignal("CollapsePhase"):Connect(changed)
        entry.connections[#entry.connections+1]=
            data.owner:GetAttributeChangedSignal("BridgeShutterPhase"):Connect(changed)
    end
    if isPortico(data.category) then
        for _,attribute in ipairs({"PromenadeLane","PromenadeStep",
            "ChaosPermanentRoute","RouteTier"}) do
            entry.connections[#entry.connections+1]=
                data.owner:GetAttributeChangedSignal(attribute):Connect(changed)
        end
    end
    local function watchPorticoNative(native)
        watch(native,{"CFrame","Size","Transparency","Anchored",
            "CanCollide","CanTouch","CanQuery","Name"})
        if native:IsA("Part") then
            entry.connections[#entry.connections+1]=
                native:GetPropertyChangedSignal("Shape"):Connect(changed)
        end
        for _,attribute in ipairs({"PromenadeVisualOnly","PerimeterPlatformIndex"}) do
            entry.connections[#entry.connections+1]=
                native:GetAttributeChangedSignal(attribute):Connect(changed)
        end
    end
    for _,native in ipairs(data.originals) do
        if isPortico(data.category) then
            watchPorticoNative(native)
        else
            watch(native,{"CFrame","Size","Transparency"})
        end
    end
    if data.anchor then watchPorticoNative(data.anchor) end
    entry.connections[#entry.connections+1]=
        source.AncestryChanged:Connect(changed)
    entry.connections[#entry.connections+1]=
        source.DescendantRemoving:Connect(function(child)
            if (child:IsA("BasePart") or child:IsA("LuaSourceContainer"))
                and not entry.disposing then
                task.defer(function()
                    if not entry.disposing then changed() end
                end)
            end
        end)
    entry.connections[#entry.connections+1]=
        source.DescendantAdded:Connect(function(child)
            if (child:IsA("BasePart") or child:IsA("LuaSourceContainer"))
                and not entry.disposing then
                task.defer(function()
                    if not entry.disposing then changed() end
                end)
            end
        end)
    entry.connections[#entry.connections+1]=
        clone.DescendantRemoving:Connect(function(child)
            if child:IsA("MeshPart") and not entry.disposing then
                task.defer(function()
                    if not entry.disposing then changed() end
                end)
            end
        end)
    entry.connections[#entry.connections+1]=
        clone.DescendantAdded:Connect(function(child)
            if not entry.disposing and (child:IsA("BasePart")
                or child:IsA("LuaSourceContainer")) then
                -- Reject extra geometry immediately, BEFORE the next
                -- camera sampler. A foreign Part cannot add a collider.
                entry.corrupt=true
                if child:IsA("BasePart") then
                    child.Anchored=true
                    child.CanCollide=false
                    child.CanTouch=false
                    child.CanQuery=false
                    child.LocalTransparencyModifier=1
                end
                changed()
            end
        end)
    if not entry.other then refresh(entry) end
    return entry
end

local function caps(tier,touch,pressure,kind)
    if kind=="stay" then
        local cap=STAY_BUDGET[tier] or 0
        if (tonumber(pressure) or 0)>=1 then return 0 end
        return touch==true and math.min(cap,1) or cap
    end
    if kind=="equipment" then
        if (tonumber(pressure) or 0)>=1 then return 0 end
        return (touch==true and EQUIPMENT_TOUCH_CAP or EQUIPMENT_BUDGET)[tier] or 0
    end
    local t=BUDGET[tier] or BUDGET.Low
    local cap=t[kind] or 0
    if touch==true then
        cap=math.min(cap,(TOUCH_CAP[tier] or TOUCH_CAP.Low)[kind] or 0)
    end
    local p=tonumber(pressure) or 0
    if p~=p then p=0 end
    p=math.clamp(math.floor(p),0,2)
    if p==2 then return 0 end
    if p==1 then
        local prior=(PRESSURE_CAP[tier] or PRESSURE_CAP.Low)[kind] or 0
        return math.min(math.floor(cap*.5),prior)
    end
    return cap
end
Kit.budget=caps

local function score(data,cameraPoint,cameraLook,existing)
    local v=data.center-cameraPoint
    local d=v.Magnitude
    local n=d
    if typeof(cameraLook)=="Vector3" and cameraLook.Magnitude>.5 and d>20 then
        n-=math.min(35,d*.20)*v.Unit:Dot(cameraLook.Unit)
    end
    if existing then n-=18 end
    return n,d
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,cameraLook,pressure,touch)
    if arena~=activeArena then
        clear()
        activeArena=arena
    end
    if not arena or not cameraReady or
        typeof(cameraPoint)~="Vector3" then
        clear();return
    end
    local scale=realFloorScale(arena)
    if not scale then clear();return end
    local base=arena:FindFirstChild("Base")
    if baseWatch~=base then
        if baseSignal then baseSignal:Disconnect() end
        baseWatch=base
        baseSignal=base:GetPropertyChangedSignal("Size"):Connect(function()
            for _,entry in pairs(mounted) do refresh(entry) end
        end)
    end
    -- Recheck approved templates on the existing camera pass, with no
    -- permanent trusted cache across eviction or streaming.
    local src={}
    local variant=arena:GetAttribute("VariantId")
    local promenadeVariant=PROMENADE_VARIANTS[variant]
    for name in pairs(SOURCE) do
        local kind=name=="Crosshead" and "promenade" or (name=="Stay" and "stay")
        if not kind or (promenadeVariant and caps(tier,touch,pressure,kind)>0) then
            src[name]=sourceFor(name)
        end
    end
    local equipment=EQUIPMENT[variant]
    if equipment and caps(tier,touch,pressure,"equipment")>0 then
        src[equipment.name]=sourceFor(equipment.name,equipment.source)
    end
    local desired={}
    local candidates={arch={},casing={},helix={},promenade={},stay={},equipment={}}
    local decor=arena:FindFirstChild("Decor")
    local platforms=arena:FindFirstChild("Platforms")
    if decor and decor:IsA("Folder")
        and platforms and platforms:IsA("Folder") then
        for _,deck in ipairs(platforms:GetChildren()) do
            local data=collectArch(arena,deck,decor,scale)
            if not data and src.Crosshead and deck:GetAttribute("PromenadeStep") then
                data=collectPorticoPart(arena,deck,decor,scale)
            end
            if src.Stay and deck:GetAttribute("PromenadeStep") then
                local pair=collectStayPair(arena,deck,decor,scale)
                if pair then
                    local stay=pair[1]
                    local resident=mounted[stay.key]~=nil and mounted[pair[2].key]~=nil
                    local priority,distance=score(stay,cameraPoint,cameraLook,resident)
                    if distance<=STAY_DISTANCE[tier]+(resident and 18 or 0) then
                        stay.priority=priority
                        stay.pair=pair
                        candidates.stay[#candidates.stay+1]=stay
                    end
                end
            end
            if equipment and src[equipment.name] and deck:GetAttribute("PromenadeStep") then
                local gear=collectEquipment(arena,deck,decor,scale,equipment)
                if gear then
                    local resident=mounted[gear.key]~=nil
                    local priority,distance=score(gear,cameraPoint,cameraLook,resident)
                    if distance<=EQUIPMENT_DISTANCE[tier]+(resident and 18 or 0) then
                        gear.priority=priority
                        candidates.equipment[#candidates.equipment+1]=gear
                    end
                end
            end
            if data and src[data.name] then
                local priority,distance=score(data,cameraPoint,cameraLook,
                    mounted[deck]~=nil)
                if distance<=(DISTANCE[tier] or DISTANCE.Low)[data.category]+
                    (mounted[deck] and 22 or 0) then
                    data.priority=priority
                    local pool=candidates[data.category]
                    pool[#pool+1]=data
                end
            end
        end
    end
    local group=decor and decor:FindFirstChild("OriginalPremiumColumnCladding")
    if group and group:IsA("Folder") and src.Casing then
        for _,casing in ipairs(group:GetChildren()) do
            local data=collectCasing(arena,casing,group)
            if data then
                local priority,distance=score(data,cameraPoint,cameraLook,
                    mounted[casing]~=nil)
                if distance<=(DISTANCE[tier] or DISTANCE.Low).casing+
                    (mounted[casing] and 20 or 0) then
                    data.priority=priority
                    candidates.casing[#candidates.casing+1]=data
                end
            end
        end
    end
    local circuit=arena:FindFirstChild("HelixCircuit")
    if circuit and circuit:IsA("Folder") and src.Helix
        and caps(tier,touch,pressure,"helix")>0 then
        for _,ramp in ipairs(circuit:GetChildren()) do
            local data=collectHelix(arena,ramp,circuit)
            if data then
                local priority,distance=score(data,cameraPoint,cameraLook,
                    mounted[ramp]~=nil)
                if distance<=(DISTANCE[tier] or DISTANCE.Low).helix+
                    (mounted[ramp] and 18 or 0) then
                    data.priority=priority
                    candidates.helix[#candidates.helix+1]=data
                end
            end
        end
    end
    for _,kind in ipairs({"arch","casing","helix","promenade","stay","equipment"}) do
        table.sort(candidates[kind],function(a,b)
            if a.priority~=b.priority then return a.priority<b.priority end
            return a.owner.Name<b.owner.Name
        end)
        local cap=caps(tier,touch,pressure,kind)
        local taken=0
        -- Healthy DESKTOP Medium/High: distribute only existing approved
        -- source modules over four real escape routes first, then reserve
        -- one true TRANSFER and SUMMIT when available. Low/touch/pressure
        -- keep the previous distance-ranked proximity/stage behavior.
        -- No native lower-support or signal may be suppressed by this.
        if kind=="arch" and (tier=="High" or tier=="Medium") and touch~=true
            and (tonumber(pressure) or 0)<1 and cap>=4 then
            local routes={}
            for _,data in ipairs(candidates.arch) do
                if taken>=cap then break end
                if not routes[data.route] then
                    routes[data.route]=true
                    desired[data.owner]=data
                    taken+=1
                end
            end
            -- The approved sculptors made THREE distinct silhouettes;
            -- camera-only ranking could otherwise use every slot on ACCESS.
            -- After giving each real route one owner, prioritize one
            -- TRANSFER and one SUMMIT arch, provided those genuine decks
            -- and their exact source templates are safely available.
            for _,stage in ipairs({4,8}) do
                if taken>=cap then break end
                for _,data in ipairs(candidates.arch) do
                    if data.stage==stage and not desired[data.owner] then
                        desired[data.owner]=data
                        taken+=1
                        break
                    end
                end
            end
        elseif kind=="arch" and cap>=2
            and (tonumber(pressure) or 0)<1 then
            -- On Android Medium/High, filling all slots by
            -- proximity can repeat ACCESS on one route while approved
            -- TRANSFER/SUMMIT sculptures nearby never appear. Preserve
            -- the nearest arch; use remaining SAME-budget slots for
            -- distinct sculpted stages and real escape routes. Never
            -- sacrifice close foreground for a far, barely visible arch.
            local nearest=candidates.arch[1]
            local boundary=candidates.arch[math.min(cap,#candidates.arch)]
            if nearest and boundary then
                local ceiling=boundary.priority+60
                local stages={}
                local routes={}
                local function claim(data)
                    desired[data.owner]=data
                    stages[data.stage]=true
                    routes[data.route]=true
                    taken+=1
                end
                claim(nearest)
                for _,stage in ipairs({8,4,1}) do
                    if taken>=cap then break end
                    if not stages[stage] then
                        local first=nil
                        for _,data in ipairs(candidates.arch) do
                            if data.stage==stage and not desired[data.owner]
                                and data.priority<=ceiling then
                                if not first then first=data end
                                if not routes[data.route] then
                                    first=data
                                    break
                                end
                            end
                        end
                        if first then claim(first) end
                    end
                end
                for _,data in ipairs(candidates.arch) do
                    if taken>=cap then break end
                    if not routes[data.route] and data.priority<=ceiling then
                        claim(data)
                    end
                end
            end
        end
        for _,data in ipairs(candidates[kind]) do
            if taken>=cap then break end
            local key=data.key or data.owner
            if not desired[key] then
                if data.pair then
                    for _,side in ipairs(data.pair) do desired[side.key]=side end
                else
                    desired[key]=data
                end
                taken+=1
            end
        end
    end
    for owner,entry in pairs(mounted) do
        local data=desired[owner]
        if not data or data.name~=entry.name
            or data.category~=entry.category or data.arena~=entry.arena
            or src[entry.name]~=entry.source
            or (isPortico(entry.category) and not sameOriginals(entry,data))
            or not sourceIntact(entry) then
            -- A streamed/lost local MeshPart is not a valid seven-piece
            -- sculpture. refresh() already restores the real native trim;
            -- discard its broken clone and remount only from the currently
            -- verified creator-owned source on this SAME existing LOD pass.
            -- Without this check a partial clone stayed mounted forever,
            -- keeping its authentic source slot but never recovering 3D.
            mounted[owner]=nil
            dispose(entry)
        end
    end
    for owner,data in pairs(desired) do
        local entry=mounted[owner]
        if not entry then
            entry=mount(data,src[data.name])
            if entry then mounted[owner]=entry end
        end
    end
    for _,entry in pairs(mounted) do refresh(entry) end
end

function Kit.count(category)
    local count=0
    for _,entry in pairs(mounted) do
        if entry.visible and sourceIntact(entry)
            and (category==nil or category==entry.category) then
            count+=1
        end
    end
    return count
end

function Kit.nativeCount(category)
    local count=0
    for _,entry in pairs(mounted) do
        if entry.visible and sourceIntact(entry)
            and (category==nil or category==entry.category) then
            count+=#entry.native
        end
    end
    return count
end

return Kit
