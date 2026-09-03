shader_type canvas_item;
render_mode blend_premul_alpha;

uniform bool enable = true;
varying float vertex_alpha;

void vertex() {
	vertex_alpha = COLOR.a;
}

vec4 texturePointSmooth(sampler2D tex, vec2 uv) {
	vec2 size = vec2(textureSize(tex, 0));
	vec2 pixel = vec2(1.0) / size;
	uv -= pixel * vec2(0.5);
	vec2 uv_pixels = uv * size;
	vec2 delta_pixel = fract(uv_pixels) - vec2(0.5);
	vec2 ddxy = fwidth(uv_pixels);
	vec2 mip = log2(ddxy) - 0.5;
	return textureLod(tex, uv + (clamp(delta_pixel / ddxy, 0.0, 1.0) - delta_pixel) * pixel, min(mip.x, mip.y));
}

void fragment() {
	vec4 tex = enable ? texturePointSmooth(TEXTURE, UV) : texture(TEXTURE, UV);
	COLOR = tex;
	COLOR.a *= vertex_alpha;
}