local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")

local VfxQuality=require(ReplicatedStorage.Shared.VfxQuality)
local DisasterSetpiece=require(ReplicatedStorage.Shared.DisasterSetpiece)
local DisasterIntroGlyphKit=require(script.Parent.DisasterIntroGlyphKit)
local DisasterIntroMotionKit=require(script.Parent.DisasterIntroMotionKit)

local player=Players.LocalPlayer
local stateEvent=ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local previousPhase="waiting"
local token=0
local glyphFolder=Instance.new("Folder")
glyphFolder.Name="DisasterIntroGlyphLocal"
glyphFolder.Parent=workspace
local motionFolder=Instance.new("Folder")
motionFolder.Name="DisasterIntroMotionLocal"
motionFolder.Parent=workspace

local function arenaBase()
    local g=workspace:FindFirstChild("GeneratedMap")
    local a=g and g:FindFirstChild("Arena")
    local b=a and a:FindFirstChild("Base")
    return b and b:IsA("BasePart") and b or nil
end

local function part(name,size,cf,color,transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = Enum.Material.Neon
    p.Color = color
    p.Transparency = transparency or 0.3
    p.Parent = motionFolder
    return p
end

local function tween(p,duration,goal)
    TweenService:Create(p,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),goal):Play()
    Debris:AddItem(p,duration+0.2)
end

-- Existing per-hazard physical intro is enhanced by a distinct geometric
-- emblem for each of the eleven disasters, never a shared generic ring.
local function revealGlyphs(base, ids, current)
    if token~=current or not base.Parent then return end
    local tier=VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reduced=player:GetAttribute("ReduceMotion")==true
    local duration=reduced and 0.33 or 0.80
    for slot,id in ipairs(ids or {}) do
        if slot>2 then break end
        local bundle=DisasterIntroGlyphKit.build(
            glyphFolder,base,tostring(id),tier.Name,slot)
        if bundle then
            for _,piece in ipairs(bundle.parts) do
                tween(piece,duration,{Transparency=1})
            end
            Debris:AddItem(bundle.folder,duration+0.14)
        end
    end
end

local function playProfile(profile,base,index,total,current)
    if token~=current or not base.Parent then return end
    local tier=VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reduced=player:GetAttribute("ReduceMotion")==true
    local centerFrame=base.CFrame*CFrame.new(0,base.Size.Y*0.5+0.14,0)
    local center=centerFrame.Position
    local span=math.max(base.Size.X,base.Size.Z)
    local duration=reduced and 0.28 or 0.58
    if profile.Kind=="freeze" or profile.Kind=="blast"
        or profile.Kind=="void" or profile.Kind=="collapse"
        or profile.Kind=="shock" then
        DisasterIntroMotionKit.emit(
            motionFolder,profile.Kind,centerFrame,span,
            profile.Color,profile.Secondary,tier.Name,reduced,duration
        )
        return
    end
    if profile.Kind=="rise" then
        for i=1,(tier.Name=="High" and 4 or 2) do
            local x=((i%2==0) and 1 or -1)*span*0.34
            local z=((i<=2) and 1 or -1)*span*0.34
            local p=part("LavaIntro",Vector3.new(0.35,1,0.35),CFrame.new(center+Vector3.new(x,0,z)),profile.Color,0.3)
            tween(p,duration,{Size=Vector3.new(0.18,13,0.18),CFrame=p.CFrame*CFrame.new(0,6,0),Transparency=1})
        end
    elseif profile.Kind=="skyfall" then
        for i=1,(tier.Name=="Low" and 2 or 4) do
            local x=((i*37)%9-4)*span*0.07
            local z=((i*53)%9-4)*span*0.07
            local p=part("MeteorIntro",Vector3.new(0.28,10,0.28),CFrame.new(center+Vector3.new(x,18,z)),profile.Color,0.36)
            tween(p,duration,{CFrame=CFrame.new(center+Vector3.new(x,2,z)),Transparency=1})
        end
    elseif profile.Kind=="lift" then
        for i=1,(tier.Name=="Low" and 3 or 6) do
            local angle=(i/6)*math.pi*2
            local p=part("GravityIntro",Vector3.new(0.2,3,0.2),CFrame.new(center+Vector3.new(math.cos(angle)*span*0.28,0,math.sin(angle)*span*0.28)),profile.Color,0.44)
            tween(p,duration,{CFrame=p.CFrame*CFrame.new(0,10,0),Transparency=1})
        end
    elseif profile.Kind=="fracture" then
        for i=1,4 do
            local yaw=math.rad((i-1)*45)
            local p=part("FractureIntro",Vector3.new(span*0.55,0.08,0.18),CFrame.new(center)*CFrame.Angles(0,yaw,0),profile.Color,0.38)
            tween(p,duration,{Size=Vector3.new(span*0.78,0.05,0.08),Transparency=1})
        end
    elseif profile.Kind=="spiral" then
        for i=1,(tier.Name=="Low" and 3 or 6) do
            local angle=(i/6)*math.pi*2
            local p=part("TornadoIntro",Vector3.new(0.22,5,0.22),CFrame.new(center+Vector3.new(math.cos(angle)*span*0.22,2,math.sin(angle)*span*0.22)),profile.Color,0.4)
            tween(p,duration,{CFrame=CFrame.new(center+Vector3.new(math.cos(angle+1.3)*span*0.10,9,math.sin(angle+1.3)*span*0.10)),Transparency=1})
        end
    elseif profile.Kind=="speed" then
        for i=1,(tier.Name=="Low" and 3 or 6) do
            local yaw=math.rad((i-1)*(180/6))
            local p=part("SpeedIntro",Vector3.new(span*0.34,0.08,0.12),CFrame.new(center)*CFrame.Angles(0,yaw,0),profile.Color,0.38)
            tween(p,duration*0.8,{CFrame=p.CFrame*CFrame.new(0,0,-span*0.22),Transparency=1})
        end
    end
end

local function startIntro(state, current, retry)
    if token~=current then return end
    local base=arenaBase()
    if not base then
        -- The arena base can replicate after RoundState on slow mobile clients.
        if retry then
            task.delay(0.24,function()
                if token==current then startIntro(state,current,false) end
            end)
        end
        return
    end
    revealGlyphs(base,state.disasterIds,current)
    local profiles=DisasterSetpiece.forIds(state.disasterIds)
    for i,p in ipairs(profiles) do
        task.delay((i-1)*0.11,function()
            playProfile(p,base,i,#profiles,current)
        end)
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase=tostring(state.phase or "waiting")
    if phase=="round" and previousPhase~="round" then
        token+=1
        glyphFolder:ClearAllChildren()
        motionFolder:ClearAllChildren()
        startIntro(state,token,true)
    elseif phase~="round" then
        token+=1
        glyphFolder:ClearAllChildren()
        motionFolder:ClearAllChildren()
    end
    previousPhase=phase
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    if player:GetAttribute("ReduceMotion")==true then
        glyphFolder:ClearAllChildren()
        motionFolder:ClearAllChildren()
    end
end)
