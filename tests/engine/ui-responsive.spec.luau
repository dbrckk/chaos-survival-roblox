--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local UIResponsive = require("../../src/shared/UIResponsive")

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

    it("reduces vertical density on short screens without shrinking tap targets", function()
        local tiny = UIResponsive.mobileProfile(Vector2.new(640, 360))
        local regular = UIResponsive.mobileProfile(Vector2.new(1280, 720))

        expect(tiny.topHeight < regular.topHeight).toBe(true)
        expect(tiny.timerSize < regular.timerSize).toBe(true)
        expect(tiny.voteHeight < regular.voteHeight).toBe(true)
        expect(tiny.resultHeight < regular.resultHeight).toBe(true)
        expect(tiny.dockButtonHeight).toBe(44)
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

    it("reserves panel space above the bottom dock", function()
        local tiny = UIResponsive.mobileProfile(Vector2.new(640, 360))
        local regular = UIResponsive.mobileProfile(Vector2.new(1280, 720))

        expect(tiny.panelBottomOffset > tiny.dockHeight).toBe(true)
        expect(regular.panelBottomOffset > regular.dockHeight).toBe(true)
    end)
end)

return nil
