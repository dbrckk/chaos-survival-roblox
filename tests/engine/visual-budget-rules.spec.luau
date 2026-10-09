--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local VisualBudgetRules = require("../../src/shared/VisualBudgetRules")
local CinematicPulseRingKit = require("../../src/client/CinematicPulseRingKit")
local LandingImprintKit = require("../../src/client/LandingImprintKit")
local DisasterIntroMotionKit = require("../../src/client/DisasterIntroMotionKit")
local DisasterBoundaryClimaxKit = require("../../src/client/DisasterBoundaryClimaxKit")
local LocomotionGroundFx = require("../../src/client/LocomotionGroundFx")

describe("visual budget rules", function()
    it("uses progressively smaller budgets for lower tiers", function()
        local high = VisualBudgetRules.forTier("High")
        local medium = VisualBudgetRules.forTier("Medium")
        local low = VisualBudgetRules.forTier("Low")

        expect(high.Parts > medium.Parts).toBe(true)
        expect(medium.Parts > low.Parts).toBe(true)
        expect(high.Lights > medium.Lights).toBe(true)
        expect(medium.Lights > low.Lights).toBe(true)
        expect(high.Effects > medium.Effects).toBe(true)
        expect(medium.Effects > low.Effects).toBe(true)
    end)

    it("keeps local visual folder coverage unique and comprehensive", function()
        local seen = {}
        expect(#VisualBudgetRules.LocalFolders >= 37).toBe(true)

        for _, folderName in ipairs(VisualBudgetRules.LocalFolders) do
            expect(type(folderName)).toBe("string")
            expect(folderName ~= "").toBe(true)
            expect(seen[folderName] ~= true).toBe(true)
            seen[folderName] = true
        end
    end)

    it("classifies every managed GPU effect type consistently", function()
        local managed = {
            Instance.new("ParticleEmitter"),
            Instance.new("Trail"),
            Instance.new("Beam"),
            Instance.new("Highlight"),
            Instance.new("Smoke"),
            Instance.new("Fire"),
            Instance.new("Sparkles"),
        }

        for _, instance in ipairs(managed) do
            expect(VisualBudgetRules.isEffect(instance)).toBe(true)
            instance:Destroy()
        end

        local light = Instance.new("PointLight")
        expect(VisualBudgetRules.isLight(light)).toBe(true)
        expect(VisualBudgetRules.isEffect(light)).toBe(false)
        light:Destroy()
    end)

    it("collects parts lights and effects from registered visual folders", function()
        local root = Instance.new("Folder")
        local layer = Instance.new("Folder")
        layer.Name = VisualBudgetRules.LocalFolders[1]
        layer.Parent = root

        local part = Instance.new("Part")
        part.Parent = layer

        local light = Instance.new("PointLight")
        light.Parent = part

        local attachment = Instance.new("Attachment")
        attachment.Parent = part

        local emitter = Instance.new("ParticleEmitter")
        emitter.Parent = attachment

        local highlight = Instance.new("Highlight")
        highlight.Parent = layer

        local smoke = Instance.new("Smoke")
        smoke.Parent = part

        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(1)
        expect(metrics.Parts).toBe(1)
        expect(metrics.Lights).toBe(1)
        expect(metrics.Effects).toBe(3)

        root:Destroy()
    end)

    it("counts transient Phase Dash facets and Showtime glyphs in mobile budgets", function()
        local root = Instance.new("Folder")
        local dash = Instance.new("Folder")
        dash.Name = "PhaseDashVfxLocal"
        dash.Parent = root
        local showtime = Instance.new("Folder")
        showtime.Name = "LobbyShowtimeLocal"
        showtime.Parent = root

        for index = 1, 7 do
            local part = Instance.new("Part")
            part.Name = "PhaseDashRingFacet" .. index
            part.CanCollide = false
            part.Parent = dash
        end
        for index = 1, 3 do
            local part = Instance.new("Part")
            part.Name = "OrbitDanceGlyph" .. index
            part.CanCollide = false
            part.Parent = showtime
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(2)
        expect(metrics.Parts).toBe(10)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)
        root:Destroy()
    end)

    it("audits the entire four-gate Flux Relay scene rather than hiding it from budget metrics", function()
        local root = Instance.new("Folder")
        local flux = Instance.new("Folder")
        flux.Name = "FluxRelayLocal"
        flux.Parent = root
        for index = 1, 4 do
            for partIndex = 1, 12 do
                local piece = Instance.new("Part")
                piece.Name = "FluxGate" .. index .. "_" .. partIndex
                piece.CanCollide = false
                piece.Parent = flux
            end
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(1)
        expect(metrics.Parts).toBe(48)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)
        root:Destroy()
    end)

    it("tracks up to twenty-four Orbital helix runner glyphs at High quality", function()
        local root = Instance.new("Folder")
        local helix = Instance.new("Folder")
        helix.Name = "OrbitalHelixLocal"
        helix.Parent = root
        for index = 1, 24 do
            local glyph = Instance.new("Part")
            glyph.Name = "HelixMotionGlyph"
            glyph.CanCollide = false
            glyph.CanTouch = false
            glyph.CanQuery = false
            glyph.Parent = helix
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(1)
        expect(metrics.Parts).toBe(24)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)
        root:Destroy()
    end)

    it("includes all four detailed Classic Grid Circuit monuments in visual telemetry", function()
        local root = Instance.new("Folder")
        local circuit = Instance.new("Folder")
        circuit.Name = "GridCircuitLocal"
        circuit.Parent = root
        -- High tier: 1 base + 12 ring rails + 4 pylons +
        -- 4 filaments + 4 service crowns = 25 parts per monument.
        for index = 1, 100 do
            local piece = Instance.new("Part")
            piece.Name = "CircuitArt" .. index
            piece.CanCollide = false
            piece.Parent = circuit
        end
        local metrics, count = VisualBudgetRules.collect(root)
        expect(count).toBe(1)
        expect(metrics.Parts).toBe(100)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("High", metrics)).toBe(true)
        root:Destroy()
    end)

    it("audits temporary meteor and bomb setpieces under their shared local folder", function()
        local root = Instance.new("Folder")
        local folder = Instance.new("Folder")
        folder.Name = "ImpactSetpieceLocal"
        folder.Parent = root
        local meteor = Instance.new("Folder")
        meteor.Name = "ImpactSignature_Meteor"
        meteor.Parent = folder
        local bomb = Instance.new("Folder")
        bomb.Name = "ImpactSignature_Bomb"
        bomb.Parent = folder
        for i = 1, 7 do
            Instance.new("WedgePart").Parent = meteor
        end
        for i = 1, 8 do
            Instance.new("Part").Parent = bomb
        end
        local found = 0
        for _, name in ipairs(VisualBudgetRules.LocalFolders) do
            if name == folder.Name then
                found += 1
            end
        end
        expect(found).toBe(1)
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(1)
        expect(metrics.Parts).toBe(15)
        root:Destroy()
    end)

    it("includes short-lived sprint and skid traces in the live part count", function()
        local root = Instance.new("Folder")
        local effects = Instance.new("Folder")
        effects.Name = "LocomotionContactLocal"
        effects.Parent = root
        local sprint = Instance.new("Folder")
        sprint.Name = "ChaosLaunchContact"
        sprint.Parent = effects
        for i = 1, 4 do
            local trace = Instance.new("Part")
            trace.Name = "LaunchFootTrace" .. i
            trace.Parent = sprint
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(1)
        expect(metrics.Parts).toBe(4)
        root:Destroy()
    end)

    it("audits all transient winner and transition contours without solid screen-covering disks", function()
        local root = Instance.new("Folder")
        local transitions = Instance.new("Folder")
        transitions.Name = "RoundTransitionPulsesLocal"
        transitions.Parent = root
        local celebrations = Instance.new("Folder")
        celebrations.Name = "RoundCelebrationPulsesLocal"
        celebrations.Parent = root
        local cf = CFrame.new(0, 5, 0)
        local tint = Color3.fromRGB(75, 214, 255)
        local first = CinematicPulseRingKit.emit(
            transitions, "RoundStart", cf, tint, 1, 82, 0.6, "Medium", true
        )
        local second = CinematicPulseRingKit.emit(
            celebrations, "Win", cf, tint, 1, 22, 0.6, "High", true
        )
        local third = CinematicPulseRingKit.emit(
            celebrations, "Clutch", cf, tint, 1, 19, 0.6, "High", true
        )
        expect(#first).toBe(6)
        expect(#second).toBe(8)
        expect(#third).toBe(8)
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(2)
        expect(metrics.Parts).toBe(22)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        for _, arc in ipairs(first) do
            expect(arc.Shape).toBe(Enum.PartType.Block)
            expect(arc.CanCollide).toBe(false)
        end
        root:Destroy()
    end)

    it("counts simultaneous bot landings and launch marks in the live graphics budget", function()
        local root = Instance.new("Folder")
        local landing = Instance.new("Folder")
        landing.Name = "CharacterContactLocal"
        landing.Parent = root
        local locomotion = Instance.new("Folder")
        locomotion.Name = "LocomotionContactLocal"
        locomotion.Parent = root
        local frame = CFrame.new(0, 5, 0)
        for i = 1, 4 do
            local shifted = frame * CFrame.new(i * 2, 0, 0)
            local botLanding = LandingImprintKit.build(
                landing, shifted, Color3.fromRGB(120, 210, 230),
                "Mechanical", Enum.Material.Metal, 3, 0.85, false
            )
            expect(#botLanding).toBe(3)
            local botPivot = LocomotionGroundFx.build(
                locomotion, shifted, "Pivot", 0.9, "High"
            )
            expect(botPivot ~= nil).toBe(true)
            expect(#botPivot:GetChildren()).toBe(4)
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(2)
        expect(metrics.Parts).toBe(28)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("High", metrics)).toBe(true)
        root:Destroy()
    end)

    it("counts all double-chaos intro strokes without full arena-covering cylinders", function()
        local root = Instance.new("Folder")
        local glyph = Instance.new("Folder")
        glyph.Name = "DisasterIntroGlyphLocal"
        glyph.Parent = root
        local motion = Instance.new("Folder")
        motion.Name = "DisasterIntroMotionLocal"
        motion.Parent = root
        local frame = CFrame.new(8, 3, -11)
            * CFrame.Angles(math.rad(7), math.rad(32), 0)
        local blue = Color3.fromRGB(75, 175, 255)
        local red = Color3.fromRGB(255, 80, 80)
        for _, kind in ipairs({"freeze", "blast"}) do
            local pieces = DisasterIntroMotionKit.emit(
                motion, kind, frame, 98, blue, red,
                "High", true, 0.58
            )
            expect(#pieces).toBe(6)
            for _, piece in ipairs(pieces) do
                expect(piece:IsA("Part") or piece:IsA("WedgePart")).toBe(true)
                if piece:IsA("Part") then
                    expect(piece.Shape).toBe(Enum.PartType.Block)
                end
                expect(piece.CanCollide).toBe(false)
                expect(piece.CanTouch).toBe(false)
                expect(piece.CanQuery).toBe(false)
                expect(piece.Size.Y <= 0.08).toBe(true)
            end
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(2)
        expect(metrics.Parts).toBe(12)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("High", metrics)).toBe(true)
        root:Destroy()
    end)

    it("audits shrinking/blackout scenery and both simultaneous climax signatures", function()
        local root = Instance.new("Folder")
        local persistent = Instance.new("Folder")
        persistent.Name = "ChaosMotionDisasterVfxLocal"
        persistent.Parent = root
        for i = 1, 8 do
            local part = Instance.new("Part")
            part.Name = i <= 4 and "ShrinkPerimeterLocal" .. i
                or "BlackoutEmergencyBeacon" .. (i - 4)
            part.Parent = persistent
        end
        local transient = Instance.new("Folder")
        transient.Name = "DisasterClimaxLocal"
        transient.Parent = root
        local frame = CFrame.new(3, 5, 7)
            * CFrame.Angles(0, math.rad(20), math.rad(9))
        local arenaSize = Vector3.new(124, 3, 92)
        local primary = Color3.fromRGB(250, 85, 110)
        local secondary = Color3.fromRGB(245, 220, 160)
        for _, kind in ipairs({"blast", "shrink"}) do
            local pieces = DisasterBoundaryClimaxKit.emit(transient, kind,
                frame, arenaSize, 3, primary, secondary, "High", false)
            expect(#pieces).toBe(6)
            for _, part in ipairs(pieces) do
                expect(part.CanCollide).toBe(false)
                expect(part.CanTouch).toBe(false)
                expect(part.CanQuery).toBe(false)
                expect(part.CastShadow).toBe(false)
            end
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(2)
        expect(metrics.Parts).toBe(20)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)
        root:Destroy()
    end)

    it("counts attached local meteor trails even when meteor shells are server owned", function()
        local root = Instance.new("Folder")
        for i = 1, 6 do
            local meteor = Instance.new("Part")
            meteor.Name = "RoundMeteor"
            meteor.Parent = root
            local trail = Instance.new("Trail")
            trail.Name = "SignatureMeteorTrail"
            trail.Parent = meteor
        end
        local other = Instance.new("Part")
        other.Name = "OtherHazard"
        other.Parent = root
        local extra = Instance.new("Trail")
        extra.Name = "SignatureMeteorTrail"
        extra.Parent = other
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(0)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(6)
        expect(VisualBudgetRules.withinBudget("High", metrics)).toBe(true)
        root:Destroy()
    end)

    it("classifies live visual budget status before any tier lookup", function()
        expect(type(VisualBudgetRules.status)).toBe("function")
        expect(VisualBudgetRules.status("High", {
            Parts = 1,
            Lights = 1,
            Effects = 1,
        })).toBe("OK")

        local high = VisualBudgetRules.forTier("High")
        expect(VisualBudgetRules.status("High", {
            Parts = high.Parts + 1,
            Lights = 0,
            Effects = 0,
        })).toBe("OVER")

        expect(VisualBudgetRules.status("Unknown", {
            Parts = 0,
            Lights = 0,
            Effects = 0,
        })).toBe("UNKNOWN")
    end)

    it("detects over-budget visual scenes", function()
        expect(VisualBudgetRules.withinBudget("Medium", {
            Parts = 400,
            Lights = 20,
            Effects = 30,
        })).toBe(true)

        expect(VisualBudgetRules.withinBudget("Low", {
            Parts = 441,
            Lights = 20,
            Effects = 30,
        })).toBe(false)

        local over = VisualBudgetRules.overages("Low", {
            Parts = 450,
            Lights = 40,
            Effects = 60,
        })

        expect(over.Parts).toBe(10)
        expect(over.Lights).toBe(8)
        expect(over.Effects).toBe(4)
    end)
end)

return nil
