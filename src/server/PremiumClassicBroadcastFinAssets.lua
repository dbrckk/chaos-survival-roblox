-- Creator-owned original Classic airfoil source (Roblox Approved Model).
-- Verified owner upload #42866820903: Model 123049626693705.
-- Optional sanitized visual only: never blocks rounds or modifies collisions.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local Assets = {}
local ID = 123049626693705
local NAME = "ApprovedClassicBroadcastFinTemplates"
local BOUNDS = Vector3.new(5.46,15.92,1.76)
local started = false

local function genuine(model)
    local pieces = 0
    for _,item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return false end
            pieces += 1
        elseif item:IsA("LuaSourceContainer") then
            return false
        end
    end
    if pieces ~= 7 then return false end
    local _,bounds=model:GetBoundingBox()
    local horizontal={bounds.X,bounds.Z}
    table.sort(horizontal)
    return math.abs(bounds.Y-BOUNDS.Y) <= .32
        and math.abs(horizontal[1]-BOUNDS.Z) <= .32
        and math.abs(horizontal[2]-BOUNDS.X) <= .32
end

function Assets.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild(NAME)
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name=NAME
        holder.Parent=ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- One owner Model serves all four fin locations. Avoid loading
        -- at character spawn alongside essential route/AI geometry.
        task.wait(105)
        if holder:FindFirstChild("BroadcastFin") then return end
        for attempt=1,3 do
            local ok,raw=pcall(AssetService.LoadAssetAsync,AssetService,ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not genuine(clean) then
                    if clean then clean:Destroy() end
                    warn("Classic broadcast fin source rejected by geometry gate")
                    return
                end
                clean.Name="BroadcastFin"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalClassicBroadcastFin3D",true)
                clean:SetAttribute("Original3DAssetId",ID)
                clean.Parent=holder
                holder:SetAttribute("BroadcastFinReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Classic original broadcast fin source unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
