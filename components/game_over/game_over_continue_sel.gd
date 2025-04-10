extends MenuSelection

@export var block_if_no_continues: bool = false

@onready var pause: Control = $"../.."

func _handle_select(mouse_input: bool = false) -> void:
	if block_if_no_continues && Data.technical_values.remaining_continues == 0:
		return
	var data_forced = Data.values.get("map_force_selected_marker", "")
	var data_forced_2 = Data.values.get("map_force_go_next", false)
	var data_forced_3 = Data.values.get("map_force_old_marker", "")
	super(mouse_input)
	pause.toggle(false)
	
	(func():
		if data_forced: Data.values.map_force_selected_marker = data_forced
		if data_forced_2: Data.values.map_force_go_next = data_forced_2
		if data_forced_3: Data.values.map_force_old_marker = data_forced_3
	).call_deferred()
