-- Approved original South Crossroads complete 13-part freight interchange.
-- Creator-owned Roblox Model 77870668100712; Moderation Approved, run 42842143479.
-- Sanitized nonphysical only; no gameplay or northern signature replacement.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")

local Assets={}
local APPROVED_ID=77870668100712
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
    return dims[1]>=4.35 and dims[1]<=4.85
        and dims[2]>=16.70 and dims[2]<=17.55
        and dims[3]>=17.95 and dims[3]<=18.65
end

function Assets.start()
    if started then return end
    started=true
    local folder=ReplicatedStorage:FindFirstChild(
        "ApprovedSouthCrossroadsExchangeTemplates")
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="ApprovedSouthCrossroadsExchangeTemplates"
        folder.Parent=ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        task.wait(49)
        if folder:FindFirstChild("ForgedExchange") then return end
        for attempt=1,3 do
            local ok,raw=pcall(AssetService.LoadAssetAsync,
                AssetService,APPROVED_ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not valid(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved south Crossroads forged exchange geometry rejected")
                    return
                end
                clean.Name="ForgedExchange"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalSouthCrossroadsForgedExchange3D",true)
                clean:SetAttribute("Original3DAssetId",APPROVED_ID)
                clean.Parent=folder
                folder:SetAttribute("ForgedExchangeReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Approved south Crossroads forged exchange unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
