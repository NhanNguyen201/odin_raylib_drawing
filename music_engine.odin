package main
import rl "vendor:raylib"
import "core:math"


Music_System :: struct {
    bpm: f32,
    playing: bool,

    current_step: int,
    timer: f32,
    music_tracks : [dynamic]Music_Track,
    generated_notes: map[int]rl.Sound
}

Note :: enum {
    C4,
    D4,
    E4,
    F4,
    G4,
    A4,
    B4
}

Music_Track :: struct {
    note_name: Note,

    steps: [BEAT_STEP_NUMB]bool,
}


Instrument :: struct {
    waveform: Wave_Type
}

Wave_Type :: enum {
    Sine,
    Square,
    Saw,
}

note_to_freq :: proc(midi: int) -> f32 {

    return 440 *math.pow(2, f32(midi - 69) / 12)
}
generate_sine_note :: proc( freq: f32, seconds: f32) -> rl.Sound {

    @static sample_rate: u32 = 44100

    count := int( f32(sample_rate) * seconds )

    samples  := make([]i16, count)

    for i in 0..<count {

        t := f32(i) / f32(sample_rate)

        value := abs(math.sin_f32(2 * math.PI * freq * t )) * 0.375 + 0.125 

        samples[i] = i16( value * 32727 )
    }

    // return rl.LoadWa(raw_data(data),count,sample_rate, 32,1)
    wave := rl.Wave{
        frameCount = u32(count),
        sampleRate = sample_rate,
        sampleSize = 16,
        channels = 1,

        data = raw_data(samples),
    }
    delete(samples)
    return rl.LoadSoundFromWave(wave)
}

music_update :: proc(music: ^Music_System) {

    if rl.IsKeyPressed(.O) {
        music.playing = !music.playing
    }

    if !music.playing {
        return
    }

    step_time := 60.0 / (music.bpm  *4)

    music.timer += rl.GetFrameTime()

    for music.timer >= step_time {

        music.timer -= step_time

        music.current_step += 1

        music.current_step %= BEAT_STEP_NUMB

        trigger_step(
            music
        )
    }

}

trigger_step :: proc(music: ^Music_System) {

    for track in music.music_tracks {
        sound := music.generated_notes[get_note_pitch(track.note_name)]
        for step, step_idx in track.steps {
        
            if step && step_idx == music.current_step{
    
    
                rl.PlaySound(
                    sound
                )
            }
        

        }
    }

}


get_note_pitch :: proc(note: Note) -> int {
    midi :int
    switch(note) {
        case .C4 : midi = 60
        case .D4 : midi = 62
        case .E4 : midi = 64
        case .F4 : midi = 65
        case .G4 : midi = 67
        case .A4 : midi = 69
        case .B4 : midi = 71
    }
    return midi
}