#+feature dynamic-literals

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
    
    rl.SetConfigFlags({.WINDOW_RESIZABLE})
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "drawing")
    rl.SetExitKey(.KEY_NULL)
    rl.SetTargetFPS(60)
    app := app_init()
    defer {
        for layer in app.settings.layers.canvas_layers {
            rl.UnloadRenderTexture(layer.render_texture)
        }
        delete(app.settings.layers.canvas_layers)

        for _, entry in track.allocation_map {
            fmt.eprintf("%v leak %v bytes \n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free \n", entry.location)
            
        }
        mem.tracking_allocator_destroy(&track)
        rl.CloseWindow()
        
    }

    for layer in app.settings.layers.canvas_layers {
        rl.BeginTextureMode(layer.render_texture)
        rl.ClearBackground(rl.BLANK)
        rl.EndTextureMode()

    }


    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        app_update(&app, dt)
        rl.BeginDrawing()
        rl.ClearBackground(rl.Color {57, 57, 57, 255})
        container_rect := app.settings.container_rect
        rl.DrawRectangleRec(container_rect, rl.Color{75,75,75,255})
        rl.DrawRectangleLinesEx(container_rect, 0.5, rl.Color{125,125,125,255})
        for col in 0..<int(math.floor_f32(container_rect.width / 50)) {
            for row in 0..<int(math.floor_f32(container_rect.height / 50)) {
                if col % 2 == row % 2 {
                    rl.DrawRectangleV({f32(col) * 50 + container_rect.x, f32(row) * 50 + container_rect.y}, 50, rl.BLACK)
                }
            }
        }
        
        rl.DrawRectangleRec(app.settings.paint_rect, rl.WHITE)

        for layer in app.settings.layers.canvas_layers {
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
        rl.EndDrawing()
    }
}

