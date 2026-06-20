package main

import rl "vendor:raylib"
BEAT_STEP_NUMB :: 32
Beat_System :: struct {
    volume: f32, 
    bpm: f32,
    playing: bool,

    current_step: int,
    timer: f32,

    tracks: [dynamic]Beat_Track
}

Beat_Track :: struct {
    name: string,

    sound: rl.Sound,

    steps: [BEAT_STEP_NUMB]bool
}

beat_engine_update :: proc(beat: ^Beat_System) {
    if rl.IsKeyPressed(.SPACE) {
        beat.playing = !beat.playing
    }
    
    step_duration := 60 / (beat.bpm * 4)
    if beat.playing {
        beat.timer += rl.GetFrameTime()

        if beat.timer >= step_duration {

            beat.timer -= step_duration

            beat.current_step += 1

            beat.current_step %= BEAT_STEP_NUMB

            play_current_step(beat)
        }
    }
}

play_current_step :: proc(beat: ^Beat_System) {

    for track in beat.tracks {

        if track.steps[beat.current_step ] {
            rl.PlaySound(track.sound)
            
        }

    }

}