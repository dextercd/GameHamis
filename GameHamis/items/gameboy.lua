local base64 = dofile("mods/GameHamis/base64.lua")

local cartridge_path = nil
local function has_cartridge()
    return cartridge_path ~= nil
end

local core = dofile("mods/GameHamis/core.lua")

function reset()
    for i=0,core.memory._len-1 do
        core.memory:write8(i, 0)
    end
    core.init()
end
reset()

local frame_location = core.globals[core.exports.FRAME_LOCATION]

function pixel_addr(x, y)
    return frame_location + ((y * 160) + x) * 3
end

function getrgb(x, y)
    local location = pixel_addr(x, y)
    local r = core.memory:read8(location)
    local g = core.memory:read8(location + 1)
    local b = core.memory:read8(location + 2)
    return r, g, b
end

gui = GuiCreate()

local gui_up = false
local gui_down = false
local gui_left = false
local gui_right = false

local gui_a = false
local gui_b = false

local gui_select = false
local gui_start = false

local screen_pixels_width = 160
local screen_pixels_height = 144

local text_offset_y = -7
local offset_x = 200
local offset_y = 50

local screen_offset_x = 28
local screen_offset_y = 21

function draw()
    GuiZSet(gui, -10000)
    GuiImage(gui, 100, offset_x, offset_y, "mods/GameHamis/ui/device.png", 1, 1, 1)

    GuiZSet(gui, -10050)
    gui_up = GuiImageButton(gui, 101, offset_x + 28, offset_y + 212, "", "mods/GameHamis/ui/up.png")
    gui_down = GuiImageButton(gui, 102, offset_x + 28, offset_y + 234, "", "mods/GameHamis/ui/down.png")
    gui_left = GuiImageButton(gui, 103, offset_x + 12, offset_y + 228, "", "mods/GameHamis/ui/left.png")
    gui_right = GuiImageButton(gui, 104, offset_x + 34, offset_y + 228, "", "mods/GameHamis/ui/right.png")

    gui_a = GuiImageButton(gui, 105, offset_x + 185, offset_y + 218, "", "mods/GameHamis/ui/a.png")
    gui_b = GuiImageButton(gui, 106, offset_x + 155, offset_y + 227, "", "mods/GameHamis/ui/b.png")

    gui_select = GuiImageButton(gui, 107, offset_x + 83, offset_y + 275, "", "mods/GameHamis/ui/c.png")
    gui_start = GuiImageButton(gui, 108, offset_x + 113, offset_y + 275, "", "mods/GameHamis/ui/c.png")

    if not has_cartridge() then
        return
    end

    GuiZSet(gui, -10100)

    for y=0,screen_pixels_height-1 do
        for x=0,screen_pixels_width-1 do
            local r,g,b = getrgb(x, y)
            GuiColorSetForNextWidget(gui, r/255, g/255, b/255, 1)
            GuiText(gui, x + offset_x + screen_offset_x, y + offset_y + text_offset_y + screen_offset_y, ".")
        end
    end
end

function handle_inputs(controls)
    core.exports.setJoypadState(
        (gui_up or ComponentGetValue2(controls, "mButtonDownUp")) and 1 or 0,
        (gui_right or ComponentGetValue2(controls, "mButtonDownRight")) and 1 or 0,
        (gui_down or ComponentGetValue2(controls, "mButtonDownDown")) and 1 or 0,
        (gui_left or ComponentGetValue2(controls, "mButtonDownLeft")) and 1 or 0,
        (gui_a or ComponentGetValue2(controls, "mButtonDownKick")) and 1 or 0,
        (gui_b or ComponentGetValue2(controls, "mButtonDownInteract")) and 1 or 0,
        gui_select and 1 or 0,
        gui_start and 1 or 0
    )
end

function wake_up_waiting_threads()
    GuiStartFrame(gui)

    local e = GetUpdatedEntityID()
    local s = EntityGetFirstComponent(e, "SpriteComponent")

    if not s then return end

    local player = EntityGetRootEntity(e)

    local new_cartridge_path

    local cartridge_entity = (EntityGetAllChildren(e) or {})[1]
    if cartridge_entity then
        local vscs = EntityGetComponentIncludingDisabled(cartridge_entity, "VariableStorageComponent") or {}
        for _, vsc in ipairs(vscs) do
            if ComponentGetValue2(vsc, "name") == "cartridge_path" then
                new_cartridge_path = ComponentGetValue2(vsc, "value_string")
                break
            end
        end
    end

    if cartridge_path ~= new_cartridge_path then
        cartridge_path = new_cartridge_path
        if cartridge_path then
            reset()
            local cartridge_datab64 = ModTextFileGetContent(cartridge_path)
            local cartridge_data = base64.decode(cartridge_datab64)

            local cartridge_rom_addr = core.globals[core.exports.CARTRIDGE_ROM_LOCATION]
            for i=1,#cartridge_data do
                core.memory:write8(cartridge_rom_addr + i - 1, cartridge_data:byte(i, i))
            end

            core.exports.config(0,1,1,1,1,1,1,1,0,0)
        end
    end

    draw()
    core.exports.executeFrame()
    core.exports.clearAudioBuffer()

    local gh_gaming
    local controls
    for _, v in ipairs(EntityGetAllChildren(player) or {}) do
        if EntityGetName(v) == "gh_gaming" then
            gh_gaming = v
            controls = EntityGetFirstComponent(v, "ControlsComponent")
        end
    end

    if controls then
        handle_inputs(controls)
    end

    if controls then
        if GuiButton(gui, 109, offset_x + 220, offset_y, "Unfocus") then
            local ge = EntityGetFirstComponent(gh_gaming, "GameEffectComponent")
            ComponentSetValue2(ge, "frames", 0)
        end
    else
        if GuiButton(gui, 110, offset_x + 220, offset_y, "Focus") then
            LoadGameEffectEntityTo(player, "mods/GameHamis/entities/effect_gaming.xml")
        end
    end
end
