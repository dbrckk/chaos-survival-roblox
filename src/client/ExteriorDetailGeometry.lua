local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:FindFirstChild("Shared")
local horizonGeometryModule = shared and shared:FindFirstChild("HorizonMonumentGeometry")
local HorizonMonumentGeometry = if horizonGeometryModule then require(horizonGeometryModule)
    else require("../shared/HorizonMonumentGeometry")

local ExteriorDetailGeometry = {}

-- The complete LOD models use the authored poses, even when an imported
-- fallback region is a quarter-turn away from that reference frame.
function ExteriorDetailGeometry.footprint(part, owner, assetId, fallbackClass, fallbackShape)
    if not part or not part:IsA("BasePart") or part.Parent ~= owner
        or not part.Anchored or part.CanCollide or part.CanTouch or part.CanQuery then
        return nil
    end
    if part:IsA("MeshPart") then
        if not assetId or part.MeshId == "" or part:GetAttribute("OriginalExteriorDetail3D") ~= true
            or part:GetAttribute("Original3DAssetId") ~= assetId then
            return nil
        end
        if part:GetAttribute("ExteriorDetailAxisSwap") == true then
            local size = part.Size
            return Vector3.new(size.Z, size.Y, size.X),
                part.CFrame * CFrame.Angles(0, -math.pi * .5, 0)
        end
    elseif not part:IsA(fallbackClass)
        or (fallbackClass == "Part" and part.Shape ~= (fallbackShape or Enum.PartType.Block)) then
        return nil
    end
    return part.Size, part.CFrame
end

function ExteriorDetailGeometry.monumentFootprint(part, owner, fallbackClass, fallbackShape)
    if not part then return nil end
    local profile = HorizonMonumentGeometry.profile(owner.Name, part.Name)
    local variant = owner:GetAttribute("SignatureVariant")
    local assetId = HorizonMonumentGeometry.assetId(profile, variant)
    if variant == "Harbor" and fallbackClass == "Part" and not fallbackShape then
        local nativeId = part:GetAttribute("Original3DAssetId")
        if HorizonMonumentGeometry.matchesHarborStructuralFallback(nativeId, profile) then
            assetId = nativeId
        end
    end
    return ExteriorDetailGeometry.footprint(part, owner, assetId, fallbackClass, fallbackShape)
end

return ExteriorDetailGeometry
