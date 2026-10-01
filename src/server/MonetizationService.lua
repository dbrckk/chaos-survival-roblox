local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local PlayerReadiness = require(script.Parent.PlayerReadiness)

local GameAnalytics = require(script.Parent.GameAnalytics)

local MonetizationService = {}

local offers = {
    {
        key = "supporter",
        idAttribute = "SupporterPassId",
        cosmeticId = "aura_supporter",
        fallbackName = "Founder Supporter",
    },
    {
        key = "neon_pack",
        idAttribute = "NeonPackPassId",
        cosmeticId = "trail_neon",
        fallbackName = "Hyper Neon Pack",
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
        cosmeticId = offer.cosmeticId,
    }
end

local function grantOwnedPasses(player)
    if not cosmeticService then
        return
    end

    for _, offer in ipairs(offers) do
        local passId = configuredPassId(offer)
        if passId and ownsPass(player, passId) then
            cosmeticService.grant(player, offer.cosmeticId)
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

    return {
        offers = result,
        enabled = #result > 0,
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

    stateEvent = remotes:FindFirstChild("MonetizationState") or Instance.new("RemoteEvent")
    stateEvent.Name = "MonetizationState"
    stateEvent.Parent = remotes

    actionEvent = remotes:FindFirstChild("MonetizationAction") or Instance.new("RemoteEvent")
    actionEvent.Name = "MonetizationAction"
    actionEvent.Parent = remotes

    local allowAction = rateLimiterFactory.new(0.75)

    actionEvent.OnServerEvent:Connect(function(player, action, key)
        if player.Parent ~= Players or player:GetAttribute("DataLoaded") ~= true then
            return
        end

        if not allowAction(player.UserId) then
            return
        end

        if action == "sync" then
            sendState(player)
            return
        end

        if action ~= "buy_pass" or type(key) ~= "string" then
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
            cosmeticService.grant(player, offer.cosmeticId)
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

        for _, offer in ipairs(offers) do
            local passId = configuredPassId(offer)
            if passId and passId == purchasedPassId then
                cosmeticService.grant(player, offer.cosmeticId)
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
