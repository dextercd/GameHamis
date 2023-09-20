local gaming_effect

function remove_effect(e)
    for _, child in ipairs(EntityGetAllChildren(e) or {}) do
        if EntityGetName(child) == "gh_gaming" then
            local c = EntityGetFirstComponentIncludingDisabled(child, "GameEffectComponent")
            if c then
                ComponentSetValue2(c, "frames", 0)
            end
        end
    end
end

function enabled_changed(e, enabled)
    local player = EntityGetRootEntity(e)
    if enabled then
        if player ~= e then
            LoadGameEffectEntityTo(player, "mods/GameHamis/entities/effect_gaming.xml")
        end
    else
        remove_effect(player)
    end
end
