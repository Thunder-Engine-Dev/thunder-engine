extends MenuSelection

const toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")

@onready var value: Label = $Value


func _ready() -> void:
	SettingsManager.mouse_pressed.connect(_on_mouse_pressed)
	_update_string()


func _handle_select(mouse_input: bool = false) -> void:
	if !focused || !get_parent().focused: return
	_cycle_hint(1)


func _physics_process(delta: float) -> void:
	super(delta)
	if get_parent().focused:
		_update_string()
	if !get_parent().focused: return
	if !focused: return

	if Input.is_action_just_pressed("ui_right"):
		_cycle_hint(1)
	elif Input.is_action_just_pressed("ui_left"):
		_cycle_hint(-1)


func _cycle_hint(direction: int) -> void:
	var options := SettingsManager.GAMEPAD_HINT_OPTIONS
	var current := SettingsManager.get_gamepad_hint()
	var idx := options.find(current)
	if idx < 0:
		idx = 0
	var next: String = options[wrapi(idx + direction, 0, options.size())]
	if next == SettingsManager.settings.get("gamepad_hint", ""):
		return
	SettingsManager.settings.gamepad_hint = next
	var _sfx = CharacterManager.get_sound_replace(toggle_sound, toggle_sound, "menu_toggle", false)
	Audio.play_1d_sound(_sfx, true, { "ignore_pause": true, "bus": "1D Sound" })
	SettingsManager._process_settings()
	_update_string()


func _update_string() -> void:
	value.text = SettingsManager.get_gamepad_hint()


func _on_mouse_pressed(index: MouseButton) -> void:
	if !mouse_hovered || !focused || !get_parent().focused: return
	if index != MOUSE_BUTTON_LEFT: return
	_cycle_hint(1)
