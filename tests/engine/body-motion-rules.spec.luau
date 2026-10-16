--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local BodyMotionRules = require("../../src/shared/BodyMotionRules")
local BotMotionPresentationRules = require("../../src/shared/BotMotionPresentationRules")
local LocomotionDynamics = require("../../src/shared/LocomotionDynamics")
local GroundFx = require("../../src/client/LocomotionGroundFx")
local MotionTrailRegistry = require("../../src/client/CharacterMotionTrailRegistry")
local MotionTrailBuilder = require("../../src/client/CharacterMotionTrailBuilder")

describe("Body motion rules", function()
    it("crossfades additional R6/R15 body poses around Showtime emotes", function()
        local blend = BodyMotionRules.emotePoseBlend
        expect(blend(1, false, 0.10)).toBe(1)
        expect(blend(1, true, 0)).toBe(1)
        local falling = blend(1, true, 0.10)
        expect(falling > 0 and falling < 0.35).toBe(true)
        local softer = blend(falling, true, 0.10)
        expect(softer >= 0 and softer < falling).toBe(true)
        local rising = blend(softer, false, 0.10)
        expect(rising > softer and rising < 1).toBe(true)
        local stable = 1
        for _ = 1, 60 do stable = blend(stable, true, 1 / 60) end
        expect(stable < 0.001).toBe(true)
        for _ = 1, 60 do stable = blend(stable, false, 1 / 60) end
        expect(stable > 0.999).toBe(true)
        expect(blend(-20, false, 0)).toBe(0)
        expect(blend(20, true, 0)).toBe(1)
        expect(blend(1, true, -3)).toBe(1)
        expect(blend(1, true, nil)).toBe(1)
        expect(blend(1, nil, 0.10)).toBe(1)
    end)


    it("compacts R6 motor references past the intentionally missing Waist", function()
        local model = Instance.new("Model")
        local torso = Instance.new("Part")
        torso.Name = "Torso"
        torso.Parent = model
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Parent = model
        local function add(parent, name)
            local j = Instance.new("Motor6D")
            j.Name = name
            j.C0 = CFrame.new(0.2, 0.3, -0.4)
            j.Parent = parent
            return j
        end
        local rootJoint = add(root, "RootJoint")
        local lh = add(torso, "Left Hip")
        local rh = add(torso, "Right Hip")
        local ls = add(torso, "Left Shoulder")
        local rs = add(torso, "Right Shoulder")
        local joints = BodyMotionRules.joints(model, Enum.HumanoidRigType.R6)
        local active = BodyMotionRules.activeJoints(joints)
        expect(#active).toBe(5)
        expect(active[1]).toBe(rootJoint)
        expect(active[2]).toBe(lh)
        expect(active[3]).toBe(rh)
        expect(active[4]).toBe(ls)
        expect(active[5]).toBe(rs)
        local snapshots = {}
        for _, motor in ipairs(active) do snapshots[motor] = motor.C0 end
        for _, motor in ipairs(active) do
            motor.C0 = motor.C0 * CFrame.Angles(0, 0.4, 0)
        end
        for _, motor in ipairs(active) do
            motor.C0 = snapshots[motor]
            expect(motor.C0).toBe(snapshots[motor])
        end
        local late = Instance.new("Part")
        late.Name = "Left Shoulder"
        late.Parent = torso
        ls:Destroy()
        expect(#BodyMotionRules.activeJoints(
            BodyMotionRules.joints(model, Enum.HumanoidRigType.R6)
        )).toBe(4)
        late:Destroy()
        local replacement = add(torso, "Left Shoulder")
        local healed = BodyMotionRules.activeJoints(
            BodyMotionRules.joints(model, Enum.HumanoidRigType.R6))
        expect(#healed).toBe(5)
        expect(healed[4]).toBe(replacement)
        local broken = BodyMotionRules.activeJoints({waist = "not a motor",
            rootJoint = rootJoint})
        expect(#broken).toBe(1)
        expect(broken[1]).toBe(rootJoint)
        expect(#BodyMotionRules.activeJoints(nil)).toBe(0)
        model:Destroy()
    end)


    it("binds native R15 and R6 body joints without duplicating motors", function()
        local rules = BodyMotionRules
        local function part(model, name)
            local p = Instance.new("Part")
            p.Name = name
            p.Parent = model
            return p
        end
        local function joint(parent, name)
            local j = Instance.new("Motor6D")
            j.Name = name
            j.Parent = parent
            return j
        end
        local r15 = Instance.new("Model")
        local lower = part(r15, "LowerTorso")
        local upper = part(r15, "UpperTorso")
        local waist = joint(upper, "Waist")
        local root15 = joint(lower, "Root")
        local lhip15 = joint(lower, "LeftHip")
        joint(lower, "RightHip")
        joint(upper, "LeftShoulder")
        joint(upper, "RightShoulder")
        local b15 = rules.joints(r15, Enum.HumanoidRigType.R15)
        expect(b15.waist).toBe(waist)
        expect(b15.rootJoint).toBe(root15)
        expect(b15.leftHip).toBe(lhip15)
        expect(b15.rightShoulder ~= nil).toBe(true)
        local r6 = Instance.new("Model")
        local torso = part(r6, "Torso")
        local hrp = part(r6, "HumanoidRootPart")
        local root6 = joint(hrp, "RootJoint")
        local lhip6 = joint(torso, "Left Hip")
        local rhip6 = joint(torso, "Right Hip")
        local leftArm = joint(torso, "Left Shoulder")
        local rightArm = joint(torso, "Right Shoulder")
        local b6 = rules.joints(r6, Enum.HumanoidRigType.R6)
        expect(b6.waist == nil).toBe(true)
        expect(b6.rootJoint).toBe(root6)
        expect(b6.leftHip).toBe(lhip6)
        expect(b6.rightHip).toBe(rhip6)
        expect(b6.leftShoulder).toBe(leftArm)
        expect(b6.rightShoulder).toBe(rightArm)
        expect(rules.rigPoseScale(Enum.HumanoidRigType.R15)).toBe(1)
        expect(rules.rigPoseScale(Enum.HumanoidRigType.R6)).toBe(0.46)
        expect(rules.rigPoseScale(nil)).toBe(0)
        expect(rules.joints(r6, nil) == nil).toBe(true)
        expect(rules.joints(nil, Enum.HumanoidRigType.R6) == nil).toBe(true)
        -- Partially streamed R6 rigs are fail-soft; no duplicate joints.
        root6:Destroy()
        local partial = rules.joints(r6, Enum.HumanoidRigType.R6)
        expect(partial.rootJoint == nil).toBe(true)
        expect(partial.leftHip).toBe(lhip6)
        -- Non-Motor6D lookalikes must not become animation targets.
        leftArm:Destroy()
        local decoy = Instance.new("Folder")
        decoy.Name = "Left Shoulder"
        decoy.Parent = torso
        expect(rules.joints(r6, Enum.HumanoidRigType.R6).leftShoulder == nil).toBe(true)
        r6:Destroy()
        r15:Destroy()
    end)


    it("differentiates starting sprint and braking with released input", function()
        local launch, noBrake = LocomotionDynamics.acceleration(12, 2, 0.10, true)
        local noLaunch, braking = LocomotionDynamics.acceleration(8, 20, 0.10, true)
        expect(launch > 0).toBe(true)
        expect(noBrake).toBe(0)
        expect(noLaunch).toBe(0)
        expect(braking > 0).toBe(true)
        -- A hard stop may leap directly from sprint speed to zero in one
        -- low-FPS sample or after collision: the skid must not disappear.
        local hardStopLaunch, hardStopSkid =
            LocomotionDynamics.acceleration(0, 20, 0.11, true)
        expect(hardStopLaunch).toBe(0)
        expect(hardStopSkid > 0.7).toBe(true)
        local settledLaunch, settledStop =
            LocomotionDynamics.acceleration(0, 0, 0.11, true)
        expect(settledLaunch).toBe(0)
        expect(settledStop).toBe(0)
        local airborneLaunch, airborneBrake = LocomotionDynamics.acceleration(4, 20, 0.10, false)
        expect(airborneLaunch).toBe(0)
        expect(airborneBrake).toBe(0)
        local invalidLaunch, invalidBrake = LocomotionDynamics.acceleration(10, 0, 0, true)
        expect(invalidLaunch).toBe(0)
        expect(invalidBrake).toBe(0)
    end)

    it("restores human momentum trails after late or replaced avatar rigs", function()
        local mock = {GetPlayerFromCharacter = function() return nil end}
        local tracked, stop, watch, count = MotionTrailRegistry.create(mock)
        local model = Instance.new("Model")
        model.Name = "StreamingHumanTrail"
        model.Parent = workspace
        watch(model)
        expect(count()).toBe(1)
        expect(tracked[model] == nil).toBe(true)
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = model
        watch(model)
        expect(tracked[model] == nil).toBe(true)
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Parent = model
        watch(model)
        expect(tracked[model].root).toBe(root)
        local oldOrder = tracked[model].order
        local oldTrail = Instance.new("Trail")
        oldTrail.Enabled = true
        oldTrail.Parent = root
        tracked[model].trail = oldTrail
        root.Parent = nil
        watch(model)
        expect(tracked[model] == nil).toBe(true)
        expect(count()).toBe(1)
        expect(oldTrail.Enabled).toBe(false)
        local replacement = Instance.new("Part")
        replacement.Name = "HumanoidRootPart"
        replacement.Parent = model
        watch(model)
        expect(tracked[model].root).toBe(replacement)
        expect(tracked[model].order > oldOrder).toBe(true)
        expect(tracked[model].trail == nil).toBe(true)
        humanoid.Parent = nil
        watch(model)
        expect(tracked[model] == nil).toBe(true)
        local nextHumanoid = Instance.new("Humanoid")
        nextHumanoid.Parent = model
        watch(model)
        expect(tracked[model].humanoid).toBe(nextHumanoid)
        watch(model)
        expect(count()).toBe(1)
        stop(model)
        expect(tracked[model] == nil).toBe(true)
        expect(count()).toBe(0)
        watch(model)
        expect(count()).toBe(1)
        model.Parent = nil
        expect(count()).toBe(0)
        model.Parent = workspace
        watch(model)
        expect(tracked[model] ~= nil).toBe(true)
        stop(model)
        model:Destroy()
        root:Destroy()
        humanoid:Destroy()
    end)

    it("releases owned ribbon geometry when a human rig streams out or is replaced", function()
        local mock = {GetPlayerFromCharacter = function() return nil end}
        local tracked, stop, watch, count =
            MotionTrailRegistry.create(mock, MotionTrailBuilder.release)
        local model = Instance.new("Model")
        model.Parent = workspace
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = model
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Parent = model
        watch(model)
        expect(count()).toBe(1)
        local original = MotionTrailBuilder.ensure(root,
            Color3.fromRGB(80, 160, 255))
        original.Enabled = true
        tracked[model].trail = original
        root.Parent = nil
        task.wait()
        expect(original.Parent == nil).toBe(true)
        expect(root:FindFirstChild("ChaosMotionTrailLeft") == nil).toBe(true)
        expect(root:FindFirstChild("ChaosMotionTrailRight") == nil).toBe(true)
        expect(tracked[model] == nil).toBe(true)
        expect(count()).toBe(1)
        local replacement = Instance.new("Part")
        replacement.Name = "HumanoidRootPart"
        replacement.Parent = model
        task.wait()
        expect(tracked[model] ~= nil).toBe(true)
        local nextTrail = MotionTrailBuilder.ensure(replacement,
            Color3.fromRGB(255, 120, 80))
        tracked[model].trail = nextTrail
        stop(model)
        expect(nextTrail.Parent == nil).toBe(true)
        expect(replacement:FindFirstChild("ChaosMotionTrailLeft") == nil)
            .toBe(true)
        expect(replacement:FindFirstChild("ChaosMotionTrailRight") == nil)
            .toBe(true)
        expect(count()).toBe(0)
        model:Destroy()
        root:Destroy()
    end)

    it("stays responsive to sharp corner cuts and 180-degree turnarounds", function()
        local sign, weight = LocomotionDynamics.cut(
            Vector3.new(0, 0, -1), Vector3.new(1, 0, 0), 18, true
        )
        expect(math.abs(sign) > 0.3).toBe(true)
        expect(weight > 0.3 and weight < 0.8).toBe(true)
        local reverse, reverseWeight = LocomotionDynamics.cut(
            Vector3.new(0, 0, -1), Vector3.new(0, 0, 1), 18, true
        )
        expect(math.abs(reverse) > 0.9).toBe(true)
        expect(reverseWeight).toBe(1)
        local idle, idleWeight = LocomotionDynamics.cut(
            Vector3.new(0, 0, -1), Vector3.new(0, 0, 1), 0, true
        )
        expect(idle).toBe(0)
        expect(idleWeight).toBe(0)
        local air, _ = LocomotionDynamics.cut(
            Vector3.new(0, 0, -1), Vector3.new(0, 0, 1), 18, false
        )
        expect(air).toBe(0)
    end)

    it("classifies only major grounded movements into a short floor accent", function()
        local r = LocomotionDynamics
        local skid, strength = r.groundCue(0.7, 0.95, 0.9, "High", false, "round")
        expect(skid).toBe("Skid")
        expect(strength > 0.9).toBe(true)
        local pivot = r.groundCue(0.10, 0.1, -0.9, "Medium", false, "round")
        expect(pivot).toBe("Pivot")
        local sprint = r.groundCue(0.9, 0, 0, "Medium", false, "round")
        expect(sprint).toBe("Launch")
        for _, data in ipairs({
            {"Low", false, "round"},
            {"High", true, "round"},
            {"High", false, "waiting"},
        }) do
            local nothing, quiet = r.groundCue(1, 1, 1, data[1], data[2], data[3])
            expect(nothing == nil).toBe(true)
            expect(quiet).toBe(0)
        end
        local noCue = r.groundCue(0.1, 0.1, 0.1, "High", false, "round")
        expect(noCue == nil).toBe(true)
    end)

    it("creates only bounded non-colliding transient ground geometry", function()
        local root = Instance.new("Folder")
        local cf = CFrame.new(0, 2, 0)
        for _, style in ipairs({"Launch", "Skid", "Pivot"}) do
            local high = GroundFx.build(root, cf, style, 0.9, "High")
            local medium = GroundFx.build(root, cf, style, 0.9, "Medium")
            expect(high ~= nil).toBe(true)
            expect(#high:GetChildren()).toBe(4)
            expect(#medium:GetChildren()).toBe(2)
            for _, child in ipairs(high:GetChildren()) do
                expect(child:IsA("BasePart")).toBe(true)
                expect(child.CanCollide).toBe(false)
                expect(child.CanTouch).toBe(false)
                expect(child.CanQuery).toBe(false)
                expect(child.Anchored).toBe(true)
            end
            high:Destroy()
            medium:Destroy()
        end
        expect(GroundFx.build(root, cf, "Skid", 1, "Low") == nil).toBe(true)
        expect(GroundFx.build(root, cf, "Other", 1, "High") == nil).toBe(true)
        root:Destroy()
    end)

    it("authors three distinct 3D ground signatures without increasing the GPU budget", function()
        local surface = Instance.new("Folder")
        for _, tier in ipairs({"Medium", "High"}) do
            local count = tier == "High" and 4 or 2
            for _, kind in ipairs({"Launch", "Skid", "Pivot"}) do
                local fx = GroundFx.build(surface, CFrame.new(5, 1, -3),
                    kind, 0.9, tier)
                expect(#fx:GetChildren()).toBe(count)
                for index, piece in ipairs(fx:GetChildren()) do
                    local sig = GroundFx.signature(kind, index, 0.9, tier)
                    expect(sig ~= nil).toBe(true)
                    expect(piece.ClassName).toBe(sig.Class)
                    expect(piece.Material).toBe(sig.Material)
                    expect(piece.Size).toBe(sig.Size)
                    expect(piece.CastShadow).toBe(false)
                    expect(piece.CanCollide).toBe(false)
                    expect(piece.CanTouch).toBe(false)
                    expect(piece.CanQuery).toBe(false)
                    expect(piece.Transparency >= 0.25).toBe(true)
                    if tier == "Medium" then
                        expect(piece.Material == Enum.Material.Neon).toBe(false)
                    end
                end
                if kind == "Skid" then
                    expect(fx:GetChildren()[1]:IsA("Part")).toBe(true)
                    expect(fx:GetChildren()[1].Material).toBe(Enum.Material.Metal)
                else
                    expect(fx:GetChildren()[1]:IsA("WedgePart")).toBe(true)
                end
                fx:Destroy()
            end
            expect(GroundFx.signature("Launch", count + 1, 1, tier) == nil).toBe(true)
        end
        expect(GroundFx.signature("Launch", 1, 1, "Low") == nil).toBe(true)
        expect(GroundFx.signature("Invalid", 1, 1, "High") == nil).toBe(true)
        expect(GroundFx.signature("Skid", 1.5, 1, "High") == nil).toBe(true)
        expect(GroundFx.signature("Skid", 0, 1, "High") == nil).toBe(true)
        expect(#surface:GetChildren()).toBe(0)
        surface:Destroy()
    end)

    it("sculpts material-specific footwork marks without raising mobile part caps", function()
        local root = Instance.new("Folder")
        local frame = CFrame.new(10, 2, -6)
        for _, kind in ipairs({"Launch", "Skid", "Pivot"}) do
            local iceAccent = GroundFx.materialAccent(kind, Enum.Material.Ice,
                Color3.fromRGB(175, 212, 236), "High")
            local stoneAccent = GroundFx.materialAccent(kind, Enum.Material.Slate,
                Color3.fromRGB(95, 105, 113), "High")
            local mudAccent = GroundFx.materialAccent(kind, Enum.Material.Mud,
                Color3.fromRGB(122, 99, 80), "Medium")
            expect(iceAccent ~= stoneAccent).toBe(true)
            expect(stoneAccent ~= mudAccent).toBe(true)
            expect(GroundFx.materialAccent(kind, Enum.Material.Ice,
                nil, "Medium") ~= iceAccent).toBe(true)
            local ice = GroundFx.build(root, frame, kind, 0.9, "High",
                Enum.Material.Ice, Color3.fromRGB(175, 212, 236))
            expect(ice ~= nil and #ice:GetChildren() == 4).toBe(true)
            local marks = ice:GetChildren()
            -- BasePart.Color is stored with Roblox's 8-bit channel precision,
            -- while Color3:Lerp retains higher precision in the recipe.
            -- Check the visible color within one channel step, not exact bits.
            local storedAccent = marks[1].Color
            local channelStep = 1 / 255 + 0.00001
            expect(math.abs(storedAccent.R - iceAccent.R) <= channelStep
                and math.abs(storedAccent.G - iceAccent.G) <= channelStep
                and math.abs(storedAccent.B - iceAccent.B) <= channelStep)
                .toBe(true)
            expect(marks[2].Color ~= marks[1].Color).toBe(true)
            for _, piece in ipairs(marks) do
                expect(piece.Anchored).toBe(true)
                expect(piece.CanCollide).toBe(false)
                expect(piece.CanQuery).toBe(false)
                expect(piece.Size.Magnitude > 0).toBe(true)
            end
            ice:Destroy()
        end
        expect(GroundFx.materialAccent("Unknown", Enum.Material.Ice,
            nil, "High") == nil).toBe(true)
        expect(#root:GetChildren()).toBe(0)
        root:Destroy()
    end)

    it("rejects nonfinite contact impulses and geometry before allocation", function()
        local root = Instance.new("Folder")
        local frame = CFrame.new(3, 2, 1)
        for _, bad in ipairs({0/0, math.huge, -math.huge}) do
            expect(GroundFx.signature("Launch", 1, bad, "High") == nil).toBe(true)
            expect(GroundFx.signature("Skid", bad, 1, "High") == nil).toBe(true)
            expect(GroundFx.build(root, frame, "Pivot", bad, "High") == nil).toBe(true)
            expect(GroundFx.evictionCount(bad, 2, "Medium")).toBe(0)
            expect(GroundFx.evictionCount(6, bad, "Medium")).toBe(0)
            expect(GroundFx.surfaceBasis(Vector3.new(bad, 0, 0),
                Vector3.yAxis, Vector3.zAxis) == nil).toBe(true)
            expect(GroundFx.surfaceBasis(Vector3.zero,
                Vector3.new(0, bad, 0), Vector3.zAxis) == nil).toBe(true)
        end
        expect(GroundFx.build(root, frame, "Pivot", nil, "High") == nil).toBe(true)
        expect(GroundFx.build("not-an-instance", frame, "Pivot",
            0.9, "High") == nil).toBe(true)
        expect(GroundFx.signature("Launch", 1, 1, "Low") == nil).toBe(true)
        expect(GroundFx.evictionCount(16, 4, "High")).toBe(4)
        expect(#root:GetChildren()).toBe(0)
        root:Destroy()
    end)

    it("caps combined human and AI ground-contact bursts without cutting pairs", function()
        local root = Instance.new("Folder")
        local cf = CFrame.new(2, 0.1, 5)
        local rules = GroundFx
        expect(rules.livePieceBudget("High")).toBe(16)
        expect(rules.livePieceBudget("Medium")).toBe(8)
        expect(rules.livePieceBudget("Low")).toBe(0)
        expect(rules.evictionCount(16, 4, "High")).toBe(4)
        expect(rules.evictionCount(12, 4, "High")).toBe(0)
        expect(rules.evictionCount(7, 2, "Medium")).toBe(1)
        expect(rules.evictionCount(0, 2, "Medium")).toBe(0)
        local unrelated = Instance.new("Folder")
        unrelated.Name = "UnrelatedUI"
        unrelated.Parent = root
        for i = 1, 7 do
            local fx = GroundFx.build(root, cf,
                i % 2 == 0 and "Skid" or "Pivot", 0.90, "High")
            expect(fx ~= nil).toBe(true)
            local pieces = 0
            for _, group in ipairs(root:GetChildren()) do
                if group ~= unrelated then
                    pieces += #group:GetChildren()
                end
            end
            expect(pieces <= 16).toBe(true)
        end
        expect(unrelated.Parent).toBe(root)
        -- Switching to Medium enforces its smaller scene-wide cap.
        local medium = GroundFx.build(root, cf, "Launch", 0.88, "Medium")
        expect(medium ~= nil).toBe(true)
        local pieces = 0
        for _, group in ipairs(root:GetChildren()) do
            if group ~= unrelated then
                pieces += #group:GetChildren()
                expect(#group:GetChildren() == 2
                    or #group:GetChildren() == 4).toBe(true)
            end
        end
        expect(pieces <= 8).toBe(true)
        expect(GroundFx.build(root, cf, "Pivot", 0.88, "Low") == nil).toBe(true)
        root:Destroy()
    end)

    it("requires a living server-confirmed contestant for local battle scuffs", function()
        local r = LocomotionDynamics.footworkEligible
        expect(r("round", true, false, 100)).toBe(true)
        expect(r("round", true, nil, 1)).toBe(true)
        expect(r("round", nil, nil, 100)).toBe(false)
        expect(r("round", false, false, 100)).toBe(false)
        expect(r("round", true, true, 100)).toBe(false)
        expect(r("waiting", true, false, 100)).toBe(false)
        expect(r("result", true, false, 100)).toBe(false)
        expect(r("round", true, false, 0)).toBe(false)
        expect(r("round", true, false, nil)).toBe(false)
    end)

    it("places authored movement wedges tangent to rotated and inclined floors", function()
        local normal = Vector3.new(0.25, 1, 0.32).Unit
        local face = Vector3.new(0, 0, -1)
        local origin = Vector3.new(15, 6, -23)
        local basis = GroundFx.surfaceBasis(origin, normal, face)
        expect(basis ~= nil).toBe(true)
        expect((basis.Position - origin).Magnitude < 0.0001).toBe(true)
        expect(basis.UpVector:Dot(normal) > 0.999).toBe(true)
        expect(math.abs(basis.LookVector:Dot(normal)) < 0.001).toBe(true)
        expect(basis.LookVector:Dot(face) > 0.9).toBe(true)
        local root = Instance.new("Folder")
        for _, kind in ipairs({"Launch", "Skid", "Pivot"}) do
            local fx = GroundFx.build(root, basis, kind, 0.92, "High")
            expect(#fx:GetChildren()).toBe(4)
            for _, piece in ipairs(fx:GetChildren()) do
                expect(piece.CFrame.UpVector:Dot(normal) > 0.999).toBe(true)
                expect(piece.Anchored).toBe(true)
                expect(piece.CanCollide).toBe(false)
            end
            fx:Destroy()
        end
        root:Destroy()
        expect(GroundFx.surfaceBasis(origin, Vector3.new(0, 0, 1), face) == nil).toBe(true)
        expect(GroundFx.surfaceBasis(origin, Vector3.zero, face) == nil).toBe(true)
        expect(GroundFx.surfaceBasis(origin, normal, normal) == nil).toBe(true)
        expect(GroundFx.surfaceBasis(nil, normal, face) == nil).toBe(true)
    end)

    it("adds planted footsteps and safe airborne reach without forcing physics", function()
        expect(LocomotionDynamics.footPlant(0, 1, true)).toBe(1)
        expect(LocomotionDynamics.footPlant(math.pi / 2, 1, true)).toBe(0)
        expect(LocomotionDynamics.footPlant(0, 1, false)).toBe(0)
        expect(LocomotionDynamics.footPlant(0, 0, true)).toBe(0)
        local ascent, descent = LocomotionDynamics.flight(25, false, false)
        expect(ascent > 0).toBe(true)
        expect(descent).toBe(0)
        local downAscent, downBrace = LocomotionDynamics.flight(-28, false, false)
        expect(downAscent).toBe(0)
        expect(downBrace > 0).toBe(true)
        local moonAscent = LocomotionDynamics.flight(25, false, true)
        expect(moonAscent < ascent).toBe(true)
        local landReach, landBrace = LocomotionDynamics.flight(-35, true, false)
        expect(landReach).toBe(0)
        expect(landBrace).toBe(0)
    end)

    it("scales expressive movement to graphics quality and accessibility settings", function()
        expect(LocomotionDynamics.profile("High", false)).toBe(1)
        expect(LocomotionDynamics.profile("Low", false) < LocomotionDynamics.profile("Medium", false)).toBe(true)
        expect(LocomotionDynamics.profile("Medium", false) < LocomotionDynamics.profile("High", false)).toBe(true)
        expect(LocomotionDynamics.profile("High", true) <= 0.10).toBe(true)
    end)

    it("keeps stride off while idle or airborne", function()
        local idleWeight, idleFrequency = BodyMotionRules.stride(1, true, false)
        expect(idleWeight).toBe(0)
        expect(idleFrequency).toBe(0)

        local airWeight, airFrequency = BodyMotionRules.stride(16, false, false)
        expect(airWeight).toBe(0)
        expect(airFrequency).toBe(0)
    end)

    it("scales stride with speed and SpeedSurge", function()
        local walkWeight, walkFrequency = BodyMotionRules.stride(8, true, false)
        local runWeight, runFrequency = BodyMotionRules.stride(17, true, false)
        local surgeWeight, surgeFrequency = BodyMotionRules.stride(17, true, true)

        expect(runWeight > walkWeight).toBe(true)
        expect(runFrequency > walkFrequency).toBe(true)
        expect(surgeWeight >= runWeight).toBe(true)
        expect(surgeFrequency > runFrequency).toBe(true)
    end)

    it("only adds braking pose during meaningful deceleration", function()
        expect(BodyMotionRules.brakeWeight(120, true)).toBe(0)
        expect(BodyMotionRules.brakeWeight(-75, true) > 0).toBe(true)
        expect(BodyMotionRules.brakeWeight(-300, true)).toBe(1)
        expect(BodyMotionRules.brakeWeight(-300, false)).toBe(0)
    end)

    it("detects turn direction and severity", function()
        local rightSigned, rightSeverity = BodyMotionRules.turnResponse(
            Vector3.new(0, 0, -1),
            Vector3.new(1, 0, 0)
        )
        local leftSigned, leftSeverity = BodyMotionRules.turnResponse(
            Vector3.new(0, 0, -1),
            Vector3.new(-1, 0, 0)
        )
        local _, reverseSeverity = BodyMotionRules.turnResponse(
            Vector3.new(0, 0, -1),
            Vector3.new(0, 0, 1)
        )

        expect(rightSigned ~= 0).toBe(true)
        expect(leftSigned ~= 0).toBe(true)
        expect(rightSigned * leftSigned < 0).toBe(true)
        expect(math.abs(rightSeverity - 0.5) < 0.01).toBe(true)
        expect(math.abs(leftSeverity - 0.5) < 0.01).toBe(true)
        expect(reverseSeverity).toBe(1)
    end)

    it("uses a grounded pre-round anticipation stance without fighting movement", function()
        expect(BodyMotionRules.readyStance("waiting", true, 0)).toBe(0)
        expect(BodyMotionRules.readyStance("ready", false, 0)).toBe(0)
        expect(BodyMotionRules.readyStance("ready", true, 0)).toBe(1)
        expect(BodyMotionRules.readyStance("ready", true, 6)).toBe(0.5)
        expect(BodyMotionRules.readyStance("ready", true, 12)).toBe(0)
    end)

    it("reduces motion consistently when accessibility is enabled", function()
        expect(BodyMotionRules.motionScale(false)).toBe(1)
        expect(BodyMotionRules.motionScale(true)).toBe(0.18)
    end)
end)


describe("Directional character impact and cinematic AI footwork", function()
    it("reacts to the physical explosion side without rotating the avatar or applying force", function()
        local base = CFrame.new(20, 8, -14)
            * CFrame.Angles(0, math.rad(72), 0)
        local right = base.RightVector
        local forward = base.LookVector
        local strength, rightward, forwardward = BodyMotionRules.blastResponse(
            base, base.Position - right * 6, 8
        )
        expect(strength > 0 and strength < 1).toBe(true)
        expect(rightward > 0.99).toBe(true)
        expect(math.abs(forwardward) < 0.01).toBe(true)

        local _, leftward = BodyMotionRules.blastResponse(
            base, base.Position + right * 6, 8
        )
        expect(leftward < -0.99).toBe(true)
        local _, _, forwardReaction = BodyMotionRules.blastResponse(
            base, base.Position - forward * 5, 8
        )
        expect(forwardReaction > 0.99).toBe(true)
        local _, _, backwardReaction = BodyMotionRules.blastResponse(
            base, base.Position + forward * 5, 8
        )
        expect(backwardReaction < -0.99).toBe(true)
        local farIntensity = BodyMotionRules.blastResponse(
            base, base.Position + Vector3.new(200, 0, 0), 8
        )
        expect(farIntensity).toBe(0)
        local zeroIntensity, zeroSide, zeroForward = BodyMotionRules.blastResponse(
            base, base.Position, 8
        )
        expect(zeroIntensity).toBe(1)
        expect(zeroSide).toBe(0)
        expect(zeroForward).toBe(0)
        expect(BodyMotionRules.blastResponse(nil, base.Position, 8)).toBe(0)
        expect(BodyMotionRules.blastResponse(base, nil, 8)).toBe(0)
    end)

    it("culls far AI trails without flicker or extra instances", function()
        local visible = BotMotionPresentationRules.trailVisible
        expect(visible("Low", false, "round", true, 1, 5, false)).toBe(false)
        expect(visible("Medium", false, "round", true, 1, 40, false)).toBe(true)
        expect(visible("High", false, "round", true, 1, 95, false)).toBe(true)
        expect(visible("Medium", false, "round", true, 1, 70, false)).toBe(false)
        expect(visible("Medium", false, "round", true, 1, 70, true)).toBe(true)
        expect(visible("High", false, "round", true, 1, 100, false)).toBe(false)
        expect(visible("High", false, "round", true, 1, 100, true)).toBe(true)
        expect(visible("High", false, "round", true, 1, 108, true)).toBe(false)
        expect(visible("High", true, "round", true, 1, 5, true)).toBe(false)
        expect(visible("High", false, "ready", true, 1, 5, true)).toBe(false)
        expect(visible("High", false, "round", false, 1, 5, true)).toBe(false)
        expect(visible("High", false, "round", true, 0.3, 5, true)).toBe(false)
        expect(visible("High", false, "round", true, 1, -1, true)).toBe(false)
        expect(visible("High", false, "round", true, 1, nil, true)).toBe(false)
    end)

    it("rejects malformed human trail telemetry without bypassing tier caps", function()
        local rules = require("../../src/shared/CharacterMotionTrailRules")
        local function visible(ratio, distance, retained)
            return rules.visible("round", false, false, ratio,
                "High", false, distance, retained)
        end
        expect(visible(1, 0, false)).toBe(true)
        expect(visible(1, 90, false)).toBe(true)
        expect(visible(1, 93, true)).toBe(true)
        expect(visible(1, 94, true)).toBe(false)
        for _, bad in ipairs({-1, math.huge, -math.huge, 0/0}) do
            expect(visible(bad, 5, false)).toBe(false)
            expect(visible(bad, 5, true)).toBe(false)
            expect(visible(1, bad, false)).toBe(false)
            expect(visible(1, bad, true)).toBe(false)
        end
        expect(visible(nil, 5, true)).toBe(false)
        expect(visible(1, nil, true)).toBe(false)
        expect(visible("1", 5, false)).toBe(false)
        expect(visible(1, "5", false)).toBe(false)
        expect(rules.visible("round", false, false, 1,
            "Low", false, 5, true)).toBe(false)
        expect(rules.visible("round", false, false, 1,
            "High", true, 5, true)).toBe(false)
    end)

    it("suspends local and remote ribbons immediately without foreign cleanup", function()
        local rules = require("../../src/shared/CharacterMotionTrailRules")
        local localModel = Instance.new("Model")
        local remoteModel = Instance.new("Model")
        local localRoot = Instance.new("Part")
        local remoteRoot = Instance.new("Part")
        localRoot.Name, remoteRoot.Name = "HumanoidRootPart", "HumanoidRootPart"
        localRoot.Parent, remoteRoot.Parent = localModel, remoteModel
        local accent = Color3.fromRGB(90, 190, 255)
        local localTrail = MotionTrailBuilder.ensure(localRoot, accent)
        local remoteTrail = MotionTrailBuilder.ensure(remoteRoot, accent)
        localTrail.Enabled, remoteTrail.Enabled = true, true
        local tracked = {
            [localModel] = {root = localRoot, trail = localTrail,
                appliedTier = "High", eligible = true},
            [remoteModel] = {root = remoteRoot, trail = remoteTrail,
                appliedTier = "High", eligible = true},
        }
        local disabled = rules.suspendOwned(
            tracked, localModel, MotionTrailBuilder.release)
        expect(disabled).toBe(2)
        expect(localTrail.Parent).toBe(localRoot)
        expect(localTrail.Enabled).toBe(false)
        expect(tracked[localModel].eligible).toBe(false)
        expect(remoteTrail.Parent == nil).toBe(true)
        expect(remoteRoot:FindFirstChild("ChaosMotionTrailLeft") == nil)
            .toBe(true)
        expect(remoteRoot:FindFirstChild("ChaosMotionTrailRight") == nil)
            .toBe(true)
        expect(tracked[remoteModel].trail == nil).toBe(true)
        expect(tracked[remoteModel].appliedTier == nil).toBe(true)
        expect(tracked[remoteModel].eligible).toBe(false)
        expect(rules.suspendOwned(tracked, localModel, MotionTrailBuilder.release))
            .toBe(1)
        expect(rules.suspendOwned(nil, localModel, MotionTrailBuilder.release))
            .toBe(0)
        localModel:Destroy()
        remoteModel:Destroy()
    end)

    it("reduces idle human ribbon work without slowing active Medium and High", function()
        local rules = require("../../src/shared/CharacterMotionTrailRules")
        expect(rules.updateInterval("High", "round", false, false)).toBe(1 / 30)
        expect(rules.updateInterval("Medium", "round", false, false)).toBe(1 / 24)
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            for _, phase in ipairs({"waiting", "ready", "result"}) do
                expect(rules.updateInterval(tier, phase, false, false)).toBe(0.12)
            end
            expect(rules.updateInterval(tier, "round", true, false)).toBe(0.12)
            expect(rules.updateInterval(tier, "round", false, true)).toBe(0.12)
        end
        expect(rules.updateInterval("Unknown", "round", false, false)).toBe(0.12)
        expect(rules.updateInterval(nil, "round", false, false)).toBe(0.12)
        expect(rules.updateInterval("High", nil, false, false)).toBe(0.12)
        expect(rules.suspended("round", false, "High", false)).toBe(false)
        expect(rules.suspended("round", false, "Medium", false)).toBe(false)
        expect(rules.suspended("ready", false, "High", false)).toBe(true)
        expect(rules.suspended("round", true, "High", false)).toBe(true)
        expect(rules.suspended("round", false, "Low", false)).toBe(true)
        expect(rules.suspended("round", false, "High", true)).toBe(true)
        expect(rules.suspended("round", false, "Unknown", false)).toBe(true)
    end)

    it("selects bounded nearest human motion trails without full sorting", function()
        local rules = require("../../src/shared/CharacterMotionTrailRules")
        local function person(id, distance, active)
            return {order = id, distance = distance,
                trail = {Enabled = active == true}}
        end
        local distant = person(10, 80)
        local retained = person(2, 21, true) -- effective distance: 18
        local equalLate = person(5, 18)
        local equalEarly = person(1, 18)
        local closest = person(9, 2)
        local third = person(8, 11)
        local others = person(7, 37)
        local candidates = {distant, equalLate, retained, others,
            equalEarly, closest, third}
        local selected = {[distant] = true}
        expect(rules.selectRemote(candidates, "Low", selected)).toBe(selected)
        expect(next(selected) == nil).toBe(true)

        expect(rules.selectRemote(candidates, "Medium", selected)).toBe(selected)
        expect(selected[closest]).toBe(true)
        expect(selected[third]).toBe(true)
        expect(selected[equalEarly]).toBe(true)
        expect(selected[retained]).toBe(true)
        expect(selected[equalLate] == true).toBe(false)
        expect(selected[distant] == true).toBe(false)
        local count = 0
        for _ in pairs(selected) do count += 1 end
        expect(count).toBe(4)
        expect(rules.remoteBudget("Medium")).toBe(4)
        expect(rules.remoteBudget("High")).toBe(8)
        expect(rules.remoteBudget("Low")).toBe(0)

        local many = {}
        for n = 16, 1, -1 do
            many[#many + 1] = person(n, n * 4)
        end
        many[#many + 1] = person(30, math.huge)
        many[#many + 1] = person(31, 0/0)
        rules.selectRemote(many, "High", selected)
        for _, state in ipairs(many) do
            expect(selected[state] == true).toBe(state.order <= 8)
        end
        local small = {person(4, 8), person(3, 2)}
        rules.selectRemote(small, "High", selected)
        expect(selected[small[1]]).toBe(true)
        expect(selected[small[2]]).toBe(true)
        count = 0
        for _ in pairs(selected) do count += 1 end
        expect(count).toBe(2)
    end)

    it("bounds allocated human ribbons and leaves foreign attachments intact", function()
        local rules = require("../../src/shared/CharacterMotionTrailRules")
        local folder = Instance.new("Folder")
        local crowd, selected = {}, {}
        for i = 1, 12 do
            local root = Instance.new("Part")
            root.Name = "HumanoidRootPart"
            root.Parent = folder
            local foreign = Instance.new("Attachment")
            foreign.Name = "ForeignAttachment"
            foreign.Parent = root
            crowd[i] = {root = root, foreign = foreign,
                distance = i * 4, order = i}
        end
        local function update(tier, reverse)
            for i, state in ipairs(crowd) do
                state.distance = (reverse and (13 - i) or i) * 4
            end
            rules.selectRemote(crowd, tier, selected)
            local allocated = 0
            for _, state in ipairs(crowd) do
                if selected[state] then
                    if not state.trail then
                        state.trail = MotionTrailBuilder.ensure(state.root,
                            Color3.fromRGB(80, 180, 255))
                    end
                elseif state.trail then
                    expect(MotionTrailBuilder.release(state.root, state.trail)).toBe(true)
                    state.trail = nil
                end
                if state.trail then allocated += 1 end
                expect(state.foreign.Parent).toBe(state.root)
            end
            expect(allocated <= rules.remoteBudget(tier)).toBe(true)
            return allocated
        end
        expect(update("High", false)).toBe(8)
        expect(update("High", true)).toBe(8)
        expect(update("Medium", true)).toBe(4)
        expect(update("Low", true)).toBe(0)
        local unrelated = Instance.new("Trail")
        unrelated.Name = "UnrelatedEffect"
        unrelated.Parent = crowd[1].root
        expect(MotionTrailBuilder.release(crowd[1].root, unrelated)).toBe(false)
        expect(unrelated.Parent).toBe(crowd[1].root)
        for _, state in ipairs(crowd) do
            expect(state.root:FindFirstChild("ChaosMotionTrail") == nil).toBe(true)
            expect(state.root:FindFirstChild("ChaosMotionTrailLeft") == nil).toBe(true)
            expect(state.root:FindFirstChild("ChaosMotionTrailRight") == nil).toBe(true)
        end
        folder:Destroy()
    end)

    it("shares stable camera-frustum limits for AI and human optional trails", function()
        local Viewport = require("../../src/shared/VisualViewportRules")
        local Humans = require("../../src/shared/CharacterMotionTrailRules")
        expect(Humans.visible("round", false, false, 1,
            "High", false, 30)).toBe(true)
        expect(Viewport.contains(960, 540, 10, 1920, 1080, false)).toBe(true)
        expect(Viewport.contains(-190, 540, 10, 1920, 1080, false)).toBe(true)
        expect(Viewport.contains(-200, 540, 10, 1920, 1080, false)).toBe(false)
        expect(Viewport.contains(-300, 540, 10, 1920, 1080, true)).toBe(true)
        expect(Viewport.contains(-350, 540, 10, 1920, 1080, true)).toBe(false)
        expect(Viewport.contains(2100, 540, 10, 1920, 1080, false)).toBe(true)
        expect(Viewport.contains(2150, 540, 10, 1920, 1080, false)).toBe(false)
        expect(Viewport.contains(960, -120, 10, 1920, 1080, false)).toBe(false)
        expect(Viewport.contains(960, 540, -1, 1920, 1080, true)).toBe(false)
        expect(Viewport.contains(960, 540, 0, 1920, 1080, true)).toBe(false)
        expect(Viewport.contains(960, 540, 10, 0, 0, false)).toBe(true)
        expect(Viewport.contains(960, 540, 10, nil, nil, false)).toBe(true)
        -- Projection is an additional cull; tier and distance gates still win.
        expect(BotMotionPresentationRules.trailVisible(
            "Low", false, "round", true, 1, 2, true)).toBe(false)
        expect(BotMotionPresentationRules.trailVisible(
            "High", true, "round", true, 1, 2, true)).toBe(false)
        expect(BotMotionPresentationRules.trailVisible(
            "High", false, "round", true, 1, 120, true)).toBe(false)
    end)

    it("sculpts three short-lived AI trail gestures without extra instances", function()
        local rules = BotMotionPresentationRules
        local launch = rules.trailGesture("High", "Launch")
        local skid = rules.trailGesture("High", "Skid")
        local pivot = rules.trailGesture("High", "Pivot")
        expect(launch ~= nil and skid ~= nil and pivot ~= nil).toBe(true)
        expect(launch.Peak < pivot.Peak and pivot.Peak < skid.Peak).toBe(true)
        expect(launch.Width < pivot.Width and pivot.Width < skid.Width)
            .toBe(true)
        expect(launch.DurationScale > pivot.DurationScale
            and pivot.DurationScale > skid.DurationScale).toBe(true)
        for _, tier in ipairs({"High", "Medium"}) do
            for _, kind in ipairs({"Launch", "Skid", "Pivot"}) do
                local design = rules.trailGesture(tier, kind)
                expect(design.Width > 0 and design.Width <= 0.32).toBe(true)
                expect(design.Emission >= 0 and design.Emission <= 0.75).toBe(true)
                expect(design.Peak > 0 and design.Peak < 1).toBe(true)
                expect(design.DurationScale > 0 and design.DurationScale <= 1.08)
                    .toBe(true)
            end
        end
        expect(rules.trailGesture("Low", "Skid") == nil).toBe(true)
        expect(rules.trailGesture("High", "Unknown") == nil).toBe(true)
        expect(rules.trailGesture("Medium", nil) == nil).toBe(true)
        local root = Instance.new("Part")
        local trail = Instance.new("Trail")
        trail.Parent = root
        local originalWidth = trail.WidthScale
        local originalEmission = trail.LightEmission
        local originalLifetime = trail.Lifetime
        for _, kind in ipairs({"Launch", "Skid", "Pivot"}) do
            local gesture = rules.trailGesture("High", kind)
            trail.WidthScale = NumberSequence.new({
                NumberSequenceKeypoint.new(0, gesture.Width * 0.30),
                NumberSequenceKeypoint.new(gesture.Peak, gesture.Width),
                NumberSequenceKeypoint.new(1, 0),
            })
            trail.LightEmission = gesture.Emission
            trail.Lifetime = 0.114 * gesture.DurationScale
            expect(math.abs(trail.WidthScale.Keypoints[2].Value
                - gesture.Width) < 0.0001).toBe(true)
            expect(math.abs(trail.Lifetime - 0.114 * gesture.DurationScale)
                < 0.0001).toBe(true)
            expect(#root:GetChildren()).toBe(1)
        end
        trail.WidthScale = originalWidth
        trail.LightEmission = originalEmission
        trail.Lifetime = originalLifetime
        expect(trail.WidthScale).toBe(originalWidth)
        expect(trail.LightEmission).toBe(originalEmission)
        expect(trail.Lifetime).toBe(originalLifetime)
        root:Destroy()
    end)

    it("rejects nonfinite AI movement inputs before making any visual cue", function()
        local r = BotMotionPresentationRules
        local normal = Vector3.new(17, 0, 0)
        local before = Vector3.new(3, 0, 0)
        for _, bad in ipairs({0/0, math.huge, -math.huge}) do
            expect(r.trailVisible("High", false, "round", true,
                bad, 5, true)).toBe(false)
            expect(r.trailVisible("High", false, "round", true,
                1, bad, true)).toBe(false)
            expect(r.cue(Vector3.new(bad, 0, 0), before, 0.08,
                true, "High", false, "round", 5, LocomotionDynamics)
                == nil).toBe(true)
            expect(r.cue(normal, before, bad,
                true, "High", false, "round", 5, LocomotionDynamics)
                == nil).toBe(true)
            expect(r.cue(normal, before, 0.08,
                true, "High", false, "round", bad, LocomotionDynamics)
                == nil).toBe(true)
        end
        expect(r.cue(normal, before, 0.08, true, "High", false,
            "round", -1, LocomotionDynamics) == nil).toBe(true)
    end)

    it("creates only nearby, meaningful AI launch, skid and pivot cues", function()
        local rules = {
            profile = BotMotionPresentationRules.profile,
            trailAccent = BotMotionPresentationRules.trailAccent,
            cue = function(v, before, dt, grounded, tier, reduced, phase, distance)
                return BotMotionPresentationRules.cue(
                    v, before, dt, grounded, tier, reduced, phase, distance,
                    LocomotionDynamics
                )
            end,
        }
        expect(rules.profile("Low", false).MaxPerScan).toBe(0)
        expect(rules.profile("Medium", false).Range).toBe(54)
        expect(rules.profile("High", false).Range).toBe(78)
        expect(rules.profile("High", true).MaxPerScan).toBe(0)
        expect(rules.profile("High", false).Cooldown > 1).toBe(true)
        expect(rules.trailAccent("Launch")).toBe(Color3.fromRGB(83, 222, 255))
        expect(rules.trailAccent("Skid")).toBe(Color3.fromRGB(255, 156, 83))
        expect(rules.trailAccent("Pivot")).toBe(Color3.fromRGB(187, 105, 255))
        expect(rules.trailAccent("Unknown") == nil).toBe(true)

        local launch, launchStrength = rules.cue(
            Vector3.new(17, 0, 0), Vector3.new(3, 0, 0),
            0.08, true, "High", false, "round", 10
        )
        expect(launch).toBe("Launch")
        expect(launchStrength > 0.78).toBe(true)
        local skid, skidStrength = rules.cue(
            Vector3.new(3, 0, 0), Vector3.new(18, 0, 0),
            0.08, true, "High", false, "round", 10
        )
        expect(skid).toBe("Skid")
        expect(skidStrength > 0.78).toBe(true)
        local pivot, pivotStrength = rules.cue(
            Vector3.new(-17, 0, 0), Vector3.new(17, 0, 0),
            0.08, true, "High", false, "round", 10
        )
        expect(pivot).toBe("Pivot")
        expect(pivotStrength > 0.78).toBe(true)
        for _, scenario in ipairs({
            {true, "Low", false, "round", 10},
            {true, "High", true, "round", 10},
            {true, "High", false, "ready", 10},
            {true, "High", false, "round", 110},
            {false, "High", false, "round", 10},
        }) do
            local inactive = rules.cue(
                Vector3.new(17, 0, 0), Vector3.new(3, 0, 0),
                0.08, scenario[1], scenario[2], scenario[3],
                scenario[4], scenario[5]
            )
            expect(inactive == nil).toBe(true)
        end
        expect(rules.cue(nil, Vector3.zero, 0.08, true,
            "High", false, "round", 10) == nil).toBe(true)
        expect(rules.cue(Vector3.zero, Vector3.zero, 0,
            true, "High", false, "round", 10) == nil).toBe(true)
        expect(rules.cue(Vector3.new(3, 0, 0), Vector3.new(3, 0, 0),
            0.08, true, "High", false, "round", 10) == nil).toBe(true)
    end)
end)

return nil
