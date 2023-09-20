dofile("mods/GameHamis/cartridges.lua")

function init(entity_id)
    local x,y = EntityGetTransform(entity_id)
    SetRandomSeed(x, y)

    local cartridge = cartridges[Random(1, #cartridges)]

    local entity = GetUpdatedEntityID()
    local item = EntityGetFirstComponent(entity, "ItemComponent")
    ComponentSetValue2(item, "item_name", cartridge.name)

    local path_vsc = EntityGetFirstComponent(entity, "VariableStorageComponent")
    ComponentSetValue2(path_vsc, "value_string", cartridge.path)

    local item_action = EntityGetFirstComponent(entity, "ItemActionComponent")
    ComponentSetValue2(item_action, "action_id", "GAMEHAMIS_CARTRIDGE_" .. cartridge.name:upper())
end
