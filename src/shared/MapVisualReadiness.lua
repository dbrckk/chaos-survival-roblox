-- Watch dynamic Roblox map sections without relying on replication order.
-- A model can arrive before its Base/Floor part or variant attributes.
local MapVisualReadiness = {}

function MapVisualReadiness.part(generated, sectionName, partName)
    local section = generated and generated:FindFirstChild(sectionName)
    local part = section and section:FindFirstChild(partName)
    return part and part:IsA("BasePart") and part or nil
end

function MapVisualReadiness.watch(generated, sectionName, partName, onChange)
    assert(generated ~= nil and type(onChange) == "function",
        "MapVisualReadiness.watch needs a map and callback")
    local connections = {}
    local sectionConnections = {}
    local currentSection = nil
    local alive = true

    local function emit()
        if alive then
            onChange(MapVisualReadiness.part(generated, sectionName, partName))
        end
    end

    local function bindSection(section)
        for _, connection in ipairs(sectionConnections) do
            connection:Disconnect()
        end
        table.clear(sectionConnections)
        currentSection = section
        if section then
            table.insert(sectionConnections, section.ChildAdded:Connect(function(child)
                if child.Name == partName then
                    emit()
                end
            end))
            table.insert(sectionConnections, section.ChildRemoved:Connect(function(child)
                if child.Name == partName then
                    emit()
                end
            end))
            -- VariantId can replicate after the initial arena parts.
            if sectionName == "Arena" then
                table.insert(sectionConnections,
                    section:GetAttributeChangedSignal("VariantId"):Connect(emit))
            end
        end
        emit()
    end

    table.insert(connections, generated.ChildAdded:Connect(function(child)
        if child.Name == sectionName then
            bindSection(child)
        end
    end))
    table.insert(connections, generated.ChildRemoved:Connect(function(child)
        if child == currentSection then
            bindSection(generated:FindFirstChild(sectionName))
        end
    end))
    bindSection(generated:FindFirstChild(sectionName))

    return function()
        alive = false
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        for _, connection in ipairs(sectionConnections) do
            connection:Disconnect()
        end
        table.clear(connections)
        table.clear(sectionConnections)
        currentSection = nil
    end
end

return MapVisualReadiness
