-- Seven creator-owned real 3D sculpted structure models, moderated Approved.
-- Evidence: GitHub Actions 41808940118. Never accept a client-selected ID.
-- All are optional cosmetics; native collision/route/fallback stays untouched.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Kit = {}
local APPROVED = {
    Classic = 91626128452597,
    Towers = 107521411452905,
    Crossroads = 93993697329658,
    Orbital = 119010829781313,
    Harbor = 76194593490199,
    LongCradle = 128914328933863,
    ShortCradle = 140716716476069,
}
local ORDER = {"Classic","Towers","Crossroads","Orbital","Harbor","LongCradle","ShortCradle"}

-- Import the real active world's columns FIRST, the shared 22-stud
-- genuine LongCradle SECOND, then the four inactive worlds. Previously
-- this universally useful 3D underframe came LAST, after up to four
-- irrelevant sources; players saw primitive underframes for longer.
-- Preserve all six approved IDs, the retry sequence and global
-- two-slot AssetService gate.
local function prioritizedOrder()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local variant = nil
    if generated and generated:IsA("Folder")
        and generated.Parent == workspace
        and arena and arena:IsA("Folder") and arena.Parent == generated then
        variant = arena:GetAttribute("VariantId")
    end
    if not APPROVED[variant] or variant == "LongCradle"
        or variant == "ShortCradle" then
        return ORDER
    end
    local ordered = {variant,"LongCradle","ShortCradle"}
    for _, name in ipairs(ORDER) do
        if name ~= variant and name ~= "LongCradle"
            and name ~= "ShortCradle" then
            ordered[#ordered + 1] = name
        end
    end
    return ordered
end
local started = false

function Kit.approvedId(name)
    return APPROVED[name]
end

function Kit.shaftProfile(variant)
    local id = APPROVED[variant]
    local holder = ReplicatedStorage:FindFirstChild("ApprovedLargeStructureTemplates")
    if not id or not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local model = holder:FindFirstChild(variant)
    if not model or not model:IsA("Model")
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("OriginalLargeStructure3D") ~= true
        or model:GetAttribute("Original3DAssetId") ~= id then return nil end
    local shaft = model:FindFirstChild("BeaconShaft")
    if shaft and shaft:IsA("MeshPart") and shaft.Archivable and shaft.MeshId ~= "" then
        return shaft, id
    end
    return nil
end

local function geometryAllowed(model,name)
    local n = 0
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            if not v:IsA("MeshPart") then return false end
            n += 1
        elseif v:IsA("LuaSourceContainer") then
            return false
        end
    end
    if n ~= 7 then return false end
    local _, box = model:GetBoundingBox()
    local xzLong = math.max(box.X,box.Z)
    local xzShort = math.min(box.X,box.Z)
    if name == "LongCradle" then
        return box.Y > 1.9 and box.Y < 4.7
            and xzLong >= 21.2 and xzLong <= 24.2
            and xzShort >= 9.1 and xzShort <= 11.4
    elseif name == "ShortCradle" then
        -- Creator-approved original: 10.13 x 2.34 x 16.52.
        return box.Y >= 2.1 and box.Y <= 2.8
            and xzLong >= 16.3 and xzLong <= 17.1
            and xzShort >= 9.9 and xzShort <= 10.6
    end
    return box.Y >= 13.4 and box.Y <= 15.1
        and xzLong >= 1.6 and xzLong <= 2.8
        and xzShort >= 1.5 and xzShort <= 2.7
end

local function markBeaconShaft(model)
    -- Every approved variant column has one 13.56-stud polygonal ARMOR
    -- shaft. The wider collars and taller boots are separate regions.
    local shaft
    for _, mesh in ipairs(model:GetChildren()) do
        if mesh:IsA("MeshPart") and mesh.Archivable and mesh.MeshId ~= "" then
            local size = mesh.Size
            if math.abs(size.Y - 13.56) < 0.13
                and math.min(size.X, size.Z) >= 1.27
                and math.max(size.X, size.Z) <= 1.70 then
                if shaft then return end
                shaft = mesh
            end
        end
    end
    if shaft then shaft.Name = "BeaconShaft" end
end

function Kit.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild("ApprovedLargeStructureTemplates")
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedLargeStructureTemplates"
        holder.Parent = ReplicatedStorage
    end
    if not holder:IsA("Folder") then return end
    holder:SetAttribute("OwnerVerified",true)

    -- Deferred, serialized, optional Roblox asset loading. A missing or
    -- rate-limited package never touches any server-owned route Part.
    task.spawn(function()
        -- Start after active hero signature requests (18-21s), without
        -- blocking bots or adding any extra concurrent import workers.
        task.wait(29)
        for _, name in ipairs(prioritizedOrder()) do
            if not holder:FindFirstChild(name) then
                for attempt = 1, 3 do
                    local ok, raw = pcall(
                        GlobalApprovedImportGate.load, AssetService, APPROVED[name])
                    if ok and raw and raw:IsA("Model") then
                        local safe = OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not safe or not geometryAllowed(safe,name) then
                            if safe then safe:Destroy() end
                            warn("Original large structure rejected by bounds",name)
                            break
                        end
                        safe.Name = name
                        safe:SetAttribute("OwnerVerified",true)
                        safe:SetAttribute("Original3DAssetId",APPROVED[name])
                        safe:SetAttribute("OriginalLargeStructure3D",true)
                        safe:SetAttribute("CosmeticOnly",true)
                        if name ~= "LongCradle" and name ~= "ShortCradle" then
                            markBeaconShaft(safe)
                        end
                        safe.Parent = holder
                        holder:SetAttribute(name.."Ready",true)
                        break
                    end
                    if ok and typeof(raw)=="Instance" then raw:Destroy() end
                    if attempt==3 then
                        warn("Original large structure unavailable: native fallback",
                            name,tostring(raw))
                    else
                        task.wait(attempt*3)
                    end
                end
            end
        end
    end)
end

return Kit
