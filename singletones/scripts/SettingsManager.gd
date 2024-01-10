extends Node

enum QUALITY {
	MIN,
	MID,
	MAX,
}

const settings_path = "user://settings.thss"

var default_settings = {
	"sound": 1,
	"music": 1,
	"quality": QUALITY.MAX,
	"game_speed": 1,
	"autopause": true,
	"vsync": true,
	"scale": 1,
	"filter": true,
	"fullscreen": false,
	"first_launch": true,
	"controls": {
		"m_up": _get_current_key(&"m_up"),
		"m_down": _get_current_key(&"m_down"),
		"m_left": _get_current_key(&"m_left"),
		"m_right": _get_current_key(&"m_right"),
		"m_jump": _get_current_key(&"m_jump"),
		"m_run": _get_current_key(&"m_run"),
		"m_attack": _get_current_key(&"m_attack"),
		"pause_toggle": _get_current_key(&"pause_toggle"),
	},
}

var settings = default_settings.duplicate(true)

func _ready() -> void:
	load_settings()

## Returns the key label of specified action
func _get_current_key(action: StringName) :
	var keys = InputMap.action_get_events(action)
	for key in keys:
		if key is InputEventKey:
			return key.as_text().split(' (')[0]

## Loads controls settings to InputMap
func _load_keys() -> void:
	var controls = settings.controls
	for action in controls:
		if controls[action] and controls[action] is String:
			var scancode = OS.find_keycode_from_string(controls[action])
			var key = InputEventKey.new()
			key.keycode = scancode
			if key is InputEventKey:
				var oldKeys = InputMap.action_get_events(action)
				for toRemove in oldKeys:
					if toRemove is InputEventKey:
						InputMap.action_erase_event(action, toRemove)
				InputMap.action_add_event(action, key)
	
	print("[Settings Manager] Loaded input maps from settings.")

## Saves the settings variable to file
func save_settings() -> void:
	var data = JSON.stringify(settings)
	
	var file: FileAccess = FileAccess.open(settings_path, FileAccess.WRITE)
	file.store_string(data)
	file.close()
	
	print("[Settings Manager] Settings saved!")

## Loads the settings variable from file
func load_settings() -> void:
	var path: String = settings_path
	if !FileAccess.file_exists(path):
		print("[Settings Manager] Using the default settings, no saved ones.")
		return
	
	var data: String = FileAccess.get_file_as_string(path)
	var dict = JSON.parse_string(data)
	
	if dict == null:
		OS.alert("Failed to load saved settings " + name, "Can't load save file!")
		return
	
	settings = dict
	_check_for_validity()
	_process_settings()
	print("[Settings Manager] Loaded settings from file.")

func _check_for_validity() -> void:
	for i in default_settings.keys():
		if !i in settings:
			settings[i] = default_settings[i]

## Processes certain settings and applies their effects
func _process_settings() -> void:
	# Game Speed
	Engine.time_scale = settings.game_speed
	
	# Vsync
	var current_vsync = DisplayServer.window_get_vsync_mode(0)
	if settings.vsync && current_vsync != DisplayServer.VSYNC_ENABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	elif !settings.vsync && current_vsync != DisplayServer.VSYNC_DISABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# Scale
	_window_scale_logic()
	
	# Filter
	GlobalViewport.container.material.set_shader_parameter(
		&"enable",
		!settings.filter && GlobalViewport.container.scale.y != 1
	)
	#GlobalViewport.vp.canvas_item_default_texture_filter = settings.filter
	
	ProjectSettings.set_setting(
		&"rendering/textures/canvas_textures/default_texture_filter",
		int(settings.filter)
	)
	
	# Music Volume
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(settings.music)
	)
	
	# Sound Volume
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Sound"),
		linear_to_db(settings.sound)
	)

var old_scale: float = -1
func _window_scale_logic() -> void:
	if settings.scale == 0: return
	if old_scale == settings.scale: return
	
	var current_screen: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_usable_rect(current_screen).size
	var screen_center: Vector2i = screen_size / 2
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	) * settings.scale)
	if old_scale != 0 || settings.scale > 1:
		DisplayServer.window_set_position(
			screen_center - (DisplayServer.window_get_size() / 2)
		)
		GlobalViewport._update_view()
	
	old_scale = settings.scale
