-- Creator-owned, Open Cloud Approved original Orbital reactor Models:
-- Node 104654294187035 and Strut 138666009076890, workflow 42869295978.
-- Only optional sanitized seven-MeshPart cosmetic art; never blocks rounds.
local AssetService=game:GetService("AssetService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local OriginalMeshScenery=require("./OriginalMeshScenery")

local Assets={}
local MODELS={
    {name="Node",id=104654294187035,dims=Vector3.new(4.36,4.36,4.36)},
    {name="Strut",id=138666009076890,dims=Vector3.new(8.46,1.24,1.10)},
}
local started=false

local function authentic(model,entry)
    local count=0
    for _,piece in ipairs(model:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") or piece.CanCollide
                or piece.CanTouch or piece.CanQuery then return false end
            count+=1
        elseif piece:IsA("LuaSourceContainer") then return false end
    end
    if count~=7 then return false end
    local _,bounds=model:GetBoundingBox()
    if entry.name=="Node" then
        return (bounds-entry.dims).Magnitude<=.62
    end
    local major=math.max(bounds.X,bounds.Z)
    local minor=math.min(bounds.X,bounds.Z)
    return math.abs(major-entry.dims.X)<=.38
        and math.abs(bounds.Y-entry.dims.Y)<=.35
        and math.abs(minor-entry.dims.Z)<=.35
end

function Assets.start()
    if started then return end
    started=true
    local holder=ReplicatedStorage:FindFirstChild("ApprovedOrbitalReactorLandmarkTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder=Instance.new("Folder")
        holder.Name="ApprovedOrbitalReactorLandmarkTemplates"
        holder.Parent=ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- One server-side lane: the two art Models load sequentially,
        -- not in parallel with each other or on every connected client.
        task.wait(112)
        for _,entry in ipairs(MODELS) do
            if not holder:FindFirstChild(entry.name) then
                for attempt=1,3 do
                    local ok,raw=pcall(AssetService.LoadAssetAsync,
                        AssetService,entry.id)
                    if ok and raw and raw:IsA("Model") then
                        local safe=OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not safe or not authentic(safe,entry) then
                            if safe then safe:Destroy() end
                            warn("Orbital original reactor art rejected",
                                entry.name)
                            break
                        end
                        safe.Name=entry.name
                        safe:SetAttribute("OwnerVerified",true)
                        safe:SetAttribute("CosmeticOnly",true)
                        safe:SetAttribute("OriginalOrbitalReactorLandmark3D",true)
                        safe:SetAttribute("Original3DAssetId",entry.id)
                        safe.Parent=holder
                        holder:SetAttribute(entry.name.."Ready",true)
                        break
                    end
                    if typeof(raw)=="Instance" then raw:Destroy() end
                    if attempt==3 then
                        warn("Original Orbital reactor art unavailable",
                            entry.name,tostring(raw))
                    else
                        task.wait(attempt*5)
                    end
                end
            end
            task.wait(8)
        end
    end)
end

return Assets
