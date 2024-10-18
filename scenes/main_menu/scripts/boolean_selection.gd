extends MenuSelection

@onready var value = $Value
@export var setting_name: String

var toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")
var _mouse_pressed: bool

func _handle_select(mouse_input: bool = false) -> void:
	return


func _physics_process(delta: float) -> void:
	super(delta)

	if SettingsManager.settings[setting_name]:
		value.texture.region.position.y = 36
	else:
		value.texture.region.position.y = 0

	if !focused: return

	if Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("ui_left"):
		_toggle_setting()
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && mouse_hovered:
		if !_mouse_pressed:
			_mouse_pressed = true
			_toggle_setting()
	elif mouse_hovered:
		_mouse_pressed = false


func _toggle_setting() -> void:
	SettingsManager.settings[setting_name] = !SettingsManager.settings[setting_name]
	Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
	SettingsManager._process_settings()
