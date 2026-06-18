#+feature dynamic-literals

package main

import "core:math"
import rl "vendor:raylib"

import "core:mem"
import "core:fmt"

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 960 
PIXEL_WINDOW_HEIGHT :: 180

calc_dist :: proc (v1: rl.Vector2 , v2 : rl.Vector2) -> f32 {
    return math.sqrt_f32(math.pow_f32(v1.x - v2.x, 2.) + math.pow_f32(v1.y - v2.y, 2.))
}

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)
    rl.InitAudioDevice()
    rl.SetConfigFlags({.WINDOW_RESIZABLE, .MSAA_4X_HINT})
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "drawing")
    rl.SetExitKey(.KEY_NULL)
    rl.SetTargetFPS(65)
    app := app_init()
    defer {
        for &layer in app.paint_settings.layers {
            for &stroke in layer.strokes {
                delete(stroke.points)
            }
            delete(layer.strokes)
            rl.UnloadRenderTexture(layer.render_texture)
        }
        delete(app.paint_settings.layers)
        delete(app.paint_settings.color_pallete.colors)
        delete(app.paint_settings.current_stroke.points)
        rl.UnloadModel(app.view_settings.view_plane_model)
        rl.UnloadRenderTexture(app.view_settings.in_texutre)
        rl.UnloadRenderTexture(app.view_settings.out_texture)
        for track in app.beat_system.tracks {
            rl.UnloadSound(track.sound)
        }
        delete(app.beat_system.tracks)
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leak %v bytes \n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free \n", entry.location)
            
        }
        mem.tracking_allocator_destroy(&track)
        rl.CloseWindow()
        
    }

    for layer in app.paint_settings.layers {
        rl.BeginTextureMode(layer.render_texture)
        rl.ClearBackground(rl.BLANK)
        rl.EndTextureMode()

    }


    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        rl.BeginDrawing()
        rl.ClearBackground(UI_DARK_25_COLOR)
        container_rect := app.paint_settings.container_rect
        rl.DrawRectangleRec(container_rect.rect, UI_DARK_75_COLOR)
        for col in 0..<int(math.floor_f32(container_rect.rect.width / 50) + 1 ) {
            for row in 0..<int(math.floor_f32(container_rect.rect.height / 50) + 1) {
                if col % 2 == row % 2 {
                    rect := rl.Rectangle { x = f32(col) * 50 + container_rect.rect.x, y = f32(row) * 50 + container_rect.rect.y, width = 50, height = 50}
                    if rect.x + rect.width >= container_rect.rect.x + container_rect.rect.width {
                        rect.width = container_rect.rect.x + container_rect.rect.width - rect.x
                    }
                    if rect.y + rect.height >=container_rect.rect.y +  container_rect.rect.height {
                        rect.height = container_rect.rect.y +container_rect.rect.height - rect.y
                    }
                    rl.DrawRectangleRec(rect, rl.BLACK)
                }
            }
        }
        app_update(&app, dt)

        rl.EndDrawing()
        
        
        
        
    }
}

