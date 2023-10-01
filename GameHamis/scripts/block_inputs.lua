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
    local root = EntityGetRootEntity(e)
    local is_player = EntityHasTag(root, "player_unit") or EntityHasTag(root, "polymorphed_player")

    if not is_player then
        return
    end

    if enabled then
        if root ~= e then
            LoadGameEffectEntityTo(root, "mods/GameHamis/entities/effect_gaming.xml")
        end
    else
        remove_effect(root)
    end
end
