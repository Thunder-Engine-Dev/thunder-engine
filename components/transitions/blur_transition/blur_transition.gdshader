shader_type canvas_item;

uniform float size = 0.008;
uniform sampler2D SCREEN_TEX: hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv -= mod(uv, vec2(size, size));

	COLOR.rgb = textureLod(SCREEN_TEX, uv, 0.0).rgb;
}