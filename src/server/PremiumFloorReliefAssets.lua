-- Six original, owner-created, Roblox Approved low-profile floor relief Models.
-- Upload source receipt: GitHub Actions #41736767816. Asset IDs below are
-- Model package IDs, never used as MeshPart.MeshId strings.
-- No gameplay collision or player interaction is ever added by this loader.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Kit = {}
local APPROVED = {
    Essential = 71267601603297,
    Classic = 102746904688141,
    Towers = 74708751016233,
    Crossroads = 84038993323581,
    Orbital = 123089585720736,
    Harbor = 94830155055482,
    -- One piece of mechanical art for each remaining primitive family.
    -- The bolt source is authored at 10x scale for reliable Roblox import;
    -- the client scales it to the actual compact mechanical dimensions.
    CornerGuard = 102215174919938,
    AnchorBolt = 92226531849432,
    HarborTie = 135412901717584,
}
local ORDER = {
    "Essential", "Classic", "Towers", "Crossroads", "Orbital", "Harbor",
    "CornerGuard", "AnchorBolt", "HarborTie",
}
local started = false

function Kit.approvedId(variant)
    return APPROVED[variant]
end

local function validRelief(model, kind)
    local pieces = 0
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return false end
            pieces += 1
        elseif item:IsA("LuaSourceContainer") then
            return false
        end
    end
    if pieces < 1 or pieces > 12 then return false end
    local _, size = model:GetBoundingBox()
    if kind == "CornerGuard" then
        return size.X >= 4.7 and size.X <= 5.6
            and size.Z >= 4.7 and size.Z <= 5.6
            and size.Y >= .24 and size.Y <= .56
    elseif kind == "AnchorBolt" then
        -- Deliberately imported at 10× scale. A .4-stud upload previously
        -- produced an ambiguous HTTP 500; never blindly re-submit it.
        return size.X >= 3.1 and size.X <= 6.1
            and size.Z >= 3.1 and size.Z <= 6.1
            and size.Y >= 1.5 and size.Y <= 3.0
    elseif kind == "HarborTie" then
        return size.X >= .90 and size.X <= 1.25
            and size.Z >= .90 and size.Z <= 1.25
            and size.Y >= .21 and size.Y <= .52
    end
    return size.X >= 2.7 and size.X <= 12
        and size.Z >= .45 and size.Z <= 5.5
        and size.Y >= .06 and size.Y <= .75
end

function Kit.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild("ApprovedFloorReliefTemplates")
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedFloorReliefTemplates"
        holder.Parent = ReplicatedStorage
    end
    if not holder:IsA("Folder") then return end
    holder:SetAttribute("OwnerVerified", true)

    -- Gameplay and core imports have first priority. Six floor relief
    -- models followed by THREE small mechanical sculpt families load late
    -- through one serialized lane (no extra concurrent AssetService load).
    -- Failure always leaves the original nonphysical floor art intact.
    task.spawn(function()
        task.wait(34)
        for _, name in ipairs(ORDER) do
            if not holder:FindFirstChild(name) then
                for attempt = 1, 3 do
                    local ok, raw = pcall(
                        GlobalApprovedImportGate.load, AssetService, APPROVED[name])
                    if ok and raw and raw:IsA("Model") then
                        local clean = OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not clean or not validRelief(clean, name) then
                            if clean then clean:Destroy() end
                            warn("Original approved floor geometry refused", name)
                            break
                        end
                        clean.Name = name
                        clean:SetAttribute("Original3DAssetId", APPROVED[name])
                        clean:SetAttribute("OwnerVerified", true)
                        clean:SetAttribute("CosmeticOnly", true)
                        clean:SetAttribute("OriginalFloorRelief3D", true)
                        clean.Parent = holder
                        holder:SetAttribute(name .. "Ready", true)
                        break
                    end
                    if ok and typeof(raw) == "Instance" then raw:Destroy() end
                    if attempt == 3 then
                        warn("Approved 3D floor import unavailable; original art kept",
                            name, tostring(raw))
                    else
                        task.wait(attempt * 4)
                    end
                end
            end
        end
    end)
end

return Kit
