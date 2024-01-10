extends MenuSelection

@export var type: String

var change_sound = preload("res://engine/components/hud/sounds/scoring.wav")

func _handle_select() -> void:
	return


func _physics_process(delta: float) -> void:
	super(delta)
	
	$Value.value = SettingsManager.settings[type] * 10
	
	if !focused || !get_parent().focused: return
	var old_value = SettingsManager.settings[type]
	
	if Input.is_action_just_pressed("ui_right"):
		SettingsManager.settings[type] = clamp(old_value + 0.1, 0, 1)
		_toggled_option(old_value, SettingsManager.settings[type])
		
	if Input.is_action_just_pressed("ui_left"):
		SettingsManager.settings[type] = clamp(old_value - 0.1, 0, 1)
		_toggled_option(old_value, SettingsManager.settings[type])


func _toggled_option(old_val, new_val) -> void:
	if old_val == new_val: return
	Audio.play_1d_sound(change_sound, true, { "ignore_pause": true })
	SettingsManager._process_settings()
	
