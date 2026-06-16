package main

import "core:math"
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

Container_resize_state :: enum {
    None,
    Right, 
    Bottom
}

Container_resize :: struct {
    active: Container_resize_state,
    dragging: bool,
}

Container_rect :: struct {
    rect : rl.Rectangle,
    resize : Container_resize
}

Draggable_rect :: struct {
    rect: rl.Rectangle,
    is_dragged: bool,
    click_pos: rl.Vector2,
}

Text_Input :: struct {
    buf: [4]u8,
    len: int,
    is_active: bool,
}

Size_widget :: struct {
    is_active: bool,
    width_input: Text_Input,
    height_input: Text_Input
}
painting_rect_update :: proc(app : ^App) {
    if app.settings.app_mode == .Paint {

        mouse := rl.GetScreenToWorld2D(
            rl.GetMousePosition() ,
            app.settings.camera,
        )
        active_layer := &app.settings.layers[app.settings.active_layer]
        brush_color := get_color_from_pallete(app.settings.color_pallete.colors[:], app.settings.color_pallete.active_color)
        container_rect := &app.settings.container_rect
        if app.settings.ui_scene == .None {
            if app.settings.paint_mode == .Drawing   {
                if rl.IsMouseButtonPressed(.LEFT) && is_rect_hover(mouse, app.settings.paint_rect.rect) && is_rect_hover(rl.GetMousePosition(), app.settings.container_rect.rect) {              
                    app.settings.is_mouse_down = true
                }
    
                if app.settings.is_mouse_down {
                    draw_pos := mouse - {app.settings.paint_rect.rect.x, app.settings.paint_rect.rect.y}
                    
                    append(&app.settings.current_stroke.points,  draw_pos)
                    
                    rl.BeginTextureMode(active_layer.render_texture)
                    points := app.settings.current_stroke.points
                    
                    if len(points) > 1 {
                        p1 := points[len(points)-1]
                        p2 := points[len(points)-2]
                        paint_canvas_2_point(p1, p2, app.settings.brush_size.val, app.settings.brush_shape, brush_color)
                    } else if len(points) == 1 {
                        p := points[0]
                        paint_canvas_1_point(p, app.settings.brush_size.val, app.settings.brush_shape, brush_color)
                    }
        
                        
                        
                    rl.EndTextureMode()
                }
                if rl.IsMouseButtonReleased(.LEFT) && app.settings.is_mouse_down {
                    app.settings.is_mouse_down = false
                    
                    new_stroke := Stroke {
                        points = app.settings.current_stroke.points, 
                        mode = .Drawing,
                        size = app.settings.brush_size.val, 
                        shape = app.settings.brush_shape,
                        color = brush_color
                    }
                    append(&active_layer.strokes, new_stroke)
                    app.settings.current_stroke = Stroke {}
                }
                
            } else if app.settings.paint_mode == .Erase  {
                if rl.IsMouseButtonPressed(.LEFT) && is_rect_hover(mouse, app.settings.paint_rect.rect) {
                    app.settings.is_mouse_down = true           
                }
                if app.settings.is_mouse_down {
                    
                    canvas_mouse := mouse - rl.Vector2{app.settings.paint_rect.rect.x, app.settings.paint_rect.rect.y}
                    erase_point(canvas_mouse, active_layer.render_texture, app.settings.brush_size.val, app.settings.brush_shape)
                    append(&app.settings.current_stroke.points,  canvas_mouse)
        
                }
                if rl.IsMouseButtonReleased(.LEFT) && app.settings.is_mouse_down {
                    app.settings.is_mouse_down = false
                    
                    new_stroke := Stroke {
                        points = app.settings.current_stroke.points, 
                        mode = .Erase,
                        size = app.settings.brush_size.val, 
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
                                case .Drawing : {
                                    if idx > 0 {
                                        p1 := points[idx]
                                        p2 := points[idx - 1]
                                        paint_canvas_2_point(p1, p2, stroke.size, stroke.shape, stroke.color)
                                    } else {
                                        paint_canvas_1_point(points[0], stroke.size, stroke.shape, stroke.color)
                
                                    }
                                }
                                case .Erase : {
                                    erase_point(point, active_layer.render_texture, stroke.size, stroke.shape)
                                }
                            }
        
                        }
                    }
                    rl.EndTextureMode()
        
                }
            }
            right_side_rect := rl.Rectangle {
                x = container_rect.rect.x + container_rect.rect.width - 3,
                y = container_rect.rect.y + 3,
                width = 6,
                height = container_rect.rect.height - 6,
            }
            bottom_side_rect := rl.Rectangle {
                x = container_rect.rect.x + 3,
                y = container_rect.rect.y + container_rect.rect.height - 3,
                width = container_rect.rect.width - 6,
                height = 6,
            }
            if is_rect_hover(rl.GetMousePosition(), right_side_rect) {
                rl.DrawRectangleRec(right_side_rect, rl.BLUE)
                if rl.IsMouseButtonPressed(.LEFT) {
                    container_rect.resize.active = .Right
                    container_rect.resize.dragging = true
                }
            }
             if is_rect_hover(rl.GetMousePosition(), bottom_side_rect) {
                rl.DrawRectangleRec(bottom_side_rect, rl.BLUE)
                if rl.IsMouseButtonPressed(.LEFT) {
                    container_rect.resize.active = .Bottom
                    container_rect.resize.dragging = true
                }
            }
            
            if container_rect.resize.dragging  {
                @static min_size : f32 = 100
                delta := rl.GetMouseDelta()
                switch container_rect.resize.active {
                    case .Right : {
                        container_rect.rect.width = max(min_size, container_rect.rect.width + delta.x)
                        app.settings.layers_rect.x += container_rect.rect.width > min_size ? delta.x : 0
                    }
                    case .Bottom: {
                        container_rect.rect.height = max( min_size, container_rect.rect.height + delta.y)
                        app.settings.tools_rect.y += container_rect.rect.height > min_size ? delta.y : 0
                    }

                    case .None: 
                }
                if rl.IsMouseButtonReleased(.LEFT) {
                    container_rect.resize.active = .None
                    container_rect.resize.dragging = false
                }
            }
        }
    
        if app.settings.is_debug {
            // stroke_length_fmt := fmt.ctprintfln("stroke length: %d, current_length %d", len(active_layer.strokes[:]), len(app.settings.current_stroke.points[:]))
            // rl.DrawText(stroke_length_fmt, 0, 800, 20, rl.WHITE)
            // for stroke, idx in active_layer.strokes[:] {
            //     stroke_length_fmt := fmt.ctprintfln("stroke idx: %d, current_length %d", idx, len(stroke.points))
            //     rl.DrawText(stroke_length_fmt, 0, i32(850 + idx * 20), 15, rl.WHITE)
        
            // }
        }
        if is_rect_hover(rl.GetMousePosition(), app.settings.container_rect.rect) {
            if rl.IsKeyDown(.KP_ADD) {
                app.settings.brush_size.val += rl.GetFrameTime()
            }
            if rl.IsKeyDown(.KP_SUBTRACT) {
                app.settings.brush_size.val = max (0., app.settings.brush_size.val - rl.GetFrameTime())
            }
            wheel := rl.GetMouseWheelMove()
    
            if wheel != 0 {
    
                mouse_world_before :=
                    rl.GetScreenToWorld2D(
                        mouse,
                        app.settings.camera,
                    )  * app.settings.camera_zoom
    
                app.settings.camera_zoom += wheel * rl.GetFrameTime()
    
                app.settings.camera_zoom = clamp(app.settings.camera_zoom, 0.1, 1.5)
                app.settings.camera.zoom = app.settings.camera_zoom
                mouse_world_after :=
                    rl.GetScreenToWorld2D(
                        mouse,
                        app.settings.camera,
                    ) * app.settings.camera_zoom
    
                app.settings.camera.target += (mouse_world_before - mouse_world_after) * rl.GetFrameTime() * 20
            }
            
            
        }
    } else if app.settings.app_mode == .View_3d {
        wheel := rl.GetMouseWheelMove()

        if wheel != 0 {
            
            app.settings.view_3d.distance = math.clamp(app.settings.view_3d.distance +  wheel  * rl.GetFrameTime() * 5., 0.2, 20)

            

            
        }
    }

    
}

painting_rect_render :: proc(app: ^App) {
    if app.settings.app_mode == .Paint {
        paint_rect := app.settings.paint_rect.rect
        container_rect := app.settings.container_rect
        rl.BeginMode2D(app.settings.camera)
       
        rl.BeginScissorMode(
            i32(container_rect.rect.x),
            i32(container_rect.rect.y),
            i32(container_rect.rect.width),
            i32(container_rect.rect.height),
        )
        rl.DrawRectangleRec(paint_rect, rl.Color {255,255,255, 150})
        for layer in app.settings.layers {
            if layer.visible {
                source := rl.Rectangle {
                    x = 0,
                    y =  0,
                    width= f32(layer.render_texture.texture.width),
                    height = -f32(layer.render_texture.texture.height)
                }
               
                
                rl.DrawTexturePro(
                    layer.render_texture.texture,
                    source,
                    paint_rect,
                    0,
                    0,
                    rl.WHITE,
                )
            }
            
        }
        // ui draw a shape at the cursor
        draw_pos := rl.GetScreenToWorld2D(
            rl.GetMousePosition(),
            app.settings.camera,
        ) 
         if is_rect_hover(draw_pos, app.settings.paint_rect.rect) {
            brush_color := get_color_from_pallete(app.settings.color_pallete.colors[:], app.settings.color_pallete.active_color)
    
            switch app.settings.brush_shape {
                case .Point : {
                    if app.settings.paint_mode == .Drawing {
                        rl.DrawCircleV(draw_pos, app.settings.brush_size.val, brush_color)
                    } else {
                        rl.DrawCircleLinesV(draw_pos, app.settings.brush_size.val, brush_color)
                    }
                }
                case .Circle : {
                    rl.DrawCircleLinesV(draw_pos, app.settings.brush_size.val, brush_color)
                }
                case .Rect : {
                    if app.settings.paint_mode == .Drawing {
                        rl.DrawRectangleV(draw_pos - app.settings.brush_size.val, app.settings.brush_size.val * 2, brush_color)
                    } else {
                        rl.DrawRectangleLinesEx({x = draw_pos.x - app.settings.brush_size.val, y = draw_pos.y - app.settings.brush_size.val , width = app.settings.brush_size.val * 2, height = app.settings.brush_size.val * 2}, 1. , brush_color)

                    }
    
                }
            }
        }
        rl.EndScissorMode()
        rl.EndMode2D()
        dragged_rect_update(&app.settings.paint_rect, app.settings.container_rect.rect, &app.settings.camera)

    } else if app.settings.app_mode == .View_3d {
    
        
            
        app.settings.view_3d.camera_settings.position.z = app.settings.view_3d.distance 
        app.settings.view_3d.camera.position = app.settings.view_3d.camera_settings.position
        
        
        app.settings.view_3d.view_plane_model.transform = rl.MatrixRotateXYZ({
            rl.DEG2RAD * 90,
            rl.DEG2RAD * 0,
            rl.DEG2RAD * app.settings.app_time  * 25,
        })

        rl.BeginTextureMode(app.settings.view_3d.out_texture)
        
        rl.BeginMode3D(app.settings.view_3d.camera)
        rl.ClearBackground(rl.Color{175,175,175,220})
        rlgl.DisableBackfaceCulling()

        rl.DrawModel(
            app.settings.view_3d.view_plane_model,
            rl.Vector3{0,0, 0},
            1.,
            rl.WHITE,
        )
        rlgl.EnableBackfaceCulling()
        
        rl.EndMode3D()
        rl.EndTextureMode()

        // rl.DrawTexture(app.settings.view_3d.out_texture.texture, i32(app.settings.paint_rect.container_rect.x), i32(app.settings.paint_rect.container_rect.y), rl.WHITE)
        rl.DrawTexturePro(
            app.settings.view_3d.out_texture.texture , 
            {
                x = 0,
                y = 0,
                width = f32(app.settings.view_3d.out_texture.texture.width),
                height = f32(app.settings.view_3d.out_texture.texture.height) 
            },
            app.settings.container_rect.rect,
            0,
            0,
            rl.WHITE
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

draw_3d_plane_texture :: proc(in_texture: rl.RenderTexture2D, layers: []Canvas_layer, model: ^rl.Model) {
    rl.BeginTextureMode(in_texture)
    rl.ClearBackground(rl.BLANK)
    for layer in layers {
        rl.DrawTextureRec(layer.render_texture.texture, {x =0, y =0, width = f32(layer.render_texture.texture.width), height = -f32(layer.render_texture.texture.height)}, 0, rl.WHITE)
    }
    rl.EndTextureMode()

    model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = in_texture.texture

}