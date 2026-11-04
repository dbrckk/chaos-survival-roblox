-- REAL original source-authored Tower Run cooling-spire 3D model.
-- Approved Roblox Model #95543769387033 (6,380 triangles, 148 groups,
-- seven independent UV/tangent MeshParts); import receipt #41904066937.
-- Five pre-existing TowerCoolingMass native skyline sculptures remain
-- nonphysical and available as a client-only LOD/streaming fallback.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local Kit = {}
local ID = 95543769387033
local started = false

function Kit.approvedId()
    return ID
end

local function isAuthored(model)
    local count=0
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            if not p:IsA("MeshPart") or p.CanCollide or p.CanTouch
                or p.CanQuery then return false end
            count+=1
        elseif p:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count~=7 then return false end
    local _,dimensions=model:GetBoundingBox()
    -- Source bounds 6.6444 x 29.11975 x 4.956 studs; X/Z may be
    -- swapped by Roblox glTF import. Never accept another catalog item.
    local long=math.max(dimensions.X,dimensions.Z)
    local short=math.min(dimensions.X,dimensions.Z)
    return long>=6.35 and long<=6.98
        and short>=4.70 and short<=5.20
        and dimensions.Y>=28.8 and dimensions.Y<=29.5
end

function Kit.start()
    if started then return end
    started=true
    local folder=ReplicatedStorage:FindFirstChild(
        "ApprovedTowerCoolingSpireTemplates")
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="ApprovedTowerCoolingSpireTemplates"
        folder.Parent=ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified",true)
    folder:SetAttribute("Original3DAssetId",ID)
    if folder:FindFirstChild("RealCoolingSpire") then return end
    task.spawn(function()
        -- A secondary non-playable skyline. All routes, primary industrial
        -- columns and the Harbor sea have loaded before this optional art.
        task.wait(104)
        for attempt=1,3 do
            local ok,raw=pcall(AssetService.LoadAssetAsync,
                AssetService,ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not isAuthored(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved Tower Run cooling megaspire source guard failed")
                    return
                end
                clean.Name="RealCoolingSpire"
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("OriginalTowerCoolingSpire3D",true)
                clean:SetAttribute("Original3DAssetId",ID)
                clean:SetAttribute("Original3DTriangleCount",6380)
                clean:SetAttribute("SourceArchitecturalBodyHeight",40)
                clean.Parent=folder
                folder:SetAttribute("RealCoolingSpireReady",true)
                return
            end
            if ok and typeof(raw)=="Instance" then raw:Destroy() end
            if attempt<3 then
                task.wait(attempt*3)
            else
                warn("Approved Tower Run cooling spire unavailable, native skyline retained")
            end
        end
    end)
end

return Kit
