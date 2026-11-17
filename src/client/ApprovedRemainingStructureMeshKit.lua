-- Original approved cosmetic geometry for perimeter ascension arches,
-- casing ornaments, Orbital helix underframes and promenade equipment.
-- Real colliders/route lights/warnings remain server-owned, never masked.
-- Exactly ONE existing scenery-lod sampler owns source residency. Event
-- callbacks are only for genuine streaming / shrink / collapse changes.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Trim=if script and script.Parent
    and script.Parent:FindFirstChild("PlatformNativeTrimReplacementKit")
    then require(script.Parent.PlatformNativeTrimReplacementKit)
    else require("./PlatformNativeTrimReplacementKit")
local LargeStructure=if script and script.Parent and script.Parent:FindFirstChild("PremiumLargeStructureMeshKit")
    then require(script.Parent.PremiumLargeStructureMeshKit)
    else require("./PremiumLargeStructureMeshKit")
local Crown=if script and script.Parent and script.Parent:FindFirstChild("SkySpineCrownMeshKit")
    then require(script.Parent.SkySpineCrownMeshKit)
    else require("./SkySpineCrownMeshKit")
local HarborHoist=if script and script.Parent and script.Parent:FindFirstChild("HarborPromenadeHoistArt")
    then require(script.Parent.HarborPromenadeHoistArt)
    else require("./HarborPromenadeHoistArt")
local shared=ReplicatedStorage:FindFirstChild("Shared")
local connectionModule=shared and shared:FindFirstChild("SkyRouteConnectionRules")
local Connection=if connectionModule then require(connectionModule)
    else require("../shared/SkyRouteConnectionRules")
local Kit={}
local SOURCE={
    Access={id=110243423264048,major=17.6,minor=3.9,height=17.53,centerY=6.855},
    Transfer={id=107273631120961,major=17.6,minor=4.1,height=18.33,centerY=7.255},
    Summit={id=127049813505254,major=17.6,minor=5.2,height=19.73,centerY=7.955},
    Casing={id=130196548599769,major=8.58,minor=5.3,height=10.378,centerY=0},
    Helix={id=106863534763803,major=23.6,minor=5.08,height=1.453,centerY=-.97125},
    AccessChassis={id=106401955318567,major=12.8,minor=5.17,height=.5065,
        centerY=0,heightTolerance=.09},
    Crosshead={id=108452611210970,major=8.94,minor=1.12,height=.5675,
        centerY=0,holder="ApprovedPerimeterStructuresTemplates",
        template="Brace",tag="OriginalPerimeterStructure3D"},
    JunctionTruss={id=108452611210970,major=8.94,minor=1.12,height=.5675,
        centerY=0,holder="ApprovedPerimeterStructuresTemplates",
        template="Brace",tag="OriginalPerimeterStructure3D"},
    ArchAbutment={id=88962643359267,major=2.7699,minor=2.34,height=2.14,
        centerY=0,holder="ApprovedPerimeterArmorTemplates",
        template="Cap",tag="OriginalPerimeterArmor3D"},
    ArchGirder={id=122766792774607,major=9.62,minor=.6175,height=1.505,
        centerY=0,holder="ApprovedPlatformSideTemplates",
        template="Bridge",tag="OriginalStructuralSide3D"},
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
    Harbor={
        name="PromenadeHarbor",
        source={id=75684193304551,major=44,minor=21.86,height=36.08949,centerY=0,
            holder="ApprovedHarborKineticGantryTemplates",template="ContainerGantry",
            tag="OriginalHarborKineticGantry3D"},
        natives={
            {name="FreightHoistArm",size=Vector3.new(16.8,1.6,2.3),x=1,y=1.9},
            {name="SuspendedCrate",size=Vector3.new(4.2,3.8,4.2),x=8.1,y=-2.3,z=-4},
            {name="CargoChain",size=Vector3.new(.3,3.2,.3),x=8.1,y=.8,z=-4},
        },
    },
}
local FITTING_SOURCE={
    Rail={id=138666009076890,major=8.46,minor=1.10,height=1.24,centerY=0,
        holder="ApprovedOrbitalReactorLandmarkTemplates",
        template="Strut",tag="OriginalOrbitalReactorLandmark3D"},
    Beacon={id=88962643359267,major=2.7699,minor=2.34,height=2.14,centerY=0,
        holder="ApprovedPerimeterArmorTemplates",
        template="Cap",tag="OriginalPerimeterArmor3D"},
    Fin={id=123049626693705,major=5.46,minor=1.76,height=15.92,centerY=0,
        holder="ApprovedClassicBroadcastFinTemplates",
        template="BroadcastFin",tag="OriginalClassicBroadcastFin3D"},
}
local VERTICAL_FITTING=CFrame.fromMatrix(Vector3.zero,Vector3.zAxis,
    Vector3.xAxis,Vector3.yAxis)
local ROOF_FITTINGS={
    Towers={
        {name="HoistRail",source="Rail",size=Vector3.new(.6,5,.6),
            x=4.2,y=3.8,axes=VERTICAL_FITTING,vertical=true,
            fitSize=Vector3.new(.56,.56,4.92)},
        {name="HoistBeacon",source="Beacon",size=Vector3.new(2.2,.55,2),
            x=0,y=4.2,axes=CFrame.Angles(0,-math.pi*.5,0),
            fitSize=Vector3.new(1.94,.53,2.14)},
    },
    Orbital={
        {name="ContainmentFin-1",source="Fin",size=Vector3.new(.9,5.5,3.2),
            x=-4.4,y=2.8,roll=-18,wedge=true,axes=CFrame.identity,
            fitSize=Vector3.new(.86,5.39,3.12)},
        {name="ContainmentFin1",source="Fin",size=Vector3.new(.9,5.5,3.2),
            x=4.4,y=2.8,roll=18,wedge=true,axes=CFrame.identity,
            fitSize=Vector3.new(.86,5.39,3.12)},
    },
}
-- These approved add-ons occupy the space above the common gateway crown.
-- Heights are measured from the actual physical deck's top.
local COMMAND_ART={
    Classic={{name="CommandOptics",source=EQUIPMENT.Classic.source,
        fit=Vector3.new(4.3,5.3,5.2),y=22.22,natives={
            {name="CommandRadar",shape=Enum.PartType.Cylinder,
                size=Vector3.new(.8,6.8,6.8),y=17,roll=24},
            {name="SurveyBeacon",size=Vector3.new(1.7,2.2,1.7),y=18.1,z=-.35},
        }}},
    Towers={
        {name="CommandBridge",
            source={id=126298311664881,major=40.64,minor=6.77,height=4.87784,centerY=0,
                holder="ApprovedTowersSignatureBridgeTemplates",
                template="ForgedBridge",tag="OriginalTowersSignatureBridge3D"},
            fit=Vector3.new(3.82,2.22,13.9),y=24.1,natives={
                {name="CargoOverpass",size=Vector3.new(14,2.2,3.7),y=17.3},
            }},
        {name="CommandCabin",
            source={id=72210530094580,major=2.455,minor=2.449,height=5.005,centerY=0,
                holder="ApprovedAmbientMotionTemplates",
                template="Towers",tag="ApprovedAmbientMotion3D"},
            fit=Vector3.new(3.18,3.55,3.76),y=21.28,natives={
                {name="HangingTransitCabin",size=Vector3.new(3.8,3.8,3.2),y=14},
            }},
    },
    Crossroads={{name="CommandConcourse",source=EQUIPMENT.Crossroads.source,
        fit=Vector3.new(2.66,3.55,14.3),y=21.3,natives={
            {name="RoutingAileron-1",size=Vector3.new(6.8,2.1,1),x=-4.1,y=16.8,roll=-26,wedge=true},
            {name="RoutingAileron1",size=Vector3.new(6.8,2.1,1),x=4.1,y=16.8,roll=26,wedge=true},
        }}},
    Orbital={{name="CommandReactor",source=EQUIPMENT.Orbital.source,
        fit=Vector3.new(6.25,6.25,6.25),y=22.63,natives={
            {name="OrbitalPowerOrb",shape=Enum.PartType.Ball,size=Vector3.new(5.8,5.8,5.8),y=17.3},
            {name="OrbitRing",shape=Enum.PartType.Cylinder,
                size=Vector3.new(.55,8.4,8.4),y=17.3,roll=90},
        }}},
    Harbor={{name="CommandCrane",
        source={id=124368710235343,major=40.8,minor=9.141,height=14.0425,centerY=0,
            holder="ApprovedHarborSignatureGantryTemplates",
            template="SculptedGantry",tag="OriginalHarborSignatureGantry3D"},
        fit=Vector3.new(4.35,7.12,16.4),x=2.2,y=23.16,natives={
            {name="DryDockHighCrane",size=Vector3.new(16,1.7,2.9),x=3,y=17.3},
            {name="CableLift",size=Vector3.new(.36,4.6,.36),x=9.1,y=14.2},
            {name="FreightPod",size=Vector3.new(4.1,3.1,3.5),x=9.1,y=10.4},
        }}},
}
local COMMAND_DISTANCE={Low=112,Medium=165,High=240}
local PROMENADE_VARIANTS={Classic=true,Towers=true,Crossroads=true,Orbital=true,Harbor=true}
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
-- Each roof fitting slot is one complete 14-MeshPart pair near the camera.
local FITTING_DISTANCE={Low=100,Medium=145,High=210}
local FITTING_BUDGET={Low=1,Medium=2,High=6}
local SIDES={-1,1}
local STAGE={[1]="Access",[4]="Transfer",[8]="Summit"}
local ARCH_BASE_CAP={Low=1,Medium=2,High=4}
local ARCH_BASE_RANGE={Low=105,Medium=145,High=190}
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
    Low={arch=135,casing=155,helix=0,promenade=118},
    Medium={arch=215,casing=180,helix=170,promenade=195},
    High={arch=325,casing=275,helix=265,promenade=280},
}
local ARCH_NATIVE={
    -- The upper arch owns only its five canopy pieces.
    "VerticalBridgePylon-1","VerticalBridgePylon1",
    "TaperedFin-1","TaperedFin1","MonumentalOverpass",
}
local ARCH_BASE_NATIVE={
    {name="ExteriorAbutment-1", size=Vector3.new(2.4,3.4,2.8), y=-1.65, side=-1},
    {name="ExteriorAbutment1", size=Vector3.new(2.4,3.4,2.8), y=-1.65, side=1},
    {name="LoadBearingKeel", size=Vector3.new(0,1.25,.9), y=-1.45, trim=1},
    {name="RecessedCentralGirder", size=Vector3.new(0,.7,1.15), y=-.72, trim=1.2},
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
        or math.abs(b.Y-spec.height)>(spec.heightTolerance or (portico and .16 or .8)) then return nil end
    return model
end

local function visualNative(part,parent)
    return part and part:IsA("BasePart") and part.Parent==parent
        and part.Anchored and not part.CanCollide
        and not part.CanTouch and not part.CanQuery
        and part.Transparency<.95
end

local function archDeck(arena,deck,scale)
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
    return key,step,route,tonumber(deck.Name:match("%d+"))
end

local function collectArch(arena,deck,decor,scale)
    local key,step,route,index=archDeck(arena,deck,scale)
    if not key then return nil end
    local size=deck.Size
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
        -- the native overpass offset. The plinth has its own footprint.
        orientation=deck.CFrame*CFrame.new(0,size.Y*.5-1,0),
        scaleZ=overpass.Size.Z/17.6,
        stage=step,route=route,index=index,expectedParent=decor}
end

local function collectArchBase(arena,deck,decor,scale)
    if decor~=arena:FindFirstChild("Decor") then return nil end
    local stage,_,_,index=archDeck(arena,deck,scale)
    if not stage then return nil end
    local size=deck.Size
    local bottom=-size.Y*.5
    local halfZ=size.Z*.5
    local natives={}
    for slot,partSpec in ipairs(ARCH_BASE_NATIVE) do
        local part=decor:FindFirstChild("SkyRouteMonument"..index.."_"..partSpec.name)
        if not visualNative(part,decor) or not part:IsA("Part")
            or part.Shape~=Enum.PartType.Block
            or part:GetAttribute("SkyRouteMonument")~=true
            or part:GetAttribute("PerimeterPlatformIndex")~=index
            or part:GetAttribute("SkyRouteStage")~=stage:upper() then return nil end
        local src=partSpec.size
        local width=partSpec.trim and size.X-partSpec.trim*scale or src.X*scale
        local z=partSpec.side and partSpec.side*(halfZ+scale) or 0
        local expected=deck.CFrame*CFrame.new(0,bottom+partSpec.y,z)
        if (part.Size-Vector3.new(width,src.Y,src.Z*scale)).Magnitude>.14
            or (part.Position-expected.Position).Magnitude>.16
            or part.CFrame.UpVector:Dot(expected.UpVector)<.999
            or part.CFrame.LookVector:Dot(expected.LookVector)<.999 then return nil end
        natives[slot]=part
    end
    -- The original blocks are under the floor plane. Put the castings
    -- against the approach-facing wall, grounded below the landing.
    local base=arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") then return nil end
    local dx=deck.Position.X-base.Position.X
    if math.abs(dx)<1 then return nil end
    local facing=dx<0 and 1 or -1
    local wall=deck.CFrame*CFrame.new(facing*(size.X*.5+.13*scale),bottom,0)
    local height=math.min(3.4,size.Y-.38)
    local crest=height-.59
    local center=wall.Position
    local pieces={}
    for i,side in ipairs(SIDES) do
        pieces[i]={category="archBase",name="ArchAbutment",owner=deck,
            key=natives[i],arena=arena,expectedParent=decor,
            originals={natives[i]},component=i,center=center,
            orientation=wall*CFrame.new(0,height*.5-.035,side*(halfZ-.30*scale))
                * CFrame.Angles(0,side==facing and math.pi or 0,0),
            fitSize=Vector3.new(1.35*scale,height,2.45*scale)}
    end
    pieces[3]={category="archBase",name="ArchGirder",owner=deck,
        key=natives[3],arena=arena,expectedParent=decor,
        originals={natives[3],natives[4]},component=3,center=center,
        orientation=wall*CFrame.new(facing*.17*scale,crest,0)
            * CFrame.Angles(0,facing==-1 and math.pi or 0,0),
        fitSize=Vector3.new(.93*scale,1.05,size.Z-.42*scale)}
    for _,data in ipairs(pieces) do data.group=pieces end
    return pieces
end

local function porticoStep(arena,deck,scale)
    local variant=arena:GetAttribute("VariantId")
    if not PROMENADE_VARIANTS[variant] then return nil end
    if not deck:IsA("BasePart") or deck.Parent~=arena:FindFirstChild("Platforms")
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
    if not native or Trim.hasPrimaryStructure(native) then return nil end
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

local function promenadeUnderdeck(deck,decor,scale,span)
    local index=deck.Name:match("^Platform(%d+)$")
    local native=promenadeNative(decor,index,"_UnderdeckTruss")
    if not native or Trim.hasPrimaryStructure(native) then return nil end
    local expected=deck.CFrame*CFrame.new(0,-.3,0)
    if (native.Position-expected.Position).Magnitude>.14
        or (native.Size-Vector3.new(5.6*scale,1.7,span*scale)).Magnitude>.13
        or expected.UpVector:Dot(native.CFrame.UpVector)<.999
        or expected.LookVector:Dot(native.CFrame.LookVector)<.999 then return nil end
    return native
end

local function promenadeChassis(arena,deck,decor,frame,truss,name,spine)
    local size=deck.Size
    local depth=.56
    local orientation=deck.CFrame*CFrame.new(0,-size.Y*.5-.04-depth*.5,0)
        *CFrame.Angles(0,math.pi*.5,0)
    return {category="junction",name=name,spec=SOURCE.AccessChassis,
        key=frame,owner=deck,arena=arena,originals=truss and {frame,truss} or {frame},
        otherDeck=spine,center=deck.Position,orientation=orientation,
        fitSize=Vector3.new(size.Z*.985,depth,size.X*.985),expectedParent=decor}
end

local function collectPromenadeUnderframe(arena,deck,decor)
    if deck.Parent~=arena:FindFirstChild("Platforms") then return nil end
    local step=deck:GetAttribute("PromenadeStep")
    -- Step four uses the dedicated two-deck junction fit.
    if step==4 then return nil end
    local frame,_,scale=LargeStructure.promenadeNativeFrame(decor,deck)
    if not frame or Trim.hasPrimaryStructure(frame) then return nil end

    if step==2 or step==7 then
        local truss=promenadeUnderdeck(deck,decor,scale,step==2 and 11 or 15)
        if not truss then return nil end
        return promenadeChassis(arena,deck,decor,frame,truss,"PromenadeTruss")
    end
    return promenadeChassis(arena,deck,decor,frame,nil,"PromenadeUnderframe")
end

local function collectSpineUnderframe(arena,deck,decor)
    if not deck:IsA("BasePart") or deck.Parent~=arena:FindFirstChild("Platforms") then return nil end
    local native=LargeStructure.spineNativeParts(decor,deck)
    if not native then return nil end
    for _,part in ipairs(native) do
        if Trim.hasPrimaryStructure(part) then return nil end
    end
    local size=deck.Size
    local depth=.60
    -- Fit the whole underside within the solid deck's perimeter. Keep
    -- just below the collision face and above the original cross brace bottom.
    local orientation=deck.CFrame*CFrame.new(0,-size.Y*.5-.04-depth*.5,0)
    return {category="junction",name="SpineUnderframe",spec=SOURCE.AccessChassis,
        key=native[1],owner=deck,arena=arena,originals=native,
        center=deck.Position,orientation=orientation,
        fitSize=Vector3.new(size.X*.985,depth,size.Z*.985),expectedParent=decor}
end

-- The central fittings depend on their own traversable Sky Spine endpoint.
local function collectJunctionTruss(arena,deck,spine,decor,scale,useChassis)
    if not spine or deck.Parent~=arena:FindFirstChild("Platforms")
        or deck:GetAttribute("PromenadeStep")~=4
        or deck:GetAttribute("RouteTier")~=4 or spine:GetAttribute("RouteTier")~=4
        or math.abs(deck.Size.Z-12*scale)>.12
        or math.abs(spine.Size.X-12*scale)>.12
        or math.abs(deck.Size.Y-2)>.08 or math.abs(spine.Size.Y-2)>.08
        or not Connection.spineJunction(spine,deck) then return nil end
    local native=promenadeUnderdeck(deck,decor,scale,13)
    if not native then return nil end
    if useChassis then
        local frame=LargeStructure.promenadeNativeFrame(decor,deck)
        if not frame or Trim.hasPrimaryStructure(frame) then return nil end
        return promenadeChassis(arena,deck,decor,frame,native,"JunctionUnderframe",spine)
    end
    -- The shoulder remains underneath the real two-stud collision deck,
    -- with a flange at its underside and visible structural depth below.
    return {category="junction",name="JunctionTruss",key=native,owner=deck,
        otherDeck=spine,arena=arena,originals={native},center=deck.Position,
        orientation=native.CFrame*CFrame.new(0,-1.02,0),
        fitSize=Vector3.new(native.Size.X*.97,1.7,native.Size.Z*.98),expectedParent=decor}
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

local function collectRoofNative(decor,index,orientation,scale,spec)
    local native=promenadeNative(decor,index,"_"..spec.name,spec.wedge)
    if not native then return nil end
    local expected=orientation*CFrame.new(spec.x*scale,spec.y,(spec.z or 0)*scale)
        *CFrame.Angles(0,0,math.rad(spec.roll or 0))
    local size=spec.size
    if (native.Size-Vector3.new(size.X*scale,size.Y,size.Z*scale)).Magnitude>.10
        or (native.Position-expected.Position).Magnitude>.15
        or native.CFrame.UpVector:Dot(expected.UpVector)<.999
        or native.CFrame.LookVector:Dot(expected.LookVector)<.999 then return nil end
    return native
end

local function collectEquipment(arena,deck,decor,scale,equipment)
    -- Authenticate the actual crosshead and its complete, correctly
    -- streamed equipment before erecting any local art above the route.
    local crosshead=collectPorticoPart(arena,deck,decor,scale)
    if not crosshead then return nil end
    local index=deck.Name:match("^Platform(%d+)$")
    local natives={}
    for _,spec in ipairs(equipment.natives) do
        local native=collectRoofNative(decor,index,crosshead.orientation,scale,spec)
        if not native or (equipment.name=="PromenadeHarbor" and Trim.hasPrimaryStructure(native)) then
            return nil
        end
        natives[#natives+1]=native
    end
    if equipment.name=="PromenadeHarbor" then
        local targets=HarborHoist.targets(natives[1],natives[2],natives[3],scale)
        if not targets then return nil end
        return {category="equipment",name=equipment.name,spec=equipment.source,
            owner=deck,key=natives[1],arena=arena,originals=natives,anchor=crosshead.originals[1],
            center=natives[1].Position,hoistTargets=targets,expectedParent=decor}
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

local function collectFittingPair(arena,deck,decor,scale,fittings)
    local crosshead=collectPorticoPart(arena,deck,decor,scale)
    if not crosshead then return nil end
    local index=deck.Name:match("^Platform(%d+)$")
    local pair={}
    for slot,fitting in ipairs(fittings) do
        local native=collectRoofNative(decor,index,crosshead.orientation,scale,fitting)
        if not native then return nil end
        local size=fitting.fitSize
        local vertical=fitting.vertical
        -- The rail's long axis becomes vertical after rotation. Shrink
        -- changes the horizontal cross-section in the fitted source frame.
        pair[slot]={category="fitting",name=fitting.source,spec=FITTING_SOURCE[fitting.source],
            owner=deck,key=native,side=slot==1 and -1 or 1,arena=arena,
            originals={native},anchor=crosshead.originals[1],
            center=crosshead.center,orientation=native.CFrame*fitting.axes,
            fitSize=Vector3.new(size.X*scale,vertical and size.Y*scale or size.Y,
                vertical and size.Z or size.Z*scale),expectedParent=decor}
    end
    pair[1].other=pair[2].key
    pair[2].other=pair[1].key
    return pair
end

local function collectCommandArt(arena,deck,decor,scale,profiles)
    local index=deck.Name:match("^Platform(%d+)$")
    local step=deck:GetAttribute("SkySpineStep")
    if not index or not deck:IsA("BasePart") or deck.Parent~=arena:FindFirstChild("Platforms")
        or (step~=5 and step~=6) or deck:GetAttribute("SkySpineInterchange")~=true
        or deck:GetAttribute("ChaosPermanentRoute")~=true or deck:GetAttribute("RouteTier")~=4
        or not Crown.supportsCommandArt(deck)
        or not deck.Anchored or not deck.CanCollide or deck.Transparency>=.75
        or math.abs(deck.Size.X/scale-12)>.22 or math.abs(deck.Size.Y-2)>.12
        or deck.Size.Z/scale<14.3 or deck.Size.Z/scale>33.2 then return nil end
    local phase=deck:GetAttribute("CollapsePhase")
    local shutter=deck:GetAttribute("BridgeShutterPhase")
    if (phase and phase~="Normal" and phase~="Safe")
        or (shutter and shutter~="Idle") then return nil end

    local top=deck.CFrame*CFrame.new(0,deck.Size.Y*.5,0)
    local prefix="SkySpine"..index.."_"
    local function nativePart(spec)
        local native=decor:FindFirstChild(prefix..spec.name)
        if not visualNative(native,decor) or native:GetAttribute("SkySpineDecor")~=true
            or native:GetAttribute("PerimeterPlatformIndex")~=tonumber(index) then return nil end
        if spec.wedge then
            if not native:IsA("WedgePart") then return nil end
        elseif not native:IsA("Part") or native.Shape~=(spec.shape or Enum.PartType.Block) then
            return nil
        end
        local size=spec.size
        local aim=top*CFrame.new((spec.x or 0)*scale,spec.y,(spec.z or 0)*scale)
            *CFrame.Angles(0,0,math.rad(spec.roll or 0))
        if (native.Size-Vector3.new(size.X*scale,size.Y,size.Z*scale)).Magnitude>.11
            or (native.Position-aim.Position).Magnitude>.15
            or native.CFrame.UpVector:Dot(aim.UpVector)<.999
            or native.CFrame.LookVector:Dot(aim.LookVector)<.999 then return nil end
        return native
    end
    local crown=nativePart({name="InterchangeCrown",size=Vector3.new(17.2,1.4,2.5),y=13})
    if not crown then return nil end
    local group={}
    for i,profile in ipairs(profiles) do
        local natives={}
        for _,spec in ipairs(profile.natives) do
            local native=nativePart(spec)
            if not native then return nil end
            natives[#natives+1]=native
        end
        local fit=profile.fit
        group[i]={category="command",name=profile.name,spec=profile.source,
            owner=deck,key=natives[1],arena=arena,originals=natives,anchor=crown,
            center=top.Position,orientation=top*CFrame.new((profile.x or 0)*scale,profile.y,0)
                * CFrame.Angles(0,-math.pi*.5,0),
            fitSize=Vector3.new(fit.X*scale,fit.Y,fit.Z*scale),expectedParent=decor}
    end
    if #group==2 then
        group[1].side,group[2].side=-1,1
        group[1].other,group[2].other=group[2].key,group[1].key
    end
    return group
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
    local foot,front=natives[1],natives[2]
    if not foot:IsA("Part") or foot.Shape~=Enum.PartType.Block
        or (foot.Size-Vector3.new(5.5,1,5.5)).Magnitude>.13
        or not front:IsA("Part") or front.Shape~=Enum.PartType.Block
        or (front.Size-Vector3.new(3.35,6.4,.65)).Magnitude>.13
        or foot.CFrame.LookVector:Dot(front.CFrame.LookVector)<.999
        or foot.CFrame.UpVector:Dot(front.CFrame.UpVector)<.999 then return nil end
    local origin=front.CFrame*CFrame.new(0,0,1.7)
    local localFoot=origin:PointToObjectSpace(foot.Position)
    if math.abs(localFoot.X)>.08 or math.abs(localFoot.Z)>.08
        or localFoot.Y< -3.65 or localFoot.Y> -2.55 then return nil end

    -- Fit bottom to the actual slab without raising the crown into the
    -- separate navigation head. Yaw the detailed front toward the center
    -- even when joining a place built with the older mirrored shells.
    local base=arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") then return nil end
    local toward=base.Position-origin.Position
    toward=Vector3.new(toward.X,0,toward.Z)
    if toward.Magnitude<1 then return nil end
    local width=0
    for i=10,11 do
        local part=natives[i]
        local relative=origin:ToObjectSpace(part.CFrame)
        local half=.5*(math.abs(relative.RightVector.X)*part.Size.X
            +math.abs(relative.UpVector.X)*part.Size.Y
            +math.abs(relative.LookVector.X)*part.Size.Z)
        width=math.max(width,2*(math.abs(relative.X)+half))
    end
    -- The caster's original proportions are the minimum envelope; long
    -- Towers and Harbor cantilevers need more horizontal coverage.
    local bottom=math.max(foot.Position.Y-foot.Size.Y*.5,base.Position.Y+base.Size.Y*.5+.015)
    local top=origin.Position.Y+6.3384
    if top-bottom<8.8 then return nil end
    local center=Vector3.new(origin.Position.X,(top+bottom)*.5,origin.Position.Z)
    return {category="casing",name="Casing",owner=casing,arena=arena,
        originals=natives,center=front.Position,orientation=CFrame.lookAt(center,center+toward),
        fitSize=Vector3.new(math.clamp(width,8.58,11.6),top-bottom,5.3),
        expectedParent=casing}
end

local function availableOrbitalRamp(arena,ramp,circuit)
    if arena:GetAttribute("VariantId")~="Orbital" or not ramp:IsA("BasePart")
        or ramp.Parent~=circuit or not ramp.Anchored or not ramp.CanCollide
        or ramp.Transparency>=.75 then return false end
    local phase=ramp:GetAttribute("CollapsePhase")
    local shutter=ramp:GetAttribute("BridgeShutterPhase")
    return typeof(ramp:GetAttribute("HelixStart"))=="Vector3"
        and typeof(ramp:GetAttribute("HelixFinish"))=="Vector3"
        and phase~="Warning" and phase~="Gone" and (not shutter or shutter=="Idle")
end

local function collectHelix(arena,ramp,circuit)
    if not availableOrbitalRamp(arena,ramp,circuit) then return nil end
    local index=ramp:GetAttribute("HelixLane")
    if type(index)~="number" or index%1~=0
        or index<1 or index>9 or ramp.Name~="HelixRamp"..index then return nil end
    local core=index==9
    local group=core and "Core2" or "Helix"..index
    local tag=core and "OrbitalCoreRamp" or "OrbitalHelixRamp"
    local fullWidth=core and 4.6 or 5.4
    local size=ramp.Size
    if ramp:GetAttribute(tag)~=true or ramp:GetAttribute("OrbitRouteGroup")~=group
        or size.X<(core and 2.38 or 5.37) or size.X>fullWidth+.03
        or size.Z<6.5 or size.Z>57.6 or math.abs(size.Y-.92)>.04 then return nil end

    local originals={}
    local lateralScale=size.X/fullWidth
    local function take(name,specSize,position)
        local part=circuit:FindFirstChild(name)
        if not visualNative(part,circuit) or not part:IsA("Part")
            or part.Shape~=Enum.PartType.Block or part:GetAttribute("HelixLane")~=index
            or part:GetAttribute("OrbitRouteGroup")~=group then return false end
        local relative=ramp.CFrame:ToObjectSpace(part.CFrame)
        if (part.Size-specSize).Magnitude>.09 or (relative.Position-position).Magnitude>.09
            or relative.LookVector:Dot(-Vector3.zAxis)<.998
            or relative.UpVector:Dot(Vector3.yAxis)<.998 then return false end
        originals[#originals+1]=part
        return true
    end
    for side=-1,1,2 do
        if not take("HelixUnderframe"..index.."_"..side,
            Vector3.new(.34,.26,size.Z-.7),
            Vector3.new(side*(fullWidth*.5-.45)*lateralScale,-.65,0))
            or not take("HelixSpineBrace"..index.."_"..side,
            Vector3.new((fullWidth+.25)*lateralScale,.23,.45),
            Vector3.new(0,-.62,side*size.Z*.28)) then return nil end
    end

    local data={category="helix",name="Helix",owner=ramp,arena=arena,
        originals=originals,center=ramp.Position,orientation=ramp.CFrame,
        scaleX=size.X/5.4,scaleZ=size.Z/24,expectedParent=circuit}
    if core then
        if not take("HelixSpineBrace"..index.."_0",
            Vector3.new((fullWidth+.25)*lateralScale,.23,.45),
            Vector3.new(0,-.62,0)) then return nil end
        -- This short reactor crossing has another playable route underneath.
        -- Fit within the native underframe's depth instead of hanging a keel below it.
        local depth=.30
        local centerY=-size.Y*.5-.012-depth*.5
        data.orientation=ramp.CFrame*CFrame.new(0,centerY-SOURCE.Helix.centerY,0)
        data.fitSize=Vector3.new(size.X*.965,depth,size.Z-.7)
    end
    return data
end

local function collectAccessChassis(arena,ramp,circuit)
    if not availableOrbitalRamp(arena,ramp,circuit) then return nil end
    local kind,number=ramp.Name:match("^(%a+)Ramp([1-8])$")
    if kind~="Entry" and (kind~="Core" or number=="2") then return nil end
    local attribute=kind=="Entry" and "OrbitalAccessRamp" or "OrbitalCoreRamp"
    local group=kind..number
    if ramp:GetAttribute(attribute)~=true or ramp:GetAttribute("OrbitRouteGroup")~=group then
        return nil
    end
    local size=ramp.Size
    local fullWidth=kind=="Entry" and 5.4 or 4.6
    if size.X<2.38 or size.X>fullWidth+.025 or math.abs(size.Y-.92)>.04
        or size.Z<2.6 or size.Z>55 then return nil end
    local native=circuit:FindFirstChild(kind.."Chassis"..number)
    if not visualNative(native,circuit) or not native:IsA("Part")
        or native.Shape~=Enum.PartType.Block or native:GetAttribute("OrbitRouteGroup")~=group then
        return nil
    end
    local expected=Vector3.new(size.X*(1-.38/fullWidth),.22,size.Z-.45)
    local relative=ramp.CFrame:ToObjectSpace(native.CFrame)
    if (native.Size-expected).Magnitude>.08
        or (relative.Position-Vector3.new(0,-.58,0)).Magnitude>.07
        or relative.LookVector:Dot(-Vector3.zAxis)<.998
        or relative.UpVector:Dot(Vector3.yAxis)<.998 then
        return nil
    end
    local depth=math.min(.44,size.X*.16)
    return {category="helix",name="AccessChassis",owner=ramp,arena=arena,
        originals={native},center=ramp.Position,expectedParent=circuit,
        orientation=ramp.CFrame*CFrame.new(0,-size.Y*.5-.012-depth*.5,0),
        fitSize=Vector3.new(native.Size.X*.985,depth,native.Size.Z*.985)}
end

local function isPortico(category)
    return category=="promenade" or category=="stay"
        or category=="equipment" or category=="fitting" or category=="command"
        or category=="junction"
end

local function usesStructureMask(entry)
    local category=entry.category
    return category=="junction" or category=="stay" or category=="promenade"
        or entry.name=="PromenadeHarbor"
end

local function reveal(entry)
    for _,n in ipairs(entry.native) do
        if entry.category=="command" then
            Trim.setSkySpineRoofMask(n.part,true,false)
        elseif usesStructureMask(entry) then
            Trim.setPromenadeStructureMask(n.part,false,false)
        elseif (n.part.Parent==entry.expectedParent
            or ((isPortico(entry.category) or entry.category=="archBase" or entry.category=="casing"
                or entry.category=="helix")
                and entry.visible))
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
    local partCount=entry.hoistBeam and HarborHoist.PartCount or 7
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
        or not entry.pieces or #entry.pieces~=partCount then return false end
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
    if actual~=partCount then return false end
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
    if entry.hoistBeam then
        local beam=HarborHoist.beamSource()
        if not beam or beam.model~=entry.hoistBeam.model or not HarborHoist.roles(entry.source) then return false end
        for i,part in ipairs(beam.parts) do
            if entry.hoistBeam.parts[i]~=part then return false end
        end
    end
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
        if entry.category=="archBase" then
            local group=collectArchBase(entry.arena,entry.owner,entry.expectedParent,scale)
            data=group and group[entry.component]
            if data then
                for _,member in ipairs(group) do
                    local peer=mounted[member.key]
                    if not peer or peer.owner~=entry.owner or not sameOriginals(peer,member)
                        or (peer~=entry and not sourceIntact(peer)) then
                        data=nil
                        break
                    end
                end
            end
        elseif entry.category=="arch" or isPortico(entry.category) then
            local decor=entry.arena:FindFirstChild("Decor")
            if decor==entry.expectedParent then
                if entry.category=="arch" then
                    data=collectArch(entry.arena,entry.owner,decor,scale)
                elseif entry.category=="junction" then
                    if entry.name=="PromenadeTruss" or entry.name=="PromenadeUnderframe" then
                        data=collectPromenadeUnderframe(entry.arena,entry.owner,decor)
                    elseif entry.name=="SpineUnderframe" then
                        data=collectSpineUnderframe(entry.arena,entry.owner,decor)
                    else
                        data=collectJunctionTruss(entry.arena,entry.owner,entry.otherDeck,decor,scale,
                            entry.name=="JunctionUnderframe")
                    end
                elseif entry.category=="equipment" then
                    local equipment=EQUIPMENT[entry.arena:GetAttribute("VariantId")]
                    if equipment then
                        data=collectEquipment(entry.arena,entry.owner,decor,scale,equipment)
                    end
                elseif entry.category=="command" or entry.side then
                    local pair
                    if entry.category=="command" then
                        local profiles=COMMAND_ART[entry.arena:GetAttribute("VariantId")]
                        if profiles then
                            pair=collectCommandArt(entry.arena,entry.owner,decor,scale,profiles)
                        end
                    elseif entry.category=="stay" then
                        pair=collectStayPair(entry.arena,entry.owner,decor,scale)
                    else
                        local fittings=ROOF_FITTINGS[entry.arena:GetAttribute("VariantId")]
                        if fittings then
                            pair=collectFittingPair(entry.arena,entry.owner,decor,scale,fittings)
                        end
                    end
                    data=pair and pair[entry.side==1 and 2 or 1]
                    if data and entry.other then
                        local other=mounted[entry.other]
                        if data.other~=entry.other or not other
                            or other.other~=entry.native[1].part
                            or other.anchor~=data.anchor or not sourceIntact(other) then
                            data=nil
                        end
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
                if entry.name=="AccessChassis" then
                    data=collectAccessChassis(entry.arena,entry.owner,circuit)
                else
                    data=collectHelix(entry.arena,entry.owner,circuit)
                end
            end
        end
    end
    if not data or data.name~=entry.name or not sameOriginals(entry,data) then
        reveal(entry)
        return false
    end
    if data.hoistTargets then
        for _,piece in ipairs(entry.pieces) do
            HarborHoist.refit(piece,data.hoistTargets[piece.role])
            piece.part.LocalTransparencyModifier=0
        end
    else
        local rule=entry.spec
        local sx,sy,sz=data.scaleX or 1,1,data.scaleZ or 1
        if data.fitSize then
            local size,bounds=data.fitSize,entry.bounds
            local major,minor=math.max(bounds.X,bounds.Z),math.min(bounds.X,bounds.Z)
            sx=size.X/(entry.category=="casing" and major or minor)
            sy=size.Y/bounds.Y
            sz=size.Z/(entry.category=="casing" and minor or major)
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
    end
    for _,n in ipairs(entry.native) do
        if n.part.Parent==entry.expectedParent then
            if entry.category=="command" then
                Trim.setSkySpineRoofMask(n.part,true,true)
            elseif usesStructureMask(entry) then
                Trim.setPromenadeStructureMask(n.part,false,true)
            else
                n.part.LocalTransparencyModifier=1
            end
        end
    end
    entry.visible=true
    return true
end

local function dispose(entry)
    if entry.disposing then return end
    entry.disposing=true
    if entry.disconnectStructureObserver then entry.disconnectStructureObserver() end
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
            for _,key in ipairs(entry.groupKeys or {}) do
                local peer=mounted[key]
                if peer then refresh(peer) end
            end
            local other=entry.other and mounted[entry.other]
            if other then refresh(other) end
        end
    end
end)

local function mount(data,source)
    local clone,hoistPieces
    if data.hoistTargets then
        clone,hoistPieces=HarborHoist.build(source,data.hoistBeam)
    else
        clone=source:Clone()
    end
    if not clone then return nil end
    local cf,b=clone:GetBoundingBox()
    local entry={category=data.category,name=data.name,spec=data.spec or SOURCE[data.name],
        owner=data.owner,side=data.side,other=data.other,arena=data.arena,
        component=data.component,
        otherDeck=data.otherDeck,hoistBeam=data.hoistBeam,
        source=source,sourceFolder=source.Parent,
        expectedParent=data.expectedParent,anchor=data.anchor,
        native={},model=clone,pieces={},connections={},bounds=b,
        -- The casing is authored X-wide, while route fits are Z-long.
        -- Correct either imported axis before applying its local fit.
        longX=(data.category=="casing" and b.Z>b.X)
            or (data.category~="casing" and b.X>b.Z),
        visible=false,disposing=false}
    if data.group then
        entry.groupKeys={}
        for _,member in ipairs(data.group) do
            entry.groupKeys[#entry.groupKeys+1]=member.key
        end
    end
    for _,native in ipairs(data.originals) do
        entry.native[#entry.native+1]={
            part=native,alpha=native.LocalTransparencyModifier}
    end
    for _,piece in ipairs(clone:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then clone:Destroy();return nil end
            local fit=hoistPieces and hoistPieces[piece] or {frame=cf:ToObjectSpace(piece.CFrame)}
            fit.part,fit.size=piece,piece.Size
            entry.pieces[#entry.pieces+1]=fit
            piece.Anchored=true
            piece.Massless=true
            piece.CanCollide=false
            piece.CanTouch=false
            piece.CanQuery=false
            piece.CastShadow=false
            piece.LocalTransparencyModifier=1
        end
    end
    local partCount=hoistPieces and HarborHoist.PartCount or 7
    if #entry.pieces~=partCount then clone:Destroy();return nil end
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
        for _,key in ipairs(entry.groupKeys or {}) do
            local peer=mounted[key]
            if peer and peer~=entry then refresh(peer) end
        end
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
    if data.category=="arch" or data.category=="archBase" or isPortico(data.category)
        or data.category=="helix" then
        -- A collapsing/shutter warning takes precedence over decorative
        -- art IMMEDIATELY, not after the next 0.65-second scenery sample.
        entry.connections[#entry.connections+1]=
            data.owner:GetAttributeChangedSignal("CollapsePhase"):Connect(changed)
        entry.connections[#entry.connections+1]=
            data.owner:GetAttributeChangedSignal("BridgeShutterPhase"):Connect(changed)
    end
    if isPortico(data.category) then
        local routeAttributes=(data.category=="command" or data.name=="SpineUnderframe")
            and {"SkySpineInterchange","SkySpineStep","ChaosPermanentRoute","RouteTier","LocalSkySpineCrownVisible"}
            or {"PromenadeLane","PromenadeStep","ChaosPermanentRoute","RouteTier"}
        for _,attribute in ipairs(routeAttributes) do
            entry.connections[#entry.connections+1]=
                data.owner:GetAttributeChangedSignal(attribute):Connect(changed)
        end
    end
    if data.otherDeck then
        watch(data.otherDeck,{"CFrame","Size","Transparency","CanCollide","Anchored","Name"})
        for _,name in ipairs({"SkySpineStep","SkySpineInterchange","RouteTier",
            "ChaosPermanentRoute","CollapsePhase","BridgeShutterPhase"}) do
            entry.connections[#entry.connections+1]=
                data.otherDeck:GetAttributeChangedSignal(name):Connect(changed)
        end
    end
    if usesStructureMask(data) then
        local disconnects={}
        for _,part in ipairs(data.originals) do
            disconnects[#disconnects+1]=Trim.observePrimaryStructure(part,changed)
        end
        entry.disconnectStructureObserver=function()
            for _,disconnect in ipairs(disconnects) do disconnect() end
        end
        for _,tag in ipairs({"OwnerVerified","Original3DAssetId","CosmeticOnly",
            entry.spec.tag or "P4OriginalRemainingStructure3D"}) do
            entry.connections[#entry.connections+1]=source:GetAttributeChangedSignal(tag):Connect(changed)
        end
        entry.connections[#entry.connections+1]=
            entry.sourceFolder:GetAttributeChangedSignal("OwnerVerified"):Connect(changed)
    end
    local function watchPorticoNative(native)
        watch(native,{"CFrame","Size","Transparency","Anchored",
            "CanCollide","CanTouch","CanQuery","Name"})
        if native:IsA("Part") then
            entry.connections[#entry.connections+1]=
                native:GetPropertyChangedSignal("Shape"):Connect(changed)
        end
        local marker=data.category=="command" and "SkySpineDecor" or "PromenadeVisualOnly"
        if data.name=="SpineUnderframe" then
            marker=native==data.originals[1] and "PremiumArchitecturalSurface" or "SkySpineDecor"
        elseif data.category=="junction" and native.Name:match("^PlatformUnderFrame%d+$") then
            marker="PremiumArchitecturalSurface"
        end
        for _,attribute in ipairs({marker,"PerimeterPlatformIndex"}) do
            entry.connections[#entry.connections+1]=
                native:GetAttributeChangedSignal(attribute):Connect(changed)
        end
    end
    for _,native in ipairs(data.originals) do
        if data.category=="casing" or data.category=="archBase" then
            watch(native,{"CFrame","Size","Transparency","Anchored",
                "CanCollide","CanTouch","CanQuery","Name"})
            if native:IsA("Part") then
                entry.connections[#entry.connections+1]=native:GetPropertyChangedSignal("Shape"):Connect(changed)
            end
            if data.category=="archBase" then
                for _,tag in ipairs({"SkyRouteMonument","SkyRouteStage","PerimeterPlatformIndex"}) do
                    entry.connections[#entry.connections+1]=native:GetAttributeChangedSignal(tag):Connect(changed)
                end
            end
        elseif data.category=="helix" then
            watch(native,{"CFrame","Size","Transparency","Anchored","CanCollide",
                "CanTouch","CanQuery","Name","Shape"})
            for _,tag in ipairs({"OrbitRouteGroup","HelixLane"}) do
                entry.connections[#entry.connections+1]=native:GetAttributeChangedSignal(tag):Connect(changed)
            end
        elseif isPortico(data.category) then
            watchPorticoNative(native)
        else
            watch(native,{"CFrame","Size","Transparency"})
        end
    end
    if data.anchor then watchPorticoNative(data.anchor) end
    if data.hoistBeam then
        local beam=data.hoistBeam.model
        for _,tag in ipairs({"OwnerVerified","Original3DAssetId","OriginalStructuralSide3D","CosmeticOnly"}) do
            entry.connections[#entry.connections+1]=beam:GetAttributeChangedSignal(tag):Connect(changed)
        end
        entry.connections[#entry.connections+1]=beam.Parent:GetAttributeChangedSignal("OwnerVerified"):Connect(changed)
        entry.connections[#entry.connections+1]=beam.AncestryChanged:Connect(changed)
        entry.connections[#entry.connections+1]=beam.ChildAdded:Connect(changed)
        entry.connections[#entry.connections+1]=beam.ChildRemoved:Connect(changed)
    end
    if data.category=="helix" then
        local routeTag=data.name=="AccessChassis" and "OrbitalAccessRamp" or "OrbitalHelixRamp"
        for _,tag in ipairs({routeTag,"OrbitalCoreRamp","OrbitRouteGroup","HelixLane","HelixStart","HelixFinish"}) do
            entry.connections[#entry.connections+1]=data.owner:GetAttributeChangedSignal(tag):Connect(changed)
        end
        entry.connections[#entry.connections+1]=data.owner:GetPropertyChangedSignal("Name"):Connect(changed)
    end
    if data.category=="archBase" or data.category=="casing" then
        local tags=data.category=="casing"
            and {"FrameColumnIndex","OriginalFrameCladding","SourceIsOriginal","CosmeticOnly"}
            or {"PerimeterRoute","PerimeterStep","RouteTier"}
        for _,tag in ipairs(tags) do
            entry.connections[#entry.connections+1]=data.owner:GetAttributeChangedSignal(tag):Connect(changed)
        end
    end
    if data.category=="archBase" or data.category=="casing" or data.category=="helix" then
        for _,tag in ipairs({"OwnerVerified","Original3DAssetId","CosmeticOnly",
            entry.spec.tag or "P4OriginalRemainingStructure3D"}) do
            entry.connections[#entry.connections+1]=source:GetAttributeChangedSignal(tag):Connect(changed)
        end
        entry.connections[#entry.connections+1]=entry.sourceFolder:GetAttributeChangedSignal("OwnerVerified"):Connect(changed)
    end
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
    if not entry.other and not data.group then refresh(entry) end
    return entry
end

local function caps(tier,touch,pressure,kind)
    if kind=="archBase" then
        if (tonumber(pressure) or 0)>=1 then return 0 end
        return touch==true and 1 or (ARCH_BASE_CAP[tier] or ARCH_BASE_CAP.Low)
    end
    if kind=="junction" then
        if (tonumber(pressure) or 0)>=1 then return 0 end
        return tier~="Low" and touch~=true and 2 or 1
    end
    if kind=="stay" then
        local cap=STAY_BUDGET[tier] or 0
        if (tonumber(pressure) or 0)>=1 then return 0 end
        return touch==true and math.min(cap,1) or cap
    end
    if kind=="equipment" then
        if (tonumber(pressure) or 0)>=1 then return 0 end
        return (touch==true and EQUIPMENT_TOUCH_CAP or EQUIPMENT_BUDGET)[tier] or 0
    end
    if kind=="command" then
        if (tonumber(pressure) or 0)>=1 then return 0 end
        return tier=="High" and touch~=true and 2 or 1
    end
    if kind=="fitting" then
        local cap=FITTING_BUDGET[tier] or 0
        if (tonumber(pressure) or 0)>=1 then return 0 end
        return touch==true and math.min(cap,1) or cap
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
    local archBaseCap=caps(tier,touch,pressure,"archBase")
    local trussCap=caps(tier,touch,pressure,"junction")
    for name in pairs(SOURCE) do
        local kind=name=="Crosshead" and "promenade" or (name=="Stay" and "stay")
            or (name=="JunctionTruss" and "junction")
        if name=="ArchAbutment" or name=="ArchGirder" then
            if archBaseCap>0 then src[name]=sourceFor(name) end
        elseif name=="AccessChassis" then
            local routeUnderframes=trussCap>0 and promenadeVariant
            if variant=="Orbital" or routeUnderframes then
                local source=sourceFor(name)
                if variant=="Orbital" then src[name]=source end
                if routeUnderframes then
                    src.JunctionUnderframe=source
                    src.PromenadeUnderframe=source
                    src.PromenadeTruss=source
                    src.SpineUnderframe=source
                end
            end
        elseif not kind or ((promenadeVariant or kind=="junction") and caps(tier,touch,pressure,kind)>0) then
            src[name]=sourceFor(name)
        end
    end
    local equipment=EQUIPMENT[variant]
    local hoistBeam
    if equipment and caps(tier,touch,pressure,"equipment")>0 then
        local source=sourceFor(equipment.name,equipment.source)
        if source and equipment.name=="PromenadeHarbor" then
            hoistBeam=HarborHoist.beamSource()
            if not hoistBeam or not HarborHoist.roles(source) then source=nil end
        end
        src[equipment.name]=source
    end
    local fittings=ROOF_FITTINGS[variant]
    local fittingSourcesReady=false
    if fittings and caps(tier,touch,pressure,"fitting")>0 then
        local first,second=fittings[1].source,fittings[2].source
        src[first]=sourceFor(first,FITTING_SOURCE[first])
        if second~=first then src[second]=sourceFor(second,FITTING_SOURCE[second]) end
        fittingSourcesReady=src[first]~=nil and src[second]~=nil
    end
    local commandProfiles=COMMAND_ART[variant]
    local commandReady=commandProfiles~=nil and caps(tier,touch,pressure,"command")>0
    if commandReady then
        for _,profile in ipairs(commandProfiles) do
            src[profile.name]=sourceFor(profile.name,profile.source)
            if not src[profile.name] then commandReady=false end
        end
    end
    local desired={}
    local candidates={arch={},archBase={},casing={},helix={},promenade={},stay={},equipment={},fitting={},command={},junction={}}
    local function queuePair(pair,limit,pool)
        if not pair then return end
        local first=pair[1]
        local resident=true
        for _,part in ipairs(pair) do
            if not mounted[part.key] then resident=false; break end
        end
        local priority,distance=score(first,cameraPoint,cameraLook,resident)
        if distance<=limit+(resident and 18 or 0) then
            first.priority=priority
            if #pair>1 then first.pair=pair end
            pool[#pool+1]=first
        end
    end
    local decor=arena:FindFirstChild("Decor")
    local platforms=arena:FindFirstChild("Platforms")
    if decor and decor:IsA("Folder")
        and platforms and platforms:IsA("Folder") then
        local decks=platforms:GetChildren()
        local spineEnds={}
        if src.JunctionTruss or src.JunctionUnderframe then
            for _,deck in ipairs(decks) do
                local step=deck:GetAttribute("SkySpineStep")
                if step==1 or step==10 then
                    local lane=step==1 and 1 or 2
                    spineEnds[lane]=spineEnds[lane]==nil and deck or false
                end
            end
        end
        for _,deck in ipairs(decks) do
            local lane=deck:GetAttribute("PromenadeLane")
            if lane and (src.JunctionTruss or src.PromenadeUnderframe) then
                local underframe
                if deck:GetAttribute("PromenadeStep")==4 then
                    local spine=spineEnds[lane]
                    if src.JunctionUnderframe then
                        underframe=collectJunctionTruss(arena,deck,spine,decor,scale,true)
                    end
                    if not underframe and src.JunctionTruss then
                        underframe=collectJunctionTruss(arena,deck,spine,decor,scale,false)
                    end
                elseif src.PromenadeUnderframe then
                    underframe=collectPromenadeUnderframe(arena,deck,decor)
                end
                queuePair(underframe and {underframe},(DISTANCE[tier] or DISTANCE.Low).promenade,
                    candidates.junction)
            end
            if src.SpineUnderframe and deck:GetAttribute("SkySpineStep") then
                local underframe=collectSpineUnderframe(arena,deck,decor)
                queuePair(underframe and {underframe},(DISTANCE[tier] or DISTANCE.Low).promenade,
                    candidates.junction)
            end
            local data=collectArch(arena,deck,decor,scale)
            if src.ArchAbutment and src.ArchGirder and deck:GetAttribute("PerimeterStep") then
                local range=ARCH_BASE_RANGE[tier] or ARCH_BASE_RANGE.Low
                queuePair(collectArchBase(arena,deck,decor,scale),range,candidates.archBase)
            end
            if not data and src.Crosshead and deck:GetAttribute("PromenadeStep") then
                data=collectPorticoPart(arena,deck,decor,scale)
            end
            if commandReady and deck:GetAttribute("SkySpineStep") then
                queuePair(collectCommandArt(arena,deck,decor,scale,commandProfiles),
                    COMMAND_DISTANCE[tier] or COMMAND_DISTANCE.Low,candidates.command)
            end
            if src.Stay and deck:GetAttribute("PromenadeStep") then
                queuePair(collectStayPair(arena,deck,decor,scale),
                    STAY_DISTANCE[tier],candidates.stay)
            end
            if fittingSourcesReady and deck:GetAttribute("PromenadeStep") then
                queuePair(collectFittingPair(arena,deck,decor,scale,fittings),
                    FITTING_DISTANCE[tier],candidates.fitting)
            end
            if equipment and src[equipment.name] and deck:GetAttribute("PromenadeStep") then
                local gear=collectEquipment(arena,deck,decor,scale,equipment)
                if gear then
                    gear.hoistBeam=hoistBeam
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
    local helixCap=caps(tier,touch,pressure,"helix")
    -- The nearest complete Orbital underframe can borrow the existing Low
    -- casing slot. Both models continue to share one pool on higher tiers.
    local borrowCasing=tier=="Low" and caps(tier,touch,pressure,"casing")>0
    if circuit and circuit:IsA("Folder") and (src.Helix or src.AccessChassis)
        and (helixCap>0 or borrowCasing) then
        for _,ramp in ipairs(circuit:GetChildren()) do
            local data=src.AccessChassis and collectAccessChassis(arena,ramp,circuit)
            if not data and src.Helix then
                data=collectHelix(arena,ramp,circuit)
            end
            if data then
                local priority,distance=score(data,cameraPoint,cameraLook,
                    mounted[ramp]~=nil)
                local limit=borrowCasing and 65 or (DISTANCE[tier] or DISTANCE.Low).helix
                if distance<=limit+(mounted[ramp] and 18 or 0) then
                    data.priority=priority
                    candidates.helix[#candidates.helix+1]=data
                end
            end
        end
    end
    borrowCasing=borrowCasing and #candidates.helix>0
    for _,kind in ipairs({"arch","archBase","casing","helix","promenade","stay","equipment","fitting","command","junction"}) do
        table.sort(candidates[kind],function(a,b)
            if a.priority~=b.priority then return a.priority<b.priority end
            return a.owner.Name<b.owner.Name
        end)
        local cap=caps(tier,touch,pressure,kind)
        if borrowCasing then
            if kind=="casing" then cap=0 end
            if kind=="helix" then cap=1 end
        end
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
            or data.otherDeck~=entry.otherDeck
            or src[entry.name]~=entry.source
            or ((isPortico(entry.category) or entry.category=="archBase" or entry.category=="casing"
                or entry.category=="helix")
                and not sameOriginals(entry,data))
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

function Kit.count(category,name)
    local count=0
    for _,entry in pairs(mounted) do
        if entry.visible and sourceIntact(entry)
            and (category==nil or category==entry.category)
            and (name==nil or name==entry.name) then
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
