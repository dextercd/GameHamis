local settings = {}


local mod_id = "GameHamis"
local cached_settings = {}

local function load_setting_value(key)
    local full_key = mod_id .. "." .. key
    local value = ModSettingGet(full_key)

    -- Seems like 'value_default=false' gets turned into nil by Noita
    if value == nil then
        return false
    end

    return value
end

function settings.load_settings()
    cached_settings = {}
end

function settings.get(key)
    if cached_settings[key] == nil then
        cached_settings[key] = load_setting_value(key)
    end

    return cached_settings[key]
end

function settings.set(key, value)
    ModSettingSet(mod_id .. "." .. key, value)
    cached_settings[key] = value
end

return settings
