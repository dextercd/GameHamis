dofile("data/scripts/lib/mod_settings.lua")

local mod_id = "GameHamis"
mod_settings_version = 1
mod_settings =
{
    {
        id = "copyright_notices",
        ui_name = "Copyright Notices",
        ui_description = "Display copyright notices next to the GameHämis",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
}

function ModSettingsUpdate(init_scope)
    mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui( gui, in_main_menu )
    mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
