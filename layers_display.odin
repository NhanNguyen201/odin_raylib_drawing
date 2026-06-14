package main

import "core:fmt"
import rl "vendor:raylib"

layers_display_render :: proc(font: rl.Font, app_settings: ^App_settings) {
    @static padding : f32 = 10
    @static layers_title := "Layers"
    @static layer_rect_h : f32 = 25.
    @static layer_rect_w : f32 = 150.
    @static text_spacing: f32 = 0.2
    @static text_fontsize :f32 = 20
    display_rect := app_settings.layers_rect
    title_rect := rl.Rectangle {x = display_rect.x + padding, y = display_rect.y, width = display_rect.width, height = 30}
    rl.DrawRectangleRec(title_rect, rl.Color {175,175,175, 255})
    fmt_title := fmt.ctprint(layers_title)
    masured_title, title_fontsize, _ := get_text_to_ui(font, fmt_title, 24, text_spacing)
    rl.DrawTextPro(font, fmt_title, {title_rect.x + 10, title_rect.y + title_rect.height / 2}, {0, masured_title.y / 2}, 0, title_fontsize, text_spacing, rl.BLACK)
    add_rect := rl.Rectangle {x = title_rect.x + title_rect.width - 25, y = title_rect.y + 5, width = 20, height = title_rect.height - 10}
    is_add_rect_hovered := is_rect_hover(rl.GetMousePosition(), add_rect)
    rl.DrawRectangleRec(add_rect, is_add_rect_hovered ? rl.Color {175,175,175,255} : rl.WHITE)
    rl.DrawRectangleLinesEx(add_rect, 1., rl.BLACK)
    rl.DrawTextEx(font, fmt.ctprint("+"), {add_rect.x + 5, add_rect.y + add_rect.height / 2 - text_fontsize / 2}, text_fontsize, text_spacing, rl.BLACK)
    if is_add_rect_hovered && rl.IsMouseButtonPressed(.LEFT){
        new_texture := rl.LoadRenderTexture(i32(app_settings.paint_rect.rect.width), i32(app_settings.paint_rect.rect.height))
        rl.BeginTextureMode(new_texture)
        rl.ClearBackground(rl.BLANK)
        rl.EndTextureMode()
        append(&app_settings.layers, Canvas_layer {
            name = fmt.ctprintf("Layer %d", len(app_settings.layers) + 1),
            render_texture = new_texture,
            visible = true
        })

        app_settings.active_layer = len(app_settings.layers) - 1
    }
    for &layer, idx in app_settings.layers {
        layer_rect := rl.Rectangle {x = title_rect.x + 5, y = title_rect.y + title_rect.height + 20 + (5. + layer_rect_h) * f32(idx), height = layer_rect_h, width = layer_rect_w}
        remove_rect := rl.Rectangle {x = layer_rect.x + layer_rect.width - 25, y = layer_rect.y + 2.5, width = 20, height = 20}
        visible_rect := rl.Rectangle {x = layer_rect.x + layer_rect.width - 50, y = layer_rect.y + 2.5, width = 20, height = 20}

        is_hover := is_rect_hover(rl.GetMousePosition(), layer_rect)
        is_visible_hovered := is_rect_hover(rl.GetMousePosition(), visible_rect)
        is_remove_hovered := is_rect_hover(rl.GetMousePosition(), remove_rect) 
        rl.DrawRectangleRounded(layer_rect, 0.25, 3, is_hover ? rl.Color {150, 150, 255, 255} : rl.Color {200,200,200, 255})
        if idx == app_settings.active_layer {
            rl.DrawRectangleRoundedLinesEx(layer_rect, 0.25, 3, 2, rl.WHITE)
        }
        if is_hover && rl.IsMouseButtonPressed(.LEFT) && !is_remove_hovered && !is_visible_hovered{
            app_settings.active_layer = idx
        }
        fmt_layer_name := fmt.ctprint(layer.name)
        masured_title, _, _ := get_text_to_ui(font, fmt_layer_name, text_fontsize, text_spacing)

        rl.DrawTextPro(font, fmt_layer_name, {layer_rect.x + 2, layer_rect.y + layer_rect.height / 2}, {0, masured_title.y / 2}, 0, text_fontsize, text_spacing, rl.BLACK)

        rl.DrawRectangleRec(visible_rect, layer.visible ? rl.GREEN : rl.GRAY)
        rl.DrawRectangleLinesEx(visible_rect, 1, rl.BLACK)
        if is_rect_hover(rl.GetMousePosition(), visible_rect) && rl.IsMouseButtonPressed(.LEFT) {
            layer.visible = !layer.visible
        }
        rl.DrawRectangleRec(remove_rect, is_rect_hover(rl.GetMousePosition(), remove_rect)  ? rl.RED : rl.Color {175, 175, 175, 255})

        rl.DrawTextEx(font, fmt.ctprint("X"), {remove_rect.x + 5, remove_rect.y }, text_fontsize, text_spacing, rl.BLACK)
        if rl.IsMouseButtonPressed(.LEFT) {
            mouse := rl.GetMousePosition()
            if is_rect_hover(mouse, remove_rect) {
                if len(app_settings.layers) > 1 {
                    if app_settings.active_layer >= idx  || app_settings.active_layer == len(app_settings.layers) - 1 {
                        app_settings.active_layer -= 1
                    }
                    for stroke in layer.strokes {
                        delete(stroke.points)
                    }
                    delete(layer.strokes)
                    rl.UnloadRenderTexture(layer.render_texture)
                    ordered_remove(&app_settings.layers, idx)
                } else if len(app_settings.layers) == 1 {
                    app_settings.active_layer = 0

                    for stroke in layer.strokes {
                        delete(stroke.points)
                    }
                    clear(&layer.strokes)
                    rl.UnloadRenderTexture(layer.render_texture)
                    layer.render_texture = rl.LoadRenderTexture(i32(app_settings.paint_rect.rect.width), i32(app_settings.paint_rect.rect.height))
                }
            }
        }
    }
}

get_text_to_ui :: proc(font: rl.Font, text: cstring, size: f32, spacing: f32) -> (rl.Vector2, f32, f32) {
    return rl.MeasureTextEx(font, text, size, spacing), size, spacing
}