-- Original true toroidal orbital megareactor Model. GitHub source/Roblox
-- Approved workflow 42711150534; owner asset ID 125070862497818.
-- Optional, source-verified and collisionless. No Place publication here.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")
local ActiveSignatureSchedule=require("./PremiumActiveVariantImportSchedule")

local Assets={}
local APPROVED_ID=125070862497818
local started=false

local function valid(model)
    local count=0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return false end
            count+=1
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count~=7 then return false end
    local _,s=model:GetBoundingBox()
    local dims={s.X,s.Y,s.Z}
    table.sort(dims)
    return dims[1]>=1.05 and dims[1]<=1.60
        and dims[2]>=16.45 and dims[2]<=17.50
        and dims[3]>=16.45 and dims[3]<=17.50
end

function Assets.start()
    if started then return end
    started=true
    local folder=ReplicatedStorage:FindFirstChild(
        "ApprovedOrbitalSignatureRingTemplates")
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="ApprovedOrbitalSignatureRingTemplates"
        folder.Parent=ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        ActiveSignatureSchedule.waitFor("Orbital",22,42)
        if folder:FindFirstChild("ReactorRing") then return end
        for attempt=1,3 do
            local ok,raw=pcall(GlobalApprovedImportGate.load,
                AssetService,APPROVED_ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not valid(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved Orbital signature torus geometry rejected")
                    return
                end
                clean.Name="ReactorRing"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalOrbitalSignatureTorus3D",true)
                clean:SetAttribute("Original3DAssetId",APPROVED_ID)
                clean.Parent=folder
                folder:SetAttribute("ReactorRingReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Approved Orbital signature torus unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
