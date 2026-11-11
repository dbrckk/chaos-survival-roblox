-- Original creator-owned complementary Classic observatory support sculpture.
-- Five nonphysical native support/panel Parts can be replaced by genuine
-- seven-material 3D source Model: ID 91717127334369, Roblox Approved
-- in GitHub Actions 42809450851. Never load untrusted code or physics.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")
local ActiveSignatureSchedule = require("./PremiumActiveVariantImportSchedule")

local Assets={}
local MODEL_ID=91717127334369
local started=false

local function verified(model)
    local count=0
    for _,obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not obj:IsA("MeshPart") or obj.CanCollide
                or obj.CanTouch or obj.CanQuery then return false end
            count+=1
        elseif obj:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count~=7 then return false end
    -- Authored source envelope: 13.47557 × 19.26613 × 2.47275.
    -- The Roblox importer can interchange X/Z (Y remains vertical).
    local _,b=model:GetBoundingBox()
    local a,z=math.min(b.X,b.Z),math.max(b.X,b.Z)
    return math.abs(b.Y-19.26613)<.42
        and math.abs(a-2.47275)<.27
        and math.abs(z-13.47557)<.46
end

function Assets.start()
    if started then return end
    started=true
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedClassicForgedSupportTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name="ApprovedClassicForgedSupportTemplates"
        holder.Parent=ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- The original twin-dish source keeps its earlier slot. Only
        -- real active Classic gets this complementary forged sculpture
        -- at 56s; all other worlds retain the old 119s fallback.
        -- Imports stay optional behind the global two-slot FIFO.
        ActiveSignatureSchedule.waitFor("Classic",56,119)
        if holder:FindFirstChild("ForgedSupports") then return end
        for attempt=1,3 do
            local ok,raw=pcall(GlobalApprovedImportGate.load,
                AssetService,MODEL_ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not verified(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved Classic support sculpture geometry rejected")
                    return
                end
                clean.Name="ForgedSupports"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalClassicForgedSupports3D",true)
                clean:SetAttribute("Original3DAssetId",MODEL_ID)
                clean.Parent=holder
                holder:SetAttribute("ForgedSupportsReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Original Classic support sculpture unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
