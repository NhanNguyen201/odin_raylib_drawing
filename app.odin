package main
import rl "vendor:raylib"

SCREEN_WIDTH :: 1080
SCREEN_HEIGHT :: 720 
PIXEL_WINDOW_HEIGHT :: 180

App :: struct {
    canvas : rl.RenderTexture2D,
    prev_mouse: rl.Vector2,
    app_mode : App_mode,
    app_setting: App_settings
}

App_mode :: enum {
    DRAWING,
    ERASE
}

App_settings:: struct {
    brush_size: f32,
    brush_color: rl.Color,
    painting_rect: rl.Rectangle,
}

Drawing_shape :: enum {
    POINT,
    RECT
}

app_init :: proc () -> App {
    painting_rect := rl.Rectangle{x = 10, y = 10, width = 500, height = 500}
    return {
        canvas = rl.LoadRenderTexture(i32(painting_rect.width), i32(painting_rect.height)),
        app_setting = {
            brush_size = 8.,
            brush_color = rl.BLACK,
            painting_rect = painting_rect
        }
    }
}

app_update:: proc(app: ^App, dt: f32) {
    if rl.IsKeyPressed(.K) {
        app.app_mode = app.app_mode == .DRAWING ? .ERASE : .DRAWING
    }
    mouse := rl.GetMousePosition()

    if rl.IsMouseButtonDown(.LEFT) && is_rect_hover(mouse, app.app_setting.painting_rect){
        if app.app_mode == .DRAWING {
            rl.BeginTextureMode(app.canvas)
            canvas_mouse := mouse - rl.Vector2{app.app_setting.painting_rect.x, app.app_setting.painting_rect.y}
            canvas_prev_mouse := app.prev_mouse - rl.Vector2{app.app_setting.painting_rect.x, app.app_setting.painting_rect.y}
                rl.DrawCircleV(canvas_mouse, app.app_setting.brush_size, app.app_setting.brush_color)
                if calc_dist(canvas_mouse, canvas_prev_mouse) > app.app_setting.brush_size {
                    rl.DrawLineEx(
                        canvas_prev_mouse,     
                        canvas_mouse,
                        app.app_setting.brush_size * 2,
                        app.app_setting.brush_color
                    )
                    
                } 
            rl.EndTextureMode()
        } else if app.app_mode == .ERASE {
            canvas_mouse := mouse - rl.Vector2{app.app_setting.painting_rect.x, app.app_setting.painting_rect.y}
            canvas_prev_mouse := app.prev_mouse - rl.Vector2{app.app_setting.painting_rect.x, app.app_setting.painting_rect.y}
            rl.BeginTextureMode(app.canvas)
            rl.BeginBlendMode(.CUSTOM)
            // rl.(
            //     rl.ZERO,
            //     rl.ONE_MINUS_SRC_ALPHA,
            //     rl.FUNC_ADD,
            // )

            rl.DrawCircleV(
                canvas_mouse,
                app.app_setting.brush_size,
                rl.Color {255, 255, 255, 0},
            )
            // rl.DrawCircleV(canvas_mouse, app.app_setting.brush_size, rl.Color{50,50,50,50})
            // if calc_dist(canvas_mouse, canvas_prev_mouse) > app.app_setting.brush_size {
            //    rl.DrawLineEx(
            //        canvas_prev_mouse,     
            //        canvas_mouse,
            //        app.app_setting.brush_size * 2,
            //        rl.Color{0,0,0,0}
            //     )
                
            // } 
            rl.EndBlendMode();
            rl.EndTextureMode()

        }
    }   
    app.prev_mouse = mouse
}

is_rect_hover:: proc(mouse: rl.Vector2, rect: rl.Rectangle) -> bool {
    return rl.CheckCollisionPointRec(mouse, rect)

}