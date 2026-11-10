-- Creator-owned original seven-material triangulated 3D Harbor skywalk
-- gantry with suspended load and underside frame; moderation Approved.
-- GitHub evidence: actions/runs/41837415151. NO new walkable decks.
-- Server remains sole owner of bridges, collision, hazards and bots.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Kit = {}
local ID = 134157110756659
local started = false

function Kit.approvedId()
    return ID
end

local function matches(model)
    local n = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then return false end
            n += 1
        elseif part:IsA("LuaSourceContainer") then return false end
    end
    if n < 1 or n > 12 then return false end
    local _, b = model:GetBoundingBox()
    local short = math.min(b.X, b.Z)
    local long = math.max(b.X, b.Z)
    -- Roblox may rotate the source X/Z frame on glTF import.
    return short >= 10.8 and short <= 15.5
        and long >= 18.2 and long <= 21.6
        and b.Y >= 18.4 and b.Y <= 21.8
end

function Kit.start()
    if started then return end
    started = true
    local folder = ReplicatedStorage:FindFirstChild(
        "ApprovedHarborPromenadePortalTemplates")
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ApprovedHarborPromenadePortalTemplates"
        folder.Parent = ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified", true)
    if folder:FindFirstChild("CargoGantry") then return end

    -- This late cosmetic load must not contend with the initial lobby,
    -- first round or earlier already-approved hero/ground Models.
    task.spawn(function()
        task.wait(52)
        for attempt = 1, 3 do
            local ok, raw = pcall(
                GlobalApprovedImportGate.load, AssetService, ID)
            if ok and raw and raw:IsA("Model") then
                local safe = OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not safe or not matches(safe) then
                    if safe then safe:Destroy() end
                    warn("Approved Harbor skywalk portal geometry rejected")
                    return
                end
                safe.Name = "CargoGantry"
                safe:SetAttribute("Original3DAssetId", ID)
                safe:SetAttribute("OwnerVerified", true)
                safe:SetAttribute("CosmeticOnly", true)
                safe:SetAttribute("OriginalHarborPromenadePortal3D", true)
                safe.Parent = folder
                folder:SetAttribute("CargoGantryReady", true)
                return
            end
            if ok and typeof(raw) == "Instance" then raw:Destroy() end
            if attempt == 3 then
                warn("Approved Harbor cargo gantry unavailable, native portal retained",
                    tostring(raw))
            else
                task.wait(3 * attempt)
            end
        end
    end)
end

return Kit
