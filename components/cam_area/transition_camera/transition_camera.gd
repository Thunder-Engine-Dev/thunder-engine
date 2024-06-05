extends Camera2D

var state: int = 0

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
	Thunder.view.cam_border()
	global_position = camera.global_position
	
	position_smoothing_speed += 1 * Thunder.get_delta(delta)
	
	var is_close: bool = (
		get_screen_center_position().is_equal_approx(camera.get_screen_center_position())
	) || position_smoothing_speed > 35
	
	match state:
		0:
			if is_close:
				state = 1
				position_smoothing_speed = 15
				is_close = false
		1:
			var pl: Player = Thunder._current_player
			if !pl: return
			camera.global_position = pl.global_position
			if is_close:
				state = 2
		2:
			camera.make_current()
			_free.call_deferred()


func _free() -> void:
	Scenes.current_scene.falling_below_y_offset /= 10
	queue_free()
