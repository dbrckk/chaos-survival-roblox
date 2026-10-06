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

local animationCatalogModule = shared:FindFirstChild("AnimationCatalog")
check(animationCatalogModule ~= nil, "AnimationCatalog module missing")
local AnimationCatalog = require(animationCatalogModule)
for name, id in pairs(AnimationCatalog.AISurvivor or {}) do
    check(type(id) == "number" and id > 0, "Invalid AI animation id: " .. tostring(name))
    check(AnimationCatalog.assetId(id) == "rbxassetid://" .. tostring(id), "Invalid animation asset URI: " .. tostring(name))
end

local visualBudgetModule = shared:FindFirstChild("VisualBudgetRules")
check(visualBudgetModule ~= nil, "VisualBudgetRules module missing")
local VisualBudgetRules = require(visualBudgetModule)
for _, tierName in ipairs({"High", "Medium", "Low"}) do
    local budget = VisualBudgetRules.forTier(tierName)
    check(type(budget.Parts) == "number" and budget.Parts > 0, "Invalid parts budget: " .. tierName)
    check(type(budget.Lights) == "number" and budget.Lights > 0, "Invalid lights budget: " .. tierName)
    check(type(budget.Effects) == "number" and budget.Effects > 0, "Invalid effects budget: " .. tierName)
end

local mapBuilderModule = server:FindFirstChild("MapBuilder")
check(mapBuilderModule ~= nil, "MapBuilder module missing")
local MapBuilder = require(mapBuilderModule)
check(type(MapBuilder.build) == "function", "MapBuilder.build missing")

local aiServiceModule = server:FindFirstChild("AISurvivorService")
check(aiServiceModule ~= nil, "AISurvivorService module missing")
local aiOk, AISurvivorService = pcall(require, aiServiceModule)
check(aiOk, "Cannot require AISurvivorService: " .. tostring(AISurvivorService))
check(type(AISurvivorService) == "table", "AISurvivorService did not return a table")
for _, methodName in ipairs({
    "start",
    "setRoundState",
    "aliveRoundCount",
    "visibleCount",
    "activeCount",
    "names",
}) do
    check(
        type(AISurvivorService[methodName]) == "function",
        "AISurvivorService." .. methodName .. " missing"
    )
end

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
    "ChaosShardCollected",
    "PerformancePulse",
    "AccessibilitySettings",
    "SocialSignal",
    "SocialReaction",
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
