--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local UIResponsive = require("../../src/shared/UIResponsive")
local NearMissVisualRules = require("../../src/shared/NearMissVisualRules")

describe("UI responsive profiles", function()
    it("classifies short landscape phones as tiny height", function()
        local c = UIResponsive.classify(Vector2.new(640, 360), true)
        expect(c.touch).toBe(true)
        expect(c.tinyHeight).toBe(true)
        expect(c.compactHeight).toBe(true)
        expect(c.aspect > 1.7).toBe(true)
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
        expect(profile.topWidthScale <= 0.82).toBe(true)
        expect(profile.roundFocusWidthScale <= 0.52).toBe(true)
        expect(profile.roundFocusBottomOffset >= 96).toBe(true)
        expect(profile.topHeight <= 68).toBe(true)
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
