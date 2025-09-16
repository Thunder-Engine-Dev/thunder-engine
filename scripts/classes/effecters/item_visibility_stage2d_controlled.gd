extends CanvasItem

func _ready() -> void:
	add_to_group(&"stage2d_ctrl_light")
	if !Scenes.current_scene.get(&"is_lighting_visible"):
		hide()
		return
