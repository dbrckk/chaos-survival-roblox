-- Original identity mast sculptures from owner-verified Open Cloud import:
-- Classic grid 105555650820011 / Towers spine 86423178125318.
-- Both Roblox Model assets Moderation Approved (workflow 42874906992).
-- Seven genuine MeshParts per model. Server-only, optional and cosmetic.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")

local Assets={}
local SOURCES={
    {name="Classic",id=105555650820011,
        dims=Vector3.new(2.16,11.92,2.16)},
    {name="Towers",id=86423178125318,
        dims=Vector3.new(2.52,19.97562,2.52)},
}
local FOLDER="ApprovedVariantIdentitySpineTemplates"
local started=false

local function authentic(model,spec)
    local count=0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return false end
            count+=1
        elseif part:IsA("LuaSourceContainer") then return false end
    end
    if count~=7 then return false end
    local _,bounds=model:GetBoundingBox()
    return math.abs(bounds.X-spec.dims.X)<=.34
        and math.abs(bounds.Y-spec.dims.Y)<=.34
        and math.abs(bounds.Z-spec.dims.Z)<=.34
end

function Assets.start()
    if started then return end
    started=true
    local folder=ReplicatedStorage:FindFirstChild(FOLDER)
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder=Instance.new("Folder")
        folder.Name=FOLDER
        folder.Parent=ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- 2 serial owner imports; no parallel client calls and no
        -- waiting on these sources before the round can start.
        task.wait(97)
        for _,spec in ipairs(SOURCES) do
            if not folder:FindFirstChild(spec.name) then
                for attempt=1,3 do
                    local ok,raw=pcall(AssetService.LoadAssetAsync,
                        AssetService,spec.id)
                    if ok and raw and raw:IsA("Model") then
                        local clean=OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not clean or not authentic(clean,spec) then
                            if clean then clean:Destroy() end
                            warn("Original identity sculpture geometry rejected",
                                spec.name)
                            break
                        end
                        clean.Name=spec.name
                        clean:SetAttribute("OwnerVerified",true)
                        clean:SetAttribute("CosmeticOnly",true)
                        clean:SetAttribute("OriginalVariantIdentitySpine3D",true)
                        clean:SetAttribute("Original3DAssetId",spec.id)
                        clean.Parent=folder
                        folder:SetAttribute(spec.name.."Ready",true)
                        break
                    end
                    if typeof(raw)=="Instance" then raw:Destroy() end
                    if attempt==3 then
                        warn("Original identity sculpture source unavailable",
                            spec.name,tostring(raw))
                    else
                        task.wait(attempt*5)
                    end
                end
            end
            task.wait(13)
        end
    end)
end

return Assets
