extends MenuSelection

var _timer: float
@onready var valu: HBoxContainer = $Value

func _physics_process(delta: float) -> void:
	super(delta)
	if focused:
		_timer += delta * 10
		valu.modulate.a = min((cos(_timer) / 4) + 0.75, 1.0)
	else:
		valu.modulate.a = 0.0
		_timer = 0


func _handle_select(mouse_input: bool = false) -> void:
	var scene = Scenes.custom_scenes.pause.get_parent()
	super(mouse_input)
	scene.offset.x -= 640
	scene.reset_physics_interpolation()
	await get_tree().physics_frame
	scene.get_node("Settings/SubViewportContainer/SubViewport/Options").focused = false
	scene.get_node("Controls/SubViewportContainer/SubViewport/Options").focused = true
