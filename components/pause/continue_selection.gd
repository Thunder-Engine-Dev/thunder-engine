extends MenuSelection

@export var block_if_no_continues: bool = false

@onready var pause: Control = $"../.."

func _handle_select(mouse_input: bool = false) -> void:
	if block_if_no_continues && Data.technical_values.remaining_continues == 0:
		return
	super(mouse_input)
	pause.toggle(false)
