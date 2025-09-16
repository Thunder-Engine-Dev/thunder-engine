extends MenuSelection

@onready var pause: Control = $"../.."
@onready var v_box_container: MenuItemsController = $".."


func _handle_select(mouse_input: bool = false) -> void:
	Audio.stop_all_sounds()
	super()
	Scenes.custom_scenes.pause._no_unpause = false
	pause.toggle(true)
	v_box_container.focused = false
	#await get_tree().create_timer(0.4).timeout
	Data.technical_values.impulse_progress_continue = true
	Scenes.goto_scene(ProjectSettings.get("application/thunder_settings/save_game_room_path"))
