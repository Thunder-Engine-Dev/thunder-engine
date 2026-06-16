extends GeneralMovementBody2D

@export_category("Jumping Goomba")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var jumping_speed: float = 400
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px") var detection_radius: float = 96


func _physics_process(delta: float) -> void:
	super(delta)
	
	var player: Player = Thunder._current_player
	if !player: return
	if is_on_floor() && global_position.distance_squared_to(player.global_position) < detection_radius ** 2:
		jump(jumping_speed)
