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
		var old_value = SettingsManager.settings.quality
		SettingsManager.settings.quality = clamp(old_value + 1, 0, 2)
		_toggled_option(old_value, SettingsManager.settings.quality)
		
	if Input.is_action_just_pressed("ui_left"):
		var old_value = SettingsManager.settings.quality
		SettingsManager.settings.quality = clamp(old_value - 1, 0, 2)
		_toggled_option(old_value, SettingsManager.settings.quality)


func _toggled_option(old_val, new_val) -> void:
	if old_val == new_val: return
	Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true })
	SettingsManager._process_settings()
	_update_string()


func _update_string() -> void:
	if SettingsManager.settings.quality == SettingsManager.QUALITY.MIN:
		$Value.texture.region.position.y = 32
	if SettingsManager.settings.quality == SettingsManager.QUALITY.MID:
		$Value.texture.region.position.y = 64
	if SettingsManager.settings.quality == SettingsManager.QUALITY.MAX:
		$Value.texture.region.position.y = 0
	
