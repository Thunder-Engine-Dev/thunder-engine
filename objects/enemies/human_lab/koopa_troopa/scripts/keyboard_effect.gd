extends Node2D

const KEYBOARD_EFFECT = preload("res://engine/objects/enemies/human_lab/koopa_troopa/keyboard_effect.tscn")
## Vector2.INF means default speed
@export var set_speed_min_quality: Vector2 = Vector2(0, -600)
## Vector2.INF means default speed
@export var set_speed_other_quality: Vector2 = Vector2.INF

func create() -> void:
	var keyboard = KEYBOARD_EFFECT.instantiate()
	var quality = SettingsManager.get_quality()
	if set_speed_other_quality != Vector2.INF && quality != SettingsManager.QUALITY.MIN:
		keyboard.default_speed_x_min = set_speed_other_quality.x
		keyboard.default_speed_x_max = set_speed_other_quality.x
		keyboard.speed = set_speed_other_quality
	elif set_speed_min_quality != Vector2.INF && quality == SettingsManager.QUALITY.MIN:
		keyboard.default_speed_x_min = set_speed_min_quality.x
		keyboard.default_speed_x_max = set_speed_min_quality.x
		keyboard.speed = set_speed_min_quality
	Scenes.current_scene.add_child(keyboard)
	keyboard.position = global_position
	keyboard.reset_physics_interpolation()
