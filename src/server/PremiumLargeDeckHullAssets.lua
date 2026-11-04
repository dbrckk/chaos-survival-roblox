-- Roblox-moderated original 18-stud structural hull, source gate #41809088464.
-- Optional high/medium client art only: the server never adds gameplay parts.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")

local Kit = {}
local APPROVED_HULL = 125929150866282
local started = false

function Kit.approvedId()
    return APPROVED_HULL
end

function Kit.start()
    if started then return end
    started = true
    local templates = ReplicatedStorage:FindFirstChild("ApprovedLargeDeckHullTemplates")
    if templates and not templates:IsA("Folder") then return end
    if not templates then
        templates = Instance.new("Folder")
        templates.Name = "ApprovedLargeDeckHullTemplates"
        templates.Parent = ReplicatedStorage
    end
    templates:SetAttribute("OwnerVerified", true)
    task.spawn(function()
        -- Optional hero-deck art is serialized behind existing gameplay,
        -- ambient, relief and column lanes. No client load requests.
        task.wait(98)
        for attempt = 1, 3 do
            local ok, raw = pcall(
                AssetService.LoadAssetAsync, AssetService, APPROVED_HULL)
            if ok and raw and raw:IsA("Model") then
                local safe = OriginalMeshScenery.sanitize(raw)
                raw:Destroy()
                if not safe then
                    warn("Original large deck hull rejected by sanitizer")
                    return
                end
                local meshes = 0
                for _, part in ipairs(safe:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if not part:IsA("MeshPart") then
                            safe:Destroy()
                            warn("Original large deck hull contains native geometry")
                            return
                        end
                        meshes += 1
                    elseif part:IsA("LuaSourceContainer") then
                        safe:Destroy()
                        return
                    end
                end
                local _, box = safe:GetBoundingBox()
                if meshes < 1 or meshes > 12
                    or box.X < 16.5 or box.X > 18.4
                    or box.Z < 16.5 or box.Z > 18.4
                    or box.Y < 2.3 or box.Y > 4.2 then
                    safe:Destroy()
                    warn("Original large deck hull geometry provenance mismatch")
                    return
                end
                safe.Name = "LargeDeckHull"
                safe:SetAttribute("Original3DAssetId", APPROVED_HULL)
                safe:SetAttribute("OwnerVerified", true)
                safe:SetAttribute("CosmeticOnly", true)
                safe:SetAttribute("OriginalLargeDeckHull3D", true)
                safe.Parent = templates
                templates:SetAttribute("LargeDeckHullReady", true)
                return
            end
            if ok and typeof(raw) == "Instance" then raw:Destroy() end
            if attempt == 3 then
                warn("Original large deck hull unavailable, keeping native art",
                    tostring(raw))
            else
                task.wait(3 * attempt)
            end
        end
    end)
end

return Kit
