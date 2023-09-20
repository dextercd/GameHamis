local c = EntityGetFirstComponent(EntityGetRootEntity(GetUpdatedEntityID()), "ControlsComponent")
if c then
    ComponentSetValue2(c, "enabled", true)
end
