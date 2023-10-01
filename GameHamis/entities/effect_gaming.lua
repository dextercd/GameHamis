local root = EntityGetRootEntity(GetUpdatedEntityID())
if EntityHasTag(root, "player_unit") or EntityHasTag(root, "polymorphed_player") then
    local c = EntityGetFirstComponent(root, "ControlsComponent")
    if c then
        ComponentSetValue2(c, "enabled", true)
    end
end
