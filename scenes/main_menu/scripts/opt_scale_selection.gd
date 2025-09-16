extends MenuSelection

@export var viewport_height: int = 480

const toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")
const bump = preload("res://engine/objects/bumping_blocks/_sounds/bump.wav")
var is_custom: bool = false

@onready var _value: TextureRect = $Value
var _fullscr: bool

func _handle_select(mouse_input: bool = false) -> void:
	if !focused || !get_parent().focused: return
	
	_fullscr = SettingsManager.settings.fullscreen
	if _fullscr:
		Audio.play_1d_sound(bump, true, { "ignore_pause": true, "bus": "1D Sound" })
		return
	var user_screen := float(DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()).y)
	var max_val: float = 4.0
	
	max_val = floorf((user_screen / viewport_height) * 2.0) / 2.0
	print(max_val)
	
	var old_value = SettingsManager.settings.scale
	if old_value == 0:
		SettingsManager.settings.scale = 1
	else:
		SettingsManager.settings.scale = wrapf(old_value + 0.5, 1, max_val + 0.5)
	_toggled_option(old_value, SettingsManager.settings.scale)


func _physics_process(delta: float) -> void:
	super(delta)
	if (
		(fmod(GlobalViewport.container.scale.x, 0.5) == 0 ||
		fmod(GlobalViewport.container.scale.y, 0.5) == 0)
	):
		_value.texture.region.position.y = 38 * (-1 + GlobalViewport.container.scale.x * 2)
		is_custom = true
	else:
		_value.texture.region.position.y = 0
		is_custom = false
	
	_fullscr = SettingsManager.settings.fullscreen
	if _fullscr:
		_value.modulate.v = 0.5
	else:
		_value.modulate.v = 1.0
	
	if !focused: return
	
	if Input.is_action_just_pressed("ui_right"):
		if _fullscr:
			Audio.play_1d_sound(bump, true, { "ignore_pause": true, "bus": "1D Sound" })
			return
		var old_value = SettingsManager.settings.scale
		if old_value == 0:
			SettingsManager.settings.scale = 1
		else:
			SettingsManager.settings.scale = clamp(old_value + 0.5, 1, 4)
		_toggled_option(old_value, SettingsManager.settings.scale)
		
	if Input.is_action_just_pressed("ui_left"):
		if _fullscr:
			Audio.play_1d_sound(bump, true, { "ignore_pause": true, "bus": "1D Sound" })
			return
		var old_value = SettingsManager.settings.scale
		SettingsManager.settings.scale = clamp(old_value - 0.5, 1, 4)
		_toggled_option(old_value, SettingsManager.settings.scale)
		#if is_custom:
			#if DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		#	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		#	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _toggled_option(old_val, new_val) -> void:
	if old_val == new_val: return
	var _sfx = CharacterManager.get_sound_replace(toggle_sound, toggle_sound, "menu_toggle", false)
	Audio.play_1d_sound(_sfx, true, { "ignore_pause": true, "bus": "1D Sound" })
	SettingsManager.no_saved_settings = false
	SettingsManager._process_settings()
	
