-- Original approved Harbor South drydock (14 nonphysical native candidates).
-- Creator Model 125428569657840; Moderation Approved, run 42847077638.
-- Seven sanitized MeshParts, no gameplay or northern Harbor change.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local ActiveSignatureSchedule=require("./PremiumActiveVariantImportSchedule")

local Assets={}
local APPROVED_ID=125428569657840
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
    return dims[1]>=4.40 and dims[1]<=4.90
        and dims[2]>=16.30 and dims[2]<=16.85
        and dims[3]>=18.00 and dims[3]<=18.75
end

function Assets.start()
    if started then return end
    started=true
    local folder=ReplicatedStorage:FindFirstChild(
        "ApprovedSouthHarborDrydockTemplates")
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="ApprovedSouthHarborDrydockTemplates"
        folder.Parent=ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- Eight South Monument imports previously competed at t=49s.
        -- Prioritize the current map only; stagger inactive art.
        ActiveSignatureSchedule.waitFor("Harbor",59,129)
        if folder:FindFirstChild("SculptedDrydock") then return end
        for attempt=1,3 do
            local ok,raw=pcall(AssetService.LoadAssetAsync,
                AssetService,APPROVED_ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not valid(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved south Harbor forged exchange geometry rejected")
                    return
                end
                clean.Name="SculptedDrydock"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalSouthHarborSculptedDrydock3D",true)
                clean:SetAttribute("Original3DAssetId",APPROVED_ID)
                clean.Parent=folder
                folder:SetAttribute("SculptedDrydockReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Approved south Harbor forged exchange unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
