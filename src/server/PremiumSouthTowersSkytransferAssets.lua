-- Authenticated south Towers torus, owner Model ID 120959181274080.
-- Source gate and Roblox Moderation: Approved run 42833322096.
-- Cosmetic only, does not replace the northern reactor ring.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local ActiveSignatureSchedule=require("./PremiumActiveVariantImportSchedule")

local Assets={}
local APPROVED_ID=120959181274080
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
    return dims[1]>=2.75 and dims[1]<=3.20
        and dims[2]>=4.20 and dims[2]<=4.70
        and dims[3]>=19.35 and dims[3]<=20.05
end

function Assets.start()
    if started then return end
    started=true
    local folder=ReplicatedStorage:FindFirstChild(
        "ApprovedSouthTowersSkytransferTemplates")
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="ApprovedSouthTowersSkytransferTemplates"
        folder.Parent=ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- Eight South Monument imports previously competed at t=49s.
        -- Prioritize the current map only; stagger inactive art.
        ActiveSignatureSchedule.waitFor("Towers",75,171)
        if folder:FindFirstChild("ForgedSkytransfer") then return end
        for attempt=1,3 do
            local ok,raw=pcall(AssetService.LoadAssetAsync,
                AssetService,APPROVED_ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not valid(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved south Towers forged skytransfer geometry rejected")
                    return
                end
                clean.Name="ForgedSkytransfer"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalSouthTowersForgedSkytransfer3D",true)
                clean:SetAttribute("Original3DAssetId",APPROVED_ID)
                clean.Parent=folder
                folder:SetAttribute("ForgedSkytransferReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Approved south Towers forged skytransfer unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
