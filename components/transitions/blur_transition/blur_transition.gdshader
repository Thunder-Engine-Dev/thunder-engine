shader_type canvas_item;

uniform float size = 0.008;
uniform sampler2D SCREEN_TEX: hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	float block_pixels = size / SCREEN_PIXEL_SIZE.y;
	vec2 block_uv = block_pixels * SCREEN_PIXEL_SIZE;
	uv = (floor(uv / block_uv) + 0.5) * block_uv;
	
	COLOR.rgb = textureLod(SCREEN_TEX, uv, 0.0).rgb;
}