local DataSession = {}

DataSession.TokenKey = "__SessionToken"
DataSession.ClaimedAtKey = "__SessionClaimedAt"
DataSession.SavedAtKey = "__SessionSavedAt"

local function copyTable(source)
    local result = {}
    if type(source) == "table" then
        for key, value in pairs(source) do
            result[key] = value
        end
    end
    return result
end

function DataSession.claim(saved, token, claimedAt)
    local result = copyTable(saved)
    result[DataSession.TokenKey] = tostring(token or "")
    result[DataSession.ClaimedAtKey] = math.max(0, tonumber(claimedAt) or 0)
    return result
end

function DataSession.owns(saved, token)
    return type(saved) == "table"
        and type(token) == "string"
        and token ~= ""
        and saved[DataSession.TokenKey] == token
end

function DataSession.merge(saved, snapshot, token, savedAt)
    if not DataSession.owns(saved, token) then
        return nil
    end

    local result = copyTable(saved)
    for key, value in pairs(snapshot or {}) do
        result[key] = value
    end
    result[DataSession.TokenKey] = token
    result[DataSession.SavedAtKey] = math.max(0, tonumber(savedAt) or 0)
    return result
end

return DataSession
