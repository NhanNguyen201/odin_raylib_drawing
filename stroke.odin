package main

import rl "vendor:raylib"


Stroke :: struct {
    mode: Paint_mode,
    color: rl.Color,
    size:  f32,
    shape: Brush_shape,
    points: [dynamic]rl.Vector2,
}
