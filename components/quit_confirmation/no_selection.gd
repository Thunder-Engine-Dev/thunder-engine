extends MenuSelection

@onready var quit_confirm_layer: CanvasLayer = $"../../.."

func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
	quit_confirm_layer.trigger_hide()
	
	await get_tree().physics_frame
	if quit_confirm_layer.parent_items_controller:
		quit_confirm_layer.parent_items_controller.focused = true
