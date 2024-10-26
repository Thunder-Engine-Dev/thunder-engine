extends MenuSelection

@onready var value = $Value
var changing: bool = false
var old_device_name: String = ""

const toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")


func _handle_select(mouse_input: bool = false) -> void:
	return


func _physics_process(delta: float) -> void:
	super(delta)

	if !get_parent().focused: return

	if SettingsManager.device_keyboard:
		value.texture.region.position.y = 60
	else:
		value.texture.region.position.y = 30

	if !focused: return

	var joy_name: String = Input.get_joy_name(0)
	if old_device_name != joy_name:
		old_device_name = joy_name
		SettingsManager.device_name = joy_name
		SettingsManager.device_keyboard = joy_name.is_empty()
		if SettingsManager.device_keyboard:
			print("Gamepad not connected, using keyboard by default.")
		else:
			print(SettingsManager.device_name)

	if Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("ui_left"):
		SettingsManager.device_keyboard = !SettingsManager.device_keyboard
		SettingsManager.device_name = Input.get_joy_name(0)
		Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
