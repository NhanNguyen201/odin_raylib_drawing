package main

import rl "vendor:raylib"


Stroke :: struct {
    color: rl.Color,
    size:  f32,
    shape: Drawing_shape,
    points: [dynamic]rl.Vector2,
}
