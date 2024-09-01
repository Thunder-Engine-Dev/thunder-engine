shader_type canvas_item;

// The color that flashes when highlighting the sprite
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Used to control the time between flashes
uniform float frequency : hint_range(0.0, 25.0) = 0.35;

// Speed of each flash
uniform float highlight_speed : hint_range(0.0, 25.0) = 6.0;

// How much area each flash covers (width)
uniform float highlight_width : hint_range(0.0, 50.0) = 15.0;

void fragment( )
{
	vec4 input_color = texture(TEXTURE, UV);
	float width = 0.001 * frequency * highlight_width / 2.0;
	
	// can play with + or - sign for each UV
	// to control which direction the highlight moves
	// ex. -UV.x - UV.y makes the highlight go from
	// top left to bottom right
	float value = floor(sin(frequency * ((UV.x - UV.y) + TIME * highlight_speed)) + width);
	
	// used to control when to use input color vs highlight color
	float highlight = value > 0.5? 1.0: 0.0;
	vec3 new_color = input_color.rgb * (1.0 - highlight) + highlight_color.rgb * highlight;
	COLOR = vec4(new_color, input_color.a);
}