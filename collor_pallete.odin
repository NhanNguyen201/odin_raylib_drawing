#+feature dynamic-literals

package main
import rl "vendor:raylib"
import "core:fmt"
import "core:math"
COLOR_BLOCK_SIZE : f32 : 25
COLOR_BLOCK_PADDING: f32 : 3.

UI_DARK_75_COLOR :: rl.Color {75,75,75,255}
UI_DARK_25_COLOR :: rl.Color {25,25,25,255}
UI_BRIGHT_125_COLOR :: rl.Color {125,125,125,255}

Color_pallete :: struct {
    component_rect : rl.Rectangle,
    active_color : int,
    colors : [dynamic] Draw_color,
    color_picker: rl.Vector4
}

Draw_color :: struct {
    color : rl.Color
}

color_pallete_render :: proc(font:rl.Font, pallete: ^Color_pallete) {
    ui_rect := pallete.component_rect
    color_per_row := math.floor_f32(ui_rect.width / (COLOR_BLOCK_PADDING * 2 + COLOR_BLOCK_SIZE))
    rl.DrawRectangleRec(ui_rect, UI_DARK_75_COLOR)
    for color, idx in pallete.colors {
        row := math.floor_f32(f32(idx) / color_per_row) 
        col := i32(idx) % i32(color_per_row)
        item_block := rl.Rectangle {
            x = ui_rect.x + f32(col) * (COLOR_BLOCK_PADDING * 2 + COLOR_BLOCK_SIZE) + COLOR_BLOCK_PADDING,
            y = ui_rect.y + row * (COLOR_BLOCK_PADDING * 2 + COLOR_BLOCK_SIZE) + COLOR_BLOCK_PADDING,
            width = COLOR_BLOCK_SIZE,
            height = COLOR_BLOCK_SIZE 
        }
        rl.DrawRectangleRec(item_block, color.color)
        if idx == pallete.active_color {
            rl.DrawRectangleLinesEx({x = item_block.x - 1, y = item_block.y - 1, width = item_block.width + 2, height = item_block.height + 2}, 1., rl.WHITE)
        }
        if is_rect_hover( rl.GetMousePosition(), item_block) && rl.IsMouseButtonPressed(.LEFT) {
            pallete.active_color = idx
            brush_color := get_color_from_pallete(pallete.colors[:], idx)

            pallete.color_picker = {f32(brush_color[0]), f32(brush_color[1]), f32(brush_color[2]), f32(brush_color[3])}
        } 
        if idx == len(pallete.colors) - 1 {
            add_row := math.floor_f32(f32(idx + 1) / color_per_row) 
            add_col := i32(idx + 1) % i32(color_per_row)
            add_rect := rl.Rectangle {
                x = ui_rect.x + f32(add_col) * (COLOR_BLOCK_PADDING * 2 + COLOR_BLOCK_SIZE) + COLOR_BLOCK_PADDING,
                y = ui_rect.y + add_row * (COLOR_BLOCK_PADDING * 2 + COLOR_BLOCK_SIZE) + COLOR_BLOCK_PADDING,
                width = COLOR_BLOCK_SIZE,
                height = COLOR_BLOCK_SIZE 
            }
            rl.DrawRectangleRec(add_rect, rl.WHITE)
            // rl.DrawRectangleLinesEx(add_rect, 5, rl.RED)
            fmt_icon := fmt.ctprint("+")
            masured_icon := rl.MeasureTextEx(font, fmt_icon, COLOR_BLOCK_SIZE, 0.5)
            rl.DrawTextPro(font, fmt_icon, {add_rect.x + add_rect.width / 2, add_rect.y + add_rect.height / 2}, masured_icon / 2,0., COLOR_BLOCK_SIZE, 0.5, rl.BLACK)
            if is_rect_hover( rl.GetMousePosition(), add_rect) && rl.IsMouseButtonPressed(.LEFT) {
                append(&pallete.colors, Draw_color {color = rl.BLACK})
                pallete.color_picker = {0,0,0,255}

            } 
        }
    }
    color_picker_bg_rect := rl.Rectangle {x = ui_rect.x , y = ui_rect.y + 500, width = ui_rect.width , height = 50}
    rl.DrawRectangleGradientEx(color_picker_bg_rect, rl.Color{225,225,225,255},  rl.Color{0,0,0,255}, rl.Color{225,225,225,255}, rl.Color{0,0,0,255})
    if is_rect_hover(rl.GetMousePosition(), color_picker_bg_rect) && rl.IsMouseButtonPressed(.LEFT) {
        pallete.colors[pallete.active_color].color = rl.Color { u8(pallete.color_picker[0]), u8(pallete.color_picker[1]), u8(pallete.color_picker[2]), u8(pallete.color_picker[3])}
    }
    color_picker_res_rect := rl.Rectangle {x = color_picker_bg_rect.x + 10, y = color_picker_bg_rect.y + 20, width = color_picker_bg_rect.width - 20, height = 10}
    rl.DrawRectangleRec(color_picker_res_rect, rl.Color { u8(pallete.color_picker[0]), u8(pallete.color_picker[1]), u8(pallete.color_picker[2]), u8(pallete.color_picker[3])})
    for &color_el, idx in pallete.color_picker {
        color_val := math.clamp(color_el, 0.,255.)
        color_display := rl.Color{0,0,0, 255}
        if idx == 3 {
            color_display.xyz = {255,255,255}
        } else {
            color_display[idx] = u8(color_val)
        }
        slot_rect := rl.Rectangle {x = ui_rect.x + 2.5 + (5 + 20) * f32(idx), y = color_picker_bg_rect.y + color_picker_bg_rect.height + 10, width = 20, height = 80}
        rl.DrawRectangleRec(slot_rect, rl.Color {220,220,220,255})
        if is_rect_hover(rl.GetMousePosition(), slot_rect) && rl.IsMouseButtonDown(.LEFT) {
            mouse_y := rl.GetMousePosition().y
            color_el = (1. - (mouse_y - slot_rect.y ) / slot_rect.height) * 255
        }
        color_rect:= rl.Rectangle {x = slot_rect.x, y = slot_rect.y + slot_rect.height * (1. - color_val / 255.), width = slot_rect.width, height = slot_rect.height * color_val / 255.}
        rl.DrawRectangleRec(color_rect,color_display)
    }   
} 