local SouthMonumentGeometry = {}

local profiles = {
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
    profiles["ObservationArc" .. index] = "bevel"
end

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

function SouthMonumentGeometry.profile(name)
    return profiles[name]
end

function SouthMonumentGeometry.assetId(profile, variant)
    return if profile == "shaft" then shafts[variant] else assets[profile]
end

return SouthMonumentGeometry
