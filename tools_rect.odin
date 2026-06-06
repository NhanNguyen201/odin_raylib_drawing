package main

import "core:math"
import "core:fmt"
import rl "vendor:raylib"
import "core:reflect"

Slider_value :: struct {
    val: f32,
    rect: rl.Rectangle,
    is_click: bool,
    click_pos: rl.Vector2
}

tools_rect_render :: proc(font: rl.Font, settings : ^App_settings) {
    @static button_size :rl.Vector2 = {60, 30}
    @static font_size :f32 = 20
    @static spacing :f32 = 0.25
    ui_rect := settings.tools_rect
    brush_size_rect := rl.Rectangle {x = ui_rect.x, y = ui_rect.y, width = 40, height = button_size.y}
    is_brush_size_hovered := is_rect_hover(rl.GetMousePosition(), brush_size_rect)
    rl.DrawRectangleRounded(brush_size_rect, .25, 3, is_brush_size_hovered || settings.brush_size.is_click ? rl.Color {100,100,255, 255} : rl.WHITE)
    fmt_tool_size := fmt.ctprintf("%.1f", settings.brush_size.val)
    masured_tool_size,_, _ := get_text_to_ui(font, fmt_tool_size, font_size, spacing)
    rl.DrawTextPro(font, fmt_tool_size, {brush_size_rect.x + 2.5, brush_size_rect.y + brush_size_rect.height / 2}, {0, masured_tool_size.y / 2}, 0, font_size, spacing, rl.BLACK)
    settings.brush_size.rect = brush_size_rect
    dragged_value_from_rect_update(&settings.brush_size)
    for tool, idx in Brush_shape {
        button_rect := rl.Rectangle {x = ui_rect.x + 50 + (5 + button_size.x) * f32(idx), y = ui_rect.y , width = button_size.x, height = button_size.y}
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

dragged_value_from_rect_update :: proc(slider_comp: ^Slider_value) {
    mouse := rl.GetMousePosition()
    if is_rect_hover(mouse, slider_comp.rect) && rl.IsMouseButtonPressed(.LEFT) {
        slider_comp.is_click = true
        slider_comp.click_pos = mouse
        rl.SetMouseCursor(.RESIZE_EW)
    }
    if slider_comp.is_click && rl.IsMouseButtonDown(.LEFT) {
        subed := mouse.x - slider_comp.click_pos.x 
        slider_comp.val = math.max(slider_comp.val + rl.GetFrameTime() * (subed > 0 ? 1 : -1) * math.clamp(abs(subed), 5, 100) * 0.015, 0)
    }
    if slider_comp.is_click && rl.IsMouseButtonReleased(.LEFT) {
        slider_comp.is_click = false
        rl.SetMouseCursor(.DEFAULT)
        
    }
} 

dragged_rect_update :: proc(drag_rect: ^Draggable_rect, camera: ^rl.Camera2D) {
    mouse := rl.GetMousePosition()
    canvas_mouse := rl.GetScreenToWorld2D(
        mouse,
        camera^,
    )
    if is_rect_hover(mouse, drag_rect.container_rect) && rl.IsMouseButtonPressed(.MIDDLE) {
        drag_rect.is_dragged = true
        drag_rect.drag_offset = mouse - {drag_rect.rect.x, drag_rect.rect.y}
    }
    if drag_rect.is_dragged && rl.IsMouseButtonDown(.MIDDLE) {
        delta := rl.GetMouseDelta()

        camera.target.x -= delta.x / camera.zoom
        camera.target.y -= delta.y / camera.zoom



    }
    if drag_rect.is_dragged && rl.IsMouseButtonReleased(.MIDDLE) {
        drag_rect.is_dragged = false

    }
}

get_rect_center :: proc(rect: rl.Rectangle) -> rl.Vector2 {
    return {rect.x + rect.width / 2, rect.y + rect.height / 2}
}