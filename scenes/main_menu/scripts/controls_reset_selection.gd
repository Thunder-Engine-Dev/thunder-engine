extends MenuSelection

var device: bool = true # True is Keyboard, False is Joypad

func _ready() -> void:
	add_to_group(&"_control_select_key")


func _handle_select() -> void:
	super()
	
	if device:
		SettingsManager.settings.controls = SettingsManager.default_settings.controls.duplicate(true)
	else:
		SettingsManager.settings.controls_joypad = SettingsManager.default_settings.controls_joypad.duplicate(true)
	SettingsManager._load_keys()


func _toggle_device() -> void:
	device = !device
