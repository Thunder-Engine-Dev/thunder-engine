shader_type canvas_item;
render_mode unshaded;

uniform float circle_size: hint_range(0.0, 2);
uniform float screen_width;
uniform float screen_height;
uniform vec2 center;

void fragment() {
	float ratio = screen_width / screen_height;
	float dist = distance(vec2(center.x, center.y), vec2(mix(center.x, UV.x, ratio), UV.y));
	COLOR.a = step(circle_size, dist);
}
