-- One genuine creator-owned Roblox Approved solid six-material district sidewall
-- shell. This is NOT a Part/WedgePart mock: 1,764 original triangles from
-- approved workflow #43302925840, asset 77387019170428 (Approved).
-- Server owns import/security; the client only clones sanitized originals.
-- Optional scenery cannot block player joins, bots or gameplay.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Kit = {}
local ASSET_ID = 77387019170428
local started = false

local function genuine(model)
    if not model or not model:IsA("Model") then return false end
    local meshCount = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return false end
            meshCount += 1
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    -- 6 separate original glTF metal/ceramic/carbon/non-slip primitives.
    if meshCount ~= 6 then return false end
    local _, bounds = model:GetBoundingBox()
    local large = math.max(bounds.X, bounds.Z)
    local small = math.min(bounds.X, bounds.Z)
    return large >= 9.7 and large <= 11.3
        and small >= 6.8 and small <= 8.1
        and bounds.Y >= 12.5 and bounds.Y <= 14.0
end

function Kit.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedDistrictSidewallShellTemplates")
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedDistrictSidewallShellTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified", true)
    -- Defer until the four existing original district fronts have begun
    -- their serial AssetService loads. The shared import gate still caps
    -- ALL simultaneously executing owner imports to two.
    task.spawn(function()
        task.wait(22)
        for attempt = 1, 3 do
            local ok, raw = pcall(GlobalApprovedImportGate.load,
                AssetService, ASSET_ID)
            if ok and raw and raw:IsA("Model") then
                local clean = OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not genuine(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved original district sidewall rejected: "
                        .. "source geometry does not match 6-mesh envelope")
                    return
                end
                clean.Name = "Sidewall"
                clean:SetAttribute("OwnerVerified", true)
                clean:SetAttribute("CosmeticOnly", true)
                clean:SetAttribute("Original3DAssetId", ASSET_ID)
                clean:SetAttribute("OriginalDistrictSidewallShell3D", true)
                clean.Parent = holder
                holder:SetAttribute("SidewallReady", true)
                return
            end
            if ok and typeof(raw) == "Instance" then raw:Destroy() end
            if attempt == 3 then
                warn("Approved original district sidewall unavailable; "
                    .. "native walls retained", tostring(raw))
            else
                task.wait(attempt * 3)
            end
        end
    end)
end

return Kit
