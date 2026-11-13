-- Two new creator-owned, moderated Approved original platform perimeter
-- rim Models. Cosmetic imported MeshParts only: gameplay floors, native
-- WedgePart fallback, collapses and route cues remain server-owned.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local ImportGate = require("./PremiumApprovedAssetImportGate")

local Kit = {}
local APPROVED = {
    Rect = 131482590870627,
    Long = 127617571835277,
}
local started = false

function Kit.approvedId(name)
    return APPROVED[name]
end

local function exactSource(model, name)
    if not model or not model:IsA("Model") then return false end
    local count = 0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart")
                or part.CanCollide or part.CanTouch or part.CanQuery then
                return false
            end
            count += 1
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if count ~= 7 then return false end
    local _,size = model:GetBoundingBox()
    local long,short=math.max(size.X,size.Z),math.min(size.X,size.Z)
    if size.Y < 1.80 or size.Y > 2.70 then return false end
    if name == "Rect" then
        return long >= 15.9 and long <= 17.4
            and short >= 9.0 and short <= 10.5
    end
    return long >= 25.0 and long <= 26.4
        and short >= 7.0 and short <= 8.6
end

function Kit.start()
    if started then return end
    started = true
    local templates = ReplicatedStorage:FindFirstChild(
        "ApprovedPlatformRimTemplates")
    if templates and not templates:IsA("Folder") then return end
    if not templates then
        templates = Instance.new("Folder")
        templates.Name = "ApprovedPlatformRimTemplates"
        templates.Parent = ReplicatedStorage
    end
    templates:SetAttribute("OwnerVerified", true)

    task.spawn(function()
        -- Cosmetic imports begin after essential world setup. The shared
        -- ImportGate serializes Roblox AssetService usage for every kit.
        task.wait(65)
        local order = {"Rect","Long"}
        local generated = workspace:FindFirstChild("GeneratedMap")
        local arena = generated and generated:FindFirstChild("Arena")
        if arena and arena:GetAttribute("VariantId") == "Harbor" then
            order = {"Long","Rect"}
        end
        for _,kind in ipairs(order) do
            if not templates:FindFirstChild(kind) then
                for attempt=1,3 do
                    local ok,raw=pcall(ImportGate.load,
                        AssetService, APPROVED[kind])
                    if ok and raw and raw:IsA("Model") then
                        local clean=OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not clean or not exactSource(clean,kind) then
                            if clean then clean:Destroy() end
                            warn("Approved platform perimeter rim rejected",
                                kind)
                            break
                        end
                        clean.Name=kind
                        clean:SetAttribute("Original3DAssetId",APPROVED[kind])
                        clean:SetAttribute("OriginalPlatformRim3D",true)
                        clean:SetAttribute("CosmeticOnly",true)
                        clean:SetAttribute("OwnerVerified",true)
                        clean.Parent=templates
                        templates:SetAttribute(kind.."Ready",true)
                        break
                    end
                    if ok and typeof(raw)=="Instance" then raw:Destroy() end
                    if attempt==3 then
                        warn("Approved platform rim unavailable, preserving "
                            .."native WedgeParts",kind,tostring(raw))
                    else
                        task.wait(attempt*3)
                    end
                end
            end
        end
    end)
end

return Kit
