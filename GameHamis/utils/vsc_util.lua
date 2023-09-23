local vsc_util = {}

function vsc_util.get(entity_id, name)
    local components = EntityGetComponentIncludingDisabled(entity_id, "VariableStorageComponent")
    if components ~= nil then
        for _,comp_id in ipairs(components) do
            if ComponentGetValue2(comp_id, "name") == name then
                return comp_id
            end
        end
    end

    return nil
end

function vsc_util.getstr(entity_id, name)
    local vsc = vsc_util.get(entity_id, name)
    if not vsc then
        return nil
    end

    return ComponentGetValue2(vsc, "value_string")
end

return vsc_util
