shader_type canvas_item;
render_mode unshaded;

varying vec4 v_vertex_color;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	v_vertex_color = COLOR;
}

void fragment() {
	vec4 self_color = texture(TEXTURE, UV) * 255.0;
	vec4 back_color = texture(SCREEN_TEXTURE, SCREEN_UV) * 255.0;
	self_color.r = float(int(self_color.r) | int(back_color.r)) / 255.0;
	self_color.g = float(int(self_color.g) | int(back_color.g)) / 255.0;
	self_color.b = float(int(self_color.b) | int(back_color.b)) / 255.0;
	COLOR = v_vertex_color * self_color;
}
