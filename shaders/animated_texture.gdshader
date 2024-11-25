shader_type canvas_item;

uniform sampler2D sprite_sheet : filter_nearest, repeat_enable;
uniform vec2 frame_size = vec2(1.0, 1.0);
uniform uint frame_count = 1;
uniform uint frames_per_row = 1;
uniform float time_scale = 1.0;

uniform uint frame_offset = 0;
varying vec4 v_vertex_color;

void vertex() {
	v_vertex_color = COLOR;
}

void fragment() {
    uint frame = (uint(TIME * time_scale) + frame_offset) % frame_count;

    vec2 uv = (UV + vec2(
        float(frame % frames_per_row),
        float(frame / frames_per_row)
    )) / frame_size;
    
    COLOR = v_vertex_color * texture(sprite_sheet, uv);
}
