-- Six creator-owned real 3D sculpted structure models, moderated Approved.
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
}
local ORDER = {"Classic","Towers","Crossroads","Orbital","Harbor","LongCradle"}
local started = false

function Kit.approvedId(name)
    return APPROVED[name]
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
    if n < 1 or n > 12 then return false end
    local _, box = model:GetBoundingBox()
    local xzLong = math.max(box.X,box.Z)
    local xzShort = math.min(box.X,box.Z)
    if name == "LongCradle" then
        return box.Y > 1.9 and box.Y < 4.7
            and xzLong >= 21.2 and xzLong <= 24.2
            and xzShort >= 9.1 and xzShort <= 11.4
    end
    return box.Y >= 13.4 and box.Y <= 15.1
        and xzLong >= 1.6 and xzLong <= 2.8
        and xzShort >= 1.5 and xzShort <= 2.7
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
        task.wait(35)
        for _, name in ipairs(ORDER) do
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
