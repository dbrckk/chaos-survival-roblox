local MonetizationRules = {}

function MonetizationRules.offersEnabled(dataAvailable, offerCount)
    return dataAvailable == true
        and math.max(0, math.floor(tonumber(offerCount) or 0)) > 0
end

return MonetizationRules
