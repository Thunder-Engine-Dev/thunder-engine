shader_type canvas_item;

vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);

	//vec4 limit = step(0.1, base);
	//return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

varying vec4 v_vertex_color;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void vertex() {
	v_vertex_color = COLOR;
}

void fragment() {
	vec4 scr_tex = texture(SCREEN_TEXTURE, SCREEN_UV);
	float avg = (scr_tex.r + scr_tex.g + scr_tex.b) / 3.0;
	scr_tex.rgb = vec3(avg);
	COLOR = v_vertex_color * overlay(texture(TEXTURE, UV), vec4(scr_tex.rgb, 0.5));
}