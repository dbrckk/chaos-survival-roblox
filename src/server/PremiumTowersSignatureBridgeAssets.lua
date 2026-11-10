-- Original creator-owned sculpted Towers signature bridge, asset
-- 126298311664881. Workflow 42777274284 confirms Roblox Approved.
-- Optional late cosmetic loader, NEVER gameplay or Skyrail collider code.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")
local ActiveSignatureSchedule=require("./PremiumActiveVariantImportSchedule")

local Assets={}
local ID=126298311664881
local started=false

local function valid(source)
    local count=0
    for _,part in ipairs(source:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return false end
            count+=1
        elseif part:IsA("LuaSourceContainer") then return false end
    end
    if count~=7 then return false end
    local _,b=source:GetBoundingBox()
    -- OBJ source auth: 40.64 x 4.87784 x 6.77. The importer may
    -- swap X/Z, but must preserve its physical Y-oriented bridge slab.
    local x,z=math.min(b.X,b.Z),math.max(b.X,b.Z)
    return math.abs(b.Y-4.87784)<.30
        and math.abs(x-6.77)<.35
        and math.abs(z-40.64)<.50
end

function Assets.start()
    if started then return end
    started=true
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedTowersSignatureBridgeTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name="ApprovedTowersSignatureBridgeTemplates"
        holder.Parent=ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- Art lane: allow first round, player spawn and existing sources
        -- to initialize. Model absence never delays a disaster.
        ActiveSignatureSchedule.waitFor("Towers",47,62)
        if holder:FindFirstChild("ForgedBridge") then return end
        for attempt=1,3 do
            local ok,raw=pcall(GlobalApprovedImportGate.load,
                AssetService,ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not valid(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved Towers signature bridge geometry rejected")
                    return
                end
                clean.Name="ForgedBridge"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalTowersSignatureBridge3D",true)
                clean:SetAttribute("Original3DAssetId",ID)
                clean.Parent=holder
                holder:SetAttribute("ForgedBridgeReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Approved original Towers bridge unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
