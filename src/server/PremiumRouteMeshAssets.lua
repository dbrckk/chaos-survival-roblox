-- Nine original Roblox Model packages now exist in the owner inventory;
-- these THREE approved imports are genuine triangulated UV/tangent 3D assets.
-- The loader is cosmetic-only and never changes live authoritative platforms.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local PremiumRouteMeshAssets = {}

local APPROVED = {
    PremiumJumpDeck = 98478693994864,
    PremiumSkybridgeModule = 94023662427980,
    PremiumGroundTile = 72507987666671,
}
local ORDER = {"PremiumJumpDeck", "PremiumSkybridgeModule", "PremiumGroundTile"}
local started = false

-- Public provenance for QA and static Roblox Cloud suites. Do not accept
-- client-provided IDs or automatically load similarly named marketplace art.
function PremiumRouteMeshAssets.approvedId(name)
    return APPROVED[name]
end

function PremiumRouteMeshAssets.start()
    if started then return end
    started = true

    local folder = ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "PremiumRouteMeshTemplates"
        folder:SetAttribute("OwnerVerified", true)
        folder.Parent = ReplicatedStorage
    end

    -- No client ever fetches remote Roblox assets itself; a single server
    -- sanitizer rejects scripts, effects, arbitrary constraints and any
    -- package outside the existing trusted owner/size/part-count bounds.
    local function loadOne(name)
        local assetId = APPROVED[name]
        for attempt = 1, 3 do
            local ok, raw = pcall(
                AssetService.LoadAssetAsync, AssetService, assetId)
            if ok and raw and raw:IsA("Model") then
                local safe = OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not safe then
                    warn("Premium route mesh rejected: invalid package", name)
                    return
                end

                local meshCount = 0
                for _, part in ipairs(safe:GetDescendants()) do
                    if part:IsA("MeshPart") then
                        meshCount += 1
                    end
                end
                if meshCount == 0 then
                    safe:Destroy()
                    warn("Premium route import contained no real MeshPart", name)
                    return
                end

                safe.Name = name
                safe:SetAttribute("OwnerVerified", true)
                safe:SetAttribute("Original3DAssetId", assetId)
                safe:SetAttribute("CosmeticOnly", true)
                safe:SetAttribute("PremiumRoute3D", name ~= "PremiumGroundTile")
                safe:SetAttribute("PremiumGround3D", name == "PremiumGroundTile")
                safe.Parent = folder
                folder:SetAttribute(name .. "Ready", true)
                return
            end
            if ok and typeof(raw) == "Instance" then raw:Destroy() end
            if attempt == 3 then
                warn("Approved 3D route model unavailable; native fallback remains",
                    name, tostring(raw))
                return
            end
            task.wait(attempt * 3)
        end
    end

    for _, name in ipairs(ORDER) do
        task.spawn(loadOne, name)
    end
end

return PremiumRouteMeshAssets
