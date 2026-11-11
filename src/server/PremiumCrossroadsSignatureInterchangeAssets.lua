-- Creator-approved original Crossroads two-level forged interchange.
-- Model 96622579843060, Moderation Approved in run 42778699782.
-- Optional late artwork only. Never alters playable switchyards or bots.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")
local ActiveSignatureSchedule=require("./PremiumActiveVariantImportSchedule")

local Assets={}
local MODEL_ID=96622579843060
local started=false

local function sourceIsAuthentic(model)
    local count=0
    for _,item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return false end
            count+=1
        elseif item:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count~=7 then return false end
    local _,box=model:GetBoundingBox()
    local smaller,larger=math.min(box.X,box.Z),math.max(box.X,box.Z)
    -- Genuine glTF source bounds 47.68 × 11.73404 × 6.76. Roblox can
    -- swap horizontal X/Z, but stretching any dimension is forbidden.
    return math.abs(box.Y-11.73404)<.45
        and math.abs(smaller-6.76)<.36
        and math.abs(larger-47.68)<.52
end

function Assets.start()
    if started then return end
    started=true
    local folder=ReplicatedStorage:FindFirstChild(
        "ApprovedCrossroadsSignatureInterchangeTemplates")
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="ApprovedCrossroadsSignatureInterchangeTemplates"
        folder.Parent=ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- Nonblocking: initial round, bots and core gameplay run first.
        ActiveSignatureSchedule.waitFor("Crossroads",19,77)
        if folder:FindFirstChild("ForgedInterchange") then return end
        for attempt=1,3 do
            local ok,raw=pcall(GlobalApprovedImportGate.load,
                AssetService,MODEL_ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not sourceIsAuthentic(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved Crossroads interchange rejected by source geometry")
                    return
                end
                clean.Name="ForgedInterchange"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalCrossroadsSignatureInterchange3D",true)
                clean:SetAttribute("Original3DAssetId",MODEL_ID)
                clean.Parent=folder
                folder:SetAttribute("ForgedInterchangeReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Original Crossroads interchange unavailable",tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
