-- Genuine creator-authored Storm Harbor maritime signal station.
-- Owner Model #73237902371094, moderated Approved in Actions #41859877575.
-- Seven 2,816-triangle combined UV/tangent material MeshParts, including
-- THREE independently addressable live-animated Radar/Cable/Weight groups.
-- Client controls placement; all native decorations and movement remain.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Kit = {}
local ID = 73237902371094
local started = false

local function role(part)
    local b=part.Size
    local short,long=math.min(b.X,b.Z),math.max(b.X,b.Z)
    if b.Y >= 7.5 and b.Y <= 9.3 and long < .7 then
        return "Cable"
    end
    if b.Y <= 1.4 and long >= 8 and long <= 10.2
        and short < 1.3 then return "Radar" end
    if b.Y >= 1.4 and b.Y <= 2.3
        and b.X >= 2.2 and b.X <= 3.3
        and b.Z >= 2.2 and b.Z <= 3.3 then return "Weight" end
    return "Static"
end

local function check(model)
    local counts={Static=0,Radar=0,Cable=0,Weight=0}
    local count=0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then return false end
            count += 1
            local kind=role(part)
            counts[kind] += 1
            part:SetAttribute("OriginalHarborHeroMotionRole",kind)
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count ~= 7 or counts.Static ~= 4 or counts.Radar ~= 1
        or counts.Cable ~= 1 or counts.Weight ~= 1 then return false end
    local _,b=model:GetBoundingBox()
    return math.min(b.X,b.Z) >= 6.8
        and math.min(b.X,b.Z) <= 7.7
        and math.max(b.X,b.Z) >= 27.8
        and math.max(b.X,b.Z) <= 29.1
        and b.Y >= 27.5 and b.Y <= 28.7
end

function Kit.start()
    if started then return end
    started = true
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedHarborHeroStationTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name="ApprovedHarborHeroStationTemplates"
        holder.Parent=ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    if holder:FindFirstChild("SignalStation") then return end
    task.spawn(function()
        -- The player, gameplay, arena and important near-camera routes
        -- always load before this optional skyline landmark sculpture.
        task.wait(96)
        for attempt=1,3 do
            local ok,raw=pcall(GlobalApprovedImportGate.load,AssetService,ID)
            if ok and raw and raw:IsA("Model") then
                local safe=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not safe or not check(safe) then
                    if safe then safe:Destroy() end
                    warn("Original Harbor signal tower 3D rejected: invalid geometry or moving groups")
                    return
                end
                safe.Name="SignalStation"
                safe:SetAttribute("OwnerVerified",true)
                safe:SetAttribute("CosmeticOnly",true)
                safe:SetAttribute("OriginalHarborHeroStation3D",true)
                safe:SetAttribute("Original3DAssetId",ID)
                safe.Parent=holder
                holder:SetAttribute("SignalStationReady",true)
                return
            end
            if ok and typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Approved Harbor signal tower unavailable, native animated station retained")
            else
                task.wait(attempt*3)
            end
        end
    end)
end

return Kit
