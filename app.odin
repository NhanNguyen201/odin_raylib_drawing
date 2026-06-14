#+feature dynamic-literals

package main
import rl "vendor:raylib"
import "core:math"
import "core:reflect"
import "core:fmt"
import "core:strconv"
UI_SETTING_START : rl.Vector2 : {2.5, 0}
UI_SETTING_HEIGHT : f32 : 10.  
UI_TOOL_START : rl.Vector2 : {2.5, 30}
UI_TOOL_HEIGHT : f32 : 10.  
UI_COLOR_PCIKER_START : rl.Vector2 : {2.5, 50}
UI_COLOR_PCIKER_WIDTH : f32 : 100
UI_PAINTING_CONTAINER_START : rl.Vector2 : {80, 50}

App :: struct {
    settings: App_settings,
    font: rl.Font
}

App_mode :: enum {
    Paint, 
    View_3d,
}

Paint_mode :: enum {
    Drawing,
    Erase
}

App_settings:: struct {
    app_time: f32,
    app_mode: App_mode,
    camera: rl.Camera2D,
    camera_zoom: f32,
    canvas_size: rl.Vector2,
    container_rect: rl.Rectangle,
    paint_rect : Draggable_rect,
    layers_rect: rl.Rectangle,
    tools_rect: rl.Rectangle,
    paint_mode : Paint_mode,
    color_pallete : Color_pallete,
    is_debug: bool,
    is_mouse_down : bool,
    brush_size: Slider_value ,
    brush_shape: Brush_shape,
    layers: [dynamic] Canvas_layer,
    active_layer: int,
    current_stroke: Stroke,
    view_3d: View_3d,
    size_widget: Size_widget,
    ui_scene: UI_scenes
}

Brush_shape :: enum {
    Point,
    Circle,
    Rect
}

UI_scenes :: enum {
    None,
    Size_widget
}

View_3d :: struct {
    distance : f32 ,
    out_texture: rl.RenderTexture2D,
    in_texutre: rl.RenderTexture2D,
    camera: rl.Camera3D,
    camera_settings: View_3d_camera_settings,
    view_plane_model : rl.Model
}

View_3d_camera_settings:: struct {
    position: rl.Vector3
}

Canvas_layer :: struct {
    name: cstring,
    opacity: f32,
    visible: bool,
    render_texture:  rl.RenderTexture2D,
    strokes: [dynamic] Stroke
}

app_init :: proc () -> App {
    canvas_size := rl.Vector2 {750, 500}
    color_pallete_rect := rl.Rectangle {x = UI_COLOR_PCIKER_START.x, y= UI_COLOR_PCIKER_START.y, width = UI_COLOR_PCIKER_WIDTH, height = 200}
    container_rect := rl.Rectangle {x = color_pallete_rect.x + color_pallete_rect.width + 10., y = UI_PAINTING_CONTAINER_START.y, width = 960, height = 720}
    tools_rect := rl.Rectangle {x = container_rect.x , y = container_rect.y + container_rect.height + 10, width = 960, height = 100}
    painting_rect := rl.Rectangle{x = container_rect.x + 10, y = container_rect.y + 10, width = canvas_size.x, height = canvas_size.y}
    layers_display_rect := rl.Rectangle{x = container_rect.x + container_rect.width, y = 50, width = 180, height = 720}
    view_3d_distance : f32 = 5. 
    brush_color := rl.BLACK
    app := App {
        font = rl.LoadFont("assets/Roboto-Regular.ttf"),
        settings = {
            container_rect = container_rect,
            view_3d = {
                distance = view_3d_distance,
                out_texture = rl.LoadRenderTexture(i32(container_rect.width), i32(container_rect.height)),
                in_texutre = rl.LoadRenderTexture(i32(painting_rect.width), i32(painting_rect.height)),
                view_plane_model = rl.LoadModelFromMesh(rl.GenMeshPlane(
                    4,
                    painting_rect.height / painting_rect.width * 4,
                    1,
                    1,
                )),
                camera_settings = {position = {0, 0, 25.}},
                camera = {
                    fovy = 45,
                    position = {0, 0, view_3d_distance},
                    projection = .PERSPECTIVE,
                    target = rl.Vector3{0,0,0},
                    up = rl.Vector3{0,1,0}
                }
            },
            camera = {
                offset = 0,
                zoom = 1.,
                // offset = {container_rect.width / 2, container_rect.height / 2},
            },
            camera_zoom = 1.,
            paint_rect = {
                rect = painting_rect,
                
                container_rect = container_rect
            },
            layers_rect = layers_display_rect,
            tools_rect = tools_rect,
            brush_size = { val = 8. },
            active_layer = 0,
            paint_mode = .Drawing,
            color_pallete = {
                active_color = 0,
                colors = {{color = rl.BLACK}, {color = rl.BLUE}, {color = rl.BROWN}, {color = rl.WHITE}},
                color_picker = {f32(brush_color[0]), f32(brush_color[1]), f32(brush_color[2]), f32(brush_color[3])},
                component_rect = color_pallete_rect
            }
            
        }
    }
    texture := rl.LoadRenderTexture(i32(painting_rect.width), i32(painting_rect.height))
    append(&app.settings.layers, Canvas_layer {
        name = "Layer_1", render_texture = texture,
        visible = true
    })
    return app
}

app_update:: proc(app: ^App, dt: f32) {
    app.settings.app_time += rl.GetFrameTime()
    if rl.IsKeyPressed(.K) {
        app.settings.paint_mode = app.settings.paint_mode == .Drawing ? .Erase : .Drawing
    }
    if rl.IsKeyPressed(.D) {
        app.settings.is_debug = !app.settings.is_debug 
    }
    
    
    painting_rect_update(app)
    painting_rect_render(app)
    app_bar_render(app.font, &app.settings)
    
    if app.settings.app_mode == .Paint {
        color_pallete_render(app.font, &app.settings.color_pallete)
        layers_display_render(app.font, &app.settings)
        tools_rect_render(app.font, &app.settings)
    }

    ui_render(app.font, &app.settings)
    if rl.IsKeyPressed(.TAB) {
        if app.settings.app_mode == .Paint {
            app.settings.app_mode = .View_3d
        } else if app.settings.app_mode == .View_3d {
            app.settings.app_mode = .Paint
        }
    }
    if rl.IsKeyPressed(.E) {
        texture := rl.LoadRenderTexture(i32(app.settings.paint_rect.rect.width), i32(app.settings.paint_rect.rect.height))
        // rl.BeginDrawing()
        // rl.BeginTextureMode(texture)
        for layer in app.settings.layers {
            layer_txt := rl.LoadRenderTexture(i32(app.settings.paint_rect.rect.width), i32(app.settings.paint_rect.rect.height))
            rl.BeginDrawing()
            rl.BeginTextureMode(layer_txt)
            for stroke in layer.strokes {
                for point, idx in stroke.points {
                    switch stroke.mode {
                        case .Drawing : {
                            if idx > 0 {
                                p1 := stroke.points[idx]
                                p2 := stroke.points[idx - 1]
                                paint_canvas_2_point(p1, p2, stroke.size, stroke.shape, stroke.color)
                            } else {
                                paint_canvas_1_point(stroke.points[0], stroke.size, stroke.shape, stroke.color)
        
                            }
                        }
                        case .Erase : {
                            erase_point(point, layer_txt, stroke.size, stroke.shape)
                        }
                    }
                }
            }
            rl.EndTextureMode()
            rl.BeginTextureMode(texture)
            rl.DrawTexture(layer_txt.texture, 0, 0, rl.WHITE)
            rl.EndTextureMode()
            rl.EndDrawing()
            rl.UnloadTexture(layer_txt.texture)
        }
     
        image := rl.LoadImageFromTexture(texture.texture)
       

        rl.ExportImage(image, "drawing.png")
        rl.UnloadTexture(texture.texture)
        rl.UnloadImage(image)
    }
}

is_rect_hover:: proc(mouse: rl.Vector2, rect: rl.Rectangle) -> bool {
    return rl.CheckCollisionPointRec(mouse, rect)

}

app_bar_render :: proc(font: rl.Font, settings: ^App_settings) {
    @static button_size :rl.Vector2 = {75, 30}
    @static button_font_size : f32 = 20
    @static button_font_spacing : f32 = 0.4
    new_rect := rl.Rectangle {x =  5, y = 10 , width = button_size.x, height =button_size.y}
    rl.DrawRectangleRounded(new_rect, 0.2, 5, rl.WHITE)
    fmt_new := fmt.ctprintf("New")
    if is_rect_hover(rl.GetMousePosition(), new_rect) && rl.IsMouseButtonPressed(.LEFT) {
        settings.size_widget.is_active = true
        settings.ui_scene = .Size_widget
    }
    
    masured_new, _, _ := get_text_to_ui(font, fmt_new, button_font_size, button_font_spacing)
    rl.DrawTextEx(font, fmt_new, {new_rect.x + 2.5, new_rect.y + new_rect.height / 2 - masured_new.y / 2}, button_font_size, button_font_spacing, rl.BLACK)
    for mode, idx in App_mode {
        mode_button_rect := rl.Rectangle {x = new_rect.x + new_rect.width + 10 + (button_size.x + 10) * f32(idx), y = 10, width = button_size.x, height = button_size.y}
        is_hovered := is_rect_hover(rl.GetMousePosition(), mode_button_rect)
        is_active := mode == settings.app_mode
        rl.DrawRectangleRounded(mode_button_rect, 0.2, 5, is_active ? rl.BLACK : rl.WHITE)
        if is_active {
            rl.DrawRectangleRoundedLinesEx({x = mode_button_rect.x + 2, y = mode_button_rect.y + 2, width = mode_button_rect.width - 4, height = mode_button_rect.height - 4}, 0.2, 5, 2, rl.WHITE)
        } else {
            if is_hovered {
                rl.DrawRectangleRec({x = mode_button_rect.x , y = mode_button_rect.y + 5, width = mode_button_rect.width, height = mode_button_rect.height - 10}, rl.BLACK)
                if rl.IsMouseButtonPressed(.LEFT) {
                    settings.app_mode = mode
                }
            }
        } 

        fmt_mode := fmt.ctprint(reflect.enum_string(mode))
        masured, _, _ := get_text_to_ui(font, fmt_mode, button_font_size, button_font_spacing)
        rl.DrawTextPro(font, fmt_mode, {mode_button_rect.x + 5, mode_button_rect.y + (mode_button_rect.height / 2)}, {0, masured.y / 2}, 0, button_font_size, button_font_spacing, (is_active || is_hovered) ? rl.WHITE : rl.BLACK)
    }
}

ui_render :: proc(font: rl.Font, settings: ^App_settings) {
    
    if settings.size_widget.is_active {
        size_widget_render(font, settings)
    }
}
size_widget_render :: proc(font: rl.Font, settings: ^App_settings) {
    @static button_size :rl.Vector2 = {75, 30}
    @static font_size: f32 = 20
    @static font_spacing: f32 = 0.3
    @static width_text := "Width :"
    @static height_text := "Height :"
    @static cancel_text := "Cancel"
    @static confirm_text := "Confirm"
    if rl.IsKeyPressed(.ESCAPE) {
        settings.size_widget.is_active = false
        settings.ui_scene = .None
    }
    size_widget_rect := rl.Rectangle {x = 50, y = 50, width = 200, height = 150}
    rl.DrawRectangleRounded(size_widget_rect, 0.025, 3, rl.Color {175,175,175, 255})
    rl.DrawRectangleRoundedLinesEx(size_widget_rect, 0.025, 3, 1, rl.BLACK)
    width_rect := rl.Rectangle {x = size_widget_rect.x + 65, y = size_widget_rect.y + 20, width = 130, height = 30}
    height_rect := rl.Rectangle {x = size_widget_rect.x + 65, y = size_widget_rect.y + 60, width = 130, height = 30}
    width_input := &settings.size_widget.width_input
    height_input := &settings.size_widget.height_input
    rl.DrawRectangleRec(width_rect, settings.size_widget.width_input.is_active ? rl.BLUE : UI_DARK_25_COLOR)
    rl.DrawTextEx(font, fmt.ctprint(width_text), {size_widget_rect.x + 5, width_rect.y + 5}, font_size, font_spacing, rl.BLACK)
    if rl.IsMouseButtonPressed(.LEFT) {
        mouse_pos := rl.GetMousePosition()
        if is_rect_hover(mouse_pos, width_rect) {
            width_input.is_active = true
                
            
        } else {
            width_input.is_active = false
        }

        if is_rect_hover(mouse_pos, height_rect) {
            height_input.is_active = true
        } else {
            height_input.is_active = false
        }
    }
    if width_input.is_active {
        key := rl.GetCharPressed()
        if key >= '0' && key <= '9' && width_input.len < len(width_input.buf){
            width_input.buf[width_input.len] = u8(key)
            width_input.len += 1
        }
        if rl.IsKeyPressed(.BACKSPACE) {
            if width_input.len > 0 {
                width_input.len -= 1
            }
        }
            if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.KP_ENTER) {
            width_input.is_active = false

        }
        value, ok := strconv.parse_uint(string(width_input.buf[:width_input.len]))
        if ok {
            fmt_width := fmt.ctprint(value > 0 ? f32(value) : 0.)
            rl.DrawTextEx(font, fmt_width, {width_rect.x + 5, width_rect.y + 5}, font_size, font_spacing, rl.WHITE)
        }
    } else {
        fmt_setting_width := fmt.ctprintf("%.1f ", settings.paint_rect.rect.width)
        value, ok := strconv.parse_uint(string(width_input.buf[:width_input.len]))

        if abs(value) > 0 && ok {
            fmt_setting_width = fmt.ctprintf("%.1f -> %d", settings.paint_rect.rect.width, value)
        }
        rl.DrawTextEx(font, fmt_setting_width, {width_rect.x + 5, width_rect.y + 5}, font_size, font_spacing, rl.WHITE)

    }
    
    rl.DrawRectangleRec(height_rect, settings.size_widget.height_input.is_active ? rl.BLUE : UI_DARK_25_COLOR)
    rl.DrawTextEx(font, fmt.ctprint(height_text), {size_widget_rect.x + 5, height_rect.y + 5}, font_size, font_spacing, rl.BLACK)
    if height_input.is_active {
        key := rl.GetCharPressed()
        if key >= '0' && key <= '9' && height_input.len < len(height_input.buf){
            height_input.buf[height_input.len] = u8(key)
            height_input.len += 1
        }
        if rl.IsKeyPressed(.BACKSPACE) {
            if height_input.len > 0 {
                height_input.len -= 1
            }
        }
        if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.KP_ENTER) {
            height_input.is_active = false

        }
        value, ok := strconv.parse_uint(string(height_input.buf[:height_input.len]))
        if ok {
            fmt_height := fmt.ctprint(value > 0 ? f32(value) : 0.)
            rl.DrawTextEx(font, fmt_height, {height_rect.x + 5, height_rect.y + 5}, font_size, font_spacing, rl.WHITE)
        }
    } else {
        fmt_setting_height := fmt.ctprintf("%.1f ", settings.paint_rect.rect.height)
        value, ok := strconv.parse_int(string(height_input.buf[:height_input.len]))

        if abs(value) > 0 && ok {
            fmt_setting_height = fmt.ctprintf("%.1f -> %d", settings.paint_rect.rect.height, value)
        }
        rl.DrawTextEx(font, fmt_setting_height, {height_rect.x + 5, height_rect.y + 5}, font_size, font_spacing, rl.WHITE)

    }
    cancel_rect :=  rl.Rectangle { x = size_widget_rect.x + 40, y = size_widget_rect.y + size_widget_rect.height - 5 - button_size.y, width = button_size.x, height = button_size.y}
    is_cancel_hovered := is_rect_hover(rl.GetMousePosition(), cancel_rect)
    confirm_rect :=  rl.Rectangle { x = size_widget_rect.x + 120, y = size_widget_rect.y + size_widget_rect.height - 5 - button_size.y, width = button_size.x, height = button_size.y}
    rl.DrawRectangleRec(cancel_rect, is_cancel_hovered ? UI_DARK_75_COLOR : UI_DARK_25_COLOR)
    fmt_cancel := fmt.ctprint(cancel_text)
    masured_cancel, _, _ := get_text_to_ui(font, fmt_cancel, font_size, font_spacing)
    rl.DrawTextEx(font, fmt_cancel, get_rect_center(cancel_rect) - masured_cancel / 2, font_size, font_spacing, rl.WHITE)
    if is_cancel_hovered && rl.IsMouseButtonPressed(.LEFT) {
        settings.size_widget.is_active = false
        settings.ui_scene = .None
    } 
    rl.DrawRectangleRec(confirm_rect, rl.BLUE)
    fmt_confirm := fmt.ctprint(confirm_text)
    masured_confirm, _, _ := get_text_to_ui(font, fmt_confirm, font_size, font_spacing)
    rl.DrawTextEx(font, fmt_confirm, get_rect_center(confirm_rect) - masured_confirm / 2, font_size, font_spacing, rl.WHITE)
    is_confirm_hovered := is_rect_hover(rl.GetMousePosition(), confirm_rect)
    if is_confirm_hovered && rl.IsMouseButtonPressed(.LEFT) {

        for &layer in settings.layers {
            for &stroke in layer.strokes {
                delete(stroke.points)
            }
            delete(layer.strokes)
            rl.UnloadRenderTexture(layer.render_texture)
        }
        clear(&settings.layers)
        rl.UnloadRenderTexture(settings.view_3d.in_texutre)
        rl.UnloadRenderTexture(settings.view_3d.out_texture)

        // re init
        parse_width, _ := strconv.parse_uint(string(width_input.buf[:width_input.len]))
        res_width := max(5., f32(parse_width))
        settings.paint_rect.rect.width = res_width

        parse_height, _ := strconv.parse_uint(string(height_input.buf[:height_input.len]))
        res_height := max(5., f32(parse_height))
        settings.paint_rect.rect.height = res_height

        settings.view_3d.in_texutre = rl.LoadRenderTexture(i32(parse_width), i32(parse_height))
        settings.view_3d.out_texture = rl.LoadRenderTexture(i32(parse_width), i32(parse_height))
        rl.UnloadModel(settings.view_3d.view_plane_model)
        settings.view_3d.view_plane_model = rl.LoadModelFromMesh(rl.GenMeshPlane (
             4,
            res_height / res_width * 4,
            1,
            1,
        ))
        texture := rl.LoadRenderTexture(i32(res_width), i32(res_height))
        append(&settings.layers, Canvas_layer {
            name = "Layer_1", 
            render_texture = texture,
            visible = true
        })
        settings.active_layer = 0
        settings.size_widget.is_active = false
        settings.ui_scene = .None
    }
}