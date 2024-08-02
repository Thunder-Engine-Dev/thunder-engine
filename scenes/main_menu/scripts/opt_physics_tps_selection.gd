extends MenuSelection

var toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")

func _ready():
	_update_string.call_deferred()


func _handle_select() -> void:
	return


func _physics_process(delta: float) -> void:
	super(delta)
	if !focused: return
	
	if Input.is_action_just_pressed("ui_right"):
		var old_value = SettingsManager.settings.physics_tps
		if old_value < 120 && old_value != 0:
			SettingsManager.settings.physics_tps += 60
		else:
			SettingsManager.settings.physics_tps = 0
		_toggled_option(old_value, SettingsManager.settings.physics_tps)
		
	if Input.is_action_just_pressed("ui_left"):
		var old_value = SettingsManager.settings.physics_tps
		if old_value == 60: return
		if old_value > 0:
			SettingsManager.settings.physics_tps -= 60
		else:
			SettingsManager.settings.physics_tps = 120
		_toggled_option(old_value, SettingsManager.settings.physics_tps)
	


func _toggled_option(old_val, new_val) -> void:
	if old_val == new_val: return
	Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
	SettingsManager._process_settings()
	_update_string()


func _update_string() -> void:
	if SettingsManager.settings.physics_tps == 60:
		$Value.texture.region.position.y = 0
	elif SettingsManager.settings.physics_tps == 120:
		$Value.texture.region.position.y = 38
	else:
		$Value.texture.region.position.y = 76
	
