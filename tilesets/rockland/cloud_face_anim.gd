extends AnimatedSprite2D

func _ready() -> void:
	_timer()

func _timer() -> void:
	await get_tree().create_timer(randf_range(0.5, 3), false).timeout
	
	play("default")
	_timer()
