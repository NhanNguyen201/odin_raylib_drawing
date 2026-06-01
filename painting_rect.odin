package main

import "core:fmt"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"

is_color :: proc(colors: []Draw_color, idx: int) -> bool {
    return idx < len(colors)
}

get_color_from_pallete :: proc (colors: []Draw_color, idx: int) -> rl.Color {
    res := is_color(colors, idx)
    return res ? colors[idx].color : rl.BLACK
}
painting_rect_update :: proc(app : ^App) {
    mouse := rl.GetMousePosition()
    active_layer := &app.settings.layers[app.settings.active_layer]
    brush_color := get_color_from_pallete(app.settings.color_pallete.colors[:], app.settings.color_pallete.active_color)
    
    
    if app.app_mode == .DRAWING {
        if rl.IsMouseButtonDown(.LEFT) && is_rect_hover(mouse, app.settings.paint_rect){
            if !app.settings.is_mouse_down {
                app.settings.is_mouse_down = true
            } 
            canvas_mouse := mouse - {app.settings.paint_rect.x, app.settings.paint_rect.y}
            // canvas_prev_mouse := app.prev_mouse - rl.Vector2{app.settings.paint_rect.x, app.settings.paint_rect.y}
           
            append(&app.settings.current_stroke.points,  canvas_mouse)
         
            rl.BeginTextureMode(active_layer.render_texture)
            points := app.settings.current_stroke.points
            if len(points) > 1 {
                p1 := points[len(points)-1]
                p2 := points[len(points)-2]
                if calc_dist(p1, p2) > app.settings.brush_size / 2 {
                    rl.DrawLineEx(p1, p2, app.settings.brush_size * 2, brush_color)
                    rl.DrawCircleV(p1, app.settings.brush_size, brush_color)

                } else {
                    rl.DrawCircleV(p1, app.settings.brush_size, brush_color)
                    // rl.DrawCircleV(p2, app.settings.brush_size, brush_color)
                }
            } else if len(points) == 1 {
                rl.DrawCircleV(points[len(points)-1], app.settings.brush_size, brush_color)
            }

                
              
            rl.EndTextureMode()
                    
        }
    
        if rl.IsMouseButtonReleased(.LEFT) && app.settings.is_mouse_down {
            app.settings.is_mouse_down = false
            
            new_stroke := Stroke {
                points = app.settings.current_stroke.points, 
                size = app.settings.brush_size, 
                color = brush_color
            }
            append(&active_layer.strokes, new_stroke)
            app.settings.current_stroke = Stroke {}
        }
        
    } else if app.app_mode == .ERASE {
        if rl.IsMouseButtonDown(.LEFT) && is_rect_hover(mouse, app.settings.paint_rect){
        
            canvas_mouse := mouse - rl.Vector2{app.settings.paint_rect.x, app.settings.paint_rect.y}
            canvas_prev_mouse := app.prev_mouse - rl.Vector2{app.settings.paint_rect.x, app.settings.paint_rect.y}
            rl.BeginTextureMode(active_layer.render_texture)
            rl.BeginBlendMode(.CUSTOM)
            rlgl.SetBlendFactors(rlgl.ZERO, rlgl.ONE_MINUS_DST_ALPHA, rlgl.FUNC_ADD)
        

            rl.DrawCircleV(
                canvas_mouse,
                app.settings.brush_size,
                rl.Color {255, 255, 255, 0},
            )
    
            
            rl.EndBlendMode()
            rl.EndTextureMode()

        }
    }
    if rl.IsKeyPressed(.Z) {
        strokes_len := len(active_layer.strokes)
        if   strokes_len > 0 {

            delete(active_layer.strokes[strokes_len - 1].points)
            _ = pop(&active_layer.strokes)

            rl.BeginTextureMode(active_layer.render_texture)
            rl.ClearBackground(rl.BLANK)
            for stroke in active_layer.strokes {
                points := stroke.points
                for point, idx in points {
                    if idx > 0 {
                        p1 := points[idx]
                        p2 := points[idx - 1]
                        if calc_dist(p1, p2) > stroke.size / 2 {
                            rl.DrawLineEx(p1, p2, stroke.size * 2, stroke.color)
                            rl.DrawCircleV(p1, app.settings.brush_size, brush_color)

                        } else {
                            rl.DrawCircleV(p1, stroke.size, stroke.color)
                            // rl.DrawCircleV(p2, stroke.size, stroke.color)
                        }
                    } else {
                        rl.DrawCircleV(point, stroke.size, stroke.color)
                    }

                }
            }
            rl.EndTextureMode()

        }
    }

    if app.settings.is_debug {
        stroke_length_fmt := fmt.ctprintfln("stroke length: %d, current_length %d", len(active_layer.strokes[:]), len(app.settings.current_stroke.points[:]))
        rl.DrawText(stroke_length_fmt, 0, 800, 20, rl.WHITE)
        for stroke, idx in active_layer.strokes[:] {
            stroke_length_fmt := fmt.ctprintfln("stroke idx: %d, current_length %d", idx, len(stroke.points))
            rl.DrawText(stroke_length_fmt, 0, i32(850 + idx * 20), 15, rl.WHITE)
    
        }
    }
    app.prev_mouse = mouse
}

painting_rect_render :: proc(app: ^App) {
    rl.DrawRectangleRec(app.settings.paint_rect, rl.Color {255,255,255, 150})
    rl.DrawRectangleLinesEx(app.settings.container_rect, 2.5, rl.Color{125,125,125,255})
    for layer in app.settings.layers {
        source := rl.Rectangle {
            0,
            0,
            f32(layer.render_texture.texture.width),
            -f32(layer.render_texture.texture.height), // IMPORTANT: flip vertically
        }

        rl.DrawTexturePro(
            layer.render_texture.texture,
            source,
            app.settings.paint_rect,
            0,
            0,
            rl.WHITE,
        )

    }
}