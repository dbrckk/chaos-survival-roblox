-- Four nonphysical authentic Storm Harbor nearshore 3D barges.
-- Source-created 3,718 triangles, 126 sculpted groups, seven PBR-ready
-- UV/tangent meshes. Creator-owned Roblox Model #132891280963772,
-- moderated Approved in GitHub Actions #41862430789.
-- Original 28x3.5x13.2 native Part hulls + all native detail remain present
-- as client-visible fallback. No gameplay, collision or server geometry.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Kit={}
local ID=132891280963772
local started=false

function Kit.approvedId()
    return ID
end

local function authenticShape(model)
    local n=0
    for _,item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return false end
            if item.CanCollide or item.CanTouch or item.CanQuery then
                return false
            end
            n+=1
        elseif item:IsA("LuaSourceContainer") then
            return false
        end
    end
    if n~=7 then return false end
    local _,size=model:GetBoundingBox()
    -- Exact verified source 28.35 x 11.18 x 13.30. Roblox glTF can
    -- swap the authored long/short horizontal axes; no other silhouette
    -- or Marketplace free model can be mounted by this kit.
    local long=math.max(size.X,size.Z)
    local short=math.min(size.X,size.Z)
    return long>=28.05 and long<=28.65
        and short>=13.0 and short<=13.65
        and size.Y>=10.93 and size.Y<=11.45
end

function Kit.start()
    if started then return end
    started=true
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedHarborBargeTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name="ApprovedHarborBargeTemplates"
        holder.Parent=ReplicatedStorage
    end
    if holder:FindFirstChild("CoastalFreightBarge") then return end
    holder:SetAttribute("OwnerVerified",true)
    -- Only the server can establish this source/ID provenance, and
    -- clients must compare the same immutable ID to the Model.
    holder:SetAttribute("Original3DAssetId",ID)
    task.spawn(function()
        -- First-screen interaction, playable routes, major cargo vessel,
        -- four large cranes and hero radar station retain their priority.
        task.wait(108)
        for attempt=1,3 do
            local ok,raw=pcall(
                GlobalApprovedImportGate.load,AssetService,ID)
            if ok and raw and raw:IsA("Model") then
                local safe=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not safe or not authenticShape(safe) then
                    if safe then safe:Destroy() end
                    warn("Approved Harbor barge rejected by strict source geometry")
                    return
                end
                safe.Name="CoastalFreightBarge"
                safe:SetAttribute("OwnerVerified",true)
                safe:SetAttribute("CosmeticOnly",true)
                safe:SetAttribute("OriginalHarborBarge3D",true)
                safe:SetAttribute("Original3DAssetId",ID)
                safe:SetAttribute("Original3DTriangleCount",3718)
                safe.Parent=holder
                holder:SetAttribute("CoastalFreightBargeReady",true)
                return
            end
            if ok and typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Approved Harbor 3D barge unavailable, native barges retained")
            else
                task.wait(attempt*3)
            end
        end
    end)
end

return Kit
