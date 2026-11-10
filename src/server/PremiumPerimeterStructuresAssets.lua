-- Approved original seven-material open steel girder and generator guard.
-- Genuine Model ID + Moderation Approved confirmed by run #42696898936.
-- Never publish imported scripts, constraints or gameplay colliders.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Assets={}
local SPECS={
    {name="Brace",id=108452611210970,
        bounds=Vector3.new(8.94,.5675,1.12)},
    {name="Shield",id=113687802206554,
        bounds=Vector3.new(3.93,.5405,1.3)},
}
local started=false

local function valid(model,spec)
    local parts=0
    for _,child in ipairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            if not child:IsA("MeshPart") or child.CanCollide
                or child.CanTouch or child.CanQuery then return false end
            parts+=1
        elseif child:IsA("LuaSourceContainer") then return false end
    end
    if parts~=7 then return false end
    local _,actual=model:GetBoundingBox()
    local got={actual.X,actual.Y,actual.Z}
    local required={spec.bounds.X,spec.bounds.Y,spec.bounds.Z}
    table.sort(got)
    table.sort(required)
    return math.abs(got[1]-required[1])<.18
        and math.abs(got[2]-required[2])<.25
        and math.abs(got[3]-required[3])<.30
end

function Assets.start()
    if started then return end
    started=true
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedPerimeterStructuresTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name="ApprovedPerimeterStructuresTemplates"
        holder.Parent=ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    -- Late optional art lane; player spawn and first danger phase go first.
    task.spawn(function()
        task.wait(112)
        for _,spec in ipairs(SPECS) do
            if not holder:FindFirstChild(spec.name) then
                for attempt=1,3 do
                    local ok,raw=pcall(GlobalApprovedImportGate.load,
                        AssetService,spec.id)
                    if ok and raw and raw:IsA("Model") then
                        local clean=OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not clean or not valid(clean,spec) then
                            if clean then clean:Destroy() end
                            warn("Approved original station structure rejected",
                                spec.name)
                            break
                        end
                        clean.Name=spec.name
                        clean:SetAttribute("OwnerVerified",true)
                        clean:SetAttribute("CosmeticOnly",true)
                        clean:SetAttribute("OriginalPerimeterStructure3D",true)
                        clean:SetAttribute("Original3DAssetId",spec.id)
                        clean.Parent=holder
                        holder:SetAttribute(spec.name.."Ready",true)
                        break
                    end
                    if typeof(raw)=="Instance" then raw:Destroy() end
                    if attempt==3 then
                        warn("Original station structure unavailable",
                            spec.name,tostring(raw))
                    else
                        task.wait(attempt*4)
                    end
                end
            end
            task.wait(5)
        end
    end)
end

return Assets
