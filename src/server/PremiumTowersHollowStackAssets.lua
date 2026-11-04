-- Distinct original 3D hollow cooling unit for Tower Run.
-- Roblox owner Model #97498534364335 Approved in GitHub Actions #41904135484.
-- Actual source has 9,980 triangles, 330 authored groups, 7 UV/tangent
-- material MeshParts, and a real open chimney wall + service gantry.
-- Complements (does not replace) the taller original turbine spire
-- #95543769387033. Neither source creates collisions or a new game path.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local Kit={}
local ID=97498534364335
local started=false

local function isAuthentic(model)
    local pieces=0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then
                return false
            end
            pieces+=1
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if pieces~=7 then return false end
    local _,b=model:GetBoundingBox()
    -- Exact verified source 6.256 x 21.1646 x 5.52. Roblox glTF may
    -- swap source X/Z, never allow unrelated Marketplace sculptures.
    local broad,thin=math.max(b.X,b.Z),math.min(b.X,b.Z)
    return broad>=6.00 and broad<=6.48
        and thin>=5.30 and thin<=5.76
        and b.Y>=20.95 and b.Y<=21.40
end

function Kit.approvedId()
    return ID
end

function Kit.start()
    if started then return end
    started=true
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedTowersHollowStackTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name="ApprovedTowersHollowStackTemplates"
        holder.Parent=ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    holder:SetAttribute("Original3DAssetId",ID)
    if holder:FindFirstChild("HollowCoolingStack") then return end
    task.spawn(function()
        -- All playable geometry, first-round assets, original cooling
        -- megaspire and original Harbor scenery load before this
        -- second optional 3D skyline material model.
        task.wait(125)
        for attempt=1,3 do
            local ok,raw=pcall(AssetService.LoadAssetAsync,
                AssetService,ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not isAuthentic(clean) then
                    if clean then clean:Destroy() end
                    warn("Original Towers hollow stack rejected by strict 3D geometry guard")
                    return
                end
                clean.Name="HollowCoolingStack"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalTowersHollowStack3D",true)
                clean:SetAttribute("Original3DAssetId",ID)
                clean:SetAttribute("Original3DTriangleCount",9980)
                clean:SetAttribute("ReferenceNativeStackHeight",44)
                clean.Parent=holder
                holder:SetAttribute("HollowStackReady",true)
                return
            end
            if ok and typeof(raw)=="Instance" then raw:Destroy() end
            if attempt>=3 then
                warn("Approved Towers hollow stack unavailable, native cooling skyline retained")
            else
                task.wait(3*attempt)
            end
        end
    end)
end

return Kit
