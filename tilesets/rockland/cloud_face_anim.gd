extends AnimatedSprite2D

func _ready() -> void:
	_timer()
	animation_finished.connect(_on_animation_finished)

func _timer() -> void:
	await get_tree().create_timer(randf_range(0.5, 3), false).timeout
	
	if sprite_frames.has_animation(&"grin") && randi_range(1, 3) == 2 && !is_playing():
		play(&"grin")
		speed_scale = 0.3
	else:
		speed_scale = 1.0
		play("default")
	_timer()


func _on_animation_finished() -> void:
	if animation == &"grin":
		animation = &"default"
		frame = 0
		stop()
