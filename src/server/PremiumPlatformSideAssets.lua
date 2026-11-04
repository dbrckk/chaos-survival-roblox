-- Six original creator-owned 3D structural cosmetics. Real Roblox
-- Model IDs, all moderated Approved in GitHub Actions #41798024000.
-- Never change live gameplay platforms, collision, hazard cues or camera.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local Kit = {}
local APPROVED = {
    Classic = 92590025262416,
    Towers = 85204303404953,
    Crossroads = 116452624086023,
    Orbital = 118444100674717,
    Harbor = 124136394128432,
    Bridge = 122766792774607,
}
local ORDER = {"Classic", "Towers", "Crossroads", "Orbital", "Harbor", "Bridge"}
local started = false

function Kit.approvedId(name)
    return APPROVED[name]
end

local function validModel(model, kind)
    local n = 0
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return false end
            n += 1
        elseif item:IsA("LuaSourceContainer") then
            return false
        end
    end
    if n < 1 or n > 12 then return false end
    local _, size = model:GetBoundingBox()
    local length = math.max(size.X, size.Z)
    local depth = math.min(size.X, size.Z)
    if kind == "Bridge" then
        return length >= 9.0 and length <= 11.2
            and depth >= .4 and depth <= 1.5
            and size.Y >= 1.25 and size.Y <= 2.65
    end
    return length >= 10.6 and length <= 12.3
        and depth >= 7.8 and depth <= 9.6
        and size.Y >= 2.0 and size.Y <= 4.1
end

function Kit.start()
    if started then return end
    started = true
    local folder = ReplicatedStorage:FindFirstChild("ApprovedPlatformSideTemplates")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ApprovedPlatformSideTemplates"
        folder.Parent = ReplicatedStorage
    end
    if not folder:IsA("Folder") then return end
    folder:SetAttribute("OwnerVerified", true)

    -- The existing core route, hazards and approved floor imports must load
    -- first; optional side skins are serialized and may fail safely.
    task.spawn(function()
        task.wait(74)
        for _, name in ipairs(ORDER) do
            if not folder:FindFirstChild(name) then
                for attempt = 1, 3 do
                    local ok, raw = pcall(
                        AssetService.LoadAssetAsync, AssetService, APPROVED[name])
                    if ok and raw and raw:IsA("Model") then
                        local clean = OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not clean or not validModel(clean, name) then
                            if clean then clean:Destroy() end
                            warn("Original platform-side Model rejected by geometry gate",
                                name)
                            break
                        end
                        clean.Name = name
                        clean:SetAttribute("Original3DAssetId", APPROVED[name])
                        clean:SetAttribute("OriginalStructuralSide3D", true)
                        clean:SetAttribute("OwnerVerified", true)
                        clean:SetAttribute("CosmeticOnly", true)
                        clean.Parent = folder
                        folder:SetAttribute(name .. "Ready", true)
                        break
                    end
                    if ok and typeof(raw) == "Instance" then raw:Destroy() end
                    if attempt == 3 then
                        warn("Original platform-side 3D unavailable; native fallback",
                            name, tostring(raw))
                    else
                        task.wait(3 * attempt)
                    end
                end
            end
        end
    end)
end

return Kit
