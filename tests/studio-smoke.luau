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

check(disasterCount >= 10, "Expected at least 10 disasters, found " .. tostring(disasterCount))

local root = MapBuilder.build(Config)
check(root ~= nil and root.Parent == workspace, "MapBuilder did not create map")
check(root:FindFirstChild("Lobby") ~= nil, "Lobby missing")
check(root:FindFirstChild("Arena") ~= nil, "Arena missing")
check(root.Arena:FindFirstChild("Spawns") ~= nil, "Arena spawns missing")
check(#root.Arena.Spawns:GetChildren() >= 4, "Not enough arena spawns")

print("CHAOS_SMOKE_OK disasters=" .. tostring(disasterCount))
