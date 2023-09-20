ModLuaFileAppend("data/scripts/gun/gun_actions.lua", "mods/GameHamis/gun_actions.lua")
ModLuaFileAppend("data/scripts/item_spawnlists.lua", "mods/GameHamis/item_spawnlists.lua")

function OnPlayerSpawned()
    if GameHasFlagRun("gamehamis_init") then return end
    GameAddFlagRun("gamehamis_init")

    local console = EntityLoad("mods/GameHamis/items/gameboy.xml", 610, -85)
    local cartridge = EntityLoad("mods/GameHamis/items/cartridge.xml", 610, -85)

    EntityAddChild(console, cartridge)
    for _, c in ipairs(EntityGetAllComponents(cartridge)) do
        EntitySetComponentIsEnabled(cartridge, c, false)
    end
end
