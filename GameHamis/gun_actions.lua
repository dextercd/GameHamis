dofile("mods/GameHamis/cartridges.lua")

for _, cartridge in ipairs(cartridges) do

    table.insert(actions, {
        id = "GAMEHAMIS_CARTRIDGE_" .. cartridge.name:upper(),
        name = cartridge.name,
        description = "Cartridge for the GameHämis handheld console. Don't put this on a wand you weirdo.",
        type = ACTION_TYPE_MODIFIER,
        spawn_level = "0",
        spawn_probability = "0",
        mana = 0,
        action = function()
            if not reflecting then
                add_projectile("data/entities/projectiles/deck/explosion.xml")
                c.fire_rate_wait = c.fire_rate_wait + 3
                c.screenshake = c.screenshake + 2.5
            end
        end
    })

end
