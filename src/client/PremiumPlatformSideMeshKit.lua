-- Creator-owned, moderated-Approved original structural 3D near actual
-- jump decks. Six asset IDs matched to #41798024000. No new collider,
-- hazard layer, movable platform or frame-update owner.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local IDS = {
    Classic = 92590025262416,
    Towers = 85204303404953,
    Crossroads = 116452624086023,
    Orbital = 118444100674717,
    Harbor = 124136394128432,
    Bridge = 122766792774607,
}

local function verified(name)
    local folder = ReplicatedStorage:FindFirstChild("ApprovedPlatformSideTemplates")
    if not folder or not folder:IsA("Folder")
        or folder:GetAttribute("OwnerVerified") ~= true then return nil end
    local model = folder:FindFirstChild(name)
    if not model or not model:IsA("Model") or model.Parent ~= folder
        or model:GetAttribute("Original3DAssetId") ~= IDS[name]
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("OriginalStructuralSide3D") ~= true then return nil end
    local pieces = 0
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not obj:IsA("MeshPart") then return nil end
            pieces += 1
        elseif obj:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if pieces < 1 or pieces > 12 then return nil end
    local _, size = model:GetBoundingBox()
    local long, short = math.max(size.X, size.Z), math.min(size.X, size.Z)
    if name == "Bridge" then
        if long < 9 or long > 11.2 or short < .4 or short > 1.5
            or size.Y < 1.25 or size.Y > 2.65 then return nil end
    elseif long < 10.6 or long > 12.3
        or short < 7.8 or short > 9.6
        or size.Y < 2.0 or size.Y > 4.1 then return nil end
    return model, size
end

local function preparedParts(copy, sourceFrame, target, platform, name)
    local list = {}
    local adjustable = platform:GetAttribute("ChaosSkybridge") == true
        or tonumber(platform:GetAttribute("RouteTier")) ~= nil
    for _, obj in ipairs(copy:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not obj:IsA("MeshPart") then return nil end
            obj.CFrame = target * sourceFrame:ToObjectSpace(obj.CFrame)
            obj.Anchored = false
            obj.Massless = true
            obj.CanCollide = false
            obj.CanTouch = false
            obj.CanQuery = false
            obj.CastShadow = false
            obj:SetAttribute("ChaosBaseTransparency", obj.Transparency)
            obj:SetAttribute("ChaosPlatformTrim", true)
            obj:SetAttribute("Original3DStructuralSide", true)
            obj:SetAttribute("Original3DAssetId", IDS[name])
            local joint = Instance.new(adjustable and "Weld" or "WeldConstraint")
            joint.Name = "ChaosPlatformTrimWeld"
            joint.Part0 = obj
            joint.Part1 = platform
            if adjustable then
                joint.C0 = CFrame.identity
                joint.C1 = platform.CFrame:ToObjectSpace(obj.CFrame)
            end
            joint.Parent = obj
            list[#list + 1] = obj
        end
    end
    if #list < 1 or #list > 12 then return nil end
    return list
end

local function publishParts(parent, copy, pieces, label)
    for i, piece in ipairs(pieces) do
        piece.Name = "ApprovedOriginal3D_" .. label .. "_" .. tostring(i)
        piece.Parent = parent
    end
    copy:Destroy()
    return pieces
end

local function stage(parent, platform, source, name, scale, target)
    local copy = source:Clone()
    if not pcall(function() copy:ScaleTo(scale) end) then
        copy:Destroy()
        return nil
    end
    local sourceFrame, dimensions = copy:GetBoundingBox()
    local safe, frame = pcall(target, dimensions)
    if not safe or typeof(frame) ~= "CFrame" then
        copy:Destroy()
        return nil
    end
    local pieces = preparedParts(copy, sourceFrame, frame, platform, name)
    if not pieces then
        copy:Destroy()
        return nil
    end
    return publishParts(parent, copy, pieces, name)
end

-- The previous fixed "every sixth/every twelfth" sample could leave ALL
-- jump decks nearest the player with native WedgePart skirts. At a map/
-- quality rebuild, reserve the SAME bounded source-backed owner for REAL
-- safe platforms closest to the play area, not arbitrary index parity.
-- This is a snapshot (not live camera tracking); PremiumRouteMeshKit already
-- owns continuous camera-LOD for upper deck paint and bridge covers.
-- The server keeps all colliders, collapse cues and source fallbacks.
function Kit.selectCarapaceDecks(platforms, variant, tier, base, cameraPoint)
    local chosen = {}
    local limit = tier == "High" and 16 or (tier == "Medium" and 8 or 0)
    if limit == 0 or type(platforms) ~= "table"
        or not base or not base:IsA("BasePart") then
        return chosen
    end
    -- Do not reserve slots until the actual seven-material model has
    -- replicated and passed the same OwnerVerified/provenance/size gate
    -- that the mount itself requires.
    local approved, bounds = verified(variant)
    if not approved then return chosen end
    local sourceLong = math.max(bounds.X,bounds.Z)
    local sourceShort = math.min(bounds.X,bounds.Z)
    local focus = base.Position
    if typeof(cameraPoint) == "Vector3" then
        local localCamera = base.CFrame:PointToObjectSpace(cameraPoint)
        if math.abs(localCamera.X) <= base.Size.X*.5 + 16
            and math.abs(localCamera.Z) <= base.Size.Z*.5 + 16
            and math.abs(localCamera.Y) <= 130 then
            focus = cameraPoint
        end
    end
    local candidates = {}
    for _, platform in ipairs(platforms) do
        if platform:IsA("BasePart") and platform.Parent
            and platform.Name:match("^Platform%d+$")
            and platform.Anchored and platform.CanCollide
            and platform.Transparency < .75
            and platform:GetAttribute("ChaosSkybridge") ~= true then
            local phase = platform:GetAttribute("CollapsePhase")
            local x,z = platform.Size.X,platform.Size.Z
            local long,short = math.max(x,z),math.min(x,z)
            local scale = math.min(1.1,
                long*.92/sourceLong,short*.91/sourceShort)
            -- The approved 11-stud compact shell must cover the REAL
            -- native deck footprint before its full-width underframe may
            -- be hidden. Long 26-stud promenades require the different
            -- certified 22-stud LongCradle, not half a carapace.
            if (phase == nil or phase == "Normal" or phase == "Safe")
                and short >= 7.1 and long <= 36
                and long / short <= 2.6 and scale >= .62
                and sourceLong*scale >= long*.78
                and sourceShort*scale >= short*.72 then
                local delta=platform.Position-focus
                -- Upper decks remain attractive but distant unused edge
                -- platforms must not consume the scarce true-mesh budget.
                local score=Vector3.new(delta.X,delta.Y*.60,delta.Z).Magnitude
                if platform:GetAttribute("ChaosPermanentRoute") == true then
                    score-=6
                end
                candidates[#candidates+1]={part=platform,score=score}
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.score ~= b.score then return a.score < b.score end
        return a.part.Name < b.part.Name
    end)
    for i=1,math.min(#candidates,limit) do
        chosen[candidates[i].part]=true
    end
    return chosen
end

-- Genuine whole-underside skins replace native wedges,
-- bars and fake keel blocks on a selected subset of existing platforms.
-- High 1/6, Medium 1/12, Low 0. Original assets replace native
-- wedge/rail/brace clusters instead of simply stacking extra primitives.
-- Candidate only: real Android GPU and silhouette QA still required.
function Kit.carapace(parent, platform, variant, tier, index, selected)
    if tier == "Low" or platform:GetAttribute("ChaosSkybridge") == true then
        return nil
    end
    local id = tonumber(index)
    if not id or id < 1 then return nil end
    -- Explicit TRUE only for one of the 16/8 nearest genuine safe decks.
    -- FALSE never mounts an extra model; nil preserves the old 1/6/1/12
    -- legacy API for independent consumers / test harnesses.
    if selected == false then return nil end
    local step = tier == "High" and 6 or 12
    if selected ~= true and id % step ~= 1 then return nil end
    local source, original = verified(variant)
    if not source or not parent or not platform or not platform:IsA("BasePart")
        or not platform.Parent or not platform.CanCollide
        or platform.Transparency >= .75 then return nil end
    local sx, sy, sz = platform.Size.X, platform.Size.Y, platform.Size.Z
    local long = math.max(sx, sz)
    local short = math.min(sx, sz)
    if short < 7.1 or long > 36 then return nil end
    local sourceLong = math.max(original.X, original.Z)
    local sourceShort = math.min(original.X, original.Z)
    local scale = math.min(1.1, long*.92/sourceLong, short*.91/sourceShort)
    -- Prevent a 12-stud real imported shell from hiding the entire 26-
    -- stud native underside. Small square jump decks are eligible;
    -- long promenade/interchange underframes need true LongCradle art.
    if scale < .62 or sourceLong*scale < long*.78
        or sourceShort*scale < short*.72 then return nil end
    local yaw = (sz > sx) ~= (original.Z > original.X)
        and math.pi * .5 or 0
    local parts = stage(parent, platform, source, variant, scale,
        function(size)
            if size.Y <= 0 or size.Y > 4.55
                or math.max(size.X,size.Z) > long*.96
                or math.min(size.X,size.Z) > short*.95 then
                error("invalid imported carapace fit")
            end
            -- Top of sloped armor is below collidable platform surface
            -- by 0.16 studs. Underside can protrude ONLY downwards.
            return platform.CFrame
                * CFrame.new(0, sy*.5 - .16 - size.Y*.5, 0)
                * CFrame.Angles(0, yaw, 0)
        end)
    if parts and selected == true then
        -- Diagnostic of ACTUAL mounted approved sources, not merely
        -- selected candidates, rendered pixels or a performance result.
        for _, part in ipairs(parts) do
            part:SetAttribute("NearCameraCarapace3D", true)
        end
    end
    return parts
end

-- Authored side-only bridge truss hardware replaces selected native
-- rectangular local side rails; server glow/danger rails remain untouched.
-- Two pieces (Medium) or four pieces (High), on two real bridge flanks.
-- Route shrink adjusts individual MeshPart Weld.C1/Size in existing owner.
function Kit.bridgeGirders(parent, platform, tier, index)
    if tier == "Low" or platform:GetAttribute("ChaosSkybridge") ~= true then
        return nil
    end
    local id = tonumber(index)
    if not id or id < 1 or id % (tier == "High" and 3 or 6) ~= 0 then
        return nil
    end
    local source, original = verified("Bridge")
    if not source or not parent or not platform or not platform:IsA("BasePart")
        or not platform.Parent or not platform.CanCollide
        or platform.Transparency >= .75 then return nil end

    local sx, sy, sz = platform.Size.X, platform.Size.Y, platform.Size.Z
    local length = math.max(sx, sz)
    local width = math.min(sx, sz)
    if length < 14 or length > 125 or width < 4.0 then return nil end
    local sourceLength = math.max(original.X, original.Z)
    local scale = math.min(1.1, width*.24, length*.32/sourceLength)
    if scale < .75 then return nil end

    -- Roblox may import a long-X glTF as a long-Z Model. All bridge
    -- placements must follow the *imported source long axis*, not assume
    -- it is always X; otherwise truss modules can appear across the
    -- walkway or past its physical ends on some uploaded orientations.
    local sourceLongZ = original.Z > original.X
    local along = platform.CFrame * CFrame.Angles(
        0, (sz > sx) ~= sourceLongZ and math.pi*.5 or 0, 0)
    local perSide = tier == "High" and 2 or 1
    local all = {}
    -- All clones are staged before any original local rails are removed.
    -- Any failure rolls back every new piece, retaining native fallback.
    for side = -1, 1, 2 do
        for k = 1, perSide do
            local fraction = perSide == 1 and 0
                or (k == 1 and -.27 or .27)
            local copy = source:Clone()
            if not pcall(function() copy:ScaleTo(scale) end) then
                copy:Destroy()
                for _, p in ipairs(all) do p:Destroy() end
                return nil
            end
            local frame, bounds = copy:GetBoundingBox()
            if bounds.Y > 3.1 or math.max(bounds.X,bounds.Z) > length*.40
                or math.min(bounds.X,bounds.Z) > width*.35 then
                copy:Destroy()
                for _, p in ipairs(all) do p:Destroy() end
                return nil
            end
            local edgeOffset = side * (
                width*.5 - math.min(.20,math.min(bounds.X,bounds.Z)*.25))
            local longOffset = length * fraction
            local target = along * CFrame.new(
                sourceLongZ and edgeOffset or longOffset,
                sy*.5 - .20 - bounds.Y*.5,
                sourceLongZ and longOffset or edgeOffset)
            local parts = preparedParts(copy, frame, target, platform, "Bridge")
            if parts then
                -- Imported glTF long axis can be X or Z. The existing
                -- platform shrink follower needs the MESH-LOCAL long
                -- axis to resize actual 3D girders with the real span,
                -- even when their world orientation was yaw-rotated.
                for _, part in ipairs(parts) do
                    part:SetAttribute("OriginalBridgeLongAxis",
                        sourceLongZ and "Z" or "X")
                end
            end
            if not parts then
                copy:Destroy()
                for _, p in ipairs(all) do p:Destroy() end
                return nil
            end
            for _, part in ipairs(parts) do
                part.Name = "ApprovedOriginal3D_Bridge_"
                    .. tostring(side) .. "_" .. tostring(k)
                    .. "_" .. tostring(#all+1)
                part.Parent = parent
                all[#all + 1] = part
            end
            copy:Destroy()
        end
    end
    return #all > 0 and all or nil
end

return Kit
