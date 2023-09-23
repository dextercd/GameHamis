local settings = dofile_once("mods/GameHamis/utils/settings.lua")

ModLuaFileAppend("data/scripts/gun/gun_actions.lua", "mods/GameHamis/gun_actions.lua")
ModLuaFileAppend("data/scripts/item_spawnlists.lua", "mods/GameHamis/item_spawnlists.lua")

function OnPausedChanged(paused, inventory_pause)
    -- Settings might have changed
    settings.load_settings()
    GlobalsSetValue("GameHamis.copyright_notices", settings.get("copyright_notices") and "1" or "0")
end

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
