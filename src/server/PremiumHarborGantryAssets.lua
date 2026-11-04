-- Two source-authored real Harbor container-port cranes. Approved Roblox
-- owner Models #86657004812104 and #82714598831399, 3400 / 5232 triangles,
-- seven materials each, source verified by GitHub Actions #41854747878.
-- Only cosmetic templates are replicated; all 4 original server cranes
-- (and their streaming/Lod/real collision invariants) remain untouched.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local Assets = {}
local started = false
local SOURCES = {
    {"ContainerGantry", 86657004812104},
    {"CableGantry", 82714598831399},
}

local function geometryOK(model)
    local count = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then return false end
            count += 1
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count ~= 7 then return false end
    local _, b = model:GetBoundingBox()
    -- Source X = 21.86, Y = 36.08949, Z = 44.0. glTF can swap X/Z,
    -- never accept a different Marketplace model just because of a tag.
    local short, long = math.min(b.X,b.Z), math.max(b.X,b.Z)
    return short >= 21.1 and short <= 22.8
        and long >= 43.3 and long <= 45.0
        and b.Y >= 35.5 and b.Y <= 36.8
end

function Assets.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild("ApprovedHarborGantryTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedHarborGantryTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified", true)
    task.spawn(function()
        -- The lobby/route and cargo ship are prioritized. These distant
        -- source Models must never delay a round or monopolize startup API.
        task.wait(76)
        for _, spec in ipairs(SOURCES) do
            local name, id = spec[1], spec[2]
            if holder:FindFirstChild(name) then continue end
            for attempt = 1, 3 do
                local ok, raw = pcall(AssetService.LoadAssetAsync,
                    AssetService, id)
                if ok and raw and raw:IsA("Model") then
                    local clean = OriginalMeshScenery.sanitize(raw)
                    raw:Destroy()
                    if not clean or not geometryOK(clean) then
                        if clean then clean:Destroy() end
                        warn("Approved Harbor crane failed strict geometry source guard", name)
                        break
                    end
                    clean.Name = name
                    clean:SetAttribute("OwnerVerified", true)
                    clean:SetAttribute("CosmeticOnly", true)
                    clean:SetAttribute("OriginalHarborGantry3D", true)
                    clean:SetAttribute("Original3DAssetId", id)
                    clean.Parent = holder
                    holder:SetAttribute(name .. "Ready", true)
                    break
                end
                if ok and typeof(raw) == "Instance" then raw:Destroy() end
                if attempt == 3 then
                    warn("Approved Harbor crane not loaded, native fallback retained",
                        name, tostring(raw))
                else
                    task.wait(3 * attempt)
                end
            end
            task.wait(4)
        end
    end)
end

return Assets
