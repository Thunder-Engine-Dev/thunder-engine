extends MenuSelection

@onready var text_rect: TextureRect = $Text
@onready var valu: HBoxContainer = $Value

func _process(delta: float) -> void:
	valu.modulate.a = text_rect.modulate.a if focused else 0.0


func _handle_select(mouse_input: bool = false) -> void:
	# :cringe: :cringe: :cringe: :cringe: :cringe: :cringe: :cringe: :cringe: 
	#var scene = get_parent().get_parent().get_parent()
	
	super(mouse_input)
	GlobalViewport.vp.get_camera_2d().position.x += 640
	GlobalViewport.vp.get_camera_2d().reset_physics_interpolation()
	await get_tree().physics_frame
	Scenes.current_scene.get_node("Settings/SubViewportContainer/SubViewport/Options").focused = false
	var controls_scene = Scenes.current_scene.get_node("Controls")
	controls_scene.reset_menus()
	controls_scene.get_node("SubViewportContainer/SubViewport/Options").focused = true
