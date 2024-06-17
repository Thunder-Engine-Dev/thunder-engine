extends Node2D

const STARFALL_EFFECT = preload("res://engine/objects/effects/starfall/starfall_effect.tscn")
var timer: float

func _physics_process(delta: float) -> void:
	var cam: Camera2D = Thunder._current_camera
	if !cam: return
	
	var cam_pos: Vector2 = cam.get_screen_center_position()
	timer += delta
	if timer > 0.3:
		timer = 0.0
		if randi_range(0, 5) == 0:
			var efekt = STARFALL_EFFECT.instantiate()
			add_child(efekt)
			efekt.global_position = Vector2(cam_pos.x + randi_range(-220, 500), -8)
