-- Authenticated south Towers torus, owner Model ID 114886409893890.
-- Source gate and Roblox Moderation: Approved run 42835512896.
-- Cosmetic only, does not replace the northern reactor ring.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")

local Assets={}
local APPROVED_ID=114886409893890
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
    return dims[1]>=2.65 and dims[1]<=3.20
        and dims[2]>=17.40 and dims[2]<=18.10
        and dims[3]>=19.50 and dims[3]<=20.75
end

function Assets.start()
    if started then return end
    started=true
    local folder=ReplicatedStorage:FindFirstChild(
        "ApprovedSouthTowersLiftTwinsTemplates")
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="ApprovedSouthTowersLiftTwinsTemplates"
        folder.Parent=ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        task.wait(49)
        if folder:FindFirstChild("ForgedLiftTwins") then return end
        for attempt=1,3 do
            local ok,raw=pcall(AssetService.LoadAssetAsync,
                AssetService,APPROVED_ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not valid(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved south Towers forged lift twins geometry rejected")
                    return
                end
                clean.Name="ForgedLiftTwins"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalSouthTowersForgedLiftTwins3D",true)
                clean:SetAttribute("Original3DAssetId",APPROVED_ID)
                clean.Parent=folder
                folder:SetAttribute("ForgedLiftTwinsReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Approved south Towers forged lift twins unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
