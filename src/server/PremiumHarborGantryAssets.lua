-- Two independently ANIMATABLE original Harbor port cranes. These exact
-- creator Model IDs were source-gated and moderated Approved in GitHub
-- workflow #41856104459 (3400 / 5232 triangles, 7 UV/tangent meshes).
-- The 7 source groups preserve separate Trolley / Cable / Load / Static
-- so clients can follow the EXISTING HarborGantryMotionRules animation.
-- No new physical scenery, RemoteEvents, light or server tick.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local Assets = {}
local started = false
local SOURCES = {
    {"ContainerGantry", 75684193304551},
    {"CableGantry", 98809955094422},
}

-- The standard glTF importer may rename material primitives. Their
-- collision-free authored bounds are distinctive, so classify the three
-- separate moving MeshParts by REAL geometry instead of guessed names.
-- The other four material MeshParts remain fixed manufacturing structure.
local function roleOf(part)
    local b = part.Size
    local broad, thin = math.max(b.X,b.Z), math.min(b.X,b.Z)
    if b.Y >= 11.8 and b.Y <= 14.7
        and broad >= 6.5 and broad <= 9.5 and thin < 1.1 then
        return "Cable"
    end
    if b.Y >= 3.7 and b.Y <= 5.4
        and broad >= 7 and broad <= 9.5
        and thin >= 3.4 and thin <= 5.5 then
        return "Trolley"
    end
    if b.Y >= 6.6 and b.Y <= 10
        and broad >= 8.2 and broad <= 11.4
        and thin >= 4.1 and thin <= 7.7 then
        return "Load"
    end
    return "Static"
end

local function geometryOK(model)
    local counts = {Static=0,Trolley=0,Cable=0,Load=0}
    local count = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then return false end
            count += 1
            local role = roleOf(part)
            counts[role] += 1
            part:SetAttribute("OriginalHarborGantryKineticRole", role)
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count ~= 7 or counts.Static ~= 4 or counts.Trolley ~= 1
        or counts.Cable ~= 1 or counts.Load ~= 1 then
        return false
    end
    local _, b = model:GetBoundingBox()
    local short, long = math.min(b.X,b.Z), math.max(b.X,b.Z)
    return short >= 21.1 and short <= 22.8
        and long >= 43.3 and long <= 45.0
        and b.Y >= 35.5 and b.Y <= 36.8
end

function Assets.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedHarborKineticGantryTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedHarborKineticGantryTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified", true)
    task.spawn(function()
        -- Gameplay and first-screen assets load first. These *distant*
        -- sculpted cranes never compete with the first playable round.
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
                        warn("Approved animated Harbor crane rejected: geometry/role mismatch",
                            name)
                        break
                    end
                    clean.Name = name
                    clean:SetAttribute("OwnerVerified", true)
                    clean:SetAttribute("CosmeticOnly", true)
                    clean:SetAttribute("OriginalHarborKineticGantry3D", true)
                    clean:SetAttribute("Original3DAssetId", id)
                    clean.Parent = holder
                    holder:SetAttribute(name .. "Ready", true)
                    break
                end
                if ok and typeof(raw) == "Instance" then raw:Destroy() end
                if attempt == 3 then
                    warn("Animated Harbor crane unavailable; native crane retained",
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
