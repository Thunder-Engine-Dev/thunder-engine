extends MenuSelection

@onready var restart_popup: Control = $"../../../../RestartPopup/Control"

func _handle_select(mouse_input: bool = false) -> void:
	if Data.technical_values.get("credits_cooldown", 0.0) > Time.get_ticks_msec():
		return
	super(mouse_input)
	Scenes.custom_scenes.pause.get_node("../Settings/SubViewportContainer/SubViewport/Options").focused = false
	await get_tree().physics_frame
	if !SettingsManager.request_restart:
		_screen_back()
	Scenes.custom_scenes.pause.get_node("../Settings/SubViewportContainer/SubViewport/Options").focused = false
	
	SettingsManager.save_settings()
	
	if SettingsManager.request_restart:
		restart_popup.toggle()
		await restart_popup.closed
		if SettingsManager.request_restart:
			await get_tree().physics_frame
			SettingsManager.restart_application()
		else:
			_screen_back()

func _screen_back() -> void:
	Scenes.custom_scenes.pause.get_parent().offset.y += 480
	Scenes.custom_scenes.pause.get_parent().reset_physics_interpolation()
	Scenes.custom_scenes.pause.get_node("VBoxContainer").focused = true
	get_parent().move_selector(0)
