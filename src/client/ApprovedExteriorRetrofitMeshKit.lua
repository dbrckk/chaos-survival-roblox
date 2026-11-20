-- A forged tower sheath takes over the generated exterior retrofit.
-- The independently animated landmarks and their signals still own their art.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SceneryLodRules = if script then require(ReplicatedStorage.Shared.SceneryLodRules)
    else require("../shared/SceneryLodRules")

local shared = ReplicatedStorage:FindFirstChild("Shared")
local horizonModule = shared and shared:FindFirstChild("HorizonMonumentGeometry")
local HorizonMonumentGeometry = if horizonModule then require(horizonModule)
    else require("../shared/HorizonMonumentGeometry")

local Kit = {}
local TOWER = {folder="ApprovedExteriorTowerTemplates",name="Tower21",
    id=137744886537150,tag="OriginalExteriorTower3D",size=Vector3.new(11.84,22.2,9.84)}
local GANTRY = {folder="ApprovedCrossroadsGantryTemplates",name="Gantry",
    id=90844491148907,tag="OriginalCrossroadsGantry3D",size=Vector3.new(27.92,3.6,2.74)}
local CAPS = {Low=1,Medium=2,High=4}
local TOUCH_CAPS = {Low=1,Medium=1,High=2}
local RANGE = {Low=146,Medium=238,High=335}
local ACTIVE_RANGE = 14

local PARTS = {
    {"OuterFrontArmor","Part",5,11.8,.68,"bevel"},
    {"RearMaintenanceShell","Part",4.6,10.8,.78,"bevel"},
    {"RecessedEquipmentBox","Part",2.3,5.2,.43,"bevel"},
    {"FacetedSideWing-1","WedgePart",1.6,10.8,3.1,"cast"},
    {"FacetedSideWing1","WedgePart",1.6,10.8,3.1,"cast"},
    {"DiagonalExteriorStiffener-1","Part",.46,.46,math.sqrt(148.01),"beam"},
    {"DiagonalExteriorStiffener1","Part",.46,.46,math.sqrt(148.01),"beam"},
    {"CrownButtress-1","Part",.95,2.2,3.8,"bevel"},
    {"CrownButtress1","Part",.95,2.2,3.8,"bevel"},
    {"UpperStructuralCollar","Part",6.8,.72,5.4,"bevel"},
    {"CantileverPlatformUnderside","WedgePart",5.9,.55,7.5,"cast"},
    {"WeatherGuardTop","Part",4.8,.70,4.6,"bevel"},
    {"BeaconTensionMast","Part",.5,4.8,.5,"shaft"},
}
local OUTER = {
    {"LongSpanUpperStructuralFlange","Part",29.6,.62,.90,"beam"},
    {"LongSpanLowerStructuralFlange","Part",29.6,.48,.64,"beam"},
    {"LongSpanDiagonalReinforcement-1","WedgePart",2.4,2.6,.74,"cast"},
    {"LongSpanDiagonalReinforcement1","WedgePart",2.4,2.6,.74,"cast"},
}
local VARIANTS = {Classic=true,Towers=true,Crossroads=true,Orbital=true,Harbor=true}
local root = Instance.new("Folder")
root.Name = "ApprovedExteriorRetrofitsLocal"
root:SetAttribute("CosmeticOnly",true)
root.Parent = workspace

local activeArena
local mounted = {}

local function release(owner)
    local entry = mounted[owner]
    if not entry then return end
    mounted[owner] = nil
    for _,link in ipairs(entry.links) do link:Disconnect() end
    for native,alpha in pairs(entry.originals) do
        if native.Transparency == 1 then native.Transparency = alpha end
    end
    entry.model:Destroy()
end

local function clear()
    local owners = {}
    for owner in pairs(mounted) do owners[#owners+1] = owner end
    for _,owner in ipairs(owners) do release(owner) end
end

local function trusted(model,holder,spec)
    return holder and holder:IsA("Folder") and holder.Parent == ReplicatedStorage
        and holder.Name == spec.folder and holder:GetAttribute("OwnerVerified") == true
        and model and model:IsA("Model") and model.Parent == holder
        and model.Name == spec.name and model:GetAttribute("OwnerVerified") == true
        and model:GetAttribute("CosmeticOnly") == true and model:GetAttribute(spec.tag) == true
        and model:GetAttribute("Original3DAssetId") == spec.id
end

local function sortedSize(size)
    return Vector3.new(math.max(size.X,size.Z),size.Y,math.min(size.X,size.Z))
end

local function approved(spec)
    local holder = ReplicatedStorage:FindFirstChild(spec.folder)
    local model = holder and holder:FindFirstChild(spec.name)
    if not trusted(model,holder,spec) then return nil end
    local pieces = model:GetChildren()
    if #pieces ~= 7 then return nil end
    for _,piece in ipairs(pieces) do
        if not piece:IsA("MeshPart") or not piece.Anchored or piece.CanCollide
            or piece.CanTouch or piece.CanQuery or piece.Transparency >= 1 then return nil end
        for _,extra in ipairs(piece:GetDescendants()) do
            if not extra:IsA("SurfaceAppearance") and not extra:IsA("Decal")
                and not extra:IsA("Texture") then return nil end
        end
    end
    local frame,size = model:GetBoundingBox()
    if (sortedSize(size)-spec.size).Magnitude > .55 then return nil end
    local yaw = size.Z > size.X and -math.pi*.5 or 0
    if spec == TOWER then
        for _,piece in ipairs(pieces) do
            if piece.Size.Y < .16 then
                local center = frame:PointToObjectSpace(piece.Position)
                local depth = size.Z > size.X and center.X or center.Z
                if math.abs(depth) > math.min(size.X,size.Z)*.30 then
                    if depth > 0 then yaw += math.pi end
                    break
                end
            end
        end
    end
    return {model=model,holder=holder,spec=spec,frame=frame,size=size,yaw=yaw,pieces=pieces}
end

local function around(arena)
    local generated = workspace:FindFirstChild("GeneratedMap")
    if not arena or not arena:IsA("Folder") or arena.Name ~= "Arena" or not generated
        or generated.Parent ~= workspace or arena.Parent ~= generated then return nil end
    local variant = arena:GetAttribute("VariantId")
    if not VARIANTS[variant] then return nil end
    local base = arena:FindFirstChild("Base")
    local decor = arena:FindFirstChild("Decor")
    local fleet = decor and decor:FindFirstChild("OriginalExteriorRetrofits")
    if not base or not base:IsA("Part") or not base.Anchored or not base.CanCollide
        or not fleet or not fleet:IsA("Folder") then return nil end
    local x,z = base:GetAttribute("OriginalSizeX"),base:GetAttribute("OriginalSizeZ")
    if type(x) ~= "number" or type(z) ~= "number" or x < 318 or z < 318
        or base.Size.X > x+.2 or base.Size.Z > z+.2 then return nil end
    return base,fleet,variant,x,z
end

local function anchor(base,variant,index,halfX,halfZ)
    local offset
    if variant == "Classic" then
        offset = ({
            Vector3.new(-halfX-5,8,-18),Vector3.new(halfX+5,8,18),
            Vector3.new(-18,8,halfZ+5),Vector3.new(18,8,-halfZ-5)})[index]
    elseif variant == "Towers" then
        offset = Vector3.new((index%2 == 1 and -1 or 1)*(halfX+6),12,
            (index <= 2 and -1 or 1)*(halfZ+6))
    elseif variant == "Crossroads" then
        offset = ({Vector3.new(0,8,-halfZ-4),Vector3.new(0,8,halfZ+4),
            Vector3.new(-halfX-4,8,0),Vector3.new(halfX+4,8,0)})[index]
    elseif variant == "Orbital" then
        local angle = (index-1)*math.pi*.5
        offset = Vector3.new(math.cos(angle)*(math.max(halfX,halfZ)+7),12,
            math.sin(angle)*(math.max(halfX,halfZ)+7))
    else
        offset = ({Vector3.new(halfX+13,10,-36),Vector3.new(-halfX-13,10,36),
            Vector3.new(36,10,halfZ+13),Vector3.new(-36,10,-halfZ-13)})[index]
        offset = base.CFrame:VectorToWorldSpace(offset)
    end
    local p = base.Position+offset
    return CFrame.lookAt(p,Vector3.new(base.Position.X,p.Y,base.Position.Z))
end

local function nativeParts(owner,fleet,variant,index,origin)
    if not owner or not owner:IsA("Model") or owner.Parent ~= fleet
        or owner.Name ~= variant.."Retrofit"..index
        or owner:GetAttribute("OriginalExteriorRetrofit") ~= true
        or owner:GetAttribute("SourceIsOriginal") ~= true
        or owner:GetAttribute("CosmeticOnly") ~= true
        or owner:GetAttribute("RetrofitIndex") ~= index
        or owner:GetAttribute("SignatureVariant") ~= variant then return nil end
    local baked = owner:GetAttribute("RetrofitOrigin")
    if typeof(baked) ~= "CFrame" or (baked.Position-origin.Position).Magnitude > .12
        or baked.LookVector:Dot(origin.LookVector) < .999 then return nil end
    local parts = {}
    local function collect(specs,span)
        for _,row in ipairs(specs) do
            local part = owner:FindFirstChild(row[1])
            local x,y,z = row[3],row[4],row[5]
            if span and index > 2 then x,z = z,x end
            if not part or not part:IsA("BasePart") or not part.Anchored
                or part.CanCollide or part.CanTouch or part.CanQuery
                or (part.Position-origin.Position).Magnitude > (span and 11 or 13.4)
                or (part.Transparency ~= 1 and math.abs(part.Transparency-.045) > .025)
                or part:GetAttribute("SceneryLodHidden") == true
                or part.LocalTransparencyModifier >= .95 then return false end
            local size = part.Size
            if part:IsA("MeshPart") then
                local assetId = HorizonMonumentGeometry.assetId(row[6], variant)
                if not assetId or part.MeshId == "" or part:GetAttribute("Original3DAssetId") ~= assetId then
                    return false
                end
                -- Cast and forged sources can use either horizontal import axis.
                size = Vector3.new(math.max(size.X, size.Z), size.Y, math.min(size.X, size.Z))
                x, z = math.max(x, z), math.min(x, z)
            elseif not part:IsA(row[2]) then
                return false
            end
            if (size - Vector3.new(x, y, z)).Magnitude > .11 then return false end
            parts[#parts+1] = part
        end
        return true
    end
    if #owner:GetChildren() ~= (variant == "Crossroads" and 17 or 13)
        or not collect(PARTS,false) or (variant == "Crossroads" and not collect(OUTER,true)) then
        return nil
    end
    return parts
end

local function axisScale(axis,scale)
    if math.abs(axis.X) > .9999 then return scale.X end
    if math.abs(axis.Y) > .9999 then return scale.Y end
    if math.abs(axis.Z) > .9999 then return scale.Z end
    return nil
end

local function addSculpture(parent,asset,frame,envelope,color)
    local target = frame*CFrame.Angles(0,asset.yaw,0)
    if asset.size.Z > asset.size.X then
        envelope = Vector3.new(envelope.Z,envelope.Y,envelope.X)
    end
    local scale = envelope/asset.size
    for _,mesh in ipairs(asset.pieces) do
        local relative = asset.frame:ToObjectSpace(mesh.CFrame)
        local x,y,z = axisScale(relative.RightVector,scale),axisScale(relative.UpVector,scale),
            axisScale(relative.LookVector,scale)
        if not x or not y or not z then return false end
        local copy = mesh:Clone()
        if not copy then return false end
        copy.Size *= Vector3.new(x,y,z)
        copy.CFrame = target*CFrame.new(relative.Position*scale)*relative.Rotation
        copy.Massless = true
        copy.CastShadow = false
        copy.LocalTransparencyModifier = 0
        copy.Color = copy.Color:Lerp(color,.28)
        copy:SetAttribute("Original3DAssetId",asset.spec.id)
        copy.Parent = parent
    end
    return true
end

local function mount(item,tower,gantry)
    local clone = Instance.new("Model")
    clone.Name = "Sculpted"..item.owner.Name
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",TOWER.id)
    local origin = item.origin
    local color = item.parts[1].Color
    -- Match the sheath's original vertical envelope and keep its face
    -- on the inward side. The underlying active landmark is independent.
    -- Crossroads uses a shorter central column under its horizontal truss.
    local midpoint = gantry and 1.08 or 3.35
    local height = gantry and 14.1 or 18.5
    if not addSculpture(clone,tower,origin*CFrame.new(0,midpoint,0),
        Vector3.new(7.17,height,6.14),color) then clone:Destroy();return end
    if gantry then
        local span = CFrame.new(origin.Position+origin.LookVector*0.55+Vector3.new(0,-.18,0))
            *CFrame.Angles(0,item.index > 2 and math.pi*.5 or 0,0)
        if not addSculpture(clone,gantry,span,Vector3.new(29.6,3.9,2.64),color) then
            clone:Destroy()
            return
        end
    end
    clone.Parent = root
    local entry = {model=clone,owner=item.owner,originals={},links={},tower=tower.model,
        gantry=gantry and gantry.model}
    mounted[item.owner] = entry
    local function revoke()
        if mounted[item.owner] == entry then release(item.owner) end
    end
    local function watch(signal,handler)
        entry.links[#entry.links+1] = signal:Connect(handler or revoke)
    end
    watch(clone.AncestryChanged,function() if clone.Parent ~= root then revoke() end end)
    watch(clone.DescendantRemoving,revoke)
    watch(item.owner.AncestryChanged)
    watch(item.owner.ChildAdded)
    watch(item.owner.ChildRemoved)
    watch(item.base.AncestryChanged)
    watch(item.base:GetPropertyChangedSignal("CFrame"))
    watch(item.base:GetPropertyChangedSignal("Anchored"))
    watch(item.base:GetPropertyChangedSignal("CanCollide"))
    for _,attribute in ipairs({"RetrofitIndex","RetrofitOrigin","SignatureVariant",
        "OriginalExteriorRetrofit","SourceIsOriginal","CosmeticOnly"}) do
        watch(item.owner:GetAttributeChangedSignal(attribute))
    end
    for _,asset in ipairs(gantry and {tower,gantry} or {tower}) do
        watch(asset.model.AncestryChanged)
        watch(asset.model.DescendantRemoving)
        watch(asset.model.DescendantAdded)
        watch(asset.holder:GetAttributeChangedSignal("OwnerVerified"))
        watch(asset.holder:GetPropertyChangedSignal("Name"))
        watch(asset.model:GetPropertyChangedSignal("Name"))
        for _,attribute in ipairs({"OwnerVerified","CosmeticOnly","Original3DAssetId",asset.spec.tag}) do
            watch(asset.model:GetAttributeChangedSignal(attribute))
        end
        for _,piece in ipairs(asset.pieces) do
            for _,property in ipairs({"MeshId","Size","CFrame","Anchored","CanCollide","CanTouch","CanQuery"}) do
                watch(piece:GetPropertyChangedSignal(property))
            end
        end
    end
    for _,part in ipairs(item.parts) do
        entry.originals[part] = part.Transparency
        watch(part:GetAttributeChangedSignal("SceneryLodHidden"))
        if part:IsA("MeshPart") then
            watch(part:GetPropertyChangedSignal("MeshId"))
            watch(part:GetAttributeChangedSignal("Original3DAssetId"))
        end
        for _,property in ipairs({"Name","CFrame","Size","Anchored","CanCollide","CanTouch",
            "CanQuery","LocalTransparencyModifier"}) do watch(part:GetPropertyChangedSignal(property)) end
        part.Transparency = 1
    end
end

function Kit.sync(arena,point,tier,ready,touch,pressure,look)
    if activeArena ~= arena then clear();activeArena = arena end
    local caps = touch and TOUCH_CAPS or CAPS
    local stress = tonumber(pressure) or 0
    local cap = (stress ~= stress or stress < 1) and (caps[tier] or 0) or 0
    local base,fleet,variant,sx,sz = around(arena)
    if cap == 0 or not ready or typeof(point) ~= "Vector3" or not base then clear();return end
    local tower = approved(TOWER)
    local gantry = variant == "Crossroads" and approved(GANTRY) or nil
    if not tower or (variant == "Crossroads" and not gantry) then clear();return end
    local ranked = {}
    for index=1,4 do
        local owner = fleet:FindFirstChild(variant.."Retrofit"..index)
        local origin = anchor(base,variant,index,sx*.5,sz*.5)
        local held = owner and mounted[owner] ~= nil
        local offset = origin.Position-point
        if offset.Magnitude <= RANGE[tier]+(held and ACTIVE_RANGE or 0) then
            local parts = nativeParts(owner,fleet,variant,index,origin)
            if parts then
                ranked[#ranked+1] = {owner=owner,index=index,origin=origin,parts=parts,base=base,
                    score=SceneryLodRules.sceneryViewScore(offset.Magnitude-(held and 8 or 0),offset,look)}
            end
        end
    end
    table.sort(ranked,function(a,b)
        if a.score == b.score then return a.index < b.index end
        return a.score < b.score
    end)
    local wanted = {}
    for i=1,math.min(cap,#ranked) do
        local item = ranked[i]
        wanted[item.owner] = item
    end
    local stale = {}
    for owner,entry in pairs(mounted) do
        local item = wanted[owner]
        local intact = item and entry.tower == tower.model and entry.gantry == (gantry and gantry.model)
            and entry.model.Parent == root
        if not intact then
            stale[#stale+1] = owner
        else
            for _,part in ipairs(item.parts) do
                if entry.originals[part] == nil then intact = false;break end
            end
            if not intact then
                stale[#stale+1] = owner
            else
                for _,part in ipairs(item.parts) do
                    if part.Transparency < 1 then entry.originals[part] = part.Transparency end
                    part.Transparency = 1
                end
            end
        end
    end
    for _,owner in ipairs(stale) do release(owner) end
    for owner,item in pairs(wanted) do
        if not mounted[owner] then mount(item,tower,gantry) end
    end
end

function Kit.count()
    local models,parts = 0,0
    for owner,entry in pairs(mounted) do
        if entry.model.Parent == root then
            models += 1
            for part in pairs(entry.originals) do
                if part.Parent == owner and part.Transparency == 1 then parts += 1 end
            end
        end
    end
    return models,parts
end

return Kit
