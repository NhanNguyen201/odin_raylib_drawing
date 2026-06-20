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
painting_rect_update :: proc(paint_settings : ^Paint_settings,view_settings: ^View_settings, app_settings: ^App_settings) {
    container_rect := &paint_settings.container_rect
    if app_settings.app_mode == .Paint {

        mouse := rl.GetScreenToWorld2D(
            rl.GetMousePosition() ,
            paint_settings.camera,
        )
        active_layer := &paint_settings.layers[paint_settings.active_layer]
        brush_color := get_color_from_pallete(paint_settings.color_pallete.colors[:], paint_settings.color_pallete.active_color)
        if app_settings.ui_scene == .None {
            if paint_settings.paint_mode == .Drawing   {
                if rl.IsMouseButtonPressed(.LEFT) && is_rect_hover(mouse, paint_settings.paint_rect.rect) && is_rect_hover(rl.GetMousePosition(), paint_settings.container_rect.rect) {              
                    app_settings.is_mouse_down = true
                }
    
                if app_settings.is_mouse_down {
                    draw_pos := mouse - {paint_settings.paint_rect.rect.x, paint_settings.paint_rect.rect.y}
                    
                    append(&paint_settings.current_stroke.points,  draw_pos)
                    
                    rl.BeginTextureMode(active_layer.render_texture)
                    points := paint_settings.current_stroke.points
                    
                    if len(points) > 1 {
                        p1 := points[len(points)-1]
                        p2 := points[len(points)-2]
                        paint_canvas_2_point(p1, p2, paint_settings.brush_size.val, paint_settings.brush_shape, brush_color)
                    } else if len(points) == 1 {
                        p := points[0]
                        paint_canvas_1_point(p, paint_settings.brush_size.val, paint_settings.brush_shape, brush_color)
                    }
        
                        
                        
                    rl.EndTextureMode()
                }
                if rl.IsMouseButtonReleased(.LEFT) && app_settings.is_mouse_down {
                    app_settings.is_mouse_down = false
                    
                    new_stroke := Stroke {
                        points = paint_settings.current_stroke.points, 
                        mode = .Drawing,
                        size = paint_settings.brush_size.val, 
                        shape = paint_settings.brush_shape,
                        color = brush_color
                    }
                    append(&active_layer.strokes, new_stroke)
                    paint_settings.current_stroke = Stroke {}
                }
                
            } else if paint_settings.paint_mode == .Erase  {
                if rl.IsMouseButtonPressed(.LEFT) && is_rect_hover(mouse, paint_settings.paint_rect.rect) {
                    app_settings.is_mouse_down = true           
                }
                if app_settings.is_mouse_down {
                    
                    canvas_mouse := mouse - rl.Vector2{paint_settings.paint_rect.rect.x, paint_settings.paint_rect.rect.y}
                    erase_point(canvas_mouse, active_layer.render_texture, paint_settings.brush_size.val, paint_settings.brush_shape)
                    append(&paint_settings.current_stroke.points,  canvas_mouse)
        
                }
                if rl.IsMouseButtonReleased(.LEFT) && app_settings.is_mouse_down {
                    app_settings.is_mouse_down = false
                    
                    new_stroke := Stroke {
                        points = paint_settings.current_stroke.points, 
                        mode = .Erase,
                        size = paint_settings.brush_size.val, 
                        shape = paint_settings.brush_shape,
                        color = brush_color
                    }
                    append(&active_layer.strokes, new_stroke)
                    paint_settings.current_stroke = Stroke {}
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
            
        }
    
        if app_settings.is_debug {
            // stroke_length_fmt := fmt.ctprintfln("stroke length: %d, current_length %d", len(active_layer.strokes[:]), len(paint_settings.current_stroke.points[:]))
            // rl.DrawText(stroke_length_fmt, 0, 800, 20, rl.WHITE)
            // for stroke, idx in active_layer.strokes[:] {
            //     stroke_length_fmt := fmt.ctprintfln("stroke idx: %d, current_length %d", idx, len(stroke.points))
            //     rl.DrawText(stroke_length_fmt, 0, i32(850 + idx * 20), 15, rl.WHITE)
        
            // }
        }
        if is_rect_hover(rl.GetMousePosition(), paint_settings.container_rect.rect) {
            if rl.IsKeyDown(.KP_ADD) {
                paint_settings.brush_size.val += rl.GetFrameTime()
            }
            if rl.IsKeyDown(.KP_SUBTRACT) {
                paint_settings.brush_size.val = max (0., paint_settings.brush_size.val - rl.GetFrameTime())
            }
            wheel := rl.GetMouseWheelMove()
    
            if wheel != 0 {
    
                mouse_world_before :=
                    rl.GetScreenToWorld2D(
                        mouse,
                        paint_settings.camera,
                    )  * paint_settings.zoom
    
                paint_settings.zoom += wheel * rl.GetFrameTime()
    
                paint_settings.zoom = clamp(paint_settings.zoom, 0.1, 1.5)
                paint_settings.camera.zoom = paint_settings.zoom
                mouse_world_after :=
                    rl.GetScreenToWorld2D(
                        mouse,
                        paint_settings.camera,
                    ) * paint_settings.zoom
    
                paint_settings.camera.target += (mouse_world_before - mouse_world_after) * rl.GetFrameTime() * 20
            }
            
            
        }
    } else if app_settings.app_mode == .View_3d {
        wheel := rl.GetMouseWheelMove()

        if wheel != 0 {
            
            view_settings.distance = math.clamp(view_settings.distance +  wheel  * rl.GetFrameTime() * 5., 0.2, 20)

            

            
        }
    }

    if app_settings.app_mode != .View_3d {
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
                    paint_settings.layers_rect.x += container_rect.rect.width > min_size ? delta.x : 0
                }
                case .Bottom: {
                    container_rect.rect.height = max( min_size, container_rect.rect.height + delta.y)
                    paint_settings.tools_rect.y += container_rect.rect.height > min_size ? delta.y : 0
                }

                case .None: 
            }
            if rl.IsMouseButtonReleased(.LEFT) {
                container_rect.resize.active = .None
                container_rect.resize.dragging = false
            }
        }

    }
}

painting_rect_render :: proc(font: rl.Font, paint_settings: ^Paint_settings, view_settings: ^View_settings, beat_system: ^Beat_System, music_system: ^Music_System, app_settings: ^App_settings) {
    container_rect := paint_settings.container_rect
    if app_settings.app_mode == .Paint {
        paint_rect := paint_settings.paint_rect.rect
        rl.BeginMode2D(paint_settings.camera)
       
        rl.BeginScissorMode(
            i32(container_rect.rect.x),
            i32(container_rect.rect.y),
            i32(container_rect.rect.width),
            i32(container_rect.rect.height),
        )
        rl.DrawRectangleRec(paint_rect, rl.Color {255,255,255, 150})
        for layer in paint_settings.layers {
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
            paint_settings.camera,
        ) 
         if is_rect_hover(draw_pos, paint_settings.paint_rect.rect) {
            brush_color := get_color_from_pallete(paint_settings.color_pallete.colors[:], paint_settings.color_pallete.active_color)
    
            switch paint_settings.brush_shape {
                case .Point : {
                    if paint_settings.paint_mode == .Drawing {
                        rl.DrawCircleV(draw_pos, paint_settings.brush_size.val, brush_color)
                    } else {
                        rl.DrawCircleLinesV(draw_pos, paint_settings.brush_size.val, brush_color)
                    }
                }
                case .Circle : {
                    rl.DrawCircleLinesV(draw_pos, paint_settings.brush_size.val, brush_color)
                }
                case .Rect : {
                    if paint_settings.paint_mode == .Drawing {
                        rl.DrawRectangleV(draw_pos - paint_settings.brush_size.val, paint_settings.brush_size.val * 2, brush_color)
                    } else {
                        rl.DrawRectangleLinesEx({x = draw_pos.x - paint_settings.brush_size.val, y = draw_pos.y - paint_settings.brush_size.val , width = paint_settings.brush_size.val * 2, height = paint_settings.brush_size.val * 2}, 1. , brush_color)

                    }
    
                }
            }
        }
        rl.EndScissorMode()
        rl.EndMode2D()
        dragged_rect_update(&paint_settings.paint_rect, paint_settings.container_rect.rect, &paint_settings.camera)

    } else if app_settings.app_mode == .View_3d {
    
        
            
        view_settings.camera_settings.position.z = view_settings.distance 
        view_settings.camera.position = view_settings.camera_settings.position
        
        
        view_settings.view_plane_model.transform = rl.MatrixRotateXYZ({
            rl.DEG2RAD * 90,
            rl.DEG2RAD * 0,
            rl.DEG2RAD * app_settings.app_time  * 25,
        })

        rl.BeginTextureMode(view_settings.out_texture)
        
        rl.BeginMode3D(view_settings.camera)
        rl.ClearBackground(rl.Color{175,175,175,220})
        rlgl.DisableBackfaceCulling()

        rl.DrawModel(
            view_settings.view_plane_model,
            rl.Vector3{0,0, 0},
            1.,
            rl.WHITE,
        )
        rlgl.EnableBackfaceCulling()
        
        rl.EndMode3D()
        rl.EndTextureMode()

        // rl.DrawTexture(paint_settings.view_3d.out_texture.texture, i32(paint_settings.paint_rect.container_rect.x), i32(paint_settings.paint_rect.container_rect.y), rl.WHITE)
        rl.DrawTexturePro(
            view_settings.out_texture.texture , 
            {
                x = 0,
                y = 0,
                width = f32(view_settings.out_texture.texture.width),
                height = f32(view_settings.out_texture.texture.height) 
            },
            container_rect.rect,
            0,
            0,
            rl.WHITE
        )
        
    } else if app_settings.app_mode == .Beat {
        @static font_size: f32 = 16
        @static font_spacing: f32 = 0.3
        @static track_rect_size :rl.Vector2 = { 80, 50 }
        @static step_ui_width : f32 = 30
        mouse_pos := rl.GetMousePosition()
        rl.BeginScissorMode(
            i32(container_rect.rect.x),
            i32(container_rect.rect.y),
            i32(container_rect.rect.width),
            i32(container_rect.rect.height),
        )
        option_rect := rl.Rectangle {x = container_rect.rect.x + 20, y = container_rect.rect.y + 20, width = 270, height = 50}
        rl.DrawRectangleRec(option_rect, rl.Color {220,220,220,220})
        play_rect := rl.Rectangle {x = option_rect.x + 5, y = option_rect.y + 5, width = 40, height = 40}
        if beat_system.playing {
            rl.DrawRectangleRounded(play_rect, 0.2, 3, rl.Color {255,75,75,255})
        } else {
            rl.DrawTriangle({play_rect.x, play_rect.y}, {play_rect.x, play_rect.y + play_rect.height}, {play_rect.x + play_rect.width, play_rect.y + play_rect.height / 2}, rl.BLUE)
        }
        if is_rect_hover(rl.GetMousePosition(), play_rect) && rl.IsMouseButtonPressed(.LEFT) {
            beat_system.playing = !beat_system.playing
        }
        volumn_rect := rl.Rectangle {x = play_rect.x + play_rect.width + 20, y = option_rect.y + 10, width = 150, height = 30}
        
        rl.DrawRectangleRec(volumn_rect, rl.Color {75,75,75, 255})
        rl.DrawRectangleRec({x = volumn_rect.x, y= volumn_rect.y, width = beat_system.volume * volumn_rect.width, height = volumn_rect.height}, rl.Color {230,30,230,255})
        if is_rect_hover(mouse_pos, volumn_rect) && rl.IsMouseButtonDown(.LEFT) {
            beat_system.volume = (mouse_pos.x - volumn_rect.x) / volumn_rect.width
            rl.SetMasterVolume( beat_system.volume)
        }
        for &track, track_idx in beat_system.tracks {
            track_rect := rl.Rectangle {x = container_rect.rect.x + 20, y = option_rect.y + 20 + option_rect.height + (track_rect_size.y + 5) * f32(track_idx), width = track_rect_size.x, height = track_rect_size.y}
            step_container_rect := rl.Rectangle {x =  track_rect.x + track_rect.width + 10, y = track_rect.y, width = step_ui_width * (len(track.steps) + 1), height = track_rect.height}

            rl.DrawRectangleRec(track_rect, rl.Color {255,255,255,220})
            rl.DrawRectangleRec(step_container_rect, rl.Color {220,220,255,255})
            rl.DrawTextPro(font, fmt.ctprint(track.name), {track_rect.x + 2.5, track_rect.y + 25}, {0, font_size / 2},0 ,font_size, font_spacing, rl.BLACK)
            for &step, step_idx in track.steps {
                step_rect := rl.Rectangle {x = step_container_rect.x + 12.5 +(step_ui_width) * f32(step_idx), y = step_container_rect.y, width = step_ui_width, height = step_container_rect.height}
                if beat_system.current_step == step_idx {
                    line_rect := rl.Rectangle {x = step_rect.x + (step_rect.width ) * beat_system.timer / (60 / (beat_system.bpm * 4)), y = step_rect.y, width = 5, height = step_rect.height }
                    if line_rect.x - step_rect.x + line_rect.width  >= step_rect.width {
                        line_rect.width = step_rect.x + step_rect.width - line_rect.x 
                    }
                    rl.DrawRectangleRec(line_rect, rl.Color {244,50, 50, 255})
                }
                step_chkbox_rect := rl.Rectangle {x = step_rect.x + 2.5, y = step_rect.y + 10, width = 25, height = 30}
                rl.DrawRectangleLinesEx(step_chkbox_rect, 1, rl.BLACK)
                if is_rect_hover(mouse_pos, step_chkbox_rect) && rl.IsMouseButtonPressed(.LEFT) {
                    beat_system.tracks[track_idx].steps[step_idx] = !beat_system.tracks[track_idx].steps[step_idx]
                }
                if step {
                    rl.DrawCircleV(get_rect_center(step_chkbox_rect), 10, rl.BLUE)
                }
            }
        }
        rl.EndScissorMode()
    } else if app_settings.app_mode == .Music {
        rl.BeginScissorMode(
            i32(container_rect.rect.x),
            i32(container_rect.rect.y),
            i32(container_rect.rect.width),
            i32(container_rect.rect.height)
        )
        for &track, track_idx in music_system.music_tracks {
            for step, step_idx in track.steps {
                step_rect := rl.Rectangle {x = container_rect.rect.x + 10 + 20 * f32(step_idx), y = container_rect.rect.y + 10 + 15 * f32(track_idx), width = 20, height = 15}
                if is_rect_hover(rl.GetMousePosition(), step_rect) && rl.IsMouseButtonPressed(.LEFT) {
                    track.steps[step_idx] = !track.steps[step_idx]
                }
                rl.DrawRectangleRec(step_rect, step ? rl.WHITE : rl.BLACK)
                if step_idx == music_system.current_step {
                    rl.DrawRectangleLinesEx(step_rect, 0.5, rl.BLUE)
                }
            }
        }
        rl.EndScissorMode()
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