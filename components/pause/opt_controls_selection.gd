extends MenuSelection

@onready var text_rect: TextureRect = $Text
@onready var valu: HBoxContainer = $Value

func _process(delta: float) -> void:
	valu.modulate.a = text_rect.modulate.a if focused else 0.0


func _handle_select(mouse_input: bool = false) -> void:
	var scene = Scenes.custom_scenes.pause.get_parent()
	super(mouse_input)
	scene.offset.x -= 640
	scene.reset_physics_interpolation()
	await get_tree().physics_frame
	scene.get_node("Settings/SubViewportContainer/SubViewport/Options").focused = false
	scene.get_node("Controls/SubViewportContainer/SubViewport/Options").focused = true
