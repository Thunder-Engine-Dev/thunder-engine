shader_type canvas_item;

varying vec4 v_vertex_color;

void vertex() {
	v_vertex_color = COLOR;
}

void fragment(){
	vec4 color = texture(TEXTURE, UV);

	COLOR = vec4(1.0 - color.rgb, color.a);
	COLOR *= v_vertex_color;
}