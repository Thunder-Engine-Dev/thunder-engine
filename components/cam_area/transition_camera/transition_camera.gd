extends Camera2D

var state: int = 0
var counter: float = 0

var limits: Rect2i
var speed: float = 0.04
var function: Thunder.SmoothFunction = Thunder.SmoothFunction.EASE_OUT

func _ready() -> void:
	var camera = Thunder._current_camera
	position_smoothing_enabled = true
	global_position = camera.get_screen_center_position()
	
	make_current()


func _process(delta: float) -> void:
	var camera = Thunder._current_camera
	
	Thunder.view.cam_border()
	camera.make_current()
	global_position = camera.get_screen_center_position()
	
	counter += speed * Thunder.get_delta(delta)
	if counter > 1:
		counter = 1
	
	var eased_counter: float
	
	match function:
		Thunder.SmoothFunction.LINEAR:
			eased_counter = counter
		Thunder.SmoothFunction.EASE_IN:
			eased_counter = Thunder.Math.ease_in(counter)
		Thunder.SmoothFunction.EASE_OUT:
			eased_counter = Thunder.Math.ease_out(counter)
		Thunder.SmoothFunction.EASE_IN_OUT:
			eased_counter = Thunder.Math.ease_in_out(counter)
		Thunder.SmoothFunction.EASE_IN_BACK:
			eased_counter = Thunder.Math.ease_in_back(counter)
		Thunder.SmoothFunction.EASE_OUT_BACK:
			eased_counter = Thunder.Math.ease_out_back(counter)
		Thunder.SmoothFunction.EASE_IN_OUT_BACK:
			eased_counter = Thunder.Math.ease_in_out_back(counter)
	
	var rect: Rect2i = Rect2i()
	
	rect.size = Vector2i(camera.get_viewport_rect().size)
	rect.position = Vector2i(camera.get_screen_center_position() - rect.size/2.0)
	
	Thunder.view._target_pos = rect.position
	
	limit_top = lerp(limits.position.y, rect.position.y, eased_counter)
	limit_left = lerp(limits.position.x, rect.position.x, eased_counter)
	limit_bottom = lerp(limits.end.y, rect.end.y, eased_counter)
	limit_right = lerp(limits.end.x, rect.end.x, eased_counter)
	
	make_current()
	
	if counter == 1:
		camera.make_current()
		await get_tree().physics_frame
		#Scenes.current_scene.falling_below_y_offset /= 10
		queue_free()
