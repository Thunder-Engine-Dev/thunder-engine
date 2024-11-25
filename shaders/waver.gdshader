shader_type canvas_item;

uniform float wave_amplitude = 0.0;
uniform float wave_frequency = 0.0;
uniform float wave_speed = 1.0;
uniform bool y_axis = false;
varying vec4 v_vertex_color;

void vertex() {
	v_vertex_color = COLOR;
}

float calculate_diff(float uv, float amp, float freq, float spd){
	float diff_x = amp * sin((freq * uv) + (TIME * spd));
	return diff_x;
}

void fragment(){
	float uv_mod;
	if (y_axis) {
		uv_mod = UV.x;
	} else {
		uv_mod = UV.y;
	}
	float wav_x = calculate_diff(uv_mod, wave_amplitude, wave_frequency, wave_speed);

	if ( int( uv_mod * 1.0 ) % 2 == 0)
	{
		wav_x = -wav_x;
	}

	vec4 textube;
	if (y_axis) {
		textube = texture(TEXTURE, vec2(uv_mod, UV.y + wav_x));
	} else {
		textube = texture(TEXTURE, vec2(UV.x + wav_x, uv_mod));
	}

	COLOR = v_vertex_color * textube;
}