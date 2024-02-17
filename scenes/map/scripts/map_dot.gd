extends AnimatedSprite2D

func _ready() -> void:
	Scenes.current_scene.player_fast_forwarded.connect(_appear)

func _appear() -> void:
	if has_meta(&"is_appearing") && get_meta(&"is_appearing") == true:
		visible = true
