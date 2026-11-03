-- Creator-approved, real 3D modular district architecture. The four IDs
-- were verified as Roblox Model packages with Approved moderation in
-- GitHub Actions 41629861517. Never trust client or marketplace identifiers.
-- Runtime content is strictly cosmetic and optional: native district
-- architecture remains even if Roblox Assets temporarily fail to load.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local DistrictRooflineAssets = {}

local APPROVED = {
    DistrictObservatory = 132020956214241,
    DistrictFreight = 88725004643299,
    DistrictTurbine = 84217436280282,
    DistrictAerial = 135791763112202,
}
local ORDER = {
    "DistrictObservatory", "DistrictFreight",
    "DistrictTurbine", "DistrictAerial",
}
local started = false

function DistrictRooflineAssets.approvedId(name)
    return APPROVED[name]
end

local function validate(clean)
    local count = 0
    for _, descendant in ipairs(clean:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if not descendant:IsA("MeshPart") then return false end
            count += 1
        elseif descendant:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count < 1 or count > 24 then return false end
    local _, size = clean:GetBoundingBox()
    -- Enforce the genuine four authored source footprints, allowing
    -- harmless importer rounding. Reject mis-sized or substituted assets.
    return size.X >= 10 and size.X <= 34
        and size.Y >= 17 and size.Y <= 50
        and size.Z >= 1.0 and size.Z <= 24
end

function DistrictRooflineAssets.start()
    if started then return end
    started = true

    local folder = ReplicatedStorage:FindFirstChild("ApprovedDistrictRooflineTemplates")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ApprovedDistrictRooflineTemplates"
        folder:SetAttribute("OwnerVerified", true)
        folder.Parent = ReplicatedStorage
    end

    local function loadOne(name)
        for attempt = 1, 3 do
            local ok, imported = pcall(
                AssetService.LoadAssetAsync, AssetService, APPROVED[name])
            if ok and imported and imported:IsA("Model") then
                local clean = OriginalMeshScenery.sanitize(imported)
                imported:Destroy()
                if not clean then
                    warn("Approved district roofline sanitizer rejected model", name)
                    return
                end
                if not validate(clean) then
                    clean:Destroy()
                    warn("Approved district roofline invalid geometry", name)
                    return
                end
                clean.Name = name
                clean:SetAttribute("OwnerVerified", true)
                clean:SetAttribute("CosmeticOnly", true)
                clean:SetAttribute("DistrictRoofline3D", true)
                clean:SetAttribute("Original3DAssetId", APPROVED[name])
                clean.Parent = folder
                folder:SetAttribute(name .. "Ready", true)
                return
            end
            if ok and typeof(imported) == "Instance" then
                imported:Destroy()
            end
            if attempt == 3 then
                warn("Approved 3D district roofline unavailable; native buildings retained",
                    name, tostring(imported))
                return
            end
            task.wait(3 * attempt)
        end
    end

    -- ONE asynchronous owner loader. OriginalMeshScenery already loads
    -- the skyline in two lanes; do not add four concurrent asset requests
    -- during join, block the match, or create client AssetService calls.
    task.spawn(function()
        for _, name in ipairs(ORDER) do
            loadOne(name)
        end
    end)
end

return DistrictRooflineAssets
