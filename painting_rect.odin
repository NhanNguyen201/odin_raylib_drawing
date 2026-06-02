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
    
    
    if app.settings.paint_mode == .DRAWING {
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
                paint_canvas_2_point(p1, p2, app.settings.brush_size, app.settings.brush_shape, brush_color)
            } else if len(points) == 1 {
                p := points[0]
                paint_canvas_1_point(p, app.settings.brush_size, app.settings.brush_shape, brush_color)
            }

                
              
            rl.EndTextureMode()
                    
        }
    
        if rl.IsMouseButtonReleased(.LEFT) && app.settings.is_mouse_down {
            app.settings.is_mouse_down = false
            
            new_stroke := Stroke {
                points = app.settings.current_stroke.points, 
                mode = .DRAWING,
                size = app.settings.brush_size, 
                shape = app.settings.brush_shape,
                color = brush_color
            }
            append(&active_layer.strokes, new_stroke)
            app.settings.current_stroke = Stroke {}
        }
        
    } else if app.settings.paint_mode == .ERASE {
        if rl.IsMouseButtonDown(.LEFT) && is_rect_hover(mouse, app.settings.paint_rect){
            if !app.settings.is_mouse_down {
                app.settings.is_mouse_down = true
            } 
            canvas_mouse := mouse - rl.Vector2{app.settings.paint_rect.x, app.settings.paint_rect.y}
            erase_point(canvas_mouse, active_layer.render_texture, app.settings.brush_size, app.settings.brush_shape)
            append(&app.settings.current_stroke.points,  canvas_mouse)

        }
        if rl.IsMouseButtonReleased(.LEFT) && app.settings.is_mouse_down {
            app.settings.is_mouse_down = false
            
            new_stroke := Stroke {
                points = app.settings.current_stroke.points, 
                mode = .ERASE,
                size = app.settings.brush_size, 
                shape = app.settings.brush_shape,
                color = brush_color
            }
            append(&active_layer.strokes, new_stroke)
            app.settings.current_stroke = Stroke {}
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
                    switch stroke.mode {
                        case .DRAWING : {
                            if idx > 0 {
                                p1 := points[idx]
                                p2 := points[idx - 1]
                                paint_canvas_2_point(p1, p2, stroke.size, stroke.shape, stroke.color)
                            } else {
                                paint_canvas_1_point(points[0], stroke.size, stroke.shape, stroke.color)
        
                            }
                        }
                        case .ERASE : {
                            erase_point(point, active_layer.render_texture, stroke.size, stroke.shape)
                        }
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

paint_canvas_2_point :: proc(p1, p2: rl.Vector2, brush_size: f32, brush_shape: Brush_shape, color: rl.Color) {
    if calc_dist(p1, p2) > brush_size / 2 {
        switch brush_shape {
            case .Point : {
                rl.DrawLineEx(p1, p2, brush_size * 2, color)
                rl.DrawCircleV(p1, brush_size, color)
            }
            case .Circle : {
                rl.DrawCircleLinesV({(p1.x + p2.x) / 2,  (p1.y + p2.y) / 2}, brush_size , color)
                rl.DrawCircleLinesV(p1, brush_size, color)
            }
            case .Rect : {
                rl.DrawLineEx(p1, p2, brush_size * 2, color)
                rl.DrawRectangleV(p1 - brush_size , brush_size, color)
            }
        }

    } else {
        switch brush_shape {
            case .Point : {
                rl.DrawCircleV(p1, brush_size, color)
            }
            case .Circle : {
                rl.DrawCircleLinesV(p1, brush_size, color)
            }
            case .Rect : {
                rl.DrawRectangleV(p1 - brush_size , brush_size * 2, color)
            }
        }
    }
}
paint_canvas_1_point :: proc (p: rl.Vector2, brush_size: f32, brush_shape: Brush_shape, color: rl.Color){
    switch brush_shape {
        case .Point : {
            rl.DrawCircleV(p, brush_size, color)
        }
        case .Circle : {
            rl.DrawCircleLinesV(p, brush_size, color)
        }
        case .Rect : {
            rl.DrawRectangleV(p - brush_size , brush_size * 2, color)
        }
    }
}

erase_point :: proc(p: rl.Vector2, texture: rl.RenderTexture2D, brush_size: f32, brush_shape: Brush_shape) {
    rl.BeginTextureMode(texture)
    rl.BeginBlendMode(.CUSTOM)
    rlgl.SetBlendFactors(rlgl.ZERO, rlgl.ONE_MINUS_DST_ALPHA, rlgl.FUNC_ADD)


    paint_canvas_1_point(p, brush_size, brush_shape, rl.Color {255,255,255,0})
        
                
    rl.EndBlendMode()
    rl.EndTextureMode()
}