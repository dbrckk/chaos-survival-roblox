local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local MonetizationRules = require(script.Parent.MonetizationRules)
local RemoteRegistry = require(script.Parent.RemoteRegistry)

local PlayerReadiness = require(script.Parent.PlayerReadiness)
local PlayerData = require(script.Parent.PlayerData)

local GameAnalytics = require(script.Parent.GameAnalytics)

local MonetizationService = {}

local setupStarted = setmetatable({}, {__mode = "k"})

local offers = {
    {
        key = "supporter",
        idAttribute = "SupporterPassId",
        cosmeticIds = {"aura_supporter", "trail_founder"},
        fallbackName = "Founder Supporter Set",
        tagline = "FOUNDER AURA + COMET TRAIL • PERMANENT",
    },
    {
        key = "neon_pack",
        idAttribute = "NeonPackPassId",
        cosmeticIds = {"trail_neon", "aura_neon"},
        fallbackName = "Hyper Neon Set",
        tagline = "NEON TRAIL + HALO • PERMANENT",
    },
}

local stateEvent
local actionEvent
local cosmeticService

local function configuredPassId(offer)
    local id = tonumber(game:GetAttribute(offer.idAttribute))
    if not id or id <= 0 then
        return nil
    end
    return math.floor(id)
end

local function ownsPass(player, passId)
    local ok, result = pcall(
        MarketplaceService.UserOwnsGamePassAsync,
        MarketplaceService,
        player.UserId,
        passId
    )
    return ok and result == true
end

local function publicOffer(player, offer)
    local passId = configuredPassId(offer)
    if not passId then
        return nil
    end

    local info
    local ok = pcall(function()
        info = MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass)
    end)

    if not ok or type(info) ~= "table" then
        return nil
    end

    return {
        key = offer.key,
        name = tostring(info.Name or offer.fallbackName),
        price = math.max(0, tonumber(info.PriceInRobux) or 0),
        owned = ownsPass(player, passId),
        cosmeticIds = table.clone(offer.cosmeticIds or {}),
        itemCount = #(offer.cosmeticIds or {}),
        tagline = offer.tagline,
    }
end

local function grantOffer(player, offer)
    if not cosmeticService then
        return
    end

    for _, cosmeticId in ipairs(offer.cosmeticIds or {}) do
        cosmeticService.grant(player, cosmeticId)
    end
end

local function grantOwnedPasses(player)
    if not cosmeticService then
        return
    end

    for _, offer in ipairs(offers) do
        local passId = configuredPassId(offer)
        if passId and ownsPass(player, passId) then
            grantOffer(player, offer)
        end
    end
end

local function stateFor(player)
    local result = {}
    for _, offer in ipairs(offers) do
        local item = publicOffer(player, offer)
        if item then
            table.insert(result, item)
        end
    end

    local dataAvailable = PlayerData.canMutate(player)
    return {
        offers = result,
        enabled = MonetizationRules.offersEnabled(dataAvailable, #result),
        dataAvailable = dataAvailable,
        fairPlay = "COSMETIC ONLY • NO GAMEPLAY ADVANTAGE",
    }
end

local function sendState(player, notice)
    if stateEvent then
        stateEvent:FireClient(player, {
            state = stateFor(player),
            notice = notice,
        })
    end
end

local function offerForKey(key)
    for _, offer in ipairs(offers) do
        if offer.key == key then
            return offer
        end
    end
    return nil
end

local function setupPlayer(player)
    if setupStarted[player] then
        return
    end
    setupStarted[player] = true
    task.spawn(function()
        if not PlayerReadiness.waitForDataLoaded(player) then
            return
        end

        grantOwnedPasses(player)
        sendState(player)
    end)
end

function MonetizationService.init(remotes, rateLimiterFactory, cosmetics)
    cosmeticService = cosmetics

    stateEvent = RemoteRegistry.ensureRemoteEvent(remotes, "MonetizationState")
    actionEvent = RemoteRegistry.ensureRemoteEvent(remotes, "MonetizationAction")

    local allowAction = rateLimiterFactory.new(0.75)
    local allowSync = rateLimiterFactory.new(1.0)

    actionEvent.OnServerEvent:Connect(function(player, action, key)
        if player.Parent ~= Players or player:GetAttribute("DataLoaded") ~= true then
            return
        end

        if action == "sync" then
            if allowSync(player.UserId) then
                sendState(player)
            end
            return
        end

        if not allowAction(player.UserId) then
            return
        end

        if action ~= "buy_pass" or type(key) ~= "string" then
            return
        end

        if not PlayerData.canMutate(player) then
            sendState(player, "data_unavailable")
            return
        end

        local offer = offerForKey(key)
        if not offer then
            return
        end

        local passId = configuredPassId(offer)
        if not passId then
            return
        end

        if ownsPass(player, passId) then
            grantOffer(player, offer)
            sendState(player, "already_owned")
            return
        end

        GameAnalytics.custom(
            player,
            "PremiumPromptOpened",
            1,
            "Offer:" .. key,
            "CosmeticOnly:true"
        )

        MarketplaceService:PromptGamePassPurchase(player, passId)
    end)

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, purchasedPassId, purchaseSuccess)
        if not purchaseSuccess or player.Parent ~= Players then
            return
        end

        if not PlayerReadiness.waitForDataLoaded(player) then
            return
        end

        if not PlayerData.canMutate(player) then
            sendState(player, "data_unavailable")
            return
        end

        for _, offer in ipairs(offers) do
            local passId = configuredPassId(offer)
            if passId and passId == purchasedPassId then
                grantOffer(player, offer)
                sendState(player, "purchase_complete")
                GameAnalytics.custom(
                    player,
                    "PremiumPurchaseCompleted",
                    1,
                    "Offer:" .. offer.key,
                    "CosmeticOnly:true"
                )
                break
            end
        end
    end)

    Players.PlayerAdded:Connect(setupPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayer(player)
    end
end

return MonetizationService
