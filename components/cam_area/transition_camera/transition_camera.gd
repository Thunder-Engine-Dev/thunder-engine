extends Camera2D


func _ready() -> void:
	var camera = Thunder._current_camera
	position_smoothing_enabled = true
	global_position = camera.get_screen_center_position()
	
	await get_tree().physics_frame
	make_current()
	limit_top = camera.limit_top
	limit_left = camera.limit_left
	limit_right = camera.limit_right
	limit_bottom = camera.limit_bottom


func _physics_process(delta: float) -> void:
	var camera = Thunder._current_camera
	global_position = camera.global_position
	
	position_smoothing_speed += 1 * Thunder.get_delta(delta)
	
	if (
		is_equal_approx(get_screen_center_position().x, camera.get_screen_center_position().x) &&
		is_equal_approx(get_screen_center_position().y, camera.get_screen_center_position().y)
	) || position_smoothing_speed > 35:
		camera.make_current()
		queue_free()
