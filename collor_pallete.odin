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
    colors : [dynamic] Draw_color
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
            } 
        }
    }
} 