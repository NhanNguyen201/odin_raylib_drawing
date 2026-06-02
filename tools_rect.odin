package main

import "core:fmt"
import rl "vendor:raylib"
import "core:reflect"

tools_rect_render :: proc(font: rl.Font, settings : ^App_settings) {
    @static button_size :rl.Vector2 = {60, 30}
    @static font_size :f32 = 20
    @static spacing :f32 = 0.25
    ui_rect := settings.tools_rect

    for tool, idx in Brush_shape {
        button_rect := rl.Rectangle {x = ui_rect.x + (5 + button_size.x) * f32(idx), y = ui_rect.y , width = button_size.x, height = button_size.y}
        is_hovered := is_rect_hover(rl.GetMousePosition(), button_rect)

        rl.DrawRectangleRounded(button_rect, .25, 3, is_hovered ? rl.Color{0, 120, 220, 255} : rl.WHITE)
        if tool == settings.brush_shape {
            rl.DrawRectangleRoundedLinesEx(button_rect, .25, 3, 3, rl.BLUE)
        }
        if is_hovered && rl.IsMouseButtonPressed(.LEFT) {
            settings.brush_shape = tool
        }
        tool_name, _ := reflect.enum_name_from_value(tool)
        fmt_tool_name := fmt.ctprint(tool_name)
        masured,_, _ := get_text_to_ui(font, fmt_tool_name, font_size, spacing)
        rl.DrawTextPro(font, fmt_tool_name, {button_rect.x + 2.5, button_rect.y + button_rect.height / 2}, {0, masured.y / 2}, 0, font_size, spacing, rl.BLACK)
    }
}