--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local VisualBudgetRules = require("../../src/shared/VisualBudgetRules")
local SceneryLodRules = require("../../src/shared/SceneryLodRules")
local CinematicPulseRingKit = require("../../src/client/CinematicPulseRingKit")
local LandingImprintKit = require("../../src/client/LandingImprintKit")
local DisasterIntroMotionKit = require("../../src/client/DisasterIntroMotionKit")
local DisasterBoundaryClimaxKit = require("../../src/client/DisasterBoundaryClimaxKit")
local LocomotionGroundFx = require("../../src/client/LocomotionGroundFx")
local LobbyPracticeVisualKit = require("../../src/client/LobbyPracticeVisualKit")
local ArenaFloorFollowerKit = require("../../src/client/ArenaFloorFollowerKit")

describe("visual budget rules", function()
    it("hides only original off-map hero geometry on low-end Android", function()
        local root = Instance.new("Folder")
        local generated = Instance.new("Folder")
        generated.Name = "GeneratedMap"
        generated.Parent = root
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = generated
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        local hero = Instance.new("Model")
        hero.Name = "ArenaHeroArchitecture3D"
        hero:SetAttribute("ChaosDistantScenery", true)
        hero:SetAttribute("SourceIsOriginal", true)
        hero.Parent = decor
        local part = Instance.new("Part")
        part.Parent = hero
        expect(SceneryLodRules.heroArchitectureOwner(root)).toBe(hero)
        expect(SceneryLodRules.visible("Low", 5, 0, 185, nil)).toBe(false)
        expect(SceneryLodRules.visible("Medium", 110, 0, 185, nil)).toBe(true)
        expect(SceneryLodRules.visible("Medium", 204, 0, 185, false)).toBe(false)
        expect(SceneryLodRules.visible("High", 600, 0, 185, nil)).toBe(true)
        -- A replica with the same name is never trusted as cosmetic if its
        -- provenance flags are absent: no risk of hiding gameplay shells.
        hero:SetAttribute("SourceIsOriginal", nil)
        expect(SceneryLodRules.heroArchitectureOwner(root)).toBe(nil)
        hero:SetAttribute("SourceIsOriginal", true)
        hero:SetAttribute("ChaosDistantScenery", false)
        expect(SceneryLodRules.heroArchitectureOwner(root)).toBe(nil)
        root:Destroy()
    end)

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
        -- Unlike root-level decorative folders, this lives under each
        -- marked lobby pad; live visual telemetry counts its Parts there.
        expect(seen.PracticeVectorGlyphLocal).toBe(true)
        expect(seen.PracticePadPolishLocal).toBe(true)
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

    it("audits marked arena mobility pad effects without counting server lighting", function()
        local root = Instance.new("Folder")
        local generated = Instance.new("Folder")
        generated.Name = "GeneratedMap"
        generated.Parent = root
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = generated
        local mechanics = Instance.new("Folder")
        mechanics.Name = "Mechanics"
        mechanics.Parent = arena

        local pads = {}
        for i = 1, 3 do
            local pad = Instance.new("Part")
            pad.Name = "MobilityPad" .. i
            pad:SetAttribute("ArenaMobilityPad", true)
            pad.Parent = mechanics

            local serverLight = Instance.new("PointLight")
            serverLight.Name = "MobilityPadLight"
            serverLight.Parent = pad
            local serverEmitter = Instance.new("ParticleEmitter")
            serverEmitter.Name = "UnrelatedServerEmitter"
            serverEmitter.Parent = pad

            local attachment = Instance.new("Attachment")
            attachment.Name = "LocalMobilityVfx"
            attachment.Parent = pad
            local emitter = Instance.new("ParticleEmitter")
            emitter.Name = "MobilityPulseLocal"
            emitter.Parent = attachment

            local highlight = Instance.new("Highlight")
            highlight.Name = "MobilityPadHighlightLocal"
            highlight.Parent = pad
            pads[i] = pad
        end

        local metrics, audited = VisualBudgetRules.collect(root)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(6)
        expect(audited).toBe(3)

        -- Late marker removal immediately excludes a pad from local budget
        -- without confusing server-owned VFX with local ownership.
        pads[1]:SetAttribute("ArenaMobilityPad", false)
        metrics, audited = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(4)
        expect(audited).toBe(2)

        pads[2]:FindFirstChild("LocalMobilityVfx"):Destroy()
        metrics, audited = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(3)
        expect(audited).toBe(2)

        pads[3]:Destroy()
        metrics, audited = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(1)
        expect(audited).toBe(1)

        pads[2]:FindFirstChild("MobilityPadHighlightLocal"):Destroy()
        metrics, audited = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(0)
        expect(audited).toBe(0)
        root:Destroy()
    end)

    it("counts four client practice-pad emitters and highlights nested under the lobby", function()
        local root = Instance.new("Folder")
        local generated = Instance.new("Folder")
        generated.Name = "GeneratedMap"
        generated.Parent = root
        local lobby = Instance.new("Folder")
        lobby.Name = "Lobby"
        lobby.Parent = generated
        local activities = Instance.new("Folder")
        activities.Name = "Activities"
        activities.Parent = lobby
        local pads, bundles = {}, {}

        for i = 1, 4 do
            local pad = Instance.new("Part")
            pad.Name = "PracticeBoostPad" .. i
            pad:SetAttribute("LobbyPracticePad", true)
            pad.Parent = activities
            local serverLight = Instance.new("PointLight")
            serverLight.Parent = pad
            local bundle = LobbyPracticeVisualKit.create(pad)
            expect(bundle ~= nil).toBe(true)
            pads[#pads + 1] = pad
            bundles[#bundles + 1] = bundle
        end
        -- A server-owned unrelated effect must not consume the local
        -- budget merely because it happens to be under a lobby pad.
        local unrelated = Instance.new("ParticleEmitter")
        unrelated.Name = "ServerDecorEffect"
        unrelated.Parent = pads[1]

        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(4)
        expect(metrics.Effects).toBe(8) -- emitter + highlight per pad
        expect(metrics.Lights).toBe(0) -- server-owned PointLight excluded
        expect(metrics.Parts).toBe(0) -- server-owned pads excluded
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)

        LobbyPracticeVisualKit.destroy(bundles[4])
        metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(3)
        expect(metrics.Effects).toBe(6)
        LobbyPracticeVisualKit.destroy(bundles[3])
        LobbyPracticeVisualKit.destroy(bundles[2])
        LobbyPracticeVisualKit.destroy(bundles[1])
        metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(0)
        expect(metrics.Effects).toBe(0)
        root:Destroy()
    end)

    it("counts new directional practice glyphs within existing local LOD budgets", function()
        local root = Instance.new("Folder")
        local generated = Instance.new("Folder")
        generated.Name = "GeneratedMap"
        generated.Parent = root
        local lobby = Instance.new("Folder")
        lobby.Name = "Lobby"
        lobby.Parent = generated
        local activities = Instance.new("Folder")
        activities.Name = "Activities"
        activities.Parent = lobby
        local pad = Instance.new("Part")
        pad.Size = Vector3.new(7.2, 0.3, 7.2)
        pad:SetAttribute("LobbyPracticePad", true)
        pad.Parent = activities
        local bundle = LobbyPracticeVisualKit.create(pad)
        local glyphs = require("../../src/client/LobbyPracticeGlyphKit")
        local high = glyphs.build(bundle.folder, pad,
            "High", Vector3.new(0, 0, -150))
        expect(high ~= nil and #high:GetChildren() == 6).toBe(true)
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(1)
        expect(metrics.Parts).toBe(6)
        expect(metrics.Effects).toBe(2)
        high:Destroy()
        local low = glyphs.build(bundle.folder, pad,
            "Low", Vector3.new(0, 0, -150))
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Parts).toBe(2)
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)
        LobbyPracticeVisualKit.destroy(bundle)
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Effects).toBe(0)
        root:Destroy()
    end)

    it("audits avatar and solo-bot polish without server rig geometry", function()
        local root = Instance.new("Folder")
        local bots = Instance.new("Folder")
        bots.Name = "AISurvivors"
        bots.Parent = root
        local models = {}

        for index = 1, 3 do
            local model = Instance.new("Model")
            model.Name = index == 1 and "LivePlayerCharacter" or "SoloBot" .. index
            if index > 1 then model:SetAttribute("AISurvivor", true) end
            model.Parent = index == 1 and root or bots
            local torso = Instance.new("Part")
            torso.Name = "UpperTorso"
            torso.Parent = model
            local rootPart = Instance.new("Part")
            rootPart.Name = "HumanoidRootPart"
            rootPart.Parent = model
            local polish = Instance.new("Highlight")
            polish.Name = "ChaosCharacterPolishHighlight"
            polish.Parent = model
            local light = Instance.new("PointLight")
            light.Name = "ChaosCharacterPolishLight"
            light.Parent = torso
            local serverLight = Instance.new("PointLight")
            serverLight.Name = "ServerGameplayLight"
            serverLight.Parent = torso
            local serverAura = Instance.new("Highlight")
            serverAura.Name = "ServerGameplayAura"
            serverAura.Parent = model
            models[index] = {model = model, light = light}
        end

        -- The visual audit counts allocated Instances even when a quality
        -- tier temporarily disables a cosmetic; no hidden GPU allocations.
        models[3].light.Enabled = false
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(0)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Lights).toBe(3)
        expect(metrics.Effects).toBe(3)
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)

        -- An unrelated nested map rig is not owned by the character polish
        -- client controller and must not enter its budget accounting.
        local unrelatedFolder = Instance.new("Folder")
        unrelatedFolder.Parent = root
        local unrelated = Instance.new("Model")
        unrelated.Parent = unrelatedFolder
        Instance.new("Highlight").Parent = unrelated
        local unrelatedLight = Instance.new("PointLight")
        unrelatedLight.Name = "ChaosCharacterPolishLight"
        unrelatedLight.Parent = unrelated
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Lights).toBe(3)
        expect(metrics.Effects).toBe(3)

        models[2].model:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Lights).toBe(2)
        expect(metrics.Effects).toBe(2)
        models[1].model:Destroy()
        models[3].model:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        root:Destroy()
    end)

    it("counts temporary Phase Dash ribbons on actual avatar roots", function()
        local root = Instance.new("Folder")
        local player = Instance.new("Model")
        player.Name = "PlayerCharacter"
        player.Parent = root
        local hrp = Instance.new("Part")
        hrp.Name = "HumanoidRootPart"
        hrp.Parent = player

        local ribbon = Instance.new("Trail")
        ribbon.Name = "PhaseDashRibbon"
        ribbon.Parent = hrp
        local orphan = Instance.new("Trail")
        orphan.Name = "PhaseDashRibbon"
        orphan.Parent = hrp
        orphan.Enabled = false

        local unrelated = Instance.new("Trail")
        unrelated.Name = "ServerCharacterTrail"
        unrelated.Parent = hrp
        local wrongType = Instance.new("Part")
        wrongType.Name = "PhaseDashRibbon"
        wrongType.Parent = hrp
        local torso = Instance.new("Part")
        torso.Name = "UpperTorso"
        torso.Parent = player
        local wrongParent = Instance.new("Trail")
        wrongParent.Name = "PhaseDashRibbon"
        wrongParent.Parent = torso

        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(0)
        expect(metrics.Effects).toBe(2)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Lights).toBe(0)
        ribbon:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(1)

        -- Phase Dash does not normally run for bots, but the client-only
        -- accounting must also track a named ribbon on any streamed model.
        local bots = Instance.new("Folder")
        bots.Name = "AISurvivors"
        bots.Parent = root
        player.Parent = bots
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(1)
        orphan:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(0)
        root:Destroy()
    end)

    it("counts human motion ribbons and hazard reaction beams on avatar roots", function()
        local root = Instance.new("Folder")
        local model = Instance.new("Model")
        model.Name = "RealCharacter"
        model.Parent = root
        local hrp = Instance.new("Part")
        hrp.Name = "HumanoidRootPart"
        hrp.Parent = model

        local names = {
            "ChaosMotionTrail", "PhaseDashRibbon",
            "ChaosReactionDodge", "ChaosReactionShock",
            "ChaosReactionLanding",
        }
        local effects = {}
        for _, name in ipairs(names) do
            local effect = Instance.new(
                (name == "ChaosMotionTrail" or name == "PhaseDashRibbon")
                    and "Trail" or "Beam"
            )
            effect.Name = name
            effect.Enabled = name ~= "ChaosReactionShock"
            effect.Parent = hrp
            effects[#effects + 1] = effect
        end
        local excludedServerTrail = Instance.new("Trail")
        excludedServerTrail.Name = "AISurvivorCosmeticTrail"
        excludedServerTrail.Parent = hrp
        local fake = Instance.new("Part")
        fake.Name = "ChaosReactionShock"
        fake.Parent = hrp
        local unrelated = Instance.new("Beam")
        unrelated.Name = "ServerExplosionBeam"
        unrelated.Parent = hrp
        local wrongParent = Instance.new("Beam")
        wrongParent.Name = "ChaosReactionLanding"
        wrongParent.Parent = model

        local bots = Instance.new("Folder")
        bots.Name = "AISurvivors"
        bots.Parent = root
        local bot = Instance.new("Model")
        bot:SetAttribute("AISurvivor", true)
        bot.Parent = bots
        local botRoot = Instance.new("Part")
        botRoot.Name = "HumanoidRootPart"
        botRoot.Parent = bot
        local botShock = Instance.new("Beam")
        botShock.Name = "ChaosReactionShock"
        botShock.Parent = botRoot

        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(0)
        expect(metrics.Effects).toBe(6)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Lights).toBe(0)
        effects[2]:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(5)
        bot:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(4)
        model:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(0)
        root:Destroy()
    end)

    it("counts duplicate orphan polish lights as actual allocated lights", function()
        local root = Instance.new("Folder")
        local model = Instance.new("Model")
        model.Parent = root
        local torso = Instance.new("Part")
        torso.Parent = model
        for _ = 1, 3 do
            local light = Instance.new("PointLight")
            light.Name = "ChaosCharacterPolishLight"
            light.Parent = torso
        end
        local metrics = VisualBudgetRules.collect(root)
        expect(metrics.Lights).toBe(3)
        expect(metrics.Parts).toBe(0)
        root:Destroy()
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

    it("counts at most one transient High-tier Skyrail impulse flare", function()
        local root = Instance.new("Folder")
        local skyrail = Instance.new("Folder")
        skyrail.Name = "TowerSkyrailLocal"
        skyrail.Parent = root
        -- 48 authored structure/courier parts + 8 one-shot shards.
        for index = 1, 56 do
            local part = Instance.new("Part")
            part.Name = "TowerSkyrailLocal" .. index
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Parent = skyrail
        end
        local metrics = VisualBudgetRules.collect(root)
        expect(metrics.Parts).toBe(56)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("High", metrics)).toBe(true)
        root:Destroy()
    end)

    it("budgets noncolliding Tower Skyrail conductor structures and couriers", function()
        local folder = Instance.new("Folder")
        local skyrail = Instance.new("Folder")
        skyrail.Name = "TowerSkyrailLocal"
        skyrail.Parent = folder
        -- Maximum authored High tier: 2 pillars + 2 inset fibers +
        -- 2 counterweights + 1 header + 1 crown + 2 wings + 2 runners
        -- = 12 parts per bridge / 48 for all four bridges.
        for index = 1, 48 do
            local piece = Instance.new("Part")
            piece.Name = "Skyrail" .. index
            piece.CanCollide = false
            piece.Parent = skyrail
        end
        local metrics, counted = VisualBudgetRules.collect(folder)
        expect(counted).toBe(1)
        expect(metrics.Parts).toBe(48)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("High", metrics)).toBe(true)
        folder:Destroy()
    end)

    it("includes all four detailed Classic Grid Circuit monuments in visual telemetry", function()
        local root = Instance.new("Folder")
        local circuit = Instance.new("Folder")
        circuit.Name = "GridCircuitLocal"
        circuit.Parent = root
        -- High tier: 25 parts per monument (100 total), plus
        -- 3 chevrons * 2 strokes * 4 route edges = 24 guide parts.
        for index = 1, 124 do
            local piece = Instance.new("Part")
            piece.Name = "CircuitArt" .. index
            piece.CanCollide = false
            piece.Parent = circuit
        end
        local metrics, count = VisualBudgetRules.collect(root)
        expect(count).toBe(1)
        expect(metrics.Parts).toBe(124)
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

    it("counts client lava light and hazard-attached particles without server shell parts", function()
        local root = Instance.new("Folder")
        local lava = Instance.new("Part")
        lava.Name = "RoundLava"
        lava.Parent = root
        local glow = Instance.new("SurfaceLight")
        glow.Name = "LavaGlowLocal"
        glow.Parent = lava
        local heat = Instance.new("Attachment")
        heat.Name = "LavaHeatLocal"
        heat.Parent = lava
        local embers = Instance.new("ParticleEmitter")
        embers.Name = "LavaEmbers"
        embers.Parent = heat
        local freeze = Instance.new("Part")
        freeze.Name = "FreezeWarning"
        freeze.Parent = root
        local mist = Instance.new("Attachment")
        mist.Name = "FreezeMistLocal"
        mist.Parent = freeze
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "FreezeMist"
        emitter.Parent = mist
        -- Unrelated server-authored and wrongly parented objects do not count.
        local serverLamp = Instance.new("SurfaceLight")
        serverLamp.Name = "AuthoritativeHazardLight"
        serverLamp.Parent = lava
        local wrongType = Instance.new("Part")
        wrongType.Name = "LavaGlowLocal"
        wrongType.Parent = lava
        local fake = Instance.new("Part")
        fake.Name = "RoundLava"
        fake.Parent = root
        Instance.new("SurfaceLight").Parent = fake
        local metrics, folders = VisualBudgetRules.collect(root)
        expect(folders).toBe(0)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Lights).toBe(1)
        expect(metrics.Effects).toBe(2)
        glow:Destroy()
        embers:Destroy()
        emitter:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
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


describe("Android decorative scenery LOD stability", function()
    it("keeps floating arena supports underneath a shrinking collision floor", function()
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Anchored = true
        base.Size = Vector3.new(100, 2, 80)
        base.CFrame = CFrame.new(35, 12, -20)
        base.Parent = workspace

        local decor = Instance.new("Folder")
        decor.Name = "ArenaUnderstructureLocal"
        decor.Parent = workspace

        local support = Instance.new("Part")
        support.Size = Vector3.new(3, 12, 3)
        support.CFrame = base.CFrame * CFrame.new(32, -7, 24)
        support.Anchored = true
        support.CanCollide = false
        support.Parent = decor

        local beam = Instance.new("Part")
        beam.Size = Vector3.new(55, 0.8, 2)
        beam.CFrame = base.CFrame * CFrame.new(0, -2.5, -24)
        beam.Anchored = true
        beam.Parent = decor

        local snapshot = ArenaFloorFollowerKit.capture(base, decor)
        expect(snapshot ~= nil).toBe(true)
        base.Size = Vector3.new(45, 2, 36)
        expect(ArenaFloorFollowerKit.apply(snapshot)).toBe(2)
        expect(math.abs(support.Position.X - (35 + 32 * 0.45)) < 0.001).toBe(true)
        expect(math.abs(support.Position.Z - (-20 + 24 * 0.45)) < 0.001).toBe(true)
        expect(math.abs(support.Position.Y - 5) < 0.001).toBe(true)
        expect(math.abs(beam.Size.X - 55 * 0.45) < 0.001).toBe(true)
        expect(math.abs(beam.Size.Y - 0.8) < 0.001).toBe(true)

        base.Size = Vector3.new(100, 2, 80)
        expect(ArenaFloorFollowerKit.apply(snapshot)).toBe(2)
        expect(math.abs(support.Position.X - 67) < 0.001).toBe(true)
        expect(math.abs(support.Position.Z - 4) < 0.001).toBe(true)
        expect(math.abs(beam.Size.X - 55) < 0.001).toBe(true)

        decor:Destroy()
        base:Destroy()
    end)


    it("locates nested pad cosmetics but never server-owned lobby scenery", function()
        local root = Instance.new("Folder")
        expect(#SceneryLodRules.practicePadVisualOwners(root)).toBe(0)
        expect(#SceneryLodRules.practicePadVisualOwners(nil)).toBe(0)
        local generated = Instance.new("Folder")
        generated.Name = "GeneratedMap"
        generated.Parent = root
        local lobby = Instance.new("Folder")
        lobby.Name = "Lobby"
        lobby.Parent = generated
        local activities = Instance.new("Folder")
        activities.Name = "Activities"
        activities.Parent = lobby

        local pads = {}
        for i = 1, 4 do
            local pad = Instance.new("Part")
            pad.Name = "PracticeBoostPad" .. i
            pad:SetAttribute("LobbyPracticePad", true)
            pad.Parent = activities
            local light = Instance.new("PointLight")
            light.Name = "PracticePadLight"
            light.Parent = pad
            pads[i] = pad
            expect(LobbyPracticeVisualKit.create(pad) ~= nil).toBe(true)
        end
        local serverDecoration = Instance.new("ParticleEmitter")
        serverDecoration.Name = "ServerDecorMotes"
        serverDecoration.Parent = pads[1]

        local owners = SceneryLodRules.practicePadVisualOwners(root)
        expect(#owners).toBe(8)
        local unique = {}
        local highlightContainers, emitterContainers = 0, 0
        for _, owner in ipairs(owners) do
            expect(unique[owner] == nil).toBe(true)
            unique[owner] = true
            expect(owner:IsDescendantOf(activities)).toBe(true)
            expect(owner:IsA("BasePart")).toBe(false)
            expect(owner:IsA("Light")).toBe(false)
            if owner.Name == "PracticePadPolishLocal" then
                expect(owner:IsA("Folder")).toBe(true)
                highlightContainers += 1
            elseif owner.Name == "PracticeMotesAttachment" then
                expect(owner:IsA("Attachment")).toBe(true)
                emitterContainers += 1
            else
                expect(false).toBe(true)
            end
        end
        expect(highlightContainers).toBe(4)
        expect(emitterContainers).toBe(4)
        expect(unique[serverDecoration] == nil).toBe(true)
        expect(SceneryLodRules.visible("Low", 150, 100, 150, nil))
            .toBe(false)
        expect(SceneryLodRules.visible("High", 1000, 100, 150, nil))
            .toBe(true)

        pads[4]:Destroy()
        expect(#SceneryLodRules.practicePadVisualOwners(root)).toBe(6)
        local stray = Instance.new("Part")
        stray.Name = "UnrelatedPad"
        stray.Parent = activities
        local decoy = Instance.new("Folder")
        decoy.Name = "PracticePadPolishLocal"
        decoy.Parent = stray
        expect(#SceneryLodRules.practicePadVisualOwners(root)).toBe(6)
        root:Destroy()
    end)

    it("preserves only marked original 3D silhouette pieces on Android Low", function()
        local partVisible = SceneryLodRules.entryVisible
        expect(partVisible("Low", false, true, true)).toBe(true)
        expect(partVisible("Low", false, true, false)).toBe(false)
        expect(partVisible("Low", false, false, true)).toBe(false)
        expect(partVisible("Medium", false, true, true)).toBe(false)
        expect(partVisible("High", false, true, true)).toBe(false)
        expect(partVisible("Medium", true, true, false)).toBe(true)
        expect(partVisible("High", true, false, false)).toBe(true)
        -- Unrelated gameplay/LOD groups cannot use the hero exception.
        expect(partVisible("Low", false, nil, true)).toBe(false)
        expect(partVisible("Low", nil, true, false)).toBe(false)
    end)

    it("retains initial thresholds and never hides High quality scenery", function()
        local visible = SceneryLodRules.visible
        expect(visible("Low", 125, 125, 185, nil)).toBe(true)
        expect(visible("Low", 125.01, 125, 185, nil)).toBe(false)
        expect(visible("Medium", 185, 125, 185, nil)).toBe(true)
        expect(visible("Medium", 185.01, 125, 185, nil)).toBe(false)
        expect(visible("High", 10000, 125, 185, nil)).toBe(true)
        expect(visible("High", math.huge, 125, 185, false)).toBe(true)
    end)

    it("prevents toggling when a camera grazes an LOD distance cutoff", function()
        local show = SceneryLodRules.visible
        expect(SceneryLodRules.Hysteresis).toBe(8)
        for _, tier in ipairs({"Low", "Medium"}) do
            local cutoff = tier == "Low" and 125 or 185
            expect(show(tier, cutoff + 5, 125, 185, true)).toBe(true)
            expect(show(tier, cutoff + 9, 125, 185, true)).toBe(false)
            expect(show(tier, cutoff - 5, 125, 185, false)).toBe(false)
            expect(show(tier, cutoff - 9, 125, 185, false)).toBe(true)
        end
    end)

    it("fails closed for invalid mobile distance measurements", function()
        local show = SceneryLodRules.visible
        expect(show("Low", -1, 125, 185, true)).toBe(false)
        expect(show("Low", 0/0, 125, 185, true)).toBe(false)
        expect(show("Low", math.huge, 125, 185, false)).toBe(false)
        expect(show("Medium", "near", 125, 185, nil)).toBe(false)
        expect(show("Medium", 20, 0, 185, nil)).toBe(true)
        expect(show("Low", 20, 0, 185, nil)).toBe(false)
    end)
end)

return nil
