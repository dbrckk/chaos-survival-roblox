--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local UIResponsive = require("../../src/shared/UIResponsive")
local MobileHudNotices = require("../../src/shared/MobileHudNotices")
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

    it("keeps the ready strategy card clear of the alive counter on Android", function()
        for _, viewport in ipairs({
            Vector2.new(540, 320),
            Vector2.new(640, 360),
            Vector2.new(960, 440),
            Vector2.new(1536, 688),
            Vector2.new(400, 720),
        }) do
            local guide = UIResponsive.mobileArenaGuideLayout(viewport)
            local profile = UIResponsive.mobileProfile(viewport)
            local c = UIResponsive.classify(viewport, true)
            expect(guide.topOffset + guide.height < viewport.Y * 0.65).toBe(true)
            if c.wide then
                -- AliveCounter is anchored to the right of the top HUD,
                -- 8px inset, with a minimum width of 88px.
                local aliveLeft = (profile.topCenterXScale
                    + profile.topWidthScale * 0.5) * viewport.X
                    - 8 - math.max(88, profile.timerSize + 36)
                local guideRight = (guide.centerXScale
                    + guide.widthScale * 0.5) * viewport.X
                expect(guideRight + 8 <= aliveLeft).toBe(true)
            else
                -- Ready-phase alive chip extends 5px below the header,
                -- then has a 24px height. Keep a visible 6px gap.
                expect(guide.topOffset >= 7 + profile.topHeight + 5 + 24 + 6)
                    .toBe(true)
            end
        end
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

    it("keeps the optional district route below Android core HUD with safe insets", function()
        for _, data in ipairs({
            {viewport = Vector2.new(540, 320), inset = 48},
            {viewport = Vector2.new(640, 360), inset = 56},
            {viewport = Vector2.new(960, 440), inset = 54},
            {viewport = Vector2.new(1536, 688), inset = 68},
            {viewport = Vector2.new(400, 720), inset = 56},
        }) do
            local layout = UIResponsive.mobileExpeditionLayout(
                data.viewport, data.inset)
            local profile = UIResponsive.mobileProfile(data.viewport)
            expect(layout.fits).toBe(true)
            expect(layout.topOffset >= data.inset + profile.topHeight + 48)
                .toBe(true)
            expect(layout.topOffset + layout.height
                + profile.roundFocusBottomOffset + 10 <= data.viewport.Y)
                .toBe(true)
            expect(layout.width <= data.viewport.X - 20).toBe(true)
            expect(layout.xScale).toBe(profile.wide and 0.23 or 0.50)
        end
        local cramped = UIResponsive.mobileExpeditionLayout(
            Vector2.new(540, 320), 210)
        expect(cramped.fits).toBe(false)
    end)

    it("separates the Android route, escalation, and shard lanes", function()
        for _, viewport in ipairs({
            Vector2.new(540, 320),
            Vector2.new(640, 360),
            Vector2.new(960, 440),
            Vector2.new(1536, 688),
            Vector2.new(400, 720),
        }) do
            local inset = viewport.Y < 400 and 48 or 56
            local expedition = UIResponsive.mobileExpeditionLayout(viewport, inset)
            local escalation = UIResponsive.mobileEscalationToast(viewport)
            local reward = UIResponsive.mobileShardToast(viewport)
            local escalationBottom = (
                escalation.centerYScale * viewport.Y + escalation.height * 0.5)
            expect(expedition.topOffset > escalationBottom).toBe(true)
            expect(escalation.height <= 44).toBe(true)
            expect(reward.height <= 40).toBe(true)
            expect(reward.fits).toBe(true)
            local profile = UIResponsive.mobileProfile(viewport)
            local rewardTop = reward.centerYScale * viewport.Y
                - reward.height * 0.5
            local rewardBottom = reward.centerYScale * viewport.Y
                + reward.height * 0.5
            local survivalTop = viewport.Y - profile.roundFocusBottomOffset
                - profile.roundFocusHeight
            expect(rewardTop >= escalationBottom + 2).toBe(true)
            -- The 320px, 360px and 440px Android landscape layouts must
            -- never render the optional shard toast over the survival bar.
            expect(rewardBottom + 8 <= survivalTop).toBe(true)
            local c = UIResponsive.classify(viewport, true)
            if c.wide and not c.compactHeight then
                expect(expedition.topOffset + expedition.height < rewardTop)
                    .toBe(true)
                expect(expedition.xScale).toBe(reward.centerXScale)
            elseif c.wide then
                -- No vertical room between route and focus on short wide
                -- screens: move the reward to a different horizontal lane.
                expect(reward.centerXScale).toBe(0.50)
                local distance = (reward.centerXScale - expedition.xScale)
                    * viewport.X
                expect(distance > (reward.width + expedition.width) * 0.5)
                    .toBe(true)
            end
            if c.wide then
                expect(expedition.xScale < escalation.centerXScale).toBe(true)
                expect(escalation.widthScale < 0.5).toBe(true)
            end
        end
    end)

    it("hides an optional pickup toast when even the mobile safe lane is too short", function()
        expect(UIResponsive.mobileShardToast(Vector2.new(400, 230)).fits)
            .toBe(false)
    end)

    it("allows exactly one foreground Android notice at a time", function()
        MobileHudNotices.release("intro")
        MobileHudNotices.release("escalation")
        MobileHudNotices.release("shard")
        expect(MobileHudNotices.current()).toBe(nil)
        expect(MobileHudNotices.claim("shard", 10)).toBe(true)
        expect(MobileHudNotices.claim("escalation", 70)).toBe(true)
        expect(MobileHudNotices.current()).toBe("escalation")
        expect(MobileHudNotices.claim("shard", 10)).toBe(false)
        expect(MobileHudNotices.claim("intro", 100)).toBe(true)
        expect(MobileHudNotices.current()).toBe("intro")
        expect(MobileHudNotices.release("shard")).toBe(false)
        expect(MobileHudNotices.release("escalation")).toBe(false)
        expect(MobileHudNotices.release("intro")).toBe(true)
        expect(MobileHudNotices.current()).toBe(nil)
        expect(MobileHudNotices.claim("shard", 10)).toBe(true)
        expect(MobileHudNotices.release("shard")).toBe(true)
    end)

    it("positions GRID and FLUX trackers below Roblox native inset", function()
        for _, data in ipairs({
            {viewport = Vector2.new(540, 320), inset = 48},
            {viewport = Vector2.new(640, 360), inset = 56},
            {viewport = Vector2.new(960, 440), inset = 54},
            {viewport = Vector2.new(1536, 688), inset = 68},
            {viewport = Vector2.new(400, 720), inset = 56},
        }) do
            local layout = UIResponsive.mobileMechanicTracker(
                data.viewport, data.inset)
            local profile = UIResponsive.mobileProfile(data.viewport)
            local focusTop = data.viewport.Y - profile.roundFocusBottomOffset
                - profile.roundFocusHeight
            expect(layout.fits).toBe(true)
            expect(layout.centerXScale).toBe(0.5)
            expect(layout.topOffset >= data.inset + 7 + profile.topHeight
                + 5 + 24 + 8).toBe(true)
            expect(layout.topOffset + layout.height + 8 <= focusTop)
                .toBe(true)
            expect(layout.width >= 174 and layout.width <= 254).toBe(true)
            expect(layout.width < data.viewport.X).toBe(true)
        end
        -- In split-screen mode the tracker is optional; core survival
        -- status, player touch actions and world mechanics remain visible.
        expect(UIResponsive.mobileMechanicTracker(
            Vector2.new(400, 230), 48).fits).toBe(false)
    end)

    it("keeps near-miss toasts outside core HUD on common Android sizes", function()
        for _, viewport in ipairs({
            Vector2.new(540, 320),
            Vector2.new(640, 360),
            Vector2.new(960, 440),
            Vector2.new(1536, 688),
            Vector2.new(400, 720),
        }) do
            local profile = UIResponsive.mobileProfile(viewport)
            local toast = UIResponsive.mobileEscalationToast(viewport)
            local upper = toast.centerYScale * viewport.Y - toast.height * 0.5
            local lower = upper + toast.height
            expect(UIResponsive.mobileOptionalNoticeFits(viewport)).toBe(true)
            expect(upper >= 7 + profile.topHeight + 5 + 24 + 5)
                .toBe(true)
            expect(lower + 6 <= viewport.Y - profile.roundFocusBottomOffset
                - profile.roundFocusHeight).toBe(true)
        end
        expect(UIResponsive.mobileOptionalNoticeFits(Vector2.new(400, 230)))
            .toBe(false)
    end)

    it("preempts near misses below survival alerts but above pickup rewards", function()
        for _, owner in ipairs({
            "intro", "escalation", "near-miss", "mechanic", "shard", "momentum"
        }) do
            MobileHudNotices.release(owner)
        end
        expect(MobileHudNotices.claim("shard", 10)).toBe(true)
        expect(MobileHudNotices.claim("near-miss", 30)).toBe(true)
        expect(MobileHudNotices.current()).toBe("near-miss")
        expect(MobileHudNotices.claim("mechanic", 20)).toBe(false)
        expect(MobileHudNotices.claim("escalation", 70)).toBe(true)
        expect(MobileHudNotices.claim("near-miss", 30)).toBe(false)
        expect(MobileHudNotices.claim("intro", 100)).toBe(true)
        expect(MobileHudNotices.release("near-miss")).toBe(false)
        expect(MobileHudNotices.release("intro")).toBe(true)
        expect(MobileHudNotices.current()).toBe(nil)
    end)

    it("hides optional expedition navigation for any survival priority banner", function()
        expect(UIResponsive.showOptionalRoute(false, false, false)).toBe(true)
        expect(UIResponsive.showOptionalRoute(true, false, false)).toBe(false)
        expect(UIResponsive.showOptionalRoute(false, true, false)).toBe(false)
        expect(UIResponsive.showOptionalRoute(false, false, true)).toBe(false)
        expect(UIResponsive.showOptionalRoute(true, true, true)).toBe(false)
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

    it("keeps mobile momentum feedback away from the hazard, dash and focus bars", function()
        for _, viewport in ipairs({
            Vector2.new(540, 320),
            Vector2.new(640, 360),
            Vector2.new(960, 440),
            Vector2.new(1536, 688),
            Vector2.new(400, 720),
        }) do
            local chip = UIResponsive.mobileMomentumChip(viewport)
            local profile = UIResponsive.mobileProfile(viewport)
            local left, right = chip.leftInset, chip.leftInset + chip.width
            local top = chip.centerYScale * viewport.Y - chip.height * 0.5
            local bottom = top + chip.height
            expect(left >= 0 and right <= viewport.X * 0.42).toBe(true)
            expect(top > profile.topHeight + 12).toBe(true)
            expect(bottom < viewport.Y - profile.roundFocusBottomOffset
                - profile.roundFocusHeight).toBe(true)
        end
    end)

    it("hides the optional momentum chip on a height-constrained split screen", function()
        expect(UIResponsive.mobileMomentumChip(Vector2.new(400, 230)).fits)
            .toBe(false)
        expect(UIResponsive.mobileMomentumChip(Vector2.new(640, 360)).fits)
            .toBe(true)
    end)

    it("preempts optional momentum feedback with gameplay notices", function()
        MobileHudNotices.release("momentum")
        MobileHudNotices.release("shard")
        MobileHudNotices.release("escalation")
        MobileHudNotices.release("intro")
        expect(MobileHudNotices.claim("momentum", 5)).toBe(true)
        expect(MobileHudNotices.claim("shard", 10)).toBe(true)
        expect(MobileHudNotices.current()).toBe("shard")
        expect(MobileHudNotices.claim("momentum", 5)).toBe(false)
        expect(MobileHudNotices.claim("mechanic", 20)).toBe(true)
        expect(MobileHudNotices.claim("escalation", 70)).toBe(true)
        expect(MobileHudNotices.claim("mechanic", 20)).toBe(false)
        expect(MobileHudNotices.claim("intro", 100)).toBe(true)
        expect(MobileHudNotices.release("momentum")).toBe(false)
        expect(MobileHudNotices.release("intro")).toBe(true)
        expect(MobileHudNotices.current()).toBe(nil)
    end)

    it("keeps opt-in FPS/P95 monitoring clear of the mobile survival HUD", function()
        for _, viewport in ipairs({
            Vector2.new(540, 320),
            Vector2.new(640, 360),
            Vector2.new(960, 440),
            Vector2.new(1536, 688),
            Vector2.new(400, 720),
        }) do
            local layout = UIResponsive.mobilePerformanceOverlay(viewport)
            local profile = UIResponsive.mobileProfile(viewport)
            expect(layout.fits).toBe(true)
            expect(layout.width >= 156 and layout.width <= 176).toBe(true)
            expect(layout.leftInset + layout.width < viewport.X * 0.50).toBe(true)
            expect(layout.topOffset > profile.topHeight + 80).toBe(true)
            expect(layout.topOffset + layout.height + 10 <= viewport.Y
                - profile.roundFocusBottomOffset - profile.roundFocusHeight)
                .toBe(true)
        end
    end)

    it("drops optional FPS overlay on a short split-screen view", function()
        expect(UIResponsive.mobilePerformanceOverlay(Vector2.new(400, 230)).fits)
            .toBe(false)
        expect(UIResponsive.mobilePerformanceOverlay(Vector2.new(320, 520)).fits)
            .toBe(false)
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
