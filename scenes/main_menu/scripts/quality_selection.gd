extends MenuSelection

var toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")
@onready var value = $Value

func _ready():
	_update_string.call_deferred()
	SettingsManager.settings_updated.connect(_update_string)


func _handle_select(mouse_input: bool = false) -> void:
	if !focused || !get_parent().focused: return
	var old_value = SettingsManager.get_quality()
	
	SettingsManager.settings.quality = wrapi(old_value + 1, 0, 3)
	_toggled_option(old_value, SettingsManager.settings.quality)


func _physics_process(delta: float) -> void:
	super(delta)
	if !get_parent().focused: return
	if !focused: return
	
	if Input.is_action_just_pressed("ui_right"):
		var old_value = SettingsManager.get_quality()
		SettingsManager.settings.quality = clamp(old_value + 1, 0, 2)
		_toggled_option(old_value, SettingsManager.settings.quality)
		
	if Input.is_action_just_pressed("ui_left"):
		var old_value = SettingsManager.get_quality()
		SettingsManager.settings.quality = clamp(old_value - 1, 0, 2)
		_toggled_option(old_value, SettingsManager.settings.quality)


func _toggled_option(old_val, new_val) -> void:
	if old_val == new_val: return
	Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
	SettingsManager._process_settings()
	_update_string()


func _update_string() -> void:
	match SettingsManager.get_quality():
		SettingsManager.QUALITY.MIN:
			value.texture.region.position.y = 32
		SettingsManager.QUALITY.MID:
			value.texture.region.position.y = 64
		SettingsManager.QUALITY.MAX:
			value.texture.region.position.y = 0
	
