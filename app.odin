#+feature dynamic-literals

package main
import rl "vendor:raylib"
import "vendor:raylib/rlgl"
SCREEN_WIDTH :: 1080
SCREEN_HEIGHT :: 720 
PIXEL_WINDOW_HEIGHT :: 180

App :: struct {
    prev_mouse: rl.Vector2,
    app_mode : App_mode,
    settings: App_settings
}

App_mode :: enum {
    DRAWING,
    ERASE
}

App_settings:: struct {
    brush_size: f32,
    brush_color: rl.Color,
    layers: Canvas_layers,
    container_rect: rl.Rectangle,
    paint_rect : rl.Rectangle,
    active_layer: int
}

Drawing_shape :: enum {
    POINT,
    RECT
}

Canvas_layers :: struct {
    canvas_layers : [dynamic] Canvas_layer
}

Canvas_layer :: struct {
    name: string,
    render_texture:  rl.RenderTexture2D
}

app_init :: proc () -> App {
    container_rect := rl.Rectangle {x = 10, y = 10, width = 960, height = 720}
    painting_rect := rl.Rectangle{x = 10, y = 10, width = 500, height = 500}
    app := App {
        
        settings = {
            container_rect = container_rect,
            brush_size = 8.,
            brush_color = rl.BLACK,
            paint_rect = painting_rect,
            
        }
    }
    texture := rl.LoadRenderTexture(i32(painting_rect.width), i32(painting_rect.height))
    append(&app.settings.layers.canvas_layers, Canvas_layer {
        name = "Layer_1", render_texture = texture
    })
    app.settings.active_layer = 0
    return app
}

app_update:: proc(app: ^App, dt: f32) {
    if rl.IsKeyPressed(.K) {
        app.app_mode = app.app_mode == .DRAWING ? .ERASE : .DRAWING
    }
    // if rl.IsKeyPressed(.E) {
    //     image := rl.LoadImageFromTexture(app.canvas.texture)
    //     rl.ImageFlipVertical(&image)
    //     rl.ExportImage(image, "drawing.png")
    //     rl.UnloadImage(image)
    // }
    mouse := rl.GetMousePosition()
    active_layer := app.settings.layers.canvas_layers[app.settings.active_layer]
        if app.app_mode == .DRAWING {
            if rl.IsMouseButtonDown(.LEFT) && is_rect_hover(mouse, app.settings.paint_rect){
                rl.BeginTextureMode(active_layer.render_texture)
                canvas_mouse := mouse - rl.Vector2{app.settings.paint_rect.x, app.settings.paint_rect.y}
                canvas_prev_mouse := app.prev_mouse - rl.Vector2{app.settings.paint_rect.x, app.settings.paint_rect.y}
                    rl.DrawCircleV(canvas_mouse, app.settings.brush_size, app.settings.brush_color)
                    if calc_dist(canvas_mouse, canvas_prev_mouse) > app.settings.brush_size {
                        rl.DrawLineEx(
                            canvas_prev_mouse,     
                            canvas_mouse,
                            app.settings.brush_size * 2,
                            app.settings.brush_color
                        )
                        
                    } 
                rl.EndTextureMode()

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
    
    app.prev_mouse = mouse
}

is_rect_hover:: proc(mouse: rl.Vector2, rect: rl.Rectangle) -> bool {
    return rl.CheckCollisionPointRec(mouse, rect)

}