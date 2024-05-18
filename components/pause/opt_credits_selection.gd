extends "res://engine/scenes/main_menu/scripts/opt_credits_selection.gd"

var disabled: bool

func _add_scene_tree_entered(credits) -> void:
	get_parent().focused = false
	Pause.visible = false
	super(credits)
	

func _add_scene_tree_exited(canvas_layer: CanvasLayer) -> void:
	get_parent().focused = true
	Pause.visible = true
	super(canvas_layer)
