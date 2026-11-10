-- Genuine original Crossroads gantry, creator-owned Roblox Model
-- 90844491148907 (Moderation Approved; one-time import 42864120791).
-- Seven MeshParts; never affects gameplay, spawn, physics or map generation.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local Assets = {}
local ID = 90844491148907
local started = false
local NAME = "ApprovedCrossroadsGantryTemplates"
local HEIGHT = 3.6
local LONG = 27.92
local SHORT = 2.74

local function genuine(model)
    local parts = 0
    for _,descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if not descendant:IsA("MeshPart") or descendant.CanCollide
                or descendant.CanTouch or descendant.CanQuery then return false end
            parts += 1
        elseif descendant:IsA("LuaSourceContainer") then
            return false
        end
    end
    if parts ~= 7 then return false end
    local _,size=model:GetBoundingBox()
    local horizontal={size.X,size.Z}
    table.sort(horizontal)
    return math.abs(size.Y-HEIGHT) <= .40
        and math.abs(horizontal[1]-SHORT) <= .38
        and math.abs(horizontal[2]-LONG) <= .40
end

function Assets.start()
    if started then return end
    started=true
    local holder=ReplicatedStorage:FindFirstChild(NAME)
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name=NAME
        holder.Parent=ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- Avoid a new owner-wide asset API burst at first player spawn.
        -- One source feeds four native gantries, no per-player network fetch.
        task.wait(98)
        if holder:FindFirstChild("Gantry") then return end
        for attempt=1,3 do
            local ok,raw=pcall(AssetService.LoadAssetAsync,AssetService,ID)
            if ok and raw and raw:IsA("Model") then
                local safe=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not safe or not genuine(safe) then
                    if safe then safe:Destroy() end
                    warn("Crossroads forged gantry rejected by geometry gate")
                    return
                end
                safe.Name="Gantry"
                safe:SetAttribute("OwnerVerified",true)
                safe:SetAttribute("CosmeticOnly",true)
                safe:SetAttribute("OriginalCrossroadsGantry3D",true)
                safe:SetAttribute("Original3DAssetId",ID)
                safe.Parent=holder
                holder:SetAttribute("GantryReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Crossroads forged gantry unavailable",tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
