package main

import "core:fmt"
import rl "vendor:raylib"

layers_display_render :: proc(font: rl.Font, app_settings: ^App_settings) {
    @static padding : f32 = 10
    @static layers_title := "Layers"
    @static layer_rect_h : f32 = 25.
    @static text_spacing: f32 = 0.2
    @static layer_name_fontsize :f32 = 20
    display_rect := app_settings.layers_rect
    title_rect := rl.Rectangle {x = display_rect.x + padding, y = display_rect.y, width = display_rect.width, height = 30}
    rl.DrawRectangleRounded(title_rect, 0.25, 3, rl.Color {150,150,150, 200})
    fmt_title := fmt.ctprint(layers_title)
    masured_title, title_fontsize, _ := get_text_to_ui(font, fmt_title, 24, text_spacing)
    rl.DrawTextPro(font, fmt_title, {title_rect.x + 10, title_rect.y + title_rect.height / 2}, {0, masured_title.y / 2}, 0, title_fontsize, text_spacing, rl.BLACK)
    add_rect := rl.Rectangle {x = title_rect.x + title_rect.width - 30, y = title_rect.y + 5, width = 20, height = title_rect.height - 10}
    rl.DrawRectangleRec(add_rect, rl.BLUE)
    if is_rect_hover(rl.GetMousePosition(), add_rect) && rl.IsMouseButtonPressed(.LEFT){
        new_texture := rl.LoadRenderTexture(i32(app_settings.paint_rect.width), i32(app_settings.paint_rect.height))
        rl.BeginTextureMode(new_texture)
        rl.ClearBackground(rl.BLANK)
        rl.EndTextureMode()
        append(&app_settings.layers, Canvas_layer {
            name = "new_layer",
            render_texture = new_texture
        })

        app_settings.active_layer += 1
    }
    for layer, idx in app_settings.layers {
        layer_rect := rl.Rectangle {x = title_rect.x + 5, y = title_rect.y + title_rect.height + 20 + (5. + layer_rect_h) * f32(idx), height = layer_rect_h, width = 100}
        is_hover := is_rect_hover(rl.GetMousePosition(), layer_rect)
        rl.DrawRectangleRounded(layer_rect, 0.25, 3, is_hover ? rl.Color {150, 150, 255, 255} : rl.Color {150,150,150, 200})
        if idx == app_settings.active_layer {
            rl.DrawRectangleRoundedLinesEx(layer_rect, 0.25, 3, 2, rl.WHITE)
        }
        if is_hover && rl.IsMouseButtonPressed(.LEFT){
            app_settings.active_layer = idx
        }
        fmt_layer_name := fmt.ctprint(layer.name)
        masured_title, _, _ := get_text_to_ui(font, fmt_layer_name, layer_name_fontsize, text_spacing)

        rl.DrawTextPro(font, fmt_layer_name, {layer_rect.x + 10, layer_rect.y + layer_rect.height / 2}, {0, masured_title.y / 2}, 0, layer_name_fontsize, text_spacing, rl.BLACK)
    }
}

get_text_to_ui :: proc(font: rl.Font, text: cstring, size: f32, spacing: f32) -> (rl.Vector2, f32, f32) {
    return rl.MeasureTextEx(font, text, size, spacing), size, spacing
}