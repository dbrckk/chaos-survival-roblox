-- Creator-owned, Roblox-Approved FULL collision-covering original lobby shell.
-- Source and moderated import: GitHub Actions #41825253849.
-- Model 75945454705246: 3.55 x 10.36 x 3.52-stud 7-material
-- closed octagonal core encases the server's 2.2 x 10 x 2.2 pylon.
-- Strictly optional replication of sanitized 3D ART, never collisions.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Kit = {}
local APPROVED_ID = 75945454705246
local started = false

function Kit.approvedId()
    return APPROVED_ID
end

local function matchingOriginal(model)
    local n = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then return false end
            n += 1
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if n < 1 or n > 12 then return false end
    local _, bounds = model:GetBoundingBox()
    -- OBJ/glTF imported X and Z can swap; symmetric geometric envelope.
    return math.min(bounds.X, bounds.Z) >= 3.40
        and math.max(bounds.X, bounds.Z) <= 4.05
        and bounds.Y >= 10.25 and bounds.Y <= 10.75
end

function Kit.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedLobbyPylonShellTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedLobbyPylonShellTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified", true)
    if holder:FindFirstChild("LobbyPylonShell") then return end

    -- Avoid competing with the early real lobby gate upload loader.
    -- No gameplay code waits for this optional 3D source.
    task.spawn(function()
        task.wait(23)
        for attempt = 1, 3 do
            local ok, raw = pcall(
                GlobalApprovedImportGate.load, AssetService, APPROVED_ID)
            if ok and raw and raw:IsA("Model") then
                local safe = OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not safe or not matchingOriginal(safe) then
                    if safe then safe:Destroy() end
                    warn("Approved enclosed lobby shell rejected by geometry")
                    return
                end
                safe.Name = "LobbyPylonShell"
                safe:SetAttribute("Original3DAssetId", APPROVED_ID)
                safe:SetAttribute("OwnerVerified", true)
                safe:SetAttribute("CosmeticOnly", true)
                safe:SetAttribute("OriginalLobbyPylonShell3D", true)
                safe:SetAttribute("EnclosesCollider", true)
                safe.Parent = holder
                holder:SetAttribute("LobbyPylonShell3DReady", true)
                return
            end
            if ok and typeof(raw) == "Instance" then raw:Destroy() end
            if attempt == 3 then
                warn("Approved lobby shell unavailable, keeping visible native pylon",
                    tostring(raw))
            else
                task.wait(3 * attempt)
            end
        end
    end)
end

return Kit
