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

function vsc_util.get_or_create(entity_id, name)
    local vsc = vsc_util.get(entity_id, name)
    if not vsc then
        vsc = EntityAddComponent2(entity_id, "VariableStorageComponent", {name=name})
    end
    return vsc
end

function vsc_util.getstr(entity_id, name)
    local vsc = vsc_util.get(entity_id, name)
    if not vsc then
        return nil
    end

    return ComponentGetValue2(vsc, "value_string")
end

function vsc_util.setstr(entity_id, name, str)
    local vsc = vsc_util.get_or_create(entity_id, name)
    ComponentSetValue2(vsc, "value_string", str)
end

return vsc_util
