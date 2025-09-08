extends MenuSelection

const QUIT_CONFIRMATION_LAYER = preload("res://engine/components/quit_confirmation/quit_confirmation_layer.tscn")

@onready var pause: Control = $"../.."


func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
	get_parent().focused = false
	var quit_layer = QUIT_CONFIRMATION_LAYER.instantiate()
	quit_layer.parent_items_controller = get_parent()
	add_child(quit_layer)
