extends MenuSelection

@export var type: String

var change_sound = preload("res://engine/components/hud/sounds/scoring.wav")

func _physics_process(delta: float) -> void:
	super(delta)
	if !focused || !get_parent().focused: return
	
	if Input.is_action_just_pressed("ui_right"):
		SettingsManager.settings[type] = clamp(SettingsManager.settings[type] + 0.1, 0, 1)
		Audio.play_1d_sound(change_sound)
		SettingsManager._process_settings()
		
	if Input.is_action_just_pressed("ui_left"):
		SettingsManager.settings[type] = clamp(SettingsManager.settings[type] - 0.1, 0, 1)
		Audio.play_1d_sound(change_sound)
		SettingsManager._process_settings()
	
	$Value.value = SettingsManager.settings[type] * 10
