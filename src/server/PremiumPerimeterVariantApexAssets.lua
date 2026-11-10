-- Four distinct creator-owned, seven-material, 3D perimeter apex Models.
-- IDs and Roblox "Approved" receipts: workflow #42699542702.
-- Optional delayed art load; NEVER use arbitrary IDs, gameplay colliders,
-- remote scripts, sounds or unvalidated client-selected models.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Assets = {}
local APPROVED = {
    Towers = {id = 131413152501235, size = Vector3.new(2.14, 8.043, 1.72)},
    Orbital = {id = 131188899020391, size = Vector3.new(3.356, 3.92, 3.356)},
    Crossroads = {id = 134533469777794, size = Vector3.new(2.41, 3.11, 8.36)},
    Relay = {id = 110237986522853, size = Vector3.new(2.26, 6.0595, 1.89)},
}
local ORDER = {"Towers", "Orbital", "Crossroads", "Relay"}
local started = false

local function geometryOK(model, spec)
    local count = 0
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            if not child:IsA("MeshPart") or child.CanCollide
                or child.CanTouch or child.CanQuery then return false end
            count += 1
        elseif child:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count ~= 7 then return false end
    local _, size = model:GetBoundingBox()
    if math.abs(size.Y - spec.size.Y) > .30 then return false end
    -- On some Roblox glTF import paths horizontal X/Z are exchanged.
    -- No geometry stretching or arbitrary large model is accepted.
    local x,z = math.min(size.X,size.Z), math.max(size.X,size.Z)
    local expectedX,expectedZ = math.min(spec.size.X,spec.size.Z),
        math.max(spec.size.X,spec.size.Z)
    return math.abs(x-expectedX) <= .28
        and math.abs(z-expectedZ) <= .30
end

function Assets.start()
    if started then return end
    started = true
    local folder = ReplicatedStorage:FindFirstChild(
        "ApprovedPerimeterVariantApexTemplates")
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ApprovedPerimeterVariantApexTemplates"
        folder.Parent = ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        -- Queue late, AFTER first playable round and primary hero sources.
        -- This optional loader may not block real players or disaster logic.
        task.wait(132)
        for _, kind in ipairs(ORDER) do
            local spec = APPROVED[kind]
            if not folder:FindFirstChild(kind) then
                for attempt = 1, 3 do
                    local ok, raw = pcall(GlobalApprovedImportGate.load,
                        AssetService, spec.id)
                    if ok and raw and raw:IsA("Model") then
                        local clean = OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not clean or not geometryOK(clean,spec) then
                            if clean then clean:Destroy() end
                            warn("Approved original apex rejected on geometry",
                                kind)
                            break
                        end
                        clean.Name = kind
                        clean:SetAttribute("OwnerVerified",true)
                        clean:SetAttribute("CosmeticOnly",true)
                        clean:SetAttribute("OriginalPerimeterVariantApex3D",true)
                        clean:SetAttribute("Original3DAssetId",spec.id)
                        clean.Parent = folder
                        folder:SetAttribute(kind.."Ready",true)
                        break
                    end
                    if typeof(raw)=="Instance" then raw:Destroy() end
                    if attempt==3 then
                        warn("Original 3D station apex unavailable",kind,
                            tostring(raw))
                    else
                        task.wait(attempt*5)
                    end
                end
            end
            task.wait(5)
        end
    end)
end

return Assets
