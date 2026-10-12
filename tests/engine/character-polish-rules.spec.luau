--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local CharacterPolishRules = require("../../src/shared/CharacterPolishRules")
local TrailRules = require("../../src/shared/CharacterMotionTrailRules")
local PolishRegistry = require("../../src/client/CharacterPolishRegistry")
local ViewportRules = require("../../src/shared/VisualViewportRules")

describe("Character polish rules", function()
    it("keeps the local player more readable than remote characters", function()
        local localOutline = CharacterPolishRules.outlineTransparency(
            "High",
            "round",
            true,
            false,
            false
        )
        local remoteOutline = CharacterPolishRules.outlineTransparency(
            "High",
            "round",
            false,
            false,
            false
        )
        expect(localOutline < remoteOutline).toBe(true)
    end)

    it("keeps ai silhouettes subtler than the local player", function()
        local localOutline = CharacterPolishRules.outlineTransparency(
            "Medium",
            "ready",
            true,
            false,
            false
        )
        local aiOutline = CharacterPolishRules.outlineTransparency(
            "Medium",
            "ready",
            false,
            true,
            false
        )
        expect(localOutline < aiOutline).toBe(true)
    end)

    it("disables fill and most extra lighting on low quality", function()
        expect(CharacterPolishRules.fillTransparency(
            "Low",
            "round",
            true,
            false
        )).toBe(1)
        expect(CharacterPolishRules.lightBrightness(
            "Low",
            "round",
            true,
            false
        )).toBe(0)
    end)

    it("reduces trail persistence for accessibility and final rush", function()
        local normal = CharacterPolishRules.trailLifetime("High", false, false)
        local reduced = CharacterPolishRules.trailLifetime("High", true, false)
        local rush = CharacterPolishRules.trailLifetime("High", false, true)

        expect(reduced < normal).toBe(true)
        expect(rush < normal).toBe(true)
        expect(rush <= 0.13).toBe(true)
    end)

    it("attenuates spectators and eliminated players during the round", function()
        local active = CharacterPolishRules.outlineTransparency(
            "High",
            "round",
            false,
            false,
            false,
            true
        )
        local inactive = CharacterPolishRules.outlineTransparency(
            "High",
            "round",
            false,
            false,
            false,
            false
        )

        expect(inactive > active).toBe(true)
        expect(inactive >= 0.94).toBe(true)
        expect(CharacterPolishRules.lightBrightness(
            "High",
            "round",
            false,
            false,
            false
        )).toBe(0)
    end)

    it("does not allocate light during Low or ReduceMotion even on High", function()
        local bright = CharacterPolishRules.lightBrightness
        expect(bright("High", "round", true, false, true, false) > 0).toBe(true)
        expect(bright("High", "round", true, false, true, true)).toBe(0)
        expect(bright("Medium", "round", true, false, true, true)).toBe(0)
        expect(bright("Low", "round", true, false, true, false)).toBe(0)
        expect(bright("High", "waiting", true, false, true, false)).toBe(0)
        expect(bright("High", "result", true, false, true, false)).toBe(0)
    end)

    it("suppresses extra character lighting during final rush", function()
        expect(CharacterPolishRules.lightBrightness(
            "High",
            "round",
            true,
            true
        )).toBe(0)
    end)
end)


describe("Client avatar light allocation and rig handoff", function()
    local LightKit = require("../../src/client/CharacterPolishLightKit")

    it("reuses one optional PointLight, then disables it with Low or ReduceMotion", function()
        local model = Instance.new("Model")
        model.Parent = workspace
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Parent = model
        local accent = Color3.fromRGB(90, 180, 245)
        local bright = CharacterPolishRules.lightBrightness(
            "High", "round", true, false, true, false
        )
        expect(LightKit.apply(model, 0, accent, true)).toBe(nil)
        expect(#root:GetChildren()).toBe(0)
        local first = LightKit.apply(model, bright, accent, true)
        expect(first ~= nil and first:IsA("PointLight")).toBe(true)
        expect(first.Enabled).toBe(true)
        expect(first.Range).toBe(8)
        expect(#root:GetChildren()).toBe(1)
        expect(LightKit.apply(model, bright, accent, true)).toBe(first)
        expect(first.Enabled).toBe(true)
        expect(#root:GetChildren()).toBe(1)

        local torso = Instance.new("Part")
        torso.Name = "UpperTorso"
        torso.Parent = model
        local selected = LightKit.apply(model, bright, accent, true)
        expect(selected).toBe(first)
        expect(selected.Parent).toBe(torso)
        expect(selected.Enabled).toBe(true)
        expect(#root:GetChildren()).toBe(0)
        expect(LightKit.apply(model, bright, accent, true)).toBe(selected)
        expect(#torso:GetChildren()).toBe(1)

        local reduced = CharacterPolishRules.lightBrightness(
            "High", "round", true, false, true, true
        )
        expect(reduced).toBe(0)
        expect(LightKit.apply(model, reduced, accent, true)).toBe(nil)
        expect(selected.Enabled).toBe(false)
        expect(#torso:GetChildren()).toBe(1)
        local otherAccent = Color3.fromRGB(255, 120, 80)
        expect(LightKit.apply(model, bright, otherAccent, false)).toBe(selected)
        expect(selected.Enabled).toBe(true)
        expect(selected.Range).toBe(6)
        expect((Vector3.new(selected.Color.R, selected.Color.G, selected.Color.B)
            - Vector3.new(otherAccent.R, otherAccent.G, otherAccent.B)).Magnitude
            < 0.01).toBe(true)
        expect(#torso:GetChildren()).toBe(1)

        torso.Parent = nil
        local fallback = LightKit.apply(model, bright, accent, true)
        expect(fallback ~= nil and fallback ~= selected).toBe(true)
        expect(fallback.Parent).toBe(root)
        expect(fallback.Enabled).toBe(true)
        expect(#root:GetChildren()).toBe(1)
        expect(LightKit.apply(model, math.huge, accent, true)).toBe(nil)
        expect(fallback.Enabled).toBe(false)
        model:Destroy()
        torso:Destroy()
    end)
    it("reuses a torso light and removes orphan duplicates on tier refresh", function()
        local model = Instance.new("Model")
        model.Parent = workspace
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Parent = model
        local torso = Instance.new("Part")
        torso.Name = "UpperTorso"
        torso.Parent = model
        local accent = Color3.fromRGB(120, 190, 255)
        local a = Instance.new("PointLight")
        a.Name = "ChaosCharacterPolishLight"
        a.Parent = root
        local b = Instance.new("PointLight")
        b.Name = "ChaosCharacterPolishLight"
        b.Parent = torso
        local c = Instance.new("PointLight")
        c.Name = "ChaosCharacterPolishLight"
        c.Parent = root
        expect(LightKit.apply(model, 0.42, accent, true)).toBe(b)
        expect(a.Parent).toBe(nil)
        expect(c.Parent).toBe(nil)
        expect(#root:GetChildren()).toBe(0)
        expect(#torso:GetChildren()).toBe(1)
        expect(b.Enabled).toBe(true)
        expect(LightKit.apply(model, 0, accent, true)).toBe(nil)
        expect(b.Enabled).toBe(false)
        expect(#torso:GetChildren()).toBe(1)
        expect(LightKit.apply(model, 0.22, accent, false)).toBe(b)
        expect(#torso:GetChildren()).toBe(1)
        expect(b.Range).toBe(6)
        model:Destroy()
    end)

    it("consolidates dormant duplicate lights without allocating on Low", function()
        local model = Instance.new("Model")
        model.Parent = workspace
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Parent = model
        for _ = 1, 3 do
            local light = Instance.new("PointLight")
            light.Name = "ChaosCharacterPolishLight"
            light.Parent = root
        end
        expect(LightKit.apply(model, 0, Color3.new(1, 1, 1), true))
            .toBe(nil)
        expect(#root:GetChildren()).toBe(1)
        expect(root:GetChildren()[1].Enabled).toBe(false)
        model:Destroy()
    end)
end)

describe("Human momentum ribbon GPU and accessibility policy", function()
    it("never renders contestant momentum on spectators or eliminated avatars", function()
        local r = TrailRules
        expect(r.humanEligible(true, false)).toBe(true)
        expect(r.humanEligible(true, nil)).toBe(true)
        expect(r.humanEligible(false, false)).toBe(false)
        expect(r.humanEligible(nil, false)).toBe(false)
        expect(r.humanEligible(true, true)).toBe(false)
    end)
    it("culls by tier and camera distance, including ReduceMotion", function()
        local r = TrailRules
        expect(r.visible("round", false, false, 1, "High", false, 90)).toBe(true)
        expect(r.visible("round", false, false, 1, "High", false, 90.1)).toBe(false)
        expect(r.visible("round", false, false, 1, "Medium", false, 60)).toBe(true)
        expect(r.visible("round", false, false, 1, "Medium", false, 61)).toBe(false)
        expect(r.visible("round", false, false, 1, "Low", false, 0)).toBe(false)
        expect(r.visible("round", false, false, 1, "High", true, 0)).toBe(false)
        expect(r.visible("round", false, false, 1, "Unknown", false, 0)).toBe(false)
        expect(r.visible("round", false, false, 1, "High", false, nil)).toBe(false)
    end)
    it("stabilizes sprint and camera cutoff without overriding accessibility", function()
        local r = TrailRules
        expect(r.visible("round", false, false, 0.80, "High", false, 92, true)).toBe(true)
        expect(r.visible("round", false, false, 0.80, "High", false, 92, false)).toBe(false)
        expect(r.visible("round", false, false, 0.76, "High", false, 0, true)).toBe(false)
        expect(r.visible("round", false, false, 1, "Medium", false, 62, true)).toBe(true)
        expect(r.visible("round", false, false, 1, "Medium", false, 63.1, true)).toBe(false)
        expect(r.visible("round", false, false, 1, "High", true, 0, true)).toBe(false)
        expect(r.visible("round", true, false, 1, "High", false, 0, true)).toBe(false)
        expect(r.visible("round", false, true, 1, "High", false, 0, true)).toBe(false)
        expect(r.visible("round", false, false, 1, "Low", false, 0, true)).toBe(false)
    end)
    it("rejects off-screen remote ribbons with hysteresis margins", function()
        local r = TrailRules
        expect(ViewportRules.contains(960, 540, 10, 1920, 1080, false)).toBe(true)
        expect(ViewportRules.contains(-190, 540, 10, 1920, 1080, false)).toBe(true)
        expect(ViewportRules.contains(-200, 540, 10, 1920, 1080, false)).toBe(false)
        expect(ViewportRules.contains(-300, 540, 10, 1920, 1080, true)).toBe(true)
        expect(ViewportRules.contains(-350, 540, 10, 1920, 1080, true)).toBe(false)
        expect(ViewportRules.contains(2150, 540, 10, 1920, 1080, false)).toBe(false)
        expect(ViewportRules.contains(960, -120, 10, 1920, 1080, false)).toBe(false)
        expect(ViewportRules.contains(960, 540, -1, 1920, 1080, true)).toBe(false)
        expect(ViewportRules.contains(960, 540, 0, 1920, 1080, true)).toBe(false)
        -- Camera viewport may briefly be zero-sized during device init.
        expect(ViewportRules.contains(960, 540, 10, 0, 0, false)).toBe(true)
        expect(ViewportRules.contains(960, 540, 10, nil, nil, false)).toBe(true)
    end)

    it("suppresses airborne, idle, pre-round and final rush ribbons", function()
        local r = TrailRules
        expect(r.visible("ready", false, false, 1, "High", false, 0)).toBe(false)
        expect(r.visible("round", true, false, 1, "High", false, 0)).toBe(false)
        expect(r.visible("round", false, true, 1, "High", false, 0)).toBe(false)
        expect(r.visible("round", false, false, 0.82, "High", false, 0)).toBe(false)
        expect(r.visible("round", false, false, 0.83, "High", false, 0)).toBe(true)
        local highLife, highWidth = r.style("High")
        local medLife, medWidth = r.style("Medium")
        local lowLife, lowWidth = r.style("Low")
        expect(highLife > medLife and medLife > lowLife).toBe(true)
        expect(highWidth > medWidth and medWidth > lowWidth).toBe(true)
        expect(highLife <= 0.14 and highWidth <= 0.34).toBe(true)
        expect(lowLife).toBe(0)
        expect(lowWidth).toBe(0)
    end)
    it("adds hysteretic Flow Drive Surge ribbon silhouettes within mobile budgets", function()
        local r = TrailRules
        expect(r.momentumBand(0.86, nil)).toBe("Flow")
        expect(r.momentumBand(0.97, nil)).toBe("Drive")
        expect(r.momentumBand(1.12, nil)).toBe("Surge")
        expect(r.momentumBand(0.93, "Drive")).toBe("Drive")
        expect(r.momentumBand(0.89, "Drive")).toBe("Flow")
        expect(r.momentumBand(1.06, "Surge")).toBe("Surge")
        expect(r.momentumBand(1.03, "Surge")).toBe("Drive")
        for _, bad in ipairs({-1, 0/0, math.huge, -math.huge}) do
            expect(r.momentumBand(bad, "Surge")).toBe("Flow")
        end
        for _, tier in ipairs({"Medium", "High"}) do
            local flow = r.momentumStyle(tier, "Flow")
            local drive = r.momentumStyle(tier, "Drive")
            local surge = r.momentumStyle(tier, "Surge")
            expect(flow.Width < drive.Width and drive.Width < surge.Width).toBe(true)
            expect(flow.Lifetime < drive.Lifetime
                and drive.Lifetime < surge.Lifetime).toBe(true)
            expect(flow.Opacity > drive.Opacity and drive.Opacity > surge.Opacity).toBe(true)
            expect(flow.Peak < drive.Peak and drive.Peak < surge.Peak).toBe(true)
            expect(surge.Lifetime <= 0.15).toBe(true)
            expect(surge.Width <= 0.37).toBe(true)
            expect(surge.Emission <= 0.82).toBe(true)
            expect(r.momentumStyle(tier, "unknown").Width).toBe(flow.Width)
        end
        expect(r.momentumStyle("Low", "Surge").Width).toBe(0)
        expect(r.momentumStyle("Unknown", "Drive").Lifetime).toBe(0)
        expect(r.visible("round", false, false, 1.2, "High", true, 5)).toBe(false)
    end)

    it("caps remote human ribbons with nearest-first and stable selection", function()
        local r = TrailRules
        expect(r.remoteBudget("Low")).toBe(0)
        expect(r.remoteBudget("Medium")).toBe(4)
        expect(r.remoteBudget("High")).toBe(8)
        expect(r.remoteBudget("Unknown")).toBe(0)

        local candidates = {}
        for i = 1, 10 do
            candidates[i] = {order = i, distance = i * 5, trail = {Enabled = false}}
        end
        local selected = {}
        r.selectRemote(candidates, "Medium", selected)
        local count = 0
        for _, state in ipairs(candidates) do
            if selected[state] then count += 1 end
        end
        expect(count).toBe(4)
        expect(selected[candidates[1]]).toBe(true)
        expect(selected[candidates[5]]).toBe(nil)

        r.selectRemote(candidates, "High", selected)
        count = 0
        for _, state in ipairs(candidates) do
            if selected[state] then count += 1 end
        end
        expect(count).toBe(8)
        r.selectRemote(candidates, "Low", selected)
        expect(next(selected)).toBe(nil)
    end)

    it("keeps active remote trails stable within a three-stud tie window", function()
        local active = {order = 2, distance = 21, trail = {Enabled = true}}
        local newcomer = {order = 1, distance = 19, trail = {Enabled = false}}
        local tie = {order = 3, distance = 19, trail = {Enabled = false}}
        local candidates = {newcomer, tie, active}
        local selected = {}
        TrailRules.selectRemote(candidates, "Medium", selected)
        expect(candidates[1]).toBe(active)
        expect(candidates[2]).toBe(newcomer)
        expect(candidates[3]).toBe(tie)
        expect(selected[active]).toBe(true)
    end)

end)

describe("Human ribbon attachment lifecycle", function()
    local Builder = require("../../src/client/CharacterMotionTrailBuilder")

    it("restyles the existing human Trail without altering color or attachment count", function()
        local root = Instance.new("Part")
        local trail = Builder.ensure(root, Color3.fromRGB(80, 170, 255))
        local accent = trail.Color.Keypoints[1].Value
        local previousWidth = 0
        for _, band in ipairs({"Flow", "Drive", "Surge"}) do
            local style = TrailRules.momentumStyle("High", band)
            expect(Builder.applyMomentumStyle(trail, style)).toBe(true)
            expect(math.abs(trail.Lifetime - style.Lifetime) < 0.0001).toBe(true)
            expect(math.abs(trail.WidthScale.Keypoints[2].Value - style.Width)
                < 0.0001).toBe(true)
            expect(math.abs(trail.WidthScale.Keypoints[2].Time - style.Peak)
                < 0.0001).toBe(true)
            expect(math.abs(trail.LightEmission - style.Emission) < 0.0001)
                .toBe(true)
            expect(style.Width > previousWidth).toBe(true)
            previousWidth = style.Width
            expect(trail.Color.Keypoints[1].Value).toBe(accent)
            expect(#root:GetChildren()).toBe(3)
        end
        expect(Builder.applyMomentumStyle(nil,
            TrailRules.momentumStyle("High", "Flow"))).toBe(false)
        expect(Builder.applyMomentumStyle(trail, nil)).toBe(false)
        root:Destroy()
    end)

    it("reuses a single trail and its attachments across repeated ensure calls", function()
        local root = Instance.new("Part")
        local accent = Color3.fromRGB(90, 190, 255)
        local trail = Builder.ensure(root, accent)
        expect(Builder.ensure(root, accent)).toBe(trail)
        local attachments, trails = 0, 0
        for _, child in ipairs(root:GetChildren()) do
            if child:IsA("Attachment") then attachments += 1 end
            if child:IsA("Trail") then trails += 1 end
        end
        expect(attachments).toBe(2)
        expect(trails).toBe(1)
        expect(trail.Enabled).toBe(false)
        root:Destroy()
    end)

    it("recolors the same ribbon after an accent change without extra instances", function()
        local root = Instance.new("Part")
        local blue = Color3.fromRGB(90, 190, 255)
        local orange = Color3.fromRGB(255, 125, 80)
        local trail = Builder.ensure(root, blue)
        expect(trail.Color.Keypoints[1].Value).toBe(blue)
        expect(Builder.setAccent(trail, orange)).toBe(true)
        expect(trail.Color.Keypoints[1].Value).toBe(orange)
        expect(Builder.ensure(root, blue)).toBe(trail)
        expect(trail.Color.Keypoints[1].Value).toBe(blue)
        expect(#root:GetChildren()).toBe(3)
        root:Destroy()
    end)

    it("rebuilds a deleted trail without multiplying attachments", function()
        local root = Instance.new("Part")
        local accent = Color3.fromRGB(90, 190, 255)
        local first = Builder.ensure(root, accent)
        local left, right = first.Attachment0, first.Attachment1
        first:Destroy()
        local rebuilt = Builder.ensure(root, accent)
        expect(rebuilt ~= first).toBe(true)
        expect(rebuilt.Attachment0).toBe(left)
        expect(rebuilt.Attachment1).toBe(right)
        expect(#root:GetChildren()).toBe(3)
        root:Destroy()
    end)

    it("repairs an orphaned attachment on the existing trail", function()
        local root = Instance.new("Part")
        local accent = Color3.fromRGB(90, 190, 255)
        local trail = Builder.ensure(root, accent)
        expect(Builder.isIntact(trail, root)).toBe(true)
        local missing = trail.Attachment0
        local right = trail.Attachment1
        missing:Destroy()
        expect(Builder.isIntact(trail, root)).toBe(false)
        expect(Builder.ensure(root, accent)).toBe(trail)
        expect(Builder.isIntact(trail, root)).toBe(true)
        expect(trail.Attachment0 ~= missing).toBe(true)
        expect(trail.Attachment0.Parent).toBe(root)
        expect(trail.Attachment1).toBe(right)
        expect(#root:GetChildren()).toBe(3)
        root:Destroy()
    end)
end)

describe("Character polish lifecycle and late streaming", function()
    it("deduplicates model listeners and releases them when bots leave", function()
        local calls, stopped = 0, 0
        local registry = PolishRegistry.new(function()
            calls += 1
        end, function()
            stopped += 1
        end)
        local model = Instance.new("Model")
        model.Parent = workspace
        expect(registry.watch(model)).toBe(true)
        expect(registry.watch(model)).toBe(false)
        expect(registry.count()).toBe(1)
        local before = calls
        model:SetAttribute("ChaosAccent", Color3.fromRGB(70, 190, 255))
        expect(calls).toBe(before + 1)
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = model
        expect(calls > before + 1).toBe(true)
        registry.stop(model)
        expect(registry.count()).toBe(0)
        expect(stopped).toBe(1)
        local afterStop = calls
        model:SetAttribute("AISurvivor", true)
        expect(calls).toBe(afterStop)
        expect(registry.watch(model)).toBe(true)
        model.Parent = nil
        expect(registry.count()).toBe(0)
        expect(stopped).toBe(2)
        model:Destroy()
    end)

    it("refreshes bound models without extra listeners through rig streaming", function()
        local updates = 0
        local registry = PolishRegistry.new(function()
            updates += 1
        end)
        local model = Instance.new("Model")
        model.Parent = workspace
        registry.watch(model)
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Parent = model
        expect(registry.count()).toBe(1)
        local withRoot = updates
        root.Parent = nil
        expect(updates > withRoot).toBe(true)
        local replacement = Instance.new("Part")
        replacement.Name = "HumanoidRootPart"
        replacement.Parent = model
        expect(updates > withRoot + 1).toBe(true)
        local beforeRefresh = updates
        registry.refreshAll()
        expect(updates).toBe(beforeRefresh + 1)
        registry.stop(model)
        model:Destroy()
        root:Destroy()
    end)

    it("reacts to solo bot injury, defeat and rig streaming without polling", function()
        local updates, stopped = 0, 0
        local registry = PolishRegistry.new(function()
            updates += 1
        end, function()
            stopped += 1
        end)
        local model = Instance.new("Model")
        model.Parent = workspace
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = model
        expect(registry.watch(model)).toBe(true)
        local humanCount = updates
        humanoid.Health = 80
        task.wait()
        expect(updates).toBe(humanCount) -- human damage isn't cosmetic AI work

        model:SetAttribute("AISurvivor", true)
        local activated = updates
        humanoid.Health = 25
        task.wait()
        expect(updates > activated).toBe(true)
        local injured = updates
        humanoid.Health = 0
        task.wait()
        expect(updates > injured).toBe(true)

        humanoid.Parent = nil
        local detached = updates
        humanoid.Health = 50
        task.wait()
        expect(updates).toBe(detached)
        local replacement = Instance.new("Humanoid")
        replacement.Parent = model
        local resynced = updates
        replacement.Health = 30
        task.wait()
        expect(updates > resynced).toBe(true)

        model:SetAttribute("AISurvivor", false)
        local noLongerBot = updates
        replacement.Health = 10
        task.wait()
        expect(updates).toBe(noLongerBot)
        model:SetAttribute("AISurvivor", true)
        registry.stop(model)
        local afterStop = updates
        replacement.Health = 5
        task.wait()
        expect(updates).toBe(afterStop)
        expect(stopped).toBe(1)
        expect(registry.count()).toBe(0)
        model:Destroy()
        humanoid:Destroy()
    end)
end)

return nil
