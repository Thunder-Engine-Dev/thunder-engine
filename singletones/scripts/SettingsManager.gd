extends Node

enum QUALITY {
	MIN,
	MID,
	MAX,
}

const settings_path = "user://settings.thss"
const tweaks_path = "user://tweaks.thss"
var custom_file_paths: Dictionary = {}

var default_settings: Dictionary = {
	"sound": 1,
	"music": 1,
	"quality": ProjectSettings.get_setting("application/thunder_settings/default_quality_setting", QUALITY.MAX),
	"game_speed": 1,
	"autopause": true,
	"vsync": true,
	"scale": 1,
	"physics_tps": 0,
	"filter": false,
	"fullscreen": false,
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
	"character": ProjectSettings.get_setting("application/thunder_settings/default_character_setting", "Mario"),
	"custom": {},
}

var settings: Dictionary = default_settings.duplicate(true)
var no_saved_settings: bool = false

var tweaks: Dictionary = {}

signal settings_updated
signal settings_saved
signal settings_loaded
signal tweaks_updated
signal tweaks_saved
signal tweaks_loaded
signal data_saved(id: String)
signal data_loaded(id: String)

func _ready() -> void:
	load_settings()
	_load_keys()
	load_tweaks()

## Returns a ProjectSettings "tweak" located in path "application/thunder_settings/tweaks"
func get_tweak(tweak_name: String, default_value: Variant = null) -> Variant:
	return ProjectSettings.get_setting("application/thunder_settings/tweaks/" + tweak_name, default_value)

## Sets a ProjectSettings "tweak" to a new value
func set_tweak(tweak_name: String, value: Variant) -> void:
	ProjectSettings.set_setting("application/thunder_settings/tweaks/" + tweak_name, value)
	tweaks[tweak_name] = value
	tweaks_updated.emit()

## Returns a project-specific custom setting from settings variable
func get_custom_setting(setting: String, default_value: Variant = null) -> Variant:
	if setting in settings.custom:
		return settings.custom[setting]
	settings.custom[setting] = default_value
	return default_value

## Sets a project-specific custom setting to a new value
func set_custom_setting(setting: String, value: Variant = null) -> void:
	settings.custom[setting] = value


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
		# This is needed to avoid borders being outside the monitor boundaries when you exit fullscreen
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
			# Physics rate is always set to be at least around 120 TPS for better collisions
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
	Audio._settings_music_bus_volume_db = linear_to_db(settings.music)
	
	# Sound Volume
	Audio._settings_sound_bus_volume_db = linear_to_db(settings.sound)
	
	settings_updated.emit()

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


var old_scale: float = -1
## Handles scaling the window via the Scale menu option
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


## Saves the settings variable to file
func save_settings() -> void:
	save_data(settings, settings_path, "Settings")
	
	settings_saved.emit()
	print("[Settings Manager] Settings saved!")

## Loads the settings variable from file
func load_settings() -> void:
	var loaded_data: Dictionary = load_data(settings_path, "Settings")
	if loaded_data.is_empty():
		no_saved_settings = true
		return
	
	settings = loaded_data
	_check_for_validity()
	_process_settings()
	settings_loaded.emit()
	print("[Settings Manager] Loaded settings from a file.")


## Saves the tweaks variable to a file
func save_tweaks() -> void:
	save_data(tweaks, tweaks_path, "Tweaks")
	
	tweaks_saved.emit()
	print("[Settings Manager] Tweaks saved!")

## Loads the tweaks variable from file
func load_tweaks() -> void:
	var loaded_data: Dictionary = load_data(tweaks_path, "Tweaks")
	if loaded_data.is_empty():
		return
	
	tweaks = loaded_data
	for tweak in tweaks:
		var value = tweaks[tweak]
		ProjectSettings.set_setting("application/thunder_settings/tweaks/" + tweak, value)
	tweaks_loaded.emit()
	print("[Settings Manager] Loaded tweaks from a file.")


## Loads the data
func load_data(from_path: String, id: String = "Custom") -> Dictionary:
	if !FileAccess.file_exists(from_path):
		print("[Settings Manager] %s: File does not exist. Using default values." % id)
		return {}
	
	var json: String = FileAccess.get_file_as_string(from_path)
	var dict = JSON.parse_string(json)
	
	if dict == null:
		OS.alert("Failed to load saved %s data %s" % [id, name], "Can't load save file!")
		return {}
	
	data_loaded.emit(id)
	return dict

## Saves the data
func save_data(data: Dictionary, to_path: String, id: String = "Custom") -> void:
	var json: String = JSON.stringify(data)
	
	var file: FileAccess = FileAccess.open(to_path, FileAccess.WRITE)
	file.store_string(json)
	file.close()
	
	data_saved.emit(id)
