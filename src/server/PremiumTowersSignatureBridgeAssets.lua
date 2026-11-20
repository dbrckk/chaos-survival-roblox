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

local function markBridgeRegions(model)
    -- ARMOR is the swept beam; CERAMIC contains the two continuous
    -- outboard stripes and the shaped anchor tabs at their ends.
    local crossbeam, edgeBand
    for _, piece in ipairs(model:GetChildren()) do
        if not piece:IsA("MeshPart") or not piece.Archivable or piece.MeshId=="" then continue end
        local size=piece.Size
        local length,width=math.max(size.X,size.Z),math.min(size.X,size.Z)
        if math.abs(length-40.64)<.30 and math.abs(width-5.96)<.20
            and math.abs(size.Y-3.1108)<.18 then
            if crossbeam then return end
            crossbeam=piece
        elseif math.abs(length-39.38)<.25 and math.abs(width-5.43)<.16
            and math.abs(size.Y-.1625)<.055 then
            if edgeBand then return end
            edgeBand=piece
        end
    end
    if crossbeam then crossbeam.Name="SweptCrossbeam" end
    if edgeBand then edgeBand.Name="SculptedEdgeBand" end
end

function Assets.approvedSource()
    local holder = ReplicatedStorage:FindFirstChild("ApprovedTowersSignatureBridgeTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local model = holder:FindFirstChild("ForgedBridge")
    if not model or not model:IsA("Model")
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("OriginalTowersSignatureBridge3D") ~= true
        or model:GetAttribute("Original3DAssetId") ~= ID then return nil end
    return model
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
        ActiveSignatureSchedule.waitFor("Towers",21,62)
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
                markBridgeRegions(clean)
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
