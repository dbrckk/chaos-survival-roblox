local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function check(condition, message)
    if not condition then
        error("SMOKE_TEST_FAILED: " .. message, 0)
    end
end

print("CHAOS_SMOKE_BEGIN")

local server = ServerScriptService:FindFirstChild("Server")
check(server ~= nil, "Server container missing")

local shared = ReplicatedStorage:FindFirstChild("Shared")
check(shared ~= nil, "Shared container missing")

local configModule = shared:FindFirstChild("Config")
check(configModule ~= nil, "Config module missing")
local Config = require(configModule)

check(type(Config.RoundSeconds) == "number" and Config.RoundSeconds > 0, "Invalid RoundSeconds")
check(type(Config.IntermissionSeconds) == "number" and Config.IntermissionSeconds >= 0, "Invalid IntermissionSeconds")

local mapBuilderModule = server:FindFirstChild("MapBuilder")
check(mapBuilderModule ~= nil, "MapBuilder module missing")
local MapBuilder = require(mapBuilderModule)
check(type(MapBuilder.build) == "function", "MapBuilder.build missing")

local disastersFolder = server:FindFirstChild("Disasters")
check(disastersFolder ~= nil, "Disasters folder missing")

local disasterCount = 0
for _, child in ipairs(disastersFolder:GetChildren()) do
    if child:IsA("ModuleScript") then
        local ok, disaster = pcall(require, child)
        check(ok, "Cannot require disaster " .. child.Name .. ": " .. tostring(disaster))
        check(type(disaster) == "table", child.Name .. " did not return a table")
        check(type(disaster.Name) == "string" and #disaster.Name > 0, child.Name .. " missing Name")
        check(type(disaster.start) == "function", child.Name .. " missing start()")
        disasterCount += 1
    end
end

check(disasterCount == 11, "Expected exactly 11 disasters, found " .. tostring(disasterCount))

local arenaVariantsModule = server:FindFirstChild("ArenaVariants")
check(arenaVariantsModule ~= nil, "ArenaVariants module missing")
local ArenaVariants = require(arenaVariantsModule)
check(type(ArenaVariants.Order) == "table", "ArenaVariants.Order missing")
check(#ArenaVariants.Order == 4, "Expected exactly 4 arena variants")

local root = MapBuilder.build(Config, ArenaVariants.Order[1], ArenaVariants)
check(root ~= nil and root.Parent == workspace, "MapBuilder did not create map")
check(root:FindFirstChild("Lobby") ~= nil, "Lobby missing")

for _, arenaId in ipairs(ArenaVariants.Order) do
    MapBuilder.buildArena(Config, arenaId, ArenaVariants)
    local arena = root:FindFirstChild("Arena")
    check(arena ~= nil, "Arena missing after build: " .. tostring(arenaId))
    local spawns = arena:FindFirstChild("Spawns")
    check(spawns ~= nil, "Arena spawns missing: " .. tostring(arenaId))
    check(#spawns:GetChildren() >= 4, "Not enough arena spawns: " .. tostring(arenaId))
    local base = arena:FindFirstChild("Base")
    check(base ~= nil and base:IsA("BasePart"), "Arena base missing: " .. tostring(arenaId))
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
check(remotes ~= nil and remotes:IsA("Folder"), "Remotes folder missing")
for _, remoteName in ipairs({
    "RoundState",
    "VoteDisaster",
    "DailyReward",
    "QuestUpdate",
    "RoundFeedback",
    "ClientReady",
    "ArenaMechanicFeedback",
    "HazardImpactFeedback",
    "HazardNearMiss",
    "CosmeticState",
    "CosmeticAction",
    "MonetizationState",
    "MonetizationAction",
    "AchievementState",
}) do
    local remote = remotes:FindFirstChild(remoteName)
    check(remote ~= nil and remote:IsA("RemoteEvent"), "RemoteEvent missing or wrong class: " .. remoteName)
end

print(
    "CHAOS_SMOKE_OK disasters="
        .. tostring(disasterCount)
        .. " arenas="
        .. tostring(#ArenaVariants.Order)
)
