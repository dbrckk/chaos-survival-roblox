local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "DisasterSignatureVfxLocal"
folder.Parent = workspace

local phase = "waiting"
local ids = {}
local clock = 0
local updateClock = 0
local states = {}
local mapConnection = nil

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function has(id)
    for _, value in ipairs(ids) do
        if value == id then
            return true
        end
    end
    return false
end

local function clear()
    table.clear(states)
    folder:ClearAllChildren()
end

local function arenaBase()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    return base and base:IsA("BasePart") and base or nil
end

local function part(name,size,cf,color,material,transparency,shape)
    local p=Instance.new("Part")
    p.Name=name
    p.Size=size
    p.CFrame=cf
    p.Anchored=true
    p.CanCollide=false
    p.CanTouch=false
    p.CanQuery=false
    p.CastShadow=false
    p.Color=color
    p.Material=material or Enum.Material.Neon
    p.Transparency=transparency or 0
    if shape then p.Shape=shape end
    p.Parent=folder
    return p
end

local function addTornado(base, profile)
    local q=tier()
    local count=q.Name=="Low" and 3 or (q.Name=="Medium" and 5 or 8)
    local radius=math.min(base.Size.X,base.Size.Z)*0.22
    for i=1,count do
        local angle=((i-1)/count)*math.pi*2
        local height=4+i*1.8
        local p=part(
            "TornadoRibbon"..i,
            Vector3.new(0.32,height,0.32),
            CFrame.new(base.Position+Vector3.new(math.cos(angle)*radius,height*0.5+1,math.sin(angle)*radius)),
            profile.Accent,
            Enum.Material.Neon,
            q.Name=="Low" and 0.68 or 0.52
        )
        states[#states+1]={kind="tornado",part=p,index=i,base=base,radius=radius* (0.75+i*0.06)}
    end
end

local function addMeteors(base, profile)
    local q=tier()
    if q.Name=="Low" then return end
    local count=q.Name=="High" and 5 or 3
    for i=1,count do
        local seed=i*37
        local x=((((seed)%11)/10)*2-1)*base.Size.X*0.38
        local z=(((((seed*3)%13)/12)*2-1))*base.Size.Z*0.38
        local start=base.Position+Vector3.new(x,38+i*4,z)
        local endPos=base.Position+Vector3.new(x*0.75,2,z*0.75)
        local direction=endPos-start
        local length=direction.Magnitude
        local beam=part(
            "MeteorSkyTrail"..i,
            Vector3.new(0.38,0.38,length),
            CFrame.lookAt(start+direction*0.5,endPos),
            i%2==0 and profile.Accent or profile.Tint,
            Enum.Material.Neon,
            0.66
        )
        states[#states+1]={kind="meteor",part=beam,index=i,base=base}
    end
end

local function addLava(base, profile)
    local q=tier()
    local count=q.Name=="Low" and 4 or (q.Name=="Medium" and 6 or 8)
    local hx=base.Size.X*0.5
    local hz=base.Size.Z*0.5
    for i=1,count do
        local side=i%4
        local pos
        if side==0 then pos=Vector3.new(-hx*0.85,1,(-0.6+((i*17)%100)/100*1.2)*hz)
        elseif side==1 then pos=Vector3.new(hx*0.85,1,(-0.6+((i*19)%100)/100*1.2)*hz)
        elseif side==2 then pos=Vector3.new((-0.6+((i*23)%100)/100*1.2)*hx,1,-hz*0.85)
        else pos=Vector3.new((-0.6+((i*29)%100)/100*1.2)*hx,1,hz*0.85) end

        local vent=part(
            "LavaHeatVent"..i,
            Vector3.new(0.45,4.8,0.45),
            base.CFrame*CFrame.new(pos),
            i%2==0 and profile.Accent or profile.Tint,
            Enum.Material.Neon,
            q.Name=="Low" and 0.62 or 0.48
        )
        states[#states+1]={kind="lava",part=vent,index=i,baseCFrame=vent.CFrame}
    end
end

local function addDarkness(base, profile)
    local q=tier()
    if q.Name=="Low" then return end
    local count=q.Name=="High" and 8 or 4
    local radius=math.min(base.Size.X,base.Size.Z)*0.42
    for i=1,count do
        local angle=((i-1)/count)*math.pi*2
        local orb=part(
            "VoidMote"..i,
            Vector3.new(1.6,1.6,1.6),
            CFrame.new(base.Position+Vector3.new(math.cos(angle)*radius,4+(i%3)*2,math.sin(angle)*radius)),
            profile.Accent,
            Enum.Material.Neon,
            0.58,
            Enum.PartType.Ball
        )
        states[#states+1]={kind="darkness",part=orb,index=i,base=base,angle=angle,radius=radius}
    end
end

local function rebuild()
    clear()
    if phase~="round" then return end
    local base=arenaBase()
    if not base then return end

    if has("Tornado") then
        addTornado(base,DisasterVisuals.get("Tornado"))
    end
    if has("Meteors") then
        addMeteors(base,DisasterVisuals.get("Meteors"))
    end
    if has("RisingLava") then
        addLava(base,DisasterVisuals.get("RisingLava"))
    end
    if has("Darkness") then
        addDarkness(base,DisasterVisuals.get("Darkness"))
    end
end

local function bindMap()
    if mapConnection then mapConnection:Disconnect() end
    local generated=workspace:FindFirstChild("GeneratedMap")
    if generated then
        mapConnection=generated.ChildAdded:Connect(function(child)
            if child.Name=="Arena" then task.delay(0.08,rebuild) end
        end)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name=="GeneratedMap" then
        bindMap()
        task.delay(0.08,rebuild)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name=="GeneratedMap" then
        clear()
        bindMap()
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(rebuild)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(rebuild)

stateEvent.OnClientEvent:Connect(function(state)
    phase=tostring(state.phase or "waiting")
    ids={}
    for _,id in ipairs(state.disasterIds or {}) do
        ids[#ids+1]=tostring(id)
    end
    rebuild()
end)

RunService.RenderStepped:Connect(function(dt)
    if #states==0 then return end
    clock+=dt
    updateClock+=dt
    local q=tier()
    if updateClock<math.max(1/30,q.UpdateInterval) then return end
    updateClock=0
    local reduced=player:GetAttribute("ReduceMotion")==true
    local motion=reduced and 0.16 or 1

    for _,s in ipairs(states) do
        local p=s.part
        if not p or not p.Parent then continue end

        if s.kind=="tornado" and s.base and s.base.Parent then
            local angle=clock*(0.75+s.index*0.035)*motion+s.index
            local radius=s.radius*(0.88+0.12*math.sin(clock*0.8+s.index))
            local y=3+s.index*1.8+math.sin(clock*1.2+s.index)*0.6*motion
            p.CFrame=CFrame.new(
                s.base.Position+Vector3.new(math.cos(angle)*radius,y,math.sin(angle)*radius)
            )*CFrame.Angles(0,-angle,0)
            p.Transparency=0.44+((math.sin(clock*2+s.index)+1)*0.5)*0.22
        elseif s.kind=="meteor" then
            p.Transparency=0.60+((math.sin(clock*3.4+s.index)+1)*0.5)*0.24
        elseif s.kind=="lava" then
            local pulse=(math.sin(clock*(2.6+s.index*0.05))+1)*0.5
            p.Size=Vector3.new(0.45,4.4+pulse*3.2*motion,0.45)
            p.CFrame=s.baseCFrame*CFrame.new(0,(p.Size.Y-4.8)*0.5,0)
            p.Transparency=0.42+pulse*0.20
        elseif s.kind=="darkness" and s.base and s.base.Parent then
            local angle=s.angle+clock*0.12*motion*(s.index%2==0 and 1 or -1)
            local y=5+math.sin(clock*0.9+s.index)*1.6*motion
            p.CFrame=CFrame.new(
                s.base.Position+Vector3.new(math.cos(angle)*s.radius,y,math.sin(angle)*s.radius)
            )
            p.Transparency=0.50+((math.sin(clock*1.4+s.index)+1)*0.5)*0.28
        end
    end
end)

bindMap()
rebuild()
