-- Original approved Classic South observatory (14 nonphysical native candidates).
-- Creator Model 105516749001927; Moderation Approved, run 42849092927.
-- Seven sanitized MeshParts, no gameplay or northern Classic change.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local ActiveSignatureSchedule=require("./PremiumActiveVariantImportSchedule")
local SouthImportGate=require("./PremiumSouthApprovedImportGate")

local Assets={}
local APPROVED_ID=105516749001927
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
    return dims[1]>=4.95 and dims[1]<=5.45
        and dims[2]>=16.45 and dims[2]<=17.05
        and dims[3]>=18.30 and dims[3]<=18.85
end

function Assets.start()
    if started then return end
    started=true
    local folder=ReplicatedStorage:FindFirstChild(
        "ApprovedSouthClassicObservatoryTemplates")
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="ApprovedSouthClassicObservatoryTemplates"
        folder.Parent=ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- Eight South Monument imports previously competed at t=49s.
        -- Prioritize the current map only; stagger inactive art.
        ActiveSignatureSchedule.waitFor("Classic",59,101)
        if folder:FindFirstChild("SculptedObservatory") then return end
        for attempt=1,3 do
            local ok,raw=pcall(SouthImportGate.load,
                AssetService,APPROVED_ID)
            if ok and raw and raw:IsA("Model") then
                local clean=OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not valid(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved south Classic forged exchange geometry rejected")
                    return
                end
                clean.Name="SculptedObservatory"
                clean:SetAttribute("OwnerVerified",true)
                clean:SetAttribute("CosmeticOnly",true)
                clean:SetAttribute("OriginalSouthClassicSculptedObservatory3D",true)
                clean:SetAttribute("Original3DAssetId",APPROVED_ID)
                clean.Parent=folder
                folder:SetAttribute("SculptedObservatoryReady",true)
                return
            end
            if typeof(raw)=="Instance" then raw:Destroy() end
            if attempt==3 then
                warn("Approved south Classic forged exchange unavailable",
                    tostring(raw))
            else
                task.wait(attempt*5)
            end
        end
    end)
end

return Assets
