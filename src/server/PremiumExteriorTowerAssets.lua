-- Creator-approved source-original skyline towers (asset workflow 42702281053).
-- Four true seven-material MeshPart models, one per actual source height.
-- This optional server import is never allowed to stall rounds or bots.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalMeshScenery = require("./OriginalMeshScenery")
local GlobalApprovedImportGate = require("./PremiumApprovedAssetImportGate")

local Assets = {}
local SOURCES = {
    {height = 21, id = 137744886537150},
    {height = 24, id = 74958476744494},
    {height = 27, id = 97864559770371},
    {height = 30, id = 112172520488996},
}
-- Four original Models already approved by the creator. Their previous
-- first load at 145s prevented early rounds from seeing premium skyline.
-- Spread FOUR existing API calls across the session (not parallel):
-- first request after 36s, then ~77s, ~118s, ~159s on a fast API.
-- Each request still retains the same three-attempt bounded retry path.
local LOAD_STAGGER = {36,36,36,36}
local started = false

local function valid(model, entry)
    local n = 0
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return false end
            n += 1
        elseif item:IsA("LuaSourceContainer") then
            return false
        end
    end
    if n ~= 7 then return false end
    local _, dims = model:GetBoundingBox()
    local horizontal = {dims.X,dims.Z}
    table.sort(horizontal)
    -- Reject a distant large mesh pretending to be an approved tower;
    -- actual 3D source bounds are 11.84 x (height+1.2) x 9.84.
    return math.abs(dims.Y-(entry.height+1.2)) <= .42
        and math.abs(horizontal[1]-9.84) <= .36
        and math.abs(horizontal[2]-11.84) <= .38
end

function Assets.start()
    if started then return end
    started = true
    local holder = ReplicatedStorage:FindFirstChild("ApprovedExteriorTowerTemplates")
    if holder and not holder:IsA("Folder") then return end
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "ApprovedExteriorTowerTemplates"
        holder.Parent = ReplicatedStorage
    end
    holder:SetAttribute("OwnerVerified",true)
    task.spawn(function()
        for index, entry in ipairs(SOURCES) do
            task.wait(LOAD_STAGGER[index])
            local name = "Tower"..tostring(entry.height)
            if not holder:FindFirstChild(name) then
                for attempt = 1, 3 do
                    local ok, raw = pcall(GlobalApprovedImportGate.load,
                        AssetService, entry.id)
                    if ok and raw and raw:IsA("Model") then
                        local clean = OriginalMeshScenery.sanitize(raw)
                        raw:Destroy()
                        if not clean or not valid(clean, entry) then
                            if clean then clean:Destroy() end
                            warn("Original skyline tower rejected by bounds",
                                entry.height)
                            break
                        end
                        clean.Name = name
                        clean:SetAttribute("OwnerVerified",true)
                        clean:SetAttribute("CosmeticOnly",true)
                        clean:SetAttribute("OriginalExteriorTower3D",true)
                        clean:SetAttribute("Original3DAssetId",entry.id)
                        clean.Parent = holder
                        holder:SetAttribute(name.."Ready",true)
                        break
                    end
                    if typeof(raw) == "Instance" then raw:Destroy() end
                    if attempt == 3 then
                        warn("Original skyline source unavailable",
                            entry.height,tostring(raw))
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
