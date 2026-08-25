extends MenuSelection

const TWEAK_NAME := "autorun"
const toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")

@onready var value: TextureRect = $Value


func _ready() -> void:
	SettingsManager.mouse_pressed.connect(_on_mouse_pressed)
	SettingsManager.tweaks_updated.connect(_update_visual)
	_update_visual()


func _handle_select(_mouse_input: bool = false) -> void:
	return


func _physics_process(delta: float) -> void:
	super(delta)
	if !focused || !get_parent().focused: return

	if Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("ui_left"):
		_toggle_autorun()


func _toggle_autorun() -> void:
	var enabled: bool = SettingsManager.get_tweak(TWEAK_NAME, false)
	SettingsManager.save_tweak_independently(TWEAK_NAME, !enabled)
	var _sfx = CharacterManager.get_sound_replace(toggle_sound, toggle_sound, "menu_toggle", false)
	Audio.play_1d_sound(_sfx, true, { "ignore_pause": true, "bus": "1D Sound" })


func _update_visual() -> void:
	if SettingsManager.get_tweak(TWEAK_NAME, false):
		value.texture.region.position.y = 36
	else:
		value.texture.region.position.y = 0


func _on_mouse_pressed(index: MouseButton) -> void:
	if !mouse_hovered || !focused || !get_parent().focused: return
	if index != MOUSE_BUTTON_LEFT: return
	_toggle_autorun()
