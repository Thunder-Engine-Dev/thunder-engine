extends MenuSelection

@onready var value = $Value

var toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")

func _physics_process(delta: float) -> void:
	super(delta)
	
	if SettingsManager.settings["game_speed"] == 1:
		value.texture.region.position.y = 36
	else:
		value.texture.region.position.y = 0
	
	if !focused: return
	
	if Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("ui_left"):
		SettingsManager.settings["game_speed"] = 1.2 if SettingsManager.settings["game_speed"] == 1 else 1
		Audio.play_1d_sound(toggle_sound)
		SettingsManager._process_settings()
