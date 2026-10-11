--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local CharacterPolishRules = require("../../src/shared/CharacterPolishRules")
local TrailRules = require("../../src/shared/CharacterMotionTrailRules")
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

    it("suppresses extra character lighting during final rush", function()
        expect(CharacterPolishRules.lightBrightness(
            "High",
            "round",
            true,
            true
        )).toBe(0)
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

return nil
