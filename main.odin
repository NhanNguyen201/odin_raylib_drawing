package main

import "core:math"
import rl "vendor:raylib"

import "core:mem"
import "core:fmt"

calc_dist :: proc (v1: rl.Vector2 , v2 : rl.Vector2) -> f32 {
    return math.sqrt_f32(math.pow_f32(v1.x - v2.x, 2.) + math.pow_f32(v1.y - v2.y, 2.))
}

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)
    
    // rl.SetConfigFlags({.WINDOW_TRANSPARENT, .WINDOW_TOPMOST})
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "drawing")
    rl.SetExitKey(.KEY_NULL)
    rl.SetTargetFPS(60)
    defer {
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leak %v bytes \n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free \n", entry.location)
            
        }
        mem.tracking_allocator_destroy(&track)
        free_all(context.temp_allocator)
        rl.CloseWindow()
        
    }
    app := app_init()
    rl.BeginTextureMode(app.canvas)
    rl.ClearBackground(rl.WHITE)
    rl.EndTextureMode()


    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        app_update(&app, dt)
        rl.BeginDrawing()
        rl.ClearBackground(rl.Color {57, 57, 57, 255})
        source := rl.Rectangle {
            0,
            0,
            f32(app.canvas.texture.width),
            -f32(app.canvas.texture.height), // IMPORTANT: flip vertically
        }


        rl.DrawTexturePro(
            app.canvas.texture,
            source,
            app.app_setting.painting_rect,
            rl.Vector2 {},
            0,
            rl.WHITE,
        )
        rl.EndDrawing()
    }
}

