extends MenuSelection

@onready var value = $Value

var toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")

func _ready():
	_update_string()


func _handle_select() -> void:
	return


func _physics_process(delta: float) -> void:
	super(delta)
	
	if !focused: return
	
	if Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("ui_left"):
		SettingsManager.settings["game_speed"] = 1.2 if SettingsManager.settings["game_speed"] == 1.0 else 1.0
		Audio.play_1d_sound(toggle_sound, true, { &"ignore_pause": true })
		SettingsManager._process_settings()
		_update_string()


func _update_string():
	if SettingsManager.settings["game_speed"] == 1:
		value.texture.region.position.y = 36
	else:
		value.texture.region.position.y = 0
