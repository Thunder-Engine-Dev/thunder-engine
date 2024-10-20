extends MenuSelection

@onready var value = $Value
@export var setting_name: String

var toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")

func _ready() -> void:
	SettingsManager.mouse_pressed.connect(_on_mouse_pressed)


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


func _toggle_setting() -> void:
	SettingsManager.settings[setting_name] = !SettingsManager.settings[setting_name]
	Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
	SettingsManager._process_settings()


func _on_mouse_pressed(index: MouseButton) -> void:
	if !mouse_hovered || !focused: return
	if index != MOUSE_BUTTON_LEFT: return
	
	_toggle_setting()
