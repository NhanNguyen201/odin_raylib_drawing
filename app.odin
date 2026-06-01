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
    prev_mouse: rl.Vector2,
    app_mode : App_mode,
    settings: App_settings,
    font: rl.Font
}

App_mode :: enum {
    DRAWING,
    ERASE
}

App_settings:: struct {
    container_rect: rl.Rectangle,
    paint_rect : rl.Rectangle,
    layers_rect: rl.Rectangle,

    color_pallete : Color_pallete,
    is_debug: bool,
    is_mouse_down : bool,
    brush_size: f32,
    layers: [dynamic] Canvas_layer,
    active_layer: int,
    current_stroke: Stroke
}

Drawing_shape :: enum {
    POINT,
    RECT
}



Canvas_layer :: struct {
    name: string,
    opacity: f32,
    visible: bool,
    render_texture:  rl.RenderTexture2D,
    strokes: [dynamic] Stroke
}

app_init :: proc () -> App {
    color_pallete_rect := rl.Rectangle {x = UI_COLOR_PCIKER_START.x, y= UI_COLOR_PCIKER_START.y, width = UI_COLOR_PCIKER_WIDTH, height = 200}
    container_rect := rl.Rectangle {x = color_pallete_rect.x + color_pallete_rect.width + 10., y = UI_PAINTING_CONTAINER_START.y, width = 960, height = 720}
    painting_rect := rl.Rectangle{x = container_rect.x + 10, y = container_rect.y + 10, width = 500, height = 500}
    layers_display_rect := rl.Rectangle{x = container_rect.x + container_rect.width, y = 50, width = 100, height = 720}
    brush_color := rl.BLACK
    app := App {
        font = rl.LoadFont("assets/Roboto-Regular.ttf"),
        settings = {
            container_rect = container_rect,
            paint_rect = painting_rect,
            layers_rect = layers_display_rect,
            brush_size = 8.,
            active_layer = 0,
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
    if rl.IsKeyPressed(.K) {
        app.app_mode = app.app_mode == .DRAWING ? .ERASE : .DRAWING
    }
    if rl.IsKeyPressed(.D) {
        app.settings.is_debug = !app.settings.is_debug 
    }
    painting_rect_update(app)
    painting_rect_render(app)

    color_pallete_render(app.font, &app.settings.color_pallete)
    layers_display_render(app.font, &app.settings)

}

is_rect_hover:: proc(mouse: rl.Vector2, rect: rl.Rectangle) -> bool {
    return rl.CheckCollisionPointRec(mouse, rect)

}