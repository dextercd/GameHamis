local current_max = spawnlists.potion_spawnlist.rnd_max
local weight = 5
table.insert(spawnlists.potion_spawnlist.spawns,
    {
        value_min = current_max + 1,
        value_max = current_max + 1 + weight,
        load_entity = "mods/GameHamis/items/cartridge.xml",
        offset_y = -5,
    })
spawnlists.potion_spawnlist.rnd_max = spawnlists.potion_spawnlist.rnd_max + weight
