local HorizonMonumentGeometry = {}

local southProfiles = {
    Foundation = "bevel", FloorInset = "bevel",
    WestRadarPylon = "shaft", EastRadarPylon = "shaft",
    WestRadarDish = "roller", EastRadarDish = "roller",
    WestReceiver = "lens", EastReceiver = "lens",
    WestServiceBrace = "shaft", EastServiceBrace = "shaft",
    ObservatoryBridge = "beam", ObservatoryCabin = "bevel", ObservatoryGlass = "bevel",
    WestLift = "shaft", EastLift = "shaft",
    WestCrown = "cast", EastCrown = "cast",
    WestLiftRail = "shaft", EastLiftRail = "shaft",
    WestSuspension = "shaft", EastSuspension = "shaft",
    SkyTransfer = "beam", UnderslungLift = "bevel", TransferSignal = "cast",
    ExchangeCore = "shaft",
    WestFork = "beam", EastFork = "beam",
    WestFreightArm = "cast", EastFreightArm = "cast",
    WestCounterweight = "bevel", EastCounterweight = "bevel",
    WestSignal = "beam", EastSignal = "beam",
    CentralSwitchCab = "bevel", CabWindow = "bevel",
    LeftRingSupport = "shaft", RightRingSupport = "shaft",
    SuspendedOrb = "lens", OrbClamp = "beam",
    WestQuayColumn = "shaft", EastQuayColumn = "shaft",
    WestQuayCargo = "bevel", EastQuayCargo = "bevel",
    WestContainerHoist = "shaft", EastContainerHoist = "shaft",
    WestQuayRig = "cast", EastQuayRig = "cast",
    HarborLightshipBridge = "beam", HarborSignalCab = "bevel",
    HarborStormLens = "bevel", HarborStormBeacon = "shaft",
}
for index = 1, 14 do
    southProfiles["ObservationArc" .. index] = "bevel"
end

local northProfiles = {
    Foundation = "bevel", InsetBase = "bevel",
    RelayButtressWest = "shaft", RelayButtressEast = "shaft",
    RelaySparWest = "shaft", RelaySparEast = "shaft",
    ReceiverDishWest = "roller", ReceiverDishEast = "roller",
    ReceiverHubWest = "lens", ReceiverHubEast = "lens",
    PrimaryRelayMast = "shaft", RelayHead = "cast", DishBridge = "beam", ServicePanel = "bevel",
    LiftTowerWest = "shaft", LiftTowerEast = "shaft",
    TowerCrownWest = "cast", TowerCrownEast = "cast",
    TowerInlayWest = "shaft", TowerInlayEast = "shaft",
    TowerDiagonalWest = "shaft", TowerDiagonalEast = "shaft",
    OverheadServiceBridge = "beam", LowerTruss = "beam", HangingSignal = "cast",
    ExchangeLegWest = "shaft", ExchangeLegEast = "shaft",
    CantileverWest = "cast", CantileverEast = "cast",
    SwitchBraceWest = "shaft", SwitchBraceEast = "shaft",
    LowerExchange = "beam", UpperExchange = "beam",
    Switchboard = "bevel", SignalPylon = "shaft", SignalCrown = "cast",
    RingSupportLeft = "shaft", RingSupportRight = "shaft",
    RingFootLeft = "cast", RingFootRight = "cast",
    SuspendedReactorCore = "lens", CoreRetainer = "beam",
    QuayPortLeg = "shaft", QuayStarboardLeg = "shaft",
    QuayRakerPort = "shaft", QuayRakerStarboard = "shaft",
    QuayWinchPort = "bevel", QuayWinchStarboard = "bevel",
    QuayHoistPort = "shaft", QuayHoistStarboard = "shaft",
    QuayCraneSpanningBeam = "beam", QuayCraneCounterweight = "bevel",
    QuayStormMast = "shaft", QuayControlCab = "bevel",
    QuayCargoStack = "bevel", QuaySpreader = "beam",
}
for index = 1, 16 do
    northProfiles["ReactorArc" .. index] = "bevel"
end

local profiles = {
    ArenaSignatureMegastructure = northProfiles,
    SouthHorizonMonument = southProfiles,
}
local skylineProfiles = {
    Foundation = "bevel", StructuralCore = "shaft", TopCap = "cast",
    OuterRibL = "cast", OuterRibR = "cast", InsetL = "shaft", InsetR = "shaft",
    ReceiverHead = "rotor", ExchangeMast = "shaft", CrossAntenna = "beam",
    ServiceMast = "shaft", RelayAerial = "cast",
}
local depthProfiles = {DistantRoofMass = "depthHull", DistantAerial = "shaft"}
for _, direction in ipairs({"North", "East", "South", "West"}) do
    profiles["SkylineStructure" .. direction] = skylineProfiles
    for layer = 1, 2 do
        profiles["SkylineDepth" .. direction .. layer] = depthProfiles
    end
end

local assets = {
    bevel = 102746904688141,
    beam = 126298311664881,
    cast = 88962643359267,
    lens = 104654294187035,
    roller = 94830155055482,
    rotor = 133526819668194,
    depthHull = 80692067525256,
}
local shafts = {
    Classic = 91626128452597,
    Towers = 107521411452905,
    Crossroads = 93993697329658,
    Orbital = 119010829781313,
    Harbor = 76194593490199,
}

local floorCastings = {
    Classic = assets.bevel,
    Towers = 74708751016233,
    Crossroads = 84038993323581,
    Orbital = 123089585720736,
    Harbor = 94830155055482,
}

function HorizonMonumentGeometry.floorCastingAssetId(variant)
    return floorCastings[variant]
end

function HorizonMonumentGeometry.isFloorCasting(assetId, variant)
    return assetId ~= nil and (assetId == floorCastings[variant] or assetId == floorCastings.Classic)
end

function HorizonMonumentGeometry.isShaftAsset(assetId)
    for _, shaftId in pairs(shafts) do
        if shaftId == assetId then return true end
    end
    return false
end

function HorizonMonumentGeometry.profile(ownerName, name)
    local slots = profiles[ownerName]
    return slots and slots[name]
end

function HorizonMonumentGeometry.assetId(profile, variant)
    return if profile == "shaft" then shafts[variant] else assets[profile]
end

function HorizonMonumentGeometry.matchesHarborStructuralFallback(assetId, profile)
    if profile == "shaft" and HorizonMonumentGeometry.isShaftAsset(assetId) then return true end
    return (profile == "bevel" or profile == "shaft" or profile == "beam")
        and HorizonMonumentGeometry.isFloorCasting(assetId, "Harbor")
end

local promenadeRoofProfiles = {
    SurveyDish = "rotor", SurveyMast = "shaft", SurveyTip = "lens",
    HoistMachine = "cast", HoistRail = "shaft", HoistBeacon = "cast",
    SignalConcourse = "beam", ["SwitchFin-1"] = "beam", SwitchFin1 = "beam",
    GyroCore = "lens", ["ContainmentFin-1"] = "shaft", ContainmentFin1 = "shaft",
    FreightHoistArm = "beam", SuspendedCrate = "cast", CargoChain = "shaft",
}

function HorizonMonumentGeometry.promenadeRoofProfile(name)
    return promenadeRoofProfiles[name]
end

local skySpineCommandProfiles = {
    CommandRadar = "rotor", SurveyBeacon = "lens",
    CargoOverpass = "beam", HangingTransitCabin = "cast",
    ["RoutingAileron-1"] = "beam", RoutingAileron1 = "beam",
    OrbitalPowerOrb = "lens", OrbitRing = "rotor",
    DryDockHighCrane = "beam", CableLift = "shaft", FreightPod = "cast",
}

function HorizonMonumentGeometry.skySpineCommandProfile(name)
    return skySpineCommandProfiles[name]
end

return HorizonMonumentGeometry
