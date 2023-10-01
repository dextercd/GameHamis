dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/GameHamis/cartridges.lua")
local vsc_util = dofile_once("mods/GameHamis/utils/vsc_util.lua")

local base64 = dofile("mods/GameHamis/base64.lua")

local imgui = load_imgui and load_imgui({mod="GameHamis", version="1.0.0"})

function CopyTextButton(gui, id, x, y, label, text)
    label = label .. ": "
    if imgui then
        local lw = GuiGetTextDimensions(gui, label)
        GuiText(gui, x, y, label)
        if GuiButton(gui, id, x + lw, y, "[Copy] " .. text) then
            imgui.SetClipboardText(text)
        end
    else
        GuiText(gui, x, y, label .. text)
    end
end

local screen_pixels_width = 160
local screen_pixels_height = 144

local offset_x = 170
local offset_y = 50

local screen_offset_x = offset_x + 28
local screen_offset_y = offset_y +  21

local gui = GuiCreate()

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

local gameboy = nil
local cartridge_entity = nil
local cartridge = nil

function reset()
    gameboy = GameBoy.new({})
    gameboy:initialize()
    gameboy:reset()
end
reset()

local function getrgb(x, y)
    return unpack(gameboy.graphics.game_screen[y][x])
end

local gui_up = false
local gui_down = false
local gui_left = false
local gui_right = false

local gui_a = false
local gui_b = false

local gui_select = false
local gui_start = false

local function draw_screen_rect(x, y, w, h, r, g, b, alpha)
    local id = 100000 + y * screen_pixels_width + x
    GuiColorSetForNextWidget(gui, r/255, g/255, b/255, 1)
    GuiImage(gui, id, screen_offset_x + x, screen_offset_y + y, "mods/GameHamis/1.png", alpha, w, h)
end

local function draw_screen_span(sx, sy, ex, ey, r, g, b, alpha)
    if sx ~= 0 and sy < ey then
        draw_screen_rect(sx, sy, screen_pixels_width - sx, 1, r, g, b, alpha)
        sx = 0
        sy = sy + 1
    end

    local fulllines = ey - sy
    if fulllines > 0 then
        draw_screen_rect(0, sy, screen_pixels_width, fulllines, r, g, b, alpha)
        sy = sy + fulllines
    end

    if ex > sx then
        draw_screen_rect(sx, ey, ex - sx, 1, r, g, b, alpha)
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

local cartridge_by_path = {}
for _, c in ipairs(cartridges) do
    cartridge_by_path[c.path] = c
end

function entity_get_cartridge_info(entity_id)
    local cartridge_path = vsc_util.getstr(entity_id, "cartridge_path")
    if cartridge_path then
        return cartridge_by_path[cartridge_path]
    end

    return nil
end

function get_cartridge_ram(entity_id)
    local b64_data = vsc_util.getstr(entity_id, "ram")
    if not b64_data then
        return nil
    end

    return base64.decode(b64_data)
end

function set_cartridge_ram(entity_id, data)
    local b64_data = base64.encode(data)
    vsc_util.setstr(entity_id, "ram", b64_data)
end

function draw(held_by_player, alpha)
    GuiZSet(gui, -10000)

    GuiOptionsAdd(gui, GUI_OPTION.NoPositionTween)

    if not held_by_player or GameGetIsGamepadConnected() then
        GuiOptionsAdd(gui, GUI_OPTION.NonInteractive)
    end

    GuiImage(gui, 100, offset_x, offset_y, "mods/GameHamis/ui/device.png", alpha, 1, 1)

    GuiZSet(gui, -10050)

    gui_up = GuiImageButton(gui, 101, offset_x + 28, offset_y + 212, "", "mods/GameHamis/ui/up.png")
    gui_down = GuiImageButton(gui, 102, offset_x + 28, offset_y + 234, "", "mods/GameHamis/ui/down.png")
    gui_left = GuiImageButton(gui, 103, offset_x + 12, offset_y + 228, "", "mods/GameHamis/ui/left.png")
    gui_right = GuiImageButton(gui, 104, offset_x + 34, offset_y + 228, "", "mods/GameHamis/ui/right.png")

    gui_a = GuiImageButton(gui, 105, offset_x + 185, offset_y + 218, "", "mods/GameHamis/ui/a.png")
    gui_b = GuiImageButton(gui, 106, offset_x + 155, offset_y + 227, "", "mods/GameHamis/ui/b.png")

    gui_select = GuiImageButton(gui, 107, offset_x + 83, offset_y + 275, "", "mods/GameHamis/ui/c.png")
    gui_start = GuiImageButton(gui, 108, offset_x + 113, offset_y + 275, "", "mods/GameHamis/ui/c.png")

    if cartridge == nil then
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
    do
        local r, g, b = key_to_color(most_common_key)
        draw_screen_rect(0, 0, screen_pixels_width, screen_pixels_height, r, g, b, alpha)
    end

    GuiZSet(gui, -10150)
    for _, span in ipairs(spans) do
        local sx, sy, x, y, ck = unpack(span)
        if ck ~= most_common_key then
            local r, g, b = key_to_color(ck)
            draw_screen_span(sx, sy, x, y, r, g, b, alpha)
        end
    end
end

function show_copyright()
    GuiColorSetForNextWidget(gui, 1, 1, 1, 0.5)
    GuiText(gui, offset_x + 221, offset_y + 20, "Powered by LuaGB")

    GuiColorSetForNextWidget(gui, 1, 1, 1, 0.5)
    GuiText(gui, offset_x + 221, offset_y + 30, "License: BSD-3")

    GuiColorSetForNextWidget(gui, 1, 1, 1, 0.5)
    CopyTextButton(gui, 200, offset_x + 221, offset_y + 40, "Website", "https://github.com/zeta0134/LuaGB")

    if cartridge then
        GuiColorSetForNextWidget(gui, 1, 1, 1, 0.5)
        GuiText(gui, offset_x + 221, offset_y + 55, "Cartridge: " .. cartridge.name)

        GuiColorSetForNextWidget(gui, 1, 1, 1, 0.5)
        GuiText(gui, offset_x + 221, offset_y + 65, "License: " .. cartridge.license)

        GuiColorSetForNextWidget(gui, 1, 1, 1, 0.5)
        CopyTextButton(gui, 201, offset_x + 221, offset_y + 75, "Website", cartridge.website)
    end
end

function handle_inputs(controls, holder_id, held_by_player)
    local up, right, down, left, a, b, start, select
    if controls then
        up = ComponentGetValue2(controls, "mButtonDownUp")
        right = ComponentGetValue2(controls, "mButtonDownRight")
        down = ComponentGetValue2(controls, "mButtonDownDown")
        left = ComponentGetValue2(controls, "mButtonDownLeft")
        a = ComponentGetValue2(controls, "mButtonDownKick")
        b = ComponentGetValue2(controls, "mButtonDownInteract")
    end

    if held_by_player then
        up = (up or gui_up)
        right = (right or gui_right)
        down = (down or gui_down)
        left = (left or gui_left)
        a = (a or gui_a)
        b = (b or gui_b)

        start = gui_start
        select = gui_select
    end

    if controls and not held_by_player then
        SetRandomSeed(math.min(GameGetFrameNum() / 20), holder_id)
        start = Random() < 0.003
        select = Random() < 0.003
        a = a or (ComponentGetValue2(controls, "mButtonFrameFly") == GameGetFrameNum())
        b = b or ComponentGetValue2(controls, "mButtonDownRun")
    end

    gameboy.input.keys.Up = up and 1 or 0
    gameboy.input.keys.Right = right and 1 or 0
    gameboy.input.keys.Down = down and 1 or 0
    gameboy.input.keys.Left = left and 1 or 0

    gameboy.input.keys.A = a and 1 or 0
    gameboy.input.keys.B = b and 1 or 0

    gameboy.input.keys.Start = start and 1 or 0
    gameboy.input.keys.Select = select and 1 or 0

    gameboy.input.update()
end

function save_ram_to_cartridge_entity()
    if not gameboy.cartridge.external_ram.dirty then return end
    gameboy.cartridge.external_ram.dirty = false

    local parts = {}
    for i=0, #gameboy.cartridge.external_ram do
        table.insert(parts, string.char(gameboy.cartridge.external_ram[i]))
    end
    set_cartridge_ram(cartridge_entity, table.concat(parts))
end

function load_ram_from_cartridge_entity()
    local ram = get_cartridge_ram(cartridge_entity)
    if not ram then
        return
    end
    for i=1,#ram do
        gameboy.cartridge.external_ram[i - 1] = string.byte(ram, i)
    end
end

local last_frame_enabled = false

function wake_up_waiting_threads()
    GuiStartFrame(gui)

    local gameboy_entity = GetUpdatedEntityID()
    local enabled = EntityGetFirstComponent(gameboy_entity, "SpriteComponent") ~= nil

    if last_frame_enabled and not enabled then
        -- Immediately Store RAM when you stop using the device
        save_ram_to_cartridge_entity()
    end

    last_frame_enabled = enabled
    if not enabled then return end

    -- While using the device, store RAM every 5 seconds
    if GameGetFrameNum() % (60 * 5) == 0 then
        save_ram_to_cartridge_entity()
    end

    local holder_id = EntityGetRootEntity(gameboy_entity)
    local held_by_player = EntityHasTag(holder_id, "player_unit") or EntityHasTag(holder_id, "polymorphed_player")

    local new_cartridge_entity = (EntityGetAllChildren(gameboy_entity) or {})[1]

    if cartridge_entity ~= new_cartridge_entity then
        if cartridge then
            save_ram_to_cartridge_entity()
        end

        cartridge_entity = new_cartridge_entity
        cartridge = entity_get_cartridge_info(new_cartridge_entity)

        if cartridge then
            reset()
            local cartridge_datab64 = ModTextFileGetContent(cartridge.path)

            --[[ Testing code
            SetRandomSeed(GameGetRealWorldTimeSinceStarted(), 0)
            cartridge_datab64 = ModTextFileGetContent(cartridges[Random(1, #cartridges)].path)
            --]]

            local cartridge_data = base64.decode(cartridge_datab64)
            gameboy.cartridge.load(cartridge_data, #cartridge_data)
            load_ram_from_cartridge_entity()
            gameboy:reset()
        end
    end

    local gh_gaming
    local controls
    if held_by_player then
        for _, v in ipairs(EntityGetAllChildren(holder_id) or {}) do
            if EntityGetName(v) == "gh_gaming" then
                gh_gaming = v
                controls = EntityGetFirstComponent(v, "ControlsComponent")
            end
        end
    else
        controls = EntityGetFirstComponent(holder_id, "ControlsComponent")
    end

    if held_by_player then
        if controls then
            if GuiButton(gui, 109, offset_x + 221, offset_y, "[Unfocus]") then
                local ge = EntityGetFirstComponent(gh_gaming, "GameEffectComponent")
                ComponentSetValue2(ge, "frames", 0)
            end
        else
            if GuiButton(gui, 110, offset_x + 221, offset_y, "[Focus]") then
                LoadGameEffectEntityTo(holder_id, "mods/GameHamis/entities/effect_gaming.xml")
            end
        end
    end

    if cartridge ~= nil then
        handle_inputs(controls, holder_id, held_by_player)
        gameboy:run_until_vblank()
    end

    local alpha = 1
    local skip_draw = false

    if not held_by_player then
        local ix, iy = EntityGetTransform(gameboy_entity)
        local player = EntityGetClosestWithTag(ix, iy, "player_unit") or EntityGetClosestWithTag(ix, iy, "polymorphed_player")
        if player then
            local px, py = EntityGetTransform(player)
            local dx, dy = ix - px, iy - py
            local d = math.sqrt(dx * dx + dy * dy)

            local maxd = 200
            local maxa = 0.5
            local mina = 0.3
            local sharpness = 2
            alpha = maxa - (maxa - mina) * (math.pow(d, sharpness) / math.pow(maxd, sharpness))
            skip_draw = d > maxd
        else
            alpha = 0.2
        end
    end

    if not skip_draw then
        draw(held_by_player, alpha)
    end

    local show_copy = GlobalsGetValue("GameHamis.copyright_notices") == "1"
    if show_copy then
        show_copyright()
    end
end

