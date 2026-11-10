-- Four original, owner-approved exterior ridge profiles (NW/NE/SW/SE).
-- Workflow 42854203855: authentic Roblox Models, Moderation Approved.
-- Decorative only; these imported MeshParts never change terrain or physics.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Assets={}
local PROFILES={
    {name="NW",id=123836720232695,bounds=Vector3.new(37.45768,15.9,33.90254)},
    {name="NE",id=83853948389204,bounds=Vector3.new(37.90254,17.78,33.45768)},
    {name="SW",id=108491064314671,bounds=Vector3.new(37.90254,17.78,33.45768)},
    {name="SE",id=83023096720529,bounds=Vector3.new(37.45768,16.84,33.90254)},
}
local started=false

local function valid(model,spec)
    local n=0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return false end
            n+=1
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if n~=7 then return false end
    local _,size=model:GetBoundingBox()
    return (size-spec.bounds).Magnitude<=.62
end

function Assets.start()
    if started then return end
    started=true
    local folder=ReplicatedStorage:FindFirstChild("ApprovedExteriorRidgeTemplates")
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="ApprovedExteriorRidgeTemplates"
        folder.Parent=ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        task.wait(80)
        for _,spec in ipairs(PROFILES) do
            local name="Ridges"..spec.name
            if not folder:FindFirstChild(name) then
                for attempt=1,3 do
                    local ok,raw=pcall(GlobalApprovedImportGate.load,
                        AssetService,spec.id)
                    if ok and raw and raw:IsA("Model") then
                        local clean=OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not clean or not valid(clean,spec) then
                            if clean then clean:Destroy() end
                            warn("Approved exterior ridge profile rejected",
                                spec.name)
                            break
                        end
                        clean.Name=name
                        clean:SetAttribute("OwnerVerified",true)
                        clean:SetAttribute("CosmeticOnly",true)
                        clean:SetAttribute("OriginalExteriorRidges3D",true)
                        clean:SetAttribute("Original3DAssetId",spec.id)
                        clean:SetAttribute("ExteriorCornerId",spec.name)
                        clean.Parent=folder
                        folder:SetAttribute(name.."Ready",true)
                        break
                    end
                    if typeof(raw)=="Instance" then raw:Destroy() end
                    if attempt==3 then
                        warn("Approved exterior ridge source unavailable",
                            spec.name,tostring(raw))
                    else
                        task.wait(attempt*5)
                    end
                end
            end
            task.wait(4)
        end
    end)
end

return Assets
