extends MenuSelection

@onready var value = $Value

var toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")

func _ready():
	SettingsManager.mouse_pressed.connect(_on_mouse_pressed)
	await get_tree().physics_frame
	_update_string()


func _handle_select(mouse_input: bool = false) -> void:
	return


func _physics_process(delta: float) -> void:
	super(delta)
	
	if !focused: return
	
	if Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("ui_left"):
		_toggle_setting()


func _toggle_setting() -> void:
	SettingsManager.settings["game_speed"] = 1.2 if SettingsManager.settings["game_speed"] == 1.0 else 1.0
	Audio.play_1d_sound(toggle_sound, true, { &"ignore_pause": true, "bus": "1D Sound" })
	SettingsManager._process_settings()
	_update_string()


func _update_string():
	if SettingsManager.settings["game_speed"] == 1:
		value.texture.region.position.y = 36
	else:
		value.texture.region.position.y = 0


func _on_mouse_pressed(index: MouseButton) -> void:
	if !mouse_hovered || !focused || !get_parent().focused: return
	if index != MOUSE_BUTTON_LEFT: return
	
	_toggle_setting()
