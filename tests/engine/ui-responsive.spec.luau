--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local UIResponsive = require("../../src/shared/UIResponsive")
local NearMissVisualRules = require("../../src/shared/NearMissVisualRules")
local BotNameplateRules = require("../../src/shared/BotNameplateRules")
local CameraOcclusionRules = require("../../src/shared/CameraOcclusionRules")

describe("UI responsive profiles", function()
    it("softens only near avatars actually obstructing the local Android camera", function()
        local camera = Vector3.new(0, 3, 18)
        local focus = Vector3.new(0, 3, 0)
        local rules = CameraOcclusionRules
        local headOn = rules.avatarOcclusion(camera, focus, Vector3.new(0, 3, 13))
        expect(headOn ~= nil).toBe(true)
        -- A character nearly touching the lens must still be softened.
        expect(rules.avatarOcclusion(camera, focus, Vector3.new(0, 3, 17.6))
            ~= nil).toBe(true)
        expect(rules.avatarOcclusion(camera, focus, Vector3.new(10, 3, 13)))
            .toBe(nil)
        expect(rules.avatarOcclusion(camera, focus, Vector3.new(0, 3, 21)))
            .toBe(nil)
        expect(rules.avatarOcclusion(camera, focus, Vector3.new(0, 3, -2)))
            .toBe(nil)
        expect(rules.avatarOcclusion(camera, focus, Vector3.new(0, 3, 0.5)))
            .toBe(nil)
        expect(rules.avatarOcclusion(Vector3.new(0, 3, 60), focus,
            Vector3.new(0, 3, 54))).toBe(nil)
        expect(rules.avatarOcclusion(Vector3.new(0, 3, 3), focus,
            Vector3.new(0, 3, 2))).toBe(nil)
        expect(rules.avatarOcclusion(camera, focus, Vector3.new(0, 3, 12))
            < rules.avatarOcclusion(camera, focus, Vector3.new(1.9, 3, 12)))
            .toBe(true)
        expect(rules.avatarOcclusion(nil, focus, Vector3.new(0, 3, 12)))
            .toBe(nil)
        expect(rules.localModifier() > 0.5).toBe(true)
        expect(rules.localModifier() < 0.8).toBe(true)
    end)

    it("softens at most two distinct camera blockers without losing stable order", function()
        local rules = CameraOcclusionRules
        local candidates = {
            {model = "Kai", score = 3.4},
            {model = "Milo", score = 1.2},
            {model = "Nova", score = 2.1},
            {model = "Milo", score = 0.9},
            {model = "Broken", score = math.huge},
            {model = "NaN", score = 0 / 0},
        }
        local two = rules.chooseOccluders(candidates, 2)
        expect(#two).toBe(2)
        expect(two[1]).toBe("Milo")
        expect(two[2]).toBe("Nova")
        local one = rules.chooseOccluders(candidates, 1)
        expect(#one).toBe(1)
        expect(one[1]).toBe("Milo")
        expect(#rules.chooseOccluders(candidates, 0)).toBe(0)
        expect(#rules.chooseOccluders(candidates, 20)).toBe(2)
        expect(#rules.chooseOccluders(nil, 2)).toBe(0)

        local ties = rules.chooseOccluders({
            {model = "Rae", score = 2},
            {model = "Lea", score = 2},
            {model = "Zoe", score = 2},
        }, 2)
        expect(ties[1]).toBe("Rae")
        expect(ties[2]).toBe("Lea")

        -- The head can occlude a view even if its HumanoidRootPart is
        -- out of the center line (sloped platforms / climbing R15s).
        local camera = Vector3.new(0, 3, 18)
        local focus = Vector3.new(0, 3, 0)
        expect(rules.avatarOcclusion(camera, focus, Vector3.new(5, 3, 11)))
            .toBe(nil)
        expect(rules.avatarOcclusion(camera, focus, Vector3.new(0, 4, 11))
            ~= nil).toBe(true)
    end)

    it("classifies short landscape phones as tiny height", function()
        local c = UIResponsive.classify(Vector2.new(640, 360), true)
        expect(c.touch).toBe(true)
        expect(c.tinyHeight).toBe(true)
        expect(c.compactHeight).toBe(true)
        expect(c.aspect > 1.7).toBe(true)
    end)

    it("keeps main round reveals out of the center gameplay lane on Android", function()
        for _, viewport in ipairs({
            Vector2.new(540, 320),
            Vector2.new(640, 360),
            Vector2.new(960, 440),
            Vector2.new(1536, 688),
            Vector2.new(400, 720),
        }) do
            local l = UIResponsive.mobileRoundBanner(viewport)
            expect(l.widthScale >= 0.70 and l.widthScale <= 0.95).toBe(true)
            expect(l.height >= 54 and l.height <= 64).toBe(true)
            expect(l.titleMaxTextSize <= 24).toBe(true)
            expect(l.subtitleMaxTextSize <= 17).toBe(true)
            expect(l.centerYScale < 0.43).toBe(true)
            -- The first mobile banner is a 54–64px strip, never a
            -- screen-height-scaled rectangle hiding a central avatar.
            expect(l.height < viewport.Y * 0.20).toBe(true)
        end
        local wide = UIResponsive.mobileRoundBanner(Vector2.new(1536, 688))
        local narrow = UIResponsive.mobileRoundBanner(Vector2.new(540, 320))
        expect(wide.widthScale < narrow.widthScale).toBe(true)
    end)

    it("only shows nearby depth-tested AI display names on touch", function()
        local style = BotNameplateRules.presentation
        local normal = style("round", "High", true)
        local low = style("round", "Low", true)
        local ready = style("ready", "Medium", true)
        local desktop = style("round", "High", false)
        expect(normal.AlwaysOnTop).toBe(false)
        expect(ready.AlwaysOnTop).toBe(false)
        expect(low.MaxDistance < normal.MaxDistance).toBe(true)
        expect(normal.MaxDistance < desktop.MaxDistance).toBe(true)
        expect(ready.MaxDistance > normal.MaxDistance).toBe(true)
        expect(desktop.MaxDistance).toBe(72)
    end)

    it("keeps critical mobile text above a readable floor", function()
        expect(UIResponsive.criticalTextMin(Vector2.new(640, 360))).toBe(13)
        expect(UIResponsive.criticalTextMin(Vector2.new(960, 440))).toBe(14)
        expect(UIResponsive.criticalTextMin(Vector2.new(1280, 720))).toBe(15)
    end)

    it("keeps mobile dock buttons at or above the minimum touch target", function()
        for _, viewport in ipairs({
            Vector2.new(640, 360),
            Vector2.new(800, 360),
            Vector2.new(960, 440),
            Vector2.new(1280, 720),
        }) do
            local profile = UIResponsive.mobileProfile(viewport)
            expect(
                UIResponsive.touchTargetSatisfied(profile.dockButtonHeight)
            ).toBe(true)
            expect(profile.dockHeight >= profile.dockButtonHeight).toBe(true)
        end
    end)

    it("keeps padded social reaction buttons at least 44px tall", function()
        for _, viewport in ipairs({
            Vector2.new(540, 320),
            Vector2.new(640, 360),
            Vector2.new(960, 440),
            Vector2.new(1280, 720),
        }) do
            local profile = UIResponsive.mobileProfile(viewport)
            local reactionButtonHeight = profile.dockHeight - 8
            expect(UIResponsive.touchTargetSatisfied(reactionButtonHeight)).toBe(true)
        end
    end)

    it("reduces vertical density on short screens without shrinking tap targets", function()
        local tiny = UIResponsive.mobileProfile(Vector2.new(640, 360))
        local regular = UIResponsive.mobileProfile(Vector2.new(1280, 720))

        expect(tiny.topHeight < regular.topHeight).toBe(true)
        expect(tiny.timerSize < regular.timerSize).toBe(true)
        expect(tiny.voteHeight < regular.voteHeight).toBe(true)
        expect(tiny.resultHeight < regular.resultHeight).toBe(true)
        expect(tiny.dockButtonHeight).toBe(44)
    end)

    it("keeps Dash above the native jump/thumb lane on Android orientations", function()
        for _, viewport in ipairs({
            Vector2.new(540, 320),
            Vector2.new(640, 360),
            Vector2.new(960, 440),
            Vector2.new(1280, 720),
            Vector2.new(1536, 688),
            Vector2.new(400, 720),
        }) do
            local layout = UIResponsive.phaseDashLayout(viewport)
            local right = viewport.X - layout.rightInset
            local top = viewport.Y - layout.bottomInset - layout.height
            expect(UIResponsive.touchTargetSatisfied(layout.height)).toBe(true)
            expect(layout.width >= 72).toBe(true)
            expect(layout.rightInset >= 12).toBe(true)
            expect(layout.bottomInset >= 160).toBe(true)
            expect(right <= viewport.X and right - layout.width >= 0).toBe(true)
            expect(top >= 66).toBe(true)
            expect(layout.hintWidth <= right).toBe(true)
            -- The hint is LEFT of the button; it never clips past the
            -- phone's edge or overlays the top-center hazard clock.
            expect(right - layout.width - 8 - layout.hintWidth >= 0).toBe(true)
        end
        local short = UIResponsive.phaseDashLayout(Vector2.new(540, 320))
        local tall = UIResponsive.phaseDashLayout(Vector2.new(1280, 720))
        expect(short.width < tall.width).toBe(true)
        expect(short.height < tall.height).toBe(true)
        expect(tall.bottomInset > short.bottomInset).toBe(true)
    end)

    it("uses wider round focus on narrow screens and narrower focus on ultrawide", function()
        local narrow = UIResponsive.mobileProfile(Vector2.new(540, 360))
        local normal = UIResponsive.mobileProfile(Vector2.new(800, 450))
        local wide = UIResponsive.mobileProfile(Vector2.new(1000, 420))

        expect(narrow.roundFocusWidthScale > normal.roundFocusWidthScale).toBe(true)
        expect(wide.roundFocusWidthScale < normal.roundFocusWidthScale).toBe(true)
    end)

    it("keeps the HUD compact on a wide Android landscape viewport", function()
        local profile = UIResponsive.mobileProfile(Vector2.new(1536, 688))

        expect(profile.wide).toBe(true)
        expect(profile.topWidthScale <= 0.60).toBe(true)
        -- Native Roblox menu/chat overlays the left of a landscape phone.
        -- The phase title starts beyond the first 29% of the viewport,
        -- leaving the upper-left touch controls unobstructed.
        expect(profile.topCenterXScale - profile.topWidthScale * 0.5 >= 0.29)
            .toBe(true)
        expect(profile.topCenterXScale + profile.topWidthScale * 0.5 <= 0.92)
            .toBe(true)
        expect(profile.roundFocusWidthScale <= 0.52).toBe(true)
        expect(profile.roundFocusBottomOffset >= 96).toBe(true)
        expect(profile.topHeight <= 68).toBe(true)
    end)

    it("centers ordinary portrait HUDs without shifting the title off-screen", function()
        for _, viewport in ipairs({
            Vector2.new(400, 720),
            Vector2.new(540, 320),
            Vector2.new(720, 480),
        }) do
            local profile = UIResponsive.mobileProfile(viewport)
            expect(profile.topCenterXScale).toBe(0.5)
            expect(profile.topCenterXScale - profile.topWidthScale * 0.5 >= 0)
                .toBe(true)
            expect(profile.topCenterXScale + profile.topWidthScale * 0.5 <= 1)
                .toBe(true)
        end
    end)

    it("preserves a static near-miss card without moving flashes in ReduceMotion", function()
        local normal = NearMissVisualRules.profile(false)
        local reduced = NearMissVisualRules.profile(true)
        expect(normal.Animate).toBe(true)
        expect(normal.WorldPulse).toBe(true)
        expect(normal.EdgeFlash).toBe(true)
        expect(reduced.Animate).toBe(false)
        expect(reduced.WorldPulse).toBe(false)
        expect(reduced.EdgeFlash).toBe(false)
        expect(NearMissVisualRules.profile(nil).Animate).toBe(true)
    end)

    it("reserves panel space above the bottom dock", function()
        local tiny = UIResponsive.mobileProfile(Vector2.new(640, 360))
        local regular = UIResponsive.mobileProfile(Vector2.new(1280, 720))

        expect(tiny.panelBottomOffset > tiny.dockHeight).toBe(true)
        expect(regular.panelBottomOffset > regular.dockHeight).toBe(true)
    end)
end)

return nil
