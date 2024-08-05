extends MenuSelection

@onready var value = $Value
@export var setting_name: String

var toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")

func _handle_select() -> void:
	return


func _physics_process(delta: float) -> void:
	super(delta)
	
	if SettingsManager.settings[setting_name]:
		value.texture.region.position.y = 36
	else:
		value.texture.region.position.y = 0
	
	if !focused: return
	
	if Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("ui_left"):
		SettingsManager.settings[setting_name] = !SettingsManager.settings[setting_name]
		Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
		SettingsManager._process_settings()
