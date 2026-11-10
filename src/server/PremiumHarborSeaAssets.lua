-- Genuine triangulated Storm Harbor coastal sea, not a massive
-- false Roblox Part floor and not Terrain Water that changes physics.
-- Owner-uploaded Approved Model #111296950975600, 6152 original triangles,
-- 132 sculpted source groups into 7 distinct UV/tangent PBR materials.
-- Authoritative 320x320 survival floor, hazards and fall detection untouched.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Kit={}
local ID=111296950975600
local started=false

local function validGeometry(model)
    local n=0
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            if not p:IsA("MeshPart") or p.CanCollide or p.CanTouch
                or p.CanQuery then return false end
            n+=1
        elseif p:IsA("LuaSourceContainer") then
            return false
        end
    end
    if n~=7 then return false end
    local _,b=model:GetBoundingBox()
    -- Original source is 48.0 x 0.07043 x 48.0.
    -- Seven huge authored real MeshParts span a square marine annulus,
    -- scaled 20x clientside; Roblox may swap source X/Z axes.
    return b.X>=47.5 and b.X<=48.5
        and b.Z>=47.5 and b.Z<=48.5
        and b.Y>=.03 and b.Y<=.35
end

function Kit.start()
    if started then return end
    started=true
    local holder=ReplicatedStorage:FindFirstChild("ApprovedHarborSeaTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name="ApprovedHarborSeaTemplates"
        holder.Parent=ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    holder:SetAttribute("Original3DAssetId",ID)
    if holder:FindFirstChild("SculptedSea") then return end
    task.spawn(function()
        -- A dominant first-screen art feature. Load AFTER the playable
        -- arena/lobby but BEFORE very distant optional cargo silhouettes.
        task.wait(18)
        for attempt=1,3 do
            local ok,raw=pcall(
                GlobalApprovedImportGate.load,AssetService,ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not validGeometry(clean) then
                    if clean then clean:Destroy() end
                    warn("Creator-approved Harbor ocean rejected: geometry mismatch")
                    return
                end
                clean.Name="SculptedSea"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("OriginalHarborSea3D",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("Original3DAssetId",ID)
                clean:SetAttribute("Original3DTriangleCount",6152)
                clean:SetAttribute("SourceDryInnerHalfWidth",164.8)
                clean.Parent=holder
                holder:SetAttribute("SeaReady",true)
                return
            end
            if ok and typeof(raw)=="Instance" then raw:Destroy() end
            if attempt<3 then
                task.wait(attempt*3)
            else
                warn("Storm Harbor sculpted ocean unavailable; unchanged native environment retained")
            end
        end
    end)
end

return Kit
