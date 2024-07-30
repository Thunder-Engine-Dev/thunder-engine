extends Transition

var paused: bool = false
var speed_closing: float = 0.05
var speed_opening: float = -0.05
var circle: float = 1.0
var middle_switch: bool = false
var _is_with_pause: bool = false
@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	name = "circle_transition"
	#resized.connect(func():
	#	if !color_rect: return
	#	var rect = get_rect()
	#	color_rect.material.set_shader_parameter("screen_width", rect.size.x)
	#	color_rect.material.set_shader_parameter("screen_height", rect.size.y)
	#)
	
	start.emit()

## Sets the center of transition on some node
func on(ref: Variant, direct = false) -> Transition:
	if ref is Node2D: 
		color_rect.material.set_shader_parameter(&"center", Thunder.view.get_pos_ratio_in_screen(ref))
	elif ref is Vector2:
		if !direct:
			color_rect.material.set_shader_parameter(&"center", Thunder.view.get_pos_ratio_in_screen_by_pos(get_viewport_transform(), get_viewport_rect().size, ref))
		else:
			color_rect.material.set_shader_parameter(&"center", ref)
	
	return self

## Sets the speeds
func with_speeds(s_closing: float, s_opening: float) -> Transition:
	speed_closing = s_closing
	speed_opening = s_opening
	return self


func with_pause() -> Transition:
	_is_with_pause = true
	return self


func _physics_process(delta: float) -> void:
	if paused: return
	
	color_rect.material.set_shader_parameter("circle_size", circle)
	
	if circle == 0 && !middle_switch:
		if _is_with_pause:
			TransitionManager.current_transition.paused = true
		await get_tree().physics_frame
		middle.emit()
		if _is_with_pause:
			Scenes.scene_ready.connect(func():
				TransitionManager.current_transition.paused = false
			, CONNECT_ONE_SHOT)
		await get_tree().physics_frame
		middle_switch = true
		speed_closing = speed_opening
	
	if middle_switch && circle > 2:
		end.emit()
	
	if circle >= 0:
		circle = max(circle - speed_closing * Thunder.get_delta(delta), 0)
	
