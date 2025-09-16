extends Node2D

const KEYBOARD_EFFECT = preload("res://engine/objects/enemies/human_lab/koopa_troopa/keyboard_effect.tscn")

func create() -> void:
	var keyboard = KEYBOARD_EFFECT.instantiate()
	Scenes.current_scene.add_child(keyboard)
	keyboard.position = global_position
	keyboard.reset_physics_interpolation()
