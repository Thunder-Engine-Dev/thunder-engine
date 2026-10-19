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
	"master": 0.5,
	"sound": 1.0,
	"music": 1.0,
	"quality": ProjectSettings.get_setting("application/thunder_settings/default_quality_setting", QUALITY.MAX),
	"game_speed": 1,
	"autopause": true,
	"xscroll": false,
	"vsync": 1,
	"scale": 1,
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
		"m_extra": _get_current_key(&"m_extra"),
		"pause_toggle": _get_current_key(&"pause_toggle"),
		"ui_up": _get_current_key(&"ui_up"),
		"ui_down": _get_current_key(&"ui_down"),
		"ui_left": _get_current_key(&"ui_left"),
		"ui_right": _get_current_key(&"ui_right"),
		"ui_accept": _get_current_key(&"ui_accept"),
		"ui_cancel": _get_current_key(&"ui_cancel"),
		"ui_select": _get_current_key(&"ui_select"),
		"a_tab": _get_current_key(&"a_tab"),
		"a_delete": _get_current_key(&"a_delete"),
	},
	"controls_joypad": {
		"m_up": _get_current_joykey(&"m_up"),
		"m_down": _get_current_joykey(&"m_down"),
		"m_left": _get_current_joykey(&"m_left"),
		"m_right": _get_current_joykey(&"m_right"),
		"m_jump": _get_current_joykey(&"m_jump"),
		"m_run": _get_current_joykey(&"m_run"),
		"m_attack": _get_current_joykey(&"m_attack"),
		"m_extra": _get_current_joykey(&"m_extra"),
		"pause_toggle": _get_current_joykey(&"pause_toggle"),
		"ui_up": _get_current_joykey(&"ui_up"),
		"ui_down": _get_current_joykey(&"ui_down"),
		"ui_left": _get_current_joykey(&"ui_left"),
		"ui_right": _get_current_joykey(&"ui_right"),
		"ui_accept": _get_current_joykey(&"ui_accept"),
		"ui_cancel": _get_current_joykey(&"ui_cancel"),
		"ui_select": _get_current_joykey(&"ui_select"),
		"a_tab": _get_current_joykey(&"a_tab"),
		"a_delete": _get_current_joykey(&"a_delete"),
	},
	"character": ProjectSettings.get_setting("application/thunder_settings/default_character_setting", "Mario"),
	"skin": "",
	"vibration": 0.0,
	"gamepad_hint": "",
	"custom": {},
}

var settings: Dictionary = default_settings.duplicate(true)
var no_saved_settings: bool = false
var request_restart: bool = false

var tweaks: Dictionary = {}

var device_keyboard: bool = true:
	set(value):
		if device_keyboard == value:
			return
		device_keyboard = value
		device_changed.emit(value)
var device_name: String = ""
var mouse_mode: Input.MouseMode = Input.MOUSE_MODE_HIDDEN
var game_focused: bool = true

var enable_shortcut_scene_change_keys: bool = true

## Command line flag that disables the automatic window scaling based on the system (HiDPI) scale
const NO_AUTO_HIDPI_FLAG := "--no-auto-hidpi"
## Command line argument (e.g. [code]--ui-scale=1.5[/code]) that forces [member ui_scale]
const UI_SCALE_ARG := "--ui-scale="

## 0.0 means automatic; 0.5 or above will force this scaling on all supported windows.
## Can be set with [code]--ui-scale=<value>[/code] on launch.
var ui_scale: float = _get_float_cmdline_arg(UI_SCALE_ARG)

## Whether the game window is automatically enlarged to match the system scale (HiDPI).
## Independent from [code]settings.scale[/code]. Disable with [code]--no-auto-hidpi[/code].
var auto_hidpi: bool = !_has_cmdline_flag(NO_AUTO_HIDPI_FLAG)

signal mouse_pressed(index: MouseButton)
signal mouse_released(index: MouseButton)
signal mouse_moved()
signal device_changed(is_keyboard: bool)
signal gamepad_disconnected

signal settings_updated
signal settings_saved
signal settings_loaded
signal tweaks_updated
signal tweaks_saved
signal tweaks_loaded
signal data_saved(id: String)
signal data_loaded(id: String)

var _default_tps: int = Engine.physics_ticks_per_second
var _current_mouse_pos: Vector2

@onready var _mouse_timer := Timer.new()
@onready var _display_scale_timer := Timer.new()

func _ready() -> void:
	load_settings()
	_load_keys()
	_load_joy_controls()
	load_tweaks()
	device_name = Input.get_joy_name(0)
	device_keyboard = device_name.is_empty()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	add_child(_mouse_timer)
	_display_scale_timer.wait_time = 0.25
	_display_scale_timer.autostart = true
	_display_scale_timer.timeout.connect(_check_display_scale_changed)
	add_child(_display_scale_timer)
	process_mode = Node.PROCESS_MODE_ALWAYS
	apply_custom_mouse_cursor()
	_mouse_timer.timeout.connect(func():
		if get_tree().root.get_visible_rect().has_point(SettingsManager._current_mouse_pos):
			_hide_mouse()
	)
	get_tree().root.focus_entered.connect(set_deferred.bind("game_focused", true))
	get_tree().root.focus_exited.connect(set_deferred.bind("game_focused", false))
	
	InputMap.add_action(&"asws_restart")
	var event = InputEventKey.new()
	event.keycode = KEY_F5
	InputMap.action_add_event(&"asws_restart", event)


## Returns a ProjectSettings "tweak" located in path "application/thunder_settings/tweaks"
func get_tweak(tweak_name: String, default_value: Variant = null) -> Variant:
	return ProjectSettings.get_setting("application/thunder_settings/tweaks/" + tweak_name, default_value)

## Sets a ProjectSettings "tweak" to a new value
func set_tweak(tweak_name: String, value: Variant) -> void:
	ProjectSettings.set_setting("application/thunder_settings/tweaks/" + tweak_name, value)
	tweaks[tweak_name] = value
	tweaks_updated.emit()

## Updates one tweak in memory and writes only that key to the tweaks file
func save_tweak_independently(tweak_name: String, value: Variant) -> void:
	set_tweak(tweak_name, value)
	var disk_tweaks: Dictionary = load_data(tweaks_path, "Tweaks")
	disk_tweaks[tweak_name] = value
	save_data(disk_tweaks, tweaks_path, "Tweaks")
	print("[Settings Manager] Saved tweak '%s' independently." % tweak_name)

## Returns a project-specific custom setting from settings variable
func get_custom_setting(setting: String, default_value: Variant = null) -> Variant:
	if setting in settings.custom:
		return settings.custom[setting]
	settings.custom[setting] = default_value
	return default_value

## Sets a project-specific custom setting to a new value
func set_custom_setting(setting: String, value: Variant = null) -> void:
	settings.custom[setting] = value


const GAMEPAD_HINT_XBOX: PackedStringArray = [
	"xbox", "xinput",
]
const GAMEPAD_HINT_PLAYSTATION: PackedStringArray = [
	"ps3", "ps4", "ps5",
	"dualshock", "dualsense",
	"playstation 3", "playstation 4", "playstation 5",
]
const GAMEPAD_HINT_OPTIONS: PackedStringArray = [
	"xbox", "playstation", "raw",
]


## Returns the active gamepad icon style: "xbox", "playstation", or "raw".
## An empty setting falls back to detecting the connected device.
func get_gamepad_hint() -> String:
	var hint := str(settings.get("gamepad_hint", ""))
	if hint in GAMEPAD_HINT_OPTIONS:
		return hint
	var joy_name := device_name.to_lower()
	for token in GAMEPAD_HINT_XBOX:
		if token in joy_name:
			return "xbox"
	for token in GAMEPAD_HINT_PLAYSTATION:
		if token in joy_name:
			return "playstation"
	return "raw"


func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	var was_using_gamepad := !device_keyboard
	device_name = Input.get_joy_name(0)
	if device_name.is_empty():
		device_keyboard = true
		if was_using_gamepad && !connected:
			gamepad_disconnected.emit()


func _check_for_validity() -> void:
	for i in default_settings.keys():
		if !i in settings:
			settings[i] = default_settings[i]
			continue
		if settings[i] is Dictionary && default_settings.get(i):
			for j in default_settings[i].keys():
				if !j in settings[i]:
					settings[i][j] = default_settings[i][j]
					print("[Settings] Restored %s in dict %s" % [j, i])

## Processes certain settings and applies their effects
func _process_settings() -> void:
	# Game Speed
	Engine.time_scale = settings.game_speed
	@warning_ignore("narrowing_conversion")
	Engine.physics_ticks_per_second = Engine.time_scale * _default_tps

	# Vsync
	var current_vsync = DisplayServer.window_get_vsync_mode(0)
	if settings.vsync > 0:
		var xbuffer = ProjectSettings.get_setting("rendering/rendering_device/vsync/swapchain_image_count", 2)
		if xbuffer != (settings.vsync + 1):
			ProjectSettings.set_setting(
				"rendering/rendering_device/vsync/swapchain_image_count",
				mini(settings.vsync + 1, 3)
			)
			DisplayServer.window_set_vsync_mode(current_vsync)
	if settings.vsync && current_vsync != DisplayServer.VSYNC_ENABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	elif !settings.vsync && current_vsync != DisplayServer.VSYNC_DISABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	# Scale
	_window_scale_logic()

	# Fullscreen
	_fullscreen_logic()

	# Filter
	GlobalViewport._update_view()

	ProjectSettings.set_setting(
		&"rendering/textures/canvas_textures/default_texture_filter",
		int(settings.filter)
	)

	# Volume
	Audio._settings_master_bus_volume_db = linear_to_db(settings.master)
	Audio._settings_music_bus_volume_db = linear_to_db(settings.music)
	Audio._settings_sound_bus_volume_db = linear_to_db(settings.sound)

	settings_updated.emit()

## Returns the keyboard key label of specified action
func _get_current_key(action: StringName) -> String:
	if !InputMap.has_action(action):
		push_error("Input action " + action + " was not found. Please set up your Input Map in Project Settings to include this action.")
		return ""
	var keys = InputMap.action_get_events(action)
	for key in keys:
		if key is InputEventKey:
			return key.as_text().get_slice(' (', 0).replacen(' - Physical', '')
	return ""

## Returns the joypad button label of specified action
func _get_current_joykey(action: StringName) -> Array[JoyButton]:
	if !InputMap.has_action(action):
		return []
	var buttons = InputMap.action_get_events(action)
	var array: Array[JoyButton] = []
	for joykey in buttons:
		if joykey is InputEventJoypadButton:
			array.append(int(joykey.button_index))
		elif joykey is InputEventJoypadMotion && abs(joykey.axis_value) >= 0.5:
			array.append(int(40 + (joykey.axis * 2) + (0 if signf(joykey.axis_value) < 0 else 1)))
	return array

## Loads controls settings to InputMap
func _load_keys() -> void:
	var controls = settings.controls
	for action in controls:
		if !controls[action] || !controls[action] is String:
			continue
		
		var scancode = OS.find_keycode_from_string(controls[action])
		var key = InputEventKey.new()
		key.keycode = scancode
		if key is InputEventKey:
			var oldKeys = InputMap.action_get_events(action)
			for toRemove in oldKeys:
				if toRemove is InputEventKey:
					InputMap.action_erase_event(action, toRemove)
			InputMap.action_add_event(action, key)
	
	print("[Settings Manager] Loaded keyboard input maps from settings.")


func _load_joy_controls() -> void:
	var controls_joy: Dictionary = settings.controls_joypad
	#prints(controls_joy)
	for key in controls_joy.keys():
		var buttons_to_add: Array = []
		var actions = controls_joy[key]
		#print(actions)
		if !actions is Array:
			continue
		var oldKeys: Array[InputEvent] = InputMap.action_get_events(key)
		for joy_index in actions:
			if joy_index >= 40:
				var motion = InputEventJoypadMotion.new()
				motion.axis = (joy_index - 40) / 2
				motion.axis_value = -1.0 if wrapi(joy_index, 0, 2) == 0 else 1.0
				if motion is InputEventJoypadMotion:
					buttons_to_add.append(motion)
			else:
				var button = InputEventJoypadButton.new()
				button.button_index = joy_index
				if button is InputEventJoypadButton:
					buttons_to_add.append(button)
		
		if buttons_to_add.is_empty(): continue
		
		for toRemove in oldKeys:
			if toRemove is InputEventJoypadButton || toRemove is InputEventJoypadMotion:
				InputMap.action_erase_event(key, toRemove)
		for button in buttons_to_add:
			InputMap.action_add_event(key, button)

	print("[Settings Manager] Loaded joypad input maps from settings.")


var old_scale: float = -1
var old_auto_scale: float = -1
var _window_resize_id: int = 0
## Handles scaling the window via the Scale menu option and the automatic system (HiDPI) scale.
## If [param recenter] is false, the window keeps its center instead of moving to the screen center.
func _window_scale_logic(force_update: bool = false, recenter: bool = true) -> void:
	var auto_scale := get_window_auto_scale()
	# Without saved settings keep the default window, unless the system scale needs compensation
	if no_saved_settings && is_equal_approx(auto_scale, 1.0) && old_auto_scale < 0.0: return

	DisplayServer.window_set_min_size(Vector2i((Vector2(640, 480) * auto_scale).round()))

	if settings.scale == 0: return
	if old_scale == settings.scale && old_auto_scale == auto_scale && !force_update: return

	var should_resize: bool = old_scale != 0 || settings.scale > 1 || auto_scale > 1.0
	# Set before awaiting so repeated calls don't run concurrently
	old_scale = settings.scale
	old_auto_scale = auto_scale
	if !should_resize: return

	var new_size: Vector2 = Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	) * settings.scale * auto_scale
	var usable_size := Vector2(DisplayServer.screen_get_usable_rect(
		DisplayServer.window_get_current_screen()
	).size)
	var target_size := Vector2i(new_size.min(usable_size).round())
	_window_resize_id += 1
	var resize_id := _window_resize_id
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Set through the Window, not DisplayServer: on X11 and Wayland the window manager applies the size
	# asynchronously (and not reliably in time), while the Window keeps its own size in sync immediately
	var root := get_tree().root
	var old_center := root.position + root.size / 2
	root.size = target_size
	if recenter:
		root.move_to_center()
	else:
		_keep_window_center(old_center, target_size)
	GlobalViewport._update_view()

	# The window manager may reposition the window after resizing (or after it's first shown),
	# so center it again a few frames later
	for i in 3:
		await get_tree().process_frame
	if resize_id != _window_resize_id: return # A newer resize took over
	if recenter:
		root.move_to_center()
	else:
		_keep_window_center(old_center, target_size)
	GlobalViewport._update_view()


## Moves the window so its center is at [param center], but keeps it inside the usable screen area
func _keep_window_center(center: Vector2i, window_size: Vector2i) -> void:
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var pos := center - window_size / 2
	pos.x = clampi(pos.x, usable.position.x, maxi(usable.position.x, usable.end.x - window_size.x))
	pos.y = clampi(pos.y, usable.position.y, maxi(usable.position.y, usable.end.y - window_size.y))
	get_tree().root.position = pos


var _cursor_scale: float = 0.0
## Sets or removes the custom mouse cursor depending on the tweak.
## The cursor is scaled by the system (HiDPI) scale only, the Scale option doesn't affect it.
func apply_custom_mouse_cursor() -> void:
	if !get_tweak("custom_mouse_cursor", false):
		Input.set_custom_mouse_cursor(null)
		return
	var cursor: Texture2D = load(
		ProjectSettings.get_setting("application/thunder_settings/custom_mouse_cursor_path")
	)
	_cursor_scale = get_window_auto_scale()
	if !is_equal_approx(_cursor_scale, 1.0):
		var image := cursor.get_image()
		if image.is_compressed():
			image.decompress()
		image.resize(
			maxi(1, roundi(image.get_width() * _cursor_scale)),
			maxi(1, roundi(image.get_height() * _cursor_scale)),
			Image.INTERPOLATE_LANCZOS
		)
		cursor = ImageTexture.create_from_image(image)
	Input.set_custom_mouse_cursor(cursor)


var _last_window_pos: Vector2i
## Reapplies the window scale when the window gets moved to a screen with another system (HiDPI) scale.
## Called periodically, as [signal Window.dpi_changed] isn't implemented on Windows and X11.
func _check_display_scale_changed() -> void:
	# Wait until the window stops moving, so it isn't resized while being dragged
	var pos := DisplayServer.window_get_position()
	if pos != _last_window_pos:
		_last_window_pos = pos
		return
	var auto_scale := get_window_auto_scale()
	if !is_equal_approx(auto_scale, _cursor_scale) && get_tweak("custom_mouse_cursor", false):
		apply_custom_mouse_cursor()
	var previous_scale: float = old_auto_scale if old_auto_scale > 0.0 else 1.0
	if is_equal_approx(auto_scale, previous_scale): return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED || settings.scale == 0:
		# Nothing to resize, just remember it; the window is resized when it returns to windowed mode
		DisplayServer.window_set_min_size(Vector2i((Vector2(640, 480) * auto_scale).round()))
		old_auto_scale = auto_scale
		return
	_window_scale_logic(false, false)


func _fullscreen_logic() -> void:
	if !settings.fullscreen && DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		# This is needed to avoid borders being outside the monitor boundaries when you exit fullscreen
		if OS.get_name() == "Windows":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		await SettingsManager._window_scale_logic(true)
		# Patch for Wayland, not perfect though
		if "Linux" in OS.get_name():
			await get_tree().physics_frame
			get_window().move_to_center.call_deferred()
			get_window().grab_focus.call_deferred()
	elif settings.fullscreen && DisplayServer.window_get_mode(0) != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


## Returns the scale factor of the screen the [param window] is on, as set in the system (HiDPI).
## Snapped to 0.25 and never below 1.0.
func get_system_scale(window: Window = get_window()) -> float:
	var current_screen := DisplayServer.window_get_current_screen(window.get_window_id())
	var system_scale := DisplayServer.screen_get_scale(current_screen)
	if OS.get_name() == "Windows":
		system_scale = maxf(system_scale, DisplayServer.screen_get_dpi(current_screen) / 96.0)
	elif system_scale <= 1.0 && DisplayServer.get_name() == "X11":
		# X11 (including XWayland) doesn't report the scale, so use the desktop's Xft.dpi
		system_scale = _get_x11_scale()
	return maxf(snappedf(system_scale, 0.25), 1.0)


var _x11_scale: float = -1.0
## Returns the scale from the [code]Xft.dpi[/code] X resource (96 DPI = 1.0), or 1.0 if unavailable.
## Queried once, since it spawns a process.
func _get_x11_scale() -> float:
	if _x11_scale >= 0.0:
		return _x11_scale
	_x11_scale = 1.0
	var output: Array = []
	if OS.execute("xrdb", ["-query"], output) == 0 && !output.is_empty():
		for line: String in String(output[0]).split("\n"):
			if line.begins_with("Xft.dpi:"):
				var dpi := line.trim_prefix("Xft.dpi:").strip_edges().to_float()
				if dpi > 0.0:
					_x11_scale = dpi / 96.0
				break
	return _x11_scale


## Returns the factor the game window is enlarged by to match the system scale,
## on top of [code]settings.scale[/code]. Always 1.0 when launched with [code]--no-auto-hidpi[/code].
func get_window_auto_scale(window: Window = get_window()) -> float:
	if !auto_hidpi:
		return 1.0
	return get_system_scale(window)


## Defines UI scale, mainly for HiDPI displays. Use for external windows, e.g. the console.
func get_ui_scale(window: Window = get_window()) -> float:
	if ui_scale >= 0.5:
		return ui_scale
	return get_system_scale(window)


func scale_window(window: Window, scale: float = 1.0, no_resize: bool = false) -> void:
	var old_factor := window.content_scale_factor
	if is_equal_approx(old_factor, scale): return
	window.content_scale_factor = scale
	if no_resize:
		return
	# Resize relatively to the previous factor, not from scratch
	var ratio := scale / old_factor
	window.size = Vector2i((Vector2(window.size) * ratio).round())
	window.min_size = Vector2i((Vector2(window.min_size) * ratio).round())

	var usable_size = DisplayServer.screen_get_usable_rect(
		DisplayServer.window_get_current_screen(window.get_window_id())
	).size
	if window.size.y > usable_size.y:
		window.size.y = usable_size.y
	if window.size.x > usable_size.x:
		window.size.x = usable_size.x


static func _has_cmdline_flag(flag: String) -> bool:
	return OS.get_cmdline_args().has(flag) || OS.get_cmdline_user_args().has(flag)


static func _get_float_cmdline_arg(prefix: String) -> float:
	for arg in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix).to_float()
	return 0.0


## Saves the settings variable to file
func save_settings() -> void:
	save_data(settings, settings_path, "Settings")
	no_saved_settings = false
	var boot_path: String #= ProjectSettings.get_setting("application/config/project_settings_override", "user://boot.thss")
	if !boot_path.is_absolute_path():
		boot_path = "user://boot.thss"
		#ProjectSettings.set_setting("application/config/project_settings_override", "user://boot.thss")
	if FileAccess.file_exists(boot_path):
		DirAccess.remove_absolute(boot_path)

	settings_saved.emit()
	print("[Settings Manager] Settings saved!")

## Loads the settings variable from file
func load_settings() -> void:
	var loaded_data: Dictionary = load_data(settings_path, "Settings")
	if loaded_data.is_empty():
		no_saved_settings = true
		_process_settings()
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
func save_data(data: Dictionary, to_path: String, id: String = "Custom", prettify: bool = false) -> void:
	var json: String = JSON.stringify(data, "" if !prettify else "    ")
	
	if !DirAccess.dir_exists_absolute(to_path.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(to_path.get_base_dir())
	var file: FileAccess = FileAccess.open(to_path, FileAccess.WRITE)
	if !file:
		OS.alert("Failed to save %s to path:\n%s" % [id, to_path], "Can't save file!")
		return
	file.store_string(json)
	file.close()
	
	data_saved.emit(id)


## Restarts the application
func restart_application(start_on_menu: bool = true) -> void:
	var cmd_args := PackedStringArray([])
	if start_on_menu:
		var menu_path = ProjectSettings.get_setting("application/thunder_settings/main_menu_path")
		cmd_args = PackedStringArray([menu_path])
	cmd_args.append_array(OS.get_cmdline_args())
	OS.set_restart_on_exit(true, cmd_args)
	get_tree().quit()


func show_mouse() -> void:
	mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.mouse_mode = mouse_mode


func hide_mouse() -> void:
	mouse_mode = Input.MOUSE_MODE_HIDDEN
	if get_tree().root.has_focus():
		Input.mouse_mode = mouse_mode


func get_mouse_position() -> Vector2:
	return _current_mouse_pos


func get_quality() -> QUALITY:
	@warning_ignore("int_as_enum_without_cast")
	return roundi(settings.quality)


func get_key_label(action: String) -> String:
	var _events: Array[InputEvent] = InputMap.action_get_events(action)
	var _event: String = "<NOT SET>"
	var _temp: String
	for i in _events:
		if i is InputEventKey:
			_temp = i.as_text().get_slice(' (', 0) + ' button'
			#if SettingsManager.device_keyboard:
			_event = _temp
			break
		#elif i is InputEventJoypadButton:
		#	_temp = "Joy " + str(i.button_index)
		if _temp: _event = _temp
	
	return _event


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton && game_focused:
		if event.is_pressed():
			_current_mouse_pos = get_tree().root.get_mouse_position()
			mouse_moved.emit()
			mouse_pressed.emit(event.button_index)
		else:
			mouse_released.emit(event.button_index)

	elif event is InputEventMouseMotion:
		if (
			get_tree().root.has_focus() &&
			DisplayServer.window_get_mode(0) != DisplayServer.WINDOW_MODE_MINIMIZED &&
			event.relative != Vector2.ZERO
		):
			_current_mouse_pos = get_tree().root.get_mouse_position()
			mouse_moved.emit()
		
		if mouse_mode != Input.MOUSE_MODE_HIDDEN: return
		if abs(event.relative.x) < 2 && abs(event.relative.y) < 2:
			return
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mouse_timer.start(1.5)
	
	elif event is InputEventAction && event.is_action(&"asws_restart"):
		if Thunder.autosplitter && Thunder.autosplitter.config.restart_hotkey:
			Thunder.autosplitter.restarting.emit()
			Thunder.autosplitter.ws.poll()
			var state = Thunder.autosplitter.ws.get_ready_state()
			if state != WebSocketPeer.STATE_OPEN:
				Thunder.autosplitter.has_closed = false
				Thunder.autosplitter.has_connected = false
				var err = Thunder.autosplitter.connect_websocket()
				if err: print(err)


func _hide_mouse() -> void:
	if mouse_mode != Input.MOUSE_MODE_HIDDEN: return
	Input.mouse_mode = mouse_mode
