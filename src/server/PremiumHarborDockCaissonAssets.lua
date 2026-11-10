-- Original approved UV/tangent Harbor cargo dock 3D; built from source,
-- moderated Approved in GitHub Actions #41844409855. Cosmetic only.
-- Existing collidable Harbor jump platforms ALWAYS remain fully present.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Kit = {}
local ID = 101457508594609
local started = false

function Kit.approvedId()
    return ID
end

local function geometryOK(model)
    local pieces = 0
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if not descendant:IsA("MeshPart") then return false end
            pieces += 1
        elseif descendant:IsA("LuaSourceContainer") then
            return false
        end
    end
    if pieces < 1 or pieces > 12 then return false end
    local _, bounds = model:GetBoundingBox()
    -- The authored caisson is approximately 14x3.3x14, not an arbitrary
    -- marketplace asset. X and Z can swap during glTF import.
    return bounds.X >= 13.0 and bounds.X <= 14.4
        and bounds.Z >= 13.0 and bounds.Z <= 14.4
        and bounds.Y >= 2.9 and bounds.Y <= 3.55
end

function Kit.start()
    if started then return end
    started = true
    local folder = ReplicatedStorage:FindFirstChild("ApprovedHarborDockCaissonTemplates")
    if folder and not folder:IsA("Folder") then return end
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ApprovedHarborDockCaissonTemplates"
        folder.Parent = ReplicatedStorage
    end
    folder:SetAttribute("OwnerVerified", true)
    if folder:FindFirstChild("DockCaisson") then return end

    -- More important route and lobby assets already get the first import
    -- slots. This cosmetic source does not block playing or building a map.
    task.spawn(function()
        task.wait(88)
        for attempt = 1, 3 do
            local ok, raw = pcall(GlobalApprovedImportGate.load,
                AssetService, ID)
            if ok and raw and raw:IsA("Model") then
                local clean = OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not clean or not geometryOK(clean) then
                    if clean then clean:Destroy() end
                    warn("Approved Harbor dock caisson rejected by source geometry")
                    return
                end
                clean.Name = "DockCaisson"
                clean:SetAttribute("OwnerVerified", true)
                clean:SetAttribute("CosmeticOnly", true)
                clean:SetAttribute("OriginalHarborDockCaisson3D", true)
                clean:SetAttribute("Original3DAssetId", ID)
                clean.Parent = folder
                folder:SetAttribute("DockCaissonReady", true)
                return
            end
            if ok and typeof(raw) == "Instance" then raw:Destroy() end
            if attempt == 3 then
                warn("Approved Harbor dock model unavailable; all native platforms retained",
                    tostring(raw))
            else
                task.wait(attempt * 3)
            end
        end
    end)
end

return Kit
