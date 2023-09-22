dofile_once("data/scripts/lib/utilities.lua")

local base64 = dofile("mods/GameHamis/base64.lua")

local cartridge_path = nil
local function has_cartridge()
    return cartridge_path ~= nil
end

function require(what)
    if what == "bit" then
        return bit
    end

    if what == "gameboy/audio" or what == "gameboy/graphics" or what == "gameboy/z80" then
        what = what .. "/init"
    end

    return dofile_once("mods/GameHamis/" .. what .. ".lua")
end

local GameBoy = dofile_once("mods/GameHamis/gameboy/init.lua")
local gameboy

function reset()
    gameboy = GameBoy.new{}
    gameboy:initialize()
    gameboy:reset()
end
reset()

local function getrgb(x, y)
    return unpack(gameboy.graphics.game_screen[y][x])
end

local gui = GuiCreate()

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

local offset_x = 200
local offset_y = 50

local screen_offset_x = offset_x + 28
local screen_offset_y = offset_y +  21

local function draw_screen_rect(x, y, w, h, r, g, b)
    local id = 100000 + y * screen_pixels_width + x
    GuiColorSetForNextWidget(gui, r/255, g/255, b/255, 1)
    GuiImage(gui, id, screen_offset_x + x, screen_offset_y + y, "mods/GameHamis/1.png", 1, w, h)
end

local function draw_screen_span(sx, sy, ex, ey, r, g, b)
    if sx ~= 0 and sy < ey then
        draw_screen_rect(sx, sy, screen_pixels_width - sx, 1, r, g, b)
        sx = 0
        sy = sy + 1
    end

    local fulllines = ey - sy
    if fulllines > 0 then
        draw_screen_rect(0, sy, screen_pixels_width, fulllines, r, g, b)
        sy = sy + fulllines
    end

    if ex > sx then
        draw_screen_rect(sx, ey, ex - sx, 1, r, g, b)
    end
end

local function color_key(r, g, b)
    return bit.bor(
        bit.lshift(r, 16),
        bit.lshift(g, 8),
        b
    )
end

local function key_to_color(key)
    return bit.rshift(key, 16),  bit.band(bit.rshift(key, 8), 0xff), bit.band(key, 0xff)
end

local function span_draw_call_count(sx, sy, ex, ey)
    local count = 0
    if sx ~= 0 then
        count = count + 1
    end

    if sy + 1 < ey then
        count = count + 1
    end

    if sy < ey and ex ~= 0 then
        count = count + 1
    end
    return count
end

function draw()
    GuiZSet(gui, -10000)

    GuiOptionsAdd(gui, GUI_OPTION.NoPositionTween)

    -- Horscht magic. Disable buttons taking focus when using controller
    local player = EntityGetWithTag("player_unit")[1]
    if player then
        local platform_shooter_player = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
        if platform_shooter_player then
            if ComponentGetValue2(platform_shooter_player, "mHasGamepadControlsPrev") then
                GuiOptionsAdd(gui, GUI_OPTION.NonInteractive)
                GuiOptionsAdd(gui, GUI_OPTION.AlwaysClickable)
            end
        end
    end

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


    local sx, sy = 0, 0
    local ck = color_key(getrgb(0, 0))
    local y = 0
    local x = 1

    local spans = {}
    local draw_call_count_by_ck = {}

    while y < screen_pixels_height do
        while x < screen_pixels_width do
            local k = color_key(getrgb(x, y))
            if ck ~= k then
                table.insert(spans, {sx, sy, x, y, ck})
                draw_call_count_by_ck[ck] = (draw_call_count_by_ck[ck] or 0) + span_draw_call_count(sx, sy, x, y)

                ck = k
                sx, sy = x, y
            end

            x = x + 1
        end
        y = y + 1
        x = 0
    end

    table.insert(spans, {sx, sy, x, y, ck})
    draw_call_count_by_ck[ck] = (draw_call_count_by_ck[ck] or 0) + span_draw_call_count(sx, sy, x, y)

    local most_common_count = 0
    local most_common_key = nil
    for key, count in pairs(draw_call_count_by_ck) do
        if count > most_common_count then
            most_common_count = count
            most_common_key = key
        end
    end

    GuiZSet(gui, -10100)
    draw_screen_rect(0, 0, screen_pixels_width, screen_pixels_height, key_to_color(most_common_key))

    GuiZSet(gui, -10150)
    for _, span in ipairs(spans) do
        local sx, sy, x, y, ck = unpack(span)
        if ck ~= most_common_key then
            draw_screen_span(sx, sy, x, y, key_to_color(ck))
        end
    end
end

function handle_inputs(controls)
    gameboy.input.keys.Up = (gui_up or ComponentGetValue2(controls, "mButtonDownUp")) and 1 or 0
    gameboy.input.keys.Right = (gui_right or ComponentGetValue2(controls, "mButtonDownRight")) and 1 or 0
    gameboy.input.keys.Down = (gui_down or ComponentGetValue2(controls, "mButtonDownDown")) and 1 or 0
    gameboy.input.keys.Left = (gui_left or ComponentGetValue2(controls, "mButtonDownLeft")) and 1 or 0

    gameboy.input.keys.A = (gui_a or ComponentGetValue2(controls, "mButtonDownKick")) and 1 or 0
    gameboy.input.keys.B = (gui_b or ComponentGetValue2(controls, "mButtonDownInteract")) and 1 or 0

    gameboy.input.keys.Start = gui_start and 1 or 0
    gameboy.input.keys.Select = gui_select and 1 or 0

    gameboy.input.update()
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

    local gh_gaming
    local controls
    for _, v in ipairs(EntityGetAllChildren(player) or {}) do
        if EntityGetName(v) == "gh_gaming" then
            gh_gaming = v
            controls = EntityGetFirstComponent(v, "ControlsComponent")
        end
    end

    draw()

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

    if cartridge_path ~= new_cartridge_path then
        cartridge_path = new_cartridge_path
        if cartridge_path then
            reset()
            local cartridge_datab64 = ModTextFileGetContent(cartridge_path)
            dofile_once("mods/GameHamis/cartridges.lua")
            SetRandomSeed(GameGetRealWorldTimeSinceStarted(), 0)
            cartridge_datab64 = ModTextFileGetContent(cartridges[Random(1, #cartridges)].path)

            local cartridge_data = base64.decode(cartridge_datab64)
            gameboy.cartridge.load(cartridge_data, #cartridge_data)
            gameboy:reset()
        end
    end

    if not has_cartridge() then return end

    gameboy:run_until_vblank()

    if controls then
        handle_inputs(controls)
    end
end

