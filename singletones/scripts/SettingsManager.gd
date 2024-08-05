extends Node

enum QUALITY {
	MIN,
	MID,
	MAX,
}

const settings_path = "user://settings.thss"
const tweaks_path = "user://tweaks.thss"

var default_settings = {
	"sound": 1,
	"music": 1,
	"quality": QUALITY.MAX,
	"game_speed": 1,
	"autopause": true,
	"vsync": true,
	"scale": 1,
	"physics_tps": 0,
	"filter": false,
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
var no_saved_settings: bool = false

var tweaks: Dictionary = {}

signal settings_updated
signal settings_saved
signal settings_loaded
signal tweaks_updated
signal tweaks_saved
signal tweaks_loaded

func _ready() -> void:
	load_settings()
	load_tweaks()

## Get ProjectSettings "tweak" located in path "application/thunder_settings/tweaks"
func get_tweak(tweak_name: String, default_value: Variant = null) -> Variant:
	return ProjectSettings.get_setting("application/thunder_settings/tweaks/" + tweak_name, default_value)

## Set ProjectSettings "tweak" to a new value
func set_tweak(tweak_name: String, value: Variant) -> void:
	ProjectSettings.set_setting("application/thunder_settings/tweaks/" + tweak_name, value)
	tweaks[tweak_name] = value
	tweaks_updated.emit()

## Returns the key label of specified action
func _get_current_key(action: StringName) :
	var keys = InputMap.action_get_events(action)
	for key in keys:
		if key is InputEventKey:
			return key.as_text().get_slice(' (', 0)

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
	
	settings_saved.emit()
	print("[Settings Manager] Settings saved!")

## Loads the settings variable from file
func load_settings() -> void:
	var path: String = settings_path
	if !FileAccess.file_exists(path):
		print("[Settings Manager] Using the default settings, no saved ones.")
		no_saved_settings = true
		return
	
	var data: String = FileAccess.get_file_as_string(path)
	var dict = JSON.parse_string(data)
	
	if dict == null:
		OS.alert("Failed to load saved settings " + name, "Can't load save file!")
		return
	
	settings = dict
	_check_for_validity()
	_process_settings()
	settings_loaded.emit()
	print("[Settings Manager] Loaded settings from a file.")

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
	
	# Fullscreen
	if !settings.fullscreen && DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		if OS.get_name() == "Windows":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		SettingsManager._window_scale_logic(true)
	elif settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	# Physics TPS
	if settings.physics_tps <= 0:
		var rate: int = ceili(DisplayServer.screen_get_refresh_rate())
		if rate < 119:
			Engine.physics_ticks_per_second = rate * 2
			print(&"Using double tps for physics")
		else:
			Engine.physics_ticks_per_second = rate
	else:
		Engine.physics_ticks_per_second = settings.physics_tps
	
	# Filter
	GlobalViewport._update_view()
	
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
		AudioServer.get_bus_index("1D Sound"),
		linear_to_db(settings.sound)
	)
	
	settings_updated.emit()


var old_scale: float = -1
func _window_scale_logic(force_update: bool = false) -> void:
	if no_saved_settings: return
	if settings.scale == 0: return
	if old_scale == settings.scale && !force_update: return
	
	var current_screen: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_usable_rect(current_screen).size
	var screen_center: Vector2i = screen_size / 2
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	) * settings.scale)
	await get_tree().process_frame
	if old_scale != 0 || settings.scale > 1:
		DisplayServer.window_set_position(
			screen_center - (DisplayServer.window_get_size() / 2)
		)
		GlobalViewport._update_view()
	
	old_scale = settings.scale

## Saves the tweaks variable to a file
func save_tweaks() -> void:
	var data = JSON.stringify(tweaks)
	
	var file: FileAccess = FileAccess.open(tweaks_path, FileAccess.WRITE)
	file.store_string(data)
	file.close()
	
	tweaks_saved.emit()
	print("[Settings Manager] Tweaks saved!")

## Loads the settings variable from file
func load_tweaks() -> void:
	if !FileAccess.file_exists(tweaks_path):
		print("[Settings Manager] Using the default tweaks, no saved ones.")
		return
	
	var data: String = FileAccess.get_file_as_string(tweaks_path)
	var dict = JSON.parse_string(data)
	
	if dict == null:
		OS.alert("Failed to load saved tweaks " + name, "Can't load save file!")
		return
	
	tweaks = dict
	for tweak in tweaks:
		var value = tweaks[tweak]
		ProjectSettings.set_setting("application/thunder_settings/tweaks/" + tweak, value)
	
	tweaks_loaded.emit()
	print("[Settings Manager] Loaded tweaks from a file.")
