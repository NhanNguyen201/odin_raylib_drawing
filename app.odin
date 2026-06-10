#+feature dynamic-literals

package main
import rl "vendor:raylib"

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
    DRAWING,
    ERASE
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
    view_3d: View_3d
}

Brush_shape :: enum {
    Point,
    Circle,
    Rect
}

View_3d :: struct {
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
    name: string,
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
    painting_dis_rect := rl.Rectangle {
        x = painting_rect.x,
        y = painting_rect.y,
        width = min(painting_rect.width, container_rect.width - (painting_rect.x  - container_rect.x) ) ,
        height = min(painting_rect.height, container_rect.height - (painting_rect.y - container_rect.y) )
    }
    layers_display_rect := rl.Rectangle{x = container_rect.x + container_rect.width, y = 50, width = 100, height = 720}
    brush_color := rl.BLACK
    app := App {
        font = rl.LoadFont("assets/Roboto-Regular.ttf"),
        settings = {
            container_rect = container_rect,
            view_3d = {
                out_texture = rl.LoadRenderTexture(i32(container_rect.width), i32(container_rect.height)),
                in_texutre = rl.LoadRenderTexture(i32(painting_rect.width), i32(painting_rect.height)),
                view_plane_model = rl.LoadModelFromMesh(rl.GenMeshPlane(
                    4,
                    3,
                    1,
                    1,
                )),
                camera_settings = {position = {0, 0, 25.}},
                camera = {
                    fovy = 45,
                    position = {0, 0, 25.},
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
            paint_mode = .DRAWING,
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
        name = "Layer_1", render_texture = texture
    })
    return app
}

app_update:: proc(app: ^App, dt: f32) {
    app.settings.app_time += rl.GetFrameTime()
    if rl.IsKeyPressed(.K) {
        app.settings.paint_mode = app.settings.paint_mode == .DRAWING ? .ERASE : .DRAWING
    }
    if rl.IsKeyPressed(.D) {
        app.settings.is_debug = !app.settings.is_debug 
    }
    painting_rect_update(app)
    painting_rect_render(app)

    if app.settings.app_mode == .Paint {
        color_pallete_render(app.font, &app.settings.color_pallete)
        layers_display_render(app.font, &app.settings)
        tools_rect_render(app.font, &app.settings)
    }

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
                        case .DRAWING : {
                            if idx > 0 {
                                p1 := stroke.points[idx]
                                p2 := stroke.points[idx - 1]
                                paint_canvas_2_point(p1, p2, stroke.size, stroke.shape, stroke.color)
                            } else {
                                paint_canvas_1_point(stroke.points[0], stroke.size, stroke.shape, stroke.color)
        
                            }
                        }
                        case .ERASE : {
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