shader_type canvas_item;

vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

varying vec4 v_vertex_color;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void vertex() {
	v_vertex_color = COLOR;
}

void fragment() {
	COLOR = v_vertex_color * overlay(texture(TEXTURE, UV), texture(SCREEN_TEXTURE, SCREEN_UV));
}