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

local assets = {
    bevel = 102746904688141,
    beam = 126298311664881,
    cast = 88962643359267,
    lens = 104654294187035,
    roller = 94830155055482,
}
local shafts = {
    Classic = 91626128452597,
    Towers = 107521411452905,
    Crossroads = 93993697329658,
    Orbital = 119010829781313,
    Harbor = 76194593490199,
}

function HorizonMonumentGeometry.profile(ownerName, name)
    local slots = profiles[ownerName]
    return slots and slots[name]
end

function HorizonMonumentGeometry.assetId(profile, variant)
    return if profile == "shaft" then shafts[variant] else assets[profile]
end

return HorizonMonumentGeometry
