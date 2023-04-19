extends Transition

var paused: bool = false
var speed_closing: float = 0.05
var speed_opening: float = -0.05
var circle: float = 1.0
var middle_switch: bool = false
@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	resized.connect(func():
		if !color_rect: return
		var rect = get_rect()
		color_rect.material.set_shader_parameter("screen_width", rect.size.x)
		color_rect.material.set_shader_parameter("screen_height", rect.size.y)
	)
	
	start.emit()

## Sets the center of transition on some node
func on(ref: Node2D) -> Transition:
#	var window_size = DisplayServer.window_get_size()
#	var pos = ref.global_position
#	var window_pos_x = int(pos.x / window_size.x) * window_size.x #+ (window_size.x / 2)
#	var window_pos_y = int(pos.y / window_size.y) * window_size.y #+ (window_size.y / 2)
#	print(window_pos_x)
#	print(window_pos_y)
#	var final_pos = (pos - Vector2(window_pos_x, window_pos_y)) / (window_size * 1.0)
#	print(final_pos)
#	color_rect.material.set_shader_parameter("center", pos)
# TBI
	if !ref: return self
	color_rect.material.set_shader_parameter("center", Thunder.view.get_pos_ratio_in_screen(ref))
	return self


## Sets the speeds
func with_speeds(s_closing: float, s_opening: float) -> Transition:
	speed_closing = s_closing
	speed_opening = s_opening
	return self


func _physics_process(delta: float) -> void:
	if paused: return
	
	if circle >= 0:
		circle = max(circle - speed_closing * Thunder.get_delta(delta), 0)
	
	if circle == 0 && !middle_switch:
		middle.emit()
		middle_switch = true
		speed_closing = speed_opening
	
	if middle_switch && circle > 2:
		end.emit()
	
	color_rect.material.set_shader_parameter("circle_size", circle)
