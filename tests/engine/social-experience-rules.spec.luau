--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local SocialExperienceRules = require("../../src/shared/SocialExperienceRules")

describe("Social experience rules", function()
    it("keeps invite affordances out of the first-time flow and active gameplay", function()
        expect(SocialExperienceRules.shouldShow("intermission", nil, 0, true)).toBe(false)
        expect(SocialExperienceRules.shouldShow("round", nil, 4, true)).toBe(false)
        expect(SocialExperienceRules.shouldShow("ready", nil, 4, true)).toBe(false)
        expect(SocialExperienceRules.shouldShow("intermission", {{}}, 4, true)).toBe(false)
    end)

    it("surfaces the social loop after a completed round at calm moments", function()
        expect(SocialExperienceRules.shouldShow("result", nil, 1, true)).toBe(true)
        expect(SocialExperienceRules.shouldShow("intermission", nil, 1, true)).toBe(true)
        expect(SocialExperienceRules.shouldShow("intermission", {}, 2, true)).toBe(true)
        expect(SocialExperienceRules.shouldShow("result", nil, 2, false)).toBe(false)
    end)

    it("changes social framing after wins and losses without changing the action", function()
        expect(SocialExperienceRules.intent(true)).toBe("celebrate")
        expect(SocialExperienceRules.intent(false)).toBe("comeback")
        expect(SocialExperienceRules.buttonKey(true)).toBe("INVITE_FRIENDS")
        expect(SocialExperienceRules.buttonKey(false)).toBe("BRING_BACKUP")
        expect(SocialExperienceRules.promptKey(true)).toBe("INVITE_PROMPT_WIN")
        expect(SocialExperienceRules.promptKey(false)).toBe("INVITE_PROMPT_LOSS")
    end)

    it("emphasizes the crew beacon most strongly at the end of a round", function()
        expect(SocialExperienceRules.beaconEmphasis("result")).toBe(1)
        expect(SocialExperienceRules.beaconEmphasis("intermission")).toBe(0.72)
        expect(SocialExperienceRules.beaconEmphasis("round")).toBe(0)
    end)
end)

return nil
